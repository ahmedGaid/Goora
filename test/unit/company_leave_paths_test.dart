import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/company/domain/company_rules.dart';
import 'package:goora/features/company/domain/enrollment.dart';
import 'package:goora/features/company/presentation/company_controller.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/main.dart' show loadSession;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 T037 (US4 AC2–AC7; FR-018, FR-019, FR-020; SC-007): every way an
/// employee leaves — by themselves, removed by HR, their domain removed, the
/// contract end date passing, Goora staff ending it — has the same effect on
/// the employee's side once their company area next loads: trips after the
/// leave carry the fee, trips before stay fee-free, no new trial, a paused
/// personal plan comes back with its days, one inbox notice. The leaver is
/// still counted in the month's peak, and re-joining that month counts once.
/// The sixth path is the spec edge case "work email moves to another company's
/// domain" (P9, research C1).
WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));

/// The demo user's Trust work email (`FakeTrustRepository.workEmailFor`).
const _myEmail = 'omar@valeo.com';

typedef _Leave = ({String name, Future<WallTime> Function(ProviderContainer c, WallTime at) leave});

void main() {
  late ProviderContainer c;
  late WallTime now;
  final enrollAt = _at(2026, 10, 20, 9);
  final leftAt = _at(2026, 10, 20, 12);

  /// The demo user's work email as the profile gives it; a test moves it.
  var email = _myEmail;

  String me() => c.read(dailyCommuteRepositoryProvider).meId;
  CompanyRepository company() => c.read(companyRepositoryProvider);

  Future<List<NoticeKind>> inbox() async =>
      [for (final n in await c.read(dailyCommuteRepositoryProvider).notices().first) n.kind];

  Future<void> read() async {
    c.invalidate(companyAccountProvider);
    await c.read(companyAccountProvider.future);
  }

  /// What the wallet kept as fee-free before the company plan was replaced.
  List<Window> keptCovered() {
    final raw = c.read(sharedPreferencesProvider).getString(FakeWalletRepository.coveredKey(me()));
    if (raw == null) return const [];
    return [for (final w in jsonDecode(raw) as List) (from: (w as List)[0] as int, to: w[1] as int?)];
  }

  Future<void> start({Plan? personal}) async {
    now = enrollAt;
    email = _myEmail;
    SharedPreferences.setMockInitialValues({
      ...memberPrefs(role: Role.rider, member: false, withPlan: false, method: PaymentMethod.cash),
      if (personal != null) FakeWalletRepository.planKey: jsonEncode(personal.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final session = await loadSession(prefs);
    c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      initialSessionProvider.overrideWithValue(session),
      nowProvider.overrideWithValue(() => now),
      companyRepositoryProvider.overrideWith(
        (ref) => FakeCompanyRepository(
          ref.watch(sharedPreferencesProvider),
          person: (id) async => id == DailySeed.meId ? (name: 'Omar Khaled', workEmail: email) : null,
          now: ref.watch(nowProvider),
        ),
      ),
    ]);
    addTearDown(c.dispose);
    await company().enroll(me(), now: enrollAt);
    await c.read(walletRepositoryProvider).startCompanyPlan(me(), enrollAt);
    await read();
  }

  final paths = <_Leave>[
    (
      name: 'self',
      leave: (c, at) async {
        await c.read(companyRepositoryProvider).leave(c.read(dailyCommuteRepositoryProvider).meId, now: at);
        return at;
      },
    ),
    (
      name: 'removed by HR',
      leave: (c, at) async {
        await c.read(companyRepositoryProvider).removeEmployee(CompanySeed.valeoId, _myEmail, at);
        return at;
      },
    ),
    (
      name: 'domain removed',
      leave: (c, at) async {
        final repo = c.read(companyRepositoryProvider);
        await repo.addDomain(CompanySeed.valeoId, 'valeo.eg', at.plusMinutes(-30));
        await repo.removeDomain(CompanySeed.valeoId, 'valeo.com', at);
        return at;
      },
    ),
    (
      name: 'contract end date passed',
      // Seeded on 20 Oct 2026: approved 1 Aug 2026, contract to 1 Aug 2027.
      leave: (c, at) async => _at(2027, 8, 1),
    ),
    (
      name: 'work email moved to another company domain',
      // The move is seen when the company area next loads, so it is read at the leave moment.
      leave: (c, at) async {
        await c.read(companyRepositoryProvider).demoApprove(CompanySeed.orangeId, at.plusMinutes(-30));
        email = 'omar@orange.com';
        now = at;
        await read();
        return at;
      },
    ),
    (
      name: 'Goora staff ended the contract',
      leave: (c, at) async {
        await c.read(companyRepositoryProvider).demoEndContract(CompanySeed.valeoId, at);
        return at;
      },
    ),
  ];

  for (final path in paths) {
    group('leave path: ${path.name}', () {
      test('the next trip carries the fee, earlier trips stay fee-free, no trial, one notice', () async {
        await start();
        final at = await path.leave(c, leftAt);
        now = at.plusMinutes(60);
        await read();
        await read();

        expect(await company().offerFor(me(), now), isNot(isA<Enrolled>()));
        expect(await c.read(walletRepositoryProvider).getPlan(me()), isNull, reason: 'back to pay per trip');
        expect(await c.read(riderPricingProvider.future), PricingMode.perTrip);

        final kept = keptCovered();
        expect(CompanyRules.covered(kept, SharePolicy.minuteOf(enrollAt.plusMinutes(30))), isTrue);
        expect(CompanyRules.covered(kept, SharePolicy.minuteOf(at.plusMinutes(1))), isFalse);

        expect((await c.read(walletRepositoryProvider).getWallet(DailySeed.meId)).cashTrial, isNull);

        final kinds = await inbox();
        expect(kinds.where((k) => k == NoticeKind.companyPlanEnded), hasLength(1));
        expect(kinds, isNot(contains(NoticeKind.personalPlanBack)));
      });

      test('a paused personal plan comes back with its days, counted from the leave', () async {
        await start(
          personal: Plan(
            personId: DailySeed.meId,
            type: PlanType.monthly,
            status: PlanStatus.active,
            price: 149,
            startDate: _at(2026, 10, 10, 8),
            untilDate: CalendarDate(2026, 11, 9),
          ),
        );
        final daysLeft = (await c.read(walletRepositoryProvider).pausedPlan(me()))!.daysLeft;
        final at = await path.leave(c, leftAt);
        now = at.plusMinutes(60);
        await read();
        await read();

        final plan = (await c.read(walletRepositoryProvider).getPlan(me()))!;
        expect(plan.type, PlanType.monthly);
        expect(plan.startDate, at);
        expect(plan.untilDate, at.date.addDays(daysLeft));
        expect(await c.read(walletRepositoryProvider).pausedPlan(me()), isNull);
        expect((await inbox()).where((k) => k == NoticeKind.personalPlanBack), hasLength(1));
      });
    });
  }

  group('the month\'s peak (SC-007)', () {
    Future<int> peakOf(String month) async {
      final invoices = await company().invoices(CompanySeed.valeoId, now);
      return invoices.firstWhere((i) => i.month == month).peakEnrolled;
    }

    test('a leaver removed by HR is still counted in the month they left', () async {
      await start();
      await company().removeEmployee(CompanySeed.valeoId, _myEmail, leftAt);
      await read();
      now = _at(2026, 11, 2, 10);
      expect(await peakOf('2026-10'), await peakOf('2026-09') + 1);
    });

    test('removed, then re-joining the same month, counts once', () async {
      await start();
      await company().removeEmployee(CompanySeed.valeoId, _myEmail, leftAt);
      await read();
      now = _at(2026, 10, 22, 9);
      expect(await company().offerFor(me(), now), isA<CanEnroll>());
      await company().enroll(me(), now: now);
      await c.read(walletRepositoryProvider).startCompanyPlan(me(), now);
      await read();
      now = _at(2026, 11, 2, 10);
      expect(await peakOf('2026-10'), await peakOf('2026-09') + 1);
    });
  });

  test('lastLeave says which company, when and why; null while enrolled or never enrolled', () async {
    await start();
    expect(await company().lastLeave(me(), leftAt), isNull);
    await company().removeEmployee(CompanySeed.valeoId, _myEmail, leftAt);
    expect(await company().lastLeave(me(), leftAt.plusMinutes(1)),
        (companyName: 'Valeo', at: leftAt, why: LeftWhy.removedByHr));
    expect(await company().lastLeave('nobody', leftAt), isNull);
  });
}
