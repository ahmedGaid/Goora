import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/wallet.dart';
import 'package:goora/features/wallet/domain/wallet_repository.dart';

/// A rider who rides one group (price 40, trip cost 160, 3 rider seats, driver
/// "Dina") and a way to finish group trips and to move "today".
typedef TripWorld = ({
  WalletRepository wallet,
  SeatLedger ledger,
  String me,
  Future<void> Function(Iterable<CalendarDate> days) finishTrips,
  void Function(CalendarDate today) setToday,
});

/// 013 wallet live-parity cases (WT1–WT8). Numbers: contribution 40, cash share
/// 40, Goora fee 4 (10%), the 5-trip fee-free trial, 150 / month-end 30 / 3-day
/// grace (008). The fake and the Supabase implementation must agree.
void walletTripsContract(String label, Future<TripWorld> Function() make) {
  final oct1 = CalendarDate(2026, 10, 1);
  CalendarDate day(int d) => CalendarDate(2026, 10, d);
  List<CalendarDate> days(int count) => [for (var i = 0; i < count; i++) day(4 + i)];

  Future<TripWorld> start({PaymentMethod method = PaymentMethod.cash}) async {
    final w = await make();
    w.setToday(oct1);
    await w.wallet.setMethod(w.me, method);
    return w;
  }

  /// Trip rows oldest first.
  List<ActivityEntry> tripRows(Wallet wallet) => [
    for (final e in wallet.activity.reversed)
      if (const {ActivityKind.cashTrip, ActivityKind.trip, ActivityKind.bundleTrip}.contains(e.kind)) e,
  ];

  group('wallet trips contract [$label]', () {
    test('WT1 the first five trips are fee-free cash trips', () async {
      final w = await start();
      await w.finishTrips(days(5));
      w.setToday(day(20));
      final wallet = await w.wallet.getWallet(w.me);
      expect(tripRows(wallet).map((e) => e.kind), List.filled(5, ActivityKind.cashTrip));
      expect(wallet.cashTrial?.tripsDone, 5);
      expect(wallet.cashTrial?.available, isFalse);
      expect(wallet.balance, 0);
      expect(wallet.feeDue, isNull);
    });

    test('WT2 the sixth trip pays Goora\'s 4 EGP fee', () async {
      final w = await start();
      await w.finishTrips(days(6));
      w.setToday(day(20));
      final wallet = await w.wallet.getWallet(w.me);
      expect(tripRows(wallet).map((e) => e.kind), [...List.filled(5, ActivityKind.cashTrip), ActivityKind.trip]);
      expect(tripRows(wallet).last.fee, 4);
      expect(tripRows(wallet).last.shareToDriver, 40);
      expect(wallet.balance, -4);
      expect(wallet.owed, 4);
      expect(wallet.feesThisMonth, 4);
    });

    test('WT3 owing 150 is due that day and overdue after three days of grace', () async {
      final w = await start();
      w.setToday(day(12));
      await w.ledger.debitSeat(w.me, bookingId: 'big', rideId: 'offer:big', fee: 150, share: 0, date: day(12));
      w.setToday(day(14));
      var wallet = await w.wallet.getWallet(w.me);
      expect((wallet.feeDue, wallet.feeOverdue), (day(12), false));
      w.setToday(day(15));
      wallet = await w.wallet.getWallet(w.me);
      expect((wallet.feeDue, wallet.feeOverdue), (day(12), true));
    });

    test('WT4 30 or more owed at a month end is due on the 1st; less carries over', () async {
      final w = await start();
      w.setToday(CalendarDate(2026, 9, 20));
      await w.ledger.debitSeat(w.me, bookingId: 'a', rideId: 'offer:a', fee: 30, share: 0, date: CalendarDate(2026, 9, 20));
      w.setToday(day(2));
      expect((await w.wallet.getWallet(w.me)).feeDue, oct1);

      final v = await start();
      v.setToday(CalendarDate(2026, 9, 20));
      await v.ledger.debitSeat(v.me, bookingId: 'b', rideId: 'offer:b', fee: 29, share: 0, date: CalendarDate(2026, 9, 20));
      v.setToday(day(2));
      expect((await v.wallet.getWallet(v.me)).feeDue, isNull);
    });

    test('WT5 a bought bundle covers the paid trips, not the balance', () async {
      final w = await start();
      await w.wallet.buyBundle(w.me, method: 'card');
      await w.finishTrips(days(7));
      w.setToday(day(20));
      final wallet = await w.wallet.getWallet(w.me);
      expect(tripRows(wallet).map((e) => e.kind), [...List.filled(5, ActivityKind.cashTrip), ...List.filled(2, ActivityKind.bundleTrip)]);
      expect(wallet.balance, 0);
      expect(wallet.bundleTripsLeft, 18);
    });

    test('WT6 a share shows the driver\'s first name and the rider\'s real method', () async {
      final w = await start(method: PaymentMethod.instapay);
      await w.finishTrips([day(4)]);
      w.setToday(day(4));
      final shares = (await w.wallet.getWallet(w.me)).shares;
      expect(shares, hasLength(1));
      final s = shares.single;
      expect((s.otherFirstName, s.method, s.amount, s.riderId), ('Dina', PaymentMethod.instapay, 40, w.me));
    });

    test('WT7 no activity row ever reads as driver income (Law 87/2018)', () async {
      final w = await start();
      await w.finishTrips([day(4)]);
      w.setToday(day(4));
      final wallet = await w.wallet.getWallet(w.me);
      expect(wallet.activity.map((e) => e.kind), isNot(contains(ActivityKind.tripIncome)));
      expect(wallet.activity.map((e) => e.kind), isNot(contains(ActivityKind.feeReceived)));
      expect(wallet.activity.map((e) => e.kind), isNot(contains(ActivityKind.cashReceived)));
    });

    test('WT8 trips before the method was chosen are not charged', () async {
      final w = await make();
      w.setToday(day(20));
      await w.wallet.setMethod(w.me, PaymentMethod.cash);
      await w.finishTrips(days(7));
      final wallet = await w.wallet.getWallet(w.me);
      expect(tripRows(wallet), isEmpty);
      expect(wallet.balance, 0);
    });
  });
}
