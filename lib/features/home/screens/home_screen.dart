import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/container_model.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../../../widgets/common/neon_text.dart';

final selectedContainerProvider = StateProvider<ContainerModel>((ref) => containerCatalog.first);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  bool _showDailyBanner = false;
  double _dailyCoins = 0;
  int _dailyGems = 0;
  int _dailyStreak = 0;

  @override
  void initState() {
    super.initState();
    // Refresh timer ogni secondo per il countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Check daily bonus after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyBonus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkDailyBonus() async {
    final result = await sl<PlayerService>().claimDailyBonus();
    if (result.success && mounted) {
      ref.read(playerNotifierProvider.notifier).refresh();
      setState(() {
        _showDailyBanner = true;
        _dailyCoins = result.coins;
        _dailyGems = result.gems;
        _dailyStreak = result.streak;
      });
      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showDailyBanner = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedContainerProvider);
    final color = _hexToColor(selected.colorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent]),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 3000.ms),
          ),

          Column(
            children: [
              // Hero
              Expanded(flex: 6, child: _ContainerHero(container: selected, color: color)),
              // Open button
              _OpenButton(container: selected, color: color),
              const SizedBox(height: 12),
              // Container selector
              SizedBox(height: 108, child: _ContainerSelector()),
              const SizedBox(height: 8),
            ],
          ),

          // Daily bonus banner
          if (_showDailyBanner)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _DailyBonusBanner(
                coins: _dailyCoins, gems: _dailyGems, streak: _dailyStreak,
                onDismiss: () => setState(() => _showDailyBanner = false),
              ),
            ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('ff$h', radix: 16));
  }
}

// ─── Daily Bonus Banner ───────────────────────────────────────────────────────

class _DailyBonusBanner extends StatelessWidget {
  final double coins;
  final int gems;
  final int streak;
  final VoidCallback onDismiss;
  const _DailyBonusBanner({required this.coins, required this.gems, required this.streak, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.neonGold.withOpacity(0.9), AppColors.neonOrange.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.neonGold.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('BONUS GIORNALIERO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('Giorno $streak 🔥', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '+${_fmt(coins)}€  ·  +$gems 💎',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onDismiss, icon: const Icon(Icons.close, color: Colors.black54, size: 20)),
            ],
          ),
        ).animate().slideY(begin: -1, end: 0, curve: Curves.bounceOut, duration: 600.ms),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Container Hero ───────────────────────────────────────────────────────────

class _ContainerHero extends ConsumerWidget {
  final ContainerModel container;
  final Color color;
  const _ContainerHero({required this.container, required this.color});

  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji = _emojis[container.id] ?? '📦';
    final playerAsync = ref.watch(playerNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Container box
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withOpacity(0.25), color.withOpacity(0.05), Colors.transparent,
                  ]),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2000.ms),

              Container(
                width: 165, height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
              ),

              GestureDetector(
                onTap: () => context.push('/open/${container.id}'),
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
                    ),
                    border: Border.all(color: color.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.5), blurRadius: 30, spreadRadius: 4),
                      BoxShadow(color: color.withOpacity(0.2), blurRadius: 60, spreadRadius: 10),
                    ],
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1800.ms),
              ),
            ],
          ),

          const SizedBox(height: 16),

          NeonText(container.name, color: color, fontSize: 22, fontWeight: FontWeight.w900, blurRadius: 14)
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 4),
          Text(container.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),

          // Free container timer
          if (container.isFree) ...[
            const SizedBox(height: 10),
            playerAsync.when(
              data: (p) => p.canClaimFreeContainer
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.neonGreen.withOpacity(0.6)),
                      ),
                      child: const Text('✅ Disponibile adesso!',
                          style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 12)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Prossimo tra: ${_fmtDuration(p.freeContainerCooldown)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],

          const SizedBox(height: 10),

          // Rarity pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RarityPill('COMUNE', AppColors.common),
                const SizedBox(width: 6),
                _RarityPill('NON COM.', AppColors.uncommon),
                const SizedBox(width: 6),
                _RarityPill('RARO', AppColors.rare),
                const SizedBox(width: 6),
                _RarityPill('EPICO', AppColors.epic),
                const SizedBox(width: 6),
                _RarityPill('LEGG.', AppColors.legendary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _RarityPill extends StatelessWidget {
  final String label;
  final Color color;
  const _RarityPill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ─── Open Button ──────────────────────────────────────────────────────────────

class _OpenButton extends ConsumerWidget {
  final ContainerModel container;
  final Color color;
  const _OpenButton({required this.container, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = container.isFree ? '🔓   APRI GRATIS' : '🔓   APRI · ${_fmt(container.cost)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/open/${container.id}'),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withOpacity(0.15), Colors.transparent],
                      stops: const [0.3, 0.5, 0.7],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2)),
              ),
              Text(label, style: TextStyle(
                color: _isDark(color) ? Colors.white : Colors.black,
                fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2,
              )),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  bool _isDark(Color c) => (c.red * 299 + c.green * 587 + c.blue * 114) / 1000 < 128;
  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(v >= 10e6 ? 0 : 1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

// ─── Container Selector ───────────────────────────────────────────────────────

class _ContainerSelector extends ConsumerWidget {
  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedContainerProvider);
    final scrollCtrl = ScrollController();

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ListView.separated(
            controller: scrollCtrl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 32, 4),
            itemCount: containerCatalog.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = containerCatalog[i];
              final isSelected = c.id == selected.id;
              final color = _hexToColor(c.colorHex);
              final emoji = _emojis[c.id] ?? '📦';

              return GestureDetector(
                onTap: () => ref.read(selectedContainerProvider.notifier).state = c,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isSelected
                        ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [color.withOpacity(0.25), color.withOpacity(0.08)])
                        : null,
                    color: isSelected ? null : AppColors.surface,
                    border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, spreadRadius: 1)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(c.name.split(' ').first,
                          style: TextStyle(
                              color: isSelected ? color : AppColors.textMuted,
                              fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(c.isFree ? 'FREE' : _fmt(c.cost),
                          style: TextStyle(
                              color: c.isFree ? AppColors.neonGreen : (isSelected ? color : AppColors.textMuted),
                              fontSize: 8, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Freccia sinistra
        Positioned(left: 0, top: 0, bottom: 0,
          child: GestureDetector(
            onTap: () => scrollCtrl.animateTo(
              (scrollCtrl.offset - 100).clamp(0, scrollCtrl.position.maxScrollExtent),
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
            ),
            child: Container(
              width: 32,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [AppColors.background, AppColors.background.withOpacity(0)],
              )),
              child: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
        ),

        // Freccia destra
        Positioned(right: 0, top: 0, bottom: 0,
          child: GestureDetector(
            onTap: () => scrollCtrl.animateTo(
              (scrollCtrl.offset + 100).clamp(0, scrollCtrl.position.maxScrollExtent),
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
            ),
            child: Container(
              width: 32,
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [AppColors.background.withOpacity(0), AppColors.background],
              )),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('ff$h', radix: 16));
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}
