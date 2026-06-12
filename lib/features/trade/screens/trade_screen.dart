import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

// ─── Simple data classes (no Hive adapter needed) ────────────────────────────

enum TradeType { coins, gems, item }

class TradeOffer {
  final String id;
  final String sellerUsername;
  final String itemName;
  final String rarityKey;
  final String category;
  final double itemValue;
  final TradeType priceType;
  final double priceCoins;
  final int priceGems;
  final bool isMine;
  final DateTime createdAt;

  const TradeOffer({
    required this.id,
    required this.sellerUsername,
    required this.itemName,
    required this.rarityKey,
    required this.category,
    required this.itemValue,
    required this.priceType,
    required this.priceCoins,
    required this.priceGems,
    required this.isMine,
    required this.createdAt,
  });
}

// ─── Simulated marketplace data ──────────────────────────────────────────────

final _rng = Random(DateTime.now().millisecondsSinceEpoch);

final List<TradeOffer> _simulatedOffers = [
  TradeOffer(id: 'sim_1', sellerUsername: 'DragonSlayer', itemName: 'Vaso Ming',
      rarityKey: 'legendary', category: 'Arte', itemValue: 2400,
      priceType: TradeType.coins, priceCoins: 1800, priceGems: 0, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2))),
  TradeOffer(id: 'sim_2', sellerUsername: 'NightWolf99', itemName: 'Core Nucleare Piccolo',
      rarityKey: 'mythic', category: 'Energia', itemValue: 22500,
      priceType: TradeType.gems, priceCoins: 0, priceGems: 45, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5))),
  TradeOffer(id: 'sim_3', sellerUsername: 'CryptoKing', itemName: 'Stealth Tech Module',
      rarityKey: 'mythic', category: 'Tech Militare', itemValue: 87500,
      priceType: TradeType.coins, priceCoins: 65000, priceGems: 0, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
  TradeOffer(id: 'sim_4', sellerUsername: 'LuckyGamer', itemName: 'Chitarra Acustica',
      rarityKey: 'epic', category: 'Strumenti', itemValue: 660,
      priceType: TradeType.coins, priceCoins: 500, priceGems: 0, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1))),
  TradeOffer(id: 'sim_5', sellerUsername: 'StarCollector', itemName: 'Corona Reale',
      rarityKey: 'divine', category: 'Regali', itemValue: 900000,
      priceType: TradeType.gems, priceCoins: 0, priceGems: 180, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8))),
  TradeOffer(id: 'sim_6', sellerUsername: 'PixelHunter', itemName: 'Prototipo Robot',
      rarityKey: 'legendary', category: 'Robotica', itemValue: 7200,
      priceType: TradeType.coins, priceCoins: 5500, priceGems: 0, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3))),
  TradeOffer(id: 'sim_7', sellerUsername: 'QuantumX', itemName: 'Materia Oscura Campione',
      rarityKey: 'epic', category: 'Quantum', itemValue: 3300000,
      priceType: TradeType.gems, priceCoins: 0, priceGems: 220, isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15))),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TradeScreen extends ConsumerStatefulWidget {
  const TradeScreen({super.key});
  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<TradeOffer> _myOffers = [];
  String _filterRarity = 'all';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<TradeOffer> get _filteredMarket {
    if (_filterRarity == 'all') return _simulatedOffers;
    return _simulatedOffers.where((o) => o.rarityKey == _filterRarity).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1020),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔄', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    const Text('MERCATO', style: TextStyle(
                      color: AppColors.neonGold,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2,
                      shadows: [Shadow(color: Color(0xFFFFD700), blurRadius: 12)],
                    )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
                      ),
                      child: const Text('P2P', style: TextStyle(
                        color: AppColors.neonPurple, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                      ),
                      child: Row(children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGreen)),
                        const SizedBox(width: 5),
                        const Text('LIVE', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tab,
                  labelColor: AppColors.neonGold,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  indicatorColor: AppColors.neonGold,
                  indicatorWeight: 2.5,
                  tabs: [
                    const Tab(text: '🌐  MARKETPLACE'),
                    Tab(text: '📋  MIEI (${_myOffers.length})'),
                    const Tab(text: '➕  CREA'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MarketplaceTab(
                  offers: _filteredMarket,
                  filterRarity: _filterRarity,
                  onFilterChange: (r) => setState(() => _filterRarity = r),
                  onBuy: _handleBuy,
                ),
                _MyOffersTab(
                  offers: _myOffers,
                  onCancel: (id) => setState(() => _myOffers.removeWhere((o) => o.id == id)),
                ),
                _CreateTradeTab(
                  onPost: (offer) {
                    setState(() => _myOffers.insert(0, offer));
                    _tab.animateTo(1);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Offerta pubblicata nel marketplace!'),
                      backgroundColor: AppColors.neonGreen,
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBuy(TradeOffer offer) async {
    final ps = sl<PlayerService>();
    final player = ps.localPlayer;
    if (player == null) return;

    bool canAfford = false;
    if (offer.priceType == TradeType.coins) {
      canAfford = player.coins >= offer.priceCoins;
    } else if (offer.priceType == TradeType.gems) {
      canAfford = player.gems >= offer.priceGems;
    }

    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(offer.priceType == TradeType.coins
            ? '❌ Monete insufficienti!'
            : '❌ Gemme insufficienti!'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _BuyConfirmDialog(offer: offer),
    );
    if (confirmed != true) return;

    if (offer.priceType == TradeType.coins) {
      await ps.spendCoins(offer.priceCoins);
    } else {
      await ps.spendGems(offer.priceGems);
    }

    // Add item to inventory
    final inv = sl<InventoryService>();
    await inv.addItem(ItemModel(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      name: offer.itemName,
      category: offer.category,
      rarityKey: offer.rarityKey,
      mutationKey: 'none',
      baseValue: offer.itemValue / _rarityMult(offer.rarityKey),
      iconAsset: '',
      obtainedAt: DateTime.now(),
      containerId: 'trade',
    ));
    ref.read(playerNotifierProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 Hai acquistato ${offer.itemName}!'),
        backgroundColor: AppColors.neonGreen,
      ));
    }
  }

  double _rarityMult(String key) {
    switch (key) {
      case 'legendary': return 80;
      case 'mythic': return 250;
      case 'divine': return 600;
      case 'secret': return 2000;
      case 'epic': return 22;
      case 'rare': return 8;
      case 'uncommon': return 3;
      default: return 1;
    }
  }
}

// ─── Marketplace tab ──────────────────────────────────────────────────────────

class _MarketplaceTab extends StatelessWidget {
  final List<TradeOffer> offers;
  final String filterRarity;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<TradeOffer> onBuy;

  const _MarketplaceTab({
    required this.offers, required this.filterRarity,
    required this.onFilterChange, required this.onBuy,
  });

  static const _filters = [
    ('all', 'Tutti'), ('epic', 'Epico'), ('legendary', 'Legg.'),
    ('mythic', 'Mitico'), ('divine', 'Divino'), ('secret', 'Segreto'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final (key, label) = _filters[i];
              final isActive = filterRarity == key;
              final color = key == 'all' ? AppColors.neonGold : AppColors.rarityColor(key);
              return GestureDetector(
                onTap: () => onFilterChange(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? color : AppColors.border, width: isActive ? 1.5 : 1),
                  ),
                  child: Center(
                    child: Text(label, style: TextStyle(
                      color: isActive ? color : AppColors.textMuted,
                      fontSize: 11, fontWeight: FontWeight.w700,
                    )),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: offers.isEmpty
              ? const Center(child: Text('Nessuna offerta per questa rarità',
                  style: TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OfferCard(
                    offer: offers[i],
                    onBuy: () => onBuy(offers[i]),
                  ).animate(delay: Duration(milliseconds: i * 40))
                    .fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),
                ),
        ),
      ],
    );
  }
}

// ─── Offer card ───────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final TradeOffer offer;
  final VoidCallback onBuy;
  const _OfferCard({required this.offer, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(offer.rarityKey);
    final timeAgo = _timeAgo(offer.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: rarityColor.withOpacity(0.07), blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Item display
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rarityColor.withOpacity(0.5), width: 1.5),
              ),
              child: Center(child: Text(_itemEmoji(offer.category), style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(offer.itemName, style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13,
                    ), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    _RarityChip(offer.rarityKey),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(offer.sellerUsername, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                  const SizedBox(height: 5),
                  Text('Valore: 🪙 ${_fmt(offer.itemValue)}', style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Price + button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: offer.priceType == TradeType.gems
                        ? AppColors.gems.withOpacity(0.15)
                        : AppColors.coins.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: offer.priceType == TradeType.gems
                          ? AppColors.gems.withOpacity(0.5)
                          : AppColors.coins.withOpacity(0.5),
                    ),
                  ),
                  child: Row(children: [
                    Text(offer.priceType == TradeType.gems ? '💎' : '🪙',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      offer.priceType == TradeType.gems
                          ? '${offer.priceGems}'
                          : _fmt(offer.priceCoins),
                      style: TextStyle(
                        color: offer.priceType == TradeType.gems ? AppColors.gems : AppColors.coins,
                        fontWeight: FontWeight.w900, fontSize: 13,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.neonGold, const Color(0xFFFF9F00)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppColors.neonGold.withOpacity(0.35), blurRadius: 10)],
                    ),
                    child: const Text('COMPRA', style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _itemEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'gioielleria': return '💍';
      case 'arte': return '🖼️';
      case 'tech militare': return '🛡️';
      case 'elettronica': return '📱';
      case 'energia': return '⚡';
      case 'robotica': return '🤖';
      case 'quantum': return '⚛️';
      case 'spaziale': return '🌌';
      case 'alieno': return '👽';
      case 'macchinari': return '⚙️';
      case 'strumenti': return '🎸';
      case 'collezionabili': return '🏆';
      case 'regali': return '👑';
      default: return '📦';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    return '${diff.inDays}g fa';
  }

  static String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _RarityChip extends StatelessWidget {
  final String rarityKey;
  const _RarityChip(this.rarityKey);

  static const _labels = {
    'common': 'COM', 'uncommon': 'NON COM', 'rare': 'RARO',
    'epic': 'EPICO', 'legendary': 'LEGG', 'mythic': 'MITICO',
    'divine': 'DIVINO', 'secret': 'SEGRETO', 'cosmic': 'COSMICO',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarityKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(_labels[rarityKey] ?? rarityKey.toUpperCase(),
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}

// ─── My offers tab ────────────────────────────────────────────────────────────

class _MyOffersTab extends StatelessWidget {
  final List<TradeOffer> offers;
  final ValueChanged<String> onCancel;
  const _MyOffersTab({required this.offers, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Nessuna offerta attiva', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Vai su "CREA" per mettere in vendita un item', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = offers[i];
        final rarityColor = AppColors.rarityColor(o.rarityKey);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rarityColor.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rarityColor.withOpacity(0.5)),
              ),
              child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.itemName, style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 3),
              Text(
                o.priceType == TradeType.gems ? '💎 ${o.priceGems} gemme' : '🪙 ${_fmt(o.priceCoins)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ])),
            TextButton(
              onPressed: () => onCancel(o.id),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('ANNULLA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      },
    );
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Create trade tab ─────────────────────────────────────────────────────────

class _CreateTradeTab extends ConsumerStatefulWidget {
  final ValueChanged<TradeOffer> onPost;
  const _CreateTradeTab({required this.onPost});

  @override
  ConsumerState<_CreateTradeTab> createState() => _CreateTradeTabState();
}

class _CreateTradeTabState extends ConsumerState<_CreateTradeTab> {
  ItemModel? _selectedItem;
  TradeType _priceType = TradeType.coins;
  final _priceCtrl = TextEditingController();
  int _step = 0; // 0=pick item, 1=set price

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  List<ItemModel> get _inventory => sl<InventoryService>().filter(
    sort: SortMode.rarityDesc,
  ).where((i) => !i.isLocked).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _step == 0 ? _buildStep0() : _buildStep1(),
    );
  }

  Widget _buildStep0() {
    final items = _inventory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(step: 1, total: 2, title: 'Scegli un item da vendere'),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text(
              'Il tuo inventario è vuoto.\nApri dei container per ottenere items!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 0.8,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isSelected = _selectedItem?.id == item.id;
              final color = AppColors.rarityColor(item.rarityKey);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedItem = item;
                  _step = 1;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_emoji(item.category), style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(item.name, textAlign: TextAlign.center,
                        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis, maxLines: 2),
                    ),
                    Text('🪙 ${_fmt(item.finalValue)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 8)),
                  ]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep1() {
    final item = _selectedItem!;
    final color = AppColors.rarityColor(item.rarityKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 8),
          _StepHeader(step: 2, total: 2, title: 'Imposta il prezzo'),
        ]),
        const SizedBox(height: 16),

        // Selected item preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Center(child: Text(_emoji(item.category), style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              _RarityChip(item.rarityKey),
              const SizedBox(height: 3),
              Text('Valore: 🪙 ${_fmt(item.finalValue)}', style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Price type selector
        const Text('Tipo di prezzo', style: TextStyle(
          color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(children: [
          _PriceTypeBtn(label: '🪙 Monete', type: TradeType.coins,
              selected: _priceType == TradeType.coins, color: AppColors.coins,
              onTap: () => setState(() => _priceType = TradeType.coins)),
          const SizedBox(width: 8),
          _PriceTypeBtn(label: '💎 Gemme', type: TradeType.gems,
              selected: _priceType == TradeType.gems, color: AppColors.gems,
              onTap: () => setState(() => _priceType = TradeType.gems)),
        ]),
        const SizedBox(height: 16),

        // Price input
        Text(_priceType == TradeType.coins ? 'Prezzo in monete' : 'Prezzo in gemme',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixIcon: Text(
              _priceType == TradeType.coins ? '🪙' : '💎',
              style: const TextStyle(fontSize: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            hintText: _priceType == TradeType.coins ? 'es. 5000' : 'es. 10',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _priceType == TradeType.coins ? AppColors.coins : AppColors.gems,
                width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Valore stimato: 🪙 ${_fmt(item.finalValue)}  ·  Suggerito: 🪙 ${_fmt(item.finalValue * 0.75)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.info_outline, size: 12, color: AppColors.neonOrange),
          const SizedBox(width: 4),
          Text(
            _priceType == TradeType.coins
                ? 'Minimo: 🪙 ${_fmt(item.finalValue * 0.50)} (50% del valore)'
                : 'Minimo: ${(item.finalValue / 10000).ceil().clamp(1, 999999)} 💎',
            style: const TextStyle(color: AppColors.neonOrange, fontSize: 10),
          ),
        ]),
        const SizedBox(height: 24),

        // Post button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_priceCtrl.text.trim());
              if (val == null || val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Inserisci un prezzo valido'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              final item = _selectedItem!;
              if (_priceType == TradeType.coins) {
                final minCoins = item.finalValue * 0.50;
                if (val < minCoins) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      '❌ Prezzo troppo basso! Minimo 🪙 ${_fmt(minCoins)} (50% del valore)'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
              } else if (_priceType == TradeType.gems) {
                final minGems = (item.finalValue / 10000).ceil().clamp(1, 999999);
                if (val.toInt() < minGems) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('❌ Minimo $minGems 💎 per questo item'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
              }
              final player = sl<PlayerService>().localPlayer;
              widget.onPost(TradeOffer(
                id: 'my_${DateTime.now().millisecondsSinceEpoch}',
                sellerUsername: player?.username ?? 'Tu',
                itemName: item.name,
                rarityKey: item.rarityKey,
                category: item.category,
                itemValue: item.finalValue,
                priceType: _priceType,
                priceCoins: _priceType == TradeType.coins ? val : 0,
                priceGems: _priceType == TradeType.gems ? val.toInt() : 0,
                isMine: true,
                createdAt: DateTime.now(),
              ));
              _priceCtrl.clear();
              setState(() { _selectedItem = null; _step = 0; });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('📢  PUBBLICA OFFERTA', style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }

  String _emoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'gioielleria': return '💍';
      case 'arte': return '🖼️';
      case 'elettronica': return '📱';
      case 'energia': return '⚡';
      case 'robotica': return '🤖';
      case 'quantum': return '⚛️';
      case 'spaziale': return '🌌';
      case 'alieno': return '👽';
      case 'macchinari': return '⚙️';
      case 'strumenti': return '🎸';
      case 'collezionabili': return '🏆';
      default: return '📦';
    }
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _PriceTypeBtn extends StatelessWidget {
  final String label;
  final TradeType type;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PriceTypeBtn({required this.label, required this.type, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: selected ? color : AppColors.textMuted,
          fontWeight: FontWeight.w800, fontSize: 13,
        ))),
      ),
    ),
  );
}

class _StepHeader extends StatelessWidget {
  final int step, total;
  final String title;
  const _StepHeader({required this.step, required this.total, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 26, height: 26,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neonGold),
      child: Center(child: Text('$step', style: const TextStyle(
        color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12))),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(
      color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
    const Spacer(),
    Text('$step/$total', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
  ]);
}

// ─── Buy confirm dialog ───────────────────────────────────────────────────────

class _BuyConfirmDialog extends StatelessWidget {
  final TradeOffer offer;
  const _BuyConfirmDialog({required this.offer});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(offer.rarityKey);
    return Dialog(
      backgroundColor: const Color(0xFF0D1526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Conferma acquisto', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: rarityColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('📦', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(offer.itemName, style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                _RarityChip(offer.rarityKey),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  offer.priceType == TradeType.gems
                      ? '💎 ${offer.priceGems}'
                      : '🪙 ${_fmt(offer.priceCoins)}',
                  style: const TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('COMPRA', style: TextStyle(fontWeight: FontWeight.w900)),
            )),
          ]),
        ]),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
