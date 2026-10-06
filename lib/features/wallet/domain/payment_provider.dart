enum PaymentResult { success, failure }

/// Behind an interface until a real payment partner exists (constitution:
/// `FakePaymentProvider` only).
abstract interface class PaymentProvider {
  Future<PaymentResult> topUp({required String method, required int amount});
  Future<PaymentResult> withdraw({required int amount});
}
