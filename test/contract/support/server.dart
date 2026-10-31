import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/backend_gateway.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/attendance_rules.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/onboarding/data/supabase_profile_repository.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/domain/cash_trial_policy.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/fee_balance.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import 'in_memory_gateway.dart';

/// Stand-ins for the SQL functions in supabase/migrations/2026103000*, as
/// `InMemoryGateway` handlers. They do what the SQL does for the contract's
/// cases; the SQL itself is checked by supabase/tests/*.test.sql.

/// A signed-in person with their `profiles` row, as after onboarding.
Future<String> signUpPerson(
  InMemoryGateway db,
  Profile person, {
  String riderIdStatus = 'verified',
  String? id,
  String? workEmail,
}) async {
  final uid = id ?? db.newId('user');
  db.table('profiles').removeWhere((r) => r['id'] == uid);
  await db.insert('profiles', [
    {
      'id': uid,
      ...SupabaseProfileRepository.toRow(person),
      'rating': 4.8,
      'reliability': 100,
      'privacy_preference': 'verifiedUsers',
      'rider_id_status': riderIdStatus,
      'driver_docs': 'notNeeded',
      'company': null,
      'compound': null,
      'work_email': workEmail,
      'work_email_verified': workEmail != null,
    },
  ]);
  db.userId = uid;
  return uid;
}

Row _myProfile(InMemoryGateway db) => db.table('profiles').firstWhere((r) => r['id'] == db.me());

/// 20261030000100: submit_rider_id, start_driver_verification, and the
/// privacy trigger (refused:privacyUnavailable).
void installTrustServer(InMemoryGateway db) {
  db.rpcs['submit_rider_id'] = (_, db) {
    _myProfile(db)['rider_id_status'] = 'verified';
    return 'verified';
  };
  db.rpcs['start_driver_verification'] = (_, db) {
    final p = _myProfile(db);
    if (p['driver_docs'] != 'verified') p['driver_docs'] = 'pending';
    return null;
  };
}

/// A group row as the seed would load it: matching columns + its `card`.
void seedGroup(InMemoryGateway db, CommuteGroup g) {
  db.table('groups').add({
    'id': g.id,
    'origin_area': g.origin.name,
    'destination_area': g.destination.name,
    'card': g.toJson(),
  });
}

/// 20261030000100: groups_for, join_group, join_waitlist.
void installCommuteServer(InMemoryGateway db) {
  db.rpcs['groups_for'] = (p, db) => [
    for (final g in db.table('groups'))
      if (g['origin_area'] == p['p_origin'] && g['destination_area'] == p['p_destination']) g['card'],
  ];
  db.rpcs['join_group'] = (p, db) {
    final me = db.me();
    if (!db.table('groups').any((g) => g['id'] == p['p_group'])) throw const BackendRefused('noSuchGroup');
    db.table('group_members').removeWhere((m) => m['user_id'] == me && m['group_id'] != p['p_group']);
    if (!db.table('group_members').any((m) => m['user_id'] == me)) {
      db.table('group_members').add({
        'group_id': p['p_group'],
        'user_id': me,
        'role': p['p_role'],
        'legs': p['p_legs'],
      });
    }
    return null;
  };
  db.rpcs['join_waitlist'] = (p, db) {
    final me = db.me();
    final list = db.table('waitlist');
    bool route(Row r) => r['origin_area'] == p['p_origin'] && r['destination_area'] == p['p_destination'];
    if (!list.any((r) => r['user_id'] == me && route(r))) {
      list.add({'user_id': me, 'origin_area': p['p_origin'], 'destination_area': p['p_destination']});
    }
    final onRoute = list.where(route).toList();
    return onRoute.indexWhere((r) => r['user_id'] == me) + 1;
  };
}

