import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class LocalPlayerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const LocalPlayerScreen({super.key, required this.filePath});

  @override
  ConsumerState<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends ConsumerState<LocalPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _showOverlay = true;
  Timer? _hideTimer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _player.stream.playing.listen((p) => setState(() => _isPlaying = p));
    _player.stream.position.listen((p) => setState(() => _position = p));
    _player.stream.duration.listen((d) => setState(() => _duration = d));

    _player.open(Media(widget.filePath));
    _startHideTimer();

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
    _player.dispose();
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

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showOverlay = !_showOverlay);
          if (_showOverlay) _startHideTimer();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: _videoController,
                controls: NoVideoControls,
              ),
            ),
            if (_showOverlay) ...[
              // Top bar
              Positioned(
                top: 0, left: 0, right: 0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.go('/recordings'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom controls
              Positioned(
                bottom: 0, left: 0, right: 0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          Row(
                            children: [
                              Text(_formatDuration(_position),
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: _duration.inMilliseconds > 0
                                      ? _position.inMilliseconds / _duration.inMilliseconds
                                      : 0,
                                  onChanged: (v) {
                                    _player.seek(Duration(
                                        milliseconds: (v * _duration.inMilliseconds).round()));
                                  },
                                ),
                              ),
                              Text(_formatDuration(_duration),
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                          // Playback controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white),
                                iconSize: 32,
                                onPressed: () {
                                  var pos = _position - const Duration(seconds: 10);
                                  if (pos.isNegative) pos = Duration.zero;
                                  _player.seek(pos);
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                ),
                                iconSize: 56,
                                onPressed: () => _player.playOrPause(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white),
                                iconSize: 32,
                                onPressed: () {
                                  _player.seek(_position + const Duration(seconds: 10));
                                },
                              ),
                            ],
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
    );
  }
}
