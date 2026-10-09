import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/parental_pin_service.dart';
import '../../services/reminder_service.dart';
import '../epg/epg_screen.dart' show showProgramReminderPicker;
import '../../l10n/app_strings.dart';
import '../../providers/channel_list_provider.dart';
import '../../services/playlist_fetch_service.dart';
import '../../providers/recent_channels_provider.dart';
import '../../providers/pro_provider.dart';
import '../../services/epg_service.dart';
import '../../services/pro_service.dart';
import '../../providers/epg_provider.dart';
import '../../widgets/readable_width.dart';

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
  String _playlistSize = '';
  String _epgSize = '';
  String _imageSize = '';
  String _version = '';
  int? _reminderLead;

  @override
  void initState() {
    super.initState();
    _refreshSizes();
    ReminderService.instance.leadMinutes().then((m) {
      if (mounted) setState(() => _reminderLead = m);
    });
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    });
  }

  static String _fmt(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    final mb = bytes / (1024 * 1024);
    return mb < 10 ? '${mb.toStringAsFixed(1)} MB' : '${mb.round()} MB';
  }

  static Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is File) {
        try { total += await e.length(); } catch (_) {}
      }
    }
    return total;
  }

  Future<void> _refreshSizes() async {
    final epg = await EpgService.cacheSizeBytes();
    final tmp = await getTemporaryDirectory();
    final images = await _dirSize(Directory('${tmp.path}/${DefaultCacheManager.key}'));
    if (!mounted) return;
    setState(() {
      _playlistSize = _fmt(PlaylistFetchService.cacheSizeBytes);
      _epgSize = _fmt(epg);
      _imageSize = _fmt(images);
    });
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
      body: ReadableWidth(child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildProSection(context),
          _header(S.generalSettings(lang)),
          _row(
            icon: Icons.history,
            title: S.recentChannels(lang),
            trailing: _switch(recentChannels, (v) {
              ref.read(recentChannelsProvider.notifier).state = v;
              _saveBool('recent_channels', v);
            }),
          ),
          _row(
            icon: Icons.cleaning_services_outlined,
            title: S.clearRecentData(lang),
            onTap: () async {
              final ok = await _confirm(context, S.clearRecentData(lang));
              if (!ok || !context.mounted) return;
              ref.read(recentChannelsListProvider.notifier).clear();
              _toast(context, '${S.clearRecentData(lang)} ✓');
            },
          ),
          _row(
            icon: Icons.folder_outlined,
            title: S.organizeByGroups(lang),
            trailing: _switch(organizeByGroups, (v) {
              ref.read(organizeByGroupsProvider.notifier).state = v;
              _saveBool('organize_by_groups', v);
            }),
          ),
          _row(
            icon: Icons.grid_view_outlined,
            title: S.epgSettings(lang),
            trailing: _chevron(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EpgSettingsScreen()),
            ),
          ),
          _row(
            icon: Icons.language,
            title: S.appLanguage(lang),
            value: lang.displayName,
            trailing: _chevron(),
            onTap: () => _showLanguagePicker(context),
          ),
          _row(
            icon: Icons.lock_outline,
            title: S.parentalControl(lang),
            // The switch opens the PIN screen either way: turning it on needs a
            // PIN to be set, turning it off must not happen without the PIN.
            trailing: _switch(parentalControl, (_) => _openParental(context)),
            onTap: () => _openParental(context),
          ),
          if (ReminderService.supported)
            _row(
              icon: Icons.notifications_none,
              title: 'Program reminder',
              value: ReminderTiming.label(_reminderLead),
              onTap: () async {
                final m = await showProgramReminderPicker(context, current: _reminderLead);
                if (m == _reminderLead) return;
                await ReminderService.instance.setLeadMinutes(m);
                if (m != null) await ReminderService.instance.requestPermission();
                if (mounted) setState(() => _reminderLead = m);
              },
            ),
          _header(S.playerSettings(lang)),
          _row(
            icon: Icons.aspect_ratio,
            title: S.aspectRatio(lang),
            value: aspectRatio,
            onTap: () => _showAspectRatioDialog(context),
          ),
          _header(S.cacheSection(lang)),
          _row(
            icon: Icons.delete_outline,
            title: S.clearPlaylistsCache(lang),
            value: _playlistSize,
            onTap: () {
              PlaylistFetchService.clearCache();
              ref.invalidate(channelListProvider);
              _refreshSizes();
              _toast(context, '${S.clearPlaylistsCache(lang)} ✓');
            },
          ),
          _row(
            icon: Icons.delete_outline,
            title: S.clearEpgCache(lang),
            value: _epgSize,
            onTap: () async {
              await EpgService.clearCache();
              ref.invalidate(epgProvider);
              await _refreshSizes();
              if (context.mounted) _toast(context, '${S.clearEpgCache(lang)} ✓');
            },
          ),
          _row(
            icon: Icons.delete_outline,
            title: S.clearImagesCache(lang),
            value: _imageSize,
            onTap: () async {
              await DefaultCacheManager().emptyCache();
              await _refreshSizes();
              if (context.mounted) _toast(context, '${S.clearImagesCache(lang)} ✓');
            },
          ),
          _header(S.more(lang)),
          _row(
            icon: Icons.help_outline,
            title: S.customerSupport(lang),
            trailing: _chevron(),
            onTap: () => _contactSupport(context),
          ),
          if (!ref.watch(isProProvider))
            _row(
              icon: Icons.local_offer_outlined,
              title: 'Redeem Promo Code',
              trailing: _chevron(),
              onTap: () => _showPromoCodeDialog(context),
            ),
          _row(
            icon: Icons.restore,
            title: 'Restore Purchase',
            onTap: () => _restorePurchase(context),
          ),
          _row(
            icon: Icons.celebration_outlined,
            title: "What's New",
            trailing: _chevron(),
            onTap: () => context.go('/whats-new-settings'),
          ),
          _row(
            icon: Icons.description_outlined,
            title: S.termsOfUse(lang),
            trailing: _chevron(),
            onTap: () => context.go('/'),
          ),
          _row(
            icon: Icons.privacy_tip_outlined,
            title: S.privacyPolicy(lang),
            trailing: _chevron(),
            onTap: () => context.go('/privacy'),
          ),
          _row(
            icon: Icons.info_outline,
            title: S.about(lang),
            value: _version.isEmpty ? '' : 'v$_version',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'IPTV Stream Player',
              applicationVersion: _version,
              applicationLegalese: '© 2026 IPTV App. All rights reserved.',
            ),
          ),
        ],
      )),
    );
  }

  // ── actions ──────────────────────────────────────────────────────────

  Future<void> _openParental(BuildContext context) async {
    await context.push('/parental');
    final hasPin = await ParentalPinService.hasPin();
    if (mounted) ref.read(parentalControlProvider.notifier).state = hasPin;
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'IPTV@zakari.me',
      queryParameters: {'subject': 'IPTV Stream Player support (v$_version)'},
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      _toast(context, 'Email us at IPTV@zakari.me');
    }
  }

  Future<void> _restorePurchase(BuildContext context) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    _toast(context, 'Restoring…');
    await ProService.instance.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    if (ref.read(isProProvider)) {
      _toast(context, 'Pro restored ✓');
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore Result'),
          content: Text(ProService.instance.diagnosticMessage()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _confirm(BuildContext context, String title) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$title?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.cancel(ref.read(appLanguageProvider)))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
        ],
      ),
    );
    return r ?? false;
  }

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ── row styling (matches the reference: dark rounded rows, grey values) ──

  static const _rowColor = Color(0xFF141416);
  static const _accent = Color(0xFF1E9BFF);

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _chevron() => Icon(Icons.chevron_right, color: Colors.grey.shade600);

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: _accent,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF3A3A3C),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      );

  Widget _row({
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: _rowColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey.shade400, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (value != null && value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Text(value, style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                    ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
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
    final price = product == null ? '' : ' — ${product.price} one-time';
    final pro = ProService.instance;

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
                        pro.isInTrial
                            ? '${ProTrial.label(pro.trialDaysLeft)} · tap to keep Pro$price'
                            : 'EPG · Recording · Favorites · Parental Lock$price',
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


/// Settings → EPG Settings: where the program guide comes from and refreshing it.
class EpgSettingsScreen extends ConsumerWidget {
  const EpgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    Widget row(IconData icon, String title, String? sub, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Material(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(icon, color: Colors.grey.shade400),
              title: Text(title),
              subtitle: sub == null ? null : Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
              onTap: onTap,
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(S.epgSettings(lang))),
      body: ReadableWidth(child: ListView(
        padding: const EdgeInsets.only(top: 12),
        children: [
          row(Icons.link, 'EPG URL', 'Auto-detected from playlist, or set your own', () => _editUrl(context, ref)),
          row(Icons.refresh, 'Refresh EPG Now', null, () {
            ref.read(epgProvider.notifier).refresh();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing EPG data...')));
          }),
          row(Icons.view_timeline_outlined, 'Open Program Guide', null, () => context.go('/epg')),
        ],
      )),
    );
  }

  Future<void> _editUrl(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: await EpgService.getManualUrl() ?? '');
    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('EPG URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave empty to auto-detect from the playlist header, or enter an XMLTV EPG URL:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'http://example.com/epg.xml',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final url = controller.text.trim();
    await EpgService.setManualUrl(url.isEmpty ? null : url);
    ref.invalidate(epgUrlProvider);
    ref.invalidate(epgProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EPG URL saved')));
    }
  }
}
