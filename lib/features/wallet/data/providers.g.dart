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

String _$walletRepositoryHash() => r'2c030c0a6585e18ea7bdc16963de0ac255bd1cea';

/// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
/// passenger's share on this ride and where it stands; null hides the
/// buttons (no share there).

@ProviderFor(driverShare)
final driverShareProvider = DriverShareFamily._();

/// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
/// passenger's share on this ride and where it stands; null hides the
/// buttons (no share there).

final class DriverShareProvider
    extends $FunctionalProvider<AsyncValue<Share?>, Share?, FutureOr<Share?>>
    with $FutureModifier<Share?>, $FutureProvider<Share?> {
  /// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
  /// passenger's share on this ride and where it stands; null hides the
  /// buttons (no share there).
  DriverShareProvider._({
    required DriverShareFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'driverShareProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$driverShareHash();

  @override
  String toString() {
    return r'driverShareProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Share?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Share?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return driverShare(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DriverShareProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$driverShareHash() => r'235dc24552781da321791be3b48fea7861632a59';

/// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
/// passenger's share on this ride and where it stands; null hides the
/// buttons (no share there).

final class DriverShareFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Share?>, (String, String)> {
  DriverShareFamily._()
    : super(
        retry: null,
        name: r'driverShareProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
  /// passenger's share on this ride and where it stands; null hides the
  /// buttons (no share there).

  DriverShareProvider call(String rideId, String riderId) =>
      DriverShareProvider._(argument: (rideId, riderId), from: this);

  @override
  String toString() => r'driverShareProvider';
}

/// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).

@ProviderFor(driverInstapay)
final driverInstapayProvider = DriverInstapayFamily._();

/// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).

final class DriverInstapayProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).
  DriverInstapayProvider._({
    required DriverInstapayFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'driverInstapayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$driverInstapayHash();

  @override
  String toString() {
    return r'driverInstapayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return driverInstapay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DriverInstapayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$driverInstapayHash() => r'a9bf2f8440181c5291480fe1b10723d3088db93c';

/// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).

final class DriverInstapayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  DriverInstapayFamily._()
    : super(
        retry: null,
        name: r'driverInstapayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).

  DriverInstapayProvider call(String driverId) =>
      DriverInstapayProvider._(argument: driverId, from: this);

  @override
  String toString() => r'driverInstapayProvider';
}

/// The signed-in rider's shares a driver hasn't confirmed, open debts first
/// (007 US3 debt banner).

@ProviderFor(myOpenShares)
final myOpenSharesProvider = MyOpenSharesProvider._();

/// The signed-in rider's shares a driver hasn't confirmed, open debts first
/// (007 US3 debt banner).

final class MyOpenSharesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Share>>,
          List<Share>,
          FutureOr<List<Share>>
        >
    with $FutureModifier<List<Share>>, $FutureProvider<List<Share>> {
  /// The signed-in rider's shares a driver hasn't confirmed, open debts first
  /// (007 US3 debt banner).
  MyOpenSharesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myOpenSharesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myOpenSharesHash();

  @$internal
  @override
  $FutureProviderElement<List<Share>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Share>> create(Ref ref) {
    return myOpenShares(ref);
  }
}

String _$myOpenSharesHash() => r'10790c443ed9845e6dd073393e2eaec569aa224e';

/// How the signed-in rider pays the driver (cash unless they chose InstaPay):
/// price lines read it for the share (007 R4).

@ProviderFor(riderPayMethod)
final riderPayMethodProvider = RiderPayMethodProvider._();

/// How the signed-in rider pays the driver (cash unless they chose InstaPay):
/// price lines read it for the share (007 R4).

final class RiderPayMethodProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaymentMethod>,
          PaymentMethod,
          FutureOr<PaymentMethod>
        >
    with $FutureModifier<PaymentMethod>, $FutureProvider<PaymentMethod> {
  /// How the signed-in rider pays the driver (cash unless they chose InstaPay):
  /// price lines read it for the share (007 R4).
  RiderPayMethodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'riderPayMethodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$riderPayMethodHash();

  @$internal
  @override
  $FutureProviderElement<PaymentMethod> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaymentMethod> create(Ref ref) {
    return riderPayMethod(ref);
  }
}

String _$riderPayMethodHash() => r'88f020ac6351e010ecf8211e9aa0bbcac5df0098';

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

String _$riderPricingHash() => r'4e0c2cbec05ced3e5f7d5dca451df7cd1f5a9667';
