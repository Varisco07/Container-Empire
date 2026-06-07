import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/screens/home_screen.dart';
import '../features/container_opening/screens/container_opening_screen.dart';
import '../features/inventory/screens/inventory_screen.dart';
import '../features/shop/screens/shop_screen.dart';
import '../features/upgrades/screens/upgrades_screen.dart';
import '../features/missions/screens/missions_screen.dart';
import '../features/collection/screens/collection_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../widgets/common/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
          GoRoute(path: '/upgrades', builder: (_, __) => const UpgradesScreen()),
          GoRoute(path: '/missions', builder: (_, __) => const MissionsScreen()),
          GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/open/:containerId',
        builder: (context, state) => ContainerOpeningScreen(
          containerId: state.pathParameters['containerId']!,
        ),
      ),
    ],
  );
});
