// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_trip_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postStart)
final postStartProvider = PostStartProvider._();

final class PostStartProvider
    extends
        $FunctionalProvider<
          AsyncValue<PostStart>,
          PostStart,
          FutureOr<PostStart>
        >
    with $FutureModifier<PostStart>, $FutureProvider<PostStart> {
  PostStartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postStartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postStartHash();

  @$internal
  @override
  $FutureProviderElement<PostStart> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PostStart> create(Ref ref) {
    return postStart(ref);
  }
}

String _$postStartHash() => r'c7869381e803afdf30fd9738634c6545b3431bd8';

/// One posted request, read fresh: it expires on read at date + time (R13).

@ProviderFor(postedRequest)
final postedRequestProvider = PostedRequestFamily._();

/// One posted request, read fresh: it expires on read at date + time (R13).

final class PostedRequestProvider
    extends
        $FunctionalProvider<
          AsyncValue<TripRequest?>,
          TripRequest?,
          FutureOr<TripRequest?>
        >
    with $FutureModifier<TripRequest?>, $FutureProvider<TripRequest?> {
  /// One posted request, read fresh: it expires on read at date + time (R13).
  PostedRequestProvider._({
    required PostedRequestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postedRequestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postedRequestHash();

  @override
  String toString() {
    return r'postedRequestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TripRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TripRequest?> create(Ref ref) {
    final argument = this.argument as String;
    return postedRequest(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PostedRequestProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postedRequestHash() => r'cccf3321aa4fb27b4184e023402c6c4777cf00d8';

/// One posted request, read fresh: it expires on read at date + time (R13).

final class PostedRequestFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TripRequest?>, String> {
  PostedRequestFamily._()
    : super(
        retry: null,
        name: r'postedRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One posted request, read fresh: it expires on read at date + time (R13).

  PostedRequestProvider call(String id) =>
      PostedRequestProvider._(argument: id, from: this);

  @override
  String toString() => r'postedRequestProvider';
}

/// "Sent to N drivers on your route".

@ProviderFor(sentTo)
final sentToProvider = SentToFamily._();

/// "Sent to N drivers on your route".

final class SentToProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// "Sent to N drivers on your route".
  SentToProvider._({
    required SentToFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sentToProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sentToHash();

  @override
  String toString() {
    return r'sentToProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return sentTo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SentToProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sentToHash() => r'27602bd0e8ebec841848a233da74b1d701ee00ba';

/// "Sent to N drivers on your route".

final class SentToFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  SentToFamily._()
    : super(
        retry: null,
        name: r'sentToProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// "Sent to N drivers on your route".

  SentToProvider call(String requestId) =>
      SentToProvider._(argument: requestId, from: this);

  @override
  String toString() => r'sentToProvider';
}

/// The rider's requests still waiting for a driver, for Today.

@ProviderFor(myPostedRequests)
final myPostedRequestsProvider = MyPostedRequestsProvider._();

/// The rider's requests still waiting for a driver, for Today.

final class MyPostedRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripRequest>>,
          List<TripRequest>,
          FutureOr<List<TripRequest>>
        >
    with
        $FutureModifier<List<TripRequest>>,
        $FutureProvider<List<TripRequest>> {
  /// The rider's requests still waiting for a driver, for Today.
  MyPostedRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPostedRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPostedRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<TripRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TripRequest>> create(Ref ref) {
    return myPostedRequests(ref);
  }
}

String _$myPostedRequestsHash() => r'92509f18f2b1f5f8fe4334c224450d7edce279d6';
