import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _username;
  int? _userId;

  // 👇 nuevo
  int _unreadChats = 0;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  int? get userId => _userId;

  // 👇 nuevo
  int get unreadChats => _unreadChats;

  /// Login normal, con parámetros nombrados
  void logIn({
    required String? token,
    String? refreshToken,
    String? username,
    int? userId,
  }) {
    _token = token;
    _refreshToken = refreshToken;
    _username = username;
    _userId = userId;
    notifyListeners();
  }

  /// Login como invitado (sin token)
  void logInAsGuest() {
    _token = null;
    _refreshToken = null;
    _username = 'Invitado';
    _userId = null;
    _unreadChats = 0; // 👈 también lo vaciamos
    notifyListeners();
  }

  void logOut() {
    _token = null;
    _refreshToken = null;
    _username = null;
    _userId = null;
    _unreadChats = 0; // 👈 también lo vaciamos
    notifyListeners();
  }

  // 👇 para que los screens de chats puedan notificar cuántos hay sin leer
  void setUnreadChats(int value) {
    if (value == _unreadChats) return;
    _unreadChats = value;
    notifyListeners();
  }
}
