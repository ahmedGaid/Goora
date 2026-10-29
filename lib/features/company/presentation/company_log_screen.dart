import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../commute/presentation/labels.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../wallet/presentation/labels.dart';
import '../data/providers.dart';
import '../domain/company_log.dart';
import 'company_controller.dart';

/// The HR contact's company log, newest first (010 FR-031).
final companyLogProvider = FutureProvider.autoDispose<List<LogEntry>>((ref) async {
  final home = (await ref.watch(companyAccountProvider.future)).home;
  if (home == null) return const [];
  return ref.watch(companyRepositoryProvider).log(home.company.id);
});

/// What changed, in words. A self-leave says "left" with no reason (spec
/// clarification); Goora staff are "Goora".
String logWhat(AppLocalizations l10n, LogEntry e) {
  final d = e.detail ?? '';
  return switch (e.kind) {
    LogKind.approved => l10n.companyLogApproved,
    LogKind.domainAdded => l10n.companyLogDomainAdded(d),
    LogKind.domainRemoved => l10n.companyLogDomainRemoved(d),
    LogKind.employeeRemoved => l10n.companyLogEmployeeRemoved(d),
    LogKind.employeeLeft => l10n.companyLogEmployeeLeft(d),
    LogKind.invoiceIssued => l10n.companyLogInvoiceIssued(d),
    LogKind.invoicePaid => l10n.companyLogInvoicePaid(d),
    LogKind.suspended => l10n.companyLogSuspended,
    LogKind.resumed => l10n.companyLogResumed,
    LogKind.contractEnded => l10n.companyLogContractEnded,
    LogKind.hrContactChanged => l10n.companyLogHrChanged,
  };
}

String logActor(AppLocalizations l10n, LogActor actor) => switch (actor) {
      LogActor.hr => l10n.companyLogByHr,
      LogActor.employee => l10n.companyLogByEmployee,
      LogActor.goora => l10n.companyLogByGoora,
    };

/// Settings → Company account → Change log.
class CompanyLogScreen extends ConsumerWidget {
  const CompanyLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final log = ref.watch(companyLogProvider);
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final Widget body;
    if (log.hasValue) {
      final entries = log.value!;
      body = entries.isEmpty
          ? GooraCard(key: const Key('company-log-empty'), child: Text(l10n.companyLogEmpty, style: secondary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, e) in entries.indexed) ...[
                  GooraCard(
                    key: Key('log-$i'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(logWhat(l10n, e), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.companyLogMeta(
                            logActor(l10n, e.actor),
                            '${l10n.shortDateYear(e.at.date)} ${l10n.time(e.at.time)}',
                          ),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap),
                ],
              ],
            );
    } else if (log.hasError) {
      body = GooraCard(key: const Key('company-error'), child: Text(l10n.verifyNotVerified, style: secondary));
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return OnboardingScaffold(
      key: const Key('company-log-screen'),
      title: l10n.companyLogTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.company),
      body: body,
    );
  }
}
