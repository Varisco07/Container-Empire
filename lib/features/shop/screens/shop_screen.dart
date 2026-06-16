import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../../../widgets/common/neon_text.dart';

// ─── Provider IAP ─────────────────────────────────────────────────────────────

final iapStateProvider = StreamProvider<IapState>((ref) {
  return sl<IapService>().stateStream;
});

// ─── Shop Screen ──────────────────────────────────────────────────────────────

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _pendingProduct; // prodotto in acquisto

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final iapAsync   = ref.watch(iapStateProvider);
    final coins = playerAsync.when(data: (p) => p.coins, loading: () => 0.0, error: (_, __) => 0.0);
    final gems  = playerAsync.when(data: (p) => p.gems,  loading: () => 0,   error: (_, __) => 0);
    final isVip = playerAsync.when(data: (p) => p.isVip, loading: () => false, error: (_, __) => false);

    final iapState = iapAsync.when(
      data: (s) => s,
      loading: () => sl<IapService>().currentState,
      error: (_, __) => sl<IapService>().currentState,
    );

    // Reset pendingProduct quando l'acquisto finisce
    if (iapState.status != IapStatus.purchasing && _pendingProduct != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingProduct = null);
      });
    }

    // Mostra errori IAP come snackbar
    if (iapState.status == IapStatus.error && iapState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(iapState.errorMessage!),
            backgroundColor: AppColors.error,
          ));
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SHOP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(children: [
              _CurrChip('🪙', _fmt(coins), AppColors.coins),
              const SizedBox(width: 8),
              _CurrChip('💎', '$gems', AppColors.gems),
              const SizedBox(width: 8),
            ]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Banner se su Web (IAP non disponibile) ──────────────────
          if (iapState.status == IapStatus.unavailable)
            _WebBanner(message: iapState.errorMessage ??
                'Acquisti disponibili su iOS e Android'),

          if (iapState.status == IapStatus.unavailable)
            const SizedBox(height: 16),

          // ── Scambia gemme per monete ──────────────────────────────────
          const _SectionHeader(
              title: 'SCAMBIA GEMME PER MONETE',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.neonCyan),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              const _GemExchange(gems: 5,  coins: 2000,  color: AppColors.neonCyan),
              const _GemExchange(gems: 10, coins: 5000,  color: AppColors.neonGreen),
              const _GemExchange(gems: 25, coins: 15000, color: AppColors.neonPurple, isBest: true),
              const _GemExchange(gems: 50, coins: 40000, color: AppColors.neonGold),
            ].asMap().entries.map((e) => _GemExchangeTile(
              exchange: e.value,
              canAfford: gems >= e.value.gems,
              onBuy: gems >= e.value.gems ? () async {
                final ok = await sl<PlayerService>().spendGems(e.value.gems);
                if (ok) {
                  await sl<PlayerService>().addCoins(e.value.coins);
                  ref.read(playerNotifierProvider.notifier).refresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ +${_fmt(e.value.coins)} 🪙 ricevute!'),
                    backgroundColor: AppColors.coins,
                  ));
                  }
                }
              } : null,
            )).toList(),
          ),

          const SizedBox(height: 28),

          // ── Pacchetti Gemme (REALI) ──────────────────────────────────
          const _SectionHeader(
              title: 'ACQUISTA GEMME',
              icon: Icons.diamond_rounded,
              color: AppColors.gems),
          const SizedBox(height: 4),
          if (iapState.status == IapStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _gemPacks.map((pack) {
                final product = iapState.products[pack.productId];
                final isPending = _pendingProduct == pack.productId;
                final isPurchasing = iapState.status == IapStatus.purchasing;
                return _GemPackCard(
                  pack: pack,
                  product: product,
                  isPending: isPending,
                  disabled: isPurchasing,
                  onBuy: isPurchasing ? null : () => _buyProduct(pack.productId, iapState),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 28),

          // ── VIP ────────────────────────────────────────────────────────
          _VipCard(
            isVip: isVip,
            product: iapState.products[IapProducts.vipMonthly],
            isPending: _pendingProduct == IapProducts.vipMonthly,
            disabled: iapState.status == IapStatus.purchasing,
            onBuy: iapState.status == IapStatus.purchasing
                ? null
                : () => _buyProduct(IapProducts.vipMonthly, iapState),
            onRestore: () async {
              await sl<IapService>().restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Acquisti ripristinati'),
                backgroundColor: AppColors.neonCyan,
              ));
              }
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Acquisto ──────────────────────────────────────────────────────────────

  Future<void> _buyProduct(String productId, IapState state) async {
    if (state.status == IapStatus.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.errorMessage ?? 'Acquisti non disponibili su questo dispositivo'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() => _pendingProduct = productId);
    await sl<IapService>().buyProduct(productId);
    // Il risultato arriva via purchaseStream → IapState aggiornato
    ref.read(playerNotifierProvider.notifier).refresh();
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Dati pacchetti gemme ─────────────────────────────────────────────────────

class _GemPackData {
  final String productId;
  final int gems;
  final String fallbackPrice;
  final String? bonus;
  final bool isBest;
  const _GemPackData({
    required this.productId, required this.gems,
    required this.fallbackPrice, this.bonus, this.isBest = false,
  });
}

const _gemPacks = [
  _GemPackData(productId: IapProducts.gems50,   gems: 50,   fallbackPrice: '0.99€'),
  _GemPackData(productId: IapProducts.gems150,  gems: 150,  fallbackPrice: '2.49€', bonus: '+20%'),
  _GemPackData(productId: IapProducts.gems350,  gems: 350,  fallbackPrice: '4.99€', bonus: '+40%'),
  _GemPackData(productId: IapProducts.gems800,  gems: 800,  fallbackPrice: '9.99€', bonus: '+60%', isBest: true),
  _GemPackData(productId: IapProducts.gems2000, gems: 2000, fallbackPrice: '19.99€', bonus: '+100%'),
  _GemPackData(productId: IapProducts.gems5000, gems: 5000, fallbackPrice: '49.99€', bonus: '+150%'),
];

// ─── Card pacchetto gemme ─────────────────────────────────────────────────────

class _GemPackCard extends StatelessWidget {
  final _GemPackData pack;
  final ProductDetails? product;
  final bool isPending;
  final bool disabled;
  final VoidCallback? onBuy;
  const _GemPackCard({
    required this.pack, this.product,
    required this.isPending, required this.disabled, this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = product?.price ?? pack.fallbackPrice;
    return GestureDetector(
      onTap: disabled ? null : onBuy,
      child: AnimatedOpacity(
        opacity: disabled && !isPending ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pack.isBest ? AppColors.gems : AppColors.border,
              width: pack.isBest ? 2 : 1,
            ),
            boxShadow: pack.isBest
                ? [BoxShadow(color: AppColors.gems.withOpacity(0.3), blurRadius: 16)]
                : null,
          ),
          child: Stack(
            children: [
              // Badge BEST
              if (pack.isBest)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.gems,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(8)),
                    ),
                    child: const Text('BEST',
                        style: TextStyle(color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w900)),
                  ),
                ),

              Center(
                child: isPending
                    ? const CircularProgressIndicator(color: AppColors.gems)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond_rounded, color: AppColors.gems, size: 32),
                          const SizedBox(height: 4),
                          Text('${pack.gems}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          if (pack.bonus != null)
                            Text(pack.bonus!,
                                style: const TextStyle(
                                    color: AppColors.neonGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gems.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(priceStr,
                                style: const TextStyle(
                                    color: AppColors.gems,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── VIP Card ─────────────────────────────────────────────────────────────────

class _VipCard extends StatelessWidget {
  final bool isVip;
  final ProductDetails? product;
  final bool isPending;
  final bool disabled;
  final VoidCallback? onBuy;
  final VoidCallback? onRestore;
  const _VipCard({
    required this.isVip, this.product,
    required this.isPending, required this.disabled,
    this.onBuy, this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = product?.price ?? '9.99€/mese';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.neonPurple.withOpacity(0.2),
          AppColors.neonCyan.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVip ? AppColors.neonGold : AppColors.neonPurple,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isVip ? AppColors.neonGold : AppColors.neonPurple).withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.workspace_premium_rounded,
                color: isVip ? AppColors.neonGold : AppColors.neonPurple, size: 28),
            const SizedBox(width: 8),
            NeonText('VIP PASS',
                color: isVip ? AppColors.neonGold : AppColors.neonPurple,
                fontSize: 22, blurRadius: 12),
            const Spacer(),
            if (!isVip)
              Text(priceStr,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            if (isVip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonGold),
                ),
                child: const Text('✅ ATTIVO',
                    style: TextStyle(
                        color: AppColors.neonGold,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
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
            child: Text(f, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
          )),
          const SizedBox(height: 16),
          if (!isVip)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isPending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ATTIVA VIP',
                        style: TextStyle(fontWeight: FontWeight.w900,
                            letterSpacing: 2, fontSize: 16)),
              ),
            ),
          if (!isVip) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onRestore,
                child: const Text('Ripristina acquisti',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Web Banner ───────────────────────────────────────────────────────────────

class _WebBanner extends StatelessWidget {
  final String message;
  const _WebBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.warning.withOpacity(0.5)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.warning, fontSize: 12))),
    ]),
  );
}

// ─── Gem Exchange ─────────────────────────────────────────────────────────────

class _GemExchange {
  final int gems; final double coins; final Color color; final bool isBest;
  const _GemExchange({required this.gems, required this.coins,
      required this.color, this.isBest = false});
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
          border: Border.all(
              color: canAfford ? color.withOpacity(0.6) : AppColors.border,
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
                Text('${exchange.gems}', style: const TextStyle(
                    color: AppColors.gems, fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
              const Text('gemme', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
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
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon; final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 8),
    NeonText(title, color: color, fontSize: 13, blurRadius: 8),
  ]);
}

// ─── Currency chip ────────────────────────────────────────────────────────────

class _CurrChip extends StatelessWidget {
  final String icon, value; final Color color;
  const _CurrChip(this.icon, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(
          color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    ]),
  );
}
