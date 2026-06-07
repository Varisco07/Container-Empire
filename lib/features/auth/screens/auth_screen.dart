import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _bgCtrl;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _floatCtrl.dispose();
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
      final uid = auth.currentUid!;
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
      case AuthResult.userNotFound:  return 'Account non trovato. Registrati!';
      case AuthResult.wrongPassword: return 'Password errata. Riprova.';
      case AuthResult.usernameTaken: return 'Username già in uso.';
      case AuthResult.invalidInput:
        return _isLogin ? 'Username o password troppo corti' : 'Username min. 3 caratteri, password min. 6';
      default: return 'Errore. Riprova.';
    }
  }

  void _toggle() => setState(() {
    _isLogin = !_isLogin;
    _error = '';
    _userCtrl.clear();
    _passCtrl.clear();
    _emailCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04020C),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AnimatedBackground(ctrl: _bgCtrl),
          const _FloatingParticles(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, -5 + _floatCtrl.value * 10),
                      child: const _LogoSection(),
                    ),
                  ).animate().fadeIn(duration: 700.ms).slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 32),
                  _AuthCard(
                    isLogin: _isLogin, loading: _loading, obscure: _obscure,
                    error: _error, formKey: _formKey,
                    userCtrl: _userCtrl, passCtrl: _passCtrl, emailCtrl: _emailCtrl,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onSubmit: _submit, onToggle: _toggle,
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated background ──────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedBackground({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => SizedBox.expand(
        child: Stack(children: [
          Positioned(top: -100, left: -80,
            child: Container(width: 360, height: 360, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.neonCyan.withOpacity(0.06 + ctrl.value * 0.04), Colors.transparent]),
            ))),
          Positioned(bottom: -80, right: -60,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.neonPurple.withOpacity(0.08 + ctrl.value * 0.05), Colors.transparent]),
            ))),
          Positioned(top: 200, left: 60,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.neonGold.withOpacity(0.03 + ctrl.value * 0.025), Colors.transparent]),
            ))),
        ]),
      ),
    );
  }
}

// ─── Floating particles ───────────────────────────────────────────────────────

class _FloatingParticles extends StatelessWidget {
  const _FloatingParticles();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rng = Random(77);
    const emojis = ['📦', '💎', '⭐', '🔮', '✦', '💫'];
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(10, (i) {
            final x = rng.nextDouble() * size.width;
            final y = rng.nextDouble() * size.height;
            final emoji = emojis[rng.nextInt(emojis.length)];
            final s = 10.0 + rng.nextDouble() * 14;
            return Positioned(
              left: x, top: y,
              child: Opacity(
                opacity: 0.12 + rng.nextDouble() * 0.2,
                child: Text(emoji, style: TextStyle(fontSize: s)),
              ).animate(
                delay: Duration(milliseconds: rng.nextInt(3000)),
                onPlay: (c) => c.repeat(reverse: true),
              ).moveY(begin: 0, end: -18 - rng.nextDouble() * 20,
                      duration: Duration(seconds: 3 + rng.nextInt(3)))
               .fadeIn(duration: 1000.ms)
               .then().fadeOut(duration: 1000.ms),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Logo section ─────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A30), Color(0xFF0A0520)],
        ),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 30, spreadRadius: 4),
          BoxShadow(color: AppColors.neonPurple.withOpacity(0.2), blurRadius: 50, spreadRadius: 8),
        ],
      ),
      child: const Center(child: Text('📦', style: TextStyle(fontSize: 48))),
    ),
    const SizedBox(height: 18),
    ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFF5B0), Color(0xFFFFD700)],
        stops: [0, 0.5, 1],
      ).createShader(bounds),
      child: const Text('CONTAINER EMPIRE', style: TextStyle(
        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
    ),
    const SizedBox(height: 6),
    const Text('Apri · Colleziona · Domina', style: TextStyle(
      color: Color(0xFF506070), fontSize: 12, letterSpacing: 1.5)),
  ]);
}

