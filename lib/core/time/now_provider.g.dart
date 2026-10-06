// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current Cairo wall-clock time (device local time). Tests override it
/// with a fixed value; debug builds may run on a demo clock (research R11).

@ProviderFor(now)
final nowProvider = NowProvider._();

/// The current Cairo wall-clock time (device local time). Tests override it
/// with a fixed value; debug builds may run on a demo clock (research R11).

final class NowProvider extends $FunctionalProvider<Now, Now, Now>
    with $Provider<Now> {
  /// The current Cairo wall-clock time (device local time). Tests override it
  /// with a fixed value; debug builds may run on a demo clock (research R11).
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<Now> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Now create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Now value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Now>(value),
    );
  }
}

String _$nowHash() => r'ecc4d61c32c82e2a31a3a2a242a270b677925274';
