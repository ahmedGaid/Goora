// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentProvider)
final paymentProviderProvider = PaymentProviderProvider._();

final class PaymentProviderProvider
    extends
        $FunctionalProvider<PaymentProvider, PaymentProvider, PaymentProvider>
    with $Provider<PaymentProvider> {
  PaymentProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentProviderHash();

  @$internal
  @override
  $ProviderElement<PaymentProvider> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaymentProvider create(Ref ref) {
    return paymentProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentProvider>(value),
    );
  }
}

String _$paymentProviderHash() => r'62ef82df2aa758bb33f284eab53d5a24da481623';

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletRepository,
          WalletRepository,
          WalletRepository
        >
    with $Provider<WalletRepository> {
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'b59cf4bb340e6221bfdbf04cb0f1ad0be71a5d9d';
