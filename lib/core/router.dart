import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/channels/channels_screen.dart';
import '../screens/player/player_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
  ],
);
