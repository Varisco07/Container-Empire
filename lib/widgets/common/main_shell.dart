import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'currency_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,          label: 'Home',       path: '/',            color: Color(0xFF39FF14)),
    _TabItem(icon: Icons.inventory_2_rounded,    label: 'Inventario', path: '/inventory',   color: Color(0xFF00F5FF)),
    _TabItem(icon: Icons.storefront_rounded,     label: 'Shop',       path: '/shop',        color: Color(0xFFFFD700)),
    _TabItem(icon: Icons.rocket_launch_rounded,  label: 'Upgrade',    path: '/upgrades',    color: Color(0xFFFF6B00)),
    _TabItem(icon: Icons.task_alt_rounded,       label: 'Missioni',   path: '/missions',    color: Color(0xFFA855F7)),
    _TabItem(icon: Icons.swap_horiz_rounded,     label: 'Trade',      path: '/trade',       color: Color(0xFFFFD700)),
    _TabItem(icon: Icons.shield_rounded,         label: 'Clan',       path: '/clan',        color: Color(0xFFFF0080)),
    _TabItem(icon: Icons.leaderboard_rounded,    label: 'Ranking',    path: '/leaderboard', color: Color(0xFF00F5FF)),
    _TabItem(icon: Icons.person_rounded,         label: 'Profilo',    path: '/profile',     color: Color(0xFFA855F7)),
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
      bottomNavigationBar: _GameBottomNav(
        tabs: _tabs,
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _GameBottomNav extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GameBottomNav({required this.tabs, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF080C18), Color(0xFF050810)],
        ),
        border: const Border(top: BorderSide(color: Color(0xFF1E2A40), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              final color = tab.color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: isActive
                          ? Border(top: BorderSide(color: color, width: 2.5))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 38 : 34,
                          height: isActive ? 30 : 26,
                          decoration: BoxDecoration(
                            color: isActive ? color.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)] : null,
                          ),
                          child: Icon(tab.icon,
                            size: isActive ? 18 : 16,
                            color: isActive ? color : const Color(0xFF3A4558),
                            shadows: isActive ? [Shadow(color: color.withOpacity(0.8), blurRadius: 10)] : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isActive ? color : const Color(0xFF3A4558),
                            fontSize: isActive ? 8 : 7,
                            fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                            letterSpacing: isActive ? 0.3 : 0,
                            shadows: isActive ? [Shadow(color: color.withOpacity(0.6), blurRadius: 6)] : null,
                          ),
                          child: Text(tab.label),
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
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  final Color color;
  const _TabItem({required this.icon, required this.label, required this.path, required this.color});
}