/// 013 D10: the `ride` and `noCover` actions of the `commute-day` Edge Function, for the
/// cases that need them. `ride` stores the group's ride with a share token and puts every
/// non-driving member of the group document on it at a stop (the server uses each member's
/// nearest stop; here they take the group's stops in turn). `noCover` is free and refused
/// while a driver covers the leg. The other actions are not emulated.
void installDailyServer(InMemoryGateway db) {
  var tokens = 0;
  String groupOf(String me) =>
      db.table('group_members').firstWhere((m) => m['user_id'] == me)['group_id']! as String;

  db.functions['commute-day'] = (body, db) {
    final me = db.me();
    final date = body['date'] as String?;
    final leg = body['leg'] as String?;
    switch (body['action']) {
      case 'ride':
        final gid = groupOf(me);
        final id = Ride.idFor(gid, CalendarDate.parse(date!), Leg.values.byName(leg!));
        if (!db.table('rides').any((r) => r['id'] == id)) {
          final card = (db.table('groups').firstWhere((g) => g['id'] == gid)['card']! as Map).cast<String, Object?>();
          final members = (card['members']! as List).cast<Map<Object?, Object?>>();
          final stops = (card['stops'] as List? ?? const []).cast<Map<Object?, Object?>>();
          final driver = members.firstWhere((m) => m['role'] == 'driver')['id'];
          db.table('rides').add({
            'id': id,
            'group_id': gid,
            'ride_date': date,
            'leg': leg,
            'driver_id': driver,
            'share_token': 'tok-${++tokens}',
            'delay_minutes': 0,
            'confirmed': false,
          });
          var i = 0;
          for (final m in members) {
            if (m['id'] == driver) continue;
            db.table('ride_passengers').add({
              'ride_id': id,
              'user_id': m['id'],
              'stop_id': leg == 'going' && stops.isNotEmpty ? stops[i++ % stops.length]['id'] : 'work',
            });
          }
        }
        return {'rideId': id};
      case 'noCover':
        final gid = groupOf(me);
        final id = Ride.idFor(gid, CalendarDate.parse(date!), Leg.values.byName(leg!));
        final ride = db.table('rides').where((r) => r['id'] == id).firstOrNull;
        if (ride == null || ride['driver_id'] != null) throw const BackendRefused('driverCovers');
        db.table('absences').add({
          'id': db.newId('absence'),
          'user_id': me,
          'group_id': gid,
          'ride_date': date,
          'leg': leg,
          'made_at': '${date}T06:00:00Z',
          'kind': 'noCover',
          'driving': false,
          'seat_taken': false,
        });
        return <String, Object?>{};
      default:
        throw const BackendError('action not emulated');
    }
  };
}

