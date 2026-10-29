import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/presentation/company_controller.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/main.dart' show loadSession;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 T034 (US3): an enrolled employee is told once when the company plan
/// pauses for an unpaid invoice and once when it is back — neutral copy, no
/// amounts, nothing for an employee whose plan never paused.
WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));

void main() {
  late ProviderContainer c;
  late WallTime now;

  Future<List<NoticeKind>> inbox() async =>
      [for (final n in await c.read(dailyCommuteRepositoryProvider).notices().first) n.kind];

  Future<void> read() async {
    c.invalidate(companyAccountProvider);
    await c.read(companyAccountProvider.future);
  }

  setUp(() async {
    now = _at(2026, 10, 20, 10);
    SharedPreferences.setMockInitialValues(memberPrefs(role: Role.rider, member: false, withPlan: false));
    final prefs = await SharedPreferences.getInstance();
    final session = await loadSession(prefs);
    c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      initialSessionProvider.overrideWithValue(session),
      nowProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    final me = c.read(dailyCommuteRepositoryProvider).meId;
    await c.read(companyRepositoryProvider).enroll(me, now: now);
    await c.read(walletRepositoryProvider).startCompanyPlan(me, now);
  });

  test('a covered employee gets no notice', () async {
    await read();
    now = _at(2026, 11, 23, 23, 59);
    await read();
    expect(await inbox(), isNot(contains(NoticeKind.companyPlanPaused)));
  });

  test('paused once when the plan stops covering, resumed once when Goora marks the invoice paid', () async {
    now = _at(2026, 11, 24, 7, 15);
    await read();
    await read();
    expect((await inbox()).where((k) => k == NoticeKind.companyPlanPaused), hasLength(1));
    expect(await inbox(), isNot(contains(NoticeKind.companyPlanResumed)));

    now = _at(2026, 11, 25, 9);
    final company = c.read(companyRepositoryProvider);
    final october = (await company.invoices(CompanySeed.valeoId, now)).firstWhere((i) => i.month == '2026-10');
    await company.demoMarkPaid(october.id, bankRef: 'TX-1', now: now);
    await read();
    await read();
    expect((await inbox()).where((k) => k == NoticeKind.companyPlanResumed), hasLength(1));
    expect((await inbox()).where((k) => k == NoticeKind.companyPlanPaused), hasLength(1));
  });
}
