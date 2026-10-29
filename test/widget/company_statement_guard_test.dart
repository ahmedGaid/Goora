import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 P9, research "P8/P9 notes" findings U2 and A1:
///  - U2: `statement(...)` takes no caller id, so the screen is the guard. Someone
///    who is not the HR contact sees no statement: no months, no names, no totals,
///    even when they are an enrolled employee who agreed to share.
///  - A1: FR-025 says "Goora fees show as 0", which is untrue while the company is
///    suspended (FR-013: employees then pay the fee). The statement's rows carry
///    date, leg and the share paid to the driver only: no fee column.
final _now = at(rideTuesday, 10, 0);

Override _workEmail(String email) => companyRepositoryProvider.overrideWith(
      (ref) => FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (_) async => (name: 'Omar Khaled', workEmail: email),
        now: ref.watch(nowProvider),
      ),
    );

bool _keyStarts(Widget w, String prefix) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix);

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;
    final feeWord = code == 'ar' ? 'رسوم' : 'fee';

    Future<ProviderContainer> open(WidgetTester tester, {String? email, bool hr = false, bool agree = false}) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code, withPlan: false),
        overrides: [...dailyOverrides(TestClock(_now)), if (email != null) _workEmail(email)],
      );
      tester.view.physicalSize = const Size(390, 9000);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      final repo = c.read(companyRepositoryProvider);
      if (hr) await repo.demoSetHrContact(CompanySeed.valeoId, me, _now);
      if (email != null && !hr) {
        await repo.enroll(me, now: _now);
        if (agree) await repo.setHrConsent(me, true, _now);
      }
      c.read(routerProvider).go(Routes.companyStatement);
      await tester.pumpAndSettle();
      return c;
    }

    void expectNoStatement(WidgetTester tester) {
      expect(find.byKey(const Key('statement-no-months')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => _keyStarts(w, 'statement-month-')), findsNothing);
      expect(find.byWidgetPredicate((w) => _keyStarts(w, 'statement-line-')), findsNothing);
      for (final k in ['statement-note', 'statement-fee', 'statement-total', 'statement-empty']) {
        expect(find.byKey(Key(k)), findsNothing, reason: k);
      }
      // The seed's agreeing employees (Dina, Hossam) never show up for someone who is not HR.
      for (final name in ['Dina Samir', 'Hossam Nabil', 'Omar Khaled']) {
        expect(find.textContaining(name), findsNothing, reason: name);
      }
      expect(find.textContaining('@valeo.com'), findsNothing);
      expect(tester.takeException(), isNull);
    }

    group('[$code] U2: a non-HR user sees no statement', () {
      testWidgets('someone with no company at all', (tester) async {
        await open(tester);
        expectNoStatement(tester);
      });

      testWidgets('an enrolled employee who agreed to share their own trips', (tester) async {
        final c = await open(tester, email: 'omar@valeo.com', agree: true);
        expect(await c.read(companyRepositoryProvider).hrConsent(c.read(dailyCommuteRepositoryProvider).meId), isTrue);
        expectNoStatement(tester);
      });
    });

    group('[$code] A1: no fee column on the statement', () {
      testWidgets('every row is date, leg and the share paid to the driver', (tester) async {
        await open(tester, hr: true);
        final rows = find.byWidgetPredicate((w) => _keyStarts(w, 'statement-line-'));
        expect(rows, findsWidgets);
        for (final row in rows.evaluate().map((e) => e.widget)) {
          final texts = find.descendant(of: find.byWidget(row), matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data!).toList();
          expect(texts, hasLength(2), reason: 'date · leg, then the share: $texts');
          expect(texts.last, endsWith(l.companyStatementShare('').trim()));
          expect(texts.any((t) => t.toLowerCase().contains(feeWord)), isFalse, reason: 'a fee column: $texts');
        }
      });

      testWidgets('the only mention of the fee is the one header line, never a row or a total', (tester) async {
        await open(tester, hr: true);
        final mentions = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').toLowerCase().contains(feeWord));
        expect(mentions, findsOneWidget);
        expect(tester.widget<Text>(mentions).key, const Key('statement-fee'));
        expect(tester.widget<Text>(mentions).data, l.companyStatementFee(l.egpAmount(0)));
      });
    });
  }
}
