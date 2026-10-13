import '../../../core/l10n/app_localizations.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/activity_entry.dart';
import '../domain/payment_method.dart';
import '../domain/plan.dart';
import '../domain/seat_price.dart';

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
  /// Cash reads the rounded cash amount (005 FR-029); when no cash amount
  /// fits, the quote is the wallet price and so is the line.
  String priceLine(SeatPrice price) => switch (price.mode) {
        PricingMode.cash when price.cashOffered => priceCash(price.cash!),
        PricingMode.wallet || PricingMode.cash =>
          price.fee == 0 ? priceNoFee(price.contribution) : priceWithFee(price.contribution, price.fee),
        PricingMode.subscribed => priceSubscribed(price.contribution),
        PricingMode.company => priceCompany(price.contribution),
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
