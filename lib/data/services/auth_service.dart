import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wallapop/core/app_config.dart';

class AuthService {
  const AuthService();

  // ======================= AUTH =======================
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$kBaseUrl/api/token/');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al iniciar sesión (${resp.statusCode})');
    }
  }

  // ===================== PRODUCTS =====================
  Future<List<dynamic>> fetchProducts(String? token) async {
    final url = Uri.parse('$kBaseUrl/api/get_products');
    final resp = await http.get(url, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return (data['results'] as List?) ?? [];
    } else {
      throw Exception('No se pudieron cargar los productos (${resp.statusCode})');
    }
  }

  Future<List<dynamic>> fetchProductRequests(String? token) async {
    final url = Uri.parse('$kBaseUrl/api/get_products_requests/');
    final resp = await http.get(url, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return (data['results'] as List?) ?? [];
    } else {
      throw Exception('No se pudieron cargar las solicitudes (${resp.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchProductDetail(String? token, int productId) async {
    final url = Uri.parse('$kBaseUrl/api/item/?pk=$productId');
    final resp = await http.get(url, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
    print('[PRODUCT_DETAIL] url: $url');
    print('[PRODUCT_DETAIL] status: ${resp.statusCode}');
    print('[PRODUCT_DETAIL] body: ${resp.body}');
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('No se pudo cargar el producto (${resp.statusCode})');
    }
  }

  // ====================== PROFILE =====================
  /// Perfil del usuario logueado
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final url = Uri.parse('$kBaseUrl/api/get_profile/');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    print('[PROFILE] 🔹 STATUS: ${resp.statusCode}');
    print('[PROFILE] 🔹 BODY: ${resp.body}');
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('No se pudo cargar el perfil (${resp.statusCode})');
    }
  }

  /// PERFIL PÚBLICO por id (SIN TOKEN) — usa esto para ver perfiles ajenos
  Future<Map<String, dynamic>> fetchPublicProfileById(int userId) async {
    final url = Uri.parse('$kBaseUrl/api/get_profile/?pk=$userId');
    final resp = await http.get(url); // <- SIN Authorization
    print('[PUBLIC PROFILE BY ID] 🔹 STATUS: ${resp.statusCode}');
    print('[PUBLIC PROFILE BY ID] 🔹 BODY: ${resp.body}');
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('No se pudo cargar el perfil público ($userId) (${resp.statusCode})');
    }
  }

  /// Fallback autenticado por id (el backend ahora ignora pk, pero lo dejamos)
  Future<Map<String, dynamic>> fetchProfileById(String token, int userId) async {
    final url = Uri.parse('$kBaseUrl/api/get_profile/?pk=$userId');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    print('[PROFILE BY ID] 🔹 STATUS: ${resp.statusCode}');
    print('[PROFILE BY ID] 🔹 BODY: ${resp.body}');
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('No se pudo cargar el perfil ($userId) (${resp.statusCode})');
    }
  }

  // ================== CHATS / MESSAGES =================
  Future<List<dynamic>> fetchChats(String? token) async {
    if (token == null) throw Exception('No hay token para cargar los chats');
    final url = Uri.parse('$kBaseUrl/api/chats/');
    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    print('[CHATS] status: ${resp.statusCode}');
    print('[CHATS] body: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return (data['chats'] as List?) ?? [];
    } else {
      throw Exception('Error al cargar los chats (${resp.statusCode})');
    }
  }

  Future<int> createChat(String? token, int receiverId, {int? productId, int? productRequestId}) async {
    if (token == null) throw Exception('No hay token para crear el chat');
    final url = Uri.parse('$kBaseUrl/api/chats/');
    final resp = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'receiver_id': receiverId,
        'product_id': productId,
        'product_request_id': productRequestId,
      }),
    );
    print('[CHATS CREATE] status: ${resp.statusCode}');
    print('[CHATS CREATE] body: ${resp.body}');
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = json.decode(resp.body);
      return data['created'] as int;
    } else {
      throw Exception('Error al crear chat (${resp.statusCode})');
    }
  }

  Future<List<dynamic>> fetchMessages(String? token, int chatId) async {
    if (token == null) throw Exception('No hay token para cargar mensajes');
    final url = Uri.parse('$kBaseUrl/api/messages/?chat_id=$chatId');
    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    print('[MESSAGES] status: ${resp.statusCode}');
    print('[MESSAGES] body: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return (data['messages'] as List?) ?? [];
    } else {
      throw Exception('Error al cargar mensajes (${resp.statusCode})');
    }
  }

  Future<bool> sendMessage(String? token, int chatId, String content) async {
    if (token == null) throw Exception('No hay token para enviar mensajes');
    final url = Uri.parse('$kBaseUrl/api/messages/');
    final resp = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'chat_id': chatId, 'd': content}),
    );
    print('[SEND MESSAGE] status: ${resp.statusCode}');
    print('[SEND MESSAGE] body: ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['sended'] == 'ok';
    } else {
      throw Exception('Error al enviar mensaje (${resp.statusCode})');
    }
  }
}
