// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/language_state.dart';
import '../../data/services/auth_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/app_config.dart';

class ProfileScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  /// si viene, mostramos el perfil de ese usuario (vendedor, por ejemplo)
  final int? otherUserId;

  /// 👇 nuevo: datos prefetcheados desde ProductDetailScreen
  final Map<String, dynamic>? prefetchedUser;
  final List<dynamic>? prefetchedReviews;

  const ProfileScreen({
    super.key,
    required this.auth,
    required this.lang,
    this.otherUserId,
    this.prefetchedUser,
    this.prefetchedReviews,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _futureProfile;

  @override
  void initState() {
    super.initState();

    final token = widget.auth.token;
    final otherId = widget.otherUserId;

    debugPrint('[PROFILE] init otherUserId=$otherId auth.userId=${widget.auth.userId} token? ${token != null}');

    // 1) Si venimos con user prefetcheado (desde ProductDetail), úsalo directamente
    if (otherId != null && widget.prefetchedUser != null) {
      debugPrint('[PROFILE] using PREFETCHED user for id=$otherId (no fetch)');
      _futureProfile = Future.value({
        'user': widget.prefetchedUser!,
        'reviews': widget.prefetchedReviews ?? const [], // opcional
      });
      return;
    }

    // 2) Si no hay prefetch:
    if (otherId != null) {
      // Intentamos público; si falla y hay token, fallback a privado por id
      _futureProfile = (() async {
        try {
          debugPrint('[PROFILE] fetching PUBLIC profile id=$otherId');
          return await const AuthService().fetchPublicProfileById(otherId);
        } catch (e) {
          debugPrint('[PROFILE] public-by-id failed: $e');
          if (token != null) {
            debugPrint('[PROFILE] fallback to PRIVATE profile id=$otherId');
            return await const AuthService().fetchProfileById(token, otherId);
          }
          throw Exception('public_unavailable_without_login');
        }
      })();
      return;
    }

    // 3) Perfil propio
    if (token == null) {
      _futureProfile = Future.error('not_logged');
    } else {
      debugPrint('[PROFILE] fetching OWN profile');
      _futureProfile = const AuthService().fetchProfile(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isES = widget.lang.lang == 'es';
    final cs = Theme.of(context).colorScheme;
    final isForeignParam = widget.otherUserId != null;

    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      backgroundColor: cs.surface,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.error == 'not_logged') {
            return _LoginCTA(
              isES: isES,
              onTap: () => context.go('/login'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (!widget.auth.isLoggedIn) {
              return _LoginCTA(
                isES: isES,
                onTap: () => context.go('/login'),
              );
            }
            return Center(
              child: Text(
                (isES ? 'Error: ' : 'Error: ') + snapshot.error.toString(),
              ),
            );
          }

          final data = snapshot.data!;
          final user = data['user'] as Map<String, dynamic>?;

          final reviews = (data['reviews'] as List?) ?? const [];

          final userId = user?['id'] as int?;
          final isOwnByParam = widget.otherUserId != null &&
              widget.auth.userId != null &&
              widget.otherUserId == widget.auth.userId;
          final isOwn = isOwnByParam || widget.otherUserId == null;

          debugPrint('[PROFILE] build otherUserId=${widget.otherUserId} auth.userId=${widget.auth.userId} -> isOwn=$isOwn  userIdFromPayload=$userId');

          final username = user?['username']?.toString() ?? (isES ? 'Usuario' : 'Usuari');
          final photo = mediaUrl(user?['photo']?.toString());
          final phone = user?['phone']?.toString();
          final location = user?['location']?.toString();
          final desc = user?['description']?.toString();
          final valoration = user?['valoration'];

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isForeignParam
                            ? (isES ? 'Perfil de usuario' : 'Perfil d\'usuari')
                            : (isES ? 'Mi perfil' : 'El meu perfil'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              if (photo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    photo,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(Icons.person,
                                      color: cs.onPrimaryContainer),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (location != null && location.isNotEmpty)
                                      Text(
                                        location,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    if (phone != null && phone.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.phone,
                                                size: 14, color: cs.primary),
                                            const SizedBox(width: 4),
                                            Text(phone),
                                          ],
                                        ),
                                      ),
                                    if (valoration != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              (isES ? 'Valoración: ' : 'Valoració: ') +
                                                  _formatValoration(valoration),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isOwn)
                                IconButton(
                                  tooltip: isES ? 'Editar perfil' : 'Editar perfil',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {},
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isES ? 'Información' : 'Informació',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (location != null && location.isNotEmpty)
                                _InfoRow(icon: Icons.place_outlined, text: location),
                              if (phone != null && phone.isNotEmpty)
                                _InfoRow(icon: Icons.phone_outlined, text: phone),
                              if (valoration != null)
                                _InfoRow(
                                  icon: Icons.star_outline,
                                  text:
                                  '${isES ? 'Valoración' : 'Valoració'}: ${_formatValoration(valoration)}',
                                ),
                              if (desc != null && desc.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(desc, style: TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: cs.primary,
                  indicatorColor: cs.primary,
                  tabs: [
                    Tab(text: isES ? 'En venta' : 'En venda'),
                    Tab(text: isES ? 'Solicitudes' : 'Sol·licituds'),
                    Tab(text: isES ? 'Valoraciones' : 'Valoracions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPlaceholderTab(
                        context,
                        isForeignParam
                            ? (isES
                            ? 'Aún no mostramos sus productos en venta.'
                            : 'Encara no mostrem els seus productes en venda.')
                            : (isES
                            ? 'Aún no mostramos tus productos en venta.'
                            : 'Encara no mostrem els teus productes en venda.'),
                      ),
                      _buildPlaceholderTab(
                        context,
                        isForeignParam
                            ? (isES
                            ? 'Aún no mostramos sus solicitudes.'
                            : 'Encara no mostrem les seves sol·licituds.')
                            : (isES
                            ? 'Aún no mostramos tus solicitudes.'
                            : 'Encara no mostrem les teves sol·licituds.'),
                      ),
                      _buildReviewsTab(context, reviews),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatValoration(dynamic v) {
    if (v == null) return '-';
    if (v is int) return v.toString();
    if (v is double) {
      final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
      return s;
    }
    return v.toString();
  }

  Widget _buildPlaceholderTab(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildReviewsTab(BuildContext context, List<dynamic> reviews) {
    final isES = widget.lang.lang == 'es';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (reviews.isEmpty) {
      return Center(
        child: Text(
          isES ? 'No tiene valoraciones todavía.' : 'Encara no té valoracions.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = reviews[index] as Map<String, dynamic>;
        final rating = r['rating']?.toString();
        final comment = r['comment']?.toString() ?? '';
        final productId = r['product']?.toString();
        final creatorId = r['creator']?.toString();

        return Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isES ? 'Valoración' : 'Valoració',
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      Text(rating),
                    ],
                  ],
                ),
                if (productId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    (isES ? 'Producto: ' : 'Producte: ') + productId,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (creatorId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    (isES ? 'Hecha por usuario id: ' : 'Feta per usuari id: ') +
                        creatorId,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(comment, style: tt.bodyMedium),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _LoginCTA extends StatelessWidget {
  final bool isES;
  final VoidCallback onTap;

  const _LoginCTA({required this.isES, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isES
                      ? 'Crea una cuenta o inicia sesión para ver perfiles de vendedores.'
                      : 'Crea un compte o inicia sessió per veure perfils de venedors.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onTap,
                  child: Text(isES ? 'Iniciar sesión' : 'Iniciar sessió'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
