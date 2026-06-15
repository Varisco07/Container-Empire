import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/item_model.dart';
import '../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CONTAINER ANIMATION — apertura cinematografica pseudo-3D (Flutter puro).
/// Sequenza: carica energia (container in prospettiva che ondeggia + anelli che
/// si contraggono + glow crescente) → flash → crepa di luce che si apre →
/// colonna di luce + onda d'urto + esplosione di particelle + camera punch.
/// API invariata: chiama onAnimationComplete al termine.
/// ─────────────────────────────────────────────────────────────────────────────
class ContainerAnimationWidget extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  final Color containerColor;
  final ItemModel? revealedItem;
  final String containerEmoji;

  const ContainerAnimationWidget({
    super.key,
    required this.onAnimationComplete,
    required this.containerColor,
    required this.containerEmoji,
    this.revealedItem,
  });

  @override
  State<ContainerAnimationWidget> createState() => _ContainerAnimationWidgetState();
}

class _ContainerAnimationWidgetState extends State<ContainerAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _generateParticles();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onAnimationComplete();
      }
    });
    _ctrl.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 64; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 90.0 + _random.nextDouble() * 240,
        size: 2.5 + _random.nextDouble() * 6,
        color: _randomColor(),
        spin: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  Color _randomColor() {
    final colors = [
      widget.containerColor,
      Colors.white,
      AppColors.neonGold,
      AppColors.neonCyan,
      widget.containerColor,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFF05080F),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            final charge = Curves.easeIn.transform(_seg(t, 0.0, 0.55));
            final lid = Curves.easeOutCubic.transform(_seg(t, 0.46, 0.74));
            final burst = _seg(t, 0.70, 1.0);
            final flash = _tri(_seg(t, 0.64, 0.88));

            // movimento "vivo" della camera
            final shake = charge * 9 * sin(t * 70);
            final wobble = sin(t * 6.0) * 0.20 * (0.35 + 0.65 * charge);
            final tilt = -0.10 - 0.10 * charge;
            final scale = 1.0 + 0.10 * charge + 0.55 * burst;
            final boxOpacity = (1.0 - burst).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Effetti (glow, anelli, beam, onda, particelle) ──────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FxPainter(
                      t: t,
                      color: widget.containerColor,
                      particles: _particles,
                    ),
                  ),
                ),

                // ── Container pseudo-3D ─────────────────────────────────────────
                Transform.translate(
                  offset: Offset(shake, -10),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(tilt)
                      ..rotateY(wobble)
                      ..scale(scale),
                    child: Opacity(
                      opacity: boxOpacity,
                      child: _crate(lid, charge),
                    ),
                  ),
                ),

                // ── Flash bianco di apertura ────────────────────────────────────
                if (flash > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: Colors.white.withOpacity(flash * 0.9)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _crate(double lid, double charge) {
    final color = widget.containerColor;
    const size = 190.0;
    final glowPulse = 0.5 + 0.5 * sin(_ctrl.value * 18);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corpo del container (faccia metallica)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, 0.18)!.withOpacity(0.30),
                  color.withOpacity(0.12),
                  const Color(0xFF060B14),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35 + 0.4 * charge), blurRadius: 40 + 30 * charge, spreadRadius: 2 + 8 * charge),
              ],
            ),
          ),

          // Emoji del container (svanisce mentre si apre)
          Opacity(
            opacity: (1.0 - lid).clamp(0.0, 1.0),
            child: Text(widget.containerEmoji, style: const TextStyle(fontSize: 92)),
          ),

          // Crepa di luce orizzontale che si allarga (apertura)
          Align(
            alignment: Alignment.center,
            child: Container(
              height: (8 + lid * (size - 16)).clamp(0.0, size),
              width: size - 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.0),
                    Colors.white.withOpacity(0.95 * (0.4 + 0.6 * lid)),
                    color.withOpacity(0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6 * lid),
                    blurRadius: 30 * lid + 6,
                    spreadRadius: 4 * lid,
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.7 * lid),
                    blurRadius: 50 * lid,
                    spreadRadius: 8 * lid,
                  ),
                ],
              ),
            ),
          ),

          // Bordo neon che pulsa mentre carica
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15 + 0.5 * charge * glowPulse),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _tri(double x) {
  if (x <= 0 || x >= 1) return 0;
  return x < 0.25 ? x / 0.25 : 1 - (x - 0.25) / 0.75;
}

class _FxPainter extends CustomPainter {
  final double t;
  final Color color;
  final List<_Particle> particles;
  _FxPainter({required this.t, required this.color, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 10);
    final maxR = sqrt(size.width * size.width + size.height * size.height);

    final charge = Curves.easeIn.transform(_seg(t, 0.0, 0.55));
    final burst = _seg(t, 0.70, 1.0);
    final beam = _tri(_seg(t, 0.68, 1.0));
    final flash = _tri(_seg(t, 0.64, 0.88));

    // ── Glow centrale ──────────────────────────────────────────────────────────
    final glowR = (40 + 120 * charge) + burst * 160;
    final glowOp = (0.35 * charge + flash * 0.7).clamp(0.0, 1.0);
    if (glowOp > 0.01) {
      canvas.drawCircle(
        c,
        glowR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(color, Colors.white, flash)!.withOpacity(glowOp),
              color.withOpacity(0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: glowR)),
      );
    }

    // ── Anelli di energia che si contraggono (carica) ──────────────────────────
    if (charge > 0.02 && burst < 0.2) {
      for (int i = 0; i < 3; i++) {
        final rc = (charge - i * 0.14).clamp(0.0, 1.0);
        if (rc <= 0) continue;
        final r = _lerp(maxR * 0.42, 50, Curves.easeIn.transform(rc));
        final op = rc * 0.55 * (1 - rc * 0.3);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = color.withOpacity(op)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // ── Colonna di luce (burst) ────────────────────────────────────────────────
    if (beam > 0.01) {
      final bw = (18 + 70 * beam);
      final rect = Rect.fromLTWH(c.dx - bw / 2, 0, bw, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withOpacity(0.0),
              color.withOpacity(0.5 * beam),
              Colors.white.withOpacity(0.9 * beam),
              color.withOpacity(0.5 * beam),
              color.withOpacity(0.0),
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // ── Onda d'urto (burst) ────────────────────────────────────────────────────
    if (burst > 0.01) {
      final sr = burst * maxR * 0.55;
      canvas.drawCircle(
        c,
        sr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1 - burst) * 9 + 1
          ..color = Colors.white.withOpacity((1 - burst) * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        c,
        sr * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1 - burst) * 6 + 1
          ..color = color.withOpacity((1 - burst) * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // ── Esplosione di particelle (burst) ───────────────────────────────────────
    if (burst > 0.0) {
      final p = Paint();
      for (final part in particles) {
        final prog = burst;
        final dx = cos(part.angle) * part.speed * prog;
        final dy = sin(part.angle) * part.speed * prog + 70 * prog * prog;
        final op = (1 - prog).clamp(0.0, 1.0);
        if (op <= 0) continue;
        final pos = c + Offset(dx, dy);
        p
          ..color = part.color.withOpacity(op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(pos, part.size * (1 - prog * 0.4), p);
      }
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _FxPainter old) => old.t != t || old.color != color;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
  });
}
