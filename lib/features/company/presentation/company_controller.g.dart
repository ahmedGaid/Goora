// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(companyAccount)
final companyAccountProvider = CompanyAccountProvider._();

final class CompanyAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompanyAccountView>,
          CompanyAccountView,
          FutureOr<CompanyAccountView>
        >
    with
        $FutureModifier<CompanyAccountView>,
        $FutureProvider<CompanyAccountView> {
  CompanyAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companyAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companyAccountHash();

  @$internal
  @override
  $FutureProviderElement<CompanyAccountView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompanyAccountView> create(Ref ref) {
    return companyAccount(ref);
  }
}

String _$companyAccountHash() => r'6581a7af23d2200da633ae5a3cfe60588c91b55f';
