import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/player_provider.dart';
import '../../providers/pro_provider.dart';
import '../../providers/recent_channels_provider.dart';
import '../../providers/category_filter_provider.dart';
import '../../providers/epg_provider.dart';
import '../../services/hinge_service.dart';
import '../../models/m3u_entry.dart';
import '../../core/glass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../settings/settings_screen.dart';

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get _isMobile => Platform.isIOS || Platform.isAndroid;

class PlayerScreen extends ConsumerStatefulWidget {
  final int initialChannelIndex;
  const PlayerScreen({super.key, required this.initialChannelIndex});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final VideoController _videoController;
  bool _showOverlay = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(playerProvider.notifier);
    // One shared controller owned by the provider — see PlayerNotifier.videoController.
    _videoController = notifier.videoController;
    // Start playing the selected channel
    // On macOS, mpv needs a brief delay after initialization before playback
    Future.microtask(() async {
      if (Platform.isMacOS) {
        await Future.delayed(const Duration(seconds: 2));
      }
      if (mounted) {
        notifier.playChannel(widget.initialChannelIndex);
        // Track as recent channel
        final channel = notifier.currentChannel;
        if (channel != null) {
          ref.read(recentChannelsListProvider.notifier).addRecent(channel);
        }
      }
    });
    _startHideTimer();

