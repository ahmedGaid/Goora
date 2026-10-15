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
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/place.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/presentation/labels.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/seat_price.dart';
import '../../../wallet/presentation/labels.dart';
import '../../../wallet/presentation/wallet/top_up_sheet.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../data/market_seed.dart';
import '../../data/providers.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';
import '../../domain/trip_request.dart';
import '../route_form.dart';
import 'post_trip_controller.dart';

/// Post your trip (B): a rider asks drivers for a seat. The price is Goora's
/// and fixed; nothing is charged until a driver accepts (FR-012, FR-022).
class PostTripScreen extends ConsumerStatefulWidget {
  const PostTripScreen({super.key, this.id, this.draft});

  /// A posted request to watch; null starts a new one.
  final String? id;

  /// Edits to restore after the payment-method detour; null starts from the commute.
  final PostTripDraft? draft;

  @override
  ConsumerState<PostTripScreen> createState() => _PostTripScreenState();
}

enum _NoticeKind { topUp, daily }

class _PostTripScreenState extends ConsumerState<PostTripScreen> {
  late String? _id = widget.id;
  late Area? _from = widget.draft?.from;
  late Area? _to = widget.draft?.to;
  late Clock? _departure = widget.draft?.departure;
  late Repeat _repeat = widget.draft?.repeat ?? Repeat.once;
  bool _busy = false;
  _NoticeKind? _notice;
  int _gap = 0;

  void _back() => context.canPop() ? context.pop() : context.go(Routes.frequency);

  Future<void> _post(PostStart start) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    final from = _from ?? start.from;
    final to = _to ?? start.to;
    final draft = TripDraft(
      leg: from == Area.smartVillage ? Leg.ret : Leg.going,
      from: from,
      to: to,
      departure: _departure ?? start.departure,
      repeat: start.inGroup ? Repeat.once : _repeat,
    );
    final result = await ref.read(marketplaceRepositoryProvider).post(draft, now: ref.read(nowProvider)());
    if (!mounted) return;
    switch (result) {
      case Posted(:final request):
        ref
          ..invalidate(myPostedRequestsProvider)
          ..invalidate(postedRequestProvider);
        setState(() {
          _id = request.id;
          _busy = false;
        });
        return;
      case PostNeedsMethod():
        setState(() => _busy = false);
        final back = Routes.postTripDraft(
          from: from.name,
          to: to.name,
          at: draft.departure.minutes,
          repeat: draft.repeat.name,
        );
        context.push('${Routes.payMethod}?next=${Uri.encodeQueryComponent(back)}');
        return;
      case PostTopUp(:final gap):
        _gap = gap;
        _notice = _NoticeKind.topUp;
      case DailyNotAllowed():
        _notice = _NoticeKind.daily;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = _id;
    return OnboardingScaffold(
      title: l10n.postReq,
      onBack: _back,
      body: id != null
          ? _Posted(
              id: id,
              onPostAgain: () => setState(() {
                _id = null;
                _notice = null;
              }),
            )
          : _form(l10n),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final start = ref.watch(postStartProvider);
    return start.when(
      loading: () => const Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(key: Key('post-loading'))),
      ),
      error: (_, _) => _ErrorRetry(keyPrefix: 'post', onRetry: () => ref.invalidate(postStartProvider)),
      data: (s) {
        final now = ref.watch(nowProvider)();
        final mode = ref.watch(riderPricingProvider).value;
        final price = mode == null
            ? null
            : SeatPrice.of(
                PricingService.range(MarketSeed.tripCost, MarketSeed.riderSeats).suggested,
                tripCost: MarketSeed.tripCost,
                riderSeats: MarketSeed.riderSeats,
                mode: mode,
              );
        final from = _from ?? s.from;
        final to = _to ?? s.to;
        // A rider in a daily group can only post a one-off trip (R10).
        final repeat = s.inGroup ? Repeat.once : _repeat;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_notice == _NoticeKind.topUp) ...[
              GooraBanner(
                key: const Key('notice-top-up'),
                kind: GooraBannerKind.warning,
                title: l10n.topUpFirst(_gap),
                body: l10n.needsTopUpBody(_gap),
                actionLabel: l10n.actTopUp,
                onAction: () async {
                  await showTopUpSheet(context);
                  if (mounted) setState(() => _notice = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_notice == _NoticeKind.daily) ...[
              GooraBanner(key: const Key('notice-daily'), kind: GooraBannerKind.info, title: l10n.dailyNeedsNoGroup, body: ''),
              const SizedBox(height: AppSpacing.md),
            ],
            RouteForm(
              from: from,
              to: to,
              departure: _departure ?? s.departure,
              repeat: repeat,
              now: now,
              dailyBlockedReason: s.inGroup ? l10n.dailyNeedsNoGroup : null,
              onFrom: (a) => setState(() {
                if (a == to) _to = from;
                _from = a;
              }),
              onTo: (a) => setState(() {
                if (a == from) _from = to;
                _to = a;
              }),
              onShift: (d) => setState(() => _departure = (_departure ?? s.departure).shift(d)),
              onRepeat: (r) => setState(() => _repeat = r),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (price != null)
              Text(
                l10n.priceLine(price),
                key: const Key('post-price'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
            const SizedBox(height: AppSpacing.md),
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
            GooraPrimaryButton(
              key: const Key('post'),
              label: l10n.post,
              onPressed: _busy ? null : () => _post(s),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.keyPrefix, required this.onRetry});

  final String keyPrefix;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: Key('$keyPrefix-error'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.todayError, style: AppTypography.body.copyWith(color: AppColors.textBody)),
        const SizedBox(height: AppSpacing.md),
        GooraPrimaryButton(key: Key('$keyPrefix-retry'), label: l10n.retry, onPressed: onRetry),
      ],
    );
  }
}

/// A posted request: waiting, accepted, expired or withdrawn.
class _Posted extends ConsumerWidget {
  const _Posted({required this.id, required this.onPostAgain});

  final String id;
  final VoidCallback onPostAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref.watch(postedRequestProvider(id)).when(
          loading: () => const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(key: Key('posted-loading'))),
          ),
          error: (_, _) => _ErrorRetry(keyPrefix: 'posted', onRetry: () => ref.invalidate(postedRequestProvider(id))),
          data: (r) {
            if (r == null) return _ErrorRetry(keyPrefix: 'posted', onRetry: () => ref.invalidate(postedRequestProvider(id)));
            return switch (r.status) {
              RequestStatus.posted => _Waiting(request: r),
              RequestStatus.accepted => _Accepted(request: r),
              RequestStatus.withdrawn => _Withdrawn(onPostAgain: onPostAgain),
              RequestStatus.expired || RequestStatus.cancelled => Column(
                  key: const Key('request-expired'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      r.status == RequestStatus.expired ? l10n.requestExpired : l10n.postAgain,
                      style: AppTypography.body.copyWith(color: AppColors.textBody),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GooraPrimaryButton(key: const Key('post-again'), label: l10n.postAgain, onPressed: onPostAgain),
                    const SizedBox(height: AppSpacing.md),
                    GooraGhostButton(
                      key: const Key('see-empty-seats'),
                      label: l10n.seeEmptySeats,
                      onPressed: () => context.push(Routes.emptySeatsOn(r.leg)),
                    ),
                  ],
                ),
            };
          },
        );
  }
}

