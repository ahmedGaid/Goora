// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_riders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Requests on the driver's route (D): only those within a 10-minute detour,
/// for their own privacy choice, each with what accepting would do (FR-018).

@ProviderFor(requestCards)
final requestCardsProvider = RequestCardsFamily._();

/// Requests on the driver's route (D): only those within a 10-minute detour,
/// for their own privacy choice, each with what accepting would do (FR-018).

final class RequestCardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RequestCard>>,
          List<RequestCard>,
          FutureOr<List<RequestCard>>
        >
    with
        $FutureModifier<List<RequestCard>>,
        $FutureProvider<List<RequestCard>> {
  /// Requests on the driver's route (D): only those within a 10-minute detour,
  /// for their own privacy choice, each with what accepting would do (FR-018).
  RequestCardsProvider._({
    required RequestCardsFamily super.from,
    required (Area?, PartOfDay) super.argument,
  }) : super(
         retry: null,
         name: r'requestCardsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$requestCardsHash();

  @override
  String toString() {
    return r'requestCardsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<RequestCard>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RequestCard>> create(Ref ref) {
    final argument = this.argument as (Area?, PartOfDay);
    return requestCards(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestCardsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$requestCardsHash() => r'e788a9c283886679de186850e15081d7821848e5';

/// Requests on the driver's route (D): only those within a 10-minute detour,
/// for their own privacy choice, each with what accepting would do (FR-018).

final class RequestCardsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RequestCard>>,
          (Area?, PartOfDay)
        > {
  RequestCardsFamily._()
    : super(
        retry: null,
        name: r'requestCardsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Requests on the driver's route (D): only those within a 10-minute detour,
  /// for their own privacy choice, each with what accepting would do (FR-018).

  RequestCardsProvider call(Area? leavingFrom, PartOfDay part) =>
      RequestCardsProvider._(argument: (leavingFrom, part), from: this);

  @override
  String toString() => r'requestCardsProvider';
}

/// Trips the driver still has on [date] (Constitution II: two a day).

@ProviderFor(tripsLeft)
final tripsLeftProvider = TripsLeftFamily._();

/// Trips the driver still has on [date] (Constitution II: two a day).

final class TripsLeftProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Trips the driver still has on [date] (Constitution II: two a day).
  TripsLeftProvider._({
    required TripsLeftFamily super.from,
    required CalendarDate super.argument,
  }) : super(
         retry: null,
         name: r'tripsLeftProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripsLeftHash();

  @override
  String toString() {
    return r'tripsLeftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as CalendarDate;
    return tripsLeft(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripsLeftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripsLeftHash() => r'449fde56b137e79fdb9b7daa6a21a67536e5bbd0';

/// Trips the driver still has on [date] (Constitution II: two a day).

final class TripsLeftFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, CalendarDate> {
  TripsLeftFamily._()
    : super(
        retry: null,
        name: r'tripsLeftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Trips the driver still has on [date] (Constitution II: two a day).

  TripsLeftProvider call(CalendarDate date) =>
      TripsLeftProvider._(argument: date, from: this);

  @override
  String toString() => r'tripsLeftProvider';
}
