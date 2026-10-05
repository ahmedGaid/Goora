import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'locale_controller.dart';
import 'router.dart';

class GooraApp extends ConsumerWidget {
  const GooraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).tagline,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
