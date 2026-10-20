// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: those seams (T018–T019, the wallet asks this one for
/// coverage) arrive as functions after 006 merges, so no provider cycle can
/// form (005 lesson, research R8).
///
/// [PersonLookup] knows nobody outside the seed yet: the employee's work
/// email needs `TrustProfile.workEmail` (T017, an existing file that waits
/// for 006). Until then "Through my company" reads "no work email".

@ProviderFor(companyRepository)
final companyRepositoryProvider = CompanyRepositoryProvider._();

/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: those seams (T018–T019, the wallet asks this one for
/// coverage) arrive as functions after 006 merges, so no provider cycle can
/// form (005 lesson, research R8).
///
/// [PersonLookup] knows nobody outside the seed yet: the employee's work
/// email needs `TrustProfile.workEmail` (T017, an existing file that waits
/// for 006). Until then "Through my company" reads "no work email".

final class CompanyRepositoryProvider
    extends
        $FunctionalProvider<
          CompanyRepository,
          CompanyRepository,
          CompanyRepository
        >
    with $Provider<CompanyRepository> {
  /// The company network on its fake (010 P3). It reads no wallet or
  /// marketplace provider: those seams (T018–T019, the wallet asks this one for
  /// coverage) arrive as functions after 006 merges, so no provider cycle can
  /// form (005 lesson, research R8).
  ///
  /// [PersonLookup] knows nobody outside the seed yet: the employee's work
  /// email needs `TrustProfile.workEmail` (T017, an existing file that waits
  /// for 006). Until then "Through my company" reads "no work email".
  CompanyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companyRepositoryHash();

  @$internal
  @override
  $ProviderElement<CompanyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompanyRepository create(Ref ref) {
    return companyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompanyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompanyRepository>(value),
    );
  }
}

String _$companyRepositoryHash() => r'60ce7f24c611b5f300b91985adbb185d2d5af415';
