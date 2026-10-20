import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../daily/data/providers.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/domain/plan.dart';
import '../../wallet/presentation/labels.dart';
import '../domain/company_repository.dart';
import 'company_controller.dart';
import 'consent_sheet.dart';

/// What "Through my company" offers the signed-in person, one designed state
/// per [EnrollOffer] (US2): verify first · not on Goora yet (+ Tell your HR)
/// · join through the company (consent first) · already enrolled since.
/// Used by the Plan screen's sheet and the company area. [onEnrolled] runs
/// after a successful join.
class CompanyOfferView extends ConsumerStatefulWidget {
  const CompanyOfferView({super.key, required this.offer, this.onEnrolled});

  final EnrollOffer offer;
  final VoidCallback? onEnrolled;

  @override
  ConsumerState<CompanyOfferView> createState() => _CompanyOfferViewState();
}

class _CompanyOfferViewState extends ConsumerState<CompanyOfferView> {
  bool _busy = false;

  /// The paid days a personal plan has left today; they pause on joining
  /// (the same count `startCompanyPlan` keeps).
  Future<int> _daysToPause() async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final plan = await ref.read(walletRepositoryProvider).getPlan(meId);
    final until = plan?.untilDate;
    if (plan == null || plan.type == PlanType.company || plan.status != PlanStatus.active || until == null) return 0;
    final left = ref.read(nowProvider)().date.daysUntil(until);
    return left > 0 ? left : 0;
  }

  Future<void> _join(String company) async {
    setState(() => _busy = true);
    final days = await _daysToPause();
    if (!mounted) return;
    final agreed = await showConsentSheet(context, company: company, pausedDays: days);
    if (agreed) await CompanyEnrollment.enroll(ref);
    if (!mounted) return;
    setState(() => _busy = false);
    if (agreed) widget.onEnrolled?.call();
  }

  Future<void> _tellHr() =>
      ref.read(tripSharerProvider).share(AppLocalizations.of(context).companyShareText(Env.shareBaseUrl));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary);
    final body = AppTypography.body.copyWith(color: AppColors.textSecondary);
    return switch (widget.offer) {
      NoWorkEmail() => Text(l10n.verifyNotVerified, key: const Key('company-no-email'), style: body),
      NotOnGoora() || PendingCompany() => Column(
          key: const Key('company-not-on-goora'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.companyNotOnGoora, style: title),
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.companyNotOnGooraBody, style: body),
            const SizedBox(height: AppSpacing.md),
            GooraGhostButton(
              key: const Key('company-tell-hr'),
              label: l10n.companyTellHr,
              icon: GooraIcons.share,
              onPressed: _tellHr,
            ),
          ],
        ),
      CanEnroll(:final companyName) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.companyCanEnrollLine(companyName), style: body),
            const SizedBox(height: AppSpacing.md),
            GooraPrimaryButton(
              key: const Key('company-join'),
              label: l10n.companyJoinCta(companyName),
              onPressed: _busy ? null : () => _join(companyName),
            ),
          ],
        ),
      Enrolled(:final companyName, :final since) => Row(
          key: const Key('company-enrolled'),
          children: [
            const Icon(GooraIcons.verified, size: AppSizes.iconSmall, color: AppColors.greenText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.companyEnrolledLine(companyName, l10n.shortDate(since.date)), style: title),
            ),
          ],
        ),
    };
  }
}
