import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/category_filter_provider.dart';
import 'providers/channel_list_provider.dart';
import 'providers/search_provider.dart';
import 'services/reminder_service.dart';
import 'core/router.dart';
import 'core/theme.dart';

class IptvApp extends StatefulWidget {
  final bool disclaimerAccepted;
  final bool showWhatsNew;
  const IptvApp({super.key, required this.disclaimerAccepted, this.showWhatsNew = false});

  @override
  State<IptvApp> createState() => _IptvAppState();
}

class _IptvAppState extends State<IptvApp> {
  late final _router = createRouter(widget.disclaimerAccepted, widget.showWhatsNew);

  @override
  void initState() {
    super.initState();
    // Tapping a program reminder opens that channel. Runs after the first
    // frame so the router and providers exist (also replays a tap that
    // launched the app from closed).
    ReminderService.instance.onOpenChannel = _openChannel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.disclaimerAccepted) ReminderService.instance.consumeLaunchTap();
    });
  }

  Future<void> _openChannel(String url) async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final channels = await container.read(channelListProvider.future);
    final idx = channels.indexWhere((c) => c.url == url);
    if (idx < 0 || !mounted) return;
    // The player indexes into the FILTERED list — clear filters so it's the full list.
    container.read(selectedCategoryProvider.notifier).state = null;
    container.read(searchQueryProvider.notifier).state = '';
    container.read(debouncedSearchProvider.notifier).state = '';
    _router.go('/player', extra: {'initialIndex': idx});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IPTV Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
