import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_radio_card.dart';
import '../../../daily/data/providers.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../data/providers.dart';
import '../../domain/payment_method.dart';
import '../../domain/seat_price.dart';
import '../labels.dart';
import '../wallet/wallet_controller.dart';

/// v2 US1: right after "Join this group" a rider picks cash (first 10 trips)
/// or the wallet; subscribing is a small link, never a required step.
/// Drivers never route here (router.dart only sends riders).
class PayMethodScreen extends ConsumerStatefulWidget {
  const PayMethodScreen({super.key, this.next});

  /// Where to go after choosing (a seat the rider picked); Today when null.
  final String? next;

  @override
  ConsumerState<PayMethodScreen> createState() => _PayMethodScreenState();
}

class _PayMethodScreenState extends ConsumerState<PayMethodScreen> {
  PaymentMethod _selected = PaymentMethod.cash;
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(walletRepositoryProvider).setMethod(meId, _selected);
    ref
      ..invalidate(riderPricingProvider)
      ..invalidate(walletControllerProvider);
    if (mounted) context.go(widget.next ?? Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(walletControllerProvider).value;
    // No quote on the loading frame: riderSeats is 0 until the group loads.
    final walletPrice = view == null || view.riderSeats < 1
        ? null
        : SeatPrice.of(view.legShare,
            tripCost: view.groupTripCost, riderSeats: view.riderSeats, mode: PricingMode.wallet);
    return OnboardingScaffold(
      title: l10n.payMethodTitle,
      subtitle: l10n.payMethodSub,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraRadioCard(
            key: const Key('pay-cash'),
            title: l10n.payCash,
            subtitle: l10n.payCashSub,
            selected: _selected == PaymentMethod.cash,
            onTap: () => setState(() => _selected = PaymentMethod.cash),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('pay-wallet'),
            title: l10n.payWallet,
            subtitle: walletPrice == null ? null : l10n.priceLine(walletPrice),
            selected: _selected == PaymentMethod.wallet,
            onTap: () => setState(() => _selected = PaymentMethod.wallet),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraPrimaryButton(
            key: const Key('pay-continue'),
            label: l10n.continueBtn,
            onPressed: _busy ? null : _continue,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('subscribe-link'),
            onPressed: () => context.go(Routes.plan),
            child: Text(l10n.subscribeLink, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          ),
        ],
      ),
    );
  }
}
