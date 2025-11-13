import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_state.dart';
import '../../state/language_state.dart';
import '../../core/widgets/app_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  final AuthState auth;
  final LanguageState lang;
  final String name;

  const DashboardScreen({
    super.key,
    required this.auth,
    required this.lang,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final isES = lang.lang == 'es';
    return AppScaffold(
      auth: auth,
      lang: lang,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                isES ? 'Hola, $name' : 'Hola, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                isES ? 'Bienvenido al panel.' : 'Benvingut al taulell.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/products'),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(isES ? 'Ver productos' : 'Veure productes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
