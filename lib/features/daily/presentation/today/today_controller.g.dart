// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TodayController)
final todayControllerProvider = TodayControllerProvider._();

final class TodayControllerProvider
    extends $AsyncNotifierProvider<TodayController, TodayView> {
  TodayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayControllerHash();

  @$internal
  @override
  TodayController create() => TodayController();
}

String _$todayControllerHash() => r'5b53f0d8e5d29f790c29f5b89407a351a22353f0';

abstract class _$TodayController extends $AsyncNotifier<TodayView> {
  FutureOr<TodayView> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TodayView>, TodayView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TodayView>, TodayView>,
              AsyncValue<TodayView>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// In-app inbox (research R11), newest first.

@ProviderFor(notices)
final noticesProvider = NoticesProvider._();

/// In-app inbox (research R11), newest first.

final class NoticesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Notice>>,
          List<Notice>,
          Stream<List<Notice>>
        >
    with $FutureModifier<List<Notice>>, $StreamProvider<List<Notice>> {
  /// In-app inbox (research R11), newest first.
  NoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticesHash();

  @$internal
  @override
  $StreamProviderElement<List<Notice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Notice>> create(Ref ref) {
    return notices(ref);
  }
}

String _$noticesHash() => r'befd4c4118e03d0c0b4050f0648459f0691d9f99';
