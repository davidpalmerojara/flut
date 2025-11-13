// lib/features/products/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wallapop/core/app_config.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/data/services/auth_service.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class ProductDetailScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.auth,
    required this.lang,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _raw;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await const AuthService()
          .fetchProductDetail(widget.auth.token, widget.productId);
      setState(() {
        _raw = d;
        _loading = false;
      });
    } catch (e) {
      print('[PRODUCT_DETAIL] error: $e');
      setState(() => _loading = false);
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
    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_raw == null) {
      return const Center(child: Text('No se pudo cargar el producto'));
    }

    final product = _raw!['product'] as Map<String, dynamic>? ?? {};
    final owner = _raw!['user'] as Map<String, dynamic>? ?? {};
    final isFav = _raw!['favorite'] as bool? ?? false;
    final reviewCount = _raw!['review_count'] as int? ?? 0;

    final name = product['name']?.toString() ?? 'Producto';
    final desc = product['description']?.toString() ?? '';
    final updatedAt = product['updated_at']?.toString();
    final createdAt = product['created_at']?.toString();
    final images = product['images'] as List<dynamic>? ?? const [];

    String? mainImage;
    if (images.isNotEmpty) {
      final first = images.first;
      if (first is Map && first['image'] != null) {
        mainImage = mediaUrl(first['image'].toString());
      }
    }

    final sellerId = owner['id'] as int?;
    final username = owner['username']?.toString() ?? 'Usuario';
    final location = owner['location']?.toString();
    final photo = owner['photo']?.toString();
    final photoUrl = photo != null ? mediaUrl(photo) : null;
    final sellerValoration = owner['valoration'];

    final isMine = (sellerId != null) && (sellerId == widget.auth.userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mainImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mainImage,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Theme.of(context).iconTheme.color,
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (updatedAt != null)
            Text(
              'Actualizado: ${_ddMMyyyy(updatedAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          if (createdAt != null)
            Text(
              'Creado: ${_ddMMyyyy(createdAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),

          const SizedBox(height: 16),

          Text(
            desc.isEmpty ? 'Sin descripción.' : desc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          Text(
            'Vendido por',
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
                // 👇 AHORA usamos push() en lugar de go()
                if (isMine) {
                  context.push('/profile'); // mantiene historial
                  return;
                }
                if (sellerId != null) {
                  context.push('/profile/$sellerId', extra: {
                    'prefetchedUser': owner,
                    'prefetchedReviews': [],
                  });
                } else {
                  context.push('/profile');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: photoUrl != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    radius: 24,
                  )
                      : const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person),
                  ),
                  title: Text(username),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (location != null && location.isNotEmpty) Text(location),
                      Row(
                        children: [
                          _StarsRow(rating: sellerValoration),
                          const SizedBox(width: 6),
                          Text('($reviewCount reviews)'),
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
    );
  }
}

class _StarsRow extends StatelessWidget {
  final dynamic rating;

  const _StarsRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    double r = 0;
    if (rating is int) r = rating.toDouble();
    if (rating is double) r = rating as double;
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
