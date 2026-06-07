import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/auth_service.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class _ContainerEmpireAppState extends ConsumerState<ContainerEmpireApp> {
  late bool _authenticated;

  @override
  void initState() {
    super.initState();
    _authenticated = sl<AuthService>().isLoggedIn;
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
          return Container(
            color: const Color(0xFF020609),
            child: isWide
                ? Row(children: [
                    Expanded(child: Container(color: const Color(0xFF020609))),
                    SizedBox(width: appW, child: content),
                    Expanded(child: Container(color: const Color(0xFF020609))),
                  ])
                : content,
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
        return Container(
          color: const Color(0xFF020609),
          child: isWide
              ? Row(children: [
                  Expanded(child: Container(color: const Color(0xFF020609))),
                  SizedBox(width: appW, child: child!),
                  Expanded(child: Container(color: const Color(0xFF020609))),
                ])
              : child!,
        );
      },
    );
  }
}
