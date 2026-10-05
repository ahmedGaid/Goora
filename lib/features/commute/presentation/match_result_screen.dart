import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_avatar.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../data/providers.dart';
import '../domain/group.dart';
import '../domain/matching_service.dart';
import 'commute_controller.dart';
import 'labels.dart';

class MatchResultScreen extends ConsumerStatefulWidget {
  const MatchResultScreen({super.key});

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends ConsumerState<MatchResultScreen> {
  bool _showOthers = false;
  bool _joining = false;

  Future<void> _join(MatchOutcome outcome) async {
    setState(() => _joining = true);
    await ref.read(commuteRepositoryProvider).join(outcome.result.main!.group.id);
    if (mounted) context.go(outcome.viewerIsDriver ? Routes.today : Routes.plan);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outcome = ref.watch(lastMatchProvider);
    final main = outcome?.result.main;
    if (outcome == null || main == null) {
      // Opened without a fresh match (e.g. after a restart): go back to setup.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.commuteSetup);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final g = main.group;
    final viewerIsDriver = outcome.viewerIsDriver;
    final me = ref.watch(sessionControllerProvider).profile;
    final myInitials = me == null ? '' : '${me.firstName.characters.first}${me.lastName.characters.first}';
    final sharedDays = outcome.profile.days.intersection(g.days).length;
    final from = l10n.area(outcome.profile.home!.area);
    final to = l10n.area(g.destination);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);

    return OnboardingScaffold(
      header: GooraChip(key: const Key('match-chip'), label: l10n.matchPercent(main.score)),
      title: l10n.foundGroup,
      subtitle: l10n.foundSub,
      onBack: () => context.go(Routes.commuteSetup),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
            child: Column(
              children: [
                GooraAvatarStack(
                  avatars: [
                    for (final (i, m) in g.members.indexed)
                      viewerIsDriver && m.role == MemberRole.rider
                          ? GooraAvatar.anonymous(
                              size: GooraAvatarSize.s48,
                              ring: true,
                              semanticLabel: m.isWoman ? l10n.verifiedRiderWoman : l10n.verifiedRider,
                            )
                          : GooraAvatar(initials: m.initials, size: GooraAvatarSize.s48, ring: true, paletteIndex: i),
                    GooraAvatar(initials: myInitials, size: GooraAvatarSize.s48, ring: true, highlight: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.membersCount(g.members.length + 1),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.routeLine(from, to), style: secondary, textAlign: TextAlign.center),
                Text(l10n.timeDays(l10n.time(g.going), l10n.daysSummary(g.days)), style: secondary),
                const SizedBox(height: AppSpacing.gap),
                Row(
                  children: [
                    _Stat(value: '${g.drivers.length + (viewerIsDriver ? 1 : 0)}', label: l10n.statDrivers),
                    _Stat(value: '${g.riders.length + (viewerIsDriver ? 0 : 1)}', label: l10n.statRiders),
                    _Stat(value: l10n.perWeek(sharedDays), label: l10n.statFixed),
                    _Stat(value: '${g.price}', label: l10n.egpTrip),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  key: const Key('fee-line'),
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    l10n.feeLine(g.price),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
                  ),
                ),
              ],
            ),
          ),
          if (outcome.result.returnMatch != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.returnLeg(l10n.time(outcome.result.returnMatch!.group.ret)),
              key: const Key('return-leg'),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
            ),
          ],
          const SizedBox(height: AppSpacing.gap),
          GooraCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.whyGroup, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                for (final r in main.reasons)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(GooraIcons.check, size: AppSizes.iconSmall, color: AppColors.greenText),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(l10n.reason(r), style: AppTypography.bodySmall.copyWith(color: AppColors.textBody)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (outcome.result.alternatives.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('toggle-others'),
                onPressed: () => setState(() => _showOthers = !_showOthers),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.greenText,
                  minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
                ),
                icon: Icon(_showOthers ? GooraIcons.minus : GooraIcons.plus, size: AppSizes.iconSmall),
                label: Text(
                  _showOthers ? l10n.hideOthers : l10n.seeOthers,
                  style: AppTypography.bodyStrong,
                ),
              ),
            ),
            if (_showOthers) _Others(matches: outcome.result.alternatives),
          ],
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('join-group'),
        label: l10n.join,
        onPressed: _joining ? null : () => _join(outcome),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.stat.copyWith(color: AppColors.textPrimary), maxLines: 1),
          Text(label, style: AppTypography.micro.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Others extends StatelessWidget {
  const _Others({required this.matches});

  final List<GroupMatch> matches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard.rows(
      key: const Key('other-matches'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
      rows: [
        Text(l10n.otherMatches, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
        for (final (i, m) in matches.indexed)
          Row(
            children: [
              GooraAvatar(initials: m.group.drivers.first.initials, paletteIndex: i + 1),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.group.drivers.first.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    Text(
                      l10n.otherMeta(l10n.time(m.group.going), (m.pickupMeters / 50).round() * 50),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GooraChip(label: l10n.matchPercent(m.score)),
            ],
          ),
      ],
    );
  }
}
