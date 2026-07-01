import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/playlist_source.dart';
import '../../providers/playlist_source_provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/category_filter_provider.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/loading_widget.dart';
import 'add_playlist_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(playlistSourcesProvider);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.appTitle(lang)),
        centerTitle: true,
      ),
      drawer: _AppDrawer(),
      body: sourcesAsync.when(
        loading: () => const LoadingWidget(message: 'Loading playlists...'),
        error: (err, _) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.invalidate(playlistSourcesProvider),
        ),
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv, size: 80, color: Colors.deepPurple.shade300),
                  const SizedBox(height: 16),
                  Text(
                    S.noPlaylists(lang),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.addPlaylistHint(lang),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return _PlaylistCard(source: source);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const AddPlaylistDialog(),
    );
  }

}

class _AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Text(
                'IPTV Player',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.video_library,
              title: S.playlists(lang),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            _DrawerItem(
              icon: Icons.star_outline,
              title: S.favorites(lang),
              onTap: () {
                Navigator.pop(context);
                context.go('/favorites');
              },
            ),
            _DrawerItem(
              icon: Icons.download_outlined,
              title: S.downloads(lang),
              onTap: () {
                Navigator.pop(context);
                context.go('/downloads');
              },
            ),
            _DrawerItem(
              icon: Icons.fiber_manual_record_outlined,
              title: S.recordings(lang),
              onTap: () {
                Navigator.pop(context);
                context.go('/recordings');
              },
            ),
            _DrawerItem(
              icon: Icons.schedule,
              title: 'EPG',
              onTap: () {
                Navigator.pop(context);
                context.go('/epg');
              },
            ),
            _DrawerItem(
              icon: Icons.settings,
              title: S.settings(lang),
              selected: false,
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'IPTV Player © 2026',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: Colors.deepPurple.withValues(alpha: 0.2),
        leading: Icon(icon, color: selected ? Colors.deepPurple.shade200 : Colors.grey.shade400),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final PlaylistSource source;
  const _PlaylistCard({required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: source.isActive
            ? BorderSide(color: Colors.deepPurple.shade300, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: source.isActive ? Colors.deepPurple : Colors.grey.shade800,
          child: Icon(
            source.type == PlaylistType.xtreamCodes ? Icons.dns : Icons.link,
            color: Colors.white,
          ),
        ),
        title: Text(
          source.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          source.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (source.isActive)
              Chip(
                label: const Text('Active', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.deepPurple.shade800,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _onMenuAction(value, context, ref),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'activate', child: Text('Set Active')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () {
          ref.read(playlistSourcesProvider.notifier).setActive(source);
          final organizeByGroups = ref.read(organizeByGroupsProvider);
          if (organizeByGroups) {
            context.go('/groups');
          } else {
            ref.read(selectedCategoryProvider.notifier).state = null;
            context.go('/channels');
          }
        },
      ),
    );
  }

  void _onMenuAction(String action, BuildContext context, WidgetRef ref) {
    switch (action) {
      case 'activate':
        ref.read(playlistSourcesProvider.notifier).setActive(source);
        break;
      case 'delete':
        ref.read(playlistSourcesProvider.notifier).remove(source);
        break;
    }
  }
}
