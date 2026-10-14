import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_dashed_button.dart';
import '../../../../core/widgets/goora_logo.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../marketplace/presentation/today/one_off_section.dart';
import '../../../onboarding/domain/choices.dart';
import '../../../onboarding/presentation/session_controller.dart';
import '../labels.dart';
import '../shell/tab_page.dart';
import 'driver_today.dart';
import 'rider_today.dart';
import 'today_controller.dart';
import 'today_widgets.dart';

/// Today tab: rider or driver layout (FR-001, FR-003, FR-013).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _noon = 12;
  static const _logo = GooraLogo(
    key: Key('today-logo'),
    variant: GooraLogoVariant.symbol,
    tone: GooraLogoTone.primary,
    size: AppSizes.logoHeader,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(sessionControllerProvider).profile?.firstName ?? '';
    final state = ref.watch(todayControllerProvider);
    final view = state.value;
    final greeting = view != null && view.now.time.hour >= _noon ? l10n.goodEvening(name) : l10n.goodMorning(name);

    if (view == null) {
      return TabPage(
        leading: _logo,
        title: greeting,
        actions: const [TodayHeaderActions()],
        children: [TabLoadState(failed: state.hasError, onRetry: () => ref.invalidate(todayControllerProvider))],
      );
    }

    if (view.noGroupYet) {
      final driver = ref.watch(sessionControllerProvider).profile?.role == Role.driver;
      return TabPage(
        leading: _logo,
        title: greeting,
        subtitle: l10n.noGroupYet,
        actions: const [TodayHeaderActions()],
        children: [
          const OneOffSection(),
          if (driver) const DriverOffersSection(),
          GooraCard(
            key: const Key('no-group-yet'),
            child: Text(driver ? l10n.fOnceDriver : l10n.fOnceRider, style: AppTypography.body.copyWith(color: AppColors.textBody)),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraPrimaryButton(
            key: const Key('no-group-action'),
            label: driver ? l10n.offerTitle : l10n.extraTrip,
            onPressed: () => context.push(driver ? Routes.offerTrip : Routes.emptySeatsOn(Leg.going)),
          ),
          if (!driver) ...[
            const SizedBox(height: AppSpacing.md),
            GooraDashedButton(
              key: const Key('no-group-post'),
              label: l10n.postReq,
              onPressed: () => context.push(Routes.postTrip),
            ),
          ],
        ],
      );
    }

    if (view.removed) {
      return TabPage(
        leading: _logo,
        title: greeting,
        actions: const [TodayHeaderActions()],
        children: [
          GooraBanner(kind: GooraBannerKind.warning, title: l10n.removedTitle, body: l10n.removedNotice),
          const SizedBox(height: AppSpacing.gap),
          GooraPrimaryButton(
            key: const Key('find-new-group'),
            label: l10n.findNewGroup,
            onPressed: () => context.go(Routes.commuteSetup),
          ),
        ],
      );
    }

    final drive = view.drive;
    return TabPage(
      leading: _logo,
      title: greeting,
      subtitle: view.isDriver
          ? (drive == null ? l10n.notDrivingSoon : l10n.drivingWhen(l10n.when(drive.date, view.now.date)))
          : l10n.todaySub,
      actions: const [TodayHeaderActions()],
      children: [view.isDriver ? DriverToday(view: view) : RiderToday(view: view)],
    );
  }
}
