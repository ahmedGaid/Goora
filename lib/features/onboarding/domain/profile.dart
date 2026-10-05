import 'choices.dart';
import 'phone_number.dart';

final class Profile {
  const Profile({
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.role,
    this.frequency,
  });

  static const maxNameLength = 40;

  final PhoneNumber phone;
  final String firstName;
  final String lastName;
  final Gender gender;
  final Role? role;
  final Frequency? frequency;

  static bool isValidName(String value) {
    final t = value.trim();
    return t.isNotEmpty && t.length <= maxNameLength;
  }

  Profile copyWith({Role? role, Frequency? frequency}) => Profile(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        role: role ?? this.role,
        frequency: frequency ?? this.frequency,
      );

  Map<String, Object?> toJson() => {
        'phone': phone.e164,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender.name,
        'role': role?.name,
        'frequency': frequency?.name,
      };

  static Profile? fromJson(Map<String, Object?> json) {
    final phone = PhoneNumber.tryParse(json['phone'] as String? ?? '');
    final gender = enumByName(Gender.values, json['gender'] as String?);
    final first = json['firstName'] as String?;
    final last = json['lastName'] as String?;
    if (phone == null || gender == null || first == null || last == null) return null;
    return Profile(
      phone: phone,
      firstName: first,
      lastName: last,
      gender: gender,
      role: enumByName(Role.values, json['role'] as String?),
      frequency: enumByName(Frequency.values, json['frequency'] as String?),
    );
  }
}
