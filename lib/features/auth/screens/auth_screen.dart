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

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
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
      result = await auth.login(
        username: _userCtrl.text,
        password: _passCtrl.text,
      );
    } else {
      result = await auth.register(
        username: _userCtrl.text,
        password: _passCtrl.text,
        email: _emailCtrl.text,
      );
    }

    if (!mounted) return;

    if (result == AuthResult.success) {
      // Ricarica i servizi con il nuovo uid
      final uid = auth.currentUid!;
      final account = auth.currentAccount!;
      await reloadUserServices(uid);
      // Crea il player se non esiste
      await sl<PlayerService>().loadOrCreate(
        username: account.username,
        uid: uid,
      );
      widget.onAuthenticated();
    } else {
      setState(() {
        _loading = false;
        _error = _errorMessage(result);
      });
    }
  }

  String _errorMessage(AuthResult r) {
    switch (r) {
      case AuthResult.userNotFound:     return 'Account non trovato. Registrati!';
      case AuthResult.wrongPassword:    return 'Password errata. Riprova.';
      case AuthResult.usernameTaken:    return 'Username già in uso. Scegline un altro.';
      case AuthResult.invalidInput:
        return _isLogin
            ? 'Username o password troppo corti'
            : 'Username min. 3 caratteri, password min. 6';
      default: return 'Errore sconosciuto. Riprova.';
    }
  }

  void _toggle() {
    setState(() {
      _isLogin = !_isLogin;
      _error = '';
      _userCtrl.clear();
      _passCtrl.clear();
      _emailCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated background glow ──────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: -80,
                  left: -60,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.neonCyan.withOpacity(0.08 + _bgCtrl.value * 0.05),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  right: -40,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.neonPurple.withOpacity(0.07 + _bgCtrl.value * 0.04),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Logo + title
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.neonCyan.withOpacity(0.2),
                              AppColors.neonPurple.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: AppColors.neonCyan, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 30, spreadRadius: 4),
                          ],
                        ),
                        child: const Center(
                          child: Text('📦', style: TextStyle(fontSize: 48)),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms),

                      const SizedBox(height: 20),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonPurple],
                        ).createShader(bounds),
                        child: const Text(
                          'CONTAINER EMPIRE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      Text(
                        _isLogin ? 'Bentornato! Accedi al tuo account.' : 'Crea il tuo account e inizia a giocare.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 40),

                  // ── Tab login / register ─────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _TabBtn(label: 'ACCEDI', active: _isLogin, onTap: () { if (!_isLogin) _toggle(); }),
                        _TabBtn(label: 'REGISTRATI', active: !_isLogin, onTap: () { if (_isLogin) _toggle(); }),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 28),

                  // ── Form ────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Username
                        _NeonField(
                          controller: _userCtrl,
                          label: 'Username',
                          icon: Icons.person_rounded,
                          validator: (v) {
                            if (v == null || v.trim().length < 3) return 'Min. 3 caratteri';
                            return null;
                          },
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: -0.1, end: 0),

                        if (!_isLogin) ...[
                          const SizedBox(height: 14),
                          _NeonField(
                            controller: _emailCtrl,
                            label: 'Email (opzionale)',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideX(begin: -0.1, end: 0),
                        ],

                        const SizedBox(height: 14),

                        // Password
                        _NeonField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_rounded,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) return 'Min. 6 caratteri';
                            return null;
                          },
                        ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.1, end: 0),

                        const SizedBox(height: 8),

                        // Error message
                        if (_error.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).shake(),

                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.neonCyan, AppColors.neonPurple],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppColors.neonCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
                                ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Text(
                                        _isLogin ? '🔓  ACCEDI' : '🚀  CREA ACCOUNT',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Toggle link
                        GestureDetector(
                          onTap: _toggle,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: _isLogin ? 'Non hai un account? ' : 'Hai già un account? ',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                TextSpan(
                                  text: _isLogin ? 'Registrati' : 'Accedi',
                                  style: const TextStyle(
                                    color: AppColors.neonCyan,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.neonCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Info storage
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_rounded, color: AppColors.neonGreen, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'I tuoi progressi vengono salvati localmente e associati al tuo account.',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple])
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontWeight: active ? FontWeight.w900 : FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Neon text field ─────────────────────────────────────────────────────────

class _NeonField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _NeonField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }
}
