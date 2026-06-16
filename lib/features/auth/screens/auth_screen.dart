import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';

// ─── Animated auth background ────────────────────────────────────────────────

class _AuthBackground extends StatefulWidget {
  const _AuthBackground();
  @override
  State<_AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<_AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AuthBgPainter(_ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  final double t;
  _AuthBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1628), Color(0xFF0D1E34), Color(0xFF0A1628)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Pulsing top halo (cyan)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(
        center: const Alignment(0, -0.8),
        radius: 0.55 + t * 0.1,
        colors: [
          const Color(0xFF4B7BEC).withOpacity(0.08 + t * 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Bottom purple halo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(
        center: const Alignment(0.5, 1.0),
        radius: 0.5,
        colors: [
          const Color(0xFF7C5CBF).withOpacity(0.05 + t * 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => old.t != t;
}

// ─── Google SVG logo (inline) ────────────────────────────────────────────────
// Evita dipendenza da assets — usiamo un'icona colorata con lettere "G"
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => Container(
    width: 22, height: 22,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
    child: const Center(
      child: Text('G', style: TextStyle(
        color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 14, height: 1)),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  String _error = '';

  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = ''; });

    final auth = sl<AuthService>();
    AuthResult result;

    if (_isLogin) {
      result = await auth.login(username: _userCtrl.text, password: _passCtrl.text);
    } else {
      result = await auth.register(
          username: _userCtrl.text, password: _passCtrl.text, email: _emailCtrl.text);
    }

    if (!mounted) return;

    if (result == AuthResult.success) {
      final uid     = auth.currentUid!;
      final account = auth.currentAccount!;
      await reloadUserServices(uid);
      await sl<PlayerService>().loadOrCreate(username: account.username, uid: uid);
      widget.onAuthenticated();
    } else {
      setState(() { _loading = false; _error = _errorMsg(result); });
    }
  }

  String _errorMsg(AuthResult r) {
    switch (r) {
      case AuthResult.userNotFound:      return 'Account non trovato. Registrati!';
      case AuthResult.wrongPassword:     return 'Password errata. Riprova.';
      case AuthResult.usernameTaken:     return 'Username già in uso.';
      case AuthResult.emailAlreadyInUse: return 'Email già registrata. Accedi invece.';
      case AuthResult.networkError:      return 'Errore di rete o server. Controlla la connessione e riprova.';
      case AuthResult.invalidInput:
        return _isLogin ? 'Username o password troppo corti' : 'Min. 3 caratteri per username, 6 per password';
      default: return 'Account non trovato. Prova a registrarti o controlla username/password.';
    }
  }

  Future<void> _showForgotPassword() async {
    final emailCtrl = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Inserisci la tua email per ricevere il link di reset.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'email@example.com',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx, true);
              await sl<AuthService>().sendPasswordReset(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('INVIA', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✉️ Email di reset inviata! Controlla la posta.'),
        backgroundColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _googleLoading = true; _error = ''; });
    final auth   = sl<AuthService>();
    final result = await auth.loginWithGoogle();
    if (!mounted) return;
    if (result == AuthResult.success) {
      final uid     = auth.currentUid!;
      final account = auth.currentAccount!;
      await reloadUserServices(uid);
      await sl<PlayerService>().loadOrCreate(username: account.username, uid: uid);
      widget.onAuthenticated();
    } else {
      setState(() {
        _googleLoading = false;
        // Se l'utente ha semplicemente annullato, non mostrare errore
        if (result != AuthResult.error) {
          _error = _errorMsg(result);
        }
      });
    }
  }

  void _toggle() => setState(() {
    _isLogin = !_isLogin;
    _error = '';
    _userCtrl.clear(); _passCtrl.clear(); _emailCtrl.clear();
  });

  // Entra senza account: gioco in locale (Hive), nessun backend richiesto.
  Future<void> _continueAsGuest() async {
    await sl<PlayerService>().loadOrCreate(username: 'Ospite', uid: 'local');
    if (mounted) widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated background
          const _AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 44),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A3A5C), Color(0xFF0F2035)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 30, spreadRadius: 2),
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Center(child: Text('📦', style: TextStyle(fontSize: 50))),
          ),
        ),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF7EC8E3), Color(0xFF4B7BEC)],
          ).createShader(b),
          child: const Text(
            'CONTAINER EMPIRE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Apri · Colleziona · Domina',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Tab switcher
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              _Tab(label: 'ACCEDI',     active: _isLogin,  onTap: () { if (!_isLogin) _toggle(); }),
              _Tab(label: 'REGISTRATI', active: !_isLogin, onTap: () { if (_isLogin) _toggle(); }),
            ]),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(children: [
              _Field(
                ctrl: _userCtrl, label: 'Username', icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().length < 3) ? 'Minimo 3 caratteri' : null,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                _Field(
                  ctrl: _emailCtrl, label: 'Email (opzionale)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
              const SizedBox(height: 12),
              _Field(
                ctrl: _passCtrl, label: 'Password', icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Minimo 6 caratteri' : null,
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.35)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                  ]),
                ),
              ],

              // ── Password dimenticata (solo in modalità login) ───────────────
              if (_isLogin) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPassword,
                    child: const Text('Password dimenticata?',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              const SizedBox(height: 22),
              _SubmitBtn(isLogin: _isLogin, loading: _loading, onPressed: _submit),
              const SizedBox(height: 16),

              // ── Google Sign-In ──────────────────────────────────────────────
              const Row(children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('oppure', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _googleLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.surface,
                  ),
                  child: _googleLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _GoogleLogo(),
                          SizedBox(width: 10),
                          Text('Continua con Google', style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ]),
                ),
              ),
              const SizedBox(height: 14),

              GestureDetector(
                onTap: _toggle,
                child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12), children: [
                  TextSpan(
                    text: _isLogin ? 'Non hai un account? ' : 'Hai già un account? ',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  TextSpan(
                    text: _isLogin ? 'Registrati' : 'Accedi',
                    style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800),
                  ),
                ])),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _continueAsGuest,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                  ),
                  child: const Text('Entra come ospite →',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Tab switcher ─────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.neonCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12, letterSpacing: 0.8,
          ),
        ),
      ),
    ),
  );
}

// ─── Text field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl, required this.label, required this.icon,
    this.obscure = false, this.keyboardType = TextInputType.text,
    this.suffix, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, obscureText: obscure,
    keyboardType: keyboardType, validator: validator,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 10),
    ),
  );
}

// ─── Submit button ────────────────────────────────────────────────────────────

class _SubmitBtn extends StatefulWidget {
  final bool isLogin, loading;
  final VoidCallback onPressed;
  const _SubmitBtn({required this.isLogin, required this.loading, required this.onPressed});

  @override
  State<_SubmitBtn> createState() => _SubmitBtnState();
}

class _SubmitBtnState extends State<_SubmitBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   widget.loading ? null : (_) => setState(() => _pressed = true),
      onTapUp:     widget.loading ? null : (_) { setState(() => _pressed = false); widget.onPressed(); },
      onTapCancel: widget.loading ? null : ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.loading
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF5B8BFC), Color(0xFF3A6BD4)],
                  ),
            color: widget.loading ? AppColors.surfaceLight : null,
            boxShadow: widget.loading ? null : [
              const BoxShadow(color: Color(0x664B7BEC), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!widget.loading)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              widget.loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2.5))
                  : Text(
                      widget.isLogin ? 'ACCEDI' : 'CREA ACCOUNT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
