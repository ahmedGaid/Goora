import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 spec edge case "Employee is a driver only: may enroll" (research
/// "P8/P9 notes", C1): the company area is open to a signed-in driver, who
/// agrees on the consent sheet like anyone and then reads as enrolled.
final _now = at(rideTuesday, 10, 0);

Override _workEmail(String email) => companyRepositoryProvider.overrideWith(
      (ref) => FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (_) async => (name: 'Omar Khaled', workEmail: email),
        now: ref.watch(nowProvider),
      ),
    );

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] a driver-only employee joins through the company area', (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code, withPlan: false),
        overrides: [...dailyOverrides(TestClock(_now)), _workEmail('omar@valeo.com')],
      );
      tester.view.physicalSize = const Size(390, 2400);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      expect(find.text(l.companyCanEnrollLine('Valeo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('company-enrolled')), findsOneWidget);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      expect(await c.read(companyRepositoryProvider).offerFor(me, _now), isA<Enrolled>());
    });
  }
}
