// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The marketplace wired to its seams (research R9): notices and reliability
/// into 003's fake, seat money into 004's ledger, the gate's balance and plan
/// from the wallet, the verification check from Trust.
///
/// The wallet in turn reads this one's finished one-off trips (see
/// `walletRepository`), but only inside a callback, so the two providers don't
/// depend on each other while they build.

@ProviderFor(marketplaceRepository)
final marketplaceRepositoryProvider = MarketplaceRepositoryProvider._();

/// The marketplace wired to its seams (research R9): notices and reliability
/// into 003's fake, seat money into 004's ledger, the gate's balance and plan
/// from the wallet, the verification check from Trust.
///
/// The wallet in turn reads this one's finished one-off trips (see
/// `walletRepository`), but only inside a callback, so the two providers don't
/// depend on each other while they build.

final class MarketplaceRepositoryProvider
    extends
        $FunctionalProvider<
          MarketplaceRepository,
          MarketplaceRepository,
          MarketplaceRepository
        >
    with $Provider<MarketplaceRepository> {
  /// The marketplace wired to its seams (research R9): notices and reliability
  /// into 003's fake, seat money into 004's ledger, the gate's balance and plan
  /// from the wallet, the verification check from Trust.
  ///
  /// The wallet in turn reads this one's finished one-off trips (see
  /// `walletRepository`), but only inside a callback, so the two providers don't
  /// depend on each other while they build.
  MarketplaceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketplaceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketplaceRepositoryHash();

  @$internal
  @override
  $ProviderElement<MarketplaceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketplaceRepository create(Ref ref) {
    return marketplaceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketplaceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketplaceRepository>(value),
    );
  }
}

String _$marketplaceRepositoryHash() =>
    r'db629185c66b68e08680b15e443a43fb0156ea5f';
