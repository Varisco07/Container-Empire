import 'package:flutter/material.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/rarity.dart';
import '../../../core/theme/app_colors.dart';

const _itemEmojis = {
  'Bullone Arrugginito': '🔩', 'Bottiglia Vuota': '🍶', 'Chiave Inglese': '🔧',
  'Orologio Rotto': '⌚', 'Moneta Antica': '🪙', 'Cacciavite': '🪛',
  'Martello': '🔨', 'Smartphone Vecchio': '📱', 'Orologio Vintage': '⌚',
  'Chitarra Acustica': '🎸', 'Vaso Ming': '🏺', 'Trapano Industriale': '🔧',
  'Saldatrice': '⚡', 'Generatore': '🔋', 'CNC Machine Part': '⚙️',
  'Prototipo Robot': '🤖', 'Core Nucleare Piccolo': '☢️', 'Elmetto Tattico': '🪖',
  'Giubbotto Antiproiettile': '🦺', 'Drone Militare': '🚁', 'Visore Notturno': '🔭',
  'Esoscheletro Prototipo': '🦾', 'Stealth Tech Module': '🛡️',
  'Orologio Rolex': '⌚', 'Borsa Hermès': '👜', 'Anello con Diamante': '💍',
  'Ferrari Miniatura d\'Oro': '🏎️', 'Quadro Picasso': '🖼️', 'Corona Reale': '👑',
  'Meteorite Frammento': '☄️', 'Luna Rock Certificato': '🌙',
  'Satellite Disattivato': '🛰️', 'Cristallo Alieno': '💎',
  'Stardust Vial': '✨', 'Nucleo di Stella di Neutroni': '⭐',
  'Bit Quantistico': '🔮', 'Entangled Particle Pair': '🌀',
  'Quantum Processor': '💻', 'Materia Oscura Campione': '🕳️',
  'Singolarità Compressa': '🌌', 'Frammento Big Bang': '💥',
  'Ω Omega Particle': '⚛️',
};

class InventoryItemTile extends StatefulWidget {
  final ItemModel item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback onLock;
  final VoidCallback onSell;
  final VoidCallback? onDismantle;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onLock,
    required this.onSell,
    this.onTap,
    this.onDismantle,
  });

  @override
  State<InventoryItemTile> createState() => _InventoryItemTileState();
}

