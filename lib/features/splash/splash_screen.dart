import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_state.dart';
import '../../state/language_state.dart';

class SplashScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  const SplashScreen({
    super.key,
    required this.auth,
    required this.lang,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // esperamos a que se pinte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        // si quieres que si está logueado vaya al dashboard
        if (widget.auth.isLoggedIn) {
          context.go('/dashboard');
        } else {
          context.go('/login');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(size: 96),
            const SizedBox(height: 18),
            Text(
              'Reutilitzable',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
