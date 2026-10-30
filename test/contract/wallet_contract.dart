import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_repository.dart';

/// A fresh wallet for one signed-in rider with no plan and no trips.
typedef WalletSetup = ({WalletRepository wallet, SeatLedger ledger, String me});

/// 011 contracts/seam-contracts.md — Wallet (W1–W8).
void walletContract(String label, Future<WalletSetup> Function() make) {
  final today = CalendarDate(2026, 11, 2);
  Future<int> balance(WalletSetup s) async => (await s.wallet.getWallet(s.me)).balance;
  Future<List<ActivityEntry>> activity(WalletSetup s) async => (await s.wallet.getWallet(s.me)).activity;

  group('wallet contract [$label]', () {
    test('W1 no plan to start with', () async {
      final s = await make();
      expect(await s.wallet.getPlan(s.me), isNull);
    });

    test('W2 the payment method round-trips', () async {
      final s = await make();
      await s.wallet.setMethod(s.me, PaymentMethod.instapay);
      expect(await s.wallet.getMethod(s.me), PaymentMethod.instapay);
    });

    test('W3 the InstaPay handle is trimmed; empty clears it', () async {
      final s = await make();
      await s.wallet.setInstapayHandle(s.me, '  omar@instapay  ');
      expect(await s.wallet.instapayHandleOf(s.me), 'omar@instapay');
      await s.wallet.setInstapayHandle(s.me, '');
      expect(await s.wallet.instapayHandleOf(s.me), isNull);
    });

    test('W4 a top-up raises the balance and leads the activity', () async {
      final s = await make();
      final before = await balance(s);
      expect(await s.wallet.topUp(s.me, method: 'card', amount: 100), PaymentResult.success);
      expect(await balance(s), before + 100);
      final top = (await activity(s)).first;
      expect((top.kind, top.amount), (ActivityKind.topUp, 100));
    });

    test('W5 a withdrawal lowers it', () async {
      final s = await make();
      await s.wallet.topUp(s.me, method: 'card', amount: 100);
      final before = await balance(s);
      expect(await s.wallet.withdraw(s.me, amount: 40), PaymentResult.success);
      expect(await balance(s), before - 40);
      expect((await activity(s)).first.kind, ActivityKind.withdrawal);
    });

    test('W6 monthly needs a top-up first, then subscribes and charges the price', () async {
      final s = await make();
      expect(await s.wallet.subscribe(s.me, PlanType.monthly, today: today), SubscribeResult.needsTopUp);
      expect(await s.wallet.getPlan(s.me), isNull);
      await s.wallet.topUp(s.me, method: 'card', amount: 200);
      final before = await balance(s);
      expect(await s.wallet.subscribe(s.me, PlanType.monthly, today: today), SubscribeResult.subscribed);
      final plan = await s.wallet.getPlan(s.me);
      expect(plan?.type, PlanType.monthly);
      expect(await balance(s), before - plan!.price);
    });

    test('W7 settling with nothing owed writes nothing', () async {
      final s = await make();
      await s.wallet.topUp(s.me, method: 'card', amount: 50);
      final rows = (await activity(s)).length;
      expect(await s.wallet.settle(s.me, method: 'card'), PaymentResult.success);
      expect((await activity(s)).length, rows);
    });

    test('W8 one seat row per booking; a zero refund writes none', () async {
      final s = await make();
      for (var i = 0; i < 2; i++) {
        await s.ledger.debitSeat(s.me, bookingId: 'b1', rideId: 'offer:t1', fee: 6, share: 60, date: today);
      }
      await s.ledger.refundSeat(s.me, bookingId: 'b1', rideId: 'offer:t1', amount: 0, date: today);
      final rows = await activity(s);
      expect(rows.where((e) => e.kind == ActivityKind.seatBooked), hasLength(1));
      expect(rows.where((e) => e.kind == ActivityKind.seatRefund), isEmpty);
    });
  });
}
