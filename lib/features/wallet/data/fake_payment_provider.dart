import '../domain/payment_provider.dart';

/// `shouldFail` is research R4's debug override, defaulting to always-succeed
/// — a widget test can also inject one that always fails.
final class FakePaymentProvider implements PaymentProvider {
  FakePaymentProvider({bool Function()? shouldFail}) : _shouldFail = shouldFail ?? (() => false);

  final bool Function() _shouldFail;

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async =>
      _shouldFail() ? PaymentResult.failure : PaymentResult.success;

  @override
  Future<PaymentResult> withdraw({required int amount}) async =>
      _shouldFail() ? PaymentResult.failure : PaymentResult.success;
}
