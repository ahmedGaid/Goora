import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_dashed_button.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_route_map.dart';
import '../../../../core/widgets/goora_stat_tile.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../../core/widgets/goora_timeline_row.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/group.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../commute/presentation/labels.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/payment_method.dart';
import '../../../wallet/presentation/labels.dart';
import '../../data/providers.dart';
import '../../domain/location_source.dart';
import '../../domain/ride.dart';
import '../../domain/schedule.dart';
import '../labels.dart';
import '../now_ticker.dart';
import 'cant_come_sheet.dart';
import 'today_controller.dart';
import 'today_widgets.dart';

/// Rider Today, top to bottom as US1/AC2.
class RiderToday extends StatelessWidget {
  const RiderToday({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = view.display;
    final next = view.upcomingRides.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodayBanners(view: view),
        RideHero(view: view),
        const SizedBox(height: AppSpacing.gap),
        if (day != null) ...[
          LegsCard(view: view, day: day),
          const SizedBox(height: AppSpacing.gap),
          TripMapCard(view: view, next: next),
          const SizedBox(height: AppSpacing.gap),
          if (next?.driver != null) ...[
            DriverCard(view: view, driver: next!.driver!),
            const SizedBox(height: AppSpacing.gap),
          ],
          if (next != null) ...[
            TripTimeline(view: view, leg: next),
            const SizedBox(height: AppSpacing.gap),
          ],
          _Tiles(view: view, day: day),
          const SizedBox(height: AppSpacing.gap),
        ],
        SafetyRow(view: view),
        const SizedBox(height: AppSpacing.gap),
        CantComeButton(view: view),
        const SizedBox(height: AppSpacing.gap),
        GooraDashedButton(
          key: const Key('extra-trip'),
          label: l10n.extraTrip,
          onPressed: () => context.push(Routes.emptySeats),
        ),
      ],
    );
  }
}

/// Dark hero: "Your ride is confirmed · 7:25 AM · area → area", or the next
/// ride day (no countdown) when today has no trip left (US1/AC5).
class RideHero extends StatelessWidget {
  const RideHero({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = view.group!;
    final day = view.display;
    final next = view.upcomingRides.firstOrNull ?? day?.riding.firstOrNull;
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary);
    if (day == null || next == null) {
      return GooraHeroCard(
        child: Text(l10n.noRidesSoon, style: AppTypography.bodyStrong.copyWith(color: AppColors.white)),
      );
    }
    final isToday = day.date == view.now.date;
    final going = next.leg == Leg.going;
    return GooraHeroCard(
      key: const Key('ride-hero'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? (next.driver != null ? l10n.confirmed : l10n.noDriverYet) : l10n.nextRide(l10n.heroWhen(day.date, view.now.date)),
            style: secondary,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.time(next.stop.time), style: AppTypography.heroTime.copyWith(color: AppColors.white)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.routeLine(l10n.area(going ? g.origin : g.destination), l10n.area(going ? g.destination : g.origin)),
            style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody),
          ),
        ],
      ),
    );
  }
}

/// One row per leg with its driver, time and status, plus the separate-trips note.
class LegsCard extends StatelessWidget {
  const LegsCard({super.key, required this.view, required this.day});

