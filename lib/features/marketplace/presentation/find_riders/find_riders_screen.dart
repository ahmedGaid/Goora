import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/place.dart';
import '../../../commute/presentation/labels.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../domain/marketplace_repository.dart';
import 'find_riders_controller.dart';
import 'request_card.dart';

/// Find riders (D): anonymous requests on the driver's route, each acceptable
/// within the two-trip day (FR-018 – FR-021). Names show from departure only.
class FindRidersScreen extends ConsumerStatefulWidget {
  const FindRidersScreen({super.key});

  @override
  ConsumerState<FindRidersScreen> createState() => _FindRidersScreenState();
}

class _FindRidersScreenState extends ConsumerState<FindRidersScreen> {
  Area? _from;
  PartOfDay _part = PartOfDay.morning;
  bool _busy = false;
  bool _gone = false;

  /// Cards accepted here stay on screen as "Accepted ✓" until the screen closes.
  final Map<String, RequestCard> _accepted = {};

  void _back() => context.canPop() ? context.pop() : context.go(Routes.today);

  Future<void> _accept(RequestCard card) async {
    setState(() {
      _busy = true;
      _gone = false;
    });
    final result = await acceptRequest(ref, card.requestId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case AcceptCreated() || AcceptJoined():
          _accepted[card.requestId] = card;
        case AcceptRefused():
          break;
        case RiderCantPay():
          _gone = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    final cards = ref.watch(requestCardsProvider(_from, _part));
    final left = ref.watch(tripsLeftProvider(cards.value?.firstOrNull?.date ?? now.date)).value;
    return OnboardingScaffold(
      title: l10n.browseTitle,
      onBack: _back,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.leavingFrom, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              GooraPill(key: const Key('area-all'), label: l10n.allAreas, selected: _from == null, onTap: () => setState(() => _from = null)),
              for (final a in Area.values)
                GooraPill(
                  key: Key('area-${a.name}'),
                  label: l10n.area(a),
                  selected: _from == a,
                  onTap: () => setState(() => _from = a),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              GooraPill(
                key: const Key('part-morning'),
                label: l10n.morning,
                selected: _part == PartOfDay.morning,
                onTap: () => setState(() => _part = PartOfDay.morning),
              ),
              const SizedBox(width: AppSpacing.sm),
              GooraPill(
                key: const Key('part-evening'),
                label: l10n.evening,
                selected: _part == PartOfDay.evening,
                onTap: () => setState(() => _part = PartOfDay.evening),
              ),
              const Spacer(),
              if (left != null)
                Text(
                  '${l10n.tripsLeftA} · $left',
                  key: const Key('trips-left'),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_gone) ...[
            GooraBanner(key: const Key('notice-gone'), kind: GooraBannerKind.info, title: l10n.requestGone, body: ''),
            const SizedBox(height: AppSpacing.md),
          ],
          for (final c in _accepted.values) ...[
            RequestCardView(card: c, now: now, accepted: true, onAccept: () {}),
            const SizedBox(height: AppSpacing.md),
          ],
          cards.when(
            loading: () => const Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(key: Key('requests-loading'))),
            ),
            error: (_, _) => Column(
              key: const Key('requests-error'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.todayError, style: AppTypography.body.copyWith(color: AppColors.textBody)),
                const SizedBox(height: AppSpacing.md),
                GooraPrimaryButton(
                  key: const Key('requests-retry'),
                  label: l10n.retry,
                  onPressed: () => ref.invalidate(requestCardsProvider),
                ),
              ],
            ),
            data: (list) {
              final open = [for (final c in list) if (!_accepted.containsKey(c.requestId)) c];
              if (open.isEmpty && _accepted.isEmpty) {
                return Column(
                  key: const Key('requests-empty'),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        l10n.noRequests,
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    Text(l10n.privacyCaption, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in open) ...[
                    RequestCardView(card: c, now: now, busy: _busy, onAccept: () => _accept(c)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(l10n.privacyCaption, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
