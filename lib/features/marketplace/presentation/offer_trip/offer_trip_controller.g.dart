// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_trip_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the form starts: the driver's saved commute, home → work at their
/// time (T104 F22), like Post your trip's `postStart`.

@ProviderFor(offerStart)
final offerStartProvider = OfferStartProvider._();

/// Where the form starts: the driver's saved commute, home → work at their
/// time (T104 F22), like Post your trip's `postStart`.

final class OfferStartProvider
    extends
        $FunctionalProvider<
          AsyncValue<OfferForm>,
          OfferForm,
          FutureOr<OfferForm>
        >
    with $FutureModifier<OfferForm>, $FutureProvider<OfferForm> {
  /// Where the form starts: the driver's saved commute, home → work at their
  /// time (T104 F22), like Post your trip's `postStart`.
  OfferStartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offerStartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offerStartHash();

  @$internal
  @override
  $FutureProviderElement<OfferForm> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OfferForm> create(Ref ref) {
    return offerStart(ref);
  }
}

String _$offerStartHash() => r'953dc1e5907eec677e8e8d4d74dee48d7a342166';

/// The form's check, re-read when the form changes.

@ProviderFor(offerCheck)
final offerCheckProvider = OfferCheckFamily._();

/// The form's check, re-read when the form changes.

final class OfferCheckProvider
    extends
        $FunctionalProvider<
          AsyncValue<OfferCheck>,
          OfferCheck,
          FutureOr<OfferCheck>
        >
    with $FutureModifier<OfferCheck>, $FutureProvider<OfferCheck> {
  /// The form's check, re-read when the form changes.
  OfferCheckProvider._({
    required OfferCheckFamily super.from,
    required OfferForm super.argument,
  }) : super(
         retry: null,
         name: r'offerCheckProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerCheckHash();

  @override
  String toString() {
    return r'offerCheckProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OfferCheck> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OfferCheck> create(Ref ref) {
    final argument = this.argument as OfferForm;
    return offerCheck(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferCheckProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerCheckHash() => r'17d5ab750132e3531efbc3e1b03406db03b770b7';

/// The form's check, re-read when the form changes.

final class OfferCheckFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OfferCheck>, OfferForm> {
  OfferCheckFamily._()
    : super(
        retry: null,
        name: r'offerCheckProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The form's check, re-read when the form changes.

  OfferCheckProvider call(OfferForm form) =>
      OfferCheckProvider._(argument: form, from: this);

  @override
  String toString() => r'offerCheckProvider';
}

/// One published trip as its driver watches it fill (live, full, departed,
/// done, cancelled).

@ProviderFor(offerLive)
final offerLiveProvider = OfferLiveFamily._();

/// One published trip as its driver watches it fill (live, full, departed,
/// done, cancelled).

final class OfferLiveProvider
    extends
        $FunctionalProvider<
          AsyncValue<OfferLive>,
          OfferLive,
          FutureOr<OfferLive>
        >
    with $FutureModifier<OfferLive>, $FutureProvider<OfferLive> {
  /// One published trip as its driver watches it fill (live, full, departed,
  /// done, cancelled).
  OfferLiveProvider._({
    required OfferLiveFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offerLiveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerLiveHash();

  @override
  String toString() {
    return r'offerLiveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OfferLive> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OfferLive> create(Ref ref) {
    final argument = this.argument as String;
    return offerLive(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferLiveProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerLiveHash() => r'ba84ae124eab51a2b15c87e5d7ad7ce8d763aaaa';

/// One published trip as its driver watches it fill (live, full, departed,
/// done, cancelled).

final class OfferLiveFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OfferLive>, String> {
  OfferLiveFamily._()
    : super(
        retry: null,
        name: r'offerLiveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One published trip as its driver watches it fill (live, full, departed,
  /// done, cancelled).

  OfferLiveProvider call(String tripId) =>
      OfferLiveProvider._(argument: tripId, from: this);

  @override
  String toString() => r'offerLiveProvider';
}
