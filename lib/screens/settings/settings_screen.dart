import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../providers/channel_list_provider.dart';
import '../../services/playlist_fetch_service.dart';
import '../../providers/recent_channels_provider.dart';
import '../../providers/pro_provider.dart';
import '../../services/epg_service.dart';
import '../../services/pro_service.dart';
import '../../providers/epg_provider.dart';

// Settings providers
final recentChannelsProvider = StateProvider<bool>((ref) => true);
final organizeByGroupsProvider = StateProvider<bool>((ref) => true);
final parentalControlProvider = StateProvider<bool>((ref) => false);
final defaultAspectRatioProvider = StateProvider<String>((ref) => '16:9');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(recentChannelsProvider.notifier).state =
        prefs.getBool('recent_channels') ?? true;
    ref.read(organizeByGroupsProvider.notifier).state =
        prefs.getBool('organize_by_groups') ?? true;
    final hasPin = prefs.getString('parental_pin');
    ref.read(parentalControlProvider.notifier).state = hasPin != null && hasPin.isNotEmpty;
    ref.read(defaultAspectRatioProvider.notifier).state =
        prefs.getString('aspect_ratio') ?? '16:9';
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final recentChannels = ref.watch(recentChannelsProvider);
    final organizeByGroups = ref.watch(organizeByGroupsProvider);
    final parentalControl = ref.watch(parentalControlProvider);
    final aspectRatio = ref.watch(defaultAspectRatioProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(S.settings(lang)),
      ),
      body: ListView(
        children: [
          _buildProSection(context),
          _buildSectionHeader(S.playback(lang)),
          _buildSwitchTile(
            icon: Icons.history,
            title: S.recentChannels(lang),
            value: recentChannels,
            onChanged: (v) {
              ref.read(recentChannelsProvider.notifier).state = v;
              _saveBool('recent_channels', v);
            },
          ),
          _buildActionTile(
            icon: Icons.clear_all,
            title: S.clearHistory(lang),
            onTap: () {
              ref.read(recentChannelsListProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${S.clearHistory(lang)} ✓')),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.aspect_ratio,
            title: S.aspectRatio(lang),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                aspectRatio,
                style: const TextStyle(color: Colors.deepPurple, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            onTap: () => _showAspectRatioDialog(context),
          ),
          _buildSectionHeader(S.channelList(lang)),
          _buildSwitchTile(
            icon: Icons.folder_outlined,
            title: S.groupByCategories(lang),
            value: organizeByGroups,
            onChanged: (v) {
              ref.read(organizeByGroupsProvider.notifier).state = v;
              _saveBool('organize_by_groups', v);
            },
          ),
          _buildNavigationTile(
            icon: Icons.language,
            title: S.appLanguage(lang),
            subtitle: lang.displayName,
            onTap: () => _showLanguagePicker(context),
          ),
          _buildSectionHeader(S.security(lang)),
          _buildNavigationTile(
            icon: Icons.shield_outlined,
            title: S.parentalControl(lang),
            subtitle: parentalControl ? 'PIN enabled' : 'Off',
            onTap: () => context.go('/parental'),
          ),
          _buildSectionHeader('EPG / PROGRAM GUIDE'),
          _buildNavigationTile(
            icon: Icons.schedule,
            title: 'EPG URL',
            subtitle: 'Auto-detected from playlist',
            onTap: () => _showEpgUrlDialog(context),
          ),
          _buildActionTile(
            icon: Icons.refresh,
            title: 'Refresh EPG Now',
            onTap: () {
              ref.read(epgProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing EPG data...')),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.delete_outline,
            title: 'Clear EPG Cache',
            onTap: () async {
              await EpgService.clearCache();
              ref.invalidate(epgProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('EPG cache cleared')),
                );
              }
            },
          ),
          _buildSectionHeader(S.storage(lang)),
          _buildActionTile(
            icon: Icons.cleaning_services_outlined,
            title: S.clearPlaylistsCache(lang),
            onTap: () {
              PlaylistFetchService.clearCache();
              ref.invalidate(channelListProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${S.clearPlaylistsCache(lang)} ✓')),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.image_not_supported_outlined,
            title: S.clearImagesCache(lang),
            onTap: () async {
              await DefaultCacheManager().emptyCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${S.clearImagesCache(lang)} ✓')),
                );
              }
            },
          ),
          _buildSectionHeader('PURCHASES'),
          if (!ref.watch(isProProvider))
            _buildActionTile(
              icon: Icons.local_offer,
              title: 'Redeem Promo Code',
              onTap: () => _showPromoCodeDialog(context),
            ),
          _buildActionTile(
            icon: Icons.restore,
            title: 'Restore Purchase',
            onTap: () async {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restoring…'),
                  duration: Duration(seconds: 2),
                ),
              );
              await ProService.instance.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                if (ref.read(isProProvider)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pro restored ✓')),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Restore Result'),
                      content: Text(ProService.instance.diagnosticMessage()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
          _buildSectionHeader(S.about(lang)),
          _buildNavigationTile(
            icon: Icons.celebration,
            title: "What's New",
            subtitle: 'See new features in v4.1',
            onTap: () => context.go('/whats-new-settings'),
          ),
          _buildNavigationTile(
            icon: Icons.info_outline,
            title: 'IPTV Stream Player',
            subtitle: 'Version 4.1.2',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'IPTV Stream Player',
                applicationVersion: '4.1.2',
                applicationLegalese: '© 2026 IPTV App. All rights reserved.',
              );
            },
          ),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: S.termsOfUse(lang),
            onTap: () => context.go('/'),
          ),
          _buildNavigationTile(
            icon: Icons.privacy_tip_outlined,
            title: S.privacyPolicy(lang),
            onTap: () => context.go('/privacy'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _showPromoCodeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Promo Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty || !context.mounted) return;

    final ok = await ProService.instance.redeemPromoCode(code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Pro unlocked ✓'
            : 'That code is not valid or has expired.'),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final currentLang = ref.read(appLanguageProvider);
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.appLanguage(currentLang),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...AppLanguage.values.map((lang) => ListTile(
                  leading: Icon(
                    lang == currentLang ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: lang == currentLang ? Colors.deepPurple : Colors.grey,
                  ),
                  title: Text(lang.displayName),
                  subtitle: Text(lang.code.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  onTap: () {
                    ref.read(appLanguageProvider.notifier).setLanguage(lang);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildProSection(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final product = ProService.instance.product;
    final price = product?.price ?? '\$3.99';

    if (isPro) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade800, Colors.purple.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pro Unlocked — thank you!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/paywall'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purpleAccent.shade400,
                  Colors.deepPurple.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unlock Pro',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        'EPG · Recording · Favorites · Parental Lock — $price one-time',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.deepPurple.shade300,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SwitchListTile(
          secondary: Icon(icon, color: Colors.deepPurple.shade200),
          title: Text(title),
          value: value,
          onChanged: onChanged,
          activeColor: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.deepPurple.shade200),
          title: Text(title),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.deepPurple.shade200),
          title: Text(title),
          subtitle: subtitle != null
              ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
              : null,
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showEpgUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    EpgService.getManualUrl().then((url) {
      controller.text = url ?? '';
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('EPG URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave empty to auto-detect from playlist header.\nOr enter a custom XMLTV EPG URL:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://example.com/epg.xml',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              await EpgService.setManualUrl(url.isEmpty ? null : url);
              ref.invalidate(epgUrlProvider);
              ref.invalidate(epgProvider);
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/epg');
              }
            },
            child: const Text('Save & Open EPG'),
          ),
        ],
      ),
    );
  }

  void _showAspectRatioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(S.aspectRatio(ref.read(appLanguageProvider))),
        children: ['16:9', '4:3', 'Fill', 'Fit'].map((ratio) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(defaultAspectRatioProvider.notifier).state = ratio;
              _saveString('aspect_ratio', ratio);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(ratio, style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
