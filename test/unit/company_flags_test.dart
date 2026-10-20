import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/company/company_flags.dart';

/// 010 T002: open legal items stay off until research R0 is answered.
void main() {
  test('real company invoices are off (R0 a, c)', () {
    expect(CompanyFlags.companyInvoicesLive, isFalse);
  });

  test('HR statement export is off (R0 b)', () {
    expect(CompanyFlags.hrStatementExport, isFalse);
  });
}
