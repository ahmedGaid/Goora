import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_avatar.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_controller.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US4: Find riders (D), ar + en. A verified driver with no group, on
/// Tuesday 20:00; the corridor's 12 morning requests are for tomorrow.
final _tue = rideTuesday;

Session _driver() => Session(
      phone: testPhone,
      profile: Profile(
        phone: testPhone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: Role.driver,
        frequency: Frequency.once,
      ),
    );

Future<ProviderContainer> _open(WidgetTester tester, String locale, {List<Override> overrides = const []}) async {
  final c = await pumpScreen(
    tester,
    const FindRidersScreen(),
    locale: Locale(locale),
    session: _driver(),
    prefs: memberPrefs(role: Role.driver, member: false, locale: locale),
    overrides: [...dailyOverrides(TestClock(at(_tue, 20, 0))), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 6000);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] filters, trips left and the 12 morning requests', (tester) async {
      await _open(tester, code);
      expect(find.text(l.browseTitle), findsWidgets);
      expect(find.text(l.leavingFrom), findsOneWidget);
      expect(find.text(l.allAreas), findsOneWidget);
      expect(find.text(l.morning), findsOneWidget);
      expect(find.text(l.evening), findsOneWidget);
      expect(find.text('${l.tripsLeftA} · 2'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'request-rq-seed-")), findsNWidgets(12));
      expect(find.text(l.privacyCaption), findsOneWidget);
    });

    testWidgets('[$code] a card: route, verified rider, rating, pickup, time, once/daily, fixed price, detour', (tester) async {
      await _open(tester, code);
      await _tap(tester, find.byKey(const Key('area-sheikhZayed')));
      final card = find.byKey(const Key('request-rq-seed-m01'));
      expect(card, findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(l.verifiedRiderWoman)), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(l.ratingStars('4.9'))), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(l.routeLine(l.areaSheikhZayed, l.areaSmartVillage))), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining(l.everyWorkday)), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining(l.detourMin(3))), findsOneWidget);
      expect(find.byKey(const Key('request-price-rq-seed-m01')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('request-rq-seed-m03')), matching: find.text(l.newRider)), findsOneWidget);
    });

    testWidgets('[$code] SC-004: no name, no avatar and no price field before departure', (tester) async {
      await _open(tester, code);
      for (final rider in MarketSeed.riders) {
        expect(find.textContaining(rider.firstName), findsNothing);
      }
      expect(find.byType(GooraAvatar), findsNothing);
      expect(find.byType(TextField), findsNothing, reason: 'the price is Goora\'s (FR-022)');
    });

    testWidgets('[$code] Leaving from October shows fewer; All shows every one', (tester) async {
      await _open(tester, code);
      await _tap(tester, find.byKey(const Key('area-october')));
      final october = find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'request-rq-seed-")).evaluate().length;
      expect(october, inInclusiveRange(1, 11));
      await _tap(tester, find.byKey(const Key('area-all')));
      expect(find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'request-rq-seed-")), findsNWidgets(12));
    });

    testWidgets('[$code] create asks first: "This creates your trip", then Accepted ✓ and one trip left', (tester) async {
      await _open(tester, code);
      await _tap(tester, find.byKey(const Key('accept-rq-seed-m02')));
      expect(
        find.text(l.createsTrip(l.routeLine(l.areaSheikhZayed, l.areaSmartVillage), l.timeAm('7:05'), 1)),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const Key('confirm-accept-rq-seed-m02')));
      expect(find.byKey(const Key('accepted-rq-seed-m02')), findsOneWidget);
      expect(find.text(l.accepted), findsOneWidget);
      expect(find.text('${l.tripsLeftA} · 1'), findsOneWidget);
      expect(find.byKey(const Key('request-rq-seed-m02')), findsOneWidget, reason: 'it stays on screen as Accepted');
    });

    testWidgets('[$code] a request within 30 minutes joins the trip: said before the tap, no trip used', (tester) async {
      await _open(tester, code);
      await _tap(tester, find.byKey(const Key('accept-rq-seed-m02')));
      await _tap(tester, find.byKey(const Key('confirm-accept-rq-seed-m02')));
      expect(find.text(l.joinsTripInstead(l.timeAm('7:05'))), findsWidgets);
      await _tap(tester, find.byKey(const Key('accept-rq-seed-m03')));
      expect(find.byKey(const Key('accepted-rq-seed-m03')), findsOneWidget);
      expect(find.text('${l.tripsLeftA} · 1'), findsOneWidget);
    });

    testWidgets('[$code] a full car and the daily limit are words, never an Accept button', (tester) async {
      await _open(tester, code);
      for (final id in ['m02', 'm03', 'm05']) {
        await _tap(tester, find.byKey(Key('accept-rq-seed-$id')));
        if (id == 'm02') await _tap(tester, find.byKey(const Key('confirm-accept-rq-seed-m02')));
      }
      expect(find.byKey(const Key('blocked-rq-seed-m06')), findsOneWidget);
      expect(find.text(l.yourCarFull), findsWidgets);
      expect(find.byKey(const Key('accept-rq-seed-m06')), findsNothing);

      // The way back is the second trip; after it, a request far from 7:05 is over the limit.
      await _tap(tester, find.byKey(const Key('part-evening')));
      await _tap(tester, find.byKey(const Key('accept-rq-seed-e01')));
      await _tap(tester, find.byKey(const Key('confirm-accept-rq-seed-e01')));
      await _tap(tester, find.byKey(const Key('part-morning')));
      expect(find.text(l.dailyLimitReached), findsWidgets);
      expect(find.byKey(const Key('accept-rq-seed-m09')), findsNothing);
      expect(find.text('${l.tripsLeftA} · 0'), findsOneWidget);
    });

    testWidgets('[$code] empty: a calm message with the privacy caption', (tester) async {
      await _open(
        tester,
        code,
        overrides: [requestCardsProvider(null, PartOfDay.morning).overrideWith((ref) async => const [])],
      );
      expect(find.byKey(const Key('requests-empty')), findsOneWidget);
      expect(find.text(l.noRequests), findsOneWidget);
      expect(find.text(l.privacyCaption), findsOneWidget);
    });

    testWidgets('[$code] error: a calm message with a retry', (tester) async {
      await _open(
        tester,
        code,
        overrides: [
          requestCardsProvider(null, PartOfDay.morning).overrideWith((ref) => Future<List<RequestCard>>.error('boom')),
        ],
      );
      expect(find.byKey(const Key('requests-error')), findsOneWidget);
      expect(find.text(l.todayError), findsOneWidget);
      expect(find.byKey(const Key('requests-retry')), findsOneWidget);
    });

    testWidgets('[$code] loading is a spinner, not a blank screen', (tester) async {
      final never = Completer<List<RequestCard>>();
      try {
        await _open(
          tester,
          code,
          overrides: [requestCardsProvider(null, PartOfDay.morning).overrideWith((ref) => never.future)],
        );
      } catch (_) {
        // The spinner never stops, so pumpAndSettle times out.
      }
      await tester.pump();
      expect(find.byKey(const Key('requests-loading')), findsOneWidget);
    });
  }
}
