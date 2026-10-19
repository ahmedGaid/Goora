import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_radio_card.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../data/providers.dart';
import 'trust_controller.dart';

/// 009: a rider's ID check, opened by their first Book, Post or Join — never
/// during onboarding (FR-001). Front and back, then Submit (FR-003). On
/// success the rider goes back to [next] to tap the action again; nothing is
/// booked behind their back (FR-004). The fakes capture without a camera.
class IdCheckScreen extends ConsumerStatefulWidget {
  const IdCheckScreen({super.key, this.next});

  /// Where the rider was; Today when null.
  final String? next;

  @override
  ConsumerState<IdCheckScreen> createState() => _IdCheckScreenState();
}

class _IdCheckScreenState extends ConsumerState<IdCheckScreen> {
  bool _front = false;
  bool _back = false;
  bool _busy = false;
  bool _pending = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final status = await ref.read(trustRepositoryProvider).submitRiderId();
    if (!mounted) return;
    ref.invalidate(trustControllerProvider);
    if (status.ok) {
      context.go(widget.next ?? Routes.today);
    } else {
      setState(() {
        _busy = false;
        _pending = true;
      });
    }
  }

  void _goBack() => context.canPop() ? context.pop() : context.go(widget.next ?? Routes.today);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      title: l10n.idCheckTitle,
      subtitle: l10n.idCheckSub,
      onBack: _goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraRadioCard(
            key: const Key('id-front'),
            title: l10n.idFront,
            subtitle: _front ? l10n.idCaptured : null,
            icon: _front ? GooraIcons.check : GooraIcons.camera,
            selected: _front,
            onTap: () => setState(() => _front = true),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('id-back'),
            title: l10n.idBack,
            subtitle: _back ? l10n.idCaptured : null,
            icon: _back ? GooraIcons.check : GooraIcons.camera,
            selected: _back,
            onTap: () => setState(() => _back = true),
          ),
          if (_pending) ...[
            const SizedBox(height: AppSpacing.gap),
            Text(l10n.idPending,
                key: const Key('id-pending'), style: AppTypography.body.copyWith(color: AppColors.textBody)),
          ],
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('id-submit'),
        label: l10n.idSubmit,
        onPressed: _front && _back && !_busy && !_pending ? _submit : null,
      ),
    );
  }
}
