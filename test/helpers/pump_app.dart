import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/goora_app.dart';
import 'package:goora/app/locale_controller.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/main.dart' show loadSession;
import 'package:shared_preferences/shared_preferences.dart';

const ar = Locale('ar');
const en = Locale('en');
const locales = [ar, en];

bool _fontsLoaded = false;

/// Loads every font in the asset manifest (Cairo, Plus Jakarta Sans, Lucide)
/// so goldens and layout use the real glyphs instead of the test font.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

void usePhoneSize(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<SharedPreferences> testPrefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues({LocaleController.storageKey: 'ar', ...values});
  return SharedPreferences.getInstance();
}

/// Pumps a single screen in [locale] with the real theme and l10n.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Locale locale = ar,
  Map<String, Object> prefs = const {},
  Session session = const Session(),
  List<Override> overrides = const [],
  double textScale = 1,
}) async {
  await loadAppFonts();
  usePhoneSize(tester, textScale: textScale);
  final p = await testPrefs({LocaleController.storageKey: locale.languageCode, ...prefs});
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      initialSessionProvider.overrideWithValue(session),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(localeControllerProvider);
          return MaterialApp(
            locale: current,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.light(current),
            home: screen,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Pumps the whole app (router + resume) the way `main()` does.
Future<ProviderContainer> pumpGooraApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  await loadAppFonts();
  usePhoneSize(tester);
  final p = await testPrefs(prefs);
  final session = await loadSession(p);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      initialSessionProvider.overrideWithValue(session),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const GooraApp()));
  await tester.pumpAndSettle();
  return container;
}

AppLocalizations l10nFor(Locale locale) => lookupAppLocalizations(locale);

TextDirection directionOf(WidgetTester tester, Finder finder) =>
    Directionality.of(tester.element(finder));
