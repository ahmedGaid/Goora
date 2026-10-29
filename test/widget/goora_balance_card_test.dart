import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/widgets/goora_balance_card.dart';

import '../helpers/pump_app.dart';

/// Walk nit N-5: in "0 ج" the unit sat lower than the digit, because the
/// Arabic ج hangs below the baseline at the 38 px display size. The unit is
/// now a smaller run inside the same line, so it shares the number's
/// baseline and its descender no longer reads as a drop.
void main() {
  for (final locale in locales) {
    testWidgets('balance unit is a smaller run on the number\'s line [${locale.languageCode}]', (tester) async {
      await loadAppFonts();
      usePhoneSize(tester);
      late String value;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(locale),
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              value = l.egpAmount(1490);
              return Scaffold(
                body: GooraBalanceCard(
                  balanceLabel: l.balanceLabel,
                  balanceValue: value,
                  tripsCaption: l.coversTrips(4),
                  topUpLabel: l.topUp,
                  onTopUp: () {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final balance = tester.widget<Text>(find.byWidgetPredicate(
        (w) => w is Text && w.textSpan != null && w.textSpan!.toPlainText() == value,
      ));
      final line = balance.textSpan! as TextSpan;
      final runs = line.children!.cast<TextSpan>();
      expect(runs.map((r) => r.text).join(), value, reason: 'same words, same order');
      expect(runs, hasLength(2));

      final numberSize = line.style!.fontSize!;
      final unitSize = runs.last.style!.fontSize!;
      expect(unitSize, lessThan(numberSize), reason: 'unit is smaller than the digits');
      expect(runs.last.text!.trim(), isNot(contains(RegExp(r'\d'))), reason: 'the unit run holds no digits');
      expect(runs.first.text, '1490');
    });
  }

  testWidgets('a value with no space stays one run', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GooraBalanceCard(
            balanceLabel: 'Balance',
            balanceValue: '0',
            tripsCaption: '',
            topUpLabel: 'Top up',
            onTopUp: () {},
          ),
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);
  });
}
