/// An Egyptian mobile number, always stored as `+201XXXXXXXXX`.
final class PhoneNumber {
  const PhoneNumber._(this.e164);

  final String e164;

  static const _operatorDigits = {'0', '1', '2', '5'};
  static final _separators = RegExp(r'[\s\-()]');
  static final _digits = RegExp(r'^\d+$');

  /// Accepts `01XXXXXXXXX`, `+201XXXXXXXXX`, `00201XXXXXXXXX` and
  /// `201XXXXXXXXX`, with optional spaces, dashes or parentheses.
  static PhoneNumber? tryParse(String input) {
    var s = input.replaceAll(_separators, '');
    if (s.startsWith('+')) s = s.substring(1);
    if (s.startsWith('00')) s = s.substring(2);
    if (!_digits.hasMatch(s)) return null;

    final String national; // 10 digits starting with 1
    if (s.length == 12 && s.startsWith('20')) {
      national = s.substring(2);
    } else if (s.length == 11 && s.startsWith('0')) {
      national = s.substring(1);
    } else {
      return null;
    }
    if (!national.startsWith('1') || !_operatorDigits.contains(national[1])) return null;
    return PhoneNumber._('+20$national');
  }

  /// `01XXXXXXXXX`, the form Egyptians write.
  String get local => '0${e164.substring(3)}';

  @override
  bool operator ==(Object other) => other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  @override
  String toString() => e164;
}
