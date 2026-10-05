import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';

void main() {
  group('PhoneNumber.tryParse accepts every form of one Egyptian mobile', () {
    const forms = [
      '01012345678',
      '+201012345678',
      '00201012345678',
      '201012345678',
      '010 1234 5678',
      '+20 101-234-5678',
      '(010) 12345678',
    ];
    for (final f in forms) {
      test(f, () => expect(PhoneNumber.tryParse(f)?.e164, '+201012345678'));
    }
  });

  test('all four operator prefixes are accepted', () {
    for (final p in ['010', '011', '012', '015']) {
      expect(PhoneNumber.tryParse('${p}12345678'), isNotNull, reason: p);
    }
  });

  test('rejects non-mobile prefixes, wrong lengths and letters', () {
    for (final bad in ['', '013 1234 5678', '01412345678', '0101234567', '010123456789', '0221234567', '01O12345678', '+1 0101234567']) {
      expect(PhoneNumber.tryParse(bad), isNull, reason: bad);
    }
  });

  test('local form and equality', () {
    final a = PhoneNumber.tryParse('+201112345678')!;
    expect(a.local, '01112345678');
    expect(a, PhoneNumber.tryParse('01112345678'));
  });
}
