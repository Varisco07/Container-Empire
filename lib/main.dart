import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/player_service.dart';
import 'core/services/service_locator.dart';
import 'core/services/tycoon_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase — non bloccante: se la config è placeholder o manca
  // la connessione, l'app continua in modalità locale (Hive).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('⚠️ Firebase init saltato, modalità locale: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await setupServiceLocator();
  runApp(const ProviderScope(child: ContainerEmpireApp()));
}

class ContainerEmpireApp extends ConsumerStatefulWidget {
  const ContainerEmpireApp({super.key});

  @override
  ConsumerState<ContainerEmpireApp> createState() => _ContainerEmpireAppState();
}

class _ContainerEmpireAppState extends ConsumerState<ContainerEmpireApp>
    with WidgetsBindingObserver {
  late bool _authenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // PREVIEW_EMPIRE (dart-define, default off): salta l'auth per screenshot/dev.
    _authenticated =
        const bool.fromEnvironment('PREVIEW_EMPIRE') || sl<AuthService>().isLoggedIn;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Quando l'app va in background o viene chiusa, salva e forza la scrittura
    // su disco: così i progressi dell'impero non vanno persi.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (sl.isRegistered<TycoonService>()) sl<TycoonService>().persistAndFlush();
      if (sl.isRegistered<PlayerService>()) sl<PlayerService>().persistAndFlush();
    }
  }

  Widget _wrap(Widget content) {
    return MaterialApp(
      title: 'Container Empire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (ctx) {
          final screenW = MediaQuery.of(ctx).size.width;
          final isWide = screenW > 520;
          final appW = isWide ? 430.0 : screenW;
          // Wrap globale: elimina underline da testi web (GestureDetector eredita da browser)
          return DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
            child: Container(
              color: const Color(0xFF020609),
              child: isWide
                  ? Row(children: [
                      Expanded(child: Container(color: const Color(0xFF020609))),
                      SizedBox(width: appW, child: content),
                      Expanded(child: Container(color: const Color(0xFF020609))),
                    ])
                  : content,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return _wrap(AuthScreen(onAuthenticated: () => setState(() => _authenticated = true)));
    }

    // Utente autenticato → app completa con router
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Container Empire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        final screenW = MediaQuery.of(context).size.width;
        final isWide = screenW > 520;
        final appW = isWide ? 430.0 : screenW;
        // Wrap globale: elimina underline da testi web
        return DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          child: Container(
            color: const Color(0xFF020609),
            child: isWide
                ? Row(children: [
                    Expanded(child: Container(color: const Color(0xFF020609))),
                    SizedBox(width: appW, child: child!),
                    Expanded(child: Container(color: const Color(0xFF020609))),
                  ])
                : child!,
          ),
        );
      },
    );
  }
}
