import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IPTV Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
