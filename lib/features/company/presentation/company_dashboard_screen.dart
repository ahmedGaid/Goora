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
import '../../commute/presentation/labels.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../data/providers.dart';
import '../domain/hr_views.dart';
import 'company_controller.dart';

typedef DashboardMonths = ({String companyId, List<({String month, bool soFar})> months});

/// The months HR can pick (FR-021). Null = not the HR contact of any company.
final companyDashboardMonthsProvider = FutureProvider.autoDispose<DashboardMonths?>((ref) async {
  final home = (await ref.watch(companyAccountProvider.future)).home;
  if (home == null) return null;
  final months = await ref.watch(companyRepositoryProvider).dashboardMonths(home.company.id, ref.read(nowProvider)());
  return (companyId: home.company.id, months: months);
});

/// One month of totals; suppression has already happened inside the
/// aggregator (FR-022), so nothing here can show a hidden number.
final companyDashboardProvider =
    FutureProvider.autoDispose.family<DashboardMonth, ({String companyId, String month})>((ref, key) {
  return ref.watch(companyRepositoryProvider).dashboard(key.companyId, key.month, ref.read(nowProvider)());
});

/// Settings → Company account → Company numbers: totals for one month, in
/// words, each estimate with its method; "Fewer than 5" instead of a number
/// that could point at a person (010 US5, FR-021–FR-023).
class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends ConsumerState<CompanyDashboardScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final months = ref.watch(companyDashboardMonthsProvider);
    final secondary = AppTypography.body.copyWith(color: AppColors.textSecondary);
    final Widget body;
    if (months.hasValue) {
      final value = months.value;
      if (value == null || value.months.isEmpty) {
        body = GooraCard(key: const Key('company-dashboard-empty'), child: Text(l10n.companyDashboardEmpty, style: secondary));
      } else {
        final selected = value.months.any((m) => m.month == _picked) ? _picked! : value.months.first.month;
        body = _Body(
          companyId: value.companyId,
          months: value.months,
          selected: selected,
          onPick: (m) => setState(() => _picked = m),
        );
      }
    } else if (months.hasError) {
      body = GooraCard(key: const Key('company-error'), child: Text(l10n.verifyNotVerified, style: secondary));
    } else {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return OnboardingScaffold(
      key: const Key('company-dashboard-screen'),
      title: l10n.companyDashboardTitle,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.company),
      body: body,
    );
  }
}

String _monthLabel(String month) {
  final p = month.split('-');
  return '${int.parse(p[1])}/${p[0]}';
}

class _Body extends ConsumerWidget {
  const _Body({required this.companyId, required this.months, required this.selected, required this.onPick});

  final String companyId;
  final List<({String month, bool soFar})> months;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(companyDashboardProvider((companyId: companyId, month: selected)));
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
                key: Key('dashboard-month-${m.month}'),
                label: m.soFar ? l10n.companyDashboardSoFar(_monthLabel(m.month)) : _monthLabel(m.month),
                selected: m.month == selected,
                onTap: () => onPick(m.month),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(GooraIcons.hidden, size: AppSizes.iconSmall, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.companyDashboardNote, style: small)),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        if (data.hasValue)
          ..._figures(l10n, data.value!)
        else if (data.hasError)
          GooraCard(key: const Key('company-error'), child: Text(l10n.verifyNotVerified, style: secondary))
        else
          const Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  List<Widget> _figures(AppLocalizations l10n, DashboardMonth m) {
    String? n(int? v, String Function(int) fmt) => v == null ? null : fmt(v);
    final figures = <(String, String, String?, String?)>[
      ('enrolled', l10n.companyDashboardEnrolled, n(m.enrolled, groupedInt), null),
      ('active', l10n.companyDashboardActive, n(m.active, groupedInt), l10n.companyDashboardActiveMethod),
      (
        'carpool',
        l10n.companyDashboardCarpool,
        n(m.carpoolRatePct, (v) => l10n.companyDashboardPercent(v)),
        l10n.companyDashboardCarpoolMethod,
      ),
      ('groups', l10n.companyDashboardGroups, n(m.groups, groupedInt), null),
      ('trips', l10n.companyDashboardTrips, n(m.tripsShared, groupedInt), l10n.companyDashboardTripsMethod),
      (
        'saved',
        l10n.companyDashboardSaved,
        n(m.moneySaved, (v) => l10n.companyDashboardMoney(groupedInt(v))),
        l10n.companyDashboardSavedMethod,
      ),
      ('co2', l10n.companyDashboardCo2, n(m.co2Kg, (v) => l10n.companyDashboardKg(groupedInt(v))), l10n.companyDashboardCo2Method),
      (
        'parking',
        l10n.companyDashboardParking,
        n(m.parkingPerDay, groupedInt),
        l10n.companyDashboardParkingMethod,
      ),
    ];
    final small = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    final anyHidden = figures.any((f) => f.$3 == null);
    return [
      for (final (id, label, value, method) in figures) ...[
        GooraCard(
          key: Key('dash-$id'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value ?? l10n.companyDashboardFewer,
                key: Key('dash-$id-value'),
                style: value == null
                    ? AppTypography.section.copyWith(color: AppColors.textSecondary)
                    : AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              if (method != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(method, style: small),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
      ],
      GooraCard(
        key: const Key('dash-gaps'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.companyDashboardGapsTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            if (m.routeGaps.isEmpty)
              Text(l10n.companyDashboardGapsEmpty, key: const Key('dash-gaps-empty'), style: small)
            else
              for (final (area, count) in m.routeGaps)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
                  child: Text(
                    l10n.companyDashboardGapRow(l10n.area(area), count),
                    key: Key('dash-gap-${area.name}'),
                    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  ),
                ),
          ],
        ),
      ),
      if (anyHidden) ...[
        const SizedBox(height: AppSpacing.gap),
        Text(l10n.companyDashboardFewerNote, key: const Key('dash-fewer-note'), style: small),
      ],
    ];
  }
}
