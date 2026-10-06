import '../../../core/time/calendar_date.dart';

enum PlanType { monthly, yearly, company }

enum PlanStatus { trialing, active, due }

/// A rider's subscription (data-model.md). Drivers have no [Plan].
final class Plan {
  const Plan({
    required this.personId,
    required this.type,
    required this.status,
    required this.price,
    this.untilDate,
  }) : assert(
          type != PlanType.company || (price == 0 && untilDate == null),
          'Company never trials or bills the rider (FR-003)',
        );

  final String personId;
  final PlanType type;
  final PlanStatus status;

  /// Whole EGP; 0 for Company.
  final int price;

  /// Free-until (trialing) or paid-until (active); null once due.
  final CalendarDate? untilDate;

  Map<String, Object?> toJson() => {
        'personId': personId,
        'type': type.name,
        'status': status.name,
        'price': price,
        'untilDate': untilDate?.toIso(),
      };

  static Plan fromJson(Map<String, Object?> j) => Plan(
        personId: j['personId']! as String,
        type: PlanType.values.byName(j['type']! as String),
        status: PlanStatus.values.byName(j['status']! as String),
        price: j['price']! as int,
        untilDate: j['untilDate'] == null ? null : CalendarDate.parse(j['untilDate']! as String),
      );
}
