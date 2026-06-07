import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/container_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/rarity.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/rng_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../../../widgets/common/lucky_meter.dart';
import '../../../widgets/common/neon_text.dart';
import '../../../widgets/common/share_drop_dialog.dart';
import '../game/container_animation_widget.dart';
import '../widgets/item_reveal_card.dart';
import '../widgets/roulette_widget.dart';

enum OpeningPhase { idle, roulette, opening, reveal, multiReveal, batchRoulette }

class ContainerOpeningScreen extends ConsumerStatefulWidget {
  final String containerId;
  const ContainerOpeningScreen({super.key, required this.containerId});

  @override
  ConsumerState<ContainerOpeningScreen> createState() => _ContainerOpeningScreenState();
}

class _ContainerOpeningScreenState extends ConsumerState<ContainerOpeningScreen> {
  late ContainerModel _container;
  OpeningPhase _phase = OpeningPhase.idle;
  ItemModel? _revealedItem;
  bool _isBusy = false;
  bool _actionDone = false;
  String _actionMessage = '';

  int _quantity = 1;
  List<ItemModel> _multiItems = [];

  bool _showLevelUp = false;
  int _levelUpNewLevel = 1;
  double _levelUpCoins = 0;
  int _levelUpGems = 0;

  @override
  void initState() {
    super.initState();
    _container = containerCatalog.firstWhere((c) => c.id == widget.containerId);
  }

  Color get _containerColor {
    final hex = _container.colorHex.replaceFirst('#', '');
    return Color(int.parse('ff$hex', radix: 16));
  }

