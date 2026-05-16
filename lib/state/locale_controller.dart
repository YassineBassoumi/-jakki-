import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_storage.dart';
import 'storage_controller.dart';

/// Supported UI locales. Order is the order shown in the picker.
const List<Locale> kSupportedLocales = <Locale>[
  Locale('en'),
  Locale('fr'),
  Locale('ar'),
];

/// Current UI locale, persisted via [GameStorage].
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final GameStorage? storage = ref.read(gameStorageProvider);
    final String? code = storage?.loadLocale();
    if (code != null) {
      for (final Locale l in kSupportedLocales) {
        if (l.languageCode == code) return l;
      }
    }
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    final GameStorage? storage = ref.read(gameStorageProvider);
    storage?.saveLocale(locale.languageCode);
  }
}

final NotifierProvider<LocaleController, Locale> localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
