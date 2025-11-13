// lib/features/profile/my_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class MyProfileScreen extends StatelessWidget {
  final AuthState auth;
  final LanguageState lang;

  const MyProfileScreen({
    super.key,
    required this.auth,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isES = lang.lang == 'es';

    return AppScaffold(
      auth: auth,
      lang: lang,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // datos del usuario
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.username ?? 'Usuario'),
                      Text(
                        isES ? 'Mi perfil' : 'El meu perfil',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Productos favoritos'),
                Tab(text: 'Valoraciones'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Center(
                    child: Text(
                      isES
                          ? 'Aquí irán los productos favoritos'
                          : 'Aquí aniran els productes favorits',
                    ),
                  ),
                  Center(
                    child: Text(
                      isES
                          ? 'Aquí irán tus valoraciones'
                          : 'Aquí aniran les teves valoracions',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
