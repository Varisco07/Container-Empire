import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';

// ─── Simple data models (stored as Map in Hive box<dynamic>) ─────────────────

class ClanMember {
  final String username;
  final String role; // leader, officer, member
  final int level;
  final int contribution;
  const ClanMember({required this.username, required this.role, required this.level, required this.contribution});
}

class ClanData {
  final String id;
  final String name;
  final String emblem;
  final String description;
  final int level;
  final int points;
  final List<ClanMember> members;
  const ClanData({required this.id, required this.name, required this.emblem,
      required this.description, required this.level, required this.points, required this.members});
}

// ─── Simulated clans for browsing ────────────────────────────────────────────

final _browseClanList = [
  ClanData(id: 'phoenix', name: 'Phoenix Rising', emblem: '🔥', description: 'Clan d\'élite per i migliori giocatori',
      level: 12, points: 48200, members: [
        const ClanMember(username: 'DragonSlayer', role: 'leader', level: 34, contribution: 1200),
        const ClanMember(username: 'NightWolf99', role: 'officer', level: 28, contribution: 850),
        const ClanMember(username: 'QuantumX', role: 'member', level: 22, contribution: 620),
      ]),
  ClanData(id: 'dragons', name: 'Golden Dragons', emblem: '🐉', description: 'Amichevole, tutti benvenuti!',
      level: 7, points: 21500, members: [
        const ClanMember(username: 'StarCollector', role: 'leader', level: 18, contribution: 750),
        const ClanMember(username: 'LuckyGamer', role: 'member', level: 12, contribution: 340),
      ]),
  ClanData(id: 'cosmos', name: 'Cosmos Empire', emblem: '⭐', description: 'Cacciatori di item cosmici',
      level: 15, points: 87000, members: [
        const ClanMember(username: 'CryptoKing', role: 'leader', level: 45, contribution: 3400),
        const ClanMember(username: 'PixelHunter', role: 'officer', level: 38, contribution: 2100),
      ]),
];

// ─── Simulated chat ──────────────────────────────────────────────────────────

class _ChatMsg {
  final String username;
  final String text;
  final DateTime time;
  _ChatMsg(this.username, this.text, this.time);
}

