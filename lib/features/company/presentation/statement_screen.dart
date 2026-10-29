import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format/grouped_number.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../daily/presentation/labels.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../wallet/presentation/labels.dart';
import '../data/providers.dart';
import '../domain/hr_views.dart';
import 'company_controller.dart';

typedef StatementMonths = ({String companyId, List<String> months});

/// The months that have a statement: the closed ones, newest first. The
/// running month has none yet (consent can still change). Null = not the HR
/// contact of any company.
final companyStatementMonthsProvider = FutureProvider.autoDispose<StatementMonths?>((ref) async {
  final home = (await ref.watch(companyAccountProvider.future)).home;
  if (home == null) return null;
  final all = await ref.watch(companyRepositoryProvider).dashboardMonths(home.company.id, ref.read(nowProvider)());
  return (
    companyId: home.company.id,
    months: [
      for (final m in all)
        if (!m.soFar) m.month,
    ],
  );
});

final companyStatementProvider = FutureProvider.autoDispose
    .family<List<StatementLine>, ({String companyId, String month})>((ref, key) {
      return ref.watch(companyRepositoryProvider).statement(key.companyId, key.month, ref.read(nowProvider)());
    });

String _monthLabel(String month) {
  final p = month.split('-');
  return '${int.parse(p[1])}/${p[0]}';
}

/// Settings → Company account → Trips statement: for each closed month, the
/// employees who agreed to share — name, then date, leg and the share each
/// trip cost them, paid to the driver. Nobody else appears, not even a name
/// (010 US6, FR-025–FR-028). Goora's fee shows as 0; no export while
/// `hrStatementExport` is off.
class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final months = ref.watch(companyStatementMonthsProvider);
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final Widget body;
    if (months.hasValue) {
      final value = months.value;
      if (value == null || value.months.isEmpty) {
        body = GooraCard(
          key: const Key('statement-no-months'),
          child: Text(l10n.companyStatementNoMonths, style: secondary),
        );
      } else {
        final selected = value.months.contains(_picked) ? _picked! : value.months.first;
        body = _Body(
          companyId: value.companyId,
          months: value.months,
          selected: selected,
          onPick: (m) => setState(() => _picked = m),
        );
      }
    } else if (months.hasError) {
      body = GooraCard(
        key: const Key('company-error'),
        child: Text(l10n.verifyNotVerified, style: secondary),
      );
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return OnboardingScaffold(
      key: const Key('company-statement-screen'),
      title: l10n.companyStatementTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.company),
      body: body,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.companyId, required this.months, required this.selected, required this.onPick});

  final String companyId;
  final List<String> months;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(companyStatementProvider((companyId: companyId, month: selected)));
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final small = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final m in months)
              GooraPill(
                key: Key('statement-month-$m'),
                label: _monthLabel(m),
                selected: m == selected,
                onTap: () => onPick(m),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(GooraIcons.hidden, size: AppSizes.iconSmall, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.companyStatementNote, key: const Key('statement-note'), style: small),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.companyStatementFee(l10n.egpAmount(0)), key: const Key('statement-fee'), style: small),
        const SizedBox(height: AppSpacing.gap),
        if (data.hasValue)
          ..._people(l10n, data.value!, secondary)
        else if (data.hasError)
          GooraCard(
            key: const Key('company-error'),
            child: Text(l10n.verifyNotVerified, style: secondary),
          )
        else
          const Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  List<Widget> _people(AppLocalizations l10n, List<StatementLine> lines, TextStyle secondary) {
    if (lines.isEmpty) {
      return [
        GooraCard(
          key: const Key('statement-empty'),
          child: Text(l10n.companyStatementEmpty, style: secondary),
        ),
      ];
    }
    // The repository sorts by name, so one person's lines are together.
    final byName = <String, List<StatementLine>>{};
    for (final line in lines) {
      (byName[line.name] ??= []).add(line);
    }
    final total = lines.fold<int>(0, (sum, l) => sum + l.sharePaid);
    return [
      for (final MapEntry(key: name, value: own) in byName.entries) ...[
        _PersonCard(name: name, lines: own),
        const SizedBox(height: AppSpacing.gap),
      ],
      Text(
        l10n.companyStatementTotal(groupedInt(total)),
        key: const Key('statement-total'),
        style: AppTypography.section.copyWith(color: AppColors.textPrimary),
      ),
    ];
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.name, required this.lines});

  final String name;
  final List<StatementLine> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    final sum = lines.fold<int>(0, (s, l) => s + l.sharePaid);
    return GooraCard(
      key: Key('statement-$name'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.companyStatementPerson(lines.length, groupedInt(sum)), style: small),
          const SizedBox(height: AppSpacing.xs),
          for (final (i, line) in lines.indexed)
            Padding(
              key: Key('statement-line-$name-$i'),
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.shortDateYear(line.date)} · ${l10n.legName(line.leg)}',
                      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.companyStatementShare(groupedInt(line.sharePaid)), style: small),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
