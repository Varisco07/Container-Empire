import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/container_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

final selectedContainerProvider = StateProvider<ContainerModel>((ref) => containerCatalog.first);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;

  void _startTimerIfNeeded(bool isFree) {
    if (isFree && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!isFree) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedContainerProvider);
    _startTimerIfNeeded(selected.isFree);
    final color = _hexToColor(selected.colorHex);

    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: Stack(
        children: [
          // Deep gradient background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  color.withOpacity(0.18),
                  const Color(0xFF08040F).withOpacity(0.95),
                  const Color(0xFF030208),
                ],
              ),
            ),
          ),

          // Floating stars
          const _StarField(),

          // Main layout
          Column(
            children: [
              const SizedBox(height: 8),
              // Title
              _GameTitle(color: color),
              const SizedBox(height: 4),
              // Hero
              Expanded(
                child: _ContainerHero(
                  container: selected,
                  color: color,
                  glowCtrl: _glowCtrl,
                  floatCtrl: _floatCtrl,
                ),
              ),
              // Open button
              _OpenButton(container: selected, color: color),
              const SizedBox(height: 10),
              // Container selector
              SizedBox(height: 112, child: _ContainerSelector()),
              const SizedBox(height: 6),
            ],
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

// ─── Game title ───────────────────────────────────────────────────────────────

class _GameTitle extends StatelessWidget {
  final Color color;
  const _GameTitle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📦', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFF0A0), Color(0xFFFFD700)],
              stops: [0, 0.5, 1],
            ).createShader(bounds),
            child: const Text(
              'CONTAINER EMPIRE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('📦', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// ─── Container Hero ───────────────────────────────────────────────────────────

class _ContainerHero extends ConsumerWidget {
  final ContainerModel container;
  final Color color;
  final AnimationController glowCtrl;
  final AnimationController floatCtrl;
  const _ContainerHero({required this.container, required this.color,
      required this.glowCtrl, required this.floatCtrl});

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
          // Container box with game-style presentation
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              AnimatedBuilder(
                animation: glowCtrl,
                builder: (_, __) => Container(
                  width: 230 + glowCtrl.value * 12,
                  height: 230 + glowCtrl.value * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      color.withOpacity(0.0 + glowCtrl.value * 0.12),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              // Spinning orbit ring
              _OrbitRing(color: color),

              // Floating container box
              AnimatedBuilder(
                animation: floatCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -6 + floatCtrl.value * 12),
                  child: GestureDetector(
                    onTap: () => context.push('/open/${container.id}'),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow box
                        Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(color: color.withOpacity(0.7), blurRadius: 40, spreadRadius: 8),
                              BoxShadow(color: color.withOpacity(0.3), blurRadius: 80, spreadRadius: 20),
                            ],
                          ),
                        ),
                        // Main box
                        Container(
                          width: 148, height: 148,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.45),
                                color.withOpacity(0.15),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                            border: Border.all(color: color, width: 2.5),
                          ),
                          child: Stack(
                            children: [
                              // Shine overlay
                              Positioned(
                                top: 0, left: 0, right: 0,
                                child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                      colors: [Colors.white.withOpacity(0.18), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                              Center(child: Text(emoji, style: const TextStyle(fontSize: 70))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Corner dots (statici, no overhead)
              ..._buildCornerDots(color),
            ],
          ),

          const SizedBox(height: 14),

          // Container name — game style
          Text(
            container.name,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(color: color.withOpacity(0.9), blurRadius: 16),
                Shadow(color: color.withOpacity(0.4), blurRadius: 32),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            container.description,
            style: const TextStyle(color: Color(0xFF8BA4C0), fontSize: 11),
            textAlign: TextAlign.center,
          ),

          // Free countdown
          if (container.isFree) ...[
            const SizedBox(height: 10),
            playerAsync.when(
              data: (p) => p.canClaimFreeContainer
                  ? _GameBadge(text: '✅  DISPONIBILE ADESSO!', color: AppColors.neonGreen)
                  : _GameBadge(
                      text: '⏱  ${_fmtDuration(p.freeContainerCooldown)}',
                      color: AppColors.textMuted,
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            const SizedBox(height: 10),
          ],

          // Rarity badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RarityBadge('COMUNE',  AppColors.common),
                _RarityBadge('NON COM.', AppColors.uncommon),
                _RarityBadge('RARO',    AppColors.rare),
                _RarityBadge('EPICO',   AppColors.epic),
                _RarityBadge('LEGG.',   AppColors.legendary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDots(Color color) {
    const positions = [
      Offset(-86, -76), Offset(88, -72), Offset(-92, 58), Offset(90, 53),
    ];
    const sizes = [8.0, 10.0, 7.0, 9.0];
    return List.generate(positions.length, (i) => Positioned(
      left: 115 + positions[i].dx,
      top: 115 + positions[i].dy,
      child: Text('✦', style: TextStyle(
        color: color.withOpacity(0.7), fontSize: sizes[i],
        shadows: [Shadow(color: color, blurRadius: 6)],
      )),
    ));
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


class _OrbitRing extends StatefulWidget {
  final Color color;
  const _OrbitRing({required this.color});

  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<_OrbitRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * pi,
        child: Container(
          width: 195,
          height: 195,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 90,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
                  ),
                ),
              ),
              Positioned(
                bottom: 0, right: 88,
                child: Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.6),
                    boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _GameBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RarityBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.7), width: 1),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5,
      )),
    ),
  );
}

// ─── Open Button ──────────────────────────────────────────────────────────────

class _OpenButton extends ConsumerWidget {
  final ContainerModel container;
  final Color color;
  const _OpenButton({required this.container, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFree = container.isFree;
    final label = isFree ? 'APRI GRATIS' : 'APRI · ${_fmt(container.cost)}';
    final btnColor = isFree ? const Color(0xFF39FF14) : color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: () => context.push('/open/${container.id}'),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                btnColor,
                Color.lerp(btnColor, Colors.black, 0.35)!,
              ],
            ),
            boxShadow: [
              // 3D depth shadow
              BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 0, offset: const Offset(0, 5), spreadRadius: 0),
              BoxShadow(color: btnColor.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 4)),
              BoxShadow(color: btnColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 4),
            ],
            border: Border.all(color: btnColor.withOpacity(0.8), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top shine
              Positioned(
                top: 0, left: 12, right: 12,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Shimmer sweep
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(color: Colors.transparent)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.25)),
              ),
              // Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isFree ? '🔓' : '💰', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: _isDark(btnColor) ? Colors.white : Colors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.015, 1.015), duration: 1200.ms),
      ),
    );
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
    final playerAsync = ref.watch(playerNotifierProvider);
    final playerLevel = playerAsync.when(data: (p) => p.level, loading: () => 1, error: (_, __) => 1);
    final scrollCtrl = ScrollController();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: ListView.separated(
        controller: scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: containerCatalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = containerCatalog[i];
          final isSelected = c.id == selected.id;
          final isLocked = playerLevel < c.levelRequired;
          final color = _hexToColor(c.colorHex);
          final emoji = _emojis[c.id] ?? '📦';

          return GestureDetector(
            onTap: isLocked ? null : () => ref.read(selectedContainerProvider.notifier).state = c,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [color.withOpacity(0.4), color.withOpacity(0.12)])
                    : null,
                color: isSelected ? null : const Color(0xFF0D1222),
                border: Border.all(
                  color: isSelected
                      ? color
                      : c.isFree
                          ? AppColors.neonGreen.withOpacity(0.6)
                          : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)]
                    : c.isFree
                        ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 8)]
                        : null,
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLocked)
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        )
                      else
                        Text(emoji, style: TextStyle(
                          fontSize: 28,
                          shadows: isSelected ? [Shadow(color: color, blurRadius: 10)] : null,
                        )),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 72,
                        child: Text(
                          c.name.split(' ').first,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLocked
                                ? AppColors.textMuted.withOpacity(0.5)
                                : isSelected ? color : AppColors.textMuted,
                            fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      isLocked
                          ? Text('Lv.${c.levelRequired}', style: TextStyle(
                              color: AppColors.textMuted.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w700))
                          : Text(
                              c.isFree ? 'FREE' : _fmt(c.cost),
                              style: TextStyle(
                                color: c.isFree
                                    ? AppColors.neonGreen
                                    : (isSelected ? color : AppColors.textMuted),
                                fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                    ],
                  ),
                  if (isLocked)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                      ),
                    ),
                  if (c.isFree && !isLocked)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('FREE', style: TextStyle(
                          color: Colors.black, fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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

// ─── Star field — single CustomPainter, zero widget overhead ─────────────────

class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _StarPainter(_ctrl.value),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _stars = List.generate(22, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble() * 0.7,
    r: 0.7 + _rng.nextDouble() * 1.8,
    phase: _rng.nextDouble(),
    speed: 0.3 + _rng.nextDouble() * 0.7,
  ));

  const _StarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final blink = (sin((t * s.speed + s.phase) * 2 * pi) + 1) / 2;
      final opacity = 0.1 + blink * 0.5;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}
