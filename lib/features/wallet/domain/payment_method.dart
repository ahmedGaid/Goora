import '../../../core/time/wall_time.dart';
import 'plan.dart';

/// How a rider pays the driver their share — directly, outside Goora (007
/// FR-013). A label and a hint for the driver; Goora never moves this money.
enum PaymentMethod {
  cash,
  instapay;

  /// 004 stored `wallet` (pay the driver through Goora); it no longer exists,
  /// so it reads as cash (007 research R6).
  static PaymentMethod parse(String raw) => raw == instapay.name ? instapay : cash;
}

/// Which of Goora's own prices a rider pays right now (004 FR-004, 007 R6).
/// The driver's share is the same in every mode; only Goora's fee changes.
enum PricingMode {
  /// The first trips of every new rider: no Goora fee, no method needed.
  trial,

  /// Goora's service fee on each trip.
  perTrip,
  subscribed,
  company;

  bool get isFeeFree => this != perTrip;

  /// A company plan or a paid-up subscription beats the trial; the trial
  /// lasts while CashTrialPolicy allows it. Judged at the exact moment [now]
  /// (010 research R2): Wallet and Today stop saying "Company" the minute
  /// someone leaves or their company is suspended, same day.
  static PricingMode of({
    required Plan? plan,
    required WallTime now,
    required bool trialAvailable,
  }) {
    if (plan != null && plan.coversTrip(now)) return plan.type == PlanType.company ? company : subscribed;
    if (trialAvailable) return trial;
    return perTrip;
  }
}
