import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';

enum PlanType { monthly, yearly, company }

/// `due` = the paid period is over; the rider pays per trip again (v2, no
/// trial).
enum PlanStatus { active, due }

/// A rider's optional subscription (data-model.md). Drivers have no [Plan].
final class Plan {
  const Plan({
    required this.personId,
    required this.type,
    required this.status,
    required this.price,
    this.startDate,
    this.untilDate,
  }) : assert(
          type != PlanType.company || (price == 0 && untilDate == null),
          'Company never bills the rider',
        );

  final String personId;
  final PlanType type;
  final PlanStatus status;

  /// Whole EGP; 0 for Company.
  final int price;

  /// The exact moment the plan began; trips that already settled before it
  /// keep the fee they were charged, even same-day (research R14 — this needs
  /// time-of-day, not just the date, or subscribing mid-day would retroactively
  /// waive a fee already collected earlier that day). Null only for plans
  /// stored by v1.
  final WallTime? startDate;

  /// Paid-until; null for Company.
  final CalendarDate? untilDate;

  /// Whether a trip happening "today" is fee-free under this plan — for
  /// forward-looking pricing (the Today tile, the pay-method screen), where
  /// day granularity is right: once subscribed, every trip for the rest of
  /// today is covered.
  bool coversDate(CalendarDate date) {
    if (startDate != null && date.isBefore(startDate!.date)) return false;
    if (type == PlanType.company) return true;
    return status == PlanStatus.active && untilDate != null && !date.isAfter(untilDate!);
  }

  /// Whether a trip that settled at [at] was already fee-free — for deriving
  /// past wallet activity, where a trip settled before the exact subscribe
  /// moment must keep the fee it was charged, even if that was earlier the
  /// same day.
  bool coversTrip(WallTime at) {
    if (startDate != null && at.isBefore(startDate!)) return false;
    if (type == PlanType.company) return true;
    return status == PlanStatus.active && untilDate != null && !at.date.isAfter(untilDate!);
  }

  Map<String, Object?> toJson() => {
        'personId': personId,
        'type': type.name,
        'status': status.name,
        'price': price,
        'startDate': startDate?.toJson(),
        'untilDate': untilDate?.toIso(),
      };

  /// v1 stored `trialing`; there is no trial in v2, so it reads as `due` (back
  /// to pay per trip) rather than failing to parse. v1 also stored `startDate`
  /// as a bare date; read that as midnight so an old plan still parses.
  static Plan fromJson(Map<String, Object?> j) => Plan(
        personId: j['personId']! as String,
        type: PlanType.values.byName(j['type']! as String),
        status: switch (j['status']) { 'active' => PlanStatus.active, _ => PlanStatus.due },
        price: j['price']! as int,
        startDate: switch (j['startDate']) {
          null => null,
          final String s when s.contains('T') => WallTime.fromJson(s),
          final String s => WallTime(CalendarDate.parse(s), const Clock.hm(0, 0)),
          _ => null,
        },
        untilDate: j['untilDate'] == null ? null : CalendarDate.parse(j['untilDate']! as String),
      );
}
