import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_text_field.dart';
import '../data/providers.dart';
import '../domain/phone_number.dart';
import '../domain/repositories.dart';
import 'widgets/onboarding_scaffold.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  PhoneNumber? _phone;
  bool _sending = false;
  bool _networkError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = _phone;
    if (phone == null) return;
    setState(() {
      _sending = true;
      _networkError = false;
    });
    try {
      await ref.read(authRepositoryProvider).sendCode(phone);
      if (!mounted) return;
      context.go(Uri(path: Routes.otp, queryParameters: {Routes.phoneParam: phone.e164}).toString());
    } on AuthNetworkException {
      if (mounted) setState(() => _networkError = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      title: l10n.phoneTitle,
      subtitle: l10n.phoneSub,
      onBack: () => context.go(Routes.welcome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraTextField(
            key: const Key('phone-field'),
            controller: _controller,
            label: l10n.phoneLabel,
            ltr: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+ \-]'))],
            onChanged: (v) => setState(() {
              _phone = PhoneNumber.tryParse(v);
              _networkError = false;
            }),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.phoneHint, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          if (_networkError) ...[
            const SizedBox(height: AppSpacing.gap),
            Text(
              l10n.networkError,
              style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
            ),
          ],
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('phone-continue'),
        label: _networkError ? l10n.retry : l10n.sendCode,
        onPressed: _phone == null || _sending ? null : _send,
      ),
    );
  }
}
