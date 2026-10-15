import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_stepper.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/domain/trust.dart';
import '../../../daily/presentation/labels.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../../wallet/domain/payment_method.dart';
import '../../../wallet/domain/seat_price.dart';
import '../../data/market_seed.dart';
import '../../data/providers.dart';
import '../../domain/driver_day_rules.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';
import '../route_form.dart';
import '../today/one_off_section.dart';
import 'live_parts.dart';
import 'offer_trip_controller.dart';

/// Offer a trip (C): a verified driver publishes a once or daily trip, watches
/// its seats fill, and can cancel it. Every limit is said in words before the
/// tap — Publish stays off with the reason under it, never colour alone (VII).
class OfferTripScreen extends ConsumerStatefulWidget {
  const OfferTripScreen({super.key, this.id});

  /// A published trip to watch; null starts a new one.
  final String? id;

  @override
  ConsumerState<OfferTripScreen> createState() => _OfferTripScreenState();
}

class _OfferTripScreenState extends ConsumerState<OfferTripScreen> {
  OfferForm _form = OfferForm.start();
  late String? _id = widget.id;
  bool _busy = false;

  // A live offer lives on Today; before publishing, Back is onboarding's last
  // step when there is nothing to pop (T104 F8).
  void _back() => context.canPop()
      ? context.pop()
      : context.go(_id != null ? Routes.today : Routes.frequency);

  void _set(OfferForm f) => setState(() => _form = f);

  void _seats(int seats) => _set(_form.copyWith(seats: seats, contribution: OfferForm.rangeFor(seats).suggested));

