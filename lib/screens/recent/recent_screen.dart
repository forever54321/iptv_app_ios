import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/recent_channels_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/loading_widget.dart';
import '../channels/channel_tile.dart';

class RecentScreen extends ConsumerWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final recentAsync = ref.watch(recentChannelsListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;
    final gridExtent = isWideScreen ? 200.0 : 160.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/groups'),
        ),
        title: const Text('Recent Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(recentChannelsListProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${S.clearHistory(lang)} ✓')),
              );
            },
          ),
        ],
      ),
      body: recentAsync.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (err, _) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.invalidate(recentChannelsListProvider),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return const Center(child: Text('No recent channels'));
          }

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
              final channel = channels[index];
              final isFav = ref.watch(favoritesProvider).valueOrNull
                      ?.any((c) => c.url == channel.url) ??
                  false;
              return ChannelTile(
                channel: channel,
                isFavorite: isFav,
                onTap: () {
                  context.go('/player', extra: {'initialIndex': index});
                },
                onLongPress: () {
                  ref.read(favoritesProvider.notifier).toggle(channel);
                },
              );
            },
          );
        },
      ),
    );
  }
}
