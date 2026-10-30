import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/data/fake_otp_provider.dart';
import 'package:goora/features/onboarding/data/local_profile_repository.dart';
import 'package:goora/features/onboarding/data/supabase_auth_repository.dart';
import 'package:goora/features/onboarding/data/supabase_profile_repository.dart';
import 'package:goora/features/onboarding/domain/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/tables.dart';

final class _Fake implements OnboardingHarness {
  _Fake(SharedPreferences prefs) : auth = FakeAuthRepository(prefs), profiles = LocalProfileRepository(prefs);

  @override
  final AuthRepository auth;
  @override
  final ProfileRepository profiles;
}

final class _Supabase implements OnboardingHarness {
  _Supabase(InMemoryGateway db)
    : auth = SupabaseAuthRepository(db, otp: const FakeOtpProvider(), backendUrl: 'http://127.0.0.1:54321'),
      profiles = SupabaseProfileRepository(db);

  @override
  final AuthRepository auth;
  @override
  final ProfileRepository profiles;
}

void main() {
  onboardingContract('fake', () async {
    SharedPreferences.setMockInitialValues({});
    return _Fake(await SharedPreferences.getInstance());
  });
  onboardingContract('supabase', () async => _Supabase(InMemoryGateway(keys: tableKeys)));
}
