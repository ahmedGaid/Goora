/// Opens the system share sheet with [text].
abstract interface class TripSharer {
  Future<void> share(String text);
}
