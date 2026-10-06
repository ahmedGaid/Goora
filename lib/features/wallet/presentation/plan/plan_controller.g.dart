// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlanController)
final planControllerProvider = PlanControllerProvider._();

final class PlanControllerProvider
    extends $AsyncNotifierProvider<PlanController, Plan?> {
  PlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planControllerHash();

  @$internal
  @override
  PlanController create() => PlanController();
}

String _$planControllerHash() => r'eb097f648891761f91d4d296c211d2957de2707e';

abstract class _$PlanController extends $AsyncNotifier<Plan?> {
  FutureOr<Plan?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Plan?>, Plan?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Plan?>, Plan?>,
              AsyncValue<Plan?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
