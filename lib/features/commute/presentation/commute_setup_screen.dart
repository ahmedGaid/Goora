import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_radio_card.dart';
import '../../../core/widgets/goora_route_map.dart';
import '../../../core/widgets/goora_stepper.dart';
import '../../onboarding/domain/onboarding_flow.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../data/providers.dart';
import '../domain/commute_profile.dart';
import '../domain/place.dart';
import '../domain/pricing_service.dart';
import 'commute_controller.dart';
import 'labels.dart';

class CommuteSetupScreen extends ConsumerStatefulWidget {
  const CommuteSetupScreen({super.key});

  @override
  ConsumerState<CommuteSetupScreen> createState() => _CommuteSetupScreenState();
}

class _CommuteSetupScreenState extends ConsumerState<CommuteSetupScreen> {
  bool _finding = false;

  Future<void> _find() async {
    setState(() => _finding = true);
    try {
      final outcome = await ref.read(commuteControllerProvider.notifier).findMatch();
      if (mounted) context.go(outcome.result.found ? Routes.match : Routes.noMatch);
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  Future<void> _pickPlace({required bool home}) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(commuteRepositoryProvider);
    final controller = ref.read(commuteControllerProvider.notifier);
    final current = ref.read(commuteControllerProvider).value;
    final selected = home ? current?.home : current?.work;
    final places = home ? repo.homePlaces() : repo.workPlaces();
    final picked = await showModalBottomSheet<Place>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.pageH, 0, AppSpacing.pageH, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(home ? l10n.pickHome : l10n.pickWork, style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.gap),
              for (final p in places) ...[
                GooraRadioCard(
                  key: Key('place-${p.id}'),
                  title: l10n.area(p.area),
                  selected: selected?.id == p.id,
                  onTap: () => Navigator.of(sheetContext).pop(p),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) home ? controller.setHome(picked) : controller.setWork(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(commuteControllerProvider);
    final controller = ref.read(commuteControllerProvider.notifier);
    final profile = async.value;

    return OnboardingScaffold(
      title: l10n.whereGo,
      progressIndex: OnboardingFlow.progressIndex(destination: Destination.commuteSetup),
      onBack: () => context.go(Routes.frequency),
      body: profile == null
          ? const Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator(color: AppColors.green)),
            )
          : _SetupForm(
              profile: profile,
              isDriver: controller.isDriver,
              onPickHome: () => _pickPlace(home: true),
              onPickWork: () => _pickPlace(home: false),
            ),
      bottom: GooraPrimaryButton(
        key: const Key('find-commute'),
        label: l10n.findCommute,
        trailingArrow: true,
        onPressed: profile == null || profile.problem != null || _finding ? null : _find,
      ),
    );
  }
}

class _SetupForm extends ConsumerWidget {
  const _SetupForm({
    required this.profile,
    required this.isDriver,
    required this.onPickHome,
    required this.onPickWork,
  });

  final CommuteProfile profile;
  final bool isDriver;
  final VoidCallback onPickHome;
  final VoidCallback onPickWork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(commuteControllerProvider.notifier);
    final problem = profile.problem;
    final sectionStyle = AppTypography.section.copyWith(color: AppColors.textPrimary);

    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg, bottom: AppSpacing.md),
          child: Text(title, style: sectionStyle),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraCard.rows(
          padding: EdgeInsetsDirectional.zero,
          rows: [
            _PlaceRow(
              key: const Key('pick-home'),
              label: l10n.home,
              value: profile.home == null ? null : l10n.area(profile.home!.area),
              placeholder: l10n.choosePlace,
              onTap: onPickHome,
            ),
            _PlaceRow(
              key: const Key('pick-work'),
              label: l10n.work,
              value: profile.work == null ? null : l10n.area(profile.work!.area),
              placeholder: l10n.choosePlace,
              onTap: onPickWork,
            ),
          ],
        ),
        if (profile.home != null && profile.work != null) ...[
          const SizedBox(height: AppSpacing.gap),
          GooraRouteMap(
            fromLabel: l10n.area(profile.home!.area),
            toLabel: l10n.area(profile.work!.area),
            semanticLabel: '${l10n.mapAria}: ${l10n.routeLine(l10n.area(profile.home!.area), l10n.area(profile.work!.area))}',
          ),
        ],
        section(l10n.whenTravel),
        GooraCard.rows(
          rows: [
            _TimeRow(
              label: l10n.departure,
              valueKey: const Key('departure-value'),
              value: l10n.time(profile.departure),
              onEarlier: () => controller.shiftDeparture(-timeStepMinutes),
              onLater: () => controller.shiftDeparture(timeStepMinutes),
            ),
            _TimeRow(
              label: l10n.returnT,
              valueKey: const Key('return-value'),
              value: l10n.time(profile.ret),
              onEarlier: () => controller.shiftReturn(-timeStepMinutes),
              onLater: () => controller.shiftReturn(timeStepMinutes),
            ),
          ],
        ),
        section(l10n.workingDays),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final d in Day.values)
              GooraPill(
                key: Key('day-${d.name}'),
                label: l10n.day(d),
                selected: profile.days.contains(d),
                onTap: () => controller.toggleDay(d),
              ),
          ],
        ),
        if (isDriver) _DriverSection(profile: profile, section: section),
        if (problem != null && problem != CommuteProblem.missingPlace) ...[
          const SizedBox(height: AppSpacing.gap),
          Text(
            l10n.commuteProblem(problem),
            key: const Key('setup-hint'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
          ),
        ],
      ],
    );
  }
}

