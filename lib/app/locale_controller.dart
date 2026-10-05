import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/storage/preferences.dart';

part 'locale_controller.g.dart';

/// Arabic is the default; the device locale is ignored (constitution III).
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  static const storageKey = 'locale';
  static const arabic = Locale('ar');
  static const english = Locale('en');
  static const supported = [arabic, english];

  @override
  Locale build() {
    final stored = ref.read(sharedPreferencesProvider).getString(storageKey);
    return stored == english.languageCode ? english : arabic;
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(storageKey, locale.languageCode);
  }

  Future<void> toggle() => set(state == arabic ? english : arabic);
}
