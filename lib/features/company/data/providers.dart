import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_providers.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../daily/data/providers.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/company_repository.dart';
import 'fake_company_repository.dart';
import 'supabase_company_repository.dart';

part 'providers.g.dart';

/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: the wallet asks this one for coverage through a
/// function (T019), so no provider cycle can form (005 lesson, research R8).
///
/// [PersonLookup] knows the signed-in person only (the fake has no other
/// accounts): their name from the profile, their work email from Trust
/// (T017). Signed out = nobody.
@Riverpod(keepAlive: true)
CompanyRepository companyRepository(Ref ref) => ref.watch(backendModeProvider) == BackendMode.live
    ? SupabaseCompanyRepository(ref.watch(backendGatewayProvider))
    : FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (personId) async {
          final profile = ref.read(sessionControllerProvider).profile;
          if (profile == null || personId != ref.read(dailyCommuteRepositoryProvider).meId) return null;
          final trust = await ref.read(trustRepositoryProvider).profile();
          return (name: '${profile.firstName} ${profile.lastName}'.trim(), workEmail: trust.workEmail);
        },
        now: ref.watch(nowProvider),
      );
