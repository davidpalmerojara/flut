// lib/features/chat/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:wallapop/core/app_config.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/data/services/auth_service.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class ChatDetailScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;
  final int chatId;
  final String otherUser;
  final String? imagePath;

  const ChatDetailScreen({
    super.key,
    required this.auth,
    required this.lang,
    required this.chatId,
    required this.otherUser,
    this.imagePath,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  bool _loading = true;
  List<dynamic> _messages = [];
  final _textController = TextEditingController();
  final _service = const AuthService();
  final _listController = ScrollController(); // 👈 para hacer scroll al final

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs =
      await _service.fetchMessages(widget.auth.token, widget.chatId);
      setState(() {
        _messages = msgs;
        _loading = false;
      });

      // después de pintar, baja al final
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    // esperamos a que se pinte la lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.jumpTo(
        _listController.position.maxScrollExtent,
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final ok =
    await _service.sendMessage(widget.auth.token, widget.chatId, text);

    if (ok) {
      _textController.clear();
      await _loadMessages(); // vuelve a cargar y baja
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    }
  }

  // timestamp → "11/11/2025 08:24"
  String _formatTs(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int n) => n < 10 ? '0$n' : '$n';
      final d = two(dt.day);
      final m = two(dt.month);
      final y = dt.year.toString();
      final hh = two(dt.hour);
      final mm = two(dt.minute);
      return '$d/$m/$y $hh:$mm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      child: Column(
        children: [
          // cabecera
          Container(
            padding:
            const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 2,
                  color: Colors.black12,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(mediaUrl(widget.imagePath!)),
                  )
                else
                  const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.otherUser,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // mensajes
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _listController, // 👈 aquí
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final senderId = m['sender'];
                final myId = widget.auth.userId;
                final isMine = senderId == myId;
                final content = m['content']?.toString() ?? '';
                final ts = _formatTs(m['timestamp']?.toString());

                // debug
                // ignore: avoid_print
                print(
                    '💬 render msg#$index senderId=$senderId myId=$myId -> isMine=$isMine');

                final bubbleColor = isMine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant;

                final textColor = isMine
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface;

                final align = isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft;

                final radius = isMine
                    ? const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                )
                    : const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                );

                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: radius,
                    ),
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          content,
                          style: TextStyle(color: textColor),
                        ),
                        if (ts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ts,
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // input
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // campo de texto estilo M3
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Escribe un mensaje…',
                                border: InputBorder.none,
                              ),
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: _send,
                    label: const SizedBox.shrink(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          )
,
        ],
      ),
    );
  }
}
