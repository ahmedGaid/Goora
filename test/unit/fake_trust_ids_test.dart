import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 011 Finding F1: contact ids came from the microsecond clock, so two adds
/// inside one clock tick got the same id. Ids must differ with no pause.
void main() {
  test('contacts added back to back never share an id', () async {
    SharedPreferences.setMockInitialValues({});
    final person = Profile(
      phone: PhoneNumber.tryParse('01001234567')!,
      firstName: 'Omar',
      lastName: 'K',
      gender: Gender.male,
    );
    final repo = FakeTrustRepository(
      await SharedPreferences.getInstance(),
      person: () => person,
      now: () => WallTime.fromJson('2026-11-02T08:00:00'),
    );
    final phone = PhoneNumber.tryParse('01011111111')!;

    final seen = <String>{};
    for (var i = 0; i < 400; i++) {
      await repo.addContact('A', phone);
      final added = (await repo.contacts()).last;
      expect(seen.add(added.id), isTrue, reason: 'id ${added.id} repeated on add #$i');
      await repo.removeContact(added.id);
    }
  });

  test('three adds in a row keep three distinct ids', () async {
    SharedPreferences.setMockInitialValues({});
    final person = Profile(
      phone: PhoneNumber.tryParse('01001234567')!,
      firstName: 'Omar',
      lastName: 'K',
      gender: Gender.male,
    );
    final repo = FakeTrustRepository(
      await SharedPreferences.getInstance(),
      person: () => person,
      now: () => WallTime.fromJson('2026-11-02T08:00:00'),
    );
    for (final n in ['01011111111', '01022222222', '01033333333']) {
      await repo.addContact(n, PhoneNumber.tryParse(n)!);
    }
    final ids = [for (final c in await repo.contacts()) c.id];
    expect(ids.toSet(), hasLength(3));
  });
}
