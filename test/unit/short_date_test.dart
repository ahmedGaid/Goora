import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

/// Walk nit N-7: "Subscribed until 3/1" read as 1 March to many readers. A
/// wallet date is now the day and the month's name, Western digits in both
/// locales (goora-brand), so no day/month order can be misread.
void main() {
  const arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر', //
  ];
  const enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  for (final (locale, months) in [(const Locale('ar'), arMonths), (const Locale('en'), enMonths)]) {
    final code = locale.languageCode;

    test('[$code] shortDate is the day and the month name, all 12 months', () {
      final l = lookupAppLocalizations(locale);
      for (var m = 1; m <= 12; m++) {
        expect(l.shortDate(CalendarDate(2026, m, 3)), '3 ${months[m - 1]}');
      }
    });

    test('[$code] shortDate has no slash, so "3/1" cannot be misread', () {
      final l = lookupAppLocalizations(locale);
      expect(l.shortDate(CalendarDate(2026, 1, 3)), isNot(contains('/')));
      expect(l.shortDate(CalendarDate(2026, 12, 6)), isNot(contains('/')));
    });

    test('[$code] shortDate keeps Western digits and a two-digit day', () {
      final l = lookupAppLocalizations(locale);
      expect(l.shortDate(CalendarDate(2026, 10, 29)), startsWith('29 '));
      expect(RegExp(r'[٠-٩]').hasMatch(l.shortDate(CalendarDate(2026, 10, 29))), isFalse);
    });

    test('[$code] shortDateYear stays numeric d/m/yyyy for the company screens', () {
      final l = lookupAppLocalizations(locale);
      expect(l.shortDateYear(CalendarDate(2026, 9, 1)), '1/9/2026');
    });
  }
}
