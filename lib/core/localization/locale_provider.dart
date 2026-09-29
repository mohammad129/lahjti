import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the current application locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  // Arabic default for Lahjti
  LocaleNotifier([super.initialLocale = const Locale('ar')]);

  void setLocale(Locale newLocale) {
    if (state != newLocale) {
      state = newLocale;
    }
  }

  void toggleLocale() {
    state =
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
  }

  bool get isArabic => state.languageCode == 'ar';
}
