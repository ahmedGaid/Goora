import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_providers.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/preferences.dart';
import '../domain/repositories.dart';
import 'fake_auth_repository.dart';
import 'fake_otp_provider.dart';
import 'local_profile_repository.dart';
import 'supabase_auth_repository.dart';
import 'supabase_profile_repository.dart';

part 'providers.g.dart';

/// Fake unless the build went live (011 research D1, D2); live = the local
/// sign-in bridge with the fake code (D5, OTP is 012).
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => switch (ref.watch(backendModeProvider)) {
  BackendMode.fake => FakeAuthRepository(ref.watch(sharedPreferencesProvider)),
  BackendMode.live => SupabaseAuthRepository(
    ref.watch(backendGatewayProvider),
    otp: const FakeOtpProvider(),
    backendUrl: Env.supabaseUrl,
  ),
};

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => switch (ref.watch(backendModeProvider)) {
  BackendMode.fake => LocalProfileRepository(ref.watch(sharedPreferencesProvider)),
  BackendMode.live => SupabaseProfileRepository(ref.watch(backendGatewayProvider)),
};