final List<_ChatMsg> _chatLog = [
  _ChatMsg('DragonSlayer', '🔥 Abbiamo completato la missione settimanale!', DateTime.now().subtract(const Duration(hours: 2))),
  _ChatMsg('NightWolf99', 'GG! Ho trovato un item Mitico nel quantum', DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
  _ChatMsg('QuantumX', 'Chi vuole fare trade? ho roba buona', DateTime.now().subtract(const Duration(minutes: 45))),
  _ChatMsg('DragonSlayer', 'Forza domani abbiamo clan war 💪', DateTime.now().subtract(const Duration(minutes: 20))),
];

// ─── Hive box key ─────────────────────────────────────────────────────────────

const _clanBoxName = 'clan_state';
const _clanKey = 'current_clan';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ClanScreen extends ConsumerStatefulWidget {
  const ClanScreen({super.key});
  @override
  ConsumerState<ClanScreen> createState() => _ClanScreenState();
}

class _ClanScreenState extends ConsumerState<ClanScreen> with TickerProviderStateMixin {
  Box<dynamic>? _box;
  ClanData? _myClan;
  late TabController _tab;      // clan home (4 tab)
  late TabController _noClanTab; // no-clan (2 tab)
  final _chatCtrl = TextEditingController();
  final List<_ChatMsg> _chat = List.from(_chatLog);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _noClanTab = TabController(length: 2, vsync: this);
    _loadClan();
  }

  Future<void> _loadClan() async {
    final box = await Hive.openBox<dynamic>(_clanBoxName);
    _box = box;
    final saved = box.get(_clanKey) as Map?;
    if (saved != null) {
      final clan = _browseClanList.firstWhere(
        (c) => c.id == saved['id'],
        orElse: () => _browseClanList.first,
      );
      if (mounted) setState(() => _myClan = clan);
    }
  }

  Future<void> _joinClan(ClanData clan) async {
    await _box?.put(_clanKey, {'id': clan.id});
    setState(() => _myClan = clan);
  }

  Future<void> _leaveClan() async {
    await _box?.delete(_clanKey);
    setState(() { _myClan = null; _tab.animateTo(0); });
  }

  Future<void> _createClan(String name, String emblem, String desc) async {
    final player = sl<PlayerService>().localPlayer;
    final newClan = ClanData(
      id: 'my_${DateTime.now().millisecondsSinceEpoch}',
      name: name, emblem: emblem, description: desc,
      level: 1, points: 0,
      members: [ClanMember(username: player?.username ?? 'Tu', role: 'leader',
          level: player?.level ?? 1, contribution: 0)],
    );
    await _box?.put(_clanKey, {'id': newClan.id, 'name': name, 'emblem': emblem});
    setState(() => _myClan = newClan);
  }

  @override
  void dispose() {
    _tab.dispose();
    _noClanTab.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_myClan == null) return _buildNoClan();
    return _buildClanHome();
  }

  // ── No clan ─────────────────────────────────────────────────────────────────

  Widget _buildNoClan() {
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
                const Row(children: [
                  Text('⚔️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text('CLAN', style: TextStyle(
                    color: AppColors.neonPurple,
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2,
                    shadows: [Shadow(color: AppColors.neonPurple, blurRadius: 12)],
                  )),
                ]),
                const SizedBox(height: 12),
                TabBar(
                  controller: _noClanTab,
                  labelColor: AppColors.neonPurple,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.neonPurple,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  tabs: const [Tab(text: '🌍  CERCA CLAN'), Tab(text: '➕  CREA CLAN')],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _noClanTab,
              children: [
                _BrowseClansTab(clans: _browseClanList, onJoin: _joinClan),
                _CreateClanTab(onCreate: _createClan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Clan home ────────────────────────────────────────────────────────────────

  Widget _buildClanHome() {
    final clan = _myClan!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Clan header banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF120820), Color(0xFF0A1020)],
              ),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neonPurple.withOpacity(0.6), width: 2),
                      ),
                      child: Center(child: Text(clan.emblem, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(clan.name, style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                      Row(children: [
                        _ClanBadge('Lv.${clan.level}', AppColors.neonGold),
                        const SizedBox(width: 6),
                        _ClanBadge('${clan.members.length}/30 membri', AppColors.neonCyan),
                      ]),
                    ])),
                    // Points
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_fmt(clan.points.toDouble()), style: const TextStyle(
                        color: AppColors.neonGold, fontWeight: FontWeight.w900, fontSize: 18)),
                      const Text('punti', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tab,
                  labelColor: AppColors.neonPurple,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.neonPurple,
                  indicatorWeight: 2.5,
                  isScrollable: true,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  tabs: const [
                    Tab(text: '🏠  HOME'),
                    Tab(text: '👥  MEMBRI'),
                    Tab(text: '💬  CHAT'),
                    Tab(text: '🎯  MISSIONI'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ClanHomeTab(clan: clan, onLeave: _showLeaveDialog),
                _ClanMembersTab(members: clan.members),
                _ClanChatTab(chat: _chat, chatCtrl: _chatCtrl, onSend: _sendMessage),
                _ClanMissionsTab(clan: clan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final player = sl<PlayerService>().localPlayer;
    setState(() {
      _chat.add(_ChatMsg(player?.username ?? 'Tu', text, DateTime.now()));
      _chatCtrl.clear();
    });
  }

  void _showLeaveDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lascia il clan?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
        content: const Text('Perderai tutti i progressi del clan.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('LASCIA', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmed == true) await _leaveClan();
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Browse clans ─────────────────────────────────────────────────────────────

class _BrowseClansTab extends StatelessWidget {
  final List<ClanData> clans;
  final ValueChanged<ClanData> onJoin;
  const _BrowseClansTab({required this.clans, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = clans[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neonPurple.withOpacity(0.25)),
            boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.06), blurRadius: 12)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonPurple.withOpacity(0.5)),
                ),
                child: Center(child: Text(c.emblem, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 3),
                Text(c.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _ClanBadge('Lv.${c.level}', AppColors.neonGold),
                const SizedBox(height: 4),
                Text(_fmtPts(c.points), style: const TextStyle(
                  color: AppColors.neonGold, fontWeight: FontWeight.w900, fontSize: 13)),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.group_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${c.members.length}/30 membri', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              GestureDetector(
                onTap: () => onJoin(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.neonPurple,
                      AppColors.neonPurple.withOpacity(0.7),
                    ]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 10)],
                  ),
                  child: const Text('UNISCITI', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                ),
              ),
            ]),
          ]),
        ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
      },
    );
  }

  static String _fmtPts(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K pt';
    return '$v pt';
  }
}

