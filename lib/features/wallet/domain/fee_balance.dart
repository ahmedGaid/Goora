import '../../../core/time/calendar_date.dart';

/// One end-of-day reading of the rider's Goora ledger (below zero = owed).
typedef DayBalance = ({CalendarDate date, int balance});

/// When Goora's own owed fees fall due and when they block booking (008
/// research R2). Twin of supabase/functions/_shared/fee_balance.ts — both run
/// test/fixtures/fee_balance_vectors.json.
abstract final class FeeBalancePolicy {
  /// Owing this much makes the balance due that day.
  static const settleAt = 150;

  /// At a month end, owing at least this much makes it due on the 1st;
  /// less carries over.
  static const monthEndMin = 30;

  /// Days after the due date before booking is blocked.
  static const graceDays = 3;

  /// The day the current unpaid run fell due, or null. [days] is ascending
  /// by date; readings after [today] are ignored.
  static CalendarDate? dueDate(List<DayBalance> days, CalendarDate today) {
    final seen = [for (final d in days) if (!d.date.isAfter(today)) d];
    if (seen.isEmpty || seen.last.balance >= 0) return null;
    var start = 0;
    for (var i = 0; i < seen.length; i++) {
      if (seen[i].balance >= 0) start = i + 1;
    }
    final run = seen.sublist(start);

    CalendarDate? due150;
    for (final d in run) {
      if (-d.balance >= settleAt) {
        due150 = d.date;
        break;
      }
    }

    CalendarDate? dueMonth;
    var monthStart = CalendarDate(run.first.date.year, run.first.date.month, 1);
    while (true) {
      final next = monthStart.addMonths(1);
      if (next.isAfter(today)) break;
      final monthEnd = next.addDays(-1);
      final atEnd = run.lastWhere((d) => !d.date.isAfter(monthEnd));
      if (-atEnd.balance >= monthEndMin) {
        dueMonth = next;
        break;
      }
      monthStart = next;
    }

    if (due150 == null) return dueMonth;
    if (dueMonth == null) return due150;
    return due150.isBefore(dueMonth) ? due150 : dueMonth;
  }

  /// [graceDays] after the due date, an unpaid balance blocks booking.
  static bool isOverdue(CalendarDate? due, CalendarDate today) => due != null && due.daysUntil(today) >= graceDays;
}

/// The 20-trip bundle (008 research R3): 75 EGP once, never expires, covers
/// Goora's fee only.
abstract final class TripBundle {
  static const price = 75;
  static const trips = 20;

  /// A bundle trip is used only on a trip that would carry a fee.
  static bool useBundle(int fee, int tripsLeft) => fee > 0 && tripsLeft > 0;
}
