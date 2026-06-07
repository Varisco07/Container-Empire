import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../../../widgets/common/neon_text.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final coins = playerAsync.when(data: (p) => p.coins, loading: () => 0.0, error: (_, __) => 0.0);
    final gems = playerAsync.when(data: (p) => p.gems, loading: () => 0, error: (_, __) => 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SHOP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                _CurrChip('🪙', _fmt(coins), AppColors.coins),
                const SizedBox(width: 8),
                _CurrChip('💎', '$gems', AppColors.gems),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Pacchetti coin con gemme ──────────────────────────────────────
          _SectionHeader(title: 'SCAMBIA GEMME PER MONETE', icon: Icons.swap_horiz_rounded, color: AppColors.neonCyan),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _GemExchange(gems: 5,  coins: 2000,  color: AppColors.neonCyan),
              _GemExchange(gems: 10, coins: 5000,  color: AppColors.neonGreen),
              _GemExchange(gems: 25, coins: 15000, color: AppColors.neonPurple, isBest: true),
              _GemExchange(gems: 50, coins: 40000, color: AppColors.neonGold),
            ].asMap().entries.map((e) => _GemExchangeTile(
              exchange: e.value,
              canAfford: gems >= e.value.gems,
              onBuy: gems >= e.value.gems ? () async {
                final ok = await sl<PlayerService>().spendGems(e.value.gems);
                if (ok) {
                  await sl<PlayerService>().addCoins(e.value.coins);
                  ref.read(playerNotifierProvider.notifier).refresh();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ +${_fmt(e.value.coins)}€ ricevute!'),
                    backgroundColor: AppColors.coins,
                  ));
                }
              } : null,
            )).toList(),
          ),

          const SizedBox(height: 24),

          // ─── Pacchetti IAP (solo visual) ──────────────────────────────────
          _SectionHeader(title: 'PACCHETTI GEMME', icon: Icons.diamond_rounded, color: AppColors.gems),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _IapGemPack(gems: 50,   price: '0.99€'),
              _IapGemPack(gems: 150,  price: '2.49€', bonus: '+20%'),
              _IapGemPack(gems: 350,  price: '4.99€', bonus: '+40%'),
              _IapGemPack(gems: 800,  price: '9.99€', bonus: '+60%', isBest: true),
              _IapGemPack(gems: 2000, price: '19.99€', bonus: '+100%'),
              _IapGemPack(gems: 5000, price: '49.99€', bonus: '+150%'),
            ].map((p) => _IapGemPackCard(pack: p)).toList(),
          ),

          const SizedBox(height: 24),

          // ─── VIP ──────────────────────────────────────────────────────────
          _VipCard(),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _CurrChip extends StatelessWidget {
  final String icon, value; final Color color;
  const _CurrChip(this.icon, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    ]),
  );
}

// ─── Gem exchange ─────────────────────────────────────────────────────────────

class _GemExchange { final int gems; final double coins; final Color color; final bool isBest;
  const _GemExchange({required this.gems, required this.coins, required this.color, this.isBest = false});
}

class _GemExchangeTile extends StatelessWidget {
  final _GemExchange exchange; final bool canAfford; final VoidCallback? onBuy;
  const _GemExchangeTile({required this.exchange, required this.canAfford, this.onBuy});

  @override
  Widget build(BuildContext context) {
    final color = exchange.color;
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canAfford ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: canAfford ? color.withOpacity(0.6) : AppColors.border,
              width: exchange.isBest ? 2 : 1),
          boxShadow: exchange.isBest && canAfford
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('💎', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('${exchange.gems}', style: TextStyle(color: AppColors.gems,
                    fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
              Text('gemme', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(exchange.coins), style: TextStyle(
                  color: canAfford ? AppColors.coins : AppColors.textMuted,
                  fontWeight: FontWeight.w900, fontSize: 15)),
              const Text('🪙', style: TextStyle(fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

// ─── IAP gem packs ────────────────────────────────────────────────────────────

class _IapGemPack { final int gems; final String price; final String? bonus; final bool isBest;
  const _IapGemPack({required this.gems, required this.price, this.bonus, this.isBest = false});
}

class _IapGemPackCard extends StatelessWidget {
  final _IapGemPack pack;
  const _IapGemPackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquisti in-app non ancora configurati'),
            backgroundColor: AppColors.warning),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pack.isBest ? AppColors.gems : AppColors.border, width: pack.isBest ? 2 : 1),
          boxShadow: pack.isBest ? [BoxShadow(color: AppColors.gems.withOpacity(0.3), blurRadius: 16)] : null,
        ),
        child: Stack(
          children: [
            if (pack.isBest)
              Positioned(top: 0, right: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(color: AppColors.gems,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomLeft: Radius.circular(8))),
                child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              )),
            Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.diamond_rounded, color: AppColors.gems, size: 32),
                const SizedBox(height: 4),
                Text('${pack.gems}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                if (pack.bonus != null)
                  Text(pack.bonus!, style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.gems.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(pack.price, style: const TextStyle(color: AppColors.gems, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon; final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      NeonText(title, color: color, fontSize: 13, blurRadius: 8),
    ],
  );
}

// ─── VIP ─────────────────────────────────────────────────────────────────────

class _VipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.neonPurple.withOpacity(0.2), AppColors.neonCyan.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonPurple, width: 2),
        boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.neonPurple, size: 28),
            const SizedBox(width: 8),
            const NeonText('VIP PASS', color: AppColors.neonPurple, fontSize: 22, blurRadius: 12),
            const Spacer(),
            const Text('9.99€/mese', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          ...[
            '✦ +50% Fortuna permanente',
            '✦ +30% Valore vendita',
            '✦ 100 Gemme giornaliere',
            '✦ ×2 rate mutazione',
            '✦ Badge VIP esclusivo',
          ].map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('VIP non ancora configurato'), backgroundColor: AppColors.warning),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ATTIVA VIP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