  String get _containerEmoji => _emojis[_container.id] ?? '📦';
  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
  };

  Future<void> _startOpening() async {
    if (_isBusy) return;
    final ps = sl<PlayerService>();
    final player = ps.localPlayer;
    if (player == null) return;

    if (!_container.isFree && player.coins < _container.cost) {
      _showSnack('Monete insufficienti! Serve ${_fmt(_container.cost)}€', AppColors.error);
      return;
    }

    final forcedRare = player.pityReady;
    final item = sl<RngService>().rollItem(
      container: _container, player: player, forcedRare: forcedRare,
    );

    if (!_container.isFree) {
      await ps.spendCoins(_container.cost);
    } else {
      await ps.markFreeContainerClaimed();
    }

    final rng = sl<RngService>();
    if (rng.isRarePlus(item.rarityKey)) {
      await ps.resetPity();
      await ps.incrementRaresFound();
    } else {
      await ps.incrementPity();
    }

    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() { _isBusy = true; _revealedItem = item; _phase = OpeningPhase.roulette; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = OpeningPhase.opening);
  }

  void _onContainerAnimComplete() {
    setState(() => _phase = OpeningPhase.reveal);
    _saveItem();
  }

  Future<void> _saveItem() async {
    if (_revealedItem == null) return;
    await sl<InventoryService>().addItem(_revealedItem!);
    final result = await sl<PlayerService>().incrementContainersOpened();
    ref.read(playerNotifierProvider.notifier).refresh();
    if (result.didLevelUp && mounted) {
      setState(() {
        _showLevelUp = true;
        _levelUpNewLevel = result.newLevel;
        _levelUpCoins = result.coinsBonus;
        _levelUpGems = result.gemsBonus;
      });
    }
  }

  Future<void> _startMultiOpening() async {
    if (_isBusy || _container.isFree) return;
    final ps = sl<PlayerService>();
    final player = ps.localPlayer;
    if (player == null) return;

    final totalCost = _container.cost * _quantity;
    if (player.coins < totalCost) {
      final canAfford = (player.coins / _container.cost).floor();
      _showSnack(
        canAfford == 0
            ? 'Monete insufficienti!'
            : 'Puoi aprire solo $canAfford container (hai ${_fmtShort(player.coins)}€)',
        AppColors.error,
      );
      return;
    }

    setState(() => _isBusy = true);
    await ps.spendCoins(totalCost);
    ref.read(playerNotifierProvider.notifier).refresh();

    final rng = sl<RngService>();
    final inv = sl<InventoryService>();
    final items = <ItemModel>[];
    LevelUpResult? lastLevelUp;

    // Pity triggers at most once per batch (not per roll)
    final batchForcedRare = ps.localPlayer?.pityReady ?? false;
    bool pityUsed = false;

    for (int i = 0; i < _quantity; i++) {
      final p = ps.localPlayer!;
      // Use batch roll (reduced luck) — pity only fires once per batch
      final forcedRare = batchForcedRare && !pityUsed;
      // Use rollItemBatch for reduced luck in bulk opens
      final item = rng.rollItemBatch(container: _container, player: p, forcedRare: forcedRare);

      if (rng.isRarePlus(item.rarityKey)) {
        await ps.resetPity();
        await ps.incrementRaresFound();
        if (forcedRare) pityUsed = true;
      } else {
        await ps.incrementPity();
      }

      await inv.addItem(item);
      final lu = await ps.incrementContainersOpened();
      if (lu.didLevelUp) lastLevelUp = lu;
      items.add(item);
    }

    // Pick best item (highest value) to show in roulette preview
    final bestItem = items.reduce((a, b) => a.finalValue > b.finalValue ? a : b);

    // Show roulette animation with best item, THEN reveal all results
    setState(() {
      _revealedItem = bestItem;
      _multiItems = items;
      _phase = OpeningPhase.batchRoulette;
    });

    // Wait for roulette animation to play
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // Apply level-up overlay if needed
    final lu = lastLevelUp;
    if (lu != null) {
      setState(() {
        _showLevelUp = true;
        _levelUpNewLevel = lu.newLevel;
        _levelUpCoins = lu.coinsBonus;
        _levelUpGems = lu.gemsBonus;
      });
    }

    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() { _phase = OpeningPhase.multiReveal; });
  }

  Future<void> _keepItem() async {
    if (_actionDone) return;
    setState(() { _actionDone = true; _actionMessage = '📦 Tenuto nell\'inventario!'; });
  }

  Future<void> _sellItem() async {
    if (_actionDone || _revealedItem == null) return;
    final value = await sl<InventoryService>().sellItem(_revealedItem!.id);
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() { _actionDone = true; _actionMessage = '💰 Venduto: +${_fmtShort(value)}€'; });
  }

  Future<void> _multiSellAll() async {
    double total = 0;
    for (final item in _multiItems) total += await sl<InventoryService>().sellItem(item.id);
    ref.read(playerNotifierProvider.notifier).refresh();
    _showSnack('💰 Venduto tutto: +${_fmtShort(total)}€', AppColors.coins);
    _reset();
  }

  Future<void> _multiSellCommon() async {
    final inv = sl<InventoryService>();
    double total = 0;
    final toSell = _multiItems.where((i) => i.rarity == Rarity.common || i.rarity == Rarity.uncommon).toList();
    for (final item in toSell) total += await inv.sellItem(item.id);
    ref.read(playerNotifierProvider.notifier).refresh();
    _showSnack('💰 Venduti ${toSell.length} comuni (+${_fmtShort(total)}€), tenuti ${_multiItems.length - toSell.length} rari+', AppColors.coins);
    _reset();
  }

  Future<void> _multiKeepAll() async {
    _showSnack('📦 Tutto salvato in inventario!', AppColors.neonCyan);
    _reset();
  }

  void _reset() {
    setState(() {
      _phase = OpeningPhase.idle;
      _revealedItem = null;
      _multiItems = [];
      _isBusy = false;
      _actionDone = false;
      _actionMessage = '';
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  String _fmtShort(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_container.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: (_phase == OpeningPhase.idle ||
                      _phase == OpeningPhase.reveal ||
                      _phase == OpeningPhase.multiReveal)
                  ? () => context.pop()
                  : null, // disabled during animations
            ),
          ),
          body: _buildBody(),
        ),
        if (_showLevelUp)
          _LevelUpOverlay(
            level: _levelUpNewLevel,
            coinsBonus: _levelUpCoins,
            gemsBonus: _levelUpGems,
            onDismiss: () => setState(() => _showLevelUp = false),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case OpeningPhase.roulette:
        return RouletteWidget(container: _container, revealedItem: _revealedItem);
      case OpeningPhase.batchRoulette:
        return Stack(
          children: [
            RouletteWidget(container: _container, revealedItem: _revealedItem),
            // Banner at the top showing how many containers are being opened
            Positioned(
              top: 12, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _containerColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _containerColor.withOpacity(0.4), blurRadius: 16)],
                  ),
                  child: Text(
                    '🎰  Apertura di $_quantity container...',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                        fontSize: 14, letterSpacing: 1),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1200.ms, color: Colors.white38),
              ),
            ),
            // Bottom label: "Miglior oggetto trovato"
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Center(
                child: Text(
                  '✨ Miglior oggetto trovato',
                  style: TextStyle(color: _containerColor, fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 1),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms),
              ),
            ),
          ],
        );
      case OpeningPhase.opening:
        return ContainerAnimationWidget(
          onAnimationComplete: _onContainerAnimComplete,
          containerColor: _containerColor,
          containerEmoji: _containerEmoji,
          revealedItem: _revealedItem,
        );
      case OpeningPhase.reveal:
        return _RevealPhase(
          item: _revealedItem!, onKeep: _keepItem, onSell: _sellItem,
          onOpenAnother: _reset, actionDone: _actionDone, actionMessage: _actionMessage,
          username: sl<PlayerService>().localPlayer?.username ?? 'Player',
        );
      case OpeningPhase.multiReveal:
        return _MultiRevealPhase(
          items: _multiItems, container: _container, containerColor: _containerColor,
          onSellAll: _multiSellAll, onSellCommon: _multiSellCommon,
          onKeepAll: _multiKeepAll, onOpenAnother: _reset,
        );
      case OpeningPhase.idle:
        final player = sl<PlayerService>().localPlayer;
        return _IdlePhase(
          container: _container, containerColor: _containerColor,
          containerEmoji: _containerEmoji, quantity: _quantity,
          pityCounter: player?.pityCounter ?? 0,
          onQuantityChanged: (q) => setState(() => _quantity = q),
          onOpen: _quantity == 1 ? _startOpening : _startMultiOpening,
        );
    }
  }
}

