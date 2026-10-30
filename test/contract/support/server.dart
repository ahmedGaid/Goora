import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/backend_gateway.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/onboarding/data/supabase_profile_repository.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

import 'in_memory_gateway.dart';

/// Stand-ins for the SQL functions in supabase/migrations/2026103000*, as
/// `InMemoryGateway` handlers. They do what the SQL does for the contract's
/// cases; the SQL itself is checked by supabase/tests/*.test.sql.

/// A signed-in person with their `profiles` row, as after onboarding.
Future<String> signUpPerson(InMemoryGateway db, Profile person,
    {String riderIdStatus = 'verified', String? id, String? workEmail}) async {
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
    }
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
      db.table('group_members').add({'group_id': p['p_group'], 'user_id': me, 'role': p['p_role'], 'legs': p['p_legs']});
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

/// 20261030000200: the wallet functions the contract calls, with the same
/// ledger rows (`delta` = signed balance effect) and refusals.
void installWalletServer(InMemoryGateway db, {required String today, required String wall}) {
  const prices = {'monthly': (149, 1), 'yearly': (1490, 12), 'company': (0, 0)};
  List<Row> ledger() => db.table('wallet_entries');
  int balance(String me) => ledger().where((e) => e['person_id'] == me).fold(0, (s, e) => s + (e['delta']! as int));
  var seq = 0;
  void post(String me, String kind, int amount, int delta, {String? id, int fee = 0, int share = 0, String? ride}) {
    final key = id ?? '$kind:${db.newId()}';
    if (ledger().any((e) => e['person_id'] == me && e['id'] == key)) return;
    ledger().add({
      'person_id': me, 'id': key, 'kind': kind, 'amount': amount, 'delta': delta, 'fee': fee,
      'share_to_driver': share, 'ride_id': ride, 'leg': null, 'entry_date': today, 'created_at': ++seq,
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
      'person_id': me, 'type': type, 'status': 'active', 'price': price, 'start_wall': wall,
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
    post(db.me(), 'seatBooked', fee, -fee,
        id: 'seat:${p['p_booking']}', fee: fee, share: p['p_share']! as int, ride: p['p_ride'] as String?);
    return null;
  };
  db.rpcs['wallet_seat_refund'] = (p, db) {
    final amount = p['p_amount']! as int;
    if (amount == 0) return null;
    post(db.me(), 'seatRefund', amount, amount, id: 'refund:${p['p_booking']}', ride: p['p_ride'] as String?);
    return null;
  };
  db.rpcs['instapay_handle_of'] = (p, db) =>
      db.table('payment_settings').where((r) => r['person_id'] == p['p_driver']).firstOrNull?['instapay_handle'];
  db.rpcs['payment_method_of'] = (p, db) =>
      db.table('payment_settings').where((r) => r['person_id'] == p['p_rider']).firstOrNull?['method'];
}

/// 20261030000300: the company functions the contract calls.
void installCompanyServer(InMemoryGateway db, {required String wall}) {
  void logLine(String company, String actor, String kind, [String? detail]) => db.table('company_log').add({
        'id': db.newId('log'), 'company_id': company, 'at': wall, 'actor': actor, 'kind': kind, 'detail': detail,
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
      'id': id, 'name': (p['p_name']! as String).trim(), 'status': 'pending', 'hr_contact_id': me,
      'contract_start': null, 'contract_end': null, 'minimum_seats': 20, 'price_per_seat': 99,
      'approved_at': null, 'ended_at': null,
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
void installMarketServer(InMemoryGateway db) {
  int tripsOn(String driver, Object? date) => db
      .table('offered_trips')
      .where((t) =>
          t['driver_id'] == driver && t['trip_date'] == date && (t['status'] != 'cancelled' || t['cancelled_with_riders'] == true))
      .length;

  db.rpcs['market_publish'] = (p, db) {
    final me = db.me();
    if (db.table('profiles').firstWhere((r) => r['id'] == me)['driver_docs'] == 'pending') {
      throw const BackendRefused('notVerified');
    }
    if (tripsOn(me, p['p_date']) >= 2) throw const BackendRefused('overLimit');
    final id = db.newId('trip');
    db.table('offered_trips').add({
      'id': id, 'driver_id': me, 'leg': p['p_leg'], 'origin_area': p['p_origin'],
      'destination_area': p['p_destination'], 'trip_date': p['p_date'], 'departure': '${p['p_departure']}:00',
      'duration_minutes': 40, 'seats': p['p_seats'], 'rider_seats': p['p_seats'], 'trip_cost': p['p_trip_cost'],
      'contribution': p['p_contribution'], 'repeat': p['p_repeat'], 'pickup': p['p_pickup'], 'status': 'open',
      'group_id': null, 'origin': 'published', 'cancelled_with_riders': false,
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
      'id': id, 'rider_id': me, 'leg': p['p_leg'], 'origin_area': p['p_origin'],
      'destination_area': p['p_destination'], 'trip_date': p['p_date'], 'departure': '${p['p_departure']}:00',
      'repeat': p['p_repeat'], 'pickup': p['p_pickup'], 'contribution': p['p_contribution'], 'fee': p['p_fee'],
      'status': 'posted', 'accepted_by': null, 'trip_ref': null,
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
}
