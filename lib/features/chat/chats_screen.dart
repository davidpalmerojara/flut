import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wallapop/core/app_config.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/data/services/auth_service.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class ChatsScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  const ChatsScreen({
    super.key,
    required this.auth,
    required this.lang,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _loading = true;
  List<dynamic> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    // si no hay login, no llamamos
    if (!widget.auth.isLoggedIn) {
      setState(() {
        _loading = false;
        _chats = [];
      });
      // 👇 sin login no hay chats no leídos
      widget.auth.setUnreadChats(0);
      return;
    }

    try {
      final data = await const AuthService().fetchChats(widget.auth.token);
      // 👇 calculamos no leídos
      final unreadTotal = data
          .where((c) => (c['unread_messages_count'] ?? 0) > 0)
          .length;
      widget.auth.setUnreadChats(unreadTotal);

      setState(() {
        _chats = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isES = widget.lang.lang == 'es';

    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, isES),
    );
  }

  Widget _buildContent(BuildContext context, bool isES) {
    // 1) no logueado
    if (!widget.auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isES
                    ? 'Debes iniciar sesión para ver tus chats.'
                    : 'Has d’iniciar sessió per veure els teus xats.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: Text(isES ? 'Ir a iniciar sesión' : 'Anar a iniciar sessió'),
              ),
            ],
          ),
        ),
      );
    }

    // separar por tipo
    final productChats =
    _chats.where((c) => c['product'] != null).toList(growable: false);
    final requestChats =
    _chats.where((c) => c['product_request'] != null).toList(growable: false);

    // 2) logueado pero sin nada
    if (productChats.isEmpty && requestChats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isES
                    ? 'Todavía no tienes conversaciones.'
                    : 'Encara no tens converses.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isES
                    ? 'Habla con alguien desde un producto o una solicitud.'
                    : 'Parla amb algú des d’un producte o una sol·licitud.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/products'),
                child: Text(isES ? 'Ver productos' : 'Veure productes'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(text: isES ? 'Productos' : 'Productes'),
                Tab(text: isES ? 'Solicitudes' : 'Sol·licituds'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ChatList(
                  chats: productChats,
                  isES: isES,
                  onOpen: _openChat,
                ),
                _ChatList(
                  chats: requestChats,
                  isES: isES,
                  onOpen: _openChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(int indexInOriginal, Map<String, dynamic> chat) {
    final imgPath = chat['image'] as String?;
    final otherUser = chat['other_user']?.toString() ?? 'Chat';
    final chatId = chat['id'] as int;

    // navegamos
    context.go(
      '/chats/$chatId?name=$otherUser${imgPath != null ? '&img=$imgPath' : ''}',
    );

    // marcamos leído en UI
    setState(() {
      final pos = _chats.indexWhere((c) => c['id'] == chatId);
      if (pos != -1) {
        _chats[pos]['unread_messages_count'] = 0;
      }

      // recalcular total y mandarlo al auth
      final unreadTotal = _chats
          .where((c) => (c['unread_messages_count'] ?? 0) > 0)
          .length;
      widget.auth.setUnreadChats(unreadTotal);
    });
  }
}

// (dejo tu _ChatList tal cual)
class _ChatList extends StatelessWidget {
  final List<dynamic> chats;
  final bool isES;
  final void Function(int index, Map<String, dynamic> chat) onOpen;

  const _ChatList({
    required this.chats,
    required this.isES,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (chats.isEmpty) {
      return Center(
        child: Text(
          isES
              ? 'No hay chats en esta pestaña'
              : 'No hi ha xats en aquesta pestanya',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = chats[index];
        final unread = (c['unread_messages_count'] ?? 0) as int;
        final imgPath = c['image'] as String?;
        final otherUser = c['other_user']?.toString() ?? 'Chat';

        String? subtitle;
        if (c['product'] != null) {
          subtitle = isES
              ? 'Producto: ${c['product']}'
              : 'Producte: ${c['product']}';
        } else if (c['product_request'] != null) {
          subtitle = isES
              ? 'Solicitud: ${c['product_request']}'
              : 'Sol·licitud: ${c['product_request']}';
        }

        return Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onOpen(index, c),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: (imgPath != null && imgPath.isNotEmpty)
                        ? NetworkImage(mediaUrl(imgPath))
                        : null,
                    child: (imgPath == null || imgPath.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
