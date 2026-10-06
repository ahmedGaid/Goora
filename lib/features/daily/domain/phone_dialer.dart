/// Opens the phone dialler with [dial]'s number: E.164 or a short code such as "122".
abstract interface class PhoneDialer {
  /// False when no dialler could be opened.
  Future<bool> dial(String number);
}
