import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/battle_pass.dart';
import '../../../core/services/battle_pass_service.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/player_provider.dart';
import '../../tycoon/widgets/glass_panel.dart';

class BattlePassScreen extends ConsumerStatefulWidget {
  const BattlePassScreen({super.key});

  @override
  ConsumerState<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends ConsumerState<BattlePassScreen> {
  BattlePassService get _bp => sl<BattlePassService>();

  static const _premiumColor = AppColors.neonGold;

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  Future<void> _buyPremium() async {
    final ok = await _bp.buyPremium();
    if (ok) {
      HapticFeedback.heavyImpact();
      ref.read(playerNotifierProvider.notifier).refresh();
      if (mounted) setState(() {});
      _snack('🏆 PASS PREMIUM sbloccato!', _premiumColor);
    } else {
      _snack('Servono ${BattlePassService.premiumGemCost} 💎', AppColors.error);
    }
  }

  Future<void> _claimFree(int tier) async {
    await _bp.claimFree(tier);
    ref.read(playerNotifierProvider.notifier).refresh();
    if (mounted) setState(() {});
    HapticFeedback.selectionClick();
  }

  Future<void> _claimPremium(int tier) async {
    await _bp.claimPremium(tier);
    ref.read(playerNotifierProvider.notifier).refresh();
    if (mounted) setState(() {});
    HapticFeedback.selectionClick();
  }

  Future<void> _claimAll() async {
    final n = await _bp.claimAll();
    ref.read(playerNotifierProvider.notifier).refresh();
    if (mounted) setState(() {});
    _snack(n > 0 ? '🎁 Riscosse $n ricompense!' : 'Niente da riscuotere', n > 0 ? AppColors.success : AppColors.textMuted);
  }

  void _buyVip() {
    sl<IapService>().buyProduct(IapProducts.vipMonthly);
    _snack('Avvio acquisto VIP…', AppColors.neonPurple);
  }

  @override
  Widget build(BuildContext context) {
    final gems = ref.watch(playerNotifierProvider).maybeWhen(data: (p) => p.gems, orElse: () => 0);
    final premium = _bp.premiumOwned;
    final claimable = _bp.claimableCount;

    return Scaffold(
      backgroundColor: const Color(0xFF070C16),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 14, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/empire'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BATTLE PASS',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        Text(seasonName,
                            style: TextStyle(color: _premiumColor.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gems.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gems.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Text('💎', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text('$gems', style: const TextStyle(color: AppColors.gems, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ],
              ),
            ),

            _SeasonProgress(tier: _bp.currentTier, progress: _bp.tierProgress),

            // ── CTA premium / riscuoti tutto ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  if (!premium)
                    Expanded(
                      child: GestureDetector(
                        onTap: _buyPremium,
                        child: GlassPanel(
                          radius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          tint: _premiumColor.withOpacity(0.16),
                          borderColor: _premiumColor.withOpacity(0.5),
                          glow: _premiumColor.withOpacity(0.55),
                          child: Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('SBLOCCA PREMIUM',
                                        style: TextStyle(color: _premiumColor, fontSize: 12.5, fontWeight: FontWeight.w900)),
                                    Text('Tutte le ricompense premium della stagione',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                                  ],
                                ),
                              ),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('💎', style: TextStyle(fontSize: 12)),
                                Text('${BattlePassService.premiumGemCost}',
                                    style: const TextStyle(color: _premiumColor, fontWeight: FontWeight.w900, fontSize: 13)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GlassPanel(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        tint: _premiumColor.withOpacity(0.12),
                        borderColor: _premiumColor.withOpacity(0.4),
                        child: const Row(children: [
                          Text('🏆', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Text('PASS PREMIUM ATTIVO',
                              style: TextStyle(color: _premiumColor, fontSize: 12.5, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    ),
                  if (claimable > 0) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _claimAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF1FAE5A)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 14)],
                        ),
                        child: Text('RISCUOTI\n$claimable 🎁',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.2)),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 700.ms),
                  ],
                ],
              ),
            ),

            // Intestazione colonne
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(children: [
                SizedBox(width: 44),
                Expanded(child: Text('GRATIS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
                Expanded(child: Text('PREMIUM 🏆', textAlign: TextAlign.center, style: TextStyle(color: _premiumColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
              ]),
            ),

            // ── Lista tier ────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                physics: const BouncingScrollPhysics(),
                itemCount: _bp.tiers.length + 1,
                itemBuilder: (_, i) {
                  if (i == _bp.tiers.length) return _vipBanner();
                  final t = _bp.tiers[i];
                  return _TierRow(
                    tier: t.tier,
                    unlocked: _bp.isUnlocked(t.tier),
                    free: t.free,
                    premium: t.premium,
                    premiumOwned: premium,
                    freeClaimed: _bp.freeClaimed(t.tier),
                    premiumClaimed: _bp.premiumClaimed(t.tier),
                    canClaimFree: _bp.canClaimFree(t.tier),
                    canClaimPremium: _bp.canClaimPremium(t.tier),
                    onClaimFree: () => _claimFree(t.tier),
                    onClaimPremium: () => _claimPremium(t.tier),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vipBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassPanel(
        radius: 20,
        tint: AppColors.neonPurple.withOpacity(0.14),
        borderColor: AppColors.neonPurple.withOpacity(0.45),
        glow: AppColors.neonPurple.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              const Text('👑', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VIP CLUB', style: TextStyle(color: AppColors.neonPurple, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('+50% profitti idle · niente pubblicità\n· ricompense giornaliere doppie',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, height: 1.3)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _buyVip,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.neonPurple, Color(0xFF9B59B6)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.45), blurRadius: 16)],
                ),
                child: const Center(
                  child: Text('DIVENTA VIP', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Season progress ───────────────────────────────────────────────────────────

class _SeasonProgress extends StatelessWidget {
  final int tier;
  final double progress;
  const _SeasonProgress({required this.tier, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('LIVELLO PASS', style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
              Text('$tier / $passTiers',
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 10, color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.neonCyan, Color(0xFF3A6BD4)]),
                          boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.5), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 5),
                Text('${(progress * xpPerTier).floor()} / $xpPerTier Pass XP alla prossima tier',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tier row ───────────────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final int tier;
  final bool unlocked, premiumOwned, freeClaimed, premiumClaimed, canClaimFree, canClaimPremium;
  final PassReward free, premium;
  final VoidCallback onClaimFree, onClaimPremium;

  const _TierRow({
    required this.tier,
    required this.unlocked,
    required this.premiumOwned,
    required this.free,
    required this.premium,
    required this.freeClaimed,
    required this.premiumClaimed,
    required this.canClaimFree,
    required this.canClaimPremium,
    required this.onClaimFree,
    required this.onClaimPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Numero tier
            SizedBox(
              width: 40,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked ? AppColors.neonCyan.withOpacity(0.18) : AppColors.surface,
                    border: Border.all(color: unlocked ? AppColors.neonCyan : AppColors.border, width: 1.5),
                    boxShadow: unlocked ? [BoxShadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 8)] : null,
                  ),
                  child: Center(
                    child: Text('$tier',
                        style: TextStyle(
                            color: unlocked ? AppColors.neonCyan : AppColors.textMuted,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _RewardTile(
                reward: free,
                color: AppColors.neonCyan,
                unlocked: unlocked,
                claimed: freeClaimed,
                canClaim: canClaimFree,
                locked: false,
                onClaim: onClaimFree,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RewardTile(
                reward: premium,
                color: AppColors.neonGold,
                unlocked: unlocked,
                claimed: premiumClaimed,
                canClaim: canClaimPremium,
                locked: !premiumOwned,
                onClaim: onClaimPremium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final PassReward reward;
  final Color color;
  final bool unlocked, claimed, canClaim, locked;
  final VoidCallback onClaim;

  const _RewardTile({
    required this.reward,
    required this.color,
    required this.unlocked,
    required this.claimed,
    required this.canClaim,
    required this.locked,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !unlocked || locked;
    return GestureDetector(
      onTap: canClaim ? onClaim : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: claimed ? AppColors.success.withOpacity(0.06) : color.withOpacity(dim ? 0.04 : 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: claimed
                ? AppColors.success.withOpacity(0.4)
                : (canClaim ? color : color.withOpacity(dim ? 0.12 : 0.3)),
            width: canClaim ? 1.6 : 1,
          ),
          boxShadow: canClaim ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)] : null,
        ),
        child: Opacity(
          opacity: dim && !claimed ? 0.55 : 1,
          child: Row(
            children: [
              Text(reward.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reward.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dim ? AppColors.textMuted : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (claimed)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
              else if (canClaim)
                Icon(Icons.redeem_rounded, color: color, size: 18)
              else if (locked)
                Icon(Icons.lock_rounded, color: color.withOpacity(0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
