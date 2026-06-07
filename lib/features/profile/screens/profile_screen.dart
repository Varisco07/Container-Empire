import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/neon_text.dart';
import '../providers/player_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PROFILO')),
      body: player.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(child: Text('Errore: $e', style: const TextStyle(color: AppColors.error))),
        data: (p) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar & name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan.withOpacity(0.1),
                      border: Border.all(color: AppColors.neonCyan, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.neonCyan, size: 56),
                  ),
                  const SizedBox(height: 12),
                  NeonText(p.username, color: AppColors.textPrimary, fontSize: 22, blurRadius: 4),
                  if (p.isVip)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.neonPurple, AppColors.neonCyan]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('⭐ VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(label: 'Livello', value: '${p.level}', icon: Icons.star_rounded, color: AppColors.neonGold),
                _StatCard(label: 'Container Aperti', value: '${p.totalContainersOpened}', icon: Icons.inventory_2_rounded, color: AppColors.neonCyan),
                _StatCard(label: 'Guadagni Totali', value: _fmt(p.totalEarned), icon: Icons.monetization_on_rounded, color: AppColors.coins),
                _StatCard(label: 'Gemme', value: '${p.gems}', icon: Icons.diamond_rounded, color: AppColors.gems),
                _StatCard(label: 'Fortuna', value: '×${p.luckBoost.toStringAsFixed(1)}', icon: Icons.auto_awesome_rounded, color: AppColors.neonPurple),
                _StatCard(label: 'Boost Valore', value: '×${p.valueBoost.toStringAsFixed(1)}', icon: Icons.trending_up_rounded, color: AppColors.neonOrange),
              ],
            ),

            const SizedBox(height: 24),

            // Prestige section
            _PrestigeSection(player: p),

            const SizedBox(height: 24),

            // Settings section
            _SettingsSection(),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B€';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}

// ─── Prestige Section ─────────────────────────────────────────────────────────

class _PrestigeSection extends ConsumerWidget {
  final dynamic player;
  const _PrestigeSection({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = sl<PlayerService>();
    final canPrestige = player.level >= PlayerService.prestigeMinLevel;
    final prestigeLevel = player.prestigeLevel as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canPrestige
              ? [AppColors.neonPurple.withOpacity(0.2), AppColors.neonPink.withOpacity(0.1)]
              : [AppColors.surface, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canPrestige ? AppColors.neonPurple.withOpacity(0.8) : AppColors.border,
          width: canPrestige ? 1.5 : 1,
        ),
        boxShadow: canPrestige
            ? [BoxShadow(color: AppColors.neonPurple.withOpacity(0.25), blurRadius: 20)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚜️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SISTEMA PRESTIGE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    prestigeLevel > 0
                        ? 'Prestige $prestigeLevel  ·  +${((player.prestigeLuckBonus as double) * 100).toStringAsFixed(0)}% Fortuna permanente'
                        : 'Reset e ricomincia più forte',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              if (prestigeLevel > 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.neonPurple, AppColors.neonPink]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'P${prestigeLevel}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (!canPrestige) ...[
            // Progress to prestige
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Livello ${player.level} / ${PlayerService.prestigeMinLevel}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    Text(
                      'Mancano ${PlayerService.prestigeMinLevel - (player.level as int)} livelli',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (player.level as int) / PlayerService.prestigeMinLevel,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.neonPurple),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Al Prestige riceverai: +${(PlayerService.prestigeLuckPerLevel * 100).toStringAsFixed(0)}% Fortuna permanente',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ] else ...[
            // Prestige available!
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⚠️ Reset: livello, XP, upgrade, monete\n✅ Mantieni: gemme, inventario, prestige bonus',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPrestigeConfirm(context, ref, ps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  '⚜️  ESEGUI PRESTIGE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1800.ms, color: Colors.white24),
          ],
        ],
      ),
    );
  }

  void _showPrestigeConfirm(BuildContext context, WidgetRef ref, PlayerService ps) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('⚜️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text('PRESTIGE', style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
          ],
        ),
        content: const Text(
          'Sei sicuro?\n\nVerranno azzerati:\n• Livello → 1\n• XP e upgrade\n• Monete → 500€\n\nIn cambio ottieni:\n• +15% Fortuna PERMANENTE\n• Badge Prestige esclusivo\n• Moltiplicatore cumulativo per ogni prestige futuro',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              final result = await ps.prestige();
              if (result.success) {
                ref.read(playerNotifierProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '⚜️ PRESTIGE ${result.prestigeLevel} ATTIVATO! +${(result.totalLuckBonus * 100).toStringAsFixed(0)}% Fortuna permanente!',
                      ),
                      backgroundColor: AppColors.neonPurple,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('PRESTIGE!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatefulWidget {
  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  bool _notifications = true;
  bool _audio = true;

  void _showInfo(String title, String body) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
        content: const Text('Sei sicuro di voler uscire?\nI tuoi progressi sono salvati localmente.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await sl<AuthService>().logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout effettuato. Riavvia l\'app per accedere.'),
                    backgroundColor: AppColors.warning,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('IMPOSTAZIONI', style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),

        // Notifiche toggle
        _ToggleTile(
          icon: Icons.notifications_rounded,
          label: 'Notifiche',
          color: AppColors.neonCyan,
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
        ),
        const SizedBox(height: 2),

        // Audio toggle
        _ToggleTile(
          icon: Icons.music_note_rounded,
          label: 'Musica & Suoni',
          color: AppColors.neonPurple,
          value: _audio,
          onChanged: (v) => setState(() => _audio = v),
        ),
        const SizedBox(height: 2),

        _SettingTile(
          icon: Icons.shield_rounded,
          label: 'Privacy & Dati',
          color: AppColors.neonGreen,
          onTap: () => _showInfo('Privacy & Dati', 'Container Empire salva i tuoi dati solo localmente sul dispositivo. Nessun dato viene inviato a server esterni senza consenso.'),
        ),
        _SettingTile(
          icon: Icons.help_rounded,
          label: 'Come si gioca',
          color: AppColors.neonOrange,
          onTap: () => _showInfo('Come si gioca', '1. Scegli un container dalla Home\n2. Pagalo con le tue monete 🪙\n3. La ruota gira e rivela il tuo oggetto\n4. Tienilo nell\'inventario o vendilo\n5. Accumula monete e apri container sempre più rari!\n\nLe rarità vanno da Comune a Segreta 🌌'),
        ),
        _SettingTile(
          icon: Icons.info_outline_rounded,
          label: 'Versione App',
          color: AppColors.textMuted,
          trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          onTap: () => _showInfo('Container Empire', 'Versione 1.0.0\n\nDeveloped with Flutter ❤️\n\nTutti i prezzi e gli oggetti sono puramente virtuali.'),
        ),
        const SizedBox(height: 8),
        _SettingTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          color: AppColors.error,
          onTap: _showLogoutConfirm,
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.label, required this.color, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        value: value,
        onChanged: onChanged,
        activeColor: color,
        trackColor: WidgetStateProperty.all(color.withOpacity(0.3)),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingTile({required this.icon, required this.label, required this.color, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        onTap: onTap,
      ),
    );
  }
}
