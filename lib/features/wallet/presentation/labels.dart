import '../../../core/l10n/app_localizations.dart';
import '../domain/plan.dart';

/// Turns wallet/plan domain values into localized text. Extended with
/// activity-kind labels in US2.
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
}
