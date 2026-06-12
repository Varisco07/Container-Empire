import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/item_model.dart';
import '../../../core/theme/app_colors.dart';

/// Pure Flutter container opening animation (replaces Flame Engine)
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
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late AnimationController _explodeCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _shakeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _particleAnim;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _explodeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _explodeCtrl, curve: Curves.easeIn));

    _opacityAnim = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _explodeCtrl, curve: const Interval(0.5, 1.0)));

    _particleAnim = CurvedAnimation(parent: _particleCtrl, curve: Curves.easeOut);

    _generateParticles();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80.0 + _random.nextDouble() * 160;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: 4.0 + _random.nextDouble() * 6,
        color: _randomColor(),
      ));
    }
  }

  Color _randomColor() {
    final colors = [
      widget.containerColor,
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonGold,
      AppColors.neonGreen,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Future<void> _startSequence() async {
    // Shake
    await _shakeCtrl.forward();
    // Explode + particles simultaneously
    _explodeCtrl.forward();
    _particleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _explodeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
      color: AppColors.background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          AnimatedBuilder(
            animation: _opacityAnim,
            builder: (_, __) => Opacity(
              opacity: _opacityAnim.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.containerColor.withOpacity(0.3),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Particles
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: _particles.map((p) {
                final progress = _particleAnim.value;
                final x = cos(p.angle) * p.speed * progress;
                final y = sin(p.angle) * p.speed * progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: p.color.withOpacity(0.6), blurRadius: 4)],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Container box
          AnimatedBuilder(
            animation: Listenable.merge([_shakeAnim, _scaleAnim, _opacityAnim]),
            builder: (_, __) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: widget.containerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: widget.containerColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: widget.containerColor.withOpacity(0.5), blurRadius: 40),
                      ],
                    ),
                    child: Center(
                      child: Text(widget.containerEmoji, style: const TextStyle(fontSize: 90)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  const _Particle({required this.angle, required this.speed, required this.size, required this.color});
}