// ─── Auth card ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isLogin, loading, obscure;
  final String error;
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl, emailCtrl;
  final VoidCallback onToggleObscure, onSubmit, onToggle;

  const _AuthCard({
    required this.isLogin, required this.loading, required this.obscure,
    required this.error, required this.formKey,
    required this.userCtrl, required this.passCtrl, required this.emailCtrl,
    required this.onToggleObscure, required this.onSubmit, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A1A),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF1E2A45)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Tab switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF050A15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2535)),
          ),
          child: Row(children: [
            _AuthTab(label: 'ACCEDI',     active: isLogin,  onTap: () { if (!isLogin) onToggle(); }),
            _AuthTab(label: 'REGISTRATI', active: !isLogin, onTap: () { if (isLogin) onToggle(); }),
          ]),
        ),
        const SizedBox(height: 24),

        Form(
          key: formKey,
          child: Column(children: [
            _GameInput(controller: userCtrl, label: 'Username',
                icon: Icons.person_rounded, iconColor: AppColors.neonCyan,
                validator: (v) => (v == null || v.trim().length < 3) ? 'Min. 3 caratteri' : null),

            if (!isLogin) ...[
              const SizedBox(height: 12),
              _GameInput(controller: emailCtrl, label: 'Email (opzionale)',
                  icon: Icons.email_rounded, iconColor: AppColors.neonPurple,
                  keyboardType: TextInputType.emailAddress),
            ],

            const SizedBox(height: 12),

            _GameInput(
              controller: passCtrl, label: 'Password',
              icon: Icons.lock_rounded, iconColor: AppColors.neonGold,
              obscure: obscure,
              suffix: IconButton(
                icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.textMuted, size: 18),
                onPressed: onToggleObscure,
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min. 6 caratteri' : null,
            ),

            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                ]),
              ).animate().shake(hz: 4, offset: const Offset(4, 0)).fadeIn(),
            ],

            const SizedBox(height: 22),
            _SubmitButton(isLogin: isLogin, loading: loading, onPressed: onSubmit),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: onToggle,
              child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12), children: [
                TextSpan(
                  text: isLogin ? 'Non hai un account? ' : 'Hai già un account? ',
                  style: const TextStyle(color: AppColors.textMuted)),
                TextSpan(
                  text: isLogin ? 'Registrati →' : 'Accedi →',
                  style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline, decorationColor: AppColors.neonCyan)),
              ])),
            ),
          ]),
        ),
      ]),
    ),
  );
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _AuthTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]) : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 12)] : null,
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: active ? Colors.white : AppColors.textMuted,
          fontWeight: active ? FontWeight.w900 : FontWeight.w600, fontSize: 12, letterSpacing: 1)),
      ),
    ),
  );
}

class _GameInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _GameInput({
    required this.controller, required this.label, required this.icon, required this.iconColor,
    this.obscure = false, this.keyboardType = TextInputType.text, this.suffix, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller, obscureText: obscure,
    keyboardType: keyboardType, validator: validator,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10), width: 34, height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9),
          border: Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Icon(icon, color: iconColor, size: 16),
      ),
      suffixIcon: suffix,
      filled: true, fillColor: const Color(0xFF06090F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A2535))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A2535))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: iconColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 10),
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  final bool isLogin, loading;
  final VoidCallback onPressed;
  const _SubmitButton({required this.isLogin, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onPressed,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: loading
            ? const LinearGradient(colors: [Color(0xFF1A2535), Color(0xFF1A2535)])
            : const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.neonCyan, AppColors.neonPurple]),
        boxShadow: loading ? null : [
          BoxShadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4)),
          BoxShadow(color: AppColors.neonPurple.withOpacity(0.2), blurRadius: 30, spreadRadius: 2),
        ],
        border: Border.all(color: loading ? AppColors.border : Colors.transparent),
      ),
      child: Stack(alignment: Alignment.center, children: [
        if (!loading)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(color: Colors.transparent)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.2)),
          ),
        if (loading)
          const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2.5))
        else
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(isLogin ? '🔓' : '🚀', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(isLogin ? 'GIOCA ORA' : 'CREA ACCOUNT',
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w900, letterSpacing: 2.5,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))])),
          ]),
      ]),
    ),
  );
}
