import '../../../core/l10n/app_localizations.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/activity_entry.dart';
import '../domain/payment_method.dart';
import '../domain/plan.dart';

/// Turns wallet/plan domain values into localized text.
extension WalletLabels on AppLocalizations {
  String planTypeTitle(PlanType type) => switch (type) {
        PlanType.monthly => planMonthlyTitle,
        PlanType.yearly => planYearlyTitle,
        PlanType.company => planCompanyTitle,
      };

  String planTypeSub(PlanType type) => switch (type) {
        PlanType.monthly => planMonthlySub,
        PlanType.yearly => planYearlySub,
        PlanType.company => planCompanySub,
      };

  /// `d/m`, Western digits in both locales — no month-name infra exists yet.
  String shortDate(CalendarDate d) => '${d.day}/${d.month}';

  /// FR-004: the one price line for a trip, by the rider's arrangement.
  String priceLine(int contribution, PricingMode mode, {required int fee}) => switch (mode) {
        PricingMode.wallet => fee == 0 ? priceNoFee(contribution) : priceWithFee(contribution, fee),
        PricingMode.subscribed => priceSubscribed(contribution),
        PricingMode.company => priceCompany(contribution),
        PricingMode.cash => priceCash(contribution),
      };

  String activityLabel(ActivityEntry entry) => switch (entry.kind) {
        ActivityKind.topUp => actTopUp,
        ActivityKind.tripDeduction => actTripDeduction,
        ActivityKind.lateCancelCharge => actLateCancelCharge,
        ActivityKind.freeCancelZero => actFreeCancelZero,
        ActivityKind.tripIncome => actTripIncome,
        ActivityKind.feeReceived => actFeeReceivedFrom(entry.otherPersonId ?? ''),
        ActivityKind.withdrawal => actWithdrawal,
        ActivityKind.trip => actTrip,
        ActivityKind.cashTrip => actCashTrip,
        ActivityKind.subscription => actSubscription,
        ActivityKind.cashReceived => cashMarkedReceived,
      };

  /// The second line under a row: each trip's fee on its own (FR-011).
  String? activityCaption(ActivityEntry entry, {required int contribution}) {
    if (entry.notCollected) return notChargedCash;
    return switch (entry.kind) {
      ActivityKind.trip => entry.fee > 0 ? priceWithFee(entry.toDriver, entry.fee) : breakdownNoFee,
      ActivityKind.cashTrip => cashPaidLine(contribution),
      _ => null,
    };
  }
}
