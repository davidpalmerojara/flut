// lib/core/app_config.dart

// la base buena, la que acabas de pasar
const String kBaseUrl = 'http://192.168.3.76:8000';

/// Une la base con una ruta tipo /media/...
String mediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '$kBaseUrl$path';
}
