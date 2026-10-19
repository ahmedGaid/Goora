import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../../core/widgets/goora_text_field.dart';
import '../../../daily/data/providers.dart';
import '../../data/fake_wallet_repository.dart';
import '../../data/providers.dart';
import '../../domain/direct_pay.dart';
import '../../domain/share.dart';
import '../labels.dart';
import 'activity_row.dart';
import 'wallet_controller.dart';
import 'withdraw_sheet.dart';

/// A driver's side of direct pay (007 US4): what passengers paid them
/// directly this month, each passenger's share and where it stands, their
/// InstaPay handle, and the trip-cost breakdown. Goora holds none of the
/// driver's money, so there is no balance to withdraw — except a 004 balance
/// left from before, which can still be taken out.
class DriverWallet extends StatelessWidget {
  const DriverWallet({super.key, required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final legacy = view.wallet.balance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraHeroCard(
          key: const Key('cash-received'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.cashReceivedTitle, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.egpAmount(view.wallet.cashReceived), style: AppTypography.display.copyWith(color: AppColors.white)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.cashReceivedNote, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody)),
              if (legacy > 0) ...[
                const SizedBox(height: AppSpacing.gap),
                GooraPrimaryButton(
                  key: const Key('withdraw'),
                  label: l10n.withdraw,
                  variant: GooraPrimaryVariant.onDark,
                  onPressed: () => showWithdrawSheet(context, amount: legacy),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        Text(l10n.paymentsTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        if (view.wallet.shares.isEmpty)
          GooraCard(
            key: const Key('payments-empty'),
            child: Text(l10n.paymentsEmpty, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          )
        else
          GooraCard.rows(
            key: const Key('payments-list'),
            rows: [for (final s in view.wallet.shares) _PaymentRow(share: s)],
          ),
        const SizedBox(height: AppSpacing.gap),
        const InstapayHandleCard(),
        if (view.wallet.activity.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.gap),
          Text(l10n.activityTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          GooraCard.rows(key: const Key('activity-list'), rows: [for (final e in view.wallet.activity) ActivityRow(entry: e)]),
        ],
        // No group (a once driver): there is no per-group trip cost to break down.
        if (view.hasGroup) ...[
          const SizedBox(height: AppSpacing.gap),
          GooraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.driverBreakdownTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                _BreakdownRow(label: l10n.driverBreakdownCost, value: l10n.egpAmount(view.dayTripCost)),
                const SizedBox(height: AppSpacing.xs),
                _BreakdownRow(label: l10n.driverBreakdownReceived, value: l10n.egpAmount(view.receivedFromRiders)),
                if (view.driverGap > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _BreakdownRow(label: l10n.driverBreakdownGap, value: l10n.egpAmount(view.driverGap)),
                ],
                const Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                _BreakdownRow(label: l10n.driverBreakdownFree, value: null, strong: true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One passenger's share: first name, amount, and a status in words (never
/// colour alone).
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.share});

  final Share share;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chip = switch (share.status) {
      ShareStatus.received => GooraStatusChip(status: GooraStatus.covered, label: l10n.cashMarkedReceived),
      ShareStatus.autoReceived => GooraStatusChip(status: GooraStatus.covered, label: l10n.shareAutoReceived),
      ShareStatus.pending => GooraStatusChip(status: GooraStatus.waiting, label: l10n.sharePending),
      ShareStatus.disputed =>
        GooraStatusChip(status: GooraStatus.waiting, label: l10n.shareDisputed(share.otherFirstName)),
      ShareStatus.notReceived => GooraStatusChip(status: GooraStatus.off, label: l10n.cashMarkedUnpaid),
    };
    return Padding(
      key: Key('payment-${share.rideId}-${share.riderId}'),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(share.otherFirstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                Text(
                  '${l10n.shortDate(share.tripEnd.date)} · ${l10n.egpAmount(share.amount)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Flexible(child: Align(alignment: AlignmentDirectional.centerEnd, child: chip)),
        ],
      ),
    );
  }
}

/// The driver's InstaPay handle, shown to a passenger only once their
/// booking is confirmed (007 FR-013, research R7). Optional.
class InstapayHandleCard extends ConsumerStatefulWidget {
  const InstapayHandleCard({super.key});

  @override
  ConsumerState<InstapayHandleCard> createState() => _InstapayHandleCardState();
}

class _InstapayHandleCardState extends ConsumerState<InstapayHandleCard> {
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final handle = await ref.read(walletRepositoryProvider).instapayHandleOf(meId);
    if (!mounted) return;
    setState(() {
      _controller.text = handle ?? '';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(walletRepositoryProvider).setInstapayHandle(meId, _controller.text);
    await _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      key: const Key('instapay-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraTextField(
            key: const Key('instapay-field'),
            controller: _controller,
            label: l10n.instapayHandleLabel,
            ltr: true,
            maxLength: FakeWalletRepository.instapayMaxLength,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.instapayHandleHint, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          GooraGhostButton(
            key: const Key('instapay-save'),
            label: l10n.instapaySave,
            onPressed: _loaded ? _save : null,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String? value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = (strong ? AppTypography.bodyStrong : AppTypography.body).copyWith(color: AppColors.textPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        if (value != null) Text(value!, style: style),
      ],
    );
  }
}
