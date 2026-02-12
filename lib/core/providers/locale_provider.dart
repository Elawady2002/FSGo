import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar', 'EG')) {
    _loadLocale();
  }

  static const _storage = FlutterSecureStorage();
  static const _key = 'selected_locale';

  Future<void> _loadLocale() async {
    final languageCode = await _storage.read(key: _key);
    if (languageCode != null) {
      state = Locale(languageCode, languageCode == 'ar' ? 'EG' : null);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _key, value: locale.languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == 'ar') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar', 'EG'));
    }
  }
}