    // On iOS, force landscape for video playback — except on a half-folded iPhone Duo,
    // where the screen follows how it's held so the video can sit above the channel list.
    if (Platform.isIOS) {
      _applyOrientation(ref.read(hingeProvider).valueOrNull ?? HingeState.none);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      ref.listenManual(hingeProvider, (_, next) {
        final h = next.valueOrNull;
        if (h != null) _applyOrientation(h);
      });
    }
  }

  void _applyOrientation(HingeState hinge) {
    SystemChrome.setPreferredOrientations(hinge.isHalfOpen
        ? DeviceOrientation.values
        : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  /// Tune to a channel from the Duo's bottom list (same as next/previous: also adds it to Recent).
  void _pickChannel(int index) {
    final notifier = ref.read(playerProvider.notifier);
    notifier.playChannel(index);
    Future.microtask(() {
      final ch = notifier.currentChannel;
      if (ch != null) ref.read(recentChannelsListProvider.notifier).addRecent(ch);
    });
    setState(() => _showOverlay = true);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _goBack() async {
    final notifier = ref.read(playerProvider.notifier);
    final state = ref.read(playerProvider);
    await notifier.stop();
    if (_isDesktop && state.isFullscreen) {
      await windowManager.setFullScreen(false);
      notifier.setFullscreen(false);
    }
    // Restore orientations before navigating away (dispose fires too late)
    if (Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (!mounted) return;
    // Pop back to the list we were launched from (folder list, channel list or
    // search results); only fall back to /channels when there's nothing to pop.
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/channels');
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _onMouseMove() {
    if (!_showOverlay) {
      setState(() => _showOverlay = true);
    }
    _startHideTimer();
  }

  Future<void> _toggleFullscreen() async {
    final notifier = ref.read(playerProvider.notifier);
    final current = ref.read(playerProvider).isFullscreen;
    if (_isDesktop) {
      if (current) {
        await windowManager.setFullScreen(false);
        notifier.setFullscreen(false);
      } else {
        await windowManager.setFullScreen(true);
        notifier.setFullscreen(true);
      }
    } else {
      // On mobile, toggle immersive mode
      if (current) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        notifier.setFullscreen(false);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky);
        notifier.setFullscreen(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final channel = notifier.currentChannel;
    final aspectRatio = ref.watch(defaultAspectRatioProvider);
    final hinge = ref.watch(hingeProvider).valueOrNull ?? HingeState.none;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, box) {
        final surface = _surface(state, notifier, channel, aspectRatio);
        if (!hinge.isHalfOpen) return surface;
        // Half-folded iPhone Duo: one half plays, the other half lists the channels.
        // Held like a laptop the screen is tall → video on top, channels below the fold;
        // held like a book it's wide → video left, channels right.
        final tall = box.maxHeight >= box.maxWidth;
        return Flex(
          direction: tall ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(child: ClipRect(child: surface)),
            Expanded(child: _DuoChannelPanel(onPick: _pickChannel)),
          ],
        );
      }),
    );
  }

  Widget _surface(PlayerState state, PlayerNotifier notifier, M3uEntry? channel, String aspectRatio) {
    return KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (state.isFullscreen) {
                _toggleFullscreen();
              } else {
                _goBack();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              notifier.playPause();
            } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullscreen();
            }
          }
        },
        child: MouseRegion(
          onHover: (_) => _onMouseMove(),
          cursor: _showOverlay
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: GestureDetector(
            onTap: () {
              setState(() => _showOverlay = !_showOverlay);
              if (_showOverlay) _startHideTimer();
            },
            child: Stack(
              children: [
                // Video
                Positioned.fill(
                  child: _buildVideo(aspectRatio),
                ),
                // Overlay controls
                if (_showOverlay) ...[
                  // Top bar: back + channel info
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                iconSize: _isMobile ? 28 : 24,
                                onPressed: _goBack,
                              ),
                              const SizedBox(width: 12),
                              if (channel != null) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        channel.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (channel.groupTitle != null)
                                        Text(
                                          channel.groupTitle!,
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Previous channel
                              IconButton(
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.white),
                                iconSize: _isMobile ? 32 : 28,
                                onPressed: () {
                                  notifier.previousChannel();
                                  Future.microtask(() {
                                    final ch = notifier.currentChannel;
                                    if (ch != null) ref.read(recentChannelsListProvider.notifier).addRecent(ch);
                                  });
                                },
                              ),
                              SizedBox(width: _isMobile ? 12 : 8),
                              // Rewind 15s
                              IconButton(
                                icon: const Icon(Icons.replay_10,
                                    color: Colors.white),
                                iconSize: _isMobile ? 32 : 28,
                                onPressed: () => notifier.seekBackward(),
                              ),
                              SizedBox(width: _isMobile ? 12 : 8),
                              // Play/Pause
                              IconButton(
                                icon: Icon(
                                  state.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white,
                                ),
                                iconSize: _isMobile ? 56 : 48,
                                onPressed: () => notifier.playPause(),
                              ),
                              SizedBox(width: _isMobile ? 12 : 8),
                              // Forward 15s
                              IconButton(
                                icon: const Icon(Icons.forward_10,
                                    color: Colors.white),
                                iconSize: _isMobile ? 32 : 28,
                                onPressed: () => notifier.seekForward(),
                              ),
                              SizedBox(width: _isMobile ? 12 : 8),
                              // Next channel
                              IconButton(
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.white),
                                iconSize: _isMobile ? 32 : 28,
                                onPressed: () {
                                  notifier.nextChannel();
                                  Future.microtask(() {
                                    final ch = notifier.currentChannel;
                                    if (ch != null) ref.read(recentChannelsListProvider.notifier).addRecent(ch);
                                  });
                                },
                              ),
                              SizedBox(width: _isMobile ? 12 : 8),
                              // Record button (Pro-gated)
                              IconButton(
                                icon: Icon(
                                  state.isRecording
                                      ? Icons.stop_circle
                                      : Icons.fiber_manual_record,
                                  color: state.isRecording ? Colors.red : Colors.white,
                                ),
                                iconSize: _isMobile ? 32 : 28,
                                onPressed: () async {
                                  if (!ref.read(hasProAccessProvider)) {
                                    context.push('/paywall');
                                    return;
                                  }
                                  if (state.isRecording) {
                                    await notifier.toggleRecording();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Recording saved'),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  } else {
                                    _showRecordingDisclaimer(context, notifier);
                                  }
                                },
                              ),
                              // Volume slider: desktop only (iOS uses hardware buttons)
                              if (_isDesktop) ...[
                                const SizedBox(width: 32),
                                Icon(
                                  state.volume > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Slider(
                                    value: state.volume,
                                    max: 100,
                                    onChanged: (v) => notifier.setVolume(v),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Fullscreen button: desktop only (mobile is already fullscreen)
                              if (_isDesktop)
                                IconButton(
                                  icon: Icon(
                                    state.isFullscreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _toggleFullscreen,
                                ),
                              // Aspect ratio button
                              IconButton(
                                icon: const Icon(Icons.aspect_ratio,
                                    color: Colors.white, size: 24),
                                onPressed: _cycleAspectRatio,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }

  void _showRecordingDisclaimer(BuildContext context, PlayerNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Copyright Notice'),
          ],
        ),
        content: const Text(
          'You must own or have legal authorization to record this content. '
          'Recording copyrighted material without permission is prohibited and may violate applicable laws.\n\n'
          'By proceeding, you confirm that you have the right to record this content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await notifier.toggleRecording();
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recording started — tap again to stop'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('I Agree & Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo(String aspectRatio) {
    final video = Video(
      controller: _videoController,
      controls: NoVideoControls,
      fit: _getBoxFit(aspectRatio),
    );

    if (aspectRatio == '4:3') {
      return Center(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: video,
        ),
      );
    } else if (aspectRatio == '16:9') {
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: video,
        ),
      );
    }
    // Fill or Fit — use full screen
    return video;
  }

  BoxFit _getBoxFit(String aspectRatio) {
    switch (aspectRatio) {
      case 'Fill':
        return BoxFit.cover;
      case 'Fit':
        return BoxFit.contain;
      case '4:3':
      case '16:9':
      default:
        return BoxFit.contain;
    }
  }

  void _cycleAspectRatio() {
    const ratios = ['16:9', '4:3', 'Fill', 'Fit'];
    final current = ref.read(defaultAspectRatioProvider);
    final nextIndex = (ratios.indexOf(current) + 1) % ratios.length;
    ref.read(defaultAspectRatioProvider.notifier).state = ratios[nextIndex];
    SharedPreferences.getInstance().then((p) => p.setString('aspect_ratio', ratios[nextIndex]));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aspect Ratio: ${ratios[nextIndex]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// The bottom (or right) half of a half-folded iPhone Duo: every channel in the current list,
/// the one playing highlighted. Tap one and it plays in the other half.
class _DuoChannelPanel extends ConsumerStatefulWidget {
  final void Function(int index) onPick;
  const _DuoChannelPanel({required this.onPick});

  @override
  ConsumerState<_DuoChannelPanel> createState() => _DuoChannelPanelState();
}

class _DuoChannelPanelState extends ConsumerState<_DuoChannelPanel> {
  static const _rowHeight = 64.0;
  final _scroll = ScrollController();
  int? _scrolledTo;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Keep the playing channel in view (once per change, so the user can still scroll freely).
  void _reveal(int index) {
    if (_scrolledTo == index) return;
    _scrolledTo = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (index * _rowHeight - _scroll.position.viewportDimension / 2 + _rowHeight / 2)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(filteredChannelsProvider);
    final current = ref.watch(playerProvider.select((s) => s.currentIndex));
    _reveal(current);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(children: [
                const Icon(Icons.live_tv_rounded, color: AppColors.sky, size: 20),
                const SizedBox(width: 8),
                const Text('Channels',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${channels.length}', style: const TextStyle(color: AppColors.slate, fontSize: 14)),
              ]),
            ),
            Expanded(
              child: channels.isEmpty
                  ? const Center(child: Text('No channels in this list', style: TextStyle(color: AppColors.slate)))
                  : ListView.builder(
                      controller: _scroll,
                      itemExtent: _rowHeight,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      itemCount: channels.length,
                      itemBuilder: (_, i) => _DuoChannelRow(
                        channel: channels[i],
                        number: i + 1,
                        playing: i == current,
                        onTap: () => widget.onPick(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuoChannelRow extends ConsumerWidget {
  final M3uEntry channel;
  final int number;
  final bool playing;
  final VoidCallback onTap;
  const _DuoChannelRow({required this.channel, required this.number, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentProgramProvider(channel.tvgId ?? ''));
    final logo = channel.tvgLogo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: playing ? AppColors.violet.withValues(alpha: 0.30) : AppColors.surfaceLo.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Text('$number', textAlign: TextAlign.center,
                    style: TextStyle(color: playing ? Colors.white : AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52, height: 38, color: Colors.black26,
                  child: logo != null && logo.isNotEmpty
                      ? CachedNetworkImage(imageUrl: logo, fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(Icons.live_tv_rounded, color: Colors.white30, size: 20))
                      : const Icon(Icons.live_tv_rounded, color: Colors.white30, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    if (now != null)
                      Text(now.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.slate, fontSize: 12)),
                  ],
                ),
              ),
              if (playing) const Icon(Icons.equalizer_rounded, color: AppColors.teal, size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}
