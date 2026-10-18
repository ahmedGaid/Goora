import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_screen.dart';
import 'package:goora/features/marketplace/presentation/offer_trip/offer_trip_screen.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 (T100): the marketplace screens meet the tap-target and label
/// guidelines at normal and 1.3× text, in both languages. Book seat, Accept,
/// Publish and Post are the buttons every flow hangs on.
final _evening = at(rideTuesday, 20, 0);

Session _session(Role role) => Session(
      phone: testPhone,
      profile: Profile(
        phone: testPhone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: role,
        frequency: Frequency.once,
      ),
    );

Future<void> _pump(WidgetTester tester, Widget screen, Role role, String locale, double scale) async {
  final c = await pumpScreen(
    tester,
    screen,
    locale: Locale(locale),
    session: _session(role),
    prefs: memberPrefs(role: role, member: false, locale: locale, method: PaymentMethod.instapay, pastTrial: true),
    overrides: dailyOverrides(TestClock(_evening)),
    textScale: scale,
  );
  await c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: 200);
  tester.view.physicalSize = const Size(390, 6000);
  await tester.pumpAndSettle();
}

Future<void> _guidelines(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  // The house floor is 44 px (Constitution VII, AppSizes.minTouch); Android's 48 is stricter.
  await expectLater(tester, meetsGuideline(const MinimumTapTargetGuideline(size: Size(44, 44), link: 'https://goora.app/a11y/tap-targets')));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  for (final locale in locales) {
    final code = locale.languageCode;
    for (final scale in [1.0, 1.3]) {
      final tag = '[$code ×$scale]';

      testWidgets('$tag Empty seats', (tester) async {
        await _pump(tester, const EmptySeatsScreen(), Role.rider, code, scale);
        await _guidelines(tester);
      });

      testWidgets('$tag Offer a trip', (tester) async {
        await _pump(tester, const OfferTripScreen(), Role.driver, code, scale);
        await _guidelines(tester);
        expect(find.byKey(const Key('publish')), findsOneWidget);
      });

      testWidgets('$tag Post your trip', (tester) async {
        await _pump(tester, const PostTripScreen(), Role.rider, code, scale);
        await _guidelines(tester);
        expect(find.byKey(const Key('post')), findsOneWidget);
      });

      testWidgets('$tag Find riders', (tester) async {
        await _pump(tester, const FindRidersScreen(), Role.driver, code, scale);
        await _guidelines(tester);
        expect(find.byKey(const Key('accept-rq-seed-m02')), findsOneWidget);
      });
    }
  }
}
