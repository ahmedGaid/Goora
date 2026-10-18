import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/time/wall_time.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_dashed_button.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../../wallet/presentation/wallet/pay_sheet.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../data/providers.dart';
import '../../domain/booking.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/seat_offer.dart';
import 'booked_view.dart';
import 'empty_seats_controller.dart';
import 'seat_card.dart';

/// Empty seats (A): free seats on the rider's route for one leg, bookable in
/// one tap. Every limit and price is words, never colour alone (VII).
class EmptySeatsScreen extends ConsumerStatefulWidget {
  const EmptySeatsScreen({super.key, this.leg = Leg.going, this.seat});

  final Leg leg;

  /// The seat to show first — kept across the payment-method screen.
  final String? seat;

  @override
  ConsumerState<EmptySeatsScreen> createState() => _EmptySeatsScreenState();
}

class _EmptySeatsScreenState extends ConsumerState<EmptySeatsScreen> {
  late Leg _leg = widget.leg;
  bool _busy = false;
  SeatOffer? _bookedOffer;
  Booking? _booking;
  _Notice? _notice;

  // Nothing to pop (the pay-method detour replaces the stack): a booked seat
  // lives on Today; before that, Back is still onboarding's last step (T104 F8).
  void _back() => context.canPop()
      ? context.pop()
      : context.go(_booking != null ? Routes.today : Routes.frequency);

  Future<void> _book(SeatOffer offer) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    final now = ref.read(nowProvider)();
    final result = await ref.read(marketplaceRepositoryProvider).book(offer, now: now);
    if (!mounted) return;
    switch (result) {
      case Booked(:final booking):
        ref
          ..invalidate(walletControllerProvider)
          ..invalidate(seatOffersProvider)
          ..invalidate(myBookingsProvider);
        setState(() {
          _bookedOffer = offer;
          _booking = booking;
          _busy = false;
        });
        return;
      case BookNeedsId():
        setState(() => _busy = false);
        final back = '${Routes.emptySeats}?leg=${_leg.name}&seat=${Uri.encodeQueryComponent(seatKey(offer))}';
        context.push(Routes.idCheckThen(back));
        return;
      case BookNeedsMethod():
        setState(() => _busy = false);
        final next = '${Routes.emptySeats}?leg=${_leg.name}&seat=${Uri.encodeQueryComponent(seatKey(offer))}';
        context.push('${Routes.payMethod}?next=${Uri.encodeQueryComponent(next)}');
        return;
      case BookOwesDriver(:final amount, :final driverFirstName):
        _notice = _Notice.owesDriver(amount, driverFirstName);
      case BookFeeOverdue(:final amount):
        _notice = _Notice.feeOverdue(amount);
      case SeatTaken():
        ref.invalidate(seatOffersProvider);
        _notice = const _Notice.taken();
      case AlreadyRiding():
        _notice = const _Notice.alreadyRiding();
    }
    setState(() => _busy = false);
  }

  Future<void> _pay() async {
    await showPaySheet(context, PayPurpose.settle);
    if (!mounted) return;
    setState(() => _notice = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    final booked = _booking;
    return OnboardingScaffold(
      title: l10n.emptySeatsTitle,
      onBack: _back,
      body: booked != null
          ? BookedView(
              offer: _bookedOffer!,
              booking: booked,
              now: now,
              onUpsell: () => context.push('${Routes.commuteSetup}?frequency=everyDay'),
              onBack: () => context.go(Routes.today),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GooraPill(
                      key: const Key('leg-going'),
                      label: l10n.legGoing,
                      selected: _leg == Leg.going,
                      onTap: () => setState(() {
                        _leg = Leg.going;
                        _notice = null;
                      }),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GooraPill(
                      key: const Key('leg-return'),
                      label: l10n.legReturn,
                      selected: _leg == Leg.ret,
                      onTap: () => setState(() {
                        _leg = Leg.ret;
                        _notice = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_notice != null) ...[_noticeBanner(l10n, _notice!), const SizedBox(height: AppSpacing.md)],
                _List(leg: _leg, now: now, busy: _busy, chosen: widget.seat, onBook: _book),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.seatRule, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                GooraDashedButton(
                  key: const Key('post-trip'),
                  label: l10n.nothingFits,
                  onPressed: () => context.push(Routes.postTrip),
                ),
              ],
            ),
    );
  }

  Widget _noticeBanner(AppLocalizations l10n, _Notice n) => switch (n.kind) {
        _NoticeKind.owesDriver => GooraBanner(
            key: const Key('notice-owes-driver'),
            kind: GooraBannerKind.warning,
            title: l10n.owesDriver(n.amount, n.name),
            body: l10n.owesDriverBody(n.name),
          ),
        _NoticeKind.feeOverdue => GooraBanner(
            key: const Key('notice-fee-overdue'),
            kind: GooraBannerKind.warning,
            title: l10n.feeOwed(n.amount),
            body: l10n.feeOverdueBody,
            actionLabel: l10n.payNow,
            onAction: _pay,
          ),
        _NoticeKind.taken => GooraBanner(
            key: const Key('notice-taken'),
            kind: GooraBannerKind.info,
            title: l10n.seatJustTaken,
            body: '',
          ),
        _NoticeKind.alreadyRiding => GooraBanner(
            key: const Key('notice-already-riding'),
            kind: GooraBannerKind.info,
            title: l10n.alreadyRiding,
            body: '',
          ),
      };
}

enum _NoticeKind { owesDriver, feeOverdue, taken, alreadyRiding }

final class _Notice {
  const _Notice.owesDriver(this.amount, this.name) : kind = _NoticeKind.owesDriver;
  const _Notice.feeOverdue(this.amount) : kind = _NoticeKind.feeOverdue, name = '';
  const _Notice.taken() : kind = _NoticeKind.taken, amount = 0, name = '';
  const _Notice.alreadyRiding() : kind = _NoticeKind.alreadyRiding, amount = 0, name = '';

  final _NoticeKind kind;

  /// owesDriver only: what is owed and to whom (first name, 007 FR-018).
  final int amount;
  final String name;
}

class _List extends ConsumerWidget {
  const _List({required this.leg, required this.now, required this.busy, required this.chosen, required this.onBook});

  final Leg leg;
  final WallTime now;
  final bool busy;
  final String? chosen;
  final void Function(SeatOffer) onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref.watch(seatOffersProvider(leg)).when(
          loading: () => const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(key: Key('seats-loading'))),
          ),
          error: (_, _) => Column(
            key: const Key('seats-error'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.todayError, style: AppTypography.body.copyWith(color: AppColors.textBody)),
              const SizedBox(height: AppSpacing.md),
              GooraPrimaryButton(
                key: const Key('seats-retry'),
                label: l10n.retry,
                onPressed: () => ref.invalidate(seatOffersProvider(leg)),
              ),
            ],
          ),
          data: (offers) {
            if (offers.isEmpty) {
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.noSeatsOnRoute,
                  key: const Key('seats-empty'),
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            // The seat the rider picked before choosing how to pay comes first.
            final sorted = [...offers]..sort((a, b) => (seatKey(b) == chosen ? 1 : 0) - (seatKey(a) == chosen ? 1 : 0));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in sorted) ...[
                  SeatCard(offer: o, now: now, busy: busy, chosen: seatKey(o) == chosen, onBook: () => onBook(o)),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        );
  }
}
