import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';

/// 010 T020 (part): the inbox copy for the company plan notices, in both
/// locales. The notice kinds themselves land with P4: their labels switch
/// lives in daily/presentation (research "Lane A notes").
void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    test('[${locale.languageCode}] company plan notices name the company and the days, never an amount', () {
      final l = lookupAppLocalizations(locale);
      expect(l.nCompanyPlanStarted('Valeo'), contains('Valeo'));
      expect(l.nCompanyPlanEnded('Valeo'), contains('Valeo'));
      expect(l.nPersonalPlanBack(10), contains('10'));
      for (final line in [l.nCompanyPlanPaused, l.nCompanyPlanResumed]) {
        expect(line, isNotEmpty);
        expect(RegExp(r'\d').hasMatch(line), isFalse, reason: 'neutral, no amounts (Q10): $line');
      }
    });
  }
}
