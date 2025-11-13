import 'package:flutter/foundation.dart';

class LanguageState extends ChangeNotifier {
  // 'es' por defecto
  String _lang = 'es';

  String get lang => _lang;

  void setLang(String value) {
    if (value == _lang) return;
    _lang = value;
    notifyListeners();
  }

  bool get isSpanish => _lang == 'es';
  bool get isCatalan => _lang == 'ca';
}
