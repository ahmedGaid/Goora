import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T036 (US4 AC1–AC3, AC6; FR-016, FR-017, FR-031): the HR contact's
/// roster shows name, work email and since — nothing else — plus this
/// month's leavers "left on"; removing someone is confirmed, marks them left
/// and logs "removed" with HR as the actor; a self-leave logs "left" with no
/// reason; a domain can be added and removed from the company home — ar + en.
final _now = at(rideTuesday, 10, 0);

/// Seeded on [_now]: Valeo approved 1 Aug 09:00, Karim enrolled at 09:15.
const _karim = (name: 'Karim Fawzy', email: 'karim.fawzy@valeo.com');

Future<ProviderContainer> _asHr(WidgetTester tester, String locale, {TestClock? clock}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(clock ?? TestClock(_now)),
  );
  tester.view.physicalSize = const Size(390, 3200);
  await c
      .read(companyRepositoryProvider)
      .demoSetHrContact(CompanySeed.valeoId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _openRoster(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('company-roster')));
  await tester.pumpAndSettle();
}

Future<void> _openLog(WidgetTester tester, ProviderContainer c) async {
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('company-log')));
  await tester.pumpAndSettle();
}

Set<String> _textsIn(Finder f) => {
      for (final t in find.descendant(of: f, matching: find.byType(Text)).evaluate().map((e) => e.widget as Text))
        if (t.data != null) t.data!,
    };

Future<void> _removeKarim(WidgetTester tester) async {
  await tester.tap(find.byKey(Key('roster-remove-${_karim.email}')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('roster-remove-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;
    final since = l.companyRosterSince(l.shortDateYear(CalendarDate(2026, 8, 1)));

    testWidgets('[$code] the roster lists name, work email and since — nothing else', (tester) async {
      await _asHr(tester, code);
      await _openRoster(tester);
      expect(find.byKey(const Key('company-roster-screen')), findsOneWidget);
      expect(find.text(l.companyRosterCount(12)), findsOneWidget);
      final row = find.byKey(Key('roster-${_karim.email}'));
      expect(row, findsOneWidget);
      expect(_textsIn(row), {_karim.name, _karim.email, since, l.companyRosterRemove});
    });

    testWidgets('[$code] removing asks first; declined keeps the employee', (tester) async {
      await _asHr(tester, code);
      await _openRoster(tester);
      await tester.tap(find.byKey(Key('roster-remove-${_karim.email}')));
      await tester.pumpAndSettle();
      expect(find.text(l.companyRosterRemoveTitle(_karim.name)), findsOneWidget);
      await tester.tap(find.text(l.keepIt));
      await tester.pumpAndSettle();
      expect(find.text(l.companyRosterCount(12)), findsOneWidget);
      expect(find.byKey(Key('roster-left-${_karim.email}')), findsNothing);
    });

    testWidgets('[$code] removed: "left on" today, the count drops, the log says HR removed them', (tester) async {
      final c = await _asHr(tester, code);
      await _openRoster(tester);
      await _removeKarim(tester);
      expect(find.text(l.companyRosterCount(11)), findsOneWidget);
      final left = find.byKey(Key('roster-left-${_karim.email}'));
      expect(find.descendant(of: left, matching: find.text(l.companyRosterLeft(l.shortDateYear(_now.date)))),
          findsOneWidget);
      expect(find.byKey(Key('roster-remove-${_karim.email}')), findsNothing);

      await _openLog(tester, c);
      expect(find.byKey(const Key('company-log-screen')), findsOneWidget);
      final newest = find.byKey(const Key('log-0'));
      expect(find.descendant(of: newest, matching: find.text(l.companyLogEmployeeRemoved(_karim.name))), findsOneWidget);
      expect(find.descendant(of: newest, matching: find.textContaining(l.companyLogByHr)), findsOneWidget);
    });

    testWidgets('[$code] a leaver from an earlier month is off the roster', (tester) async {
      final clock = TestClock(_now);
      final c = await _asHr(tester, code, clock: clock);
      await _openRoster(tester);
      await _removeKarim(tester);
      clock.now = at(CalendarDate(2026, 11, 2), 10, 0);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await _openRoster(tester);
      expect(find.byKey(Key('roster-${_karim.email}')), findsNothing);
      expect(find.text(l.companyRosterCount(11)), findsOneWidget);
    });

    testWidgets('[$code] a self-leave logs "left" by the employee, with no reason', (tester) async {
      final c = await _asHr(tester, code);
      final repo = c.read(companyRepositoryProvider);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      await repo.enroll(me, now: _now);
      await repo.leave(me, now: _now.plusMinutes(5));
      await _openLog(tester, c);
      final newest = find.byKey(const Key('log-0'));
      expect(find.descendant(of: newest, matching: find.text(l.companyLogEmployeeLeft('Omar Khaled'))), findsOneWidget);
      expect(find.descendant(of: newest, matching: find.textContaining(l.companyLogByEmployee)), findsOneWidget);
    });

    testWidgets('[$code] Goora staff show as "Goora" in the log', (tester) async {
      final c = await _asHr(tester, code);
      await _openLog(tester, c);
      // The seed: approved by Goora, two months issued and paid by Goora.
      final oldest = find.byKey(Key('log-${(await c.read(companyRepositoryProvider).log(CompanySeed.valeoId)).length - 1}'));
      expect(find.descendant(of: oldest, matching: find.text(l.companyLogApproved)), findsOneWidget);
      expect(find.descendant(of: oldest, matching: find.textContaining(l.companyLogByGoora)), findsOneWidget);
    });

    testWidgets('[$code] HR adds a domain, then removes it; the last domain has no remove', (tester) async {
      final c = await _asHr(tester, code);
      expect(find.byKey(const Key('domain-remove-valeo.com')), findsNothing);
      await tester.tap(find.byKey(const Key('company-add-domain')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('company-domain-field')), 'gmail.com');
      await tester.tap(find.byKey(const Key('company-domain-add')));
      await tester.pumpAndSettle();
      expect(find.text(l.companyPublicDomain('gmail.com')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('company-domain-field')), 'valeo.eg');
      await tester.tap(find.byKey(const Key('company-domain-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domain-valeo.eg')), findsOneWidget);
      expect((await c.read(companyRepositoryProvider).companyForDomain('valeo.eg'))?.id, CompanySeed.valeoId);

      await tester.tap(find.byKey(const Key('domain-remove-valeo.eg')));
      await tester.pumpAndSettle();
      expect(find.text(l.companyDomainRemoveBody('valeo.eg')), findsOneWidget);
      await tester.tap(find.byKey(const Key('domain-remove-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domain-valeo.eg')), findsNothing);
      expect(await c.read(companyRepositoryProvider).companyForDomain('valeo.eg'), isNull);
    });

    testWidgets('[$code] HR contact left: the company stays active, /company shows only my own plan', (tester) async {
      final c = await _asHr(tester, code);
      final repo = c.read(companyRepositoryProvider);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      await repo.demoSetHrContact(CompanySeed.valeoId, null, _now);
      expect(await repo.myCompanyAccount(me, _now), isNull);
      expect(await repo.offerFor(me, _now), isA<CanEnroll>());
      c.read(routerProvider).go(Routes.settings);
      await tester.pumpAndSettle();
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-hr')), findsNothing);
      expect(find.byKey(const Key('company-roster')), findsNothing);
      expect(find.text(l.companyJoinCta('Valeo')), findsOneWidget);
    });
  }
}

