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
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../wallet/presentation/labels.dart';
import '../data/providers.dart';
import '../domain/hr_views.dart';
import 'company_controller.dart';
import 'company_log_screen.dart';

/// The HR contact's roster (010 US4, FR-016): enrolled now, then this
/// month's leavers. Null = not the HR contact of any company.
final companyRosterProvider = FutureProvider.autoDispose<({String companyId, List<RosterRow> rows})?>((ref) async {
  final home = (await ref.watch(companyAccountProvider.future)).home;
  if (home == null) return null;
  final rows = await ref.watch(companyRepositoryProvider).roster(home.company.id, ref.read(nowProvider)());
  return (companyId: home.company.id, rows: rows);
});

/// Settings → Company account → Enrolled employees. Name, work email and
/// since — the three things the employee agreed the company sees — and a
/// confirmed Remove.
class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, String companyId, RosterRow row) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyRosterRemoveTitle(row.name)),
        content: Text(l10n.companyRosterRemoveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepIt)),
          TextButton(
            key: const Key('roster-remove-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.companyRosterRemoveConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(companyRepositoryProvider).removeEmployee(companyId, row.workEmail, ref.read(nowProvider)());
    // The HR contact may have removed themselves: their own side catches up.
    ref.invalidate(companyAccountProvider);
    ref.invalidate(companyLogProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(companyRosterProvider);
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final Widget body;
    if (roster.hasValue) {
      final value = roster.value;
      final rows = value?.rows ?? const <RosterRow>[];
      final enrolled = rows.where((r) => r.leftAt == null).length;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.companyRosterCount(enrolled), style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(GooraIcons.hidden, size: AppSizes.iconSmall, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.companyRosterNote,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          if (rows.isEmpty)
            GooraCard(key: const Key('company-roster-empty'), child: Text(l10n.companyRosterEmpty, style: secondary))
          else
            for (final row in rows) ...[
              _RosterRowCard(
                row: row,
                onRemove: row.leftAt == null ? () => _remove(context, ref, value!.companyId, row) : null,
              ),
              const SizedBox(height: AppSpacing.gap),
            ],
        ],
      );
    } else if (roster.hasError) {
      body = GooraCard(key: const Key('company-error'), child: Text(l10n.verifyNotVerified, style: secondary));
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return OnboardingScaffold(
      key: const Key('company-roster-screen'),
      title: l10n.companyRosterTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.company),
      body: body,
    );
  }
}

class _RosterRowCard extends StatelessWidget {
  const _RosterRowCard({required this.row, required this.onRemove});

  final RosterRow row;

  /// null for a leaver.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return GooraCard(
      key: Key('roster-${row.workEmail}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(row.workEmail, style: small, textDirection: TextDirection.ltr),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.companyRosterSince(l10n.shortDateYear(row.enrolledAt.date)), style: small),
                if (row.leftAt != null)
                  Padding(
                    key: Key('roster-left-${row.workEmail}'),
                    padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
                    child: Text(l10n.companyRosterLeft(l10n.shortDateYear(row.leftAt!.date)),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch, minWidth: AppSizes.minTouch),
              child: TextButton(
                key: Key('roster-remove-${row.workEmail}'),
                onPressed: onRemove,
                child: Text(l10n.companyRosterRemove,
                    style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
              ),
            ),
        ],
      ),
    );
  }
}
