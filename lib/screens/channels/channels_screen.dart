import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel_category.dart';
import '../../providers/category_filter_provider.dart';
import '../../providers/channel_list_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/loading_widget.dart';
import 'category_sidebar.dart';
import 'channel_tile.dart';

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Channels'),
        actions: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search channels...',
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
        loading: () => const LoadingWidget(message: 'Loading channels...'),
        error: (err, _) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.invalidate(channelListProvider),
        ),
        data: (allChannels) {
          if (allChannels.isEmpty) {
            return const Center(child: Text('No channels found in this playlist.'));
          }

          final filtered = ref.watch(filteredChannelsProvider);
          final categories = ref.watch(categoriesProvider);
          final selected = ref.watch(selectedCategoryProvider);

          // Separate groups and languages
          final groups = categories
              .where((c) => c.type == CategoryType.group)
              .toList();
          final languages = categories
              .where((c) => c.type == CategoryType.language)
              .toList();

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
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No channels match your filter.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ChannelTile(
                            channel: filtered[index],
                            onTap: () {
                              context.go('/player', extra: {
                                'initialIndex': index,
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
