import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import '../models/m3u_entry.dart';
import 'category_filter_provider.dart';

class PlayerState {
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;
  final bool isRecording;

  const PlayerState({
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.isFullscreen = false,
    this.isRecording = false,
  });

  PlayerState copyWith({
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
    bool? isRecording,
  }) {
    return PlayerState(
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isRecording: isRecording ?? this.isRecording,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  late final Player _player;

  Player get player => _player;

  @override
  PlayerState build() {
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 64 * 1024 * 1024,
      ),
    );

    _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    });
    _player.stream.volume.listen((vol) {
      state = state.copyWith(volume: vol);
    });

    ref.onDispose(() {
      _player.dispose();
    });

    return const PlayerState();
  }

  Future<void> _configureLiveBuffering() async {
    try {
      if (_player.platform is NativePlayer) {
        final mpv = _player.platform as NativePlayer;

        // Mimic VLC user-agent so IPTV servers don't throttle
        mpv.setProperty('user-agent', 'VLC/3.0.20 LibVLC/3.0.20');

        // Disk-backed cache — overflow to storage instead of just RAM
        try {
          final tmpDir = await getTemporaryDirectory();
          final cacheDir = Directory('${tmpDir.path}/mpv_cache');
          if (!cacheDir.existsSync()) {
            cacheDir.createSync(recursive: true);
          }
          mpv.setProperty('cache-dir', cacheDir.path);
          mpv.setProperty('cache-on-disk', 'yes');
        } catch (_) {}

        // Auto-reconnect on network drops
        mpv.setProperty('demuxer-lavf-o',
            'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5,'
            'reconnect_on_network_error=1,reconnect_on_http_error=4xx\\,5xx');

        // Desktop-only: larger buffers are safe
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          mpv.setProperty('cache', 'yes');
          mpv.setProperty('cache-secs', '30');
          mpv.setProperty('demuxer-readahead-secs', '30');
          mpv.setProperty('demuxer-max-bytes', '50MiB');
          mpv.setProperty('cache-pause-initial', 'yes');
          mpv.setProperty('cache-pause-wait', '3');
          mpv.setProperty('cache-pause', 'no');
          mpv.setProperty('keep-open', 'yes');
        }

        if (Platform.isIOS || Platform.isAndroid) {
          // Start fast, probe shallow (VLC-style live behavior)
          mpv.setProperty('demuxer-lavf-probesize', '500000');
          mpv.setProperty('demuxer-lavf-analyzeduration', '1');
          mpv.setProperty('demuxer-lavf-probe-info', 'nostreams');

          // Big rolling reserve — absorbs network dips without stalling
          mpv.setProperty('cache', 'yes');
          mpv.setProperty('cache-secs', '60');
          mpv.setProperty('demuxer-readahead-secs', '60');
          mpv.setProperty('demuxer-max-bytes', '64MiB');
          mpv.setProperty('demuxer-max-back-bytes', '32MiB');

          // Keep playback alive through underruns — no hard pauses
          mpv.setProperty('cache-pause-initial', 'no');
          mpv.setProperty('cache-pause', 'no');
          mpv.setProperty('cache-pause-wait', '1');

          // Bigger TCP read chunks so bursty networks fill the cache faster
          mpv.setProperty('stream-buffer-size', '4MiB');

          // Larger audio buffer carries playback through brief demuxer gaps
          mpv.setProperty('audio-buffer', '1.0');

          // HLS: stay near live edge like VLC
          mpv.setProperty('hls-bitrate', 'max');

          // Live-friendly decode/sync
          mpv.setProperty('video-sync', 'audio');
          mpv.setProperty('interpolation', 'no');
          mpv.setProperty('vd-lavc-fast', 'yes');
          mpv.setProperty('vd-lavc-threads', '0');
          mpv.setProperty('hwdec', 'auto-safe');
          mpv.setProperty('framedrop', 'vo');
          mpv.setProperty('network-timeout', '30');
        }
      }
    } catch (_) {}
  }

  Future<void> open(String url) async {
    await _configureLiveBuffering();
    await _player.open(Media(url));
  }

  Future<void> playPause() async {
    await _player.playOrPause();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    if (state.isRecording) {
      await stopRecording();
    }
    await _player.stop();
  }

  Future<void> seekForward() async {
    final pos = state.position + const Duration(seconds: 15);
    await _player.seek(pos);
  }

  Future<void> seekBackward() async {
    var pos = state.position - const Duration(seconds: 15);
    if (pos.isNegative) pos = Duration.zero;
    await _player.seek(pos);
  }

  StreamSubscription? _recordingSubscription;
  IOSink? _recordingSink;
  String? _recordingPath;

  Future<void> startRecording() async {
    final channel = currentChannel;
    if (channel == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!recordingsDir.existsSync()) {
      recordingsDir.createSync(recursive: true);
    }

    final name = channel.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${recordingsDir.path}/${name}_$timestamp.ts';

    try {
      // Also try mpv stream-record first
      if (_player.platform is NativePlayer) {
        final mpv = _player.platform as NativePlayer;
        await mpv.setProperty('stream-record', _recordingPath!);
      }

      // Additionally capture via HTTP as backup
      final request = http.Request('GET', Uri.parse(channel.url));
      request.headers['User-Agent'] = 'VLC/3.0.20 LibVLC/3.0.20';
      final response = await request.send();

      if (response.statusCode == 200) {
        final file = File('${_recordingPath!}.http');
        _recordingSink = file.openWrite();
        _recordingSubscription = response.stream.listen(
          (chunk) => _recordingSink?.add(chunk),
          onError: (_) {},
        );
      }
    } catch (_) {}

    state = state.copyWith(isRecording: true);
  }

  Future<void> stopRecording() async {
    // Stop mpv recording
    if (_player.platform is NativePlayer) {
      final mpv = _player.platform as NativePlayer;
      try {
        await mpv.setProperty('stream-record', '');
      } catch (_) {}
    }

    // Stop HTTP recording
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    await _recordingSink?.flush();
    await _recordingSink?.close();
    _recordingSink = null;

    // Check which file has content — keep the bigger one, delete the other
    if (_recordingPath != null) {
      final mpvFile = File(_recordingPath!);
      final httpFile = File('${_recordingPath!}.http');

      final mpvSize = mpvFile.existsSync() ? mpvFile.lengthSync() : 0;
      final httpSize = httpFile.existsSync() ? httpFile.lengthSync() : 0;

      if (mpvSize > 0 && httpSize > 0) {
        // Keep the bigger one
        if (httpSize > mpvSize) {
          mpvFile.deleteSync();
          httpFile.renameSync(_recordingPath!);
        } else {
          httpFile.deleteSync();
        }
      } else if (httpSize > 0 && mpvSize == 0) {
        httpFile.renameSync(_recordingPath!);
      }
    }

    _recordingPath = null;
    state = state.copyWith(isRecording: false);
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  void setFullscreen(bool value) {
    state = state.copyWith(isFullscreen: value);
  }

  Future<void> playChannel(int index) async {
    final channels = ref.read(filteredChannelsProvider);
    if (index < 0 || index >= channels.length) return;
    state = state.copyWith(currentIndex: index);
    await open(channels[index].url);
  }

  Future<void> nextChannel() async {
    final channels = ref.read(filteredChannelsProvider);
    if (channels.isEmpty) return;
    final next = (state.currentIndex + 1) % channels.length;
    await playChannel(next);
  }

  Future<void> previousChannel() async {
    final channels = ref.read(filteredChannelsProvider);
    if (channels.isEmpty) return;
    final prev = (state.currentIndex - 1 + channels.length) % channels.length;
    await playChannel(prev);
  }

  M3uEntry? get currentChannel {
    final channels = ref.read(filteredChannelsProvider);
    if (state.currentIndex < 0 || state.currentIndex >= channels.length) {
      return null;
    }
    return channels[state.currentIndex];
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