  final TodayView view;
  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[
      for (final l in day.legs.where((l) => l.duty != Duty.drive))
        Row(
          key: Key('leg-${l.leg.name}'),
          children: [
            Expanded(
              child: Text(
                l10n.legRow(
                  l10n.legName(l.leg),
                  l.driver == null ? l10n.noDriverYet : nameFor(l10n, view, l.driver!.id),
                  l10n.time(l.stop.time),
                ),
                style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (l.duty == Duty.off)
              GooraStatusChip(status: GooraStatus.off, label: l10n.youOff)
            else if (l.driver != null)
              GooraStatusChip(status: GooraStatus.covered, label: l10n.covered)
            else
              GooraStatusChip(status: GooraStatus.waiting, label: l10n.noDriverYet),
          ],
        ),
      for (final e in view.otherLegs.entries)
        Text(
          e.key == Leg.going ? l10n.goingLeg(l10n.time(e.value)) : l10n.returnLeg(l10n.time(e.value)),
          style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
        ),
      Text(l10n.legsNote, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
    ];
    return GooraCard.rows(rows: rows);
  }
}

/// Route card. Before pickup: the pickup countdown. During an active trip
/// (driver arrived at my stop → arrival, US7/AC1): the live driver marker
/// and the arrival countdown. Also on driver Today for legs they ride off
/// duty (FR-028).
class TripMapCard extends StatelessWidget {
  const TripMapCard({super.key, required this.view, required this.next});

  final TodayView view;
  final LegPlan? next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = view.group!;
    final leg = next;
    final going = leg?.leg != Leg.ret;
    final ride = leg?.ride;
    final live = leg != null && ride != null && ride.driverId != null && ride.arrivedStopIds.contains(leg.stop.id);
    final countdownFor = leg != null && leg.date == view.now.date ? (live ? leg.end : leg.pickup) : null;
    Widget map(double? progress) => GooraRouteMap(
          fromLabel: l10n.area(going ? g.origin : g.destination),
          toLabel: l10n.area(going ? g.destination : g.origin),
          semanticLabel: live ? l10n.mapLiveAria : l10n.mapAria,
          driverProgress: progress,
        );
    return GooraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (live) _LiveMap(rideId: ride.id, builder: map) else map(null),
          if (countdownFor != null)
            NowTicker(
              builder: (context, now) {
                final minutes = now.minutesUntil(countdownFor);
                if (minutes <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(GooraIcons.pin, size: AppSizes.iconSmall, color: AppColors.greenText),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          key: Key(live ? 'arrival-countdown' : 'pickup-countdown'),
                          live ? l10n.arrivalInMin(minutes) : l10n.pickupInMin(minutes),
                          style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Subscribes once per ride to [locationSourceProvider] and redraws only
/// the map with each position.
class _LiveMap extends ConsumerStatefulWidget {
  const _LiveMap({required this.rideId, required this.builder});

  final String rideId;
  final Widget Function(double? progress) builder;

  @override
  ConsumerState<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<_LiveMap> {
  late Stream<TripPosition> _positions = ref.read(locationSourceProvider).watch(widget.rideId);

  @override
  void didUpdateWidget(_LiveMap old) {
    super.didUpdateWidget(old);
    if (old.rideId != widget.rideId) _positions = ref.read(locationSourceProvider).watch(widget.rideId);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<TripPosition>(
        stream: _positions,
        builder: (context, snap) => KeyedSubtree(
          key: const Key('live-map'),
          child: widget.builder(snap.data?.progress ?? 0),
        ),
      );
}

/// Avatar, name, verified badge, car and colour, rating, and "Call driver"
/// (only ever the current or next trip's driver, US1/AC4).
class DriverCard extends ConsumerWidget {
  const DriverCard({super.key, required this.view, required this.driver});

  final TodayView view;
  final Member driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vehicle = driver.vehicle;
    final rating = driver.rating.toStringAsFixed(1);
    return GooraCard(
      key: const Key('driver-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GooraAvatar(initials: driver.initials, paletteIndex: paletteFor(view, driver.id)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(driver.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(GooraIcons.verified, size: AppSizes.iconTiny, color: AppColors.greenText),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(l10n.verified, style: AppTypography.microBold.copyWith(color: AppColors.greenText)),
                      ],
                    ),
                    Text(
                      vehicle == null ? l10n.ratingStars(rating) : l10n.carLine(vehicle.make, l10n.colour(vehicle.colour), rating),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (driver.phone != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: l10n.callName(driver.firstName),
              excludeSemantics: true,
              button: true,
              child: GooraGhostButton(
                key: const Key('call-driver'),
                label: l10n.callDriver,
                icon: GooraIcons.phone,
                onPressed: () => ref.read(phoneDialerProvider).dial(driver.phone!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pickup → On the way → Arrival for one trip.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.view, required this.leg});

  final TodayView view;
  final LegPlan leg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = view.group!;
    final names = [for (final p in leg.ride?.passengers ?? const <Passenger>[]) nameFor(l10n, view, p.memberId)];
    return GooraCard(
      child: Column(
        children: [
          GooraTimelineRow(
            kind: GooraTimelineKind.pickup,
            title: l10n.tlPickup(l10n.time(leg.stop.time)),
            subtitle: l10n.stopName(leg.stop.name),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraTimelineRow(
            kind: GooraTimelineKind.transit,
            title: l10n.tlOnTheWay,
            subtitle: names.isEmpty ? null : l10n.tlPassengers(names.length, names.join(l10n.listSep)),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraTimelineRow(
            kind: GooraTimelineKind.arrival,
            title: l10n.tlArrival(l10n.time(leg.end.time)),
            subtitle: leg.leg == Leg.going ? l10n.stopName(g.workStop.name) : l10n.area(g.origin),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends ConsumerWidget {
  const _Tiles({required this.view, required this.day});

  final TodayView view;
  final DayPlan day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final price = view.group!.price;
    final mode = ref.watch(riderPricingProvider).value ?? PricingMode.wallet;
    final fee = mode == PricingMode.wallet
        ? PricingService.serviceFee(price, isSubscriber: false, isCashTrial: false)
        : 0;
    final ret = day.leg(Leg.ret);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GooraStatTile(
              label: l10n.returnTime,
              value: ret == null ? l10n.noReturnTrip : l10n.time(ret.stop.time),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GooraStatTile(
              key: const Key('pay-tile'),
              label: l10n.payPerTrip,
              value: l10n.egpAmount(price + fee),
              caption: l10n.priceLine(price, mode, fee: fee),
            ),
          ),
        ],
      ),
    );
  }
}

/// "I can't come tomorrow" + the rule caption; opens the cancel sheet for
/// the next ride day.
class CantComeButton extends StatelessWidget {
  const CantComeButton({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = view.target;
    if (target == null || target.riding.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraGhostButton(
          key: const Key('cant-come'),
          label: l10n.cantCome,
          danger: true,
          onPressed: () => showCantComeSheet(context, target),
        ),
        Caption(l10n.cantComeNote),
      ],
    );
  }
}