// ─── Level-up Overlay ─────────────────────────────────────────────────────────

class _LevelUpOverlay extends StatelessWidget {
  final int level;
  final double coinsBonus;
  final int gemsBonus;
  final VoidCallback onDismiss;
  const _LevelUpOverlay({required this.level, required this.coinsBonus, required this.gemsBonus, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.neonCyan.withOpacity(0.2), AppColors.neonPurple.withOpacity(0.15)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.neonCyan, width: 2),
              boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.5), blurRadius: 40, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
                const SizedBox(height: 16),
                const Text('LEVEL UP!',
                    style: TextStyle(color: AppColors.neonCyan, fontSize: 28, fontWeight: FontWeight.w900,
                        letterSpacing: 4, shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 20)]))
                    .animate().fadeIn().scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [AppColors.neonCyan, AppColors.neonPurple],
                  ).createShader(r),
                  child: Text('LIVELLO $level',
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('RICOMPENSE',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RewardChip('🪙', '+${_fmt(coinsBonus)}€', AppColors.coins),
                          _RewardChip('💎', '+$gemsBonus', AppColors.gems),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                Text('Tocca per continuare',
                    style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12))
                    .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms),
              ],
            ),
          ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 600.ms),
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

class _RewardChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _RewardChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
      ]),
    );
  }
}

