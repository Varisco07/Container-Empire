import 'dart:math';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PORT CITY BACKGROUND
/// Città-porto cyberpunk animata, disegnata interamente con CustomPainter.
/// Layer (dietro → davanti): cielo + aurora, stelle, skyline lontano/medio/vicino
/// con finestre neon pulsanti e billboard olografici, droni con scia, treno
/// magnetico, navi cargo con container, acqua riflettente, vignettatura/bloom.
/// Nessun asset esterno.
/// ─────────────────────────────────────────────────────────────────────────────
class PortCityBackground extends StatefulWidget {
  /// Intensità visiva (1..10), tipicamente il livello/rank dell'impero:
  /// più alto = più droni e neon più luminosi.
  final int intensity;
  const PortCityBackground({super.key, this.intensity = 1});

  @override
  State<PortCityBackground> createState() => _PortCityBackgroundState();
}

class _PortCityBackgroundState extends State<PortCityBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Random _rnd = Random(7);

  late final List<_Star> _stars;
  late final List<_Building> _far;
  late final List<_Building> _mid;
  late final List<_Building> _near;
  late final List<_Drone> _drones;
  late final List<_Ship> _ships;

  @override
  void initState() {
    super.initState();
    // Periodo lungo: t = value × 3600 (secondi). Movimento continuo.
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3600))
      ..repeat();

    _stars = List.generate(110, (_) => _Star(_rnd));
    _far = _genBuildings(16, 0.40, 0.60, const Color(0xFF0B1A33), 0.45);
    _mid = _genBuildings(12, 0.50, 0.72, const Color(0xFF102A52), 0.7);
    _near = _genBuildings(8, 0.62, 0.90, const Color(0xFF0A1730), 1.0);
    _drones = List.generate(6 + widget.intensity.clamp(0, 10), (_) => _Drone(_rnd));
    _ships = List.generate(3, (i) => _Ship(_rnd, i));
  }

  List<_Building> _genBuildings(
      int count, double topMin, double topMax, Color base, double neon) {
    return List.generate(count, (i) {
      return _Building(
        x: i / count + _rnd.nextDouble() * (0.6 / count),
        w: 0.05 + _rnd.nextDouble() * 0.07,
        top: topMin + _rnd.nextDouble() * (topMax - topMin),
        base: base,
        seed: _rnd.nextInt(1 << 30),
        neon: neon,
        billboard: _rnd.nextDouble() < 0.35,
      );
    });
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
      builder: (_, __) {
        final t = _c.value * 3600.0;
        return CustomPaint(
          painter: _CityPainter(
            t: t,
            bright: 1 + widget.intensity.clamp(0, 10) * 0.04,
            stars: _stars,
            far: _far,
            mid: _mid,
            near: _near,
            drones: _drones,
            ships: _ships,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ─── Data ───────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, phase, speed;
  _Star(Random rnd)
      : x = rnd.nextDouble(),
        y = rnd.nextDouble() * 0.55,
        r = 0.4 + rnd.nextDouble() * 1.3,
        phase = rnd.nextDouble() * pi * 2,
        speed = 0.5 + rnd.nextDouble() * 1.5;
}

class _Building {
  final double x, w, top, neon;
  final Color base;
  final int seed;
  final bool billboard;
  _Building({
    required this.x,
    required this.w,
    required this.top,
    required this.base,
    required this.seed,
    required this.neon,
    required this.billboard,
  });
}

class _Drone {
  final double y, size, speed, phase;
  final int dir;
  final Color color;
  _Drone(Random rnd)
      : y = 0.08 + rnd.nextDouble() * 0.42,
        size = 1.6 + rnd.nextDouble() * 2.6,
        speed = 0.018 + rnd.nextDouble() * 0.05,
        phase = rnd.nextDouble(),
        dir = rnd.nextBool() ? 1 : -1,
        color = [
          const Color(0xFF4B7BEC),
          const Color(0xFF7C5CBF),
          const Color(0xFF21E6C1),
          const Color(0xFFF5A623),
        ][rnd.nextInt(4)];
}

class _Ship {
  final double y, scale, speed, phase;
  final List<Color> stack;
  _Ship(Random rnd, int i)
      : y = 0.80 + i * 0.05,
        scale = 0.8 + rnd.nextDouble() * 0.6,
        speed = 0.006 + rnd.nextDouble() * 0.01,
        phase = rnd.nextDouble(),
        stack = List.generate(
          4 + rnd.nextInt(4),
          (_) => [
            const Color(0xFF4B7BEC),
            const Color(0xFFF5A623),
            const Color(0xFF21E6C1),
            const Color(0xFFD63384),
            const Color(0xFF7C5CBF),
          ][rnd.nextInt(5)],
        );
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _CityPainter extends CustomPainter {
  final double t;
  final double bright;
  final List<_Star> stars;
  final List<_Building> far, mid, near;
  final List<_Drone> drones;
  final List<_Ship> ships;

  _CityPainter({
    required this.t,
    required this.bright,
    required this.stars,
    required this.far,
    required this.mid,
    required this.near,
    required this.drones,
    required this.ships,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.74;

    _sky(canvas, w, h, horizon);
    _stars(canvas, w, horizon);
    _aurora(canvas, w, horizon);

    // Skyline parallax (più lontano = drift più lento).
    _skyline(canvas, w, horizon, far, drift: (t * 1.2) % w, glow: 0.5 * bright);
    _skyline(canvas, w, horizon, mid, drift: (t * 3.0) % w, glow: 0.85 * bright);
    _drones(canvas, w, h);
    _skyline(canvas, w, horizon, near, drift: (t * 6.0) % w, glow: 1.1 * bright);
    _magTrain(canvas, w, horizon);

    _water(canvas, w, h, horizon);
    _ships(canvas, w, h, horizon);

    _scanBeam(canvas, w, h);
    _vignette(canvas, w, h);
  }

  // Cielo: navy profondo → nero carbone, con bagliore all'orizzonte.
  void _sky(Canvas canvas, double w, double h, double horizon) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050A18),
            Color(0xFF0A1230),
            Color(0xFF0E1A3A),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // Bagliore caldo dietro lo skyline.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - h * 0.28, w, h * 0.32),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, 1.0),
          radius: 1.1,
          colors: [
            const Color(0xFF1E3A7A).withOpacity(0.55),
            const Color(0xFF1E3A7A).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - h * 0.28, w, h * 0.32)),
    );
  }

  void _stars(Canvas canvas, double w, double horizon) {
    final p = Paint()..color = Colors.white;
    for (final s in stars) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * s.speed + s.phase));
      p.color = Colors.white.withOpacity(tw * 0.8);
      canvas.drawCircle(Offset(s.x * w, s.y * horizon), s.r, p);
    }
  }

  // Aurora boreale soft che ondeggia.
  void _aurora(Canvas canvas, double w, double horizon) {
    final path = Path();
    final baseY = horizon * 0.30;
    path.moveTo(0, baseY);
    for (double x = 0; x <= w; x += w / 24) {
      final y = baseY + sin((x / w * 4) + t * 0.25) * 22 + sin(t * 0.13) * 10;
      path.lineTo(x, y);
    }
    path.lineTo(w, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x335B7CFF), Color(0x000A1230)],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon * 0.45)),
    );
  }

  void _skyline(Canvas canvas, double w, double horizon, List<_Building> list,
      {required double drift, required double glow}) {
    for (final b in list) {
      // posizione con wrap orizzontale per parallax infinito
      double bx = (b.x * w - drift) % (w + 200);
      if (bx < -200) bx += (w + 200);
      final bw = b.w * w;
      final bh = (1 - b.top) * horizon;
      final top = horizon - bh;
      final rect = Rect.fromLTWH(bx, top, bw, bh + 2);
      final rrect =
          RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(3), topRight: const Radius.circular(3));

      // Corpo edificio
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [b.base, const Color(0xFF050A14)],
          ).createShader(rect),
      );
      // Bordo neon sul tetto
      final edge = _neonColor(b.seed);
      canvas.drawLine(
        Offset(bx, top),
        Offset(bx + bw, top),
        Paint()
          ..color = edge.withOpacity(0.5 * glow)
          ..strokeWidth = 1.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Finestre neon (griglia con twinkle deterministico)
      final r = Random(b.seed);
      final cols = (bw / 9).floor().clamp(2, 6);
      final rows = (bh / 12).floor().clamp(3, 16);
      final cellW = bw / cols;
      final cellH = bh / rows;
      final winPaint = Paint();
      for (int cy = 0; cy < rows; cy++) {
        for (int cx = 0; cx < cols; cx++) {
          if (r.nextDouble() > 0.55) continue;
          final wx = bx + cx * cellW + cellW * 0.28;
          final wy = top + cy * cellH + cellH * 0.28;
          final on = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 1.3 + cx * 1.7 + cy * 0.9 + b.seed));
          winPaint.color = edge.withOpacity(on * 0.7 * glow);
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, cellW * 0.42, cellH * 0.42),
            winPaint,
          );
        }
      }

      // Billboard olografico pulsante
      if (b.billboard && bw > 0.05 * w) {
        final pulse = 0.5 + 0.5 * sin(t * 2 + b.seed.toDouble());
        final bbRect = Rect.fromLTWH(bx + bw * 0.18, top + bh * 0.12, bw * 0.64, bh * 0.16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bbRect, const Radius.circular(2)),
          Paint()
            ..color = edge.withOpacity((0.35 + pulse * 0.5) * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + pulse * 4),
        );
      }
    }
  }

  void _drones(Canvas canvas, double w, double h) {
    for (final d in drones) {
      double x = ((t * d.speed + d.phase) % 1.2) * (w + 80) - 40;
      if (d.dir < 0) x = w - x;
      final y = d.y * h * 0.62 + sin(t * 0.8 + d.phase * 6) * 6;
      final blink = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 6 + d.phase * 10));

      // Scia
      final trail = Paint()
        ..color = d.color.withOpacity(0.18 * blink)
        ..strokeWidth = d.size * 0.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(x - d.dir * 16, y), Offset(x, y), trail);

      // Corpo + glow
      canvas.drawCircle(
        Offset(x, y),
        d.size * 2.4,
        Paint()
          ..color = d.color.withOpacity(0.25 * blink)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(Offset(x, y), d.size, Paint()..color = d.color.withOpacity(blink));
      canvas.drawCircle(Offset(x, y), d.size * 0.45, Paint()..color = Colors.white.withOpacity(blink));
    }
  }

  // Treno magnetico: striscia luminosa che attraversa periodicamente.
  void _magTrain(Canvas canvas, double w, double horizon) {
    final cycle = (t * 0.05) % 1.0;
    if (cycle > 0.5) return; // appare metà del tempo
    final x = cycle * 2 * (w + 220) - 120;
    final y = horizon - 14;
    final rect = Rect.fromLTWH(x, y, 110, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x0021E6C1), Color(0xFF21E6C1), Color(0xFFFFFFFF)],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  // Acqua: scrim scuro + riflessi neon verticali shimmer.
  void _water(Canvas canvas, double w, double h, double horizon) {
    final rect = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF081226), Color(0xFF030814)],
        ).createShader(rect),
    );
    // Riflessi shimmer
    final rnd = Random(99);
    for (int i = 0; i < 26; i++) {
      final rx = rnd.nextDouble() * w;
      final col = [
        const Color(0xFF4B7BEC),
        const Color(0xFF21E6C1),
        const Color(0xFFF5A623),
        const Color(0xFF7C5CBF),
      ][rnd.nextInt(4)];
      final shimmer = 0.5 + 0.5 * sin(t * 2 + i.toDouble());
      final len = (h - horizon) * (0.25 + rnd.nextDouble() * 0.5);
      canvas.drawLine(
        Offset(rx, horizon),
        Offset(rx + sin(t + i) * 3, horizon + len),
        Paint()
          ..color = col.withOpacity(0.10 + shimmer * 0.10)
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    // Linea orizzonte luminosa
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..color = const Color(0xFF21E6C1).withOpacity(0.25)
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _ships(Canvas canvas, double w, double h, double horizon) {
    for (final s in ships) {
      final x = ((t * s.speed + s.phase) % 1.3) * (w + 200) - 100;
      final y = horizon + (h - horizon) * (s.y - 0.74) + sin(t * 0.6 + s.phase * 5) * 2;
      final unit = 9.0 * s.scale;

      // Scafo
      final hull = Rect.fromLTWH(x, y, unit * 7, unit * 1.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(hull, Radius.circular(unit * 0.3)),
        Paint()..color = const Color(0xFF0C1A30),
      );
      // Pila di container
      for (int i = 0; i < s.stack.length; i++) {
        final cx = x + unit * 0.6 + (i % 4) * unit * 1.5;
        final cy = y - unit * (1 + (i ~/ 4));
        final cr = Rect.fromLTWH(cx, cy, unit * 1.3, unit * 0.9);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cr, Radius.circular(unit * 0.12)),
          Paint()..color = s.stack[i].withOpacity(0.85),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cr, Radius.circular(unit * 0.12)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = s.stack[i].withOpacity(0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
      // Luce di posizione lampeggiante
      final blink = 0.5 + 0.5 * sin(t * 4 + s.phase * 8);
      canvas.drawCircle(
        Offset(x + unit * 7, y),
        unit * 0.25,
        Paint()..color = const Color(0xFFFF4D4D).withOpacity(blink),
      );
    }
  }

  // Fascio di scansione verticale che spazza la scena.
  void _scanBeam(Canvas canvas, double w, double h) {
    final x = ((t * 0.04) % 1.0) * w;
    canvas.drawRect(
      Rect.fromLTWH(x - 30, 0, 60, h),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00000000), Color(0x114B7BEC), Color(0x00000000)],
        ).createShader(Rect.fromLTWH(x - 30, 0, 60, h)),
    );
  }

  void _vignette(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
          stops: const [0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  Color _neonColor(int seed) {
    const palette = [
      Color(0xFF4B7BEC),
      Color(0xFF21E6C1),
      Color(0xFF7C5CBF),
      Color(0xFFF5A623),
      Color(0xFFD63384),
    ];
    return palette[seed % palette.length];
  }

  @override
  bool shouldRepaint(covariant _CityPainter old) => old.t != t;
}
