import '../../../core/time/calendar_date.dart';
import 'plan.dart';

/// How a rider pays the driver, chosen once after joining a group (004 v2
/// US1). `wallet` gives up the cash trial.
enum PaymentMethod { cash, wallet }

/// Which price a rider sees and pays right now (FR-004).
enum PricingMode {
  cash,
  wallet,
  subscribed,
  company;

  bool get isFeeFree => this != wallet;

  /// A company plan or a paid-up subscription beats the method; cash only
  /// while the trial still allows it.
  static PricingMode of({
    required PaymentMethod? method,
    required Plan? plan,
    required CalendarDate today,
    required bool cashAvailable,
  }) {
    if (plan != null && plan.coversDate(today)) return plan.type == PlanType.company ? company : subscribed;
    if (method == PaymentMethod.cash && cashAvailable) return cash;
    return wallet;
  }
}
