import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/supabase_trust_repository.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/supabase_marketplace_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';
import 'marketplace_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

final _now = WallTime(CalendarDate(2026, 11, 1), const Clock.hm(6, 0));
const _corridor = Corridors.sheikhZayedSmartVillage;

Profile _person(Role role) =>
    Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role);

/// Not in a group: the Supabase daily seam is P9, and the marketplace only
/// asks it for the group.
final class _NoGroup implements DailyCommuteRepository {
  @override
  Future<CommuteGroup?> myGroup() async => null;
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  marketplaceContract('fake', (role) async {
    SharedPreferences.setMockInitialValues(
      memberPrefs(role: role, member: false, method: PaymentMethod.cash, withPlan: false),
    );
    final prefs = await SharedPreferences.getInstance();
    final person = _person(role);
    final catalog = GroupCatalog(prefs);
    final commute = FakeCommuteRepository(prefs, catalog: catalog);
    final daily = FakeDailyCommuteRepository(
      prefs,
      commute: commute,
      person: () => person,
      now: () => _now,
      catalog: catalog,
    );
    final wallet = FakeWalletRepository(
      prefs,
      daily: daily,
      role: () => role == Role.driver ? MemberRole.driver : MemberRole.rider,
      now: () => _now,
      provider: FakePaymentProvider(),
    );
    final repo = FakeMarketplaceRepository(
      prefs,
      catalog: catalog,
      daily: daily,
      commute: commute,
      notices: daily,
      ledger: () => wallet,
      wallet: () => wallet,
      trust: FakeTrustRepository(prefs, person: () => person, now: () => _now),
      now: () => _now,
      corridor: _corridor,
    );
    return (repo: repo, corridor: _corridor);
  });

  marketplaceContract('supabase', (role) async {
    final db = InMemoryGateway(keys: tableKeys);
    final person = _person(role);
    await signUpPerson(db, person);
    installTrustServer(db);
    installWalletServer(db, today: _now.date.toIso(), wall: _now.toJson());
    installMarketServer(db);
    final wallet = SupabaseWalletRepository(
      db,
      role: () => role == Role.driver ? MemberRole.driver : MemberRole.rider,
      now: () => _now,
      provider: FakePaymentProvider(),
    );
    await wallet.setMethod(db.userId!, PaymentMethod.cash);
    final repo = SupabaseMarketplaceRepository(
      db,
      trust: SupabaseTrustRepository(db, person: () => person, now: () => _now),
      wallet: () => wallet,
      daily: _NoGroup(),
      corridor: _corridor,
    );
    return (repo: repo, corridor: _corridor);
  });
}
