import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../domain/payment_provider.dart';
import 'wallet_controller.dart';

Future<void> showWithdrawSheet(BuildContext context, {required int amount}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => WithdrawSheet(amount: amount),
    );

/// FR-010: withdraw the driver's full recoverable balance; a failure leaves
/// balance/activity unchanged with an inline, blame-free retry (SC-005).
class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key, required this.amount});

  final int amount;

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final result = await ref.read(walletControllerProvider.notifier).withdraw(amount: widget.amount);
    if (!mounted) return;
    if (result == PaymentResult.success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.tabH,
          end: AppSpacing.tabH,
          top: AppSpacing.tabH,
          bottom: AppSpacing.tabH + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.withdrawSheetTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.egpAmount(widget.amount), style: AppTypography.display.copyWith(color: AppColors.textPrimary)),
            if (_failed) ...[
              const SizedBox(height: AppSpacing.gap),
              GooraBanner(
                kind: GooraBannerKind.warning,
                title: l10n.withdrawFailTitle,
                body: l10n.withdrawFailBody,
                actionLabel: l10n.retry,
                onAction: _confirm,
              ),
            ],
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('withdraw-confirm'),
              label: l10n.withdrawConfirm,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
