import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/widgets/goora_balance_card.dart';

import '../helpers/pump_app.dart';

/// 004 core widgets (T017). Regenerate with
/// `flutter test --update-goldens test/golden` after an intended visual change.
void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    testWidgets('wallet widgets [$dir]', (tester) async {
      await loadAppFonts();
      tester.view.physicalSize = const Size(390, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(locale),
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
                  child: GooraBalanceCard(
                    balanceLabel: l.balanceLabel,
                    balanceValue: l.egpAmount(320),
                    tripsCaption: l.coversTrips(4),
                    topUpLabel: l.topUp,
                    onTopUp: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/wallet_widgets_$dir.png'));
    });
  }
}
