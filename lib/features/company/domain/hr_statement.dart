import 'dart:convert';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../wallet/domain/direct_pay.dart';
import 'company_rules.dart';
import 'enrollment.dart';
import 'hr_views.dart';

/// One change of an employee's HR-statement consent (data-model.md
/// "HR-statement consent"). The history, not a flag, so a month already
/// issued stays the same after a later withdrawal (FR-027).
final class ConsentChange {
  const ConsentChange({required this.on, required this.at});

  final bool on;
  final WallTime at;

  Map<String, Object?> toJson() => {'on': on, 'at': at.toJson()};

  static ConsentChange fromJson(Map<String, Object?> j) =>
      ConsentChange(on: j['on']! as bool, at: WallTime.fromJson(j['at']! as String));

  @override
  bool operator ==(Object other) => other is ConsentChange && other.on == on && other.at == at;

  @override
  int get hashCode => Object.hash(on, at);
}

/// One share of one trip, as the statement's source sees it: never shown to
/// HR as it is — only the [StatementLine] built from it, and only for an
/// employee who agreed (research R6).
final class TripShare {
  const TripShare({
    required this.personId,
    required this.date,
    required this.leg,
    required this.sharePaid,
    required this.status,
    required this.asRider,
  });

  final String personId;
  final CalendarDate date;
  final Leg leg;

  /// Whole EGP paid straight to the driver.
  final int sharePaid;
  final ShareStatus status;

  /// False for a trip the employee drove: a driver pays no share (US6 AC6).
  final bool asRider;
}

/// The HR statement's pure rules (US6, FR-024–FR-028, Q7).
abstract final class HrStatement {
  /// The moment a month's consent is read: 00:00 on the 1st of the next
  /// month (data-model.md).
  static WallTime monthEnd(String month) {
    final p = month.split('-').map(int.parse).toList();
    return WallTime(CalendarDate(p[0], p[1], 1).addMonths(1), const Clock.hm(0, 0));
  }

  /// Whether the last change at or before [at] was "on". No history = off.
  static bool consentOn(List<ConsentChange> history, WallTime at) {
    ConsentChange? last;
    for (final c in history) {
      if (c.at.isAfter(at)) continue;
      if (last == null || !c.at.isBefore(last.at)) last = c;
    }
    return last?.on ?? false;
  }

  /// Shares that count: the driver said "received", or 24 hours passed with
  /// no answer. Pending, "didn't pay" and disputed never do (Q7).
  static bool counts(ShareStatus s) => s == ShareStatus.received || s == ShareStatus.autoReceived;

  /// The statement of [month] (`yyyy-mm`): for each employee enrolled and
  /// consenting at the end of the month, their rider trips of that month
  /// whose share counts. Everyone else is absent entirely — not even a name
  /// (FR-028). Sorted by name, date, then going before return.
  static List<StatementLine> build({
    required String month,
    required List<Enrollment> enrollments,
    required Map<String, List<ConsentChange>> consent,
    required List<TripShare> shares,
  }) {
    final end = monthEnd(month);
    final minute = SharePolicy.minuteOf(end);
    final names = <String, String>{};
    for (final e in enrollments) {
      if (!CompanyRules.covered([e.window], minute)) continue;
      if (!consentOn(consent[e.personId] ?? const [], end)) continue;
      names[e.personId] = e.name;
    }
    final lines =
        [
          for (final s in shares)
            if (s.asRider && counts(s.status) && s.date.monthKey == month && names.containsKey(s.personId))
              StatementLine(name: names[s.personId]!, date: s.date, leg: s.leg, sharePaid: s.sharePaid),
        ]..sort((a, b) {
          final byName = a.name.compareTo(b.name);
          if (byName != 0) return byName;
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.leg.index.compareTo(b.leg.index);
        });
    return lines;
  }

  static String historyToJson(List<ConsentChange> history) => jsonEncode([for (final c in history) c.toJson()]);

  static List<ConsentChange> historyFromJson(String raw) => [
    for (final j in jsonDecode(raw) as List) ConsentChange.fromJson((j as Map).cast<String, Object?>()),
  ];
}
