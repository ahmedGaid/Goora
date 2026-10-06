import 'package:url_launcher/url_launcher.dart';

import '../domain/phone_dialer.dart';

/// Opens the system dialler with a `tel:` link (research R9). The call is
/// never placed automatically; the person presses call themselves.
final class UrlPhoneDialer implements PhoneDialer {
  const UrlPhoneDialer();

  @override
  Future<bool> dial(String number) => launchUrl(Uri(scheme: 'tel', path: number));
}
