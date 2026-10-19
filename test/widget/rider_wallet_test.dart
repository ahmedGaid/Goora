import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/presentation/plan/plan_screen.dart';
import 'package:goora/features/wallet/presentation/wallet/wallet_controller.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// v2 US2 (fees) + US4 (cash trial) on the rider Wallet tab.

/// Group sz-0725 rides Sun–Thu from Sun 4 Oct 2026.
final _rideDays = [
  for (var d = CalendarDate(2026, 10, 4); !d.isAfter(CalendarDate(2026, 10, 29)); d = d.addDays(1))
    if (d.weekday.index <= 4) d,
];

/// [n] completed trips as 003 records them (settled `kept` events), oldest
/// first, both legs of each ride day.
Map<String, Object> _trips(int n) => {
      FakeDailyCommuteRepository.eventsKey: jsonEncode([
        for (final id in [for (var i = 0; i < n; i++) _tripId(i)])
          ReliabilityEvent(personId: 'me', rideId: id, date: Ride.parseId(id)!.$1, kind: ReliabilityEventKind.kept)
              .toJson(),
      ]),
    };

String _tripId(int index) {
  final d = _rideDays[index ~/ 2];
  return Ride.idFor('sz-0725', d, index.isEven ? Leg.going : Leg.ret);
}

Map<String, Object> _balance(int egp) => {'wallet.balance.me': egp};

