import 'phone_number.dart';

/// Which service delivers and checks the phone code (profit change 6).
/// WhatsApp OTP and Firebase Auth are cheaper than SMS; SMS stays a fallback.
enum OtpProviderKind {
  fake,
  whatsapp,
  firebase,
  sms;

  /// Reads the `OTP_PROVIDER` config value. Empty or unknown means [fake],
  /// so a build with no config never tries to reach a real service.
  static OtpProviderKind parse(String value) {
    final v = value.trim().toLowerCase();
    for (final k in OtpProviderKind.values) {
      if (k.name == v) return k;
    }
    return OtpProviderKind.fake;
  }
}

/// Delivers a one-time code and checks it. The auth repository owns accounts
/// and sessions; a provider only knows about codes.
abstract interface class OtpProvider {
  OtpProviderKind get kind;

  /// Throws `AuthNetworkException` when the code cannot be sent.
  Future<void> send(PhoneNumber phone);

  /// True when [code] is right for [phone]. Never throws for a wrong code.
  Future<bool> verify(PhoneNumber phone, String code);
}
