import '../../../core/time/calendar_date.dart';

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

  /// The day the plan began; trips before it keep the fee they were charged.
  /// Null only for plans stored by v1.
  final CalendarDate? startDate;

  /// Paid-until; null for Company.
  final CalendarDate? untilDate;

  /// Whether a trip on [date] is fee-free under this plan.
  bool coversDate(CalendarDate date) {
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (type == PlanType.company) return true;
    return status == PlanStatus.active && untilDate != null && !date.isAfter(untilDate!);
  }

  Map<String, Object?> toJson() => {
        'personId': personId,
        'type': type.name,
        'status': status.name,
        'price': price,
        'startDate': startDate?.toIso(),
        'untilDate': untilDate?.toIso(),
      };

  /// v1 stored `trialing`; there is no trial in v2, so it reads as `due` (back
  /// to pay per trip) rather than failing to parse.
  static Plan fromJson(Map<String, Object?> j) => Plan(
        personId: j['personId']! as String,
        type: PlanType.values.byName(j['type']! as String),
        status: switch (j['status']) { 'active' => PlanStatus.active, _ => PlanStatus.due },
        price: j['price']! as int,
        startDate: j['startDate'] == null ? null : CalendarDate.parse(j['startDate']! as String),
        untilDate: j['untilDate'] == null ? null : CalendarDate.parse(j['untilDate']! as String),
      );
}