// ─── Idle Phase ───────────────────────────────────────────────────────────────

class _IdlePhase extends StatelessWidget {
  final ContainerModel container;
  final Color containerColor;
  final String containerEmoji;
  final int quantity;
  final int pityCounter;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onOpen;

  const _IdlePhase({
    required this.container, required this.containerColor, required this.containerEmoji,
    required this.quantity, required this.pityCounter,
    required this.onQuantityChanged, required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = container.cost * quantity;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [containerColor.withOpacity(0.25), containerColor.withOpacity(0.05)]),
                border: Border.all(color: containerColor, width: 2),
                boxShadow: [BoxShadow(color: containerColor.withOpacity(0.5), blurRadius: 50, spreadRadius: 6)],
              ),
              child: Center(child: Text(containerEmoji, style: const TextStyle(fontSize: 80))),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1800.ms),
            const SizedBox(height: 20),
            NeonText(container.name, color: containerColor, fontSize: 20, fontWeight: FontWeight.w900, blurRadius: 14),
            const SizedBox(height: 4),
            Text(container.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 28),

            if (!container.isFree) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('QUANTI CONTAINER APRIRE?',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _QtyBtn(icon: Icons.remove_rounded, color: containerColor,
                            onTap: () { if (quantity > 1) onQuantityChanged(quantity - 1); },
                            onLongPress: () => onQuantityChanged(1)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showQtyDialog(context, quantity, onQuantityChanged, containerColor),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: containerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: containerColor.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  Text('$quantity', textAlign: TextAlign.center,
                                      style: TextStyle(color: containerColor, fontSize: 28, fontWeight: FontWeight.w900)),
                                  Text('tocca per digitare',
                                      style: TextStyle(color: containerColor.withOpacity(0.5), fontSize: 9)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _QtyBtn(icon: Icons.add_rounded, color: containerColor,
                            onTap: () { if (quantity < 100) onQuantityChanged(quantity + 1); },
                            onLongPress: () => onQuantityChanged(100)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [1, 5, 10, 25, 50, 100].map((n) {
                        final sel = quantity == n;
                        return GestureDetector(
                          onTap: () => onQuantityChanged(n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? containerColor.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? containerColor : AppColors.border),
                            ),
                            child: Text('$n', style: TextStyle(
                              color: sel ? containerColor : AppColors.textMuted,
                              fontSize: 12, fontWeight: sel ? FontWeight.w900 : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.coins.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.coins.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text('Costo totale: ${_fmt(totalCost)}',
                              style: const TextStyle(color: AppColors.coins, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: containerColor,
                  foregroundColor: _isDark(containerColor) ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0,
                ),
                child: Text(
                  container.isFree ? '🔓   APRI GRATIS'
                      : quantity == 1 ? '🔓   APRI · ${_fmt(container.cost)}'
                          : '🔓   APRI $quantity × ${_fmt(container.cost)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),

            // Lucky Meter
            LuckyMeter(pityCounter: pityCounter)
                .animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.15, end: 0),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQtyDialog(BuildContext ctx, int current, ValueChanged<int> onChanged, Color color) {
    final ctrl = TextEditingController(text: '$current');
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quanti container?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '1–100', hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              onChanged((int.tryParse(ctrl.text) ?? current).clamp(1, 100));
              Navigator.of(dCtx).pop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  bool _isDark(Color c) => (c.red * 299 + c.green * 587 + c.blue * 114) / 1000 < 128;
  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final VoidCallback onTap; final VoidCallback? onLongPress;
  const _QtyBtn({required this.icon, required this.color, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, onLongPress: onLongPress,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(icon, color: color, size: 24),
    ),
  );
}

// ─── Multi Reveal ─────────────────────────────────────────────────────────────

class _MultiRevealPhase extends StatelessWidget {
  final List<ItemModel> items;
  final ContainerModel container;
  final Color containerColor;
  final VoidCallback onSellAll, onSellCommon, onKeepAll, onOpenAnother;

  const _MultiRevealPhase({
    required this.items, required this.container, required this.containerColor,
    required this.onSellAll, required this.onSellCommon, required this.onKeepAll,
    required this.onOpenAnother,
  });

  @override
  Widget build(BuildContext context) {
    final totalValue = items.fold(0.0, (s, i) => s + i.finalValue);
    final rareCounts = <String, int>{};
    for (final item in items) rareCounts[item.rarityKey] = (rareCounts[item.rarityKey] ?? 0) + 1;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [containerColor.withOpacity(0.15), containerColor.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: containerColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Text(_emojis[container.id] ?? '📦', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${items.length} container aperti',
                      style: TextStyle(color: containerColor, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text('Valore totale: ${_fmt(totalValue)}',
                      style: const TextStyle(color: AppColors.coins, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: rareCounts.entries.take(4).map((e) => Text(
                  '${e.value}× ${_short(e.key)}',
                  style: TextStyle(color: AppColors.rarityColor(e.key), fontSize: 10, fontWeight: FontWeight.w700),
                )).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: items.length,
            itemBuilder: (_, i) => _MultiItemRow(item: items[i], index: i),
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(color: AppColors.navBackground,
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: _ActionBtn(label: 'TIENI TUTTO', icon: '📦', color: AppColors.neonCyan, onTap: onKeepAll)),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn(label: 'VENDI COMUNI', icon: '♻️', color: AppColors.neonOrange, onTap: onSellCommon, sublabel: 'Tieni Raro+')),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn(label: 'VENDI TUTTO', icon: '💰', color: AppColors.coins, onTap: onSellAll, sublabel: _fmt(totalValue))),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenAnother,
                icon: const Text('🔄', style: TextStyle(fontSize: 14)),
                label: const Text('APRI ALTRI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  static const _emojis = {
    'free': '📦', 'basic': '🗃️', 'industrial': '🏭',
    'military': '🪖', 'luxury': '👑', 'space': '🛸', 'quantum': '⚛️',
  };
  String _short(String k) => {'common': 'Comune', 'uncommon': 'NonCom.', 'rare': 'Raro',
      'epic': 'Epico', 'legendary': 'Legg.', 'mythic': 'Mitico', 'divine': 'Divino', 'secret': 'Seg.'}[k] ?? k;
  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B€';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

class _MultiItemRow extends StatelessWidget {
  final ItemModel item; final int index;
  const _MultiItemRow({required this.item, required this.index});

  static const _emojis = {
    'Bullone Arrugginito': '🔩', 'Bottiglia Vuota': '🍶', 'Chiave Inglese': '🔧',
    'Orologio Rotto': '⌚', 'Moneta Antica': '🪙', 'Cacciavite': '🪛',
    'Martello': '🔨', 'Smartphone Vecchio': '📱', 'Orologio Vintage': '⌚',
    'Chitarra Acustica': '🎸', 'Vaso Ming': '🏺', 'Trapano Industriale': '🔧',
    'Saldatrice': '⚡', 'Generatore': '🔋', 'CNC Machine Part': '⚙️',
    'Prototipo Robot': '🤖', 'Core Nucleare Piccolo': '☢️', 'Elmetto Tattico': '🪖',
    'Giubbotto Antiproiettile': '🦺', 'Drone Militare': '🚁', 'Visore Notturno': '🔭',
    'Esoscheletro Prototipo': '🦾', 'Stealth Tech Module': '🛡️',
    'Orologio Rolex': '⌚', 'Borsa Hermès': '👜', 'Anello con Diamante': '💍',
    'Quadro Picasso': '🖼️', 'Corona Reale': '👑', 'Ferrari Miniatura d\'Oro': '🏎️',
    'Meteorite Frammento': '☄️', 'Luna Rock Certificato': '🌙',
    'Satellite Disattivato': '🛰️', 'Cristallo Alieno': '💎',
    'Stardust Vial': '✨', 'Nucleo di Stella di Neutroni': '⭐',
    'Bit Quantistico': '🔮', 'Entangled Particle Pair': '🌀',
    'Quantum Processor': '💻', 'Materia Oscura Campione': '🕳️',
    'Singolarità Compressa': '🌌', 'Frammento Big Bang': '💥',
    'Ω Omega Particle': '⚛️',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(item.rarityKey);
    final emoji = _emojis[item.name] ?? '📦';
    final hasMutation = item.mutation != Mutation.none;
    final mutColor = hasMutation ? AppColors.mutationColor(item.mutationKey) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(hasMutation ? 0.8 : 0.35), width: hasMutation ? 1.5 : 1),
        boxShadow: hasMutation ? [BoxShadow(color: mutColor.withOpacity(0.2), blurRadius: 10)] : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('${index + 1}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              Row(children: [
                _Badge(item.rarity.displayName, color),
                if (hasMutation) ...[const SizedBox(width: 4), _Badge('✦ ${item.mutation.displayName}', mutColor)],
              ]),
            ]),
          ),
          Text(_fmt(item.finalValue),
              style: TextStyle(color: hasMutation ? mutColor : AppColors.coins, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    ).animate(delay: Duration(milliseconds: (index * 30).clamp(0, 600))).fadeIn(duration: 250.ms).slideX(begin: 0.1, end: 0);
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B€';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
  );
}

// ─── Single Reveal ────────────────────────────────────────────────────────────

class _RevealPhase extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onKeep, onSell, onOpenAnother;
  final bool actionDone;
  final String actionMessage;
  final String username;
  const _RevealPhase({
    required this.item, required this.onKeep, required this.onSell,
    required this.onOpenAnother, required this.actionDone, required this.actionMessage,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              ItemRevealCard(item: item)
                  .animate()
                  .scale(begin: const Offset(0.4, 0.4), duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              // Viral share button for rare+ drops
              if (shouldShowShare(item.rarityKey)) ...[
                GestureDetector(
                  onTap: () => ShareDropDialog.show(
                    context,
                    item: item,
                    username: username,
                    onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.neonPink.withOpacity(0.2), AppColors.neonPurple.withOpacity(0.15)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neonPink.withOpacity(0.7), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'CONDIVIDI QUESTO DROP!',
                          style: TextStyle(
                            color: AppColors.neonPink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('🔥', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1500.ms, color: AppColors.neonPink.withOpacity(0.3)),
              ],
              if (!actionDone) ...[
                Row(children: [
                  Expanded(child: _RevBtn(label: 'TIENI', sublabel: 'In inventario', icon: '📦', color: AppColors.neonCyan, onTap: onKeep)),
                  const SizedBox(width: 12),
                  Expanded(child: _RevBtn(label: 'VENDI', sublabel: '+${_fmt(item.finalValue)}€', icon: '💰', color: AppColors.coins, onTap: onSell)),
                ]),
              ] else ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.3))),
                  child: Text(actionMessage, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.neonCyan, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenAnother,
                  icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                  label: const Text('APRI UN ALTRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan.withOpacity(0.12),
                    foregroundColor: AppColors.neonCyan,
                    side: const BorderSide(color: AppColors.neonCyan, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _RevBtn extends StatelessWidget {
  final String label, icon; final String? sublabel; final Color color; final VoidCallback onTap;
  const _RevBtn({required this.label, required this.icon, required this.color, required this.onTap, this.sublabel});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(18), border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        if (sublabel != null) Text(sublabel!, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ]),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label, icon; final Color color; final VoidCallback onTap; final String? sublabel;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap, this.sublabel});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        if (sublabel != null) Text(sublabel!, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9), textAlign: TextAlign.center),
      ]),
    ),
  );
}
