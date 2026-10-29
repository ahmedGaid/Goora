import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_status_chip.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../wallet/presentation/labels.dart';
import '../domain/company_terms.dart';
import '../domain/invoice.dart';
import 'invoices_screen.dart';

/// One invoice with what the company needs to pay it: the reference to write
/// on the transfer, Goora's bank details and the due date (010 US3, FR-011).
/// Paying happens outside the app; Goora staff mark it paid (FR-012).
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invoices = ref.watch(companyInvoicesProvider);
    final invoice = invoices.value?.where((i) => i.id == invoiceId).firstOrNull;
    final Widget body;
    if (invoice != null) {
      body = _Body(invoice: invoice, now: ref.read(nowProvider)());
    } else if (invoices.hasValue || invoices.hasError) {
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
      key: const Key('company-invoice-screen'),
      title: invoice == null ? l10n.companyInvoicesTitle : l10n.companyInvoiceMonthLabel(invoice.month),
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.companyInvoices),
      body: body,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.invoice, required this.now});

  final Invoice invoice;
  final WallTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = invoice.statusAt(now);
    final (chip, label) = invoiceChip(l10n, status);
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GooraStatusChip(status: chip, label: label),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.companyInvoiceMath(invoice.billedSeats, invoice.pricePerSeat, egpGrouped(invoice.total)),
                style: AppTypography.section.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.companyInvoicePeak(invoice.peakEnrolled), style: secondary),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.companyInvoiceDue(l10n.shortDateYear(invoice.dueOn)), key: const Key('invoice-due'), style: secondary),
              if (status == InvoiceStatus.paid && invoice.paidAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.companyInvoicePaidOn(l10n.shortDateYear(invoice.paidAt!.date), invoice.bankRef ?? ''),
                  key: const Key('invoice-paid-on'),
                  style: secondary,
                ),
              ],
              if (status != InvoiceStatus.paid) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.companyInvoiceSuspendNote(l10n.shortDateYear(invoice.suspendFrom.date)),
                  key: const Key('invoice-suspend-note'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.companyInvoiceReferenceTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                invoice.reference,
                key: const Key('invoice-reference'),
                style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.companyInvoiceBankTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(CompanyTerms.bankDetails, style: secondary),
            ],
          ),
        ),
      ],
    );
  }
}
