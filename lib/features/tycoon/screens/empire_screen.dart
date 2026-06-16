import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/empire_building.dart';
import '../../../core/services/rewarded_ad_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/tycoon_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/player_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/port_city_background.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EMPIRE SCREEN — home cinematografica del Tycoon.
/// Città-porto animata + HUD glass + incasso idle + tap-to-earn + TURBO +
/// ASCENSION + strutture potenziabili.
/// ─────────────────────────────────────────────────────────────────────────────
class EmpireScreen extends ConsumerStatefulWidget {
  const EmpireScreen({super.key});

  @override
  ConsumerState<EmpireScreen> createState() => _EmpireScreenState();
}

class _EmpireScreenState extends ConsumerState<EmpireScreen> {
  TycoonService get _tycoon => sl<TycoonService>();
  Timer? _timer;

  final List<_Floater> _floaters = [];
  int _floatId = 0;

  @override
  void initState() {
    super.initState();
    // Accumula subito il tempo trascorso (es. tornando da un altro tab), POI
    // genera/rinnova il contratto: così il recupero offline non lo riempie gratis.
    _tycoon.accrue();
    _tycoon.ensureContract();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tycoon.tickLive(); // idle + TURBO live + avanzamento contratto del porto
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offline = _tycoon.consumeOfflineEarnings();
      if (offline > 0 && mounted) _showOfflineDialog(offline);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tycoon.accrue(); // cattura e salva i profitti fino all'uscita dalla pagina
    super.dispose();
  }

  // ── Azioni ──────────────────────────────────────────────────────────────────

