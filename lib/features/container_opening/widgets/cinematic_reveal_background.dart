import 'dart:math';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CINEMATIC REVEAL BACKGROUND
/// Sfondo "da trailer" per il reveal di un oggetto: aura radiale pulsante,
/// raggi volumetrici rotanti (god-rays) e particelle scintillanti che salgono,
/// tutto colorato in base alla rarità. Più alta la rarità → più intenso.
/// 100% CustomPainter, nessun asset.
/// ─────────────────────────────────────────────────────────────────────────────
class CinematicRevealBackground extends StatefulWidget {
  final Color color;

  /// 0..1 — quanto è spettacolare (rari+ ≈ 1.0, comuni ≈ 0.4).
  final double intensity;

  const CinematicRevealBackground({
    super.key,
    required this.color,
    this.intensity = 0.5,
  });

  @override
  State<CinematicRevealBackground> createState() => _CinematicRevealBackgroundState();
}

class _CinematicRevealBackgroundState extends State<CinematicRevealBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Random _rnd = Random(42);
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 600))..repeat();
    final count = (28 + widget.intensity * 36).round();
    _sparks = List.generate(count, (_) => _Spark(_rnd));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _RevealPainter(
          t: _c.value * 600.0,
          color: widget.color,
          intensity: widget.intensity.clamp(0.0, 1.0),
          sparks: _sparks,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Spark {
  final double x, speed, size, phase, drift;
  _Spark(Random r)
      : x = r.nextDouble(),
        speed = 0.06 + r.nextDouble() * 0.18,
        size = 1.0 + r.nextDouble() * 2.6,
        phase = r.nextDouble(),
        drift = (r.nextDouble() - 0.5) * 0.06;
}

class _RevealPainter extends CustomPainter {
  final double t;
  final Color color;
  final double intensity;
  final List<_Spark> sparks;

  _RevealPainter({
    required this.t,
    required this.color,
    required this.intensity,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.42);
    final maxR = sqrt(w * w + h * h);

    // ── Vignette scura di base ────────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.16),
          radius: 1.0,
          colors: [color.withOpacity(0.10 * intensity), const Color(0xFF05080F)],
          stops: const [0.0, 0.85],
        ).createShader(Offset.zero & size),
    );

    // ── God-rays rotanti ──────────────────────────────────────────────────────
    final rayCount = (10 + intensity * 8).round();
    final rot = t * 0.18;
    const halfW = 0.10; // ampiezza angolare del raggio
    for (int i = 0; i < rayCount; i++) {
      final a = rot + i * (2 * pi / rayCount);
      // leggero "respiro" per ogni raggio
      final breathe = 0.5 + 0.5 * sin(t * 1.5 + i);
      final op = (0.018 + 0.05 * intensity) * (0.4 + 0.6 * breathe);
      final p = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + cos(a - halfW) * maxR, center.dy + sin(a - halfW) * maxR)
        ..lineTo(center.dx + cos(a + halfW) * maxR, center.dy + sin(a + halfW) * maxR)
        ..close();
      canvas.drawPath(p, Paint()..color = color.withOpacity(op));
    }

    // ── Aura centrale pulsante ────────────────────────────────────────────────
    final pulse = 0.5 + 0.5 * sin(t * 2.0);
    final auraR = (h * 0.16) * (0.85 + pulse * 0.35) * (0.7 + intensity * 0.6);
    canvas.drawCircle(
      center,
      auraR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.45 * intensity),
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: auraR))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 * intensity + 6),
    );

    // ── Anello d'onda (solo rari+) ────────────────────────────────────────────
    if (intensity > 0.7) {
      final ringT = (t * 0.6) % 1.0;
      final ringR = ringT * h * 0.5;
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - ringT)
          ..color = color.withOpacity(0.5 * (1 - ringT))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── Particelle scintillanti che salgono ───────────────────────────────────
    final sparkPaint = Paint();
    for (final s in sparks) {
      final prog = (t * s.speed + s.phase) % 1.0;
      final y = h * (1.05 - prog * 1.1);
      final x = (s.x + s.drift * sin(t * 0.6 + s.phase * 6)) * w;
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 4 + s.phase * 12));
      final fade = sin(prog * pi); // appare e svanisce ai bordi
      sparkPaint
        ..color = (twinkle > 0.85 ? Colors.white : color).withOpacity(twinkle * fade * (0.5 + intensity * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(x, y), s.size, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevealPainter old) => old.t != t || old.color != color;
}
