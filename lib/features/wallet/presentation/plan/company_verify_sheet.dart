import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../company/presentation/company_controller.dart';
import '../../../company/presentation/company_offer_view.dart';

/// True when the person joined through it (consent given); false when they
/// closed it, declined, or had nothing to join.
Future<bool> showCompanyVerifySheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const CompanyVerifySheet(),
    ) ??
    false;

/// "Through my company" (010 US2): what the company network offers this
/// person (`offerFor`) — verify first, not on Goora yet, join (consent
/// first) or already enrolled. Joining goes through the company network
/// (`CompanyRepository.enroll`), never `subscribe(PlanType.company)`.
class CompanyVerifySheet extends ConsumerWidget {
  const CompanyVerifySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(companyAccountProvider);
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
            Text(l10n.verifyEmailTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            // The last value stays on screen while a join reloads it, so the
            // offer view (and its "joined" callback) is never torn down.
            if (account.value case final view?)
              CompanyOfferView(offer: view.offer, onEnrolled: () => Navigator.of(context).pop(true))
            else if (account.hasError)
              Text(l10n.verifyNotVerified, style: AppTypography.body.copyWith(color: AppColors.textSecondary))
            else
              const Padding(
                padding: EdgeInsetsDirectional.all(AppSpacing.gap),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