class _Waiting extends ConsumerWidget {
  const _Waiting({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(nowProvider)().date;
    final sent = ref.watch(sentToProvider(request.id)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraCard(
          key: const Key('request-posted'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.routeLine(l10n.area(request.from), l10n.area(request.to)),
                style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                '${l10n.heroWhen(request.date, today)} · ${l10n.time(request.departure)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (sent != null)
                Text(
                  l10n.sentToDrivers(sent),
                  key: const Key('sent-to'),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText),
                ),
              Text(l10n.waitingDriver, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.priceLine(request.price), style: AppTypography.body.copyWith(color: AppColors.textBody)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GooraGhostButton(
          key: const Key('cancel-request'),
          label: l10n.cancelRequest,
          danger: true,
          onPressed: () async {
            await ref.read(marketplaceRepositoryProvider).cancelRequest(request.id);
            ref
              ..invalidate(postedRequestProvider(request.id))
              ..invalidate(myPostedRequestsProvider);
            if (context.mounted) context.canPop() ? context.pop() : context.go(Routes.today);
          },
        ),
      ],
    );
  }
}

class _Accepted extends ConsumerWidget {
  const _Accepted({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(nowProvider)().date;
    final driver = MarketSeed.driverById(request.acceptedBy ?? '');
    final daily = request.tripId?.contains(':') ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraCard(
          key: const Key('request-accepted'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.requestAccepted, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
              const SizedBox(height: AppSpacing.md),
              if (driver != null)
                Row(
                  children: [
                    GooraAvatar(initials: driver.initials),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(driver.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    ),
                    Text(
                      l10n.ratingStars(driver.rating.toStringAsFixed(1)),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${l10n.heroWhen(request.date, today)} · ${l10n.time(request.departure)}',
                style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                '${l10n.tlPickup(l10n.time(request.pickup.time))} — ${l10n.stopName(request.pickup.name)}',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.priceLine(request.price), style: AppTypography.body.copyWith(color: AppColors.textBody)),
              if (daily) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.nowGroup, key: const Key('now-group'), style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GooraPrimaryButton(
          key: const Key('accepted-continue'),
          label: daily ? l10n.continueBtn : l10n.backToToday,
          onPressed: () {
            ref
              ..invalidate(walletControllerProvider)
              ..invalidate(myPostedRequestsProvider);
            context.go(Routes.today);
          },
        ),
      ],
    );
  }
}

class _Withdrawn extends StatelessWidget {
  const _Withdrawn({required this.onPostAgain});

  final VoidCallback onPostAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('request-withdrawn'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraBanner(
          kind: GooraBannerKind.warning,
          title: l10n.requestWithdrawn,
          body: '',
          actionLabel: l10n.actTopUp,
          onAction: () => showTopUpSheet(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        GooraPrimaryButton(key: const Key('post-again'), label: l10n.postAgain, onPressed: onPostAgain),
      ],
    );
  }
}
