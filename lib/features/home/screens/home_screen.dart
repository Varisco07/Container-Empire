import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/container_model.dart';
import '../../../core/models/player_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

final selectedContainerProvider = StateProvider<ContainerModel>(
  (ref) => containerCatalog.first,
);

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('ff$h', radix: 16));
}

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _floatCtrl;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedContainerProvider);
    final color = _hexColor(selected.colorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _CleanBackground(accentColor: color),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: _AllDragBehavior(),
                        child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        dragStartBehavior: DragStartBehavior.down,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildTitle(),
                            SizedBox(
                              height: 340,
                              child: ScrollConfiguration(
                                behavior: _AllDragBehavior(),
                                child: PageView.builder(
                                  controller: _pageCtrl,
                                  onPageChanged: (i) {
                                    ref.read(selectedContainerProvider.notifier).state =
                                        containerCatalog[i];
                                  },
                                  itemCount: containerCatalog.length,
                                  itemBuilder: (_, i) {
                                    final c = containerCatalog[i];
                                    return _ContainerHero(
                                      container: c,
                                      color: _hexColor(c.colorHex),
                                      glowCtrl: _glowCtrl,
                                      floatCtrl: _floatCtrl,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _ContainerDots(selected: selected),
                            const SizedBox(height: 8),
                            _OpenButton(container: selected, color: color),
                            const SizedBox(height: 14),
                            const _RarityFilterBar(),
                            const SizedBox(height: 16),
                            _FeaturedSection(pageCtrl: _pageCtrl),
                            const SizedBox(height: 20),
                          ],
                        ),
                        ), // SingleChildScrollView
                      ), // ScrollConfiguration
                      const Positioned(left: 0, top: 24, child: _SideMenu(isLeft: true)),
                      const Positioned(right: 0, top: 24, child: _SideMenu(isLeft: false)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📦', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF7EC8E3), Color(0xFF4B7BEC), Color(0xFF9B59B6)],
                ).createShader(bounds),
                child: const Text(
                  'CONTAINER EMPIRE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                    shadows: [Shadow(color: Color(0x884B7BEC), blurRadius: 18)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Linea luminosa decorativa
          Container(
            height: 2,
            width: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, Color(0xFF4B7BEC), Colors.transparent],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF4B7BEC).withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('◆', style: TextStyle(color: Color(0xFF3A6BD4), fontSize: 7)),
              SizedBox(width: 9),
              Text(
                'APRI · COLLEZIONA · DOMINA',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 9),
              Text('◆', style: TextStyle(color: Color(0xFF3A6BD4), fontSize: 7)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Clean Background ─────────────────────────────────────────────────────────

class _CleanBackground extends StatefulWidget {
  final Color accentColor;
  const _CleanBackground({required this.accentColor});

  @override
  State<_CleanBackground> createState() => _CleanBackgroundState();
}

class _CleanBackgroundState extends State<_CleanBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Random _rnd = Random(11);
  late final List<_Star> _stars;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1200))..repeat();
    _stars = List.generate(70, (_) => _Star(_rnd));
    _embers = List.generate(22, (_) => _Ember(_rnd));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _BgPainter(_c.value * 1200, widget.accentColor, _stars, _embers),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Star {
  final double x, y, r, phase, speed;
  _Star(Random r0)
      : x = r0.nextDouble(),
        y = r0.nextDouble(),
        r = 0.4 + r0.nextDouble() * 1.4,
        phase = r0.nextDouble() * 6.28,
        speed = 0.5 + r0.nextDouble() * 1.5;
}

class _Ember {
  final double x, size, speed, phase, drift;
  _Ember(Random r0)
      : x = r0.nextDouble(),
        size = 1.0 + r0.nextDouble() * 2.2,
        speed = 0.02 + r0.nextDouble() * 0.05,
        phase = r0.nextDouble(),
        drift = (r0.nextDouble() - 0.5) * 0.05;
}

class _BgPainter extends CustomPainter {
  final double t;
  final Color accent;
  final List<_Star> stars;
  final List<_Ember> embers;
  _BgPainter(this.t, this.accent, this.stars, this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Base gradient profondo
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1830), Color(0xFF0B1424), Color(0xFF070E1C)],
        ).createShader(rect),
    );

    // Halo accent che respira in alto
    final pulse = 0.5 + 0.5 * sin(t * 0.6);
    final hc = Offset(w * 0.5, h * 0.15);
    final haloR = h * 0.5 * (0.9 + pulse * 0.15);
    canvas.drawCircle(
      hc,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withOpacity(0.12 + 0.05 * pulse), accent.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: hc, radius: haloR)),
    );

    // Stelle che brillano
    final sp = Paint();
    for (final s in stars) {
      final tw = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * s.speed + s.phase));
      sp.color = Colors.white.withOpacity(tw * 0.55);
      canvas.drawCircle(Offset(s.x * w, s.y * h * 0.78), s.r, sp);
    }

    // Griglia prospettica (pavimento cyber)
    final horizon = h * 0.74;
    final gp = Paint()..strokeWidth = 1;
    for (int i = 0; i <= 6; i++) {
      final f = i / 6.0;
      final y = horizon + (h - horizon) * f * f;
      gp.color = accent.withOpacity(0.13 * (1 - f));
      canvas.drawLine(Offset(0, y), Offset(w, y), gp);
    }
    final vx = w * 0.5;
    for (int i = -5; i <= 5; i++) {
      gp.color = accent.withOpacity(0.07);
      canvas.drawLine(Offset(vx + i * (w * 0.5), h), Offset(vx + i * (w * 0.12), horizon), gp);
    }

    // Braci che salgono
    final ep = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final e in embers) {
      final prog = (t * e.speed + e.phase) % 1.0;
      final y = h * (1.02 - prog);
      final x = (e.x + e.drift * sin(t * 0.4 + e.phase * 6)) * w;
      final fade = sin(prog * pi);
      ep.color = accent.withOpacity(fade * 0.5);
      canvas.drawCircle(Offset(x, y), e.size, ep);
    }

    // Vignettatura
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t || old.accent != accent;
}