/// 20261030000200: the wallet functions the contract calls, with the same
/// ledger rows (`delta` = signed balance effect) and refusals.
///
/// [clock] moves "today" for the 013 cases (default: fixed at [today]).
void installWalletServer(
  InMemoryGateway db, {
  required String today,
  required String wall,
  String Function()? clock,
}) {
  const prices = {'monthly': (149, 1), 'yearly': (1490, 12), 'company': (0, 0)};
  String now() => clock?.call() ?? today;
  List<Row> ledger() => db.table('wallet_entries');
  int balance(String me) => ledger().where((e) => e['person_id'] == me).fold(0, (s, e) => s + (e['delta']! as int));
  var seq = 0;
  void post(
    String me,
    String kind,
    int amount,
    int delta, {
    String? id,
    int fee = 0,
    int share = 0,
    String? ride,
    String? date,
  }) {
    final key = id ?? '$kind:${db.newId()}';
    if (ledger().any((e) => e['person_id'] == me && e['id'] == key)) return;
    ledger().add({
      'person_id': me,
      'id': key,
      'kind': kind,
      'amount': amount,
      'delta': delta,
      'fee': fee,
      'share_to_driver': share,
      'ride_id': ride,
      'leg': null,
      'entry_date': date ?? now(),
      'created_at': ++seq,
    });
  }

  db.rpcs['wallet_top_up'] = (p, db) {
    final amount = p['p_amount']! as int;
    if (amount <= 0) throw const BackendRefused('amount');
    post(db.me(), 'topUp', amount, amount);
    return null;
  };
  db.rpcs['wallet_withdraw'] = (p, db) {
    final amount = p['p_amount']! as int;
    if (balance(db.me()) < amount) throw const BackendRefused('insufficient');
    post(db.me(), 'withdrawal', amount, -amount);
    return null;
  };
  db.rpcs['wallet_subscribe'] = (p, db) {
    final me = db.me();
    final type = p['p_type']! as String;
    final (price, _) = prices[type]!;
    if (type != 'company' && balance(me) < price) return 'needsTopUp';
    if (price > 0) post(me, 'subscription', price, -price);
    db.table('plans').removeWhere((r) => r['person_id'] == me);
    db.table('plans').add({
      'person_id': me,
      'type': type,
      'status': 'active',
      'price': price,
      'start_wall': wall,
      'until_date': type == 'company' ? null : today,
    });
    return 'subscribed';
  };
  db.rpcs['wallet_settle'] = (p, db) {
    final owed = -balance(db.me());
    if (owed > 0) post(db.me(), 'settlement', owed, owed);
    return owed > 0 ? owed : 0;
  };
  db.rpcs['wallet_seat_debit'] = (p, db) {
    final fee = p['p_fee']! as int;
    post(
      db.me(),
      'seatBooked',
      fee,
      -fee,
      id: 'seat:${p['p_booking']}',
      fee: fee,
      share: p['p_share']! as int,
      ride: p['p_ride'] as String?,
      date: p['p_date'] as String?,
    );
    return null;
  };
  db.rpcs['wallet_seat_refund'] = (p, db) {
    final amount = p['p_amount']! as int;
    if (amount == 0) return null;
    post(
      db.me(),
      'seatRefund',
      amount,
      amount,
      id: 'refund:${p['p_booking']}',
      ride: p['p_ride'] as String?,
      date: p['p_date'] as String?,
    );
    return null;
  };
  db.rpcs['instapay_handle_of'] = (p, db) =>
      db.table('payment_settings').where((r) => r['person_id'] == p['p_driver']).firstOrNull?['instapay_handle'];
  db.rpcs['payment_method_of'] = (p, db) =>
      db.table('payment_settings').where((r) => r['person_id'] == p['p_rider']).firstOrNull?['method'];

  // 013 (20261031000100): the fee state. Same walk as `wallet_state()` in SQL, run on the
  // domain rules the SQL twins. Covers group trips, the trial, fees, bundles, due and overdue.

  // payment_settings_since(): "since" starts the day the method is first chosen.
  db.triggers['payment_settings'] = (row) {
    if (row['method'] != null && row['since_date'] == null) row['since_date'] = now();
  };
  db.rpcs['wallet_buy_bundle'] = (p, db) {
    final me = db.me();
    db.table('bundles').add({'id': db.newId('bundle'), 'person_id': me, 'bought_at': '${now()}T09:00:00'});
    post(me, 'bundle', 75, 0);
    return null;
  };

  Row? settings(String me) => db.table('payment_settings').where((r) => r['person_id'] == me).firstOrNull;

  Map<String, Object?> state(String me) {
    final todayDate = CalendarDate.parse(now());
    final ps = settings(me);
    final purchases = [
      for (final b in db.table('bundles'))
        if (b['person_id'] == me) CalendarDate.parse((b['bought_at']! as String).substring(0, 10)),
    ];
    final ledgerBalance = balance(me);
    final sinceRaw = ps?['since_date'] as String?;
    final since = sinceRaw == null ? null : CalendarDate.parse(sinceRaw);
    final window = todayDate.addDays(-60);
    // No "since": no derived trips, but the ledger's debt still falls due.
    final from = since == null ? todayDate.addDays(1) : (since.isAfter(window) ? since : window);
    final method = PaymentMethod.parse((ps?['method'] as String?) ?? 'cash');

    final items = <({CalendarDate d, int legIndex, String leg, String rideId, int contribution, int cost, int seats})>[];
    for (final e in db.table('reliability_events')) {
      if (e['user_id'] != me || e['kind'] != 'kept') continue;
      final ride = db.table('rides').firstWhere((r) => r['id'] == e['ride_id']);
      final date = CalendarDate.parse(ride['ride_date']! as String);
      if (ride['driver_id'] == me || date.isBefore(from) || date.isAfter(todayDate)) continue;
      final group = db.table('groups').firstWhere((g) => g['id'] == ride['group_id']);
      final card = (group['card'] as Map?) ?? const {};
      final price = group['price']! as int;
      items.add((
        d: date,
        legIndex: ride['leg'] == 'going' ? 0 : 1,
        leg: ride['leg']! as String,
        rideId: ride['id']! as String,
        contribution: price,
        cost: (card['tripCost'] as int?) ?? price * 3,
        seats: (card['riderSeats'] as int?) ?? 3,
      ));
    }
    items.sort((a, b) {
      final byDate = a.d.compareTo(b.d);
      return byDate != 0 ? byDate : a.legIndex.compareTo(b.legIndex);
    });

    final entries = <Map<String, Object?>>[];
    var debits = 0;
    var trialDone = 0;
    var strikes = 0;
    var bundleUsed = 0;
    for (final it in items) {
      final share = DirectPay.share(it.contribution, method: method, tripCost: it.cost, riderSeats: it.seats);
      Map<String, Object?> entry(String id, String kind, int amount, int fee) => {
        'id': '$id:${it.rideId}',
        'kind': kind,
        'amount': amount,
        'fee': fee,
        'date': it.d.toIso(),
        'rideId': it.rideId,
        'shareToDriver': share,
        'leg': it.leg,
      };
      if (CashTrialPolicy.available(trialDone, strikes)) {
        trialDone++;
        strikes += db
            .table('share_marks')
            .where((m) => m['ride_id'] == it.rideId && m['rider_id'] == me && m['outcome'] == 'didNotPay')
            .length;
        entries.add(entry('cash', 'cashTrip', 0, 0));
        continue;
      }
      final fee = DirectPay.fee(it.contribution, share: share, tripCost: it.cost, riderSeats: it.seats, feeFree: false);
      final left = TripBundle.trips * purchases.where((p) => !p.isAfter(it.d)).length - bundleUsed;
      if (TripBundle.useBundle(fee, left)) {
        bundleUsed++;
        entries.add(entry('bundle-trip', 'bundleTrip', 0, 0));
      } else {
        debits += fee;
        entries.add(entry('trip', 'trip', fee, fee));
      }
    }

    final byDay = <CalendarDate, int>{};
    for (final e in ledger().where((e) => e['person_id'] == me)) {
      final d = CalendarDate.parse(e['entry_date']! as String);
      byDay[d] = (byDay[d] ?? 0) + (e['delta']! as int);
    }
    for (final e in entries.where((e) => e['kind'] == 'trip')) {
      final d = CalendarDate.parse(e['date']! as String);
      byDay[d] = (byDay[d] ?? 0) - (e['amount']! as int);
    }
    var running = 0;
    final series = [
      for (final d in byDay.keys.toList()..sort()) (date: d, balance: running += byDay[d]!),
    ];
    final due = FeeBalancePolicy.dueDate(series, todayDate);
    return {
      'balance': ledgerBalance - debits,
      'debits': debits,
      'cashTrial': since == null || ps?['no_trial'] == true || ps?['no_trial_from'] != null
          ? null
          : {'tripsDone': trialDone, 'strikes': strikes},
      'bundleLeft': TripBundle.trips * purchases.length - bundleUsed,
      'feeDue': due?.toIso(),
      'feeOverdue': FeeBalancePolicy.isOverdue(due, todayDate),
      'feesThisMonth': entries
          .where((e) => e['kind'] == 'trip' && (e['date']! as String).startsWith(todayDate.monthKey))
          .fold<int>(0, (s, e) => s + (e['fee']! as int)),
      'entries': entries,
    };
  }

  db.rpcs['wallet_state'] = (p, db) => state(db.me());
  db.rpcs['wallet_assert_open'] = (p, db) {
    final s = state(db.me());
    if (s['feeOverdue'] == true) {
      final balanceNow = s['balance']! as int;
      throw BackendRefused('feeOverdue', '${balanceNow < 0 ? -balanceNow : 0}');
    }
    return null;
  };

  // Group-trip shares only (the contract's cases); one row per kept trip.
  db.rpcs['wallet_share_rows'] = (p, db) {
    final me = db.me();
    if (p['p_role'] != 'rider') return <Object?>[];
    final method = (settings(me)?['method'] as String?) ?? 'cash';
    return [
      for (final e in db.table('reliability_events'))
        if (e['user_id'] == me && e['kind'] == 'kept')
          () {
            final ride = db.table('rides').firstWhere((r) => r['id'] == e['ride_id']);
            final group = db.table('groups').firstWhere((g) => g['id'] == ride['group_id']);
            final card = (group['card'] as Map?) ?? const {};
            final price = group['price']! as int;
            final mark = db
                .table('share_marks')
                .where((m) => m['ride_id'] == ride['id'] && m['rider_id'] == me)
                .firstOrNull;
            final driver = db.table('profiles').where((r) => r['id'] == ride['driver_id']).firstOrNull;
            return <String, Object?>{
              'ride_id': ride['id'],
              'rider_id': me,
              'driver_id': ride['driver_id'],
              'other_first_name': driver?['first_name'] ?? '',
              'method': method,
              'amount': DirectPay.share(
                price,
                method: PaymentMethod.parse(method),
                tripCost: (card['tripCost'] as int?) ?? price * 3,
                riderSeats: (card['riderSeats'] as int?) ?? 3,
              ),
              'trip_end': ride['ended_at'],
              'mark_outcome': mark?['outcome'],
              'marked_at': null,
              'claimed_at': null,
              'reversed_once': (mark?['reversed_once'] as bool?) ?? false,
            };
          }(),
    ];
  };
}

