import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'state/auth_state.dart';
import 'state/language_state.dart';
import 'core/theme.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthState _auth;
  late final LanguageState _lang;
  late final RouterConfig<Object> _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthState();
    _lang = LanguageState();
    _router = createAppRouter(_auth, _lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Reutilitzable',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
