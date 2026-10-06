import '../../../core/time/calendar_date.dart';
import 'trust.dart';

/// Reliability % (FR-036, research R4). Mirrored in
/// `supabase/functions/_shared/reliability.ts`.
///
/// Over the 30 days before [today] (today itself excluded): every event is
/// one booked trip; a no-show misses 1, a late cancel or late "can't drive"
/// misses 0.5, free cancels are not booked at all (they leave no event).
/// percent = round half up of (booked − missed) ÷ booked × 100; no booked
/// trips → 100. The month counts are this calendar month's and reset on the
/// 1st; the % does not.
abstract final class ReliabilityRules {
  static const windowDays = 30;

  static Reliability compute(List<ReliabilityEvent> events, CalendarDate today) {
    final from = today.addDays(-windowDays);
    var booked = 0;
    var missedHalves = 0;
    for (final e in events) {
      if (e.date.isBefore(from) || !e.date.isBefore(today)) continue;
      booked++;
      missedHalves += switch (e.kind) {
        ReliabilityEventKind.kept => 0,
        ReliabilityEventKind.noShow => 2,
        ReliabilityEventKind.lateCancel || ReliabilityEventKind.lateCantDrive => 1,
      };
    }
    final month = [for (final e in events) if (e.date.monthKey == today.monthKey) e.kind];
    return Reliability(
      percent: percent(booked: booked, missedHalves: missedHalves),
      monthLateCancels: month
          .where((k) => k == ReliabilityEventKind.lateCancel || k == ReliabilityEventKind.lateCantDrive)
          .length,
      monthNoShows: month.where((k) => k == ReliabilityEventKind.noShow).length,
    );
  }

  /// Exact integer arithmetic in half trips, so x.5 always rounds up.
  static int percent({required int booked, required int missedHalves}) {
    if (booked == 0) return 100;
    final bookedHalves = 2 * booked;
    final keptHalves = (bookedHalves - missedHalves).clamp(0, bookedHalves);
    return ((200 * keptHalves + bookedHalves) ~/ (2 * bookedHalves)).clamp(0, 100);
  }
}