/// 20261030000300: the company functions the contract calls.
void installCompanyServer(InMemoryGateway db, {required String wall}) {
  void logLine(String company, String actor, String kind, [String? detail]) => db.table('company_log').add({
    'id': db.newId('log'),
    'company_id': company,
    'at': wall,
    'actor': actor,
    'kind': kind,
    'detail': detail,
    'created_at': db.table('company_log').length,
  });
  bool held(String d) => db.table('company_domains').any((r) => r['domain'] == d.toLowerCase());
  void mustBeHr(String company) {
    if (!db.table('companies').any((c) => c['id'] == company && c['hr_contact_id'] == db.userId)) {
      throw const BackendRefused('notHrContact');
    }
  }

  db.rpcs['company_register'] = (p, db) {
    final me = db.me();
    final domains = [for (final d in p['p_domains']! as List) (d as String).toLowerCase()];
    final email = (p['p_hr_work_email']! as String).toLowerCase();
    if (domains.isEmpty || !domains.contains(email.split('@').last)) throw const BackendRefused('emailNotOnDomain');
    for (final d in domains) {
      if (held(d)) throw BackendRefused('domainTaken', d);
    }
    final id = db.newId('co');
    db.table('companies').add({
      'id': id,
      'name': (p['p_name']! as String).trim(),
      'status': 'pending',
      'hr_contact_id': me,
      'contract_start': null,
      'contract_end': null,
      'minimum_seats': 20,
      'price_per_seat': 99,
      'approved_at': null,
      'ended_at': null,
    });
    for (final d in domains.toSet()) {
      db.table('company_domains').add({'domain': d, 'company_id': id});
    }
    logLine(id, 'hr', 'registered');
    return id;
  };
  db.rpcs['company_for_domain'] = (p, db) {
    final d = db.table('company_domains').where((r) => r['domain'] == (p['p_domain']! as String).toLowerCase());
    if (d.isEmpty) return null;
    final c = db.table('companies').firstWhere((c) => c['id'] == d.first['company_id']);
    return {'id': c['id'], 'name': c['name'], 'status': c['status']};
  };
  db.rpcs['company_add_domain'] = (p, db) {
    final company = p['p_company']! as String;
    final d = (p['p_domain']! as String).toLowerCase();
    mustBeHr(company);
    if (held(d)) throw BackendRefused('domainTaken', d);
    db.table('company_domains').add({'domain': d, 'company_id': company});
    logLine(company, 'hr', 'domainAdded', d);
    return null;
  };
}

