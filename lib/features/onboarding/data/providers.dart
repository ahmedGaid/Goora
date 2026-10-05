import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../domain/repositories.dart';
import 'fake_auth_repository.dart';
import 'local_profile_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => FakeAuthRepository(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    LocalProfileRepository(ref.watch(sharedPreferencesProvider));
