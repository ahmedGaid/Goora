import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../data/providers.dart';
import '../../domain/notice.dart';
import '../labels.dart';
import '../today/today_controller.dart';

/// In-app inbox (research R11). Opening it marks everything read.
Future<void> showInboxSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const InboxSheet(),
    );

class InboxSheet extends ConsumerStatefulWidget {
  const InboxSheet({super.key});

  @override
  ConsumerState<InboxSheet> createState() => _InboxSheetState();
}

class _InboxSheetState extends ConsumerState<InboxSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final repo = ref.read(dailyCommuteRepositoryProvider);
      final unread = ref.read(noticesProvider).value?.where((n) => !n.read) ?? const <Notice>[];
      for (final n in unread.toList()) {
        await repo.markRead(n.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notices = ref.watch(noticesProvider).value ?? const <Notice>[];
    final group = ref.watch(todayControllerProvider).value?.group;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.inboxTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.gap),
              if (notices.isEmpty)
                Padding(
                  key: const Key('inbox-empty'),
                  padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xxl),
                  child: Column(
                    children: [
                      const Icon(GooraIcons.bell, size: AppSizes.iconTileLarge, color: AppColors.disabled),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.inboxEmpty, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.inboxEmptyBody,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notices.length,
                    separatorBuilder: (_, _) => const Divider(height: AppSizes.hairline, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final n = notices[i];
                      return Padding(
                        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!n.toMe)
                              Text(l10n.sentToRiders, style: AppTypography.microBold.copyWith(color: AppColors.greenText)),
                            Text(
                              l10n.noticeText(n, group),
                              style: (n.read ? AppTypography.bodySmall : AppTypography.bodyStrong)
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