/// 20261030000400: the marketplace functions the contract calls.
///
/// [wall] is "now" as a Cairo wall time (default: the marketplace contract's 1 Nov 2026, 06:00).
void installMarketServer(InMemoryGateway db, {String Function()? wall}) {
  String nowWall() => wall?.call() ?? '2026-11-01T06:00:00';
  int tripsOn(String driver, Object? date) => db
      .table('offered_trips')
      .where(
        (t) =>
            t['driver_id'] == driver &&
            t['trip_date'] == date &&
            (t['status'] != 'cancelled' || t['cancelled_with_riders'] == true),
      )
      .length;

  db.rpcs['market_publish'] = (p, db) {
    final me = db.me();
    if (db.table('profiles').firstWhere((r) => r['id'] == me)['driver_docs'] == 'pending') {
      throw const BackendRefused('notVerified');
    }
    if (tripsOn(me, p['p_date']) >= 2) throw const BackendRefused('overLimit');
    final id = db.newId('trip');
    db.table('offered_trips').add({
      'id': id,
      'driver_id': me,
      'leg': p['p_leg'],
      'origin_area': p['p_origin'],
      'destination_area': p['p_destination'],
      'trip_date': p['p_date'],
      'departure': '${p['p_departure']}:00',
      'duration_minutes': 40,
      'seats': p['p_seats'],
      'rider_seats': p['p_seats'],
      'trip_cost': p['p_trip_cost'],
      'contribution': p['p_contribution'],
      'repeat': p['p_repeat'],
      'pickup': p['p_pickup'],
      'status': 'open',
      'group_id': null,
      'origin': 'published',
      'cancelled_with_riders': false,
    });
    return id;
  };
  db.rpcs['market_post'] = (p, db) {
    final me = db.me();
    if (p['p_repeat'] == 'daily' && db.table('group_members').any((m) => m['user_id'] == me)) {
      throw const BackendRefused('dailyNotAllowed');
    }
    final id = db.newId('req');
    db.table('trip_requests').add({
      'id': id,
      'rider_id': me,
      'leg': p['p_leg'],
      'origin_area': p['p_origin'],
      'destination_area': p['p_destination'],
      'trip_date': p['p_date'],
      'departure': '${p['p_departure']}:00',
      'repeat': p['p_repeat'],
      'pickup': p['p_pickup'],
      'contribution': p['p_contribution'],
      'fee': p['p_fee'],
      'status': 'posted',
      'accepted_by': null,
      'trip_ref': null,
    });
    return id;
  };
  db.rpcs['market_cancel_request'] = (p, db) {
    final me = db.me();
    for (final r in db.table('trip_requests')) {
      if (r['id'] == p['p_request'] && r['rider_id'] == me && r['status'] == 'posted') r['status'] = 'withdrawn';
    }
    return null;
  };
  db.rpcs['market_cancel_offer'] = (p, db) {
    final me = db.me();
    final t = db.table('offered_trips').where((t) => t['id'] == p['p_trip'] && t['driver_id'] == me).firstOrNull;
    if (t == null) throw const BackendRefused('notYours');
    final held = db.table('bookings').where((b) => b['offered_trip_id'] == t['id'] && b['status'] == 'booked').toList();
    for (final b in held) {
      b['status'] = 'refunded';
    }
    t['status'] = 'cancelled';
    t['cancelled_with_riders'] = held.isNotEmpty;
    return null;
  };

  // 013 (20261031000200): reads with first names only, and the reclaim.
  Row? profile(Object? id) => db.table('profiles').where((r) => r['id'] == id).firstOrNull;
  bool holds(Row b) => const {'booked', 'done'}.contains(b['status']);

  db.rpcs['market_offer_cards'] = (p, db) {
    final ids = (p['p_ids'] as List?)?.cast<String>();
    final me = db.me();
    return [
      for (final t in db.table('offered_trips'))
        if (ids == null
            ? t['status'] == 'open'
            : ids.contains(t['id']) &&
                  (const {'open', 'full'}.contains(t['status']) ||
                      t['driver_id'] == me ||
                      db.table('bookings').any((b) => b['offered_trip_id'] == t['id'] && b['rider_id'] == me)))
          () {
            final d = profile(t['driver_id']);
            final first = (d?['first_name'] as String?) ?? '';
            final last = (d?['last_name'] as String?) ?? '';
            return <String, Object?>{
              ...t,
              'taken': db.table('bookings').where((b) => b['offered_trip_id'] == t['id'] && holds(b)).length,
              'driver_first_name': first,
              'driver_initials': '${first.isEmpty ? '' : first[0].toUpperCase()}${last.isEmpty ? '' : last[0].toUpperCase()}',
              'driver_rating': d?['rating'] ?? 5,
              'driver_is_woman': d?['gender'] == 'female',
            };
          }(),
    ];
  };

  db.rpcs['market_book'] = (p, db) {
    final me = db.me();
    final t = db.table('offered_trips').where((t) => t['id'] == p['p_offer']).firstOrNull;
    if (t == null || !const {'open', 'full'}.contains(t['status']) || t['driver_id'] == me) {
      throw const BackendRefused('seatTaken');
    }
    final held = db.table('bookings').where((b) => b['offered_trip_id'] == t['id'] && holds(b)).length;
    if (held >= (t['seats']! as int)) throw const BackendRefused('seatTaken');
    if (db.table('bookings').any(
      (b) => b['rider_id'] == me && b['trip_date'] == t['trip_date'] && b['leg'] == t['leg'] && holds(b),
    )) {
      throw const BackendRefused('alreadyRiding');
    }
    final id = db.newId('booking');
    final fee = p['p_fee']! as int;
    final paidBy = p['p_paid_by']! as String;
    db.table('bookings').add({
      'id': id,
      'rider_id': me,
      'offered_trip_id': t['id'],
      'trip_date': t['trip_date'],
      'leg': t['leg'],
      'ride_id': 'offer:${t['id']}',
      'contribution': p['p_contribution'],
      'fee': fee,
      'paid_by': paidBy,
      'paid': paidBy == 'cash' ? 0 : fee,
      'booked_at': nowWall(),
      'is_subscriber': false,
      'status': 'booked',
    });
    if (held + 1 >= (t['seats']! as int)) t['status'] = 'full';
    return id;
  };

  db.rpcs['market_reclaim'] = (p, db) {
    final me = db.me();
    final b = db.table('bookings').where((b) => b['id'] == p['p_booking']).firstOrNull;
    final t = b == null ? null : db.table('offered_trips').where((t) => t['id'] == b['offered_trip_id']).firstOrNull;
    if (b == null || b['status'] != 'booked' || t == null || (b['rider_id'] != me && t['driver_id'] != me)) {
      throw const BackendRefused('notReclaimable');
    }
    final date = CalendarDate.parse(b['trip_date']! as String);
    if (b['is_subscriber'] == true || AttendanceRules.isLate(date, WallTime.fromJson(b['booked_at']! as String))) {
      throw const BackendRefused('notReclaimable');
    }
    if (AttendanceRules.isLate(date, WallTime.fromJson(nowWall()))) throw const BackendRefused('reclaimTooLate');
    final refund = (b['paid'] as int?) ?? 0;
    b['status'] = 'reclaimed';
    if (t['status'] == 'full') t['status'] = 'open';
    return refund;
  };

  db.rpcs['market_requests_for'] = (p, db) {
    final me = db.me();
    final mine = profile(me);
    if (mine?['role'] != 'driver' && !const {'pending', 'verified'}.contains(mine?['driver_docs'])) return <Object?>[];
    return [
      for (final r in db.table('trip_requests'))
        if (r['status'] == 'posted' && r['rider_id'] != me && r['leg'] == p['p_leg'])
          {
            for (final k in const [
              'id',
              'leg',
              'origin_area',
              'destination_area',
              'trip_date',
              'departure',
              'repeat',
              'pickup',
              'contribution',
              'fee',
              'status',
            ])
              k: r[k],
            'rider_is_woman': profile(r['rider_id'])?['gender'] == 'female',
          },
    ];
  };

  db.rpcs['market_done_one_offs'] = (p, db) {
    final me = db.me();
    final now = WallTime.fromJson(nowWall());
    final out = <Row>[];
    for (final b in db.table('bookings')) {
      final t = db.table('offered_trips').where((t) => t['id'] == b['offered_trip_id']).firstOrNull;
      if (t == null || !holds(b) || (b['rider_id'] != me && t['driver_id'] != me)) continue;
      final time = (t['departure']! as String).split(':').map(int.parse).toList();
      final end = WallTime(
        CalendarDate.parse(b['trip_date']! as String),
        Clock.hm(time[0], time[1]),
      ).plusMinutes((t['duration_minutes'] as int?) ?? 40);
      if (b['status'] != 'done' && end.compareTo(now) > 0) continue;
      out.add({
        'ride_id': b['ride_id'],
        'trip_date': b['trip_date'],
        'leg': b['leg'],
        'paid_by': b['paid_by'],
        'contribution': b['contribution'],
        'trip_cost': t['trip_cost'],
        'rider_seats': t['rider_seats'],
        'rider_id': b['rider_id'],
        'driver_id': t['driver_id'],
        'rider_first_name': profile(b['rider_id'])?['first_name'] ?? '',
        'driver_first_name': profile(t['driver_id'])?['first_name'] ?? '',
        'trip_end': end.toJson(),
      });
    }
    return out;
  };
}
