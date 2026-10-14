import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_controller.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/wallet_repository.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US3: Post your trip (B), ar + en. A once rider with a wallet, on
/// Tuesday 20:00 — 7:30 AM resolves to tomorrow.
final _tue = rideTuesday;
final _wed = rideTuesday.addDays(1);

Session _rider() => Session(
      phone: testPhone,
      profile: Profile(
        phone: testPhone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: Role.rider,
        frequency: Frequency.once,
      ),
    );

final class _Open {
  const _Open(this.c, this.clock);

  final ProviderContainer c;
  final TestClock clock;
}

Future<_Open> _open(
  WidgetTester tester,
  String locale, {
  String? id,
  bool member = false,
  int balance = 0,
  List<Override> overrides = const [],
}) async {
  final clock = TestClock(at(_tue, 20, 0));
  final c = await pumpScreen(
    tester,
    PostTripScreen(id: id),
    locale: Locale(locale),
    session: _rider(),
    prefs: memberPrefs(role: Role.rider, member: member, locale: locale, method: PaymentMethod.wallet),
    overrides: [...dailyOverrides(clock), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2800);
  if (balance > 0) await c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: balance);
  await tester.pumpAndSettle();
  return _Open(c, clock);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _refresh(WidgetTester tester, ProviderContainer c) async {
  c
    ..invalidate(postedRequestProvider)
    ..invalidate(sentToProvider);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    group('[$code] form', () {
      testWidgets('starts from the rider\'s route with one fixed price and the three rules', (tester) async {
        await _open(tester, code, balance: 100);
        expect(find.text(l.postReq), findsWidgets);
        expect(tester.widget<GooraPill>(find.byKey(const Key('from-sheikhZayed'))).selected, isTrue);
        expect(tester.widget<GooraPill>(find.byKey(const Key('to-smartVillage'))).selected, isTrue);
        expect(find.text(l.priceWithFee(40, 4)), findsOneWidget);
        expect(find.text(l.ruleNoBidding), findsOneWidget);
        expect(find.text(l.ruleCostShare), findsOneWidget);
        expect(find.text(l.ruleRoute), findsOneWidget);
        expect(find.byType(TextField), findsNothing, reason: 'no price field (FR-022)');
        expect(find.byKey(const Key('post')), findsOneWidget);
      });

      testWidgets('a rider in a daily group has Every workday off, with the reason in words', (tester) async {
        await _open(tester, code, member: true, balance: 100);
        expect(tester.widget<GooraPill>(find.byKey(const Key('repeat-daily'))).onTap, isNull);
        expect(find.text(l.dailyNeedsNoGroup), findsOneWidget);
        expect(tester.widget<GooraPill>(find.byKey(const Key('repeat-once'))).selected, isTrue);
      });

      testWidgets('an empty wallet gets the top-up gate, and nothing is posted', (tester) async {
        final o = await _open(tester, code);
        await _tap(tester, find.byKey(const Key('post')));
        expect(find.byKey(const Key('notice-top-up')), findsOneWidget);
        expect(find.text(l.topUpFirst(44)), findsOneWidget);
        expect(find.byKey(const Key('request-posted')), findsNothing);
        expect(await o.c.read(marketplaceRepositoryProvider).myRequests(now: o.clock.now), isEmpty);
      });
    });

    group('[$code] posted', () {
      testWidgets('Sent to N drivers, waiting, Cancel request — and nothing charged', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        expect(find.byKey(const Key('request-posted')), findsOneWidget);
        expect(find.text(l.sentToDrivers(4)), findsOneWidget);
        expect(find.text(l.waitingDriver), findsOneWidget);
        expect(find.byKey(const Key('cancel-request')), findsOneWidget);
        final wallet = await o.c.read(walletRepositoryProvider).getWallet(DailySeed.meId);
        expect(wallet.balance, 100);
      });

      testWidgets('accepted (once): the driver, pickup, time and price line', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-accepted')), findsOneWidget);
        expect(find.text(l.requestAccepted), findsOneWidget);
        expect(find.text('Tarek'), findsOneWidget);
        expect(find.text('${l.heroTomorrow} · ${l.timeAm('7:30')}'), findsOneWidget);
        expect(find.text(l.priceWithFee(40, 4)), findsOneWidget);
        expect(find.byKey(const Key('now-group')), findsNothing);
        expect(find.text(l.backToToday), findsOneWidget);
      });

      testWidgets('accepted (daily): "You\'re now a commute group" and Continue', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('repeat-daily')));
        await _tap(tester, find.byKey(const Key('post')));
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.text(l.nowGroup), findsOneWidget);
        expect(find.text(l.continueBtn), findsOneWidget);
      });

      testWidgets('expired: nothing was charged, with Post again and See empty seats', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        o.clock.now = at(_wed, 7, 30);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-expired')), findsOneWidget);
        expect(find.text(l.requestExpired), findsOneWidget);
        expect(find.byKey(const Key('see-empty-seats')), findsOneWidget);
        expect((await o.c.read(walletRepositoryProvider).getWallet(DailySeed.meId)).balance, 100);

        await _tap(tester, find.byKey(const Key('post-again')));
        expect(find.byKey(const Key('post')), findsOneWidget, reason: 'back on the form');
      });

      testWidgets('withdrawn: the balance fell before accept — top up, nothing charged', (tester) async {
        final o = await _open(tester, code, balance: 44);
        await _tap(tester, find.byKey(const Key('post')));
        // Spend the 44 elsewhere so the gate fails at accept.
        final ledger = o.c.read(walletRepositoryProvider) as SeatLedger;
        await ledger.debitSeat(DailySeed.meId, bookingId: 'bk-x', rideId: 'offer:x', total: 44, fee: 4, date: _wed);
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-withdrawn')), findsOneWidget);
        expect(find.text(l.requestWithdrawn), findsOneWidget);
        expect((await o.c.read(walletRepositoryProvider).getWallet(DailySeed.meId)).balance, 0);
      });

      testWidgets('loading is a spinner, not a blank screen (FR-027)', (tester) async {
        final never = Completer<TripRequest?>();
        try {
          await pumpScreen(
            tester,
            const PostTripScreen(id: 'rq-1'),
            locale: Locale(code),
            session: _rider(),
            prefs: memberPrefs(role: Role.rider, member: false, locale: code, method: PaymentMethod.wallet),
            overrides: [postedRequestProvider('rq-1').overrideWith((ref) => never.future)],
          );
        } catch (_) {
          // The spinner never stops, so the helper's pumpAndSettle times out.
        }
        await tester.pump();
        expect(find.byKey(const Key('posted-loading')), findsOneWidget);
      });

      testWidgets('an error is a calm message with a retry (FR-027)', (tester) async {
        await pumpScreen(
          tester,
          const PostTripScreen(id: 'rq-1'),
          locale: Locale(code),
          session: _rider(),
          prefs: memberPrefs(role: Role.rider, member: false, locale: code, method: PaymentMethod.wallet),
          overrides: [postedRequestProvider('rq-1').overrideWith((ref) => Future<TripRequest?>.error('boom'))],
        );
        expect(find.byKey(const Key('posted-error')), findsOneWidget);
        expect(find.text(l.todayError), findsOneWidget);
        expect(find.byKey(const Key('posted-retry')), findsOneWidget);
      });
    });
  }
}
