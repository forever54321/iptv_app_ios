import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel_category.dart';
import '../../providers/category_filter_provider.dart';
import '../../providers/channel_list_provider.dart';
import '../../services/playlist_fetch_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../providers/recent_channels_provider.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/parental_control_screen.dart';
import '../../widgets/loading_widget.dart';

import '../../models/m3u_entry.dart';

/// Classifies a group into Live, Movies, or Shows.
enum GroupSection { live, movies, shows }

/// Video file extensions that indicate VOD content (not live)
const _vodExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.m4v', '.mpg', '.mpeg', '.webm'];

/// Strip episode numbers/year/quality from a title to get the base show name.
/// "Breaking Bad S01E01 720p" → "breaking bad"
/// "The Matrix 2024 1080p" → "the matrix 2024 1080p" (stays unique)
String _extractBaseName(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[Ss]\d{1,2}\s?[Ee]\d{1,3}'), '')  // S01E01
      .replaceAll(RegExp(r'ep\.?\s?\d+', caseSensitive: false), '')  // Ep 01, Ep.5
      .replaceAll(RegExp(r'episode\s?\d+', caseSensitive: false), '')  // Episode 1
      .replaceAll(RegExp(r'season\s?\d+', caseSensitive: false), '')  // Season 1
      .replaceAll(RegExp(r'\s*[-|:]\s*$'), '')  // trailing separators
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Check if channels have many repeated base names (= shows)
/// or all unique names (= movies).
bool _hasRepeatedNames(List<M3uEntry> channels) {
  if (channels.length < 3) return false;

  final baseCounts = <String, int>{};
  for (final ch in channels) {
    final base = _extractBaseName(ch.title);
    if (base.isNotEmpty) {
      baseCounts[base] = (baseCounts[base] ?? 0) + 1;
    }
  }

  // Count how many channels share a base name with at least 1 other channel
  int repeatedCount = 0;
  for (final count in baseCounts.values) {
    if (count >= 2) repeatedCount += count;
  }

  // If >40% of channels share a base name → it's a shows group
  return repeatedCount / channels.length > 0.4;
}

/// Check if group content is VOD (not live)
bool _isVodContent(List<M3uEntry> channels) {
  if (channels.isEmpty) return false;
  int vodCount = 0;
  for (final ch in channels) {
    if (ch.duration > 0) vodCount++;
    final urlLower = ch.url.toLowerCase().split('?').first;
    if (_vodExtensions.any((ext) => urlLower.endsWith(ext))) vodCount++;
  }
  return vodCount / channels.length > 0.4;
}

/// Classify a group by analyzing its name AND channels inside it.
/// Key insight: Shows have repeated base names, Movies have unique names.
GroupSection classifyGroup(String name, List<M3uEntry> groupChannels) {
  final lower = name.toLowerCase();

  // ── Step 1: Clear name matches ──

  final isMovieName = lower.contains('movie') ||
      lower.contains('film') ||
      lower.contains('cinema');

  final isSeriesName = lower.contains('series') ||
      lower.contains('show') ||
      lower.contains('episode') ||
      lower.contains('season');

  final isVodName = lower.contains('vod') ||
      lower.contains('on demand') ||
      lower.contains('ondemand');

  // Clear movie name, not series → movies
  if (isMovieName && !isSeriesName) return GroupSection.movies;
  // Clear series name, not movie → shows
  if (isSeriesName && !isMovieName) return GroupSection.shows;

  // ── Step 2: VOD or ambiguous name → analyze channel content ──

  if (isVodName || (isMovieName && isSeriesName)) {
    if (_hasRepeatedNames(groupChannels)) return GroupSection.shows;
    return GroupSection.movies;
  }

  // ── Step 3: No name keywords → check if it's VOD at all ──

  if (groupChannels.isNotEmpty && _isVodContent(groupChannels)) {
    // It's VOD — check if shows or movies by name repetition
    if (_hasRepeatedNames(groupChannels)) return GroupSection.shows;
    return GroupSection.movies;
  }

  // ── Step 4: Default to Live ──
  return GroupSection.live;
}

// ──────────────────────────────────────────────
// SCREEN 1: Category Selector (Live / Movies / Shows / All)
// ──────────────────────────────────────────────

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelListProvider);
    final lang = ref.watch(appLanguageProvider);
    final recentEnabled = ref.watch(recentChannelsProvider);
    final recentChannels = ref.watch(recentChannelsListProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(S.groups(lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              PlaylistFetchService.clearCache();
              ref.invalidate(channelListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
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
            return Center(child: Text(S.noChannelsFound(lang)));
          }

          final categories = ref.watch(categoriesProvider);
          final groups = categories.where((c) => c.type == CategoryType.group).toList();

          // Build a map of group name → channels for smart classification
          final groupChannelsMap = <String, List<M3uEntry>>{};
          for (final ch in allChannels) {
            final g = ch.groupTitle ?? 'Uncategorized';
            (groupChannelsMap[g] ??= []).add(ch);
          }

          // Classify each group and cache the result
          final groupClassification = <String, GroupSection>{};
          for (final group in groups) {
            groupClassification[group.name] = classifyGroup(
              group.name,
              groupChannelsMap[group.name] ?? [],
            );
          }

          final liveCount = groups.where((g) => groupClassification[g.name] == GroupSection.live).fold<int>(0, (sum, g) => sum + g.channelCount);
          final movieCount = groups.where((g) => groupClassification[g.name] == GroupSection.movies).fold<int>(0, (sum, g) => sum + g.channelCount);
          final showCount = groups.where((g) => groupClassification[g.name] == GroupSection.shows).fold<int>(0, (sum, g) => sum + g.channelCount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Recent
              if (recentEnabled && recentChannels.isNotEmpty) ...[
                _CategoryCard(
                  icon: Icons.history,
                  title: 'Recent',
                  subtitle: '${recentChannels.length} channels',
                  color: Colors.orange,
                  onTap: () => context.go('/recent'),
                ),
                const SizedBox(height: 12),
              ],

              // EPG / Program Guide
              _CategoryCard(
                icon: Icons.schedule,
                title: 'Program Guide',
                subtitle: 'EPG - What\'s on now',
                color: Colors.blue,
                onTap: () => context.go('/epg'),
              ),
              const SizedBox(height: 12),

              // Live Channels
              _CategoryCard(
                icon: Icons.live_tv,
                title: 'Live Channels',
                subtitle: '$liveCount channels',
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SectionGroupsScreen(
                      key: const ValueKey('live'),
                      section: GroupSection.live,
                      title: 'Live Channels',
                      classification: groupClassification,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Movies
              _CategoryCard(
                icon: Icons.movie_outlined,
                title: 'Movies',
                subtitle: '$movieCount items',
                color: Colors.deepPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SectionGroupsScreen(
                      key: const ValueKey('movies'),
                      section: GroupSection.movies,
                      title: 'Movies',
                      classification: groupClassification,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Shows
              _CategoryCard(
                icon: Icons.tv,
                title: 'Shows',
                subtitle: '$showCount items',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SectionGroupsScreen(
                      key: const ValueKey('shows'),
                      section: GroupSection.shows,
                      title: 'Shows',
                      classification: groupClassification,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // All Channels
              _CategoryCard(
                icon: Icons.folder_outlined,
                title: S.allChannels(lang),
                subtitle: '${allChannels.length} total',
                color: Colors.blueGrey,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  context.go('/channels');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SCREEN 2: Groups within a section (Live / Movies / Shows)
// ──────────────────────────────────────────────

class _SectionGroupsScreen extends ConsumerStatefulWidget {
  final GroupSection section;
  final String title;
  final Map<String, GroupSection> classification;

  const _SectionGroupsScreen({
    super.key,
    required this.section,
    required this.title,
    required this.classification,
  });

  @override
  ConsumerState<_SectionGroupsScreen> createState() => _SectionGroupsScreenState();
}

class _SectionGroupsScreenState extends ConsumerState<_SectionGroupsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final groups = categories
        .where((c) => c.type == CategoryType.group && widget.classification[c.name] == widget.section)
        .toList();

    // Get all channels in this section for search
    final allChannels = ref.watch(channelListProvider).valueOrNull ?? [];
    final sectionGroupNames = groups.map((g) => g.name).toSet();
    final sectionChannels = allChannels
        .where((ch) => sectionGroupNames.contains(ch.groupTitle ?? 'Uncategorized'))
        .toList();

    // Search channels
    final isSearching = _searchQuery.isNotEmpty;
    final searchResults = isSearching
        ? sectionChannels.where((ch) {
            final q = _searchQuery.toLowerCase();
            return ch.title.toLowerCase().contains(q) ||
                (ch.tvgName?.toLowerCase().contains(q) ?? false);
          }).toList()
        : <M3uEntry>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Show search results or group list
          Expanded(
            child: isSearching
                ? _buildSearchResults(searchResults)
                : _buildGroupList(groups),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<M3uEntry> results) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No channels found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Find the index in the full filtered channels list for playback
    final allChannels = ref.watch(channelListProvider).valueOrNull ?? [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length > 200 ? 200 : results.length,
      itemBuilder: (context, index) {
        final channel = results[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: channel.tvgLogo != null && channel.tvgLogo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        channel.tvgLogo!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.live_tv, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.live_tv, color: Colors.grey),
              title: Text(channel.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                channel.groupTitle ?? '',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 1,
              ),
              onTap: () {
                // Find channel index in full list
                final idx = allChannels.indexWhere((c) => c.url == channel.url);
                if (idx >= 0) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  context.go('/player', extra: {'initialIndex': idx});
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupList(List<ChannelCategory> groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No groups found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final lockedGroups = ref.watch(parentalLockedGroupsProvider);
        final isLocked = lockedGroups.contains(group.name);

        return _GroupTile(
          icon: isLocked ? Icons.lock : Icons.folder_outlined,
          name: group.name,
          count: group.channelCount,
          isLocked: isLocked,
          onTap: () async {
            if (isLocked) {
              final unlocked = await _showPinDialog(context);
              if (!unlocked) return;
            }
            ref.read(selectedCategoryProvider.notifier).state = group;
            if (context.mounted) context.go('/channels');
          },
        );
      },
    );
  }

  Future<bool> _showPinDialog(BuildContext context) async {
    final pinCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Enter PIN'),
          ],
        ),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '• • • •',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final savedPin = prefs.getString('parental_pin');
              if (pinCtrl.text == savedPin) {
                Navigator.pop(context, true);
              } else {
                pinCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ──────────────────────────────────────────────
// Shared group tile widget
// ──────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final bool isLocked;
  final VoidCallback onTap;

  const _GroupTile({
    required this.icon,
    required this.name,
    required this.count,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: isLocked ? Colors.red.shade400 : Colors.grey.shade400),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatCount(count),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }
}
