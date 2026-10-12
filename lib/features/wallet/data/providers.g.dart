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

/// For a driver's check-in after drop-off (FR-012): is this passenger paying
/// cash, and has the driver already recorded it? `isCash` false hides the
/// buttons entirely.

@ProviderFor(cashStatus)
final cashStatusProvider = CashStatusFamily._();

/// For a driver's check-in after drop-off (FR-012): is this passenger paying
/// cash, and has the driver already recorded it? `isCash` false hides the
/// buttons entirely.

final class CashStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<({bool isCash, CashOutcome? outcome})>,
          ({bool isCash, CashOutcome? outcome}),
          FutureOr<({bool isCash, CashOutcome? outcome})>
        >
    with
        $FutureModifier<({bool isCash, CashOutcome? outcome})>,
        $FutureProvider<({bool isCash, CashOutcome? outcome})> {
  /// For a driver's check-in after drop-off (FR-012): is this passenger paying
  /// cash, and has the driver already recorded it? `isCash` false hides the
  /// buttons entirely.
  CashStatusProvider._({
    required CashStatusFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'cashStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cashStatusHash();

  @override
  String toString() {
    return r'cashStatusProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<({bool isCash, CashOutcome? outcome})> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<({bool isCash, CashOutcome? outcome})> create(Ref ref) {
    final argument = this.argument as (String, String);
    return cashStatus(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CashStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cashStatusHash() => r'dbaab5d01a9eac6efc3e5ce5e143e10ae811a5c9';

/// For a driver's check-in after drop-off (FR-012): is this passenger paying
/// cash, and has the driver already recorded it? `isCash` false hides the
/// buttons entirely.

final class CashStatusFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<({bool isCash, CashOutcome? outcome})>,
          (String, String)
        > {
  CashStatusFamily._()
    : super(
        retry: null,
        name: r'cashStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// For a driver's check-in after drop-off (FR-012): is this passenger paying
  /// cash, and has the driver already recorded it? `isCash` false hides the
  /// buttons entirely.

  CashStatusProvider call(String rideId, String riderId) =>
      CashStatusProvider._(argument: (rideId, riderId), from: this);

  @override
  String toString() => r'cashStatusProvider';
}

/// The signed-in rider's current price mode (FR-004). Price lines watch this;
/// screens that change the arrangement invalidate it.

@ProviderFor(riderPricing)
final riderPricingProvider = RiderPricingProvider._();

/// The signed-in rider's current price mode (FR-004). Price lines watch this;
/// screens that change the arrangement invalidate it.

final class RiderPricingProvider
    extends
        $FunctionalProvider<
          AsyncValue<PricingMode>,
          PricingMode,
          FutureOr<PricingMode>
        >
    with $FutureModifier<PricingMode>, $FutureProvider<PricingMode> {
  /// The signed-in rider's current price mode (FR-004). Price lines watch this;
  /// screens that change the arrangement invalidate it.
  RiderPricingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'riderPricingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$riderPricingHash();

  @$internal
  @override
  $FutureProviderElement<PricingMode> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PricingMode> create(Ref ref) {
    return riderPricing(ref);
  }
}

String _$riderPricingHash() => r'45b1ce5980d20729cc3bf27d68969387cfe0bc34';