// ─── Create clan ──────────────────────────────────────────────────────────────

class _CreateClanTab extends StatefulWidget {
  final Future<void> Function(String, String, String) onCreate;
  const _CreateClanTab({required this.onCreate});

  @override
  State<_CreateClanTab> createState() => _CreateClanTabState();
}

class _CreateClanTabState extends State<_CreateClanTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedEmblem = '🔥';
  bool _loading = false;

  static const _emblems = ['🔥', '⚡', '🐉', '⭐', '🛡️', '💎', '🌙', '🦅', '🐺', '🌊', '☄️', '🏔️'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.neonPurple.withOpacity(0.15),
                AppColors.neonCyan.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonPurple.withOpacity(0.6), width: 2),
                ),
                child: Center(child: Text(_selectedEmblem, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Nome del tuo clan...' : _nameCtrl.text,
                  style: TextStyle(
                    color: _nameCtrl.text.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                    fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                _ClanBadge('Lv.1', AppColors.neonGold),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Emblem picker
          const Text('EMBLEMA', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emblems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = _emblems[i];
                final isSelected = e == _selectedEmblem;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmblem = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.neonPurple.withOpacity(0.2) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.neonPurple : AppColors.border,
                        width: isSelected ? 2 : 1),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Name
          const Text('NOME CLAN', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          _GameTextField(controller: _nameCtrl, hint: 'es. Phoenix Rising', maxLength: 24,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),

          // Desc
          const Text('DESCRIZIONE', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          _GameTextField(controller: _descCtrl, hint: 'Descrivi il tuo clan...', maxLength: 80,
              maxLines: 2, onChanged: (_) {}),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : () async {
                if (_nameCtrl.text.trim().length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Il nome deve avere almeno 3 caratteri'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
                setState(() => _loading = true);
                await widget.onCreate(_nameCtrl.text.trim(), _selectedEmblem, _descCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('⚔️  CREA CLAN', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clan home tab ────────────────────────────────────────────────────────────

class _ClanHomeTab extends StatelessWidget {
  final ClanData clan;
  final VoidCallback onLeave;
  const _ClanHomeTab({required this.clan, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Clan war banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFFFF6B00).withOpacity(0.2),
              const Color(0xFFFF0080).withOpacity(0.1),
            ]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.5)),
          ),
          child: Column(children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('⚔️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text('CLAN WAR', style: TextStyle(
                color: Color(0xFFFF6B00), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
              SizedBox(width: 10),
              Text('⚔️', style: TextStyle(fontSize: 24)),
            ]),
            const SizedBox(height: 6),
            const Text('Prossima guerra: Domenica 22:00',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.5)),
              ),
              child: const Text('REGISTRATI', style: TextStyle(
                color: Color(0xFFFF6B00), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ),
          ]),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 12),

        // Stats row
        Row(children: [
          _StatBox('🏆', '${clan.points}', 'Punti', AppColors.neonGold),
          const SizedBox(width: 8),
          _StatBox('👥', '${clan.members.length}', 'Membri', AppColors.neonCyan),
          const SizedBox(width: 8),
          _StatBox('⭐', '${clan.level}', 'Livello', AppColors.neonPurple),
        ]).animate(delay: 100.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 12),

        // Description
        if (clan.description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(clan.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            ]),
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
        ],

        // Top contributors
        const Text('TOP CONTRIBUTORI', style: TextStyle(
          color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...clan.members.take(3).toList().asMap().entries.map((e) {
          final m = e.value;
          final medals = ['🥇', '🥈', '🥉'];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Text(medals[e.key], style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(m.username, style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13))),
              Text('${m.contribution} pt', style: const TextStyle(
                color: AppColors.neonGold, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          );
        }),
        const SizedBox(height: 20),

        // Leave button
        TextButton(
          onPressed: onLeave,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Lascia il clan', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Members tab ──────────────────────────────────────────────────────────────

class _ClanMembersTab extends StatelessWidget {
  final List<ClanMember> members;
  const _ClanMembersTab({required this.members});

  static const _roleColor = {
    'leader': AppColors.neonGold,
    'officer': AppColors.neonCyan,
    'member': AppColors.textMuted,
  };
  static const _roleLabel = {'leader': '👑 LEADER', 'officer': '⚡ OFFICER', 'member': '🔰 MEMBRO'};

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i];
        final color = _roleColor[m.role] ?? AppColors.textMuted;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(child: Text(m.username.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.username, style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(_roleLabel[m.role] ?? '', style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 6),
                Text('Lv.${m.level}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${m.contribution}', style: const TextStyle(
                color: AppColors.neonGold, fontWeight: FontWeight.w900, fontSize: 16)),
              const Text('punti', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ]),
          ]),
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(duration: 200.ms);
      },
    );
  }
}

