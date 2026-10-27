import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_status_chip.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../data/providers.dart';
import '../domain/invoice.dart';
import 'company_controller.dart';

/// The HR contact's company invoices, newest first (010 US3, FR-011).
final companyInvoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final account = await ref.watch(companyAccountProvider.future);
  final home = account.home;
  if (home == null) return const [];
  return ref.watch(companyRepositoryProvider).invoices(home.company.id, ref.read(nowProvider)());
});

/// 1980 → "1,980", the same in both languages (digits stay Western, as in
/// every other money line).
String egpGrouped(int amount) => amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Status chip and label for one invoice at [now].
(GooraStatus, String) invoiceChip(AppLocalizations l10n, InvoiceStatus status) => switch (status) {
      InvoiceStatus.paid => (GooraStatus.covered, l10n.companyInvoicePaid),
      InvoiceStatus.issued => (GooraStatus.waiting, l10n.companyInvoiceWaiting),
      InvoiceStatus.overdue => (GooraStatus.off, l10n.companyInvoiceOverdue),
    };

/// Settings → Company account → Invoices.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invoices = ref.watch(companyInvoicesProvider);
    final now = ref.read(nowProvider)();
    final Widget body;
    if (invoices.hasValue) {
      final list = invoices.value!;
      body = list.isEmpty
          ? GooraCard(
              key: const Key('company-invoices-empty'),
              child: Text(l10n.companyInvoicesEmpty, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final inv in list) ...[
                  _InvoiceRow(invoice: inv, status: inv.statusAt(now)),
                  const SizedBox(height: AppSpacing.gap),
                ],
              ],
            );
    } else if (invoices.hasError) {
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
      key: const Key('company-invoices-screen'),
      title: l10n.companyInvoicesTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.company),
      body: body,
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.status});

  final Invoice invoice;
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (chip, label) = invoiceChip(l10n, status);
    return InkWell(
      key: Key('invoice-${invoice.month}'),
      onTap: () => context.push('${Routes.companyInvoice}?id=${Uri.encodeQueryComponent(invoice.id)}'),
      child: GooraCard(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.companyInvoiceMonthLabel(invoice.month),
                        style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(l10n.companyInvoiceMath(invoice.billedSeats, invoice.pricePerSeat, egpGrouped(invoice.total)),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    GooraStatusChip(status: chip, label: label),
                  ],
                ),
              ),
              const Icon(GooraIcons.chevron, size: AppSizes.icon, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
