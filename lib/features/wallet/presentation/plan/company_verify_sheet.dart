import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../daily/data/providers.dart';
import '../../../daily/domain/trust.dart';
import '../../domain/plan.dart';
import 'plan_controller.dart';

Future<void> showCompanyVerifySheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const CompanyVerifySheet(),
    );

/// Reuses 001's work-email verification pattern (FR-003): confirms with the
/// already-verified company on file, then starts the Company plan.
class CompanyVerifySheet extends ConsumerStatefulWidget {
  const CompanyVerifySheet({super.key});

  @override
  ConsumerState<CompanyVerifySheet> createState() => _CompanyVerifySheetState();
}

class _CompanyVerifySheetState extends ConsumerState<CompanyVerifySheet> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    await ref.read(planControllerProvider.notifier).choosePlan(PlanType.company);
    if (!mounted) return;
    Navigator.of(context).pop();
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
        child: FutureBuilder<TrustProfile>(
          future: ref.read(trustRepositoryProvider).profile(),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final verified = profile?.company != null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.verifyEmailTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  verified ? l10n.verifyEmailBody(profile!.company!) : l10n.verifyNotVerified,
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.gap),
                GooraPrimaryButton(
                  key: const Key('verify-confirm'),
                  label: l10n.verifyConfirm,
                  onPressed: verified && !_busy ? _confirm : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