// ─── Chat tab ─────────────────────────────────────────────────────────────────

class _ClanChatTab extends StatelessWidget {
  final List<_ChatMsg> chat;
  final TextEditingController chatCtrl;
  final VoidCallback onSend;
  const _ClanChatTab({required this.chat, required this.chatCtrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            itemCount: chat.length,
            itemBuilder: (_, i) {
              final msg = chat[i];
              final isMe = msg.username == sl<PlayerService>().localPlayer?.username;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.neonPurple.withOpacity(0.2),
                        child: Text(msg.username[0], style: const TextStyle(
                          color: AppColors.neonPurple, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe) Text(msg.username, style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.neonPurple.withOpacity(0.2) : AppColors.surface,
                            borderRadius: BorderRadius.circular(14).copyWith(
                              bottomRight: isMe ? const Radius.circular(4) : null,
                              bottomLeft: !isMe ? const Radius.circular(4) : null,
                            ),
                            border: Border.all(
                              color: isMe ? AppColors.neonPurple.withOpacity(0.4) : AppColors.border),
                          ),
                          child: Text(msg.text, style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: chatCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Messaggio al clan...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true, fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.neonPurple, width: 1.5)),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.neonPurple, AppColors.neonPurple.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 8)],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ─── Missions tab ─────────────────────────────────────────────────────────────

class _ClanMissionsTab extends StatelessWidget {
  final ClanData clan;
  const _ClanMissionsTab({required this.clan});

  @override
  Widget build(BuildContext context) {
    final missions = [
      (title: 'Apri 1.000 container', icon: '📦', current: 347, target: 1000,
          reward: '💎 ×50 + Badge', color: AppColors.neonCyan),
      (title: 'Vendi oggetti per 🪙 5M', icon: '🪙', current: 1200000, target: 5000000,
          reward: '💎 ×20 + 🪙 10K', color: AppColors.neonGold),
      (title: 'Colleziona 10 item Epici', icon: '⭐', current: 6, target: 10,
          reward: '💎 ×30', color: AppColors.epic),
      (title: 'Guadagna 100K punti collettivi', icon: '🏆', current: 48200, target: 100000,
          reward: 'Container Esclusivo', color: AppColors.neonPurple),
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.neonGold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.neonGold, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Le missioni del clan si resettano ogni settimana. Contribuisci per ottenere ricompense esclusive!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
            )),
          ]),
        ),
        ...missions.asMap().entries.map((e) {
          final m = e.value;
          final progress = m.current / m.target;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: m.color.withOpacity(0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(m.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(m.title, style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: m.color.withOpacity(0.4)),
                  ),
                  child: Text(m.reward, style: TextStyle(
                    color: m.color, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  color: m.color,
                ),
              ),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(m.current.toDouble()), style: TextStyle(
                  color: m.color, fontSize: 11, fontWeight: FontWeight.w700)),
                Text(_fmt(m.target.toDouble()), style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
              ]),
            ]),
          ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn(duration: 250.ms);
        }),
      ],
    );
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _ClanBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _ClanBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
  );
}

class _StatBox extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _StatBox(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
      ]),
    ),
  );
}

class _GameTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;
  final ValueChanged<String> onChanged;
  const _GameTextField({required this.controller, required this.hint,
      required this.maxLength, this.maxLines = 1, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLength: maxLength,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      filled: true, fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonPurple, width: 1.5)),
    ),
  );
}
