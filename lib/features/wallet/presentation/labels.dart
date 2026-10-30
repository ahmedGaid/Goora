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

  /// The day and the month's name ("3 يناير", "3 Jan"), Western digits in both
  /// locales: "3/1" read as 1 March to many readers (walk nit N-7).
  String shortDate(CalendarDate d) => dayAndMonth(d.day, '${d.month}');

  /// The day, the month's name and the year ("1 Sep 2026", "1 سبتمبر 2026"):
  /// for the company screens, where a span can cross a year (a 12-month
  /// contract). Never `d/m/yyyy`: "1/9/2026" read as 9 January (walk 6 F-W6).
  String shortDateYear(CalendarDate d) => dayMonthYear(d.day, '${d.month}', d.year);

  /// FR-004, 007 FR-014: the one price line for a trip. It always names the
  /// share as going to the driver directly; Goora's fee, when there is one,
  /// is its own part. The trial reads how the rider pays the driver.
  String priceLine(SeatPrice price) => switch (price.mode) {
        PricingMode.trial =>
          price.method == PaymentMethod.instapay ? priceInstapay(price.share) : priceCash(price.share),
        PricingMode.perTrip => price.fee == 0 ? priceNoFee(price.share) : priceWithFee(price.share, price.fee),
        PricingMode.subscribed => priceSubscribed(price.share),
        PricingMode.company => priceCompany(price.share),
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
        ActivityKind.seatBooked => actSeatBooked,
        ActivityKind.seatRefund => actSeatRefund,
        ActivityKind.settlement => actSettlement,
        ActivityKind.bundle => actBundle,
        ActivityKind.bundleTrip => actBundleTrip,
      };

  /// The second line under a row: each trip's fee on its own (FR-011).
  String? activityCaption(ActivityEntry entry, {required int contribution}) {
    if (entry.notCollected) return notChargedCash;
    return switch (entry.kind) {
      ActivityKind.trip || ActivityKind.seatBooked =>
        entry.fee > 0 ? priceWithFee(entry.toDriver, entry.fee) : priceNoFee(entry.toDriver),
      ActivityKind.cashTrip => cashPaidLine(entry.shareToDriver > 0 ? entry.shareToDriver : contribution),
      ActivityKind.bundleTrip => cashPaidLine(entry.shareToDriver),
      ActivityKind.lateCancelCharge || ActivityKind.tripDeduction when entry.shareToDriver > 0 =>
        cashPaidLine(entry.shareToDriver),
      _ => null,
    };
  }
}
