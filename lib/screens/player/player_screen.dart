import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/player_provider.dart';

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
    _videoController = VideoController(notifier.player);
    // Start playing the selected channel
    Future.microtask(() {
      notifier.playChannel(widget.initialChannelIndex);
    });
    _startHideTimer();

    // On iOS, force landscape for video playback
    if (Platform.isIOS) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    ref.read(playerProvider.notifier).stop();
    // On iOS, restore all orientations when leaving the player
    if (Platform.isIOS) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
    if (mounted) context.go('/channels');
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
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
                  child: Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                  ),
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
                              IconButton(
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.white),
                                iconSize: _isMobile ? 36 : 32,
                                onPressed: () => notifier.previousChannel(),
                              ),
                              SizedBox(width: _isMobile ? 20 : 16),
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
                              SizedBox(width: _isMobile ? 20 : 16),
                              IconButton(
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.white),
                                iconSize: _isMobile ? 36 : 32,
                                onPressed: () => notifier.nextChannel(),
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
      ),
    );
  }
}
