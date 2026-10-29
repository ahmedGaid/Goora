import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../data/providers.dart';
import '../../domain/fee_balance.dart';
import '../../domain/payment_provider.dart';
import 'wallet_controller.dart';

/// What a pay sheet pays for (008): everything owed to Goora, or a bundle.
enum PayPurpose { settle, bundle }

Future<void> showPaySheet(BuildContext context, PayPurpose purpose) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => PaySheet(purpose: purpose),
    );

/// 008 FR-003 / FR-007: one payment by mobile wallet, InstaPay, Fawry code
/// or card — never a required card. A failure changes nothing and offers a
/// blame-free retry. Fawry is two steps: "Get my Fawry code" shows the
/// reference code and how to pay with it, and only "I paid at Fawry" settles
/// (the fakes settle at once; walk N-12: it used to give no code first).
class PaySheet extends ConsumerStatefulWidget {
  const PaySheet({super.key, required this.purpose});

  final PayPurpose purpose;

  @override
  ConsumerState<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<PaySheet> {
  static const _methods = ['vodafone', 'instapay', 'fawry', 'card'];

  String _method = _methods.first;
  bool _busy = false;
  bool _failed = false;

  /// Fawry only: the reference code has been asked for and is on screen.
  bool _codeShown = false;

  String _label(AppLocalizations l10n, String method) => switch (method) {
        'vodafone' => l10n.topUpMethodVodafone,
        'instapay' => l10n.topUpMethodInstaPay,
        'fawry' => l10n.methodFawry,
        'card' => l10n.topUpMethodCard,
        _ => throw ArgumentError(method),
      };

  /// A stable-looking demo reference; a real one comes from Fawry.
  String _fawryCode(int amount) => '7${(amount * 7919 % 9000 + 1000)} ${(amount * 104729 % 9000 + 1000)}';

  void _pick(String method) => setState(() {
        _method = method;
        _codeShown = false;
        _failed = false;
      });

  /// The primary button: for Fawry, first reveal the code; then settle.
  Future<void> _primary() async {
    if (_method == 'fawry' && !_codeShown) {
      setState(() => _codeShown = true);
      return;
    }
    await _confirm();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final controller = ref.read(walletControllerProvider.notifier);
    final result = widget.purpose == PayPurpose.settle
        ? await controller.settle(method: _method)
        : await controller.buyBundle(method: _method);
    if (!mounted) return;
    if (result == PaymentResult.success) {
      ref.invalidate(myOpenSharesProvider);
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
    final view = ref.watch(walletControllerProvider).value;
    final amount = widget.purpose == PayPurpose.settle ? (view?.wallet.owed ?? 0) : TripBundle.price;
    final fawry = _method == 'fawry';
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.tabH,
          end: AppSpacing.tabH,
          top: AppSpacing.tabH,
          bottom: AppSpacing.tabH + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: Key('pay-sheet-${widget.purpose.name}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.purpose == PayPurpose.settle ? l10n.settleTitle : l10n.bundleTitle,
              style: AppTypography.title.copyWith(color: AppColors.textPrimary),
            ),
            if (widget.purpose == PayPurpose.bundle) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.bundleSub, style: AppTypography.body.copyWith(color: AppColors.textBody)),
            ],
            const SizedBox(height: AppSpacing.gap),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final m in _methods)
                  GooraPill(
                    key: Key('pay-method-$m'),
                    label: _label(l10n, m),
                    selected: _method == m,
                    onTap: () => _pick(m),
                  ),
              ],
            ),
            if (fawry && _codeShown) ...[
              const SizedBox(height: AppSpacing.md),
              GooraCard(
                key: const Key('fawry-code'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fawryCode(_fawryCode(amount)),
                      style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.fawryHow(amount), style: AppTypography.body.copyWith(color: AppColors.textBody)),
                  ],
                ),
              ),
            ],
            if (_failed) ...[
              const SizedBox(height: AppSpacing.gap),
              GooraBanner(
                kind: GooraBannerKind.warning,
                title: l10n.settleFailTitle,
                body: l10n.settleFailBody,
                actionLabel: l10n.retry,
                onAction: _confirm,
              ),
            ],
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('pay-confirm'),
              label: !fawry
                  ? l10n.settleConfirm(amount)
                  : (_codeShown ? l10n.fawryPaid : l10n.fawryGetCode),
              onPressed: _busy || amount == 0 ? null : _primary,
            ),
          ],
        ),
      ),
    );
  }
}
