import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/epg_program.dart';
import '../models/playlist_source.dart';
import '../services/epg_service.dart';
import '../services/m3u_parser.dart';
import '../services/playlist_fetch_service.dart';
import 'playlist_source_provider.dart';

/// The resolved EPG URL (from M3U header, Xtream Codes, or manual override)
final epgUrlProvider = FutureProvider<String?>((ref) async {
  // Check manual override first
  final manual = await EpgService.getManualUrl();
  if (manual != null && manual.isNotEmpty) return manual;

  // Get active playlist
  final sourcesAsync = ref.watch(playlistSourcesProvider);
  final sources = sourcesAsync.valueOrNull ?? [];
  final active = sources.where((s) => s.isActive).firstOrNull ?? sources.firstOrNull;
  if (active == null) return null;

  // For Xtream Codes, build the EPG URL directly
  if (active.type == PlaylistType.xtreamCodes &&
      active.username != null &&
      active.password != null) {
    return M3uParser.buildXtreamEpgUrl(active.url, active.username!, active.password!);
  }

  // For direct M3U, try to extract from header
  try {
    final content = await PlaylistFetchService.fetch(active.effectiveUrl);
    return M3uParser.extractEpgUrl(content);
  } catch (_) {
    return null;
  }
});

/// EPG data
class EpgNotifier extends AsyncNotifier<Map<String, List<EpgProgram>>> {
  Timer? _refreshTimer;

  @override
  Future<Map<String, List<EpgProgram>>> build() async {
    final url = await ref.watch(epgUrlProvider.future);
    if (url == null || url.isEmpty) return {};

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(hours: 12), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => _refreshTimer?.cancel());

    try {
      return await EpgService.fetchAndParse(url);
    } catch (e) {
      // Return empty on error instead of crashing
      return {};
    }
  }

  Future<void> refresh() async {
    final url = await ref.read(epgUrlProvider.future);
    if (url == null || url.isEmpty) return;

    state = const AsyncLoading();
    try {
      final data = await EpgService.refresh(url);
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final epgProvider = AsyncNotifierProvider<EpgNotifier, Map<String, List<EpgProgram>>>(
  EpgNotifier.new,
);

/// Current program for a specific channel
final currentProgramProvider = Provider.family<EpgProgram?, String>((ref, channelId) {
  if (channelId.isEmpty) return null;
  final epg = ref.watch(epgProvider).valueOrNull ?? {};

  // Try exact match first
  var programs = epg[channelId];

  // Try case-insensitive match
  if (programs == null) {
    final lower = channelId.toLowerCase();
    for (final key in epg.keys) {
      if (key.toLowerCase() == lower) {
        programs = epg[key];
        break;
      }
    }
  }

  if (programs == null) return null;

  final now = DateTime.now();
  for (final p in programs) {
    if (now.isAfter(p.start) && now.isBefore(p.stop)) return p;
  }
  return null;
});

/// Next program for a specific channel
final nextProgramProvider = Provider.family<EpgProgram?, String>((ref, channelId) {
  if (channelId.isEmpty) return null;
  final epg = ref.watch(epgProvider).valueOrNull ?? {};

  var programs = epg[channelId];
  if (programs == null) {
    final lower = channelId.toLowerCase();
    for (final key in epg.keys) {
      if (key.toLowerCase() == lower) {
        programs = epg[key];
        break;
      }
    }
  }

  if (programs == null) return null;

  final now = DateTime.now();
  for (final p in programs) {
    if (p.start.isAfter(now)) return p;
  }
  return null;
});

/// Full schedule for a channel
final channelScheduleProvider = Provider.family<List<EpgProgram>, String>((ref, channelId) {
  if (channelId.isEmpty) return [];
  final epg = ref.watch(epgProvider).valueOrNull ?? {};

  var programs = epg[channelId];
  if (programs == null) {
    final lower = channelId.toLowerCase();
    for (final key in epg.keys) {
      if (key.toLowerCase() == lower) {
        programs = epg[key];
        break;
      }
    }
  }

  return programs ?? [];
});
