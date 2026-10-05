import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/language_pill.dart';
import 'locale_controller.dart';

/// The language pill wired to the persisted locale.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    return LanguagePill(
      label: l10n.langBtn,
      semanticLabel: l10n.langAria,
      labelFontFamily: AppTypography.otherFamilyFor(current.languageCode),
      onDark: onDark,
      onTap: () => ref.read(localeControllerProvider.notifier).toggle(),
    );
  }
}
