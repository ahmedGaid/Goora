// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WalletController)
final walletControllerProvider = WalletControllerProvider._();

final class WalletControllerProvider
    extends $AsyncNotifierProvider<WalletController, WalletView> {
  WalletControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletControllerHash();

  @$internal
  @override
  WalletController create() => WalletController();
}

String _$walletControllerHash() => r'a986406e9b5de6b5dbeb50e93af4b37b4cecca42';

abstract class _$WalletController extends $AsyncNotifier<WalletView> {
  FutureOr<WalletView> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WalletView>, WalletView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WalletView>, WalletView>,
              AsyncValue<WalletView>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
