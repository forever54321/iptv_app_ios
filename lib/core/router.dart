import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/legal/legal_disclaimer_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/channels/channels_screen.dart';
import '../screens/player/player_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/recent/recent_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/settings/parental_control_screen.dart';
import '../screens/player/local_player_screen.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/recordings/recordings_screen.dart';
import '../screens/whats_new/whats_new_screen.dart';
import '../screens/epg/epg_screen.dart';
import '../screens/paywall/paywall_screen.dart';
import '../providers/pro_provider.dart';

class ProGate extends ConsumerWidget {
  final Widget child;
  const ProGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(isProProvider) ? child : const PaywallScreen();
  }
}

GoRouter createRouter(bool disclaimerAccepted, bool showWhatsNew) {
  String initialLocation;
  if (!disclaimerAccepted) {
    initialLocation = '/';
  } else if (showWhatsNew) {
    initialLocation = '/whats-new';
  } else {
    initialLocation = '/home';
  }

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LegalDisclaimerScreen(),
      ),
      GoRoute(
        path: '/whats-new',
        builder: (context, state) => const WhatsNewScreen(isStartup: true),
      ),
      GoRoute(
        path: '/whats-new-settings',
        builder: (context, state) => const WhatsNewScreen(isStartup: false),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/channels',
        builder: (context, state) => const ChannelsScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialIndex = extra?['initialIndex'] as int? ?? 0;
          return PlayerScreen(initialChannelIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/recent',
        builder: (context, state) => const RecentScreen(),
      ),
      GoRoute(
        path: '/local-player',
        builder: (context, state) {
          final filePath = state.extra as String? ?? '';
          return LocalPlayerScreen(filePath: filePath);
        },
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/recordings',
        builder: (context, state) =>
            const ProGate(child: RecordingsScreen()),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) =>
            const ProGate(child: FavoritesScreen()),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/parental',
        builder: (context, state) =>
            const ProGate(child: ParentalControlScreen()),
      ),
      GoRoute(
        path: '/epg',
        builder: (context, state) => const ProGate(child: EpgScreen()),
      ),
    ],
  );
}