// ─── Side menus ───────────────────────────────────────────────────────────────

class _SideMenu extends StatelessWidget {
  final bool isLeft;
  const _SideMenu({required this.isLeft});

  static const _left = [
    (icon: Icons.track_changes_rounded,  label: 'MISSIONI',    color: Color(0xFFA855F7), route: '/missions'),
    (icon: Icons.storefront_rounded,     label: 'NEGOZIO',     color: Color(0xFF34D399), route: '/shop'),
    (icon: Icons.upgrade_rounded,        label: 'BOOST',       color: Color(0xFF00F5FF), route: '/upgrades'),
    (icon: Icons.swap_horiz_rounded,     label: 'TRADE',       color: Color(0xFFFFD700), route: '/trade'),
  ];
  static const _right = [
    (icon: Icons.groups_rounded,         label: 'CLAN',        color: Color(0xFFFF0080), route: '/clan'),
    (icon: Icons.emoji_events_rounded,   label: 'RANKING',     color: Color(0xFFFFD700), route: '/leaderboard'),
    (icon: Icons.person_rounded,         label: 'PROFILO',     color: Color(0xFF8B5CF6), route: '/profile'),
    (icon: Icons.inventory_2_rounded,    label: 'INVENTARIO',  color: Color(0xFF34D399), route: '/inventory'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = isLeft ? _left : _right;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) => _SideItem(
        icon: item.icon,
        label: item.label,
        color: item.color,
        route: item.route,
        alignRight: !isLeft,
      )).toList(),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool alignRight;
  const _SideItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: alignRight ? const Radius.circular(14) : Radius.zero,
            right: alignRight ? Radius.zero : const Radius.circular(14),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.16), color.withOpacity(0.05)],
                ),
                border: Border.all(color: color.withOpacity(0.40), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 19,
                      shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)]),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  const _ContainerHero({
    required this.container,
    required this.color,
    required this.glowCtrl,
    required this.floatCtrl,
  });

  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
    'cosmic': '🌌', 'galactic': '🌠', 'multiverse': '🪐', 'singularity': '⚫',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final emoji = _emojis[container.id] ?? '📦';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        children: [
          // Container with effects
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Platform glow
                Positioned(
                  bottom: 18,
                  child: AnimatedBuilder(
                    animation: glowCtrl,
                    builder: (_, __) => Container(
                      width: 140 + glowCtrl.value * 22,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.55 + glowCtrl.value * 0.2),
                            blurRadius: 35,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Outer radial glow
                AnimatedBuilder(
                  animation: glowCtrl,
                  builder: (_, __) => Container(
                    width: 230 + glowCtrl.value * 18,
                    height: 230 + glowCtrl.value * 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        color.withOpacity(glowCtrl.value * 0.12),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Orbit ring
                _OrbitRing(color: color),
                // Floating container box
                AnimatedBuilder(
                  animation: floatCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, -7 + floatCtrl.value * 14),
                    child: GestureDetector(
                      onTap: () => context.push('/open/${container.id}'),
                      child: _ContainerBox(
                        container: container,
                        color: color,
                        emoji: emoji,
                      ),
                    ),
                  ),
                ),
                // Corner sparkles
                ..._cornerSparkles(color),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Container name badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.40), width: 1),
            ),
            child: Text(
              container.name,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Timer / availability
          playerAsync.when(
            data: (p) {
              if (container.isFree) return const SizedBox.shrink();
              return Text(
                container.description,
                style: const TextStyle(color: Color(0xFF6B7FA0), fontSize: 11),
                textAlign: TextAlign.center,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  List<Widget> _cornerSparkles(Color c) {
    const pos = [Offset(-82, -76), Offset(84, -72), Offset(-88, 56), Offset(86, 52)];
    const sz = [8.0, 10.0, 7.0, 9.0];
    return List.generate(4, (i) => Positioned(
      left: 115 + pos[i].dx, top: 115 + pos[i].dy,
      child: Text('✦', style: TextStyle(
        color: c.withOpacity(0.7), fontSize: sz[i],
        shadows: [Shadow(color: c, blurRadius: 6)],
      )),
    ));
  }
}

class _ContainerBox extends StatelessWidget {
  final ContainerModel container;
  final Color color;
  final String emoji;
  const _ContainerBox({required this.container, required this.color, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Alone esterno
        Container(
          width: 184, height: 184,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.32), blurRadius: 42, spreadRadius: 4),
            ],
          ),
        ),
        // Corpo vetro frostato
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 172, height: 172,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.30),
                    AppColors.surface.withOpacity(0.55),
                    const Color(0xFF0A1424).withOpacity(0.65),
                  ],
                ),
                border: Border.all(color: color.withOpacity(0.6), width: 1.6),
              ),
              child: Stack(
                children: [
                  // Shine diagonale in alto
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Glow radiale dietro l'emoji
                  Center(
                    child: Container(
                      width: 124, height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [color.withOpacity(0.40), Colors.transparent]),
                      ),
                    ),
                  ),
                  // Emoji
                  Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 76, shadows: [Shadow(color: color, blurRadius: 22)]),
                    ),
                  ),
                  // Angoli neon
                  ..._brackets(color),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _brackets(Color c) {
    BorderSide s() => BorderSide(color: c.withOpacity(0.85), width: 2);
    const m = 12.0;
    return [
      Positioned(top: m, left: m, child: Container(width: 16, height: 16, decoration: BoxDecoration(border: Border(top: s(), left: s())))),
      Positioned(top: m, right: m, child: Container(width: 16, height: 16, decoration: BoxDecoration(border: Border(top: s(), right: s())))),
      Positioned(bottom: m, left: m, child: Container(width: 16, height: 16, decoration: BoxDecoration(border: Border(bottom: s(), left: s())))),
      Positioned(bottom: m, right: m, child: Container(width: 16, height: 16, decoration: BoxDecoration(border: Border(bottom: s(), right: s())))),
    ];
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
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * pi,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
          ),
          child: Stack(children: [
            Positioned(
              top: 0, left: 93,
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
              bottom: 0, right: 91,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.6),
                  boxShadow: [BoxShadow(color: widget.color, blurRadius: 6)],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Open Button ──────────────────────────────────────────────────────────────

class _OpenButton extends ConsumerStatefulWidget {
  final ContainerModel container;
  final Color color;
  const _OpenButton({required this.container, required this.color});

  @override
  ConsumerState<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends ConsumerState<_OpenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFree  = widget.container.isFree;
    final color   = widget.color;
    final label   = isFree ? 'APRI GRATIS 🎁' : 'APRI  •  🪙 ${_fmt(widget.container.cost)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GestureDetector(
            onTapDown:  (_) => setState(() => _pressed = true),
            onTapUp:    (_) { setState(() => _pressed = false); context.push('/open/${widget.container.id}'); },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, child) => Container(
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isFree
                          ? [const Color(0xFF27AE60), const Color(0xFF1E8449)]
                          : [color, color.withOpacity(0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35 + _glowCtrl.value * 0.25),
                        blurRadius: 16 + _glowCtrl.value * 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shine diagonal
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Colors.white.withOpacity(0.18), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 6),
            Text(
              widget.container.description,
              style: const TextStyle(color: Color(0xFF6B7FA0), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Rarity Filter Bar ────────────────────────────────────────────────────────

class _RarityFilterBar extends StatelessWidget {
  const _RarityFilterBar();

  static const _rarities = [
    (label: 'COMUNE',   color: AppColors.common),
    (label: 'NON COM.', color: AppColors.uncommon),
    (label: 'RARO',     color: AppColors.rare),
    (label: 'EPICO',    color: AppColors.epic),
    (label: 'LEGG.',    color: AppColors.legendary),
    (label: 'MITICO',   color: AppColors.mythic),
    (label: 'DIVINO',   color: AppColors.divine),
    (label: 'COSMICO',  color: AppColors.secret),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 8),
          child: Text(
            'RARITÀ DISPONIBILI',
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _rarities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final r = _rarities[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: r.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: r.color.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: r.color,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: r.color, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.label,
                      style: TextStyle(
                        color: r.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Featured Containers Section ──────────────────────────────────────────────

class _FeaturedSection extends ConsumerStatefulWidget {
  final PageController pageCtrl;
  const _FeaturedSection({required this.pageCtrl});

  @override
  ConsumerState<_FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends ConsumerState<_FeaturedSection> {
  late PageController _bottomCtrl;
  bool _syncingFromBottom = false;
  bool _syncingFromTop = false;

  static const _badges = [null, 'POPOLARE', 'BEST VALUE'];
  static const _badgeColors = [Colors.transparent, Color(0xFF9B3FFF), Color(0xFF10B981)];
  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
    'cosmic': '🌌', 'galactic': '🌠', 'multiverse': '🪐', 'singularity': '⚫',
  };

  @override
  void initState() {
    super.initState();
    _bottomCtrl = PageController(viewportFraction: 0.55);

    // Quando il PageView in alto cambia, aggiorna anche quello in basso
    widget.pageCtrl.addListener(_onTopScroll);
  }

  void _onTopScroll() {
    if (_syncingFromBottom) return;
    if (!_bottomCtrl.hasClients) return;
    _syncingFromTop = true;
    _bottomCtrl.jumpTo(
      (widget.pageCtrl.page ?? 0) *
          (_bottomCtrl.position.maxScrollExtent / (containerCatalog.length - 1)),
    );
    _syncingFromTop = false;
  }

  @override
  void dispose() {
    widget.pageCtrl.removeListener(_onTopScroll);
    _bottomCtrl.dispose();
    super.dispose();
  }

  void _goTo(int idx) {
    if (idx < 0 || idx >= containerCatalog.length) return;
    ref.read(selectedContainerProvider.notifier).state = containerCatalog[idx];
    widget.pageCtrl.animateToPage(idx,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    _bottomCtrl.animateToPage(idx,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final featured = containerCatalog.toList();
    final playerAsync = ref.watch(playerNotifierProvider);
    final playerLevel =
        playerAsync.when(data: (p) => p.level, loading: () => 1, error: (_, __) => 1);
    final selectedIdx = featured.indexOf(ref.watch(selectedContainerProvider));

    return Column(
      children: [
        // ── Header con frecce ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'TUTTI I CONTAINER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8),
              ),
              const Spacer(),
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(selectedIdx - 1),
              ),
              const SizedBox(width: 8),
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(selectedIdx + 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Lista scorrevole come PageView ─────────────────────────────
        SizedBox(
          height: 210,
          child: ScrollConfiguration(
            behavior: _AllDragBehavior(),
            child: PageView.builder(
            controller: _bottomCtrl,
            onPageChanged: (i) {
              if (_syncingFromTop) return;
              _syncingFromBottom = true;
              _goTo(i);
              _syncingFromBottom = false;
            },
            itemCount: featured.length,
            itemBuilder: (_, i) {
              final c = featured[i];
              final color = _hexColor(c.colorHex);
              final emoji = _emojis[c.id] ?? '📦';
              final badge = i < _badges.length ? _badges[i] : null;
              final badgeColor =
                  i < _badgeColors.length ? _badgeColors[i] : Colors.transparent;
              final isLocked = playerLevel < c.levelRequired;
              final itemCount = c.lootTable.length;
              final isSelected = i == selectedIdx;

              return GestureDetector(
                onTap: isLocked ? null : () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color.withOpacity(0.85) : color.withOpacity(0.30),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 18)]
                        : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Immagine container
                            Expanded(
                              child: Center(
                                child: Stack(alignment: Alignment.center, children: [
                                  Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20)],
                                    ),
                                  ),
                                  Text(
                                    emoji,
                                    style: TextStyle(fontSize: 44,
                                        shadows: [Shadow(color: color, blurRadius: 12)]),
                                  ),
                                ]),
                              ),
                            ),
                            // Nome
                            Text(
                              c.name.split(' ').take(2).join(' '),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Contenuto: $itemCount oggetti',
                              style: const TextStyle(color: Color(0xFF6B7FA0), fontSize: 9),
                            ),
                            const SizedBox(height: 6),
                            // Puntini rarità
                            Row(
                              children: [
                                AppColors.common, AppColors.uncommon, AppColors.rare,
                                AppColors.epic, AppColors.legendary,
                              ].map((rc) => Container(
                                    width: 12, height: 12,
                                    margin: const EdgeInsets.only(right: 3),
                                    decoration: BoxDecoration(
                                      color: rc.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: rc.withOpacity(0.7), width: 1),
                                    ),
                                  )).toList(),
                            ),
                            const SizedBox(height: 8),
                            // Prezzo
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withOpacity(0.5), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _fmtCost(c.cost),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge
                      if (badge != null)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 8)],
                            ),
                            child: Text(badge,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3)),
                          ),
                        ),
                      // Lock overlay
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_rounded, color: Colors.white38, size: 28),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ), // PageView.builder
          ), // ScrollConfiguration
        ),
      ],
    );
  }

  String _fmtCost(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Free Container Countdown ─────────────────────────────────────────────────

class _FreeContainerCountdown extends StatefulWidget {
  final PlayerModel player;
  const _FreeContainerCountdown({required this.player});
  @override
  State<_FreeContainerCountdown> createState() => _FreeContainerCountdownState();
}

class _FreeContainerCountdownState extends State<_FreeContainerCountdown> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.player.canClaimFreeContainer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
        ),
        child: const Text(
          '✅  DISPONIBILE ADESSO!',
          style: TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      );
    }
    final cd = widget.player.freeContainerCooldown;
    final h = cd.inHours.toString().padLeft(2, '0');
    final m = cd.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = cd.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '⏱  $h:$m:$s',
      style: const TextStyle(color: Color(0xFF7B8FA8), fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

// ─── Container pagination dots ────────────────────────────────────────────────

// ─── Nav Arrow ────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 22),
    ),
  );
}

// ─── Container Dots ───────────────────────────────────────────────────────────

class _ContainerDots extends StatelessWidget {
  final ContainerModel selected;
  const _ContainerDots({required this.selected});

  @override
  Widget build(BuildContext context) {
    final idx = containerCatalog.indexOf(selected);
    final color = _hexColor(selected.colorHex);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(containerCatalog.length, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: i == idx ? 18 : 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: i == idx ? color : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(3),
          boxShadow: i == idx ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : null,
        ),
      )),
    );
  }
}

// ─── Scroll behavior: abilita drag con mouse E touch ─────────────────────────

class _AllDragBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Nessuna scrollbar visibile
    return child;
  }
}
