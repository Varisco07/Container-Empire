import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// REWARDED AD SERVICE
/// Astrazione per gli annunci con ricompensa. Oggi usa un annuncio DIMOSTRATIVO
/// (overlay con countdown) così il loop di monetizzazione è completo e testabile.
///
/// PER ATTIVARE GLI ANNUNCI VERI:
///   1. aggiungi `google_mobile_ads` al pubspec
///   2. configura l'App ID in AndroidManifest.xml e Info.plist
///   3. imposta gli ad unit id reali in [_adUnitId]
///   4. implementa il ramo `if (realAdsAvailable)` in [show] con
///      RewardedAd.load(...) + ad.show(onUserEarnedReward: ...) → return true
/// ─────────────────────────────────────────────────────────────────────────────
class RewardedAdService {
  // TODO: true quando google_mobile_ads è configurato.
  bool get realAdsAvailable => false;

  // TODO: sostituisci con gli ad unit id reali (test id di AdMob qui sotto).
  // ignore: unused_field
  static const String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Mostra un annuncio con ricompensa. Ritorna true se l'utente ha guadagnato
  /// la ricompensa (annuncio completato), false se ha chiuso prima.
  Future<bool> show(BuildContext context, {String reward = 'Ricompensa'}) async {
    if (realAdsAvailable) {
      // TODO: integrazione google_mobile_ads reale.
      return false;
    }
    return _showDemo(context, reward);
  }

  Future<bool> _showDemo(BuildContext context, String reward) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _DemoAdDialog(reward: reward),
    );
    return result ?? false;
  }
}

class _DemoAdDialog extends StatefulWidget {
  final String reward;
  const _DemoAdDialog({required this.reward});

  @override
  State<_DemoAdDialog> createState() => _DemoAdDialogState();
}

class _DemoAdDialogState extends State<_DemoAdDialog> {
  static const _seconds = 4;
  int _left = _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _left <= 0;
    return Dialog(
      backgroundColor: const Color(0xFF0A1322),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.neonCyan.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ANNUNCIO (DEMO)',
                      style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                // Chiudi (niente ricompensa) — disponibile solo dopo il countdown
                GestureDetector(
                  onTap: done ? () => Navigator.of(context).pop(false) : null,
                  child: Icon(Icons.close_rounded,
                      color: done ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.4), size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Finta creatività pubblicitaria
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3A5C), Color(0xFF2A1A5C)],
                ),
              ),
              child: const Center(child: Text('📺', style: TextStyle(fontSize: 64))),
            ),
            const SizedBox(height: 16),
            if (!done)
              Text('Ricompensa tra $_left s…',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700))
            else
              GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.neonGreen, Color(0xFF1FAE5A)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.4), blurRadius: 16)],
                  ),
                  child: Center(
                    child: Text('🎁  RISCUOTI: ${widget.reward}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
