/// Feature flags for the company network's open legal items (010 research
/// R0). The constitution keeps anything a lawyer or accountant has not yet
/// answered behind a flag that is off. They live here, not in
/// `lib/core/config/env.dart`, so this feature adds files only until 006
/// merges (research R0 note); move them next to [Env] then if preferred.
///
/// Plain constants, not `--dart-define`s: turning one on must be a reviewed
/// code change made after the matching answer is written in research R0.
abstract final class CompanyFlags {
  /// Real invoice issuing (ETA e-invoice, VAT). Off: invoices are records in
  /// the fakes only. Waits for R0 a (Law 87/2018) and R0 c (e-invoice, VAT).
  static const companyInvoicesLive = false;

  /// Exporting or sharing the HR statement out of the app. Off: the statement
  /// is only shown in-app. Waits for R0 b (Law 151/2020 consent).
  static const hrStatementExport = false;
}
