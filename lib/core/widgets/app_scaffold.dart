// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_state.dart';
import '../../state/language_state.dart';
import '../../data/services/auth_service.dart'; // 👈 nuevo

class AppScaffold extends StatefulWidget {
  final Widget child;
  final AuthState auth;
  final LanguageState lang;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.child,
    required this.auth,
    required this.lang,
    this.backgroundColor,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  static const _platform = MethodChannel('app.channel/navigation');
  final _service = const AuthService(); // 👈 para pedir chats

  @override
  void initState() {
    super.initState();
    _loadUnreadChats(); // 👈 nada más montar, intentamos cargar
  }

  @override
  void didUpdateWidget(covariant AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // si cambia el token (login/logout), recargamos los no leídos
    if (oldWidget.auth.token != widget.auth.token) {
      _loadUnreadChats();
    }
  }

  Future<void> _loadUnreadChats() async {
    // si no está logueado no hay nada que pedir
    if (!widget.auth.isLoggedIn) {
      widget.auth.setUnreadChats(0);
      return;
    }

    try {
      final data = await _service.fetchChats(widget.auth.token);
      final unreadTotal = data
          .where((c) => (c['unread_messages_count'] ?? 0) > 0)
          .length;
      widget.auth.setUnreadChats(unreadTotal);
    } catch (_) {
      // si falla no rompemos la UI
    }
  }

  Future<void> _sendToBackground() async {
    try {
      await _platform.invokeMethod('sendToBackground');
    } catch (_) {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  String _currentPath(BuildContext context) {
    final r = GoRouter.of(context);
    return r.routeInformationProvider.value.uri.toString();
  }

  Future<void> _handleBack(BuildContext context) async {
    final router = GoRouter.of(context);
    final loc = _currentPath(context);

    // 1) si hay algo en el stack → pop normal
    if (router.canPop()) {
      router.pop();
      return;
    }

    // 2) detalle de producto sin stack → volver a /products
    if (loc.startsWith('/product/')) {
      router.go('/products');
      return;
    }

    // 3) detalle de chat sin stack → volver a /chats (respetando tab si viene)
    if (loc.startsWith('/chats/')) {
      final uri = Uri.parse(loc);
      final tab = uri.queryParameters['tab'];
      if (tab != null && tab.isNotEmpty) {
        router.go('/chats?tab=$tab');
      } else {
        router.go('/chats');
      }
      return;
    }

    // 4) si estamos en dashboard → mandar al fondo
    if (loc == '/dashboard' || loc == '/' || loc.isEmpty) {
      await _sendToBackground();
      return;
    }

    // 5) resto → al dashboard
    router.go('/dashboard');
  }

  void _openLangSheet(BuildContext context) {
    final isLogged = widget.auth.isLoggedIn;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lang.lang == 'es' ? 'Ajustes' : 'Ajustos',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // si está logueado: perfil + cerrar sesión
              if (isLogged) ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    widget.lang.lang == 'es' ? 'Mi perfil' : 'El meu perfil',
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.go('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(
                    widget.lang.lang == 'es'
                        ? 'Cerrar sesión'
                        : 'Tancar sessió',
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    widget.auth.logOut();
                    context.go('/login');
                  },
                ),
              ] else ...[
                // si NO está logueado: opción de login
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(
                    widget.lang.lang == 'es'
                        ? 'Entrar o registrarse'
                        : 'Entrar o registrar-se',
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.go('/login');
                  },
                ),
              ],

              const Divider(),
              Text(widget.lang.lang == 'es' ? 'Idioma' : 'Idioma'),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('ES'),
                    selected: widget.lang.lang == 'es',
                    onSelected: (_) => widget.lang.setLang('es'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('CA'),
                    selected: widget.lang.lang == 'ca',
                    onSelected: (_) => widget.lang.setLang('ca'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isES = widget.lang.lang == 'es';
    final loc = _currentPath(context);

    final onDashboard = loc == '/dashboard' || loc == '/' || loc.isEmpty;
    final onProducts =
        loc.startsWith('/products') || loc.startsWith('/product/');
    final onChats = loc.startsWith('/chats');
    final onProfile = loc.startsWith('/my-profile');

    // 👇 este valor ya lo habrá puesto el chats_screen o el propio scaffold
    final unreadChats = widget.auth.unreadChats;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? cs.surface,
        body: SafeArea(
          bottom: false,
          child: widget.child,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: () {
              if (onDashboard) return 0;
              if (onProducts) return 1;
              if (onChats) return 2;
              if (onProfile) return 3;
              return 0;
            }(),
            onDestinationSelected: (idx) {
              switch (idx) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/products');
                  break;
                case 2:
                  context.go('/chats');
                  break;
                case 3:
                  _openLangSheet(context);
                  break;
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: isES ? 'Inicio' : 'Inici',
              ),
              NavigationDestination(
                icon: const Icon(Icons.shopping_bag_outlined),
                selectedIcon: const Icon(Icons.shopping_bag),
                label: isES ? 'Productos' : 'Productes',
              ),
              NavigationDestination(
                icon: unreadChats > 0
                    ? Badge(
                  label: Text(
                    unreadChats.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                )
                    : const Icon(Icons.chat_bubble_outline),
                selectedIcon: unreadChats > 0
                    ? Badge(
                  label: Text(
                    unreadChats.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.chat_bubble),
                )
                    : const Icon(Icons.chat_bubble),
                label: isES ? 'Chats' : 'Xats',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: isES ? 'Perfil' : 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
