import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/m3u_entry.dart';

class RecentChannelsNotifier extends AsyncNotifier<List<M3uEntry>> {
  static const _key = 'recent_channels_list';
  static const _maxRecent = 30;

  @override
  Future<List<M3uEntry>> build() async {
    return _load();
  }

  Future<List<M3uEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data == null) return [];
    return data.map((json) => M3uEntry.fromJson(jsonDecode(json))).toList();
  }

  Future<void> _save(List<M3uEntry> channels) async {
    final prefs = await SharedPreferences.getInstance();
    final data = channels.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  Future<void> addRecent(M3uEntry channel) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('recent_channels') ?? true;
    if (!enabled) return;

    final current = state.valueOrNull ?? [];
    // Remove if already exists, then add to front
    final updated = [
      channel,
      ...current.where((c) => c.url != channel.url),
    ].take(_maxRecent).toList();
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData([]);
  }
}

final recentChannelsListProvider =
    AsyncNotifierProvider<RecentChannelsNotifier, List<M3uEntry>>(
  RecentChannelsNotifier.new,
);
