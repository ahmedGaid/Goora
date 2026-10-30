import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart' show Leg;
import '../../commute/domain/group.dart';
import '../domain/activity_entry.dart';
import '../domain/cash_mark.dart';
import '../domain/direct_pay.dart';
import '../domain/payment_method.dart';
import '../domain/payment_provider.dart';
import '../domain/plan.dart';
import '../domain/share.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';

/// Goora's own money on the server (011 research D8, D9, D13): the ledger is
/// `wallet_entries`, the balance is the sum of its signed `delta`, and every
/// money move is a security definer function that checks the caller and the
/// balance in one transaction. Whole EGP throughout; no driver-income kind
/// exists in the table (Law 87).
///
/// The payment partner stays the device's [PaymentProvider] until 012: a
/// failed fake payment writes nothing, a successful one calls the function.
///
/// Known gaps against the fake (research "Wallet gaps"): the cash trial,
/// `feeDue`/`feeOverdue` and the trip rows derived from 003 records are not
/// computed here yet; shares are read from the driver's marks only.
final class SupabaseWalletRepository implements WalletRepository, SeatLedger {
  SupabaseWalletRepository(this._db, {required this._role, required this._now, required this._provider});

  final BackendGateway _db;
  final MemberRole Function() _role;
  final WallTime Function() _now;
  final PaymentProvider _provider;

  // Plans ---------------------------------------------------------------------

  @override
  Future<Plan?> getPlan(String personId) async {
    final rows = await _db.select('plans', where: [Filter.eq('person_id', personId)]);
    return rows.isEmpty ? null : _plan(rows.single);
  }

  static Plan _plan(Row r) => Plan(
    personId: r['person_id']! as String,
    type: PlanType.values.byName(r['type']! as String),
    status: r['status'] == 'active' ? PlanStatus.active : PlanStatus.due,
    price: r['price']! as int,
    startDate: WallTime.fromJson(r['start_wall']! as String),
    untilDate: r['until_date'] == null ? null : CalendarDate.parse(r['until_date']! as String),
  );

  @override
  Future<SubscribeResult> subscribe(String personId, PlanType type, {required CalendarDate today}) async {
    final out = await _db.rpc('wallet_subscribe', {'p_type': type.name});
    return out == 'needsTopUp' ? SubscribeResult.needsTopUp : SubscribeResult.subscribed;
  }

  @override
  Future<Plan> changePlan(String personId, PlanType newType) async {
    await _db.rpc('wallet_change_plan', {'p_type': newType.name});
    return (await getPlan(personId))!;
  }

  @override
  Future<void> startCompanyPlan(String personId, WallTime now) => _db.rpc('wallet_start_company_plan');

  @override
  Future<void> endCompanyPlan(String personId, WallTime now) => _db.rpc('wallet_end_company_plan');

  @override
  Future<PausedPlan?> pausedPlan(String personId) async {
    final rows = await _db.select('paused_plans', where: [Filter.eq('person_id', personId)]);
    if (rows.isEmpty) return null;
    final r = rows.single;
    return (
      type: PlanType.values.byName(r['type']! as String),
      price: r['price']! as int,
      daysLeft: r['days_left']! as int,
    );
  }

  // Payment settings ------------------------------------------------------------

  Future<Row?> _settings(String personId) async {
    final rows = await _db.select('payment_settings', where: [Filter.eq('person_id', personId)]);
    return rows.isEmpty ? null : rows.single;
  }

  @override
  Future<PaymentMethod?> getMethod(String personId) async {
    final raw = (await _settings(personId))?['method'] as String?;
    return raw == null ? null : PaymentMethod.parse(raw);
  }

  @override
  Future<void> setMethod(String personId, PaymentMethod method) => _db.upsert('payment_settings', [
    {'person_id': personId, 'method': method.name},
  ], onConflict: 'person_id');

  @override
  Future<PaymentMethod?> methodOf(String riderId) async {
    final raw = await _db.rpc('payment_method_of', {'p_rider': riderId}) as String?;
    return raw == null ? null : PaymentMethod.parse(raw);
  }

