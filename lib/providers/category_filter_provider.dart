import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel_category.dart';
import '../models/m3u_entry.dart';
import 'channel_list_provider.dart';
import 'search_provider.dart';

final categoriesProvider = Provider<List<ChannelCategory>>((ref) {
  final channels = ref.watch(channelListProvider).valueOrNull ?? [];
  final groupCounts = <String, int>{};
  final langCounts = <String, int>{};

  for (final ch in channels) {
    final group = ch.groupTitle ?? 'Uncategorized';
    groupCounts[group] = (groupCounts[group] ?? 0) + 1;

    if (ch.tvgLanguage != null && ch.tvgLanguage!.isNotEmpty) {
      langCounts[ch.tvgLanguage!] = (langCounts[ch.tvgLanguage!] ?? 0) + 1;
    }
  }

  final cats = <ChannelCategory>[];
  for (final entry in groupCounts.entries) {
    cats.add(ChannelCategory(
      name: entry.key,
      type: CategoryType.group,
      channelCount: entry.value,
    ));
  }
  for (final entry in langCounts.entries) {
    cats.add(ChannelCategory(
      name: entry.key,
      type: CategoryType.language,
      channelCount: entry.value,
    ));
  }

  cats.sort((a, b) => a.name.compareTo(b.name));
  return cats;
});

final selectedCategoryProvider = StateProvider<ChannelCategory?>((ref) => null);

final filteredChannelsProvider = Provider<List<M3uEntry>>((ref) {
  final channels = ref.watch(channelListProvider).valueOrNull ?? [];
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = channels;

  if (category != null) {
    filtered = filtered.where((ch) {
      if (category.type == CategoryType.group) {
        return (ch.groupTitle ?? 'Uncategorized') == category.name;
      } else {
        return ch.tvgLanguage == category.name;
      }
    }).toList();
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((ch) {
      return ch.title.toLowerCase().contains(query) ||
          (ch.tvgName?.toLowerCase().contains(query) ?? false) ||
          (ch.groupTitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  return filtered;
});
