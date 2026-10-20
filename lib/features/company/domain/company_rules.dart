/// Half-open `[from, to)` on the shared minute scale (`SharePolicy.minuteOf`);
/// `to == null` = still open.
typedef Window = ({int from, int? to});

/// The company network's money rules (010 research R3,
/// contracts/company-rules.md). Twin of supabase/functions/_shared/company.ts —
/// both run test/fixtures/company_vectors.json. Minutes and days are on the
/// shared scale of `SharePolicy` (days since 2000-01-01), so both sides
/// compare the same integers.
///
/// The three constants are founder defaults (spec Q10 and the k = 5
/// clarification), one place each; the commercial defaults (price, minimum,
/// contract length) are in `CompanyTerms`.
abstract final class CompanyRules {
  /// Q10 default: unpaid this many full days after the due day → suspended.
  static const graceDays = 7;

  /// Q10 default: due this many days after the 1st the invoice is issued on.
  static const dueAfterDays = 15;

  /// Spec clarification: any figure built from fewer people shows "fewer
  /// than 5", so one person can't be singled out.
  static const suppressBelow = 5;

  static const _minutesPerDay = 24 * 60;

  /// Enrollment windows ∩ company active windows, merged, sorted.
  static List<Window> coverage(List<Window> enrolled, List<Window> companyActive) {
    final pieces = <Window>[];
    for (final a in enrolled) {
      for (final b in companyActive) {
        final lo = a.from > b.from ? a.from : b.from;
        final hi = _min(a.to, b.to);
        if (hi == null || hi > lo) pieces.add((from: lo, to: hi));
      }
    }
    return _merge(pieces);
  }

  /// [minute] inside any window.
  static bool covered(List<Window> windows, int minute) =>
      windows.any((w) => w.from <= minute && (w.to == null || minute < w.to!));

  /// For each day of [monthFromDay, monthToDay): distinct people enrolled at
  /// any moment of that day; the max over the month's days (spec Q2, FR-010:
  /// "on any day"). One person counts once per day however many windows.
  static int peakEnrolled(Map<String, List<Window>> byPerson, int monthFromDay, int monthToDay) {
    var best = 0;
    for (var d = monthFromDay; d < monthToDay; d++) {
      final lo = d * _minutesPerDay;
      final hi = lo + _minutesPerDay;
      final n = byPerson.values
          .where((ws) => ws.any((w) => !_isEmpty(w) && w.from < hi && (w.to == null || w.to! > lo)))
          .length;
      if (n > best) best = n;
    }
    return best;
  }

  /// Q2/Q3 default: the minimum is a floor, never pro-rated.
  static int billedSeats(int peak, int minimumSeats) => peak > minimumSeats ? peak : minimumSeats;

  /// Whole EGP; VAT is pending (research R0 c).
  static int invoiceTotal(int billedSeats, int pricePerSeat) => billedSeats * pricePerSeat;

  static int dueDay(int issueDay) => issueDay + dueAfterDays;

  /// The first day without coverage, from 00:00: the [graceDays] after the
  /// due day are still covered (issued 1 Nov → due 16 Nov → 24 Nov).
  static int suspendFromDay(int dueDay) => dueDay + graceDays + 1;

  /// Active windows = [approvedAt, endedAt) minus every [suspendFrom, paidAt)
  /// of an invoice still unpaid at its suspendFrom. Overlapping suspensions
  /// join, so coverage returns only once every overdue invoice is paid
  /// (FR-014).
  static List<Window> activeWindows({
    required int approvedAt,
    int? endedAt,
    required List<({int suspendFrom, int? paidAt})> overdue,
  }) {
    final gaps = _merge([
      for (final o in overdue)
        if (o.paidAt == null || o.paidAt! > o.suspendFrom) (from: o.suspendFrom, to: o.paidAt),
    ]);
    final out = <Window>[];
    var cur = approvedAt;
    var open = true; // false once a gap runs to the end of time
    for (final g in gaps) {
      if (endedAt != null && g.from >= endedAt) break;
      if (g.from > cur) out.add((from: cur, to: g.from));
      if (g.to == null) {
        open = false;
        break;
      }
      if (g.to! > cur) cur = g.to!;
      if (endedAt != null && cur >= endedAt) {
        open = false;
        break;
      }
    }
    if (open && (endedAt == null || cur < endedAt)) out.add((from: cur, to: endedAt));
    return out;
  }

  /// null = "fewer than 5".
  static int? suppress(int count) => count < suppressBelow ? null : count;

  static bool _isEmpty(Window w) => w.to != null && w.to! <= w.from;

  /// null = open, so it is the larger.
  static int? _min(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a < b ? a : b;
  }

  /// Sorted; overlapping or touching windows joined; empty ones dropped.
  static List<Window> _merge(List<Window> windows) {
    final sorted = windows.where((w) => !_isEmpty(w)).toList()
      ..sort((a, b) {
        final byFrom = a.from.compareTo(b.from);
        if (byFrom != 0) return byFrom;
        if (a.to == b.to) return 0;
        if (a.to == null) return 1;
        if (b.to == null) return -1;
        return a.to!.compareTo(b.to!);
      });
    final out = <Window>[];
    for (final w in sorted) {
      if (out.isNotEmpty && (out.last.to == null || w.from <= out.last.to!)) {
        final last = out.removeLast();
        out.add((from: last.from, to: last.to == null || w.to == null ? null : (w.to! > last.to! ? w.to : last.to)));
      } else {
        out.add(w);
      }
    }
    return out;
  }
}
