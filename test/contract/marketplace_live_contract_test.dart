import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/supabase_trust_repository.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/supabase_marketplace_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';
import 'marketplace_live_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/no_group_daily.dart';
import 'support/server.dart';
import 'support/tables.dart';

// Saturday morning: the offers are for Sunday, so a booking is before the 9 PM cut-off and can be reclaimed.
final _now = WallTime(CalendarDate(2026, 10, 31), const Clock.hm(10, 0));
const _corridor = Corridors.sheikhZayedSmartVillage;

Profile _rider() =>
    Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);

void main() {
  marketplaceLiveContract('fake', () async {
    SharedPreferences.setMockInitialValues(
      memberPrefs(role: Role.rider, member: false, method: PaymentMethod.cash, withPlan: false),
    );
    final prefs = await SharedPreferences.getInstance();
    final person = _rider();
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
      role: () => MemberRole.rider,
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
    return (repo: repo, now: _now);
  });

  marketplaceLiveContract('supabase', () async {
    final db = InMemoryGateway(keys: tableKeys);
    final person = _rider();
    await signUpPerson(db, person);
    installTrustServer(db);
    installWalletServer(db, today: _now.date.toIso(), wall: _now.toJson());
    installMarketServer(db, wall: _now.toJson);
    // Another driver, Dina, offers a seat tomorrow at 07:30.
    await db.insert('profiles', [
      {'id': 'drv', 'first_name': 'Dina', 'last_name': 'Tawfik', 'gender': 'female', 'role': 'driver', 'rating': 4.7},
    ]);
    await db.insert('offered_trips', [
      {
        'id': 'trip-1',
        'driver_id': 'drv',
        'leg': 'going',
        'origin_area': 'sheikhZayed',
        'destination_area': 'smartVillage',
        'trip_date': _now.date.addDays(1).toIso(),
        'departure': '07:30:00',
        'duration_minutes': 40,
        'seats': 3,
        'rider_seats': 3,
        'trip_cost': _corridor.tripCost,
        'contribution': 40,
        'repeat': 'once',
        'pickup': MarketSeed.pickupIn(Area.sheikhZayed, 'p1', const Clock.hm(7, 30)).toJson(),
        'status': 'open',
        'group_id': null,
        'origin': 'published',
        'cancelled_with_riders': false,
      },
    ]);
    final wallet = SupabaseWalletRepository(
      db,
      role: () => MemberRole.rider,
      now: () => _now,
      provider: FakePaymentProvider(),
    );
    await wallet.setMethod(db.userId!, PaymentMethod.cash);
    final repo = SupabaseMarketplaceRepository(
      db,
      trust: SupabaseTrustRepository(db, person: () => person, now: () => _now),
      wallet: () => wallet,
      daily: NoGroupDaily(),
      corridor: _corridor,
    );
    return (repo: repo, now: _now);
  });
}
