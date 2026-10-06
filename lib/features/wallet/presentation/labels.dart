import '../../../core/l10n/app_localizations.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/activity_entry.dart';
import '../domain/plan.dart';

/// Turns wallet/plan domain values into localized text. Extended with
/// driver activity-kind labels in US3 (T038).
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

  /// `d/m`, Western digits in both locales — no month-name infra exists yet
  /// and this keeps "Free until {date}" locale-neutral without adding one.
  String shortDate(CalendarDate d) => '${d.day}/${d.month}';

  /// FR-005: the plan card's status line.
  String planStatusLine(Plan plan) {
    if (plan.type == PlanType.company) return planCompanyActive;
    final until = plan.untilDate;
    return until == null ? planActiveLine(plan.price) : planFreeUntil(shortDate(until), plan.price);
  }

  /// FR-007/FR-011: rider and driver activity-row labels. `feeReceived` is
  /// labelled by the rider whose charge reached the driver (AC4).
  String activityLabel(ActivityEntry entry) => switch (entry.kind) {
        ActivityKind.topUp => actTopUp,
        ActivityKind.tripDeduction => actTripDeduction,
        ActivityKind.lateCancelCharge => actLateCancelCharge,
        ActivityKind.freeCancelZero => actFreeCancelZero,
        ActivityKind.tripIncome => actTripIncome,
        ActivityKind.feeReceived => actFeeReceivedFrom(entry.otherPersonId ?? ''),
        ActivityKind.withdrawal => actWithdrawal,
      };
}
