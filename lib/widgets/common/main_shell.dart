import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'currency_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,        emoji: '🏠', label: 'Home',       path: '/'),
    _TabItem(icon: Icons.location_city_rounded, emoji: '🌆', label: 'Impero',   path: '/empire'),
    _TabItem(icon: Icons.inventory_2_rounded, emoji: '📦', label: 'Inventario', path: '/inventory'),
    _TabItem(icon: Icons.swap_horiz_rounded,  emoji: '🔄', label: 'Trade',      path: '/trade'),
    _TabItem(icon: Icons.person_rounded,      emoji: '👤', label: 'Profilo',    path: '/profile'),
  ];

  String _location(BuildContext context) => GoRouterState.of(context).uri.toString();

  int _currentIndex(String loc) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (loc == _tabs[i].path || loc.startsWith('${_tabs[i].path}/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location     = _location(context);
    final currentIndex = _currentIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CurrencyBar(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        tabs: _tabs,
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatefulWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.tabs, required this.currentIndex, required this.onTap});

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _pillCtrl;

  @override
  void initState() {
    super.initState();
    _pillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _pillCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_BottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _pillCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.tabs.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, -6)),
          BoxShadow(color: AppColors.neonCyan.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Stack(
            children: [
              // ── Tab items ───────────────────────────────────────────
              Row(
                children: List.generate(count, (i) {
                  final isActive = i == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: _NavItem(
                        tab: widget.tabs[i],
                        isActive: isActive,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  const _NavItem({required this.tab, required this.isActive});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    if (widget.isActive) _scaleCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _scaleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.neonCyan : AppColors.textMuted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: widget.isActive ? 1.0 + _scaleAnim.value * 0.12 : 1.0,
            child: child,
          ),
          child: Icon(widget.tab.icon, size: 22, color: color),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: color,
            fontSize: widget.isActive ? 10 : 9,
            fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w400,
            letterSpacing: widget.isActive ? 0.3 : 0,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          child: Text(widget.tab.label),
        ),
        const SizedBox(height: 3),
        // Dot indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isActive ? 18 : 0,
          height: 2.5,
          decoration: BoxDecoration(
            color: AppColors.neonCyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: widget.isActive
                ? [BoxShadow(color: AppColors.neonCyan.withOpacity(0.6), blurRadius: 6)]
                : null,
          ),
        ),
      ],
    );
  }
}

class _TabItem {
  final IconData icon;
  final String emoji;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.emoji, required this.label, required this.path});
}
