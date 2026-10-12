import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../domain/payment_provider.dart';
import 'wallet_controller.dart';

Future<void> showTopUpSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const TopUpSheet(),
    );

/// FR-006: top up by method + amount; a failure leaves balance/activity
/// unchanged with an inline, blame-free retry (SC-005).
class TopUpSheet extends ConsumerStatefulWidget {
  const TopUpSheet({super.key});

  @override
  ConsumerState<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<TopUpSheet> {
  static const _methods = ['instapay', 'vodafone', 'card'];
  static const _amounts = [200, 400, 800];

  String _method = _methods.first;
  int _amount = _amounts.first;
  bool _busy = false;
  bool _failed = false;

  String _methodLabel(AppLocalizations l10n, String method) => switch (method) {
        'instapay' => l10n.topUpMethodInstaPay,
        'vodafone' => l10n.topUpMethodVodafone,
        'card' => l10n.topUpMethodCard,
        _ => throw ArgumentError(method),
      };

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final result = await ref.read(walletControllerProvider.notifier).topUp(method: _method, amount: _amount);
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
            Text(l10n.topUpSheetTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.gap),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final m in _methods)
                  GooraPill(key: Key('top-up-method-$m'), label: _methodLabel(l10n, m), selected: _method == m, onTap: () => setState(() => _method = m)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final a in _amounts)
                  GooraPill(
                    key: Key('top-up-amount-$a'),
                    label: l10n.egpAmount(a),
                    selected: _amount == a,
                    onTap: () => setState(() => _amount = a),
                  ),
              ],
            ),
            if (_failed) ...[
              const SizedBox(height: AppSpacing.gap),
              GooraBanner(
                kind: GooraBannerKind.warning,
                title: l10n.topUpFailTitle,
                body: l10n.topUpFailBody,
                actionLabel: l10n.retry,
                onAction: _confirm,
              ),
            ],
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('top-up-confirm'),
              label: l10n.topUpConfirm,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
