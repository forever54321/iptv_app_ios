import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_strings.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/loading_widget.dart';
import '../channels/channel_tile.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;
    final gridExtent = isWideScreen ? 200.0 : 160.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(S.favorites(lang)),
      ),
      body: favoritesAsync.when(
        loading: () => const LoadingWidget(message: 'Loading favorites...'),
        error: (err, _) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline, size: 80, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text(
                    S.noFavorites(lang),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.longPressToFavorite(lang),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: gridExtent,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final channel = favorites[index];
              return ChannelTile(
                channel: channel,
                isFavorite: true,
                onTap: () {
                  // Play directly — store favorites as the filtered list
                  context.go('/player', extra: {
                    'initialIndex': index,
                    'fromFavorites': true,
                  });
                },
                onLongPress: () {
                  ref.read(favoritesProvider.notifier).remove(channel);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${channel.title} removed from favorites'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).toggle(channel);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
