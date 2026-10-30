import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/domain/company.dart';
import 'package:goora/features/company/domain/company_repository.dart';

/// [person] signs up someone new (with a verified work email when given) and
/// returns their id; [actAs] makes them the signed-in person.
typedef CompanySetup = ({
  CompanyRepository repo,
  Future<String> Function(String firstName, {String? workEmail}) person,
  void Function(String personId) actAs,
});

/// 011 contracts/seam-contracts.md — Company (K1–K7). The domains are made
/// up so they never meet the fake's seeded companies.
void companyContract(String label, Future<CompanySetup> Function() make) {
  final now = WallTime(CalendarDate(2026, 11, 2), const Clock.hm(9, 0));

  Future<(CompanySetup, String hr, Company)> registered() async {
    final s = await make();
    final hr = await s.person('Mona', workEmail: 'mona@acme-k.eg');
    s.actAs(hr);
    final r = await s.repo.register(
      personId: hr,
      name: 'Acme K',
      domains: ['acme-k.eg'],
      hrWorkEmail: 'mona@acme-k.eg',
      now: now,
    );
    return (s, hr, (r as Registered).company);
  }

  group('company contract [$label]', () {
    test('K1 a fresh domain registers as pending and is found by domain', () async {
      final (s, hr, company) = await registered();
      expect(company.status, CompanyStatus.pending);
      expect(company.hrContactId, hr);
      final found = await s.repo.companyForDomain('ACME-K.eg');
      expect((found?.id, found?.name, found?.status), (company.id, 'Acme K', CompanyStatus.pending));
    });

    test('K2 a taken domain, a public domain and an email off the domains are refused', () async {
      final (s, _, _) = await registered();
      final other = await s.person('Sara', workEmail: 'sara@acme-k.eg');
      s.actAs(other);
      Future<RegisterResult> reg(List<String> domains, String email) =>
          s.repo.register(personId: other, name: 'Second', domains: domains, hrWorkEmail: email, now: now);
      expect(await reg(['acme-k.eg'], 'sara@acme-k.eg'), isA<DomainTaken>());
      expect(await reg(['gmail.com'], 'sara@gmail.com'), isA<PublicDomain>());
      expect(await reg(['beta-k.eg'], 'sara@acme-k.eg'), isA<EmailNotOnDomain>());
    });

    test('K3 the HR contact has a company home; someone else has none', () async {
      final (s, hr, company) = await registered();
      final home = await s.repo.myCompanyAccount(hr, now);
      expect((home?.company.id, home?.status), (company.id, CompanyStatus.pending));
      final other = await s.person('Sara');
      s.actAs(other);
      expect(await s.repo.myCompanyAccount(other, now), isNull);
    });

    test('K4 no work email → NoWorkEmail; on a pending company → PendingCompany', () async {
      final (s, _, _) = await registered();
      final none = await s.person('Ali');
      s.actAs(none);
      expect(await s.repo.offerFor(none, now), isA<NoWorkEmail>());
      final staff = await s.person('Sara', workEmail: 'sara@acme-k.eg');
      s.actAs(staff);
      final offer = await s.repo.offerFor(staff, now);
      expect(offer, isA<PendingCompany>());
      expect((offer as PendingCompany).companyName, 'Acme K');
    });

    test('K5 someone never enrolled has not said yes to the HR statement', () async {
      final s = await make();
      final p = await s.person('Ali');
      s.actAs(p);
      expect(await s.repo.hrConsent(p), isFalse);
    });

    test('K6 HR adds a domain; a domain someone holds is refused', () async {
      final (s, hr, company) = await registered();
      await s.repo.addDomain(company.id, 'acme-k2.eg', now);
      expect((await s.repo.companyForDomain('acme-k2.eg'))?.id, company.id);
      expect(() => s.repo.addDomain(company.id, 'acme-k.eg', now), throwsStateError);
    });

    test('K7 never enrolled: hasEnrolled false, no coverage, no last leave', () async {
      final s = await make();
      final p = await s.person('Ali', workEmail: 'ali@acme-k.eg');
      s.actAs(p);
      expect(await s.repo.hasEnrolled(p), isFalse);
      expect(await s.repo.coverageFor(p, now), isEmpty);
      expect(await s.repo.lastLeave(p, now), isNull);
    });
  });
}
