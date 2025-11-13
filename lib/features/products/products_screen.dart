import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import 'package:wallapop/core/app_config.dart';
import 'package:wallapop/core/widgets/app_scaffold.dart';
import 'package:wallapop/data/services/auth_service.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class ProductsScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  const ProductsScreen({
    super.key,
    required this.auth,
    required this.lang,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _loadingProducts = true;
  bool _loadingRequests = true;
  List<dynamic> _products = [];
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadRequests();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await const AuthService().fetchProducts(widget.auth.token);
      setState(() {
        _products = data;
        _loadingProducts = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[PRODUCTS] error: $e');
      setState(() {
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    try {
      final data =
      await const AuthService().fetchProductRequests(widget.auth.token);
      setState(() {
        _requests = data;
        _loadingRequests = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[PRODUCT_REQUESTS] error: $e');
      setState(() {
        _loadingRequests = false;
      });
    }
  }

  int _initialTab(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final tab = uri.queryParameters['tab'];
    if (tab == 'requests') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isES = widget.lang.lang == 'es';

    return AppScaffold(
      auth: widget.auth,
      lang: widget.lang,
      child: DefaultTabController(
        length: 2,
        initialIndex: _initialTab(context),
        child: Column(
          children: [
            // tabs arriba
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
            // contenido
            Expanded(
              child: TabBarView(
                children: [
                  _buildProductsGrid(context),
                  _buildRequestsGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== PRODUCTOS ===================
  Widget _buildProductsGrid(BuildContext context) {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    final isES = widget.lang.lang == 'es';

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        final width = constraints.maxWidth;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        }

        if (_products.isEmpty) {
          return Center(
            child: Text(
              isES
                  ? 'No hay productos disponibles'
                  : 'No hi ha productes disponibles',
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final p = _products[index];
                    final id = p['id'] as int? ?? 0;
                    final name = p['name']?.toString() ?? 'Producto';
                    final updatedAt = p['updated_at']?.toString();
                    final formattedDate = _formatDate(updatedAt);

                    String? firstImage;
                    final images = p['images'] as List?;
                    if (images != null && images.isNotEmpty) {
                      final first = images.first;
                      if (first is Map &&
                          first['image'] != null &&
                          first['image'].toString().isNotEmpty) {
                        firstImage = mediaUrl(first['image']);
                      }
                    }

                    return _ProductCard(
                      title: name,
                      imageUrl: firstImage,
                      updatedAt: formattedDate,
                      // 👇 usar push para mantener el stack y que el back funcione
                      onTap: () => context.push('/product/$id'),
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =================== SOLICITUDES ===================
  Widget _buildRequestsGrid(BuildContext context) {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    final isES = widget.lang.lang == 'es';

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        final width = constraints.maxWidth;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        }

        if (_requests.isEmpty) {
          return Center(
            child: Text(
              isES
                  ? 'No hay solicitudes todavía'
                  : 'No hi ha sol·licituds encara',
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final r = _requests[index];
                    final id = r['id'] as int? ?? 0;

                    final title = (r['name'] ?? 'Solicitud').toString();
                    final description = (r['description'] ?? '').toString();

                    // categoría: intenta 'category_name', si no, 'category'
                    final String categoryText;
                    if (r['category_name'] != null &&
                        r['category_name'].toString().isNotEmpty) {
                      categoryText =
                      '${isES ? 'Categoría' : 'Categoria'}: ${r['category_name']}';
                    } else if (r['category'] != null) {
                      categoryText =
                      '${isES ? 'Categoría' : 'Categoria'}: ${r['category']}';
                    } else {
                      categoryText = '-';
                    }

                    return _RequestCard(
                      title: title,
                      category: categoryText,
                      onTap: () {
                        // ---- Extrae info del solicitante de forma resiliente ----
                        final Map<String, dynamic>? user = (r['user'] is Map)
                            ? (r['user'] as Map<String, dynamic>)
                            : (r['requester'] is Map
                            ? r['requester'] as Map<String, dynamic>
                            : null);

                        final dynamic rawRequesterId =
                        user != null ? user['id'] : r['requester_id'];

                        final requesterUsername =
                            (user != null ? user['username'] : r['requester_username'])
                                ?.toString() ??
                                '';
                        final requesterPhoto =
                            (user != null ? user['photo'] : r['requester_photo'])
                                ?.toString() ??
                                '';
                        final requesterLocation =
                            (user != null ? user['location'] : r['requester_location'])
                                ?.toString() ??
                                '';
                        final requesterValoration =
                        (user != null ? user['valoration'] : r['requester_valoration']);

                        final createdAt = r['created_at']?.toString();
                        final updatedAt = r['updated_at']?.toString();

                        // Monta query parameters sólo con lo que exista
                        final qp = <String, String>{
                          'name': title,
                          'desc': description,
                        };

                        // categoría legible si la tenemos
                        if (r['category_name'] != null &&
                            r['category_name'].toString().isNotEmpty) {
                          qp['cat'] = r['category_name'].toString();
                        } else if (r['category'] != null) {
                          qp['cat'] = r['category'].toString();
                        }

                        if (rawRequesterId != null) {
                          qp['requester_id'] = rawRequesterId.toString();
                        }
                        if (requesterUsername.isNotEmpty) {
                          qp['requester_username'] = requesterUsername;
                        }
                        if (requesterPhoto.isNotEmpty) {
                          qp['requester_photo'] = requesterPhoto;
                        }
                        if (requesterLocation.isNotEmpty) {
                          qp['requester_location'] = requesterLocation;
                        }
                        if (requesterValoration != null) {
                          qp['requester_valoration'] =
                              requesterValoration.toString();
                        }
                        if (createdAt != null && createdAt.isNotEmpty) {
                          qp['created_at'] = createdAt;
                        }
                        if (updatedAt != null && updatedAt.isNotEmpty) {
                          qp['updated_at'] = updatedAt;
                        }

                        final url = Uri(
                          path: '/request/$id',
                          queryParameters: qp,
                        ).toString();

                        debugPrint('[REQUEST NAV] -> $url  requester=$user');

                        // 👇 usar push para conservar el stack y que el back funcione
                        context.push(url);
                      },
                    );
                  },
                  childCount: _requests.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return isoDate;
    }
  }
}

// =================== CARD PRODUCTO ===================
class _ProductCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String updatedAt;
  final VoidCallback onTap;

  const _ProductCard({
    required this.title,
    required this.imageUrl,
    required this.updatedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cs.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: cs.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.update, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      updatedAt.isEmpty ? '-' : updatedAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
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

// =================== CARD SOLICITUD ===================
class _RequestCard extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback onTap;

  const _RequestCard({
    required this.title,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.assignment, size: 48, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
