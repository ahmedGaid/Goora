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
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/presentation/today/today_widgets.dart';
import '../../domain/marketplace_repository.dart';
import '../find_riders/find_riders_controller.dart';
import '../find_riders/request_card.dart';

/// Driver Today's "Requests on your route": the demand banner, up to three
/// requests with the same rules as Find riders, and "See all" (US5, FR-020).
class RequestsSection extends ConsumerStatefulWidget {
  const RequestsSection({super.key});

  /// Cards shown on Today before "See all".
  static const preview = 3;

  @override
  ConsumerState<RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends ConsumerState<RequestsSection> {
  bool _busy = false;
  final Map<String, RequestCard> _accepted = {};

  Future<void> _accept(RequestCard card) async {
    setState(() => _busy = true);
    final result = await acceptRequest(ref, card.requestId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result is AcceptCreated || result is AcceptJoined) _accepted[card.requestId] = card;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    // Today leads with the morning: that is where most of the demand is.
    final cards = ref.watch(requestCardsProvider(null, PartOfDay.morning)).value ?? const <RequestCard>[];
    final open = [for (final c in cards) if (!_accepted.containsKey(c.requestId)) c];
    final first = cards.firstOrNull;
    return Column(
      key: const Key('requests-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.reqsOnRoute),
        if (first != null) ...[
          GooraBanner(
            key: const Key('demand-banner'),
            kind: GooraBannerKind.info,
            title: l10n.demandBanner(cards.length, l10n.routeLine(l10n.area(first.from), l10n.area(first.to)), 'morning'),
            body: '',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final c in _accepted.values) ...[
          RequestCardView(card: c, now: now, accepted: true, onAccept: () {}),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final c in open.take(RequestsSection.preview)) ...[
          RequestCardView(card: c, now: now, busy: _busy, onAccept: () => _accept(c)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (open.isEmpty && _accepted.isEmpty) ...[
          Text(
            l10n.noRequests,
            key: const Key('requests-empty'),
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          Caption(l10n.privacyCaption),
        ] else
          GooraGhostButton(
            key: const Key('requests-see-all'),
            label: l10n.seeAll,
            onPressed: () => context.push(Routes.findRiders),
          ),
        Caption(l10n.reqPrivacy),
      ],
    );
  }
}
