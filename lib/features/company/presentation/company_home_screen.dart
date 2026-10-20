import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_status_chip.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../wallet/presentation/labels.dart';
import '../domain/company.dart';
import '../domain/company_repository.dart';
import 'company_controller.dart';
import 'company_offer_view.dart';

/// Settings → Company account (010 research R5). Any signed-in person sees
/// their own company plan; the HR contact of a company also sees it here
/// (pending → "waiting for Goora", then status, minimum, price and
/// contract); anyone else may register one. Roster, invoices, dashboard and
/// log arrive with P5–P7.
class CompanyHomeScreen extends ConsumerWidget {
  const CompanyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(companyAccountProvider);
    final view = account.value;
    final Widget body;
    if (view != null) {
      final mine = _Section(title: l10n.companyMineTitle, child: CompanyOfferView(offer: view.offer));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: view.home == null
            ? [mine, const SizedBox(height: AppSpacing.gap), const _RegisterCard()]
            : [_HrCard(home: view.home!), const SizedBox(height: AppSpacing.gap), mine],
      );
    } else if (account.hasError) {
      body = GooraCard(
        key: const Key('company-error'),
        child: Text(l10n.verifyNotVerified, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
      );
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return OnboardingScaffold(
      key: const Key('company-home'),
      title: l10n.companyAccountTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.today),
      body: body,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => GooraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      );
}

/// No company of my own: what registering is, and the way in.
class _RegisterCard extends StatelessWidget {
  const _RegisterCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(GooraIcons.company, size: AppSizes.icon, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.companyRegisterCta,
                    style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.companyRegisterIntro, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          GooraGhostButton(
            key: const Key('company-register'),
            label: l10n.companyRegisterCta,
            onPressed: () => context.push(Routes.companyRegister),
          ),
        ],
      ),
    );
  }
}

/// The company I am the HR contact of, in each of its states.
class _HrCard extends StatelessWidget {
  const _HrCard({required this.home});

  final CompanyHome home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = home.company;
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final (GooraStatus chip, String label) = switch (home.status) {
      CompanyStatus.pending => (GooraStatus.waiting, l10n.companyStatusPending),
      CompanyStatus.active => (GooraStatus.covered, l10n.companyStatusActive),
      CompanyStatus.suspended => (GooraStatus.off, l10n.companyStatusSuspended),
      CompanyStatus.ended => (GooraStatus.off, l10n.companyStatusEnded),
    };
    Widget line(String text, {Key? key}) => Padding(
          key: key,
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
          child: Text(text, style: secondary),
        );
    return GooraCard(
      key: const Key('company-hr'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(GooraIcons.company, size: AppSizes.icon, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(c.name, style: AppTypography.section.copyWith(color: AppColors.textPrimary))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GooraStatusChip(status: chip, label: label),
          if (home.status == CompanyStatus.pending) line(l10n.companyPendingBody(c.name)),
          line(l10n.companyDomainsLine(c.domains.join(Localizations.localeOf(context).languageCode == 'ar' ? '، ' : ', '))),
          if (home.status != CompanyStatus.pending) ...[
            line(l10n.companyMinSeats(c.minimumSeats)),
            line(l10n.companyPriceLine(c.pricePerSeat)),
            if (c.contractStart != null && c.contractEnd != null)
              line(
                l10n.companyContractLine(l10n.shortDate(c.contractStart!), l10n.shortDate(c.contractEnd!)),
                key: const Key('company-contract'),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(GooraIcons.hidden, size: AppSizes.iconSmall, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.companyHomeNote,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Settings row into the company area.
class CompanyAccountRow extends StatelessWidget {
  const CompanyAccountRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: const Key('settings-company'),
      onTap: () => context.push(Routes.company),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Row(
          children: [
            const Icon(GooraIcons.company, size: AppSizes.icon, color: AppColors.greenText),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.companyAccountTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l10n.companyAccountSub, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(GooraIcons.chevron, size: AppSizes.icon, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
