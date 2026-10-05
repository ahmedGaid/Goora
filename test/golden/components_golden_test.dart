import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_colors.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/widgets/goora_avatar.dart';
import 'package:goora/core/widgets/goora_banner.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';
import 'package:goora/core/widgets/goora_card.dart';
import 'package:goora/core/widgets/goora_dashed_button.dart';
import 'package:goora/core/widgets/goora_ghost_button.dart';
import 'package:goora/core/widgets/goora_icons.dart';
import 'package:goora/core/widgets/goora_logo.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/core/widgets/goora_primary_button.dart';
import 'package:goora/core/widgets/goora_progress_dots.dart';
import 'package:goora/core/widgets/goora_radio_card.dart';
import 'package:goora/core/widgets/goora_stepper.dart';
import 'package:goora/core/widgets/goora_timeline_row.dart';
import 'package:goora/core/widgets/language_pill.dart';

import '../helpers/pump_app.dart';

/// Goldens are rendered on the developer machine (Windows); regenerate with
/// `flutter test --update-goldens test/golden` after an intended visual change.
void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    Future<void> sheet(WidgetTester tester, String name, Widget Function(AppLocalizations) build) async {
      await loadAppFonts();
      tester.view.physicalSize = const Size(390, 900);
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
            builder: (context) => Scaffold(
              body: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
                child: build(AppLocalizations.of(context)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/${name}_$dir.png'));
    }

    testWidgets('buttons + logo [$dir]', (tester) async {
      await sheet(tester, 'buttons', (l) => Column(
            children: [
              Container(
                color: AppColors.forest,
                padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GooraLogo(),
                    const SizedBox(height: AppSpacing.gap),
                    GooraPrimaryButton(
                      label: l.getStarted,
                      trailingArrow: true,
                      variant: GooraPrimaryVariant.onDark,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GooraPrimaryButton(label: l.login, variant: GooraPrimaryVariant.outlineOnDark, onPressed: () {}),
                    const SizedBox(height: AppSpacing.md),
                    LanguagePill(label: l.langBtn, semanticLabel: l.langAria, labelFontFamily: 'Cairo', onDark: true, onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.gap),
              GooraPrimaryButton(label: l.continueBtn, trailingArrow: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraPrimaryButton(label: l.continueBtn, onPressed: null),
              const SizedBox(height: AppSpacing.md),
              GooraGhostButton(label: l.join, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraGhostButton(label: l.cantCome, danger: true, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraDashedButton(label: l.postReq, onPressed: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraStepper(valueLabel: l.stepperValue('40'), decreaseLabel: l.galleryDecrease, increaseLabel: l.galleryIncrease, onIncrease: () {}),
            ],
          ));
    });

    testWidgets('selection + cards [$dir]', (tester) async {
      await sheet(tester, 'selection', (l) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GooraProgressDots(count: 3, current: 1, semanticLabel: ''),
              const SizedBox(height: AppSpacing.gap),
              Wrap(spacing: AppSpacing.sm, children: [
                GooraPill(label: l.dirBoth, selected: true, onTap: () {}),
                GooraPill(label: l.dirGoing, selected: false, onTap: () {}),
                GooraChip(label: l.matchPercent(92)),
              ]),
              const SizedBox(height: AppSpacing.gap),
              GooraRadioCard(icon: GooraIcons.calendar, title: l.fRegular, chipLabel: l.fTag, subtitle: l.fRegRider, selected: true, onTap: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraRadioCard(icon: GooraIcons.route, title: l.fOnce, subtitle: l.fOnceRider, selected: false, onTap: () {}),
              const SizedBox(height: AppSpacing.gap),
              GooraCard.rows(rows: [Text(l.confirmed), Text(l.covered)]),
              const SizedBox(height: AppSpacing.md),
              GooraHeroCard(child: Text(l.pickupIn)),
            ],
          ));
    });

    testWidgets('feedback + people + nav [$dir]', (tester) async {
      await sheet(tester, 'feedback', (l) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GooraBanner(kind: GooraBannerKind.warning, title: l.backupTitle, body: l.backupBody, actionLabel: l.gotIt, onAction: () {}),
              const SizedBox(height: AppSpacing.md),
              GooraBanner(kind: GooraBannerKind.info, title: l.extraTrip, body: l.subNote),
              const SizedBox(height: AppSpacing.gap),
              const GooraAvatarStack(avatars: [
                GooraAvatar(initials: 'AM', ring: true, highlight: true),
                GooraAvatar(initials: 'MH', ring: true, paletteIndex: 1),
                GooraAvatar(initials: 'SR', ring: true, paletteIndex: 2),
              ]),
              const SizedBox(height: AppSpacing.gap),
              GooraTimelineRow(kind: GooraTimelineKind.pickup, title: l.arrivedBtn, subtitle: l.pickupIn),
              GooraTimelineRow(kind: GooraTimelineKind.transit, title: l.covered),
              GooraTimelineRow(kind: GooraTimelineKind.arrival, title: l.confirmed),
              const Spacer(),
              GooraBottomNav(
                semanticLabel: l.navMain,
                currentIndex: 0,
                onTap: (_) {},
                items: [
                  GooraNavItem(icon: GooraIcons.today, label: l.tabToday),
                  GooraNavItem(icon: GooraIcons.week, label: l.tabWeek),
                  GooraNavItem(icon: GooraIcons.wallet, label: l.tabWallet),
                  GooraNavItem(icon: GooraIcons.trust, label: l.tabTrust),
                ],
              ),
            ],
          ));
    });
  }
}
