import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/daily/domain/privacy.dart';

void main() {
  const companies = [null, 'Vodafone', 'Valeo'];
  const compounds = [null, 'Beverly Hills', 'Zayed Dunes'];

  test('accepts: every pref × woman/man × company × compound', () {
    for (final ownerWoman in [true, false]) {
      for (final otherWoman in [true, false]) {
        for (final ownerCo in companies) {
          for (final otherCo in companies) {
            for (final ownerCp in compounds) {
              for (final otherCp in compounds) {
                final owner = PersonFacts(isWoman: ownerWoman, company: ownerCo, compound: ownerCp);
                final other = PersonFacts(isWoman: otherWoman, company: otherCo, compound: otherCp);
                final why = 'owner($ownerWoman,$ownerCo,$ownerCp) other($otherWoman,$otherCo,$otherCp)';
                expect(PrivacyRules.accepts(PrivacyPreference.verifiedUsers, owner, other), isTrue, reason: why);
                expect(PrivacyRules.accepts(PrivacyPreference.womenOnly, owner, other), otherWoman, reason: why);
                expect(PrivacyRules.accepts(PrivacyPreference.sameCompany, owner, other),
                    ownerCo != null && ownerCo == otherCo,
                    reason: why);
                expect(PrivacyRules.accepts(PrivacyPreference.sameCompound, owner, other),
                    ownerCp != null && ownerCp == otherCp,
                    reason: why);
              }
            }
          }
        }
      }
    }
  });

  group('available', () {
    test('verified users: always', () {
      expect(PrivacyRules.available(PrivacyPreference.verifiedUsers, const PersonFacts(isWoman: false)), isTrue);
    });

    test('women only: women only, and not even shown to men', () {
      const woman = PersonFacts(isWoman: true);
      const man = PersonFacts(isWoman: false);
      expect(PrivacyRules.available(PrivacyPreference.womenOnly, woman), isTrue);
      expect(PrivacyRules.available(PrivacyPreference.womenOnly, man), isFalse);
      expect(PrivacyRules.shown(PrivacyPreference.womenOnly, man), isFalse);
      expect(PrivacyRules.shown(PrivacyPreference.sameCompany, man), isTrue);
    });

    test('same company needs a verified work email (company set)', () {
      expect(PrivacyRules.available(PrivacyPreference.sameCompany, const PersonFacts(isWoman: false)), isFalse);
      expect(
        PrivacyRules.available(PrivacyPreference.sameCompany, const PersonFacts(isWoman: false, company: 'Valeo')),
        isTrue,
      );
    });

    test('same compound needs a compound', () {
      expect(PrivacyRules.available(PrivacyPreference.sameCompound, const PersonFacts(isWoman: true)), isFalse);
      expect(
        PrivacyRules.available(PrivacyPreference.sameCompound, const PersonFacts(isWoman: true, compound: 'Dunes')),
        isTrue,
      );
    });
  });
}
