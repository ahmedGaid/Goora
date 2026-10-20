// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: the wallet asks this one for coverage through a
/// function (T019), so no provider cycle can form (005 lesson, research R8).
///
/// [PersonLookup] knows the signed-in person only (the fake has no other
/// accounts): their name from the profile, their work email from Trust
/// (T017). Signed out = nobody.

@ProviderFor(companyRepository)
final companyRepositoryProvider = CompanyRepositoryProvider._();

/// The company network on its fake (010 P3). It reads no wallet or
/// marketplace provider: the wallet asks this one for coverage through a
/// function (T019), so no provider cycle can form (005 lesson, research R8).
///
/// [PersonLookup] knows the signed-in person only (the fake has no other
/// accounts): their name from the profile, their work email from Trust
/// (T017). Signed out = nobody.

final class CompanyRepositoryProvider
    extends
        $FunctionalProvider<
          CompanyRepository,
          CompanyRepository,
          CompanyRepository
        >
    with $Provider<CompanyRepository> {
  /// The company network on its fake (010 P3). It reads no wallet or
  /// marketplace provider: the wallet asks this one for coverage through a
  /// function (T019), so no provider cycle can form (005 lesson, research R8).
  ///
  /// [PersonLookup] knows the signed-in person only (the fake has no other
  /// accounts): their name from the profile, their work email from Trust
  /// (T017). Signed out = nobody.
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

String _$companyRepositoryHash() => r'e7bfc823d550cae63c56918625acdb51d4a355e5';