class _InventoryItemTileState extends State<InventoryItemTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color      = AppColors.rarityColor(widget.item.rarityKey);
    final hasMut     = widget.item.mutation != Mutation.none;
    final mutColor   = hasMut ? AppColors.mutationColor(widget.item.mutationKey) : Colors.transparent;
    final emoji      = _itemEmojis[widget.item.name] ?? '📦';
    final isRarePlus = widget.item.rarity.index >= 3; // epic+
    final borderC    = widget.isSelected ? color : (hasMut ? mutColor : color.withOpacity(0.45));
    final borderW    = widget.isSelected || hasMut ? 2.0 : 1.0;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); (widget.onTap ?? () => _showDetail(context))(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isSelected
                  ? [color.withOpacity(0.32), color.withOpacity(0.12)]
                  : [color.withOpacity(isRarePlus ? 0.14 : 0.07), AppColors.surface],
            ),
            border: Border.all(color: borderC, width: borderW),
            boxShadow: [
              if (hasMut)
                BoxShadow(color: mutColor.withOpacity(0.4), blurRadius: 16, spreadRadius: 1),
              if (isRarePlus && !hasMut)
                BoxShadow(color: color.withOpacity(0.25), blurRadius: 12),
            ],
          ),
          child: Stack(
            children: [
              // Top gradient shine for rare+
              if (isRarePlus)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withOpacity(0.18), Colors.transparent],
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rarity name badge at top
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.item.rarity.displayName.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Emoji icon
                    Expanded(
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: 36,
                            shadows: isRarePlus
                                ? [Shadow(color: color.withOpacity(0.7), blurRadius: 12)]
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Mutation tag
                    if (hasMut)
                      Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: mutColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: mutColor.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          '✦ ${widget.item.mutation.displayName}',
                          style: TextStyle(color: mutColor, fontSize: 6.5, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Name
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Value
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.coins.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _fmt(widget.item.finalValue),
                        style: const TextStyle(
                          color: AppColors.coins,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lock badge
              if (widget.item.isLocked)
                Positioned(
                  top: 5, right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('🔒', style: TextStyle(fontSize: 9)),
                  ),
                ),

              // Selection checkmark
              if (widget.isSelected)
                Positioned(
                  top: 5, right: 5,
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]),
                    child: const Icon(Icons.check, size: 13, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = AppColors.rarityColor(widget.item.rarityKey);
    final hasMut = widget.item.mutation != Mutation.none;
    final mutColor = hasMut ? AppColors.mutationColor(widget.item.mutationKey) : Colors.transparent;
    final emoji = _itemEmojis[widget.item.name] ?? '📦';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: color.withOpacity(0.5), width: 1.5)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, spreadRadius: 2)],
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(width: 44, height: 4,
              decoration: BoxDecoration(color: color.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Emoji with glow
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withOpacity(0.2), Colors.transparent]),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 30)],
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 70))),
            ),
            const SizedBox(height: 14),

            // Rarity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
              ),
              child: Text(
                widget.item.rarity.displayName.toUpperCase(),
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2,
                    shadows: [Shadow(color: color, blurRadius: 6)]),
              ),
            ),
            const SizedBox(height: 10),

            // Mutation
            if (hasMut) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: mutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mutColor.withOpacity(0.5)),
                ),
                child: Text('✦ ${widget.item.mutation.displayName}',
                  style: TextStyle(color: mutColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
            ],

            // Name
            Text(
              widget.item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Divider
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            // Value
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  _fmt(widget.item.finalValue),
                  style: TextStyle(
                    color: AppColors.coins,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: AppColors.coins.withOpacity(0.5), blurRadius: 10)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons row 1
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: widget.item.isLocked ? '🔓 Sblocca' : '🔒 Blocca',
                    color: AppColors.neonCyan,
                    outlined: true,
                    onTap: () { widget.onLock(); Navigator.pop(context); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    label: '💰 Vendi',
                    color: AppColors.coins,
                    outlined: false,
                    enabled: !widget.item.isLocked,
                    onTap: () { widget.onSell(); Navigator.pop(context); },
                  ),
                ),
              ],
            ),
            if (widget.onDismantle != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _ActionBtn(
                  label: '🌫️ Smantella → ${_dustAmountLabel(widget.item.rarityKey)} Dust',
                  color: const Color(0xFF8B7FF0),
                  outlined: true,
                  enabled: !widget.item.isLocked,
                  onTap: () { widget.onDismantle!(); Navigator.pop(context); },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dustAmountLabel(String rarityKey) {
    switch (rarityKey) {
      case 'common':    return '5';
      case 'uncommon':  return '15';
      case 'rare':      return '50';
      case 'epic':      return '200';
      case 'legendary': return '700';
      case 'mythic':    return '2.000';
      case 'divine':    return '8.000';
      case 'secret':    return '30.000';
      case 'cosmic':    return '200.000';
      default:          return '5';
    }
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9)  return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6)  return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3)  return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool outlined;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.outlined,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled ? widget.color : AppColors.textMuted;
    return GestureDetector(
      onTapDown:   widget.enabled ? (_) => setState(() => _pressed = true)  : null,
      onTapUp:     widget.enabled ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
      onTapCancel: widget.enabled ? ()  => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : effectiveColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: effectiveColor, width: 1.5),
            boxShadow: !widget.outlined && widget.enabled
                ? [BoxShadow(color: effectiveColor.withOpacity(0.35), blurRadius: 10)]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.outlined ? effectiveColor : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
