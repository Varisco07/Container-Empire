import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/item_model.dart';
import '../../core/models/rarity.dart';
import '../../core/theme/app_colors.dart';

const _shareEmojis = {
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
  'Fenice Cosmica': '🦅', 'Cristallo dell\'Universo': '🔮', 'Singolarità Primordiale': '🌌',
};

String _rarityDropRate(String rarityKey) {
  switch (rarityKey) {
    case 'common': return '70.00%';
    case 'uncommon': return '20.00%';
    case 'rare': return '7.00%';
    case 'epic': return '2.00%';
    case 'legendary': return '0.80%';
    case 'mythic': return '0.15%';
    case 'divine': return '0.04%';
    case 'secret': return '0.01%';
    case 'cosmic': return '0.000001%';
    default: return '?%';
  }
}

String _rarityEmoji(String rarityKey) {
  switch (rarityKey) {
    case 'mythic': return '🔥';
    case 'divine': return '✨';
    case 'secret': return '🌌';
    case 'cosmic': return '🌠';
    default: return '⭐';
  }
}

/// Shows a viral share bottom sheet when a rare drop is found.
/// [shouldShowShare] returns true for mythic, divine, secret, cosmic.
bool shouldShowShare(String rarityKey) {
  const shareRarities = {'mythic', 'divine', 'secret', 'cosmic'};
  return shareRarities.contains(rarityKey);
}

class ShareDropDialog extends StatefulWidget {
  final ItemModel item;
  final String username;
  final VoidCallback? onDismiss;

  const ShareDropDialog({
    super.key,
    required this.item,
    required this.username,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required ItemModel item,
    required String username,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareDropDialog(item: item, username: username, onDismiss: onDismiss),
    );
  }

  @override
  State<ShareDropDialog> createState() => _ShareDropDialogState();
}

class _ShareDropDialogState extends State<ShareDropDialog> {
  bool _copied = false;

  String _buildShareText() {
    final emoji = _shareEmojis[widget.item.name] ?? '📦';
    final rarityEmoji = _rarityEmoji(widget.item.rarityKey);
    final dropRate = _rarityDropRate(widget.item.rarityKey);
    final hasMutation = widget.item.mutation != Mutation.none;
    final mutationLine = hasMutation
        ? '\n✦ ${widget.item.mutation.displayName} MUTATION'
        : '';
    final value = _fmt(widget.item.finalValue);

    return '''$rarityEmoji ${widget.username.toUpperCase()} HA TROVATO

$emoji ${widget.item.name.toUpperCase()} $emoji
${widget.item.rarity.displayName}$mutationLine

📊 Probabilità: $dropRate
💰 Valore: $value€

📦 Container Empire
Apri i tuoi container adesso!''';
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(widget.item.rarityKey);
    final hasMutation = widget.item.mutation != Mutation.none;
    final mutColor = hasMutation ? AppColors.mutationColor(widget.item.mutationKey) : color;
    final emoji = _shareEmojis[widget.item.name] ?? '📦';
    final isCosmicOrSecret = widget.item.rarityKey == 'cosmic' || widget.item.rarityKey == 'secret';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            '🔥 DROP INCREDIBILE! 🔥',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          const SizedBox(height: 4),
          Text(
            'Condividi con i tuoi amici!',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Share card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  color.withOpacity(0.15),
                  if (hasMutation) mutColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                if (isCosmicOrSecret)
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 60, spreadRadius: 8),
              ],
            ),
            child: Column(
              children: [
                // App name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📦 CONTAINER EMPIRE',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text(
                        _rarityDropRate(widget.item.rarityKey),
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Username
                Text(
                  widget.username.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'HA TROVATO',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // Big emoji
                Text(emoji, style: const TextStyle(fontSize: 60))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1000.ms),
                const SizedBox(height: 10),

                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withOpacity(0.35), color.withOpacity(0.15)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12)],
                  ),
                  child: Text(
                    widget.item.rarity.displayName,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [Shadow(color: color, blurRadius: 8)],
                    ),
                  ),
                ),
                if (hasMutation) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: mutColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mutColor.withOpacity(0.7)),
                    ),
                    child: Text(
                      '✦ ${widget.item.mutation.displayName} MUTATION',
                      style: TextStyle(color: mutColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Item name
                Text(
                  widget.item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),

                // Value
                Text(
                  '💰 ${_fmt(widget.item.finalValue)}€',
                  style: TextStyle(
                    color: AppColors.coins,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: AppColors.coins.withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut, duration: 500.ms),

          const SizedBox(height: 20),

          // Share buttons
          Row(
            children: [
              Expanded(
                child: _ShareBtn(
                  icon: '📋',
                  label: _copied ? 'COPIATO!' : 'COPIA TESTO',
                  color: _copied ? AppColors.success : AppColors.neonCyan,
                  onTap: _copyToClipboard,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareBtn(
                  icon: '📤',
                  label: 'CONDIVIDI',
                  color: color,
                  onTap: () => _shareNative(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onDismiss ?? () => Navigator.pop(context),
            child: const Text(
              'Non ora',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _shareNative(BuildContext context) {
    // Uses the platform share sheet via text sharing.
    // To use native share_plus, add it to pubspec.yaml and call:
    //   Share.share(_buildShareText());
    // For now, copy to clipboard and show a snackbar.
    _copyToClipboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Testo copiato! Incollalo su Instagram, TikTok o WhatsApp!'),
        backgroundColor: AppColors.neonCyan,
        duration: Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) (widget.onDismiss ?? () => Navigator.pop(context))();
    });
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _ShareBtn extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    ),
  );
}
