import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel_category.dart';
import '../../models/m3u_entry.dart';
import '../../providers/category_filter_provider.dart';
import '../../providers/channel_list_provider.dart';
import '../../providers/search_provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/epg_provider.dart';
import '../../screens/settings/settings_screen.dart';
import '../../services/download_service.dart';
import '../../widgets/loading_widget.dart';
import 'category_sidebar.dart';
import 'channel_tile.dart';

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelListProvider);
    final lang = ref.watch(appLanguageProvider);
    final organizeByGroups = ref.watch(organizeByGroupsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final groupsOn = ref.read(organizeByGroupsProvider);
            context.go(groupsOn ? '/groups' : '/home');
          },
        ),
        title: Text(ref.watch(selectedCategoryProvider)?.name ?? S.allChannels(lang)),
        actions: [
          if (!isWideScreen)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showCategoryBottomSheet(context, ref),
            ),
          SizedBox(
            width: isWideScreen ? 300 : screenWidth * 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: S.searchChannels(lang),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: channelsAsync.when(
        loading: () => LoadingWidget(message: S.loadingChannels(lang)),
        error: (err, _) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.invalidate(channelListProvider),
        ),
        data: (allChannels) {
          if (allChannels.isEmpty) {
            return Center(child: Text(S.noChannelsFound(lang)));
          }

          final filtered = ref.watch(filteredChannelsProvider);
          final totalFiltered = ref.watch(filteredCountProvider);
          final categories = ref.watch(categoriesProvider);
          final selected = ref.watch(selectedCategoryProvider);

          final groups = categories
              .where((c) => c.type == CategoryType.group)
              .toList();
          final languages = categories
              .where((c) => c.type == CategoryType.language)
              .toList();

          final gridExtent = isWideScreen ? 200.0 : 160.0;

          // Build the channel content — always flat grid
          // Groups screen handles the category browsing
          Widget channelContent;
          if (filtered.isEmpty) {
            channelContent = Center(child: Text(S.noChannelsFound(lang)));
          } else {
            channelContent = _buildFlatGrid(
              context, ref, filtered, gridExtent, lang,
            );
          }

          if (isWideScreen) {
            return Row(
              children: [
                CategorySidebar(
                  groups: groups,
                  languages: languages,
                  selected: selected,
                  totalCount: allChannels.length,
                  onSelect: (cat) {
                    ref.read(selectedCategoryProvider.notifier).state = cat;
                  },
                ),
                Expanded(child: channelContent),
              ],
            );
          }

          return channelContent;
        },
      ),
    );
  }

  /// Flat grid view — all channels in one grid
  Widget _buildFlatGrid(
    BuildContext context,
    WidgetRef ref,
    List<M3uEntry> channels,
    double gridExtent,
    AppLanguage lang,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: gridExtent,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return _buildChannelTile(context, ref, channels, index, lang);
      },
    );
  }

  /// Grouped view — channels organized under category headers
  Widget _buildGroupedView(
    BuildContext context,
    WidgetRef ref,
    List<M3uEntry> channels,
    double gridExtent,
    AppLanguage lang,
  ) {
    // Group channels by their groupTitle
    final grouped = <String, List<MapEntry<int, M3uEntry>>>{};
    for (var i = 0; i < channels.length; i++) {
      final group = channels[i].groupTitle ?? 'Uncategorized';
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(MapEntry(i, channels[i]));
    }

    final sortedGroups = grouped.keys.toList()..sort();
    final crossAxisCount = (MediaQuery.of(context).size.width / gridExtent).floor().clamp(2, 10);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedGroups.length,
      itemBuilder: (context, groupIndex) {
        final groupName = sortedGroups[groupIndex];
        final groupChannels = grouped[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 16),
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 20, color: Colors.deepPurple.shade300),
                  const SizedBox(width: 8),
                  Text(
                    groupName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple.shade200,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${groupChannels.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Channel grid for this group
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: groupChannels.length,
              itemBuilder: (context, i) {
                final entry = groupChannels[i];
                return _buildChannelTile(
                  context, ref, channels, entry.key, lang,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Check if a channel is VOD (movie/series) vs live
  bool _isVOD(M3uEntry channel) {
    final group = (channel.groupTitle ?? '').toLowerCase();
    final title = channel.title.toLowerCase();
    final url = channel.url.toLowerCase();
    // VOD: has positive duration, or group contains movie/series keywords, or URL is a file
    return channel.duration > 0 ||
        group.contains('movie') ||
        group.contains('film') ||
        group.contains('series') ||
        group.contains('vod') ||
        group.contains('show') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mkv') ||
        url.endsWith('.avi');
  }

  Widget _buildChannelTile(
    BuildContext context,
    WidgetRef ref,
    List<M3uEntry> channels,
    int index,
    AppLanguage lang,
  ) {
    final channel = channels[index];
    final isFav = ref.watch(favoritesProvider).valueOrNull
            ?.any((c) => c.url == channel.url) ??
        false;
    final isVod = _isVOD(channel);

    final nowPlaying = ref.watch(currentProgramProvider(channel.tvgId ?? ''));

    return ChannelTile(
      channel: channel,
      isFavorite: isFav,
      isVOD: isVod,
      nowPlaying: nowPlaying?.title,
      onTap: () {
        context.go('/player', extra: {'initialIndex': index});
      },
      onLongPress: () {
        ref.read(favoritesProvider.notifier).toggle(channel);
        final willBeFav = !isFav;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willBeFav
                ? S.addedToFavorites(lang, channel.title)
                : S.removedFromFavorites(lang, channel.title)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onDownload: isVod
          ? () => _showDownloadDisclaimer(context, ref, channel)
          : null,
    );
  }

  void _showDownloadDisclaimer(BuildContext context, WidgetRef ref, M3uEntry channel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Copyright Notice'),
          ],
        ),
        content: const Text(
          'You must own or have legal authorization to download this content. '
          'Downloading copyrighted material without permission is prohibited and may violate applicable laws.\n\n'
          'By proceeding, you confirm that you have the right to download this content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(downloadProvider.notifier).download(channel);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${channel.title}...'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('I Agree & Download'),
          ),
        ],
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context, WidgetRef ref) {
    final categories = ref.read(categoriesProvider);
    final selected = ref.read(selectedCategoryProvider);
    final channelsAsync = ref.read(channelListProvider);
    final totalCount = channelsAsync.valueOrNull?.length ?? 0;

    final groups =
        categories.where((c) => c.type == CategoryType.group).toList();
    final languages =
        categories.where((c) => c.type == CategoryType.language).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) {
        return SafeArea(
          child: CategorySidebar(
            groups: groups,
            languages: languages,
            selected: selected,
            totalCount: totalCount,
            onSelect: (cat) {
              ref.read(selectedCategoryProvider.notifier).state = cat;
              Navigator.pop(context);
            },
            asSheet: true,
          ),
        );
      },
    );
  }
}
