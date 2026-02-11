import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/m3u_entry.dart';
import '../services/m3u_parser.dart';
import '../services/playlist_fetch_service.dart';
import 'playlist_source_provider.dart';

final channelListProvider = FutureProvider<List<M3uEntry>>((ref) async {
  final active = ref.watch(activePlaylistProvider);
  if (active == null) return [];

  final content = await PlaylistFetchService.fetch(active.effectiveUrl);
  return M3uParser.parse(content);
});