Future<ProviderContainer> _openWallet(
  WidgetTester tester,
  String locale, {
  PaymentMethod method = PaymentMethod.instapay,
  Map<String, Object> extra = const {},
  List<Override> overrides = const [],
  CalendarDate? on,
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {
      ...memberPrefs(
        role: Role.rider,
        locale: locale,
        withPlan: false,
        method: method,
        pastTrial: method == PaymentMethod.instapay,
      ),
      // No 003 demo history unless a test seeds trips: only seeded trips count.
      FakeDailyCommuteRepository.eventsKey: '[]',
      ...extra,
    },
    overrides: [...dailyOverrides(TestClock(at(on ?? CalendarDate(2026, 10, 29), 21, 0))), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 3400);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  return c;
}

/// The real wallet view with the contribution set to 44 at the same 160/3
/// basis, so the cash rounding (005 FR-029) shows: 44 → 45.
class _At44 extends WalletController {
  @override
  Future<WalletView> build() async {
    final v = await super.build();
    return WalletView(
      role: v.role,
      wallet: v.wallet,
      today: v.today,
      plan: v.plan,
      mode: v.mode,
      legShare: 44,
      capacitySeats: v.capacitySeats,
      filledSeats: v.filledSeats,
      groupTripCost: v.groupTripCost,
      riderSeats: v.riderSeats,
    );
  }
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] US2 AC1 / 007 SC-001: a 40 EGP trip takes only the 4 fee; the 40 is paid directly',
        (tester) async {
      await _openWallet(tester, code, extra: {..._trips(2), ..._balance(200)});
      expect(find.text(l.egpAmount(192)), findsOneWidget, reason: '200 − 2 × 4');
      expect(find.text(l.priceWithFee(40, 4)), findsNWidgets(2), reason: 'one caption per trip row');
      expect(find.text('-${l.egpAmount(4)}'), findsNWidgets(2));
      expect(find.text('-${l.egpAmount(44)}'), findsNothing);
    });

    testWidgets('[$code] US2 AC2: topping up 200 gives a balance of exactly 200', (tester) async {
      final c = await _openWallet(tester, code);
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();
      final wallet = await c.read(walletRepositoryProvider).getWallet(c.read(dailyCommuteRepositoryProvider).meId);
      expect(wallet.balance, 200);
      expect(wallet.activity.first.kind, ActivityKind.topUp);
    });

    testWidgets('[$code] US2 AC3: a late cancel goes to the driver with no service fee', (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          FakeDailyCommuteRepository.chargesKey: jsonEncode([
            Charge(id: 'c1', personId: 'me', rideId: _tripId(0), reason: ChargeReason.lateCancel, amount: 20, owedTo: 'ahmed')
                .toJson(),
          ]),
        },
      );
      expect(find.text(l.actLateCancelCharge), findsOneWidget);
      expect(find.text(l.cashPaidLine(20)), findsOneWidget, reason: 'paid to the driver directly (007)');
      expect(find.text('-${l.egpAmount(20)}'), findsNothing);
      expect(find.text(l.priceWithFee(20, 2)), findsNothing);
    });

    testWidgets('[$code] free cancellations still show as zero rows', (tester) async {
      await _openWallet(
        tester,
        code,
        on: CalendarDate(2026, 10, 6),
        extra: {
          FakeDailyCommuteRepository.absencesKey: jsonEncode([
            Absence(
              personId: 'me',
              date: CalendarDate(2026, 10, 5),
              leg: Leg.going,
              madeAt: WallTime(CalendarDate(2026, 10, 4), const Clock.hm(18, 0)),
              kind: AbsenceKind.freeCancel,
            ).toJson(),
          ]),
        },
      );
      expect(find.text(l.actFreeCancelZero), findsOneWidget);
    });

    testWidgets('[$code] US2 AC4: fees over 149 this month → the subscribe banner', (tester) async {
      await _openWallet(tester, code, extra: {..._trips(38), ..._balance(2000)});
      expect(find.text(l.feeSavings(152)), findsOneWidget, reason: '38 × 4 EGP');
      await tester.tap(find.descendant(of: find.byKey(const Key('fee-savings')), matching: find.text(l.subscribe)));
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget);
    });

    testWidgets('[$code] US2 AC4: 37 trips (148 in fees) → no banner', (tester) async {
      await _openWallet(tester, code, extra: {..._trips(37), ..._balance(2000)});
      expect(find.byKey(const Key('fee-savings')), findsNothing);
    });

    testWidgets('[$code] US2 AC5/AC6: plan card "Pay per trip" and the 40 / 4 / 44 breakdown', (tester) async {
      await _openWallet(tester, code, extra: _balance(200));
      expect(find.text(l.planPayPerTrip), findsOneWidget);
      expect(find.text(l.planPerTripLine(4)), findsOneWidget);
      final breakdown = find.byKey(const Key('breakdown'));
      expect(find.descendant(of: breakdown, matching: find.text(l.egpAmount(40))), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(l.egpAmount(4))), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(l.egpAmount(44))), findsOneWidget);
    });

    testWidgets('[$code] US3: a subscriber sees "Subscribed until" and no fee', (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          ..._balance(200),
          FakeWalletRepository.planKey: jsonEncode(Plan(
            personId: 'me',
            type: PlanType.monthly,
            status: PlanStatus.active,
            price: 129,
            startDate: WallTime(CalendarDate(2026, 10, 1), const Clock.hm(0, 0)),
            untilDate: CalendarDate(2026, 11, 1),
          ).toJson()),
        },
      );
      expect(find.text(l.planSubscribedLine('1/11')), findsOneWidget);
      expect(find.text(l.breakdownNoFee), findsOneWidget);
    });

    testWidgets('[$code] US3 AC5: a lapsed subscription is back to pay per trip, fee included', (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          ..._balance(200),
          FakeWalletRepository.planKey: jsonEncode(Plan(
            personId: 'me',
            type: PlanType.monthly,
            status: PlanStatus.active,
            price: 129,
            startDate: WallTime(CalendarDate(2026, 9, 1), const Clock.hm(0, 0)),
            untilDate: CalendarDate(2026, 10, 1),
          ).toJson()),
        },
      );
      expect(find.text(l.planLapsedLine), findsOneWidget);
      expect(find.text(l.planPayPerTrip), findsOneWidget);
      expect(find.text(l.breakdownFee), findsOneWidget);
    });

    testWidgets('[$code] the savings banner hides once subscribed', (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          ..._trips(38),
          ..._balance(2000),
          FakeWalletRepository.planKey: jsonEncode(Plan(
            personId: 'me',
            type: PlanType.monthly,
            status: PlanStatus.active,
            price: 129,
            startDate: WallTime(CalendarDate(2026, 10, 28), const Clock.hm(0, 0)),
            untilDate: CalendarDate(2026, 11, 28),
          ).toJson()),
        },
      );
      expect(find.byKey(const Key('fee-savings')), findsNothing,
          reason: 'fees were paid this month, but the rider is subscribed now');
    });

    testWidgets('[$code] fees past the balance read as owed to Goora, never a block (007 FR-009)', (tester) async {
      await _openWallet(tester, code, extra: _trips(2));
      expect(find.byKey(const Key('fee-owed')), findsOneWidget);
      expect(find.text(l.feeOwed(8)), findsOneWidget);
      expect(find.text(l.feeOwedBody), findsOneWidget);
    });

    testWidgets('[$code] 008 US2: Pay opens one payment for what is owed; after it nothing is owed',
        (tester) async {
      final c = await _openWallet(tester, code, extra: _trips(2));
      await tester.tap(find.descendant(of: find.byKey(const Key('fee-owed')), matching: find.text(l.payNow)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pay-sheet-settle')), findsOneWidget);
      expect(find.text(l.settleConfirm(8)), findsOneWidget);
      await tester.tap(find.byKey(const Key('pay-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fee-owed')), findsNothing);
      final wallet = await c.read(walletRepositoryProvider).getWallet(c.read(dailyCommuteRepositoryProvider).meId);
      expect(wallet.owed, 0);
    });

    testWidgets('[$code] 008: Fawry shows a reference code and "I paid at Fawry"', (tester) async {
      await _openWallet(tester, code, extra: _trips(2));
      await tester.tap(find.descendant(of: find.byKey(const Key('fee-owed')), matching: find.text(l.payNow)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-method-fawry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fawry-code')), findsOneWidget);
      expect(find.text(l.fawryPaid), findsOneWidget);
    });

    testWidgets('[$code] 008 US4: buying the bundle shows 20 trips left; the balance does not move',
        (tester) async {
      final c = await _openWallet(tester, code, extra: _balance(100));
      final buy = find.byKey(const Key('bundle-buy'));
      await tester.ensureVisible(buy);
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pay-sheet-bundle')), findsOneWidget);
      expect(find.text(l.settleConfirm(75)), findsOneWidget);
      await tester.tap(find.byKey(const Key('pay-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l.bundleLeft(20)), findsOneWidget);
      final wallet = await c.read(walletRepositoryProvider).getWallet(c.read(dailyCommuteRepositoryProvider).meId);
      expect(wallet.balance, 100);
    });

    testWidgets('[$code] 008: a failed settlement shows a retry and changes nothing', (tester) async {
      final c = await _openWallet(
        tester,
        code,
        extra: _trips(2),
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.descendant(of: find.byKey(const Key('fee-owed')), matching: find.text(l.payNow)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l.settleFailTitle), findsOneWidget);
      final wallet = await c.read(walletRepositoryProvider).getWallet(c.read(dailyCommuteRepositoryProvider).meId);
      expect(wallet.owed, 8);
    });

    testWidgets('[$code] 007 US3: a share marked unpaid shows "you owe", and "I paid" makes it disputed',
        (tester) async {
      await _openWallet(
        tester,
        code,
        method: PaymentMethod.cash,
        extra: {
          ..._trips(1),
          FakeWalletRepository.marksKey: jsonEncode([
            CashMark(
              rideId: _tripId(0),
              riderId: 'me',
              driverId: 'ahmed',
              outcome: CashOutcome.didNotPay,
              amount: 40,
              date: Ride.parseId(_tripId(0))!.$1,
            ).toJson(),
          ]),
        },
      );
      expect(find.byKey(const Key('share-debts')), findsOneWidget);
      expect(find.text(l.owesDriver(40, 'Ahmed')), findsOneWidget);
      await tester.tap(find.text(l.iPaid));
      await tester.pumpAndSettle();
      expect(find.text(l.iPaidSent('Ahmed')), findsOneWidget);
      expect(find.text(l.iPaid), findsNothing);
    });

    testWidgets('[$code] US4 AC1: 2 cash trips → "3 cash trips left", no fee, paid-cash rows', (tester) async {
      await _openWallet(tester, code, method: PaymentMethod.cash, extra: _trips(2));
      expect(find.text(l.cashTripsLeft(3)), findsOneWidget);
      expect(find.text(l.cashPaidLine(40)), findsNWidgets(2));
      expect(find.byKey(const Key('cash-top-up-banner')), findsNothing);
      expect(find.byKey(const Key('fee-owed')), findsNothing, reason: 'trial trips carry no fee');
    });

    testWidgets('[$code] 005 FR-029: on the demo corridor the cash plan card still reads 40',
        (tester) async {
      await _openWallet(tester, code, method: PaymentMethod.cash);
      final card = find.byKey(const Key('plan-card'));
      expect(find.descendant(of: card, matching: find.text(l.priceCash(40))), findsOneWidget);
    });

    testWidgets('[$code] 005 FR-029: at 44 the cash plan card reads 45', (tester) async {
      await _openWallet(
        tester,
        code,
        method: PaymentMethod.cash,
        overrides: [walletControllerProvider.overrideWith(_At44.new)],
      );
      final card = find.byKey(const Key('plan-card'));
      expect(find.descendant(of: card, matching: find.text(l.priceCash(45))), findsOneWidget);
    });

    testWidgets('[$code] US4 AC2: after 3 cash trips the top-up banner shows', (tester) async {
      await _openWallet(tester, code, method: PaymentMethod.cash, extra: _trips(3));
      expect(find.byKey(const Key('cash-top-up-banner')), findsOneWidget);
      expect(find.text(l.cashTopUpBanner), findsOneWidget);
    });

    testWidgets('[$code] US4 AC3: after 5 cash trips cash is over', (tester) async {
      await _openWallet(tester, code, method: PaymentMethod.cash, extra: _trips(5));
      expect(find.byKey(const Key('cash-trial')), findsNothing);
      expect(find.text(l.cashEnded), findsOneWidget);
      expect(find.text(l.planPerTripLine(4)), findsOneWidget, reason: 'the wallet price now');
    });

    testWidgets('[$code] US4 AC4: two "Didn\'t pay" marks turn cash off', (tester) async {
      await _openWallet(
        tester,
        code,
        method: PaymentMethod.cash,
        extra: {
          ..._trips(3),
          FakeWalletRepository.marksKey: jsonEncode([
            for (final i in [0, 1])
              CashMark(
                rideId: _tripId(i),
                riderId: 'me',
                driverId: 'ahmed',
                outcome: CashOutcome.didNotPay,
                amount: 40,
                date: Ride.parseId(_tripId(i))!.$1,
              ).toJson(),
          ]),
        },
      );
      expect(find.text(l.cashOff), findsOneWidget);
    });

    testWidgets('[$code] US4 AC5: a late cancel during the trial moves nothing in the wallet', (tester) async {
      await _openWallet(
        tester,
        code,
        method: PaymentMethod.cash,
        extra: {
          ..._trips(2),
          FakeDailyCommuteRepository.chargesKey: jsonEncode([
            Charge(id: 'c1', personId: 'me', rideId: _tripId(1), reason: ChargeReason.lateCancel, amount: 20, owedTo: 'ahmed')
                .toJson(),
          ]),
        },
      );
      expect(find.text(l.cashPaidLine(20)), findsOneWidget, reason: 'owed to the driver, paid directly (007)');
      expect(find.text('-${l.egpAmount(20)}'), findsNothing);
    });

    testWidgets('[$code] a top-up failure leaves the balance unchanged with an inline retry', (tester) async {
      final c = await _openWallet(
        tester,
        code,
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l.topUpFailTitle), findsOneWidget);
      final wallet = await c.read(walletRepositoryProvider).getWallet(c.read(dailyCommuteRepositoryProvider).meId);
      expect(wallet.balance, 0);
      expect(wallet.activity, isEmpty);
    });
  }
}

final class _AlwaysFail implements PaymentProvider {
  const _AlwaysFail();

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async => PaymentResult.failure;

  @override
  Future<PaymentResult> withdraw({required int amount}) async => PaymentResult.failure;

  @override
  Future<PaymentResult> debit({required int amount}) async => PaymentResult.failure;
}
