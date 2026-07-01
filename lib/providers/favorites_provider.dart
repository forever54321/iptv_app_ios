import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/m3u_entry.dart';

class FavoritesNotifier extends AsyncNotifier<List<M3uEntry>> {
  static const _key = 'favorite_channels';

  @override
  Future<List<M3uEntry>> build() async {
    return _load();
  }

  Future<List<M3uEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data == null) return [];
    return data
        .map((json) => M3uEntry.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _save(List<M3uEntry> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final data = favorites
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_key, data);
  }

  Future<void> toggle(M3uEntry channel) async {
    final current = state.valueOrNull ?? [];
    final exists = current.any((c) => c.url == channel.url);
    final updated = exists
        ? current.where((c) => c.url != channel.url).toList()
        : [...current, channel];
    await _save(updated);
    state = AsyncData(updated);
  }

  bool isFavorite(M3uEntry channel) {
    return (state.valueOrNull ?? []).any((c) => c.url == channel.url);
  }

  Future<void> remove(M3uEntry channel) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((c) => c.url != channel.url).toList();
    await _save(updated);
    state = AsyncData(updated);
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<M3uEntry>>(
  FavoritesNotifier.new,
);
