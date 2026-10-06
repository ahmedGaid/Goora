// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WeekController)
final weekControllerProvider = WeekControllerProvider._();

final class WeekControllerProvider
    extends $AsyncNotifierProvider<WeekController, WeekView> {
  WeekControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekControllerHash();

  @$internal
  @override
  WeekController create() => WeekController();
}

String _$weekControllerHash() => r'b816721957f48352debb90635b34c888ae4a2d45';

abstract class _$WeekController extends $AsyncNotifier<WeekView> {
  FutureOr<WeekView> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WeekView>, WeekView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WeekView>, WeekView>,
              AsyncValue<WeekView>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