  void _step(int dir) {
    final r = _form.range;
    final next = (_form.contribution + dir * PricingService.step).clamp(r.min, r.max);
    _set(_form.copyWith(contribution: next));
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    final now = ref.read(nowProvider)();
    final result = await ref.read(marketplaceRepositoryProvider).publish(_form.toDraft(), now: now);
    if (!mounted) return;
    switch (result) {
      case Published(:final trip):
        ref
          ..invalidate(offerCheckProvider)
          ..invalidate(driverOffersProvider);
        setState(() {
          _id = trip.id;
          _busy = false;
        });
      case NotVerified() || OverLimit():
        // The rules moved since the form was read: show the reason now.
        ref.invalidate(offerCheckProvider);
        setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = _id;
    return OnboardingScaffold(
      title: l10n.offerTitle,
      onBack: _back,
      body: id != null ? _Live(id: id) : _formView(l10n),
    );
  }

  Widget _formView(AppLocalizations l10n) {
    final now = ref.watch(nowProvider)();
    final check = ref.watch(offerCheckProvider(_form)).value;
    final range = _form.range;
    final delta = _form.contribution - range.suggested;
    final price = SeatPrice.of(
      _form.contribution,
      tripCost: MarketSeed.tripCost,
      riderSeats: _form.seats,
      mode: PricingMode.wallet,
    );
    final reason = check == null ? null : _reason(l10n, check);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (check != null)
          for (final kind in check.missing) ...[
            GooraGhostButton(
              key: Key('verify-${kind.name}'),
              label: l10n.verifyChip(_item(l10n, kind)),
              icon: GooraIcons.verified,
              onPressed: () => context.go(Routes.trust),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        RouteForm(
          from: _form.from,
          to: _form.to,
          departure: _form.departure,
          repeat: _form.repeat,
          now: now,
          onFrom: (a) => _set(a == _form.to ? _form.copyWith(from: a, to: _form.from) : _form.copyWith(from: a)),
          onTo: (a) => _set(a == _form.from ? _form.copyWith(to: a, from: _form.to) : _form.copyWith(to: a)),
          onShift: (d) => _set(_form.copyWith(departure: _form.departure.shift(d))),
          onRepeat: (r) => _set(_form.copyWith(repeat: r)),
        ),
        if (_form.repeat == Repeat.daily) Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
          child: Text(
            l10n.dailyOfferNote,
            key: const Key('daily-note'),
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        _label(l10n.seatsQ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GooraStepper(
            key: const Key('seats-stepper'),
            valueLabel: '${_form.seats}',
            decreaseLabel: l10n.fewerSeats,
            increaseLabel: l10n.moreSeats,
            onDecrease: _form.seats > 1 ? () => _seats(_form.seats - 1) : null,
            onIncrease: _form.seats < 4 ? () => _seats(_form.seats + 1) : null,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: GooraStepper(
            key: const Key('contribution-stepper'),
            valueLabel: l10n.egpAmount(_form.contribution),
            decreaseLabel: l10n.lowerContribution,
            increaseLabel: l10n.raiseContribution,
            onDecrease: _form.contribution > range.min ? () => _step(-1) : null,
            onIncrease: _form.contribution < range.max ? () => _step(1) : null,
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.riderPaysLine(price.total),
          key: const Key('rider-pays'),
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final rule in [l10n.ruleNoBidding, l10n.ruleCostShare, l10n.ruleRoute])
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                const Icon(GooraIcons.check, size: AppSizes.iconSmall, color: AppColors.greenText),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(rule, style: AppTypography.bodySmall.copyWith(color: AppColors.textBody))),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        GooraGhostButton(
          key: const Key('find-riders-link'),
          label: l10n.findRidersLink,
          onPressed: () => context.push(Routes.findRiders),
        ),
        const SizedBox(height: AppSpacing.md),
        GooraPrimaryButton(
          key: const Key('publish'),
          label: l10n.publish,
          onPressed: check != null && check.canPublish && !_busy ? _publish : null,
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
            child: Text(
              reason,
              key: const Key('publish-reason'),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(text, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
      );

  static String _item(AppLocalizations l10n, VerificationKind kind) => switch (kind) {
        VerificationKind.license => l10n.checkLicense,
        VerificationKind.vehicle => l10n.checkVehicle,
        VerificationKind.nationalId => l10n.checkNationalId,
        VerificationKind.phone => l10n.checkPhone,
        VerificationKind.workEmail => l10n.checkWorkEmail,
      };

  /// The one reason Publish is off, in words; null when it is on or only a
  /// document is missing (the chips above say that).
  static String? _reason(AppLocalizations l10n, OfferCheck check) {
    if (check.missing.isNotEmpty) return null;
    return switch (check.fit.kind) {
      TripFitKind.create => null,
      TripFitKind.join => l10n.joinsTripInstead(l10n.time(check.joinTime ?? const Clock.hm(0, 0))),
      TripFitKind.full => l10n.yourCarFull,
      TripFitKind.limitReached => l10n.dailyLimitReached,
      TripFitKind.doesntFit => l10n.doesntFit,
      TripFitKind.oneGroupOnly => l10n.oneGroupOnly,
      TripFitKind.overlap => l10n.overlapTrip,
    };
  }
}

/// A published trip: seats filling, who is booked, Cancel trip.
class _Live extends ConsumerWidget {
  const _Live({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(nowProvider)().date;
    return ref.watch(offerLiveProvider(id)).when(
          loading: () => const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(key: Key('offer-loading'))),
          ),
          error: (_, _) => Column(
            key: const Key('offer-error'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.todayError, style: AppTypography.body.copyWith(color: AppColors.textBody)),
              const SizedBox(height: AppSpacing.md),
              GooraPrimaryButton(
                key: const Key('offer-retry'),
                label: l10n.retry,
                onPressed: () => ref.invalidate(offerLiveProvider(id)),
              ),
            ],
          ),
          data: (live) {
            final trip = live.trip;
            final note = offerStateNote(l10n, trip.status);
            final open = trip.status == OfferStatus.open || trip.status == OfferStatus.full;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GooraCard(
                  key: const Key('offer-live'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.routeLine(l10n.area(trip.from), l10n.area(trip.to)),
                        style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        offerWhen(l10n, trip, today),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${l10n.tlPickup(l10n.time(trip.pickup.time))} — ${l10n.stopName(trip.pickup.name)}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (note != null)
                        Text(
                          note,
                          key: const Key('offer-state'),
                          style: AppTypography.bodyStrong.copyWith(color: AppColors.textBody),
                        )
                      else
                        OfferProgress(live: live),
                      if (trip.status != OfferStatus.cancelled) ...[
                        const SizedBox(height: AppSpacing.md),
                        LiveRidersList(riders: live.riders),
                      ],
                    ],
                  ),
                ),
                if (open) ...[
                  const SizedBox(height: AppSpacing.md),
                  GooraGhostButton(
                    key: const Key('cancel-trip'),
                    label: l10n.cancelTrip,
                    danger: true,
                    onPressed: () => cancelOfferWithConfirm(context, ref, id),
                  ),
                ],
              ],
            );
          },
        );
  }
}
