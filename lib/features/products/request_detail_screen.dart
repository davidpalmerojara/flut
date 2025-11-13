// lib/features/products/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wallapop/core/app_config.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';
import 'package:wallapop/data/services/auth_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  final int requestId;
  final String name;
  final String description;
  final String? categoryName;

  final int? requesterId;
  final String? requesterUsername;
  final String? requesterPhoto;    // /media/...
  final String? requesterLocation;
  final num? requesterValoration;

  final String? createdAtIso;
  final String? updatedAtIso;

  const RequestDetailScreen({
    super.key,
    required this.auth,
    required this.lang,
    required this.requestId,
    required this.name,
    required this.description,
    this.categoryName,
    this.requesterId,
    this.requesterUsername,
    this.requesterPhoto,
    this.requesterLocation,
    this.requesterValoration,
    this.createdAtIso,
    this.updatedAtIso,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _requester; // perfil cargado
  bool _loadingRequester = false;

  @override
  void initState() {
    super.initState();
    // Log inicial de lo que nos llega por router
    debugPrint('[REQ DETAIL] init '
        'id=${widget.requestId} '
        'requesterId=${widget.requesterId} '
        'rqUser=${widget.requesterUsername} '
        'rqPhoto=${widget.requesterPhoto} '
        'rqLoc=${widget.requesterLocation} '
        'rqVal=${widget.requesterValoration}');
    _maybeLoadRequester();
  }

  Future<void> _maybeLoadRequester() async {
    if (widget.requesterId == null) return;
    setState(() => _loadingRequester = true);

    try {
      // 1) público sin token
      debugPrint('[REQ DETAIL] fetch public profile id=${widget.requesterId}');
      final pub = await const AuthService()
          .fetchPublicProfileById(widget.requesterId!);
      setState(() {
        _requester = pub['user'] as Map<String, dynamic>?;
      });
      debugPrint('[REQ DETAIL] public OK -> user=${_requester}');
    } catch (e) {
      debugPrint('[REQ DETAIL] public profile failed: $e');
      // 2) si hay token, privado by id
      if (widget.auth.token != null) {
        try {
          debugPrint('[REQ DETAIL] fetch private profile id=${widget.requesterId}');
          final priv = await const AuthService()
              .fetchProfileById(widget.auth.token!, widget.requesterId!);
          setState(() {
            _requester = priv['user'] as Map<String, dynamic>?;
          });
          debugPrint('[REQ DETAIL] private OK -> user=${_requester}');
        } catch (e2) {
          debugPrint('[REQ DETAIL] private profile also failed: $e2');
        }
      }
    } finally {
      if (mounted) setState(() => _loadingRequester = false);
    }
  }

  String _ddMMyyyy(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    if (iso.length < 10) return iso;
    final y = iso.substring(0, 4);
    final m = iso.substring(5, 7);
    final d = iso.substring(8, 10);
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isES = widget.lang.lang == 'es';

    // Efectivos: lo cargado > lo pasado por query > fallback
    final effectiveUsername =
    (_requester?['username']?.toString().trim().isNotEmpty ?? false)
        ? _requester!['username'].toString()
        : (widget.requesterUsername?.trim().isNotEmpty ?? false)
        ? widget.requesterUsername!
        : (isES ? 'Usuario' : 'Usuari');

    final effectivePhotoPath =
    (_requester?['photo']?.toString().isNotEmpty ?? false)
        ? _requester!['photo'].toString()
        : (widget.requesterPhoto ?? '');
    final effectivePhotoUrl =
    effectivePhotoPath.isEmpty ? null : mediaUrl(effectivePhotoPath);

    final effectiveLocation =
    (_requester?['location']?.toString().isNotEmpty ?? false)
        ? _requester!['location'].toString()
        : (widget.requesterLocation ?? '');

    final dynamic effectiveValorationDyn =
        _requester?['valoration'] ?? widget.requesterValoration;
    num? effectiveValoration;
    if (effectiveValorationDyn is num) {
      effectiveValoration = effectiveValorationDyn;
    } else if (effectiveValorationDyn is String) {
      final parsed = num.tryParse(effectiveValorationDyn);
      if (parsed != null) effectiveValoration = parsed;
    }

    final isMine = (widget.requesterId != null) &&
        (widget.auth.userId != null) &&
        (widget.requesterId == widget.auth.userId);

    // Log de qué vamos a pintar finalmente
    debugPrint('[REQ DETAIL] will render requester: '
        'name=$effectiveUsername photo=$effectivePhotoUrl '
        'loc=$effectiveLocation val=$effectiveValoration isMine=$isMine '
        'loading=$_loadingRequester');

    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (Sin imagen de cabecera para solicitudes)

            // ======== Título ========
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.name.isEmpty
                        ? (isES ? 'Solicitud' : 'Sol·licitud')
                        : widget.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ======== Fechas y categoría ========
            if (widget.updatedAtIso != null)
              Text(
                (isES ? 'Actualizado: ' : 'Actualitzat: ') +
                    _ddMMyyyy(widget.updatedAtIso),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            if (widget.createdAtIso != null)
              Text(
                (isES ? 'Creado: ' : 'Creat: ') +
                    _ddMMyyyy(widget.createdAtIso),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            if (widget.categoryName != null &&
                widget.categoryName!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                (isES ? 'Categoría: ' : 'Categoria: ') +
                    widget.categoryName!.trim(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 16),

            // ======== Descripción ========
            Text(
              widget.description.isEmpty
                  ? (isES ? 'Sin descripción.' : 'Sense descripció.')
                  : widget.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            // ======== “Solicitado por” ========
            Text(
              isES ? 'Solicitado por' : 'Sol·licitat per',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // push para conservar back
                  if (isMine) {
                    context.push('/profile');
                    return;
                  }
                  if (widget.requesterId != null) {
                    context.push('/profile/${widget.requesterId}');
                  } else {
                    context.push('/profile');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: effectivePhotoUrl != null
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(effectivePhotoUrl),
                      radius: 24,
                    )
                        : const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.person),
                    ),
                    title: _loadingRequester
                        ? Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(isES ? 'Cargando...' : 'Carregant...'),
                      ],
                    )
                        : Text(effectiveUsername),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (effectiveLocation.isNotEmpty)
                          Text(effectiveLocation),
                        Row(
                          children: [
                            _StarsRow(rating: effectiveValoration),
                            if (effectiveValoration != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                effectiveValoration.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final num? rating;
  const _StarsRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    double r = 0;
    if (rating != null) r = rating!.toDouble();
    if (r < 0) r = 0;
    if (r > 5) r = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < r ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.orange,
        );
      }),
    );
  }
}
