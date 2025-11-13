import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_state.dart';
import '../state/language_state.dart';

// screens
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/products/products_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/request_detail_screen.dart';
import '../features/profile/profile_screen.dart';

// chats
import '../features/chat/chats_screen.dart';
import '../features/chat/chat_detail_screen.dart';

GoRouter createAppRouter(AuthState auth, LanguageState lang) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(auth: auth, lang: lang),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(auth: auth, lang: lang),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(
          auth: auth,
          lang: lang,
          name: auth.username ?? '',
        ),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => ProductsScreen(auth: auth, lang: lang),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '0') ?? 0;
          return ProductDetailScreen(auth: auth, lang: lang, productId: id);
        },
      ),
      GoRoute(
        path: '/request/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idParam) ?? 0;

          // ya tenías estos
          final name = state.uri.queryParameters['name'] ?? 'Solicitud';
          final desc = state.uri.queryParameters['desc'] ?? '';
          final cat  = state.uri.queryParameters['cat'];

          // 👇 NUEVO: opcionales del solicitante
          final requesterId         = int.tryParse(state.uri.queryParameters['requester_id'] ?? '');
          final requesterUsername   = state.uri.queryParameters['requester_username'];
          final requesterPhoto      = state.uri.queryParameters['requester_photo'];
          final requesterLocation   = state.uri.queryParameters['requester_location'];
          final requesterValStr     = state.uri.queryParameters['requester_valoration'];
          final requesterValoration = requesterValStr != null ? num.tryParse(requesterValStr) : null;

          // 👇 NUEVO: fechas opcionales (si las tuvieses)
          final createdAtIso = state.uri.queryParameters['created_at'];
          final updatedAtIso = state.uri.queryParameters['updated_at'];

          return RequestDetailScreen(
            auth: auth,
            lang: lang,
            requestId: id,
            name: name,
            description: desc,
            categoryName: cat,
            requesterId: requesterId,
            requesterUsername: requesterUsername,
            requesterPhoto: requesterPhoto,
            requesterLocation: requesterLocation,
            requesterValoration: requesterValoration,
            createdAtIso: createdAtIso,
            updatedAtIso: updatedAtIso,
          );
        },
      ),

      // 👇 Perfil propio (sin id)
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          auth: auth,
          lang: lang,
          otherUserId: null,
        ),
      ),

      // 👇 Perfil público / ajeno con id
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final rawId = state.pathParameters['id'] ?? '';
          debugPrint('[ROUTER] /profile/:id  rawId=$rawId');
          final sellerId = int.tryParse(rawId);
          final extra = state.extra;
          Map<String, dynamic>? prefetchedUser;
          List<dynamic>? prefetchedReviews;
          if (extra is Map) {
            prefetchedUser = extra['prefetchedUser'] as Map<String, dynamic>?;
            prefetchedReviews = extra['prefetchedReviews'] as List<dynamic>?;
          }
          return ProfileScreen(
            auth: auth,
            lang: lang,
            otherUserId: sellerId,
            prefetchedUser: prefetchedUser,
            prefetchedReviews: prefetchedReviews,
          );
        },
      ),

      GoRoute(
        path: '/chats',
        builder: (context, state) => ChatsScreen(auth: auth, lang: lang),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) {
          final chatIdStr = state.pathParameters['id'] ?? '0';
          final chatId = int.tryParse(chatIdStr) ?? 0;
          final otherUser = state.uri.queryParameters['name'] ?? 'Chat';
          final image = state.uri.queryParameters['img'];
          return ChatDetailScreen(
            auth: auth,
            lang: lang,
            chatId: chatId,
            otherUser: otherUser,
            imagePath: image,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
}
