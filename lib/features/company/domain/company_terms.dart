/// The commercial numbers a founder answer would change (spec Q1, Q3, Q4;
/// research R0 and the "Lane B notes" list). One constant each: a new answer
/// edits this file only. Issued invoices keep the price they were issued at.
///
/// The rule constants (due days, grace days, k = 5) are in `CompanyRules`,
/// because the server twin must use the same values.
abstract final class CompanyTerms {
  /// Q1 default: EGP per enrolled employee per month (brief §5 D says 75).
  static const pricePerSeat = 99;

  /// Q3 default: billed seats never go below this, even with fewer enrolled.
  static const minimumSeats = 20;

  /// Q4 default: annual contract, invoiced monthly.
  static const contractMonths = 12;

  /// Q4 default: notice to end. Stored for the paper contract only; the app
  /// ends a contract when Goora staff do (demo action) or when it runs out.
  static const noticeDays = 30;

  /// Goora's bank details on every invoice (research R4). Null until the
  /// founder supplies the real ones; the invoice screen then shows a line in
  /// its own language (`companyInvoiceBankPlaceholder`, walk 6 N-14).
  static const String? bankDetails = null;
}
