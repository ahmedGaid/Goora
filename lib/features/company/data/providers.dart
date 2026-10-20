import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../domain/company_repository.dart';
import 'fake_company_repository.dart';

part 'providers.g.dart';

/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: those seams (T018–T019, the wallet asks this one for
/// coverage) arrive as functions after 006 merges, so no provider cycle can
/// form (005 lesson, research R8).
///
/// [PersonLookup] knows nobody outside the seed yet: the employee's work
/// email needs `TrustProfile.workEmail` (T017, an existing file that waits
/// for 006). Until then "Through my company" reads "no work email".
@Riverpod(keepAlive: true)
CompanyRepository companyRepository(Ref ref) => FakeCompanyRepository(
      ref.watch(sharedPreferencesProvider),
      person: (_) async => null,
      now: ref.watch(nowProvider),
    );
