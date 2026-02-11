import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist_source.dart';
import '../services/storage_service.dart';

class PlaylistSourcesNotifier extends AsyncNotifier<List<PlaylistSource>> {
  @override
  Future<List<PlaylistSource>> build() async {
    return StorageService.getAll();
  }

  Future<void> add(PlaylistSource source) async {
    await StorageService.add(source);
    ref.invalidateSelf();
  }

  Future<void> remove(PlaylistSource source) async {
    await StorageService.delete(source);
    ref.invalidateSelf();
  }

  Future<void> updateSource(PlaylistSource source) async {
    await StorageService.update(source);
    ref.invalidateSelf();
  }

  Future<void> setActive(PlaylistSource source) async {
    await StorageService.setActive(source);
    ref.invalidateSelf();
  }
}

final playlistSourcesProvider =
    AsyncNotifierProvider<PlaylistSourcesNotifier, List<PlaylistSource>>(
  PlaylistSourcesNotifier.new,
);

final activePlaylistProvider = Provider<PlaylistSource?>((ref) {
  final sources = ref.watch(playlistSourcesProvider).valueOrNull;
  if (sources == null) return null;
  try {
    return sources.firstWhere((s) => s.isActive);
  } catch (_) {
    return null;
  }
});
