import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/check_in.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';
import 'wallet_contract.dart';

final _now = WallTime(CalendarDate(2026, 11, 2), const Clock.hm(9, 0));

/// A rider in no group with no trips: 003 has nothing for the wallet to price.
final class _NoTrips implements DailyCommuteRepository {
  @override
  String get meId => 'me';
  @override
  Future<CommuteGroup?> myGroup() async => null;
  @override
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to) async => const [];
  @override
  Future<List<Charge>> chargesOwed() async => const [];
  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async => const [];
  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async => null;
  @override
  Future<List<PassengerOutcome>> outcomes(String rideId) async => const [];
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  walletContract('fake', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeWalletRepository(
      await SharedPreferences.getInstance(),
      daily: _NoTrips(),
      role: () => MemberRole.rider,
      now: () => _now,
      provider: FakePaymentProvider(),
    );
    return (wallet: repo, ledger: repo, me: 'me');
  });

  walletContract('supabase', () async {
    final db = InMemoryGateway(keys: tableKeys);
    final me = await signUpPerson(
      db,
      Profile(phone: PhoneNumber.tryParse('01001234567')!, firstName: 'Omar', lastName: 'K', gender: Gender.male),
    );
    installWalletServer(db, today: _now.date.toIso(), wall: _now.toJson());
    final repo = SupabaseWalletRepository(
      db,
      role: () => MemberRole.rider,
      now: () => _now,
      provider: FakePaymentProvider(),
    );
    return (wallet: repo, ledger: repo, me: me);
  });
}