  @override
  Future<String?> instapayHandleOf(String driverId) async =>
      await _db.rpc('instapay_handle_of', {'p_driver': driverId}) as String?;

  @override
  Future<void> setInstapayHandle(String driverId, String? handle) {
    final trimmed = handle?.trim() ?? '';
    return _db.upsert('payment_settings', [
      {'person_id': driverId, 'instapay_handle': trimmed.isEmpty ? null : trimmed},
    ], onConflict: 'person_id');
  }

  // Shares (007): the driver's marks and the rider's claims -------------------------

  static CashMark _mark(Row r) => CashMark(
    rideId: r['ride_id']! as String,
    riderId: r['rider_id']! as String,
    driverId: r['driver_id']! as String,
    outcome: CashOutcome.values.byName(r['outcome']! as String),
    amount: r['amount']! as int,
    date: CalendarDate.parse(r['ride_date']! as String),
  );

  @override
  Future<List<CashMark>> shareMarks(String rideId) async => [
    for (final r in await _db.select('share_marks', where: [Filter.eq('ride_id', rideId)])) _mark(r),
  ];

  /// The server keeps the 007 rule that only the ride's driver marks and a
  /// received share turns into "didn't pay" once; a refusal is ignored, as
  /// the fake ignores a mark `SharePolicy.canMark` rejects.
  @override
  Future<void> markShare(CashMark mark) async {
    try {
      await _db.rpc('wallet_mark_share', {
        'p_ride': mark.rideId,
        'p_rider': mark.riderId,
        'p_outcome': mark.outcome.name,
        'p_amount': mark.amount,
        'p_date': mark.date.toIso(),
      });
    } on BackendRefused {
      return;
    }
  }

  @override
  Future<void> claimPaid(String rideId, String riderId) async {
    try {
      await _db.rpc('wallet_claim_paid', {'p_ride': rideId});
    } on BackendRefused {
      return;
    }
  }

  Future<List<Share>> _shares(Filter who) async {
    final marks = await _db.select('share_marks', where: [who], orderBy: 'ride_date', descending: true);
    final claims = {for (final c in await _db.select('share_claims')) '${c['ride_id']}|${c['rider_id']}': c};
    return [
      for (final r in marks)
        Share(
          rideId: r['ride_id']! as String,
          riderId: r['rider_id']! as String,
          driverId: r['driver_id']! as String,
          otherFirstName: '',
          amount: r['amount']! as int,
          method: PaymentMethod.cash,
          tripEnd: WallTime(CalendarDate.parse(r['ride_date']! as String), const Clock.hm(0, 0)),
          status: switch (r['outcome']) {
            'received' => ShareStatus.received,
            _ when claims.containsKey('${r['ride_id']}|${r['rider_id']}') => ShareStatus.disputed,
            _ => ShareStatus.notReceived,
          },
          reversedOnce: (r['reversed_once'] as bool?) ?? false,
        ),
    ];
  }

  @override
  Future<List<Share>> openShares(String riderId) async {
    final all = await _shares(Filter.eq('rider_id', riderId));
    return [
      for (final s in all)
        if (s.status.isOpenDebt) s,
    ];
  }

  @override
  Future<List<Share>> driverShares(String driverId) => _shares(Filter.eq('driver_id', driverId));

  @override
  Future<Share?> driverShareOn(String rideId, String riderId) async {
    final mine = await driverShares(_db.userId ?? '');
    return mine.where((s) => s.rideId == rideId && s.riderId == riderId).firstOrNull;
  }

  @override
  Future<bool> disputeFlagged(String riderId) async {
    final marks = await _db.select(
      'share_marks',
      where: [Filter.eq('rider_id', riderId), Filter.eq('outcome', CashOutcome.didNotPay.name)],
    );
    final days = [for (final r in marks) SharePolicy.dayOf(CalendarDate.parse(r['ride_date']! as String))];
    return SharePolicy.disputeFlagged(days, SharePolicy.dayOf(_now().date));
  }

