import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/player_service.dart';
import '../../core/theme/app_colors.dart';

/// Full-screen bottom sheet showing the 30-day login streak calendar.
/// Pass [onClaimed] to receive the DailyBonusResult after a successful claim.
class DailyStreakDialog extends StatefulWidget {
  final int currentStreak;
  final bool canClaim;
  final Future<DailyBonusResult> Function() onClaim;
  final VoidCallback? onDismiss;

  const DailyStreakDialog({
    super.key,
    required this.currentStreak,
    required this.canClaim,
    required this.onClaim,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentStreak,
    required bool canClaim,
    required Future<DailyBonusResult> Function() onClaim,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Use builder's context for dismissal — avoids root-navigator issues
      builder: (sheetCtx) => DailyStreakDialog(
        currentStreak: currentStreak,
        canClaim: canClaim,
        onClaim: onClaim,
        onDismiss: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  @override
  State<DailyStreakDialog> createState() => _DailyStreakDialogState();
}

class _DailyStreakDialogState extends State<DailyStreakDialog> {
  bool _claimed = false;
  DailyBonusResult? _result;
  bool _loading = false;

  static const int _totalDays = 30;
  static const int _daysPerRow = 7;

  String _rewardLabel(int day) {
    if (day == 30) return '🎁 MEGA';
    if (day % 7 == 0) return '💎×${(day ~/ 7) * 3 + 10}';
    final coins = (200 + day * 100) / 1000;
    return '🪙${coins >= 1 ? '${coins.toStringAsFixed(0)}K' : (200 + day * 100).toStringAsFixed(0)}';
  }

  bool _isMilestone(int day) => day % 7 == 0 || day == 30;

  Future<void> _handleClaim() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await widget.onClaim();
    setState(() {
      _claimed = true;
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final clampedStreak = widget.currentStreak.clamp(0, _totalDays);

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        const Text(
                          'STREAK GIORNALIERO',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Giorno $clampedStreak su 30',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 12),
                // Streak fire bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalDays, (i) {
                    final day = i + 1;
                    final done = day <= clampedStreak;
                    final isCurrent = day == clampedStreak + 1 && widget.canClaim;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: done
                              ? AppColors.neonOrange
                              : isCurrent
                                  ? AppColors.neonGold
                                  : AppColors.border,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Days grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _daysPerRow,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.75,
                ),
                itemCount: _totalDays,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final isDone = day <= clampedStreak;
                  final isCurrent = day == clampedStreak + 1 && widget.canClaim;
                  final isMilestone = _isMilestone(day);
                  final isMega = day == 30;

                  Color cardColor;
                  Color textColor;
                  if (isMega) {
                    cardColor = AppColors.neonPurple.withOpacity(isCurrent ? 0.4 : isDone ? 0.25 : 0.08);
                    textColor = AppColors.neonPurple;
                  } else if (isMilestone) {
                    cardColor = AppColors.neonCyan.withOpacity(isCurrent ? 0.35 : isDone ? 0.2 : 0.06);
                    textColor = AppColors.neonCyan;
                  } else {
                    cardColor = AppColors.neonOrange.withOpacity(isCurrent ? 0.3 : isDone ? 0.15 : 0.04);
                    textColor = isDone ? AppColors.neonOrange : AppColors.textMuted;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.neonGold
                            : isDone
                                ? textColor.withOpacity(0.6)
                                : AppColors.border.withOpacity(0.5),
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: AppColors.neonGold.withOpacity(0.4), blurRadius: 10)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDone)
                          const Text('✅', style: TextStyle(fontSize: 14))
                        else if (isCurrent)
                          const Text('⭐', style: TextStyle(fontSize: 14))
                        else
                          Text(
                            '$day',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          _rewardLabel(day),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: (i * 15).clamp(0, 300)))
                    .fadeIn(duration: 200.ms);
                },
              ),
            ),
          ),

          // Claim section
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _claimed && _result != null
                ? _ClaimedBanner(result: _result!, onDismiss: widget.onDismiss ?? () => Navigator.pop(context))
                : Column(
                    children: [
                      if (widget.canClaim) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.neonGold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.neonGold.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎁', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Giorno ${clampedStreak + 1} disponibile!',
                                    style: const TextStyle(
                                      color: AppColors.neonGold,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Ricompensa: ${_rewardLabel(clampedStreak + 1)}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleClaim,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    '🔥  RITIRA RICOMPENSA',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                  ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 1500.ms, color: Colors.white24),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            '✅ Ricompensa già ritirata oggi\nTorna domani!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: widget.onDismiss ?? () => Navigator.pop(context),
                          child: const Text('CHIUDI', style: TextStyle(color: AppColors.textMuted, letterSpacing: 1)),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClaimedBanner extends StatelessWidget {
  final DailyBonusResult result;
  final VoidCallback onDismiss;
  const _ClaimedBanner({required this.result, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.neonOrange, AppColors.neonGold],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.neonOrange.withOpacity(0.4), blurRadius: 20)],
          ),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'GIORNO ${result.streak}!',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ).animate().scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut),
              const SizedBox(height: 4),
              Text(
                '+🪙 ${_fmt(result.coins)}  ·  +${result.gems} 💎',
                style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 500.ms),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onDismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('CONTINUA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
