// lib/features/auth/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:wallapop/data/services/auth_service.dart';
import 'package:wallapop/state/auth_state.dart';
import 'package:wallapop/state/language_state.dart';

class LoginScreen extends StatefulWidget {
  final AuthState auth;
  final LanguageState lang;

  const LoginScreen({
    super.key,
    required this.auth,
    required this.lang,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────
  // decodifica el JWT y saca el payload
  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];

      // base64 url → base64 normal
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }

      final decoded = utf8.decode(base64.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  // ───────────────────────────────

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await const AuthService().login(
        _userCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      debugPrint('========== LOGIN RESPONSE ==========');
      debugPrint(data.toString());
      debugPrint('====================================');

      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;

      int? userId;

      // 1) primero intentamos sacarlo del propio json (por si algún día lo mandas)
      if (data['user_id'] != null) {
        userId = int.tryParse(data['user_id'].toString());
      }

      // 2) si no viene, lo sacamos del JWT de access
      if (userId == null && access != null) {
        final payload = _decodeJwt(access);
        debugPrint('🔍 JWT payload: $payload');
        final raw = payload?['user_id'];
        if (raw != null) {
          userId = int.tryParse(raw.toString());
        }
      }

      debugPrint('🔐 access: $access');
      debugPrint('👤 resolved userId (from JWT): $userId');

      widget.auth.logIn(
        token: access,
        refreshToken: refresh,
        username: _userCtrl.text.trim(),
        userId: userId,
      );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = 'Credenciales no válidas';
      });
      debugPrint('❌ LOGIN ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isES = widget.lang.lang == 'es';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(isES ? 'Entrar' : 'Entrar'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.lock_open_rounded,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isES ? 'Bienvenido de nuevo' : 'Benvingut de nou',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isES
                            ? 'Inicia sesión para continuar'
                            : 'Inicia sessió per continuar',
                        style: TextStyle(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _userCtrl,
                              decoration: InputDecoration(
                                labelText: isES ? 'Usuario' : 'Usuari',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: InputDecoration(
                                labelText:
                                isES ? 'Contraseña' : 'Contrasenya',
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            if (_error != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: cs.error),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _loading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _doLogin,
                                child: Text(isES ? 'Entrar' : 'Entrar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      widget.auth.logInAsGuest();
                      context.go('/dashboard');
                    },
                    icon: const Icon(Icons.person_off_outlined),
                    label: Text(
                      isES
                          ? 'Entrar como invitado'
                          : 'Entrar com a convidat',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
