import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/presentation/trust/id_check_screen.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 009: a new rider's ID is checked at their first Book — the seat is held
/// until it passes — and onboarding never asks for it.
final _monday = at(rideTuesday.addDays(-1), 20, 0);

final _bookButton = find.byWidgetPredicate(
  (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('book-'),
);

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] Book → the ID check first; nothing booked; after it, Book works', (tester) async {
      final clock = TestClock(_monday);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(
          role: Role.rider,
          member: false,
          locale: code,
          withPlan: false,
          method: PaymentMethod.cash,
          idVerified: false,
        ),
        overrides: dailyOverrides(clock),
      );
      tester.view.physicalSize = const Size(390, 2400);
      c.read(routerProvider).go(Routes.emptySeatsOn(Leg.going));
      await tester.pumpAndSettle();

      await tester.tap(_bookButton.first);
      await tester.pumpAndSettle();
      expect(find.byType(IdCheckScreen), findsOneWidget);
      expect(find.text(l.idCheckSub), findsOneWidget);
      expect(await c.read(marketplaceRepositoryProvider).myBookings(now: clock.now), isEmpty);

      final submit = find.byKey(const Key('id-submit'));
      await tester.tap(find.byKey(const Key('id-front')));
      await tester.pumpAndSettle();
      expect(tester.widget<ButtonStyleButton>(find.descendant(of: submit, matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))).onPressed,
          isNull, reason: 'both sides first (FR-003)');
      await tester.tap(find.byKey(const Key('id-back')));
      await tester.pumpAndSettle();
      expect(find.text(l.idCaptured), findsNWidgets(2));
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.byType(EmptySeatsScreen), findsOneWidget, reason: 'back where they were');
      expect(await c.read(marketplaceRepositoryProvider).myBookings(now: clock.now), isEmpty,
          reason: 'nothing booked behind their back (FR-004)');
      await tester.tap(_bookButton.first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booked-view')), findsOneWidget);
      final mine = await c.read(marketplaceRepositoryProvider).myBookings(now: clock.now);
      expect(mine.single.riderId, DailySeed.meId);
    });
  }
}
