// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_off_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10).

@ProviderFor(oneOffToday)
final oneOffTodayProvider = OneOffTodayProvider._();

/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10).

final class OneOffTodayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OneOffSeat>>,
          List<OneOffSeat>,
          FutureOr<List<OneOffSeat>>
        >
    with $FutureModifier<List<OneOffSeat>>, $FutureProvider<List<OneOffSeat>> {
  /// The rider's booked one-off seats on Today. A seat booked on the rider's own
  /// group ride is the group card's business, not shown twice (R10).
  OneOffTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneOffTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneOffTodayHash();

  @$internal
  @override
  $FutureProviderElement<List<OneOffSeat>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OneOffSeat>> create(Ref ref) {
    return oneOffToday(ref);
  }
}

String _$oneOffTodayHash() => r'a09efad2d780d6ca9bffb1ea5547ef490655278a';
