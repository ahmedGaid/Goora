import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/backend/backend.dart';
import 'package:goora/core/backend/backend_providers.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/commute/data/supabase_commute_repository.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/data/supabase_company_repository.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/data/supabase_daily_commute_repository.dart';
import 'package:goora/features/daily/data/supabase_trust_repository.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/data/supabase_marketplace_repository.dart';
import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/data/local_profile_repository.dart';
import 'package:goora/features/onboarding/data/providers.dart';
import 'package:goora/features/onboarding/data/supabase_profile_repository.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../contract/support/in_memory_gateway.dart';

// 011 FR-001/FR-002: one switch picks every seam; fake is exactly today's build.
void main() {
  Future<ProviderContainer> container(BackendMode mode) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      backendModeProvider.overrideWithValue(mode),
      backendGatewayProvider.overrideWithValue(InMemoryGateway()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the default mode is fake', () {
    Backend.reset();
    expect(Backend.mode, BackendMode.fake);
  });

  test('fake mode: every seam is its fake', () async {
    final c = await container(BackendMode.fake);
    expect(c.read(authRepositoryProvider), isA<FakeAuthRepository>());
    expect(c.read(profileRepositoryProvider), isA<LocalProfileRepository>());
    expect(c.read(commuteRepositoryProvider), isA<FakeCommuteRepository>());
    expect(c.read(dailyCommuteRepositoryProvider), isA<FakeDailyCommuteRepository>());
    expect(c.read(trustRepositoryProvider), isA<FakeTrustRepository>());
    expect(c.read(walletRepositoryProvider), isA<FakeWalletRepository>());
    expect(c.read(marketplaceRepositoryProvider), isA<FakeMarketplaceRepository>());
    expect(c.read(companyRepositoryProvider), isA<FakeCompanyRepository>());
  });

  test('live mode: every seam is its Supabase implementation', () async {
    final c = await container(BackendMode.live);
    expect(c.read(profileRepositoryProvider), isA<SupabaseProfileRepository>());
    expect(c.read(commuteRepositoryProvider), isA<SupabaseCommuteRepository>());
    expect(c.read(dailyCommuteRepositoryProvider), isA<SupabaseDailyCommuteRepository>());
    expect(c.read(trustRepositoryProvider), isA<SupabaseTrustRepository>());
    expect(c.read(walletRepositoryProvider), isA<SupabaseWalletRepository>());
    expect(c.read(marketplaceRepositoryProvider), isA<SupabaseMarketplaceRepository>());
    expect(c.read(companyRepositoryProvider), isA<SupabaseCompanyRepository>());
  });
}