class _DriverSection extends ConsumerWidget {
  const _DriverSection({required this.profile, required this.section});

  final CommuteProfile profile;
  final Widget Function(String) section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(commuteControllerProvider.notifier);
    final offer = controller.offerOf(profile);
    final range = controller.rangeFor(offer.seats);
    final delta = PricingService.deltaFromSuggested(offer.contribution, range);
    final recovery = PricingService.recoveryPerDay(offer.seats, offer.contribution, offer.trips);
    final caption = AppTypography.caption.copyWith(color: AppColors.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(l10n.seatsQ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GooraStepper(
            key: const Key('seats-stepper'),
            valueLabel: '${offer.seats}',
            decreaseLabel: l10n.fewerSeats,
            increaseLabel: l10n.moreSeats,
            onDecrease: offer.seats > DriverOffer.minSeats ? () => controller.setSeats(offer.seats - 1) : null,
            onIncrease: offer.seats < DriverOffer.maxSeats ? () => controller.setSeats(offer.seats + 1) : null,
          ),
        ),
        section(l10n.whichTrips),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final t in DrivenTrips.values)
              GooraPill(
                key: Key('trips-${t.name}'),
                label: l10n.trips(t),
                selected: offer.trips == t,
                onTap: () => controller.setTrips(t),
              ),
          ],
        ),
        if (offer.trips != DrivenTrips.both) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.otherTripNote, style: caption),
        ],
        section(l10n.contribTitle),
        GooraCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GooraStepper(
                  key: const Key('contribution-stepper'),
                  valueLabel: l10n.egpAmount(offer.contribution),
                  decreaseLabel: l10n.lowerContribution,
                  increaseLabel: l10n.raiseContribution,
                  onDecrease: offer.contribution > range.min ? () => controller.stepContribution(-1) : null,
                  onIncrease: offer.contribution < range.max ? () => controller.stepContribution(1) : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                delta == 0
                    ? l10n.suggestedPrice
                    : delta > 0
                        ? l10n.aboveSuggested(delta)
                        : l10n.belowSuggested(-delta),
                key: const Key('contribution-delta'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyStrong.copyWith(color: delta == 0 ? AppColors.greenText : AppColors.textBody),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(l10n.egpAmount(range.min), style: caption),
                  Expanded(child: Text(l10n.suggestedShort(range.suggested), textAlign: TextAlign.center, style: caption)),
                  Text(l10n.egpAmount(range.max), style: caption),
                ],
              ),
              const Divider(height: AppSpacing.lg, color: AppColors.divider),
              Text(l10n.contribNote, style: caption),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        Container(
          key: const Key('recovery'),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.gap, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.mintSurface,
            borderRadius: BorderRadius.circular(AppRadii.dashed),
          ),
          child: Row(
            children: [
              Expanded(child: Text(l10n.recoverDay, style: AppTypography.bodySmall.copyWith(color: AppColors.primary))),
              Text(l10n.egpAmount(recovery), style: AppTypography.bodyStrong.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
          child: Row(
            children: [
              const Icon(GooraIcons.pin, size: AppSizes.icon, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    Text(
                      value ?? placeholder,
                      style: AppTypography.bodyStrong.copyWith(
                        color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(GooraIcons.chevron, size: AppSizes.iconSmall, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.onEarlier,
    required this.onLater,
  });

  final String label;
  final String value;
  final Key valueKey;
  final VoidCallback onEarlier;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary))),
        GooraStepper(
          key: valueKey,
          valueLabel: value,
          decreaseLabel: '$label: ${l10n.earlier}',
          increaseLabel: '$label: ${l10n.later}',
          onDecrease: onEarlier,
          onIncrease: onLater,
        ),
      ],
    );
  }
}
