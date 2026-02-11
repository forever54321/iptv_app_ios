import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../models/m3u_entry.dart';
import 'category_filter_provider.dart';

class PlayerState {
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;

  const PlayerState({
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.isFullscreen = false,
  });

  PlayerState copyWith({
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
  }) {
    return PlayerState(
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  late final Player _player;

  Player get player => _player;

  @override
  PlayerState build() {
    _player = Player();

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

  Future<void> open(String url) async {
    await _player.open(Media(url));
  }

  Future<void> playPause() async {
    await _player.playOrPause();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
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
