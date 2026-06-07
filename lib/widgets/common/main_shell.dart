import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'currency_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: '🏠', label: 'Home', path: '/'),
    _TabItem(icon: '📦', label: 'Inventory', path: '/inventory'),
    _TabItem(icon: '🛒', label: 'Shop', path: '/shop'),
    _TabItem(icon: '⬆️', label: 'Upgrades', path: '/upgrades'),
    _TabItem(icon: '📋', label: 'Missions', path: '/missions'),
    _TabItem(icon: '📚', label: 'Collection', path: '/collection'),
    _TabItem(icon: '🏆', label: 'Ranking', path: '/leaderboard'),
    _TabItem(icon: '👤', label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(String location) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _currentIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CurrencyBar(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBackground,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isActive ? AppColors.neonCyan : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab.icon,
                            style: TextStyle(
                              fontSize: isActive ? 20 : 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tab.label,
                            style: TextStyle(
                              color: isActive ? AppColors.neonCyan : AppColors.textMuted,
                              fontSize: 8,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.normal,
                              shadows: isActive
                                  ? [const Shadow(color: AppColors.neonCyan, blurRadius: 6)]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