  // The ledger -------------------------------------------------------------------

  static ActivityEntry _entry(Row r) => ActivityEntry(
    id: r['id']! as String,
    kind: ActivityKind.values.byName(r['kind']! as String),
    amount: r['amount']! as int,
    date: CalendarDate.parse(r['entry_date']! as String),
    fee: (r['fee'] as int?) ?? 0,
    rideId: r['ride_id'] as String?,
    shareToDriver: (r['share_to_driver'] as int?) ?? 0,
    leg: r['leg'] == null ? null : Leg.values.byName(r['leg']! as String),
  );

  @override
  Future<Wallet> getWallet(String ownerId) async {
    final rows = await _db.select(
      'wallet_entries',
      where: [Filter.eq('person_id', ownerId)],
      orderBy: 'created_at',
      descending: true,
    );
    final month = _now().date;
    final role = _role();
    return Wallet(
      ownerId: ownerId,
      role: role,
      balance: rows.fold(0, (sum, r) => sum + (r['delta']! as int)),
      activity: [for (final r in rows) _entry(r)],
      method: role == MemberRole.rider ? await getMethod(ownerId) : null,
      feesThisMonth: rows
          .where((r) {
            final d = CalendarDate.parse(r['entry_date']! as String);
            return d.year == month.year && d.month == month.month;
          })
          .fold(0, (sum, r) => sum + ((r['fee'] as int?) ?? 0)),
      shares: role == MemberRole.rider ? await openShares(ownerId) : await driverShares(ownerId),
      bundleTripsLeft:
          (await _db.select('bundles', where: [Filter.eq('person_id', ownerId)])).length * 20 -
          rows.where((r) => r['kind'] == ActivityKind.bundleTrip.name).length,
    );
  }

  @override
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount}) async {
    if (await _provider.topUp(method: method, amount: amount) == PaymentResult.failure) return PaymentResult.failure;
    await _db.rpc('wallet_top_up', {'p_method': method, 'p_amount': amount});
    return PaymentResult.success;
  }

  @override
  Future<PaymentResult> withdraw(String ownerId, {required int amount}) async {
    if (await _provider.withdraw(amount: amount) == PaymentResult.failure) return PaymentResult.failure;
    try {
      await _db.rpc('wallet_withdraw', {'p_amount': amount});
    } on BackendRefused {
      return PaymentResult.failure;
    }
    return PaymentResult.success;
  }

  @override
  Future<PaymentResult> settle(String riderId, {required String method}) async {
    final owed = (await getWallet(riderId)).owed;
    if (owed == 0) return PaymentResult.success;
    if (await _provider.debit(amount: owed) == PaymentResult.failure) return PaymentResult.failure;
    await _db.rpc('wallet_settle', {'p_method': method});
    return PaymentResult.success;
  }

  @override
  Future<PaymentResult> buyBundle(String riderId, {required String method}) async {
    if (await _provider.debit(amount: 75) == PaymentResult.failure) return PaymentResult.failure;
    await _db.rpc('wallet_buy_bundle', {'p_method': method});
    return PaymentResult.success;
  }

  // SeatLedger (005 research R7) ----------------------------------------------------

  @override
  Future<void> debitSeat(
    String personId, {
    required String bookingId,
    required String rideId,
    required int fee,
    required int share,
    required CalendarDate date,
  }) => _db.rpc('wallet_seat_debit', {
    'p_booking': bookingId,
    'p_ride': rideId,
    'p_fee': fee,
    'p_share': share,
    'p_date': date.toIso(),
  });

  @override
  Future<void> refundSeat(
    String personId, {
    required String bookingId,
    required String rideId,
    required int amount,
    required CalendarDate date,
  }) async {
    if (amount == 0) return;
    await _db.rpc('wallet_seat_refund', {
      'p_booking': bookingId,
      'p_ride': rideId,
      'p_amount': amount,
      'p_date': date.toIso(),
    });
  }
}
