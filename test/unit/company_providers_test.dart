import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 010 T016: the company provider builds alone and reads no wallet or
/// marketplace provider, so the later wallet seam cannot form a cycle.
void main() {
  test('providers.dart imports no wallet or marketplace code', () {
    final src = File('lib/features/company/data/providers.dart').readAsStringSync();
    final imports = RegExp(r"^import '([^']+)';", multiLine: true).allMatches(src).map((m) => m[1]!).toList();
    expect(imports.where((i) => i.contains('/wallet/') || i.contains('/marketplace/')), isEmpty);
  });

  test('the provider gives the fake, which offers nothing until Trust knows the work email', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = WallTime(CalendarDate(2026, 10, 20), const Clock.hm(10, 0));
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(() => now),
    ]);
    addTearDown(container.dispose);
    final repo = container.read(companyRepositoryProvider);
    expect(repo, isA<FakeCompanyRepository>());
    expect(await repo.offerFor('me', now), isA<NoWorkEmail>());
  });
}
