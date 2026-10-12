import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/widgets/goora_progress_bar.dart';
import 'package:goora/core/widgets/goora_route_map.dart';
import 'package:goora/core/widgets/goora_stat_tile.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';

import '../helpers/pump_app.dart';

/// 003 core widgets (research R13). Regenerate with
/// `flutter test --update-goldens test/golden` after an intended visual change.
void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    testWidgets('daily widgets [$dir]', (tester) async {
      await loadAppFonts();
      tester.view.physicalSize = const Size(390, 700);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: GooraStatTile(label: l.returnTime, value: l.timePm('5:00'))),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: GooraStatTile(label: l.payPerTrip, value: l.egpAmount(44), caption: l.priceWithFee(40, 4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      GooraProgressBar(value: 0.96, valueLabel: '96%', label: l.reliability),
                      const SizedBox(height: AppSpacing.gap),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          GooraStatusChip(status: GooraStatus.covered, label: l.covered),
                          GooraStatusChip(status: GooraStatus.waiting, label: l.stWaiting('4:12')),
                          GooraStatusChip(status: GooraStatus.pickedUp, label: l.pickedUp),
                          GooraStatusChip(status: GooraStatus.noShow, label: l.stNoShow),
                          GooraStatusChip(status: GooraStatus.backup, label: l.backupName('Mohamed')),
                          GooraStatusChip(status: GooraStatus.off, label: l.youOff),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      GooraRouteMap(
                        fromLabel: l.areaSheikhZayed,
                        toLabel: l.areaSmartVillage,
                        semanticLabel: l.mapAria,
                        driverProgress: 0.4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/daily_widgets_$dir.png'));
    });
  }
}