  void _onTapCity(TapDownDetails d) {
    final v = _tycoon.tapEarn();
    HapticFeedback.lightImpact();
    final id = _floatId++;
    _floaters.add(_Floater(id, d.localPosition.dx, d.localPosition.dy, '+${fmtNum(v)}'));
    setState(() {});
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _floaters.removeWhere((f) => f.id == id));
    });
  }

  Future<void> _collect() async {
    final amount = await _tycoon.collect();
    if (amount <= 0) return;
    HapticFeedback.mediumImpact();
    ref.read(playerNotifierProvider.notifier).refresh();
    if (mounted) setState(() {});
    _snack('💰 Incassati +${fmtNum(amount)} 🪙', AppColors.success);
  }

  Future<void> _claimContract() async {
    final r = await _tycoon.claimContract();
    if (r == null) return;
    HapticFeedback.heavyImpact();
    ref.read(playerNotifierProvider.notifier).refresh();
    if (mounted) setState(() {});
    _snack('📦 ${r.title} consegnato! +${r.gems}💎  +${fmtNum(r.coins)} 🪙',
        AppColors.success);
  }

  Future<void> _buy(EmpireBuilding b) async {
    final ok = await _tycoon.buyUpgrade(b);
    if (ok) {
      HapticFeedback.selectionClick();
      ref.read(playerNotifierProvider.notifier).refresh();
      if (mounted) setState(() {});
    } else {
      _snack('Coins insufficienti per ${b.name}', AppColors.error);
    }
  }

  Future<void> _turbo() async {
    if (_tycoon.boostActive) {
      _snack('⚡ TURBO già attivo!', AppColors.neonCyan);
      return;
    }
    final ok = await sl<RewardedAdService>().show(context, reward: 'TURBO ×2 per 2 min');
    if (!ok) return;
    _tycoon.activateBoost(minutes: TycoonService.boostMinutes);
    HapticFeedback.mediumImpact();
    if (mounted) setState(() {});
    _snack('⚡ TURBO ×2 attivo!', AppColors.neonCyan);
  }

  void _tryAscend() {
    if (!_tycoon.canAscend) {
      _snack(
        'Per ascendere servono ${fmtNum(TycoonService.ascensionThreshold)}/s di profitto base '
        '(ora ${fmtNum(_tycoon.baseIncomePerSec)}/s)',
        AppColors.warning,
      );
      return;
    }
    _showAscensionDialog();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 1400),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(playerNotifierProvider).maybeWhen(
          data: (p) => p.coins,
          orElse: () => 0.0,
        );
    final incomeSec = _tycoon.totalIncomePerSec;
    final rank = _tycoon.rank;
    final boostActive = _tycoon.boostActive;

    return Scaffold(
      backgroundColor: const Color(0xFF050A18),
      body: Stack(
        children: [
          Positioned.fill(
            child: PortCityBackground(
              key: ValueKey('city_${rank.level}'),
              intensity: rank.level,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x66050A18), Color(0xCC050A18)],
                    stops: [0.0, 0.45, 0.78],
                  ),
                ),
              ),
            ),
          ),
          // Tap-to-earn sulla città (sotto la UI: le aree vuote raccolgono i tap)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _onTapCity,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopHud(rank: rank, incomeSec: incomeSec, boostActive: boostActive),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: _ContractCard(
                    contract: _tycoon.activeContract,
                    progress: _tycoon.contractProgress,
                    fraction: _tycoon.contractFraction,
                    timeLeft: _tycoon.contractTimeLeft,
                    ready: _tycoon.contractReady,
                    onClaim: _claimContract,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Text(
                      '👆 Tocca la città per profitti istantanei',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1400.ms),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CollectCard(
                    uncollected: _tycoon.uncollected,
                    incomeSec: incomeSec,
                    boostActive: boostActive,
                    onCollect: _collect,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ControlRow(
                    boostActive: boostActive,
                    boostRemaining: _tycoon.boostRemaining,
                    pendingPoints: _tycoon.pendingAscensionPoints,
                    ascensionPoints: _tycoon.ascensionPoints,
                    canAscend: _tycoon.canAscend,
                    baseIncome: _tycoon.baseIncomePerSec,
                    onTurbo: _turbo,
                    onAscend: _tryAscend,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 6,
                  child: _BuildingsPanel(tycoon: _tycoon, coins: coins, onBuy: _buy),
                ),
              ],
            ),
          ),
          // Numeri "+X" che volano via dal tap
          ..._floaters.map((f) => Positioned(
                left: f.x - 30,
                top: f.y - 24,
                child: IgnorePointer(
                  child: Text(
                    f.text,
                    style: const TextStyle(
                      color: AppColors.coins,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                    ),
                  )
                      .animate()
                      .moveY(begin: 0, end: -64, duration: 900.ms, curve: Curves.easeOut)
                      .fadeOut(delay: 350.ms, duration: 550.ms),
                ),
              )),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showOfflineDialog(double amount) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: GlassPanel(
          radius: 28,
          tint: AppColors.neonCyan.withOpacity(0.13),
          borderColor: AppColors.neonCyan.withOpacity(0.45),
          glow: AppColors.neonCyan,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛰️', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              const Text('IMPERO OPERATIVO',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              const Text('Mentre eri via le tue strutture\nhanno generato profitti:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFFFFE9A8), AppColors.coins, Color(0xFFFF9500)],
                ).createShader(r),
                child: Text('+${fmtNum(amount)} 🪙',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final ok = await sl<RewardedAdService>().show(context, reward: 'Profitti offline ×2');
                  if (ok) _tycoon.addBonus(amount);
                  await _collect();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.neonCyan, Color(0xFF3A6BD4)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.5), blurRadius: 18)],
                  ),
                  child: const Center(
                    child: Text('🎬  RADDOPPIA — GUARDA ANNUNCIO',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _collect();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.coins.withOpacity(0.5)),
                  ),
                  child: const Center(
                    child: Text('INCASSA',
                        style: TextStyle(
                            color: AppColors.coins, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 320.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  void _showAscensionDialog() {
    final gained = _tycoon.pendingAscensionPoints;
    final newMult = 1 + (_tycoon.ascensionPoints + gained) * TycoonService.ascensionBonusPerPoint;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (ctx) => _GlassDialog(
        emoji: '✦',
        title: 'ASCENSION',
        subtitle:
            'COSTO: azzeri TUTTI gli edifici (a livello 0)\ne i profitti non incassati.\nIn cambio: punti permanenti, +2% profitti\nPER SEMPRE per ogni punto.',
        bigText: '+$gained PUNTI',
        bigColor: AppColors.neonPurple,
        accent: AppColors.neonPurple,
        footer: 'Profitti globali → ×${newMult.toStringAsFixed(2)}',
        buttonLabel: 'ASCENDI',
        buttonColors: const [AppColors.neonPurple, Color(0xFF9B59B6)],
        secondaryLabel: 'Annulla',
        onSecondary: () => Navigator.of(ctx).pop(),
        onTap: () async {
          Navigator.of(ctx).pop();
          final r = await _tycoon.ascend();
          if (r.success) {
            HapticFeedback.heavyImpact();
            ref.read(playerNotifierProvider.notifier).refresh();
            if (mounted) setState(() {});
            _snack('✦ Ascension +${r.gained}! Profitti ×${r.newMultiplier.toStringAsFixed(2)}',
                AppColors.neonPurple);
          }
        },
      ),
    );
  }
}

class _Floater {
  final int id;
  final double x, y;
  final String text;
  _Floater(this.id, this.x, this.y, this.text);
}

// ─── Contratto del porto (obiettivo a tempo) ─────────────────────────────────

class _ContractCard extends StatelessWidget {
  final EmpireContract? contract;
  final double progress;
  final double fraction;
  final Duration timeLeft;
  final bool ready;
  final VoidCallback onClaim;

  const _ContractCard({
    required this.contract,
    required this.progress,
    required this.fraction,
    required this.timeLeft,
    required this.ready,
    required this.onClaim,
  });

  String _fmtDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = contract;
    if (c == null) return const SizedBox.shrink();
    final urgent = !ready && timeLeft.inSeconds <= 30;
    final accent = ready ? AppColors.success : (urgent ? AppColors.error : AppColors.neonOrange);

    final card = GlassPanel(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 11),
      tint: accent.withOpacity(0.10),
      borderColor: accent.withOpacity(ready ? 0.6 : 0.32),
      glow: ready ? AppColors.success : (urgent ? AppColors.error.withOpacity(0.6) : null),
      glowBlur: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('CONTRATTO',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(c.title.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ),
                    Text('Consegna 🪙 ${fmtNum(c.target)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!ready)
                    Text('⏳ ${_fmtDur(timeLeft)}',
                        style: TextStyle(
                            color: urgent ? AppColors.error : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900))
                  else
                    const Text('✓ PRONTO',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  Text('🎁 +${c.rewardGems}💎  +🪙 ${fmtNum(c.rewardCoins)}',
                      style: const TextStyle(
                          color: AppColors.gems, fontSize: 9.5, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(height: 10, color: Colors.white.withOpacity(0.06)),
                      FractionallySizedBox(
                        widthFactor: ready ? 1.0 : fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: ready
                                  ? const [AppColors.success, AppColors.neonGreen]
                                  : const [AppColors.neonOrange, AppColors.coins],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (ready)
                GestureDetector(
                  onTap: onClaim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.success, AppColors.neonGreen]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 12)],
                    ),
                    child: const Text('🎁 RISCATTA',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ),
                )
              else
                Text('${fmtNum(progress)} / ${fmtNum(c.target)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );

    // Pulsa leggermente quando è pronto da riscattare.
    return ready
        ? card.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
            begin: 1.0, end: 1.015, duration: 700.ms, curve: Curves.easeInOut)
        : card;
  }
}

// ─── Top HUD ───────────────────────────────────────────────────────────────────

class _TopHud extends StatelessWidget {
  final EmpireRank rank;
  final double incomeSec;
  final bool boostActive;
  const _TopHud({required this.rank, required this.incomeSec, required this.boostActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 16,
              tint: rank.color.withOpacity(0.10),
              borderColor: rank.color.withOpacity(0.4),
              glow: rank.color.withOpacity(0.6),
              glowBlur: 18,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: rank.color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: rank.color, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('LV ${rank.level} • IMPERO',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        Text(rank.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: rank.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: [Shadow(color: rank.color.withOpacity(0.6), blurRadius: 6)])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            radius: 16,
            tint: AppColors.uncommon.withOpacity(0.10),
            borderColor: (boostActive ? AppColors.neonCyan : AppColors.uncommon).withOpacity(0.45),
            glow: boostActive ? AppColors.neonCyan.withOpacity(0.6) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (boostActive)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text('⚡×2',
                            style: TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w900)),
                      ),
                    const Text('PROFITTO',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ],
                ),
                Text('${fmtNum(incomeSec)}/s',
                    style: TextStyle(
                        color: boostActive ? AppColors.neonCyan : AppColors.uncommon,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: boostActive ? AppColors.neonCyan : AppColors.uncommon, blurRadius: 6)
                        ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Collect hero card ─────────────────────────────────────────────────────────

class _CollectCard extends StatelessWidget {
  final double uncollected;
  final double incomeSec;
  final bool boostActive;
  final VoidCallback onCollect;
  const _CollectCard({
    required this.uncollected,
    required this.incomeSec,
    required this.boostActive,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfit = uncollected >= 1;
    return GlassPanel(
      radius: 26,
      tint: const Color(0x1AF5A623),
      borderColor: AppColors.coins.withOpacity(0.35),
      glow: hasProfit ? AppColors.coins : null,
      glowBlur: 30,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💰 ', style: TextStyle(fontSize: 13)),
              Text('PROFITTI ACCUMULATI',
                  style: TextStyle(
                      color: AppColors.coins.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFFE9A8), AppColors.coins, Color(0xFFFF9500)],
            ).createShader(r),
            child: Text(fmtNum(uncollected),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0.5)),
          ),
          Text('+${fmtNum(incomeSec)} / sec${boostActive ? '  ⚡' : ''}',
              style: const TextStyle(
                  color: AppColors.uncommon, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: hasProfit ? onCollect : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasProfit
                      ? const [AppColors.coins, Color(0xFFFF9500)]
                      : [AppColors.border, AppColors.border.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: hasProfit
                    ? [BoxShadow(color: AppColors.coins.withOpacity(0.5), blurRadius: 22, spreadRadius: -2)]
                    : null,
              ),
              child: Center(
                child: Text(hasProfit ? 'INCASSA PROFITTI' : 'IN PRODUZIONE...',
                    style: TextStyle(
                        color: hasProfit ? Colors.black : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(target: hasProfit ? 1 : 0)
        .shimmer(duration: 1800.ms, color: Colors.white.withOpacity(0.10), delay: 600.ms);
  }
}

// ─── Control row: TURBO + ASCENSION ──────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final bool boostActive;
  final Duration boostRemaining;
  final int pendingPoints;
  final int ascensionPoints;
  final bool canAscend;
  final double baseIncome;
  final VoidCallback onTurbo;
  final VoidCallback onAscend;

  const _ControlRow({
    required this.boostActive,
    required this.boostRemaining,
    required this.pendingPoints,
    required this.ascensionPoints,
    required this.canAscend,
    required this.baseIncome,
    required this.onTurbo,
    required this.onAscend,
  });

  String _fmtDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            color: AppColors.neonCyan,
            icon: '⚡',
            title: boostActive ? 'TURBO ×2' : 'ATTIVA TURBO',
            subtitle: boostActive ? _fmtDur(boostRemaining) : 'Guarda un annuncio',
            active: boostActive,
            onTap: onTurbo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            color: AppColors.neonPurple,
            icon: '✦',
            title: 'ASCENSION',
            // Mostra il "costo": quando puoi, +punti azzerando l'impero; quando
            // non puoi, la soglia di sblocco (profitto base richiesto).
            subtitle: canAscend
                ? '+$pendingPoints pt · azzeri l\'impero'
                : 'Sblocca a ${fmtNum(TycoonService.ascensionThreshold)}/s'
                    '${ascensionPoints > 0 ? ' · $ascensionPoints pt' : ''}',
            active: canAscend,
            onTap: onAscend,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Color color;
  final String icon, title, subtitle;
  final bool active;
  final VoidCallback onTap;
  const _ActionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tint: color.withOpacity(active ? 0.16 : 0.07),
        borderColor: color.withOpacity(active ? 0.5 : 0.25),
        glow: active ? color.withOpacity(0.55) : null,
        glowBlur: 16,
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 18, color: color)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active ? color : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3)),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active ? color.withOpacity(0.75) : AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Buildings panel ───────────────────────────────────────────────────────────

class _BuildingsPanel extends StatelessWidget {
  final TycoonService tycoon;
  final double coins;
  final void Function(EmpireBuilding) onBuy;
  const _BuildingsPanel({required this.tycoon, required this.coins, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Text('STRUTTURE DELL\'IMPERO',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
              physics: const BouncingScrollPhysics(),
              itemCount: empireBuildings.length,
              itemBuilder: (_, i) {
                final b = empireBuildings[i];
                final unlocked = tycoon.isUnlocked(b);
                final level = tycoon.level(b.id);
                final cost = tycoon.upgradeCost(b);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BuildingCard(
                    building: b,
                    level: level,
                    income: b.incomeAt(level),
                    nextIncome: b.incomeAt(level + 1),
                    cost: cost,
                    unlocked: unlocked,
                    canAfford: coins >= cost,
                    coins: coins,
                    onBuy: () => onBuy(b),
                  ),
                ).animate(delay: (i * 50).ms).fadeIn(duration: 280.ms).slideX(begin: 0.06, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final EmpireBuilding building;
  final int level;
  final double income, nextIncome, cost, coins;
  final bool unlocked, canAfford;
  final VoidCallback onBuy;

  const _BuildingCard({
    required this.building,
    required this.level,
    required this.income,
    required this.nextIncome,
    required this.cost,
    required this.unlocked,
    required this.canAfford,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final color = building.color;
    final locked = !unlocked;

    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(12),
      tint: locked ? const Color(0x0AFFFFFF) : color.withOpacity(0.08),
      borderColor: locked ? AppColors.border : color.withOpacity(0.35),
      glow: (!locked && level > 0) ? color.withOpacity(0.5) : null,
      glowBlur: 16,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.28), color.withOpacity(0.06)],
                ),
                border: Border.all(color: color.withOpacity(0.5)),
                boxShadow: locked ? null : [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)],
              ),
              child: Center(child: Text(building.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(building.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: locked ? AppColors.textSecondary : color,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3)),
                      ),
                      if (level > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Text('LV $level',
                              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (locked) ...[
                    const Text('🔒 Sblocca la struttura precedente',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text('Sblocco: 🪙 ${fmtNum(cost)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                  ] else ...[
                    Text(level > 0 ? '+${fmtNum(income)}/s' : 'Non ancora attiva',
                        style: TextStyle(
                            color: level > 0 ? AppColors.uncommon : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text('→ +${fmtNum(nextIncome)}/s',
                        style: TextStyle(color: color.withOpacity(0.6), fontSize: 9.5)),
                    const SizedBox(height: 2),
                    // Costo esplicito dell'espansione (verde se te lo puoi permettere)
                    Text(
                      '${level == 0 ? 'Costruisci' : 'Espandi'}: 🪙 ${fmtNum(cost)}',
                      style: TextStyle(
                        color: canAfford ? AppColors.success : AppColors.error.withOpacity(0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!canAfford)
                      Text('Ti mancano 🪙 ${fmtNum(cost - coins)}',
                          style: TextStyle(
                            color: AppColors.warning.withOpacity(0.9),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          )),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (locked || !canAfford) ? null : onBuy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minWidth: 78),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  gradient: (!locked && canAfford)
                      ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                      : null,
                  color: (!locked && canAfford) ? null : AppColors.border.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: (!locked && canAfford)
                      ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 12)]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level == 0 ? 'COSTRUISCI' : 'POTENZIA',
                        style: TextStyle(
                            color: (!locked && canAfford) ? Colors.white : AppColors.textMuted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(fmtNum(cost),
                            style: TextStyle(
                                color: (!locked && canAfford) ? Colors.white : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass dialog (offline / ascension) ──────────────────────────────────────

class _GlassDialog extends StatelessWidget {
  final String emoji, title, subtitle, bigText, buttonLabel;
  final Color bigColor, accent;
  final List<Color> buttonColors;
  final String? footer;
  final String? secondaryLabel;
  final VoidCallback onTap;
  final VoidCallback? onSecondary;

  const _GlassDialog({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bigText,
    required this.bigColor,
    required this.accent,
    required this.buttonLabel,
    required this.buttonColors,
    required this.onTap,
    this.footer,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassPanel(
        radius: 28,
        tint: accent.withOpacity(0.13),
        borderColor: accent.withOpacity(0.45),
        glow: accent,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (r) => LinearGradient(
                colors: [bigColor.withOpacity(0.7), bigColor, Colors.white],
              ).createShader(r),
              child: Text(bigText,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
            if (footer != null) ...[
              const SizedBox(height: 4),
              Text(footer!,
                  style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: buttonColors),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: buttonColors.first.withOpacity(0.5), blurRadius: 18)],
                ),
                child: Center(
                  child: Text(buttonLabel,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onSecondary,
                child: Text(secondaryLabel!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 320.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}
