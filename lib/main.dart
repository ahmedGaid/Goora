import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/goora_app.dart';
import 'core/storage/preferences.dart';
import 'features/onboarding/data/fake_auth_repository.dart';
import 'features/onboarding/data/local_profile_repository.dart';
import 'features/onboarding/presentation/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final session = await loadSession(prefs);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSessionProvider.overrideWithValue(session),
      ],
      child: const GooraApp(),
    ),
  );
}

/// Restores the signed-in number and profile before the first frame so the
/// router can open on the person's resume step.
Future<Session> loadSession(SharedPreferences prefs) async {
  final phone = FakeAuthRepository(prefs).currentPhone;
  if (phone == null) return const Session();
  final profile = await LocalProfileRepository(prefs).load();
  return Session(phone: phone, profile: profile?.phone == phone ? profile : null);
}
