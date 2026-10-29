import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_text_field.dart';
import '../../daily/data/providers.dart';
import '../../onboarding/data/fake_otp_provider.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../data/providers.dart';
import '../domain/company.dart';
import '../domain/company_repository.dart';
import 'company_controller.dart';

/// Register a company (010 US1): name + the HR contact's work email, whose
/// domain becomes the company's; a code to that email proves it (fake:
/// the same test code as the phone OTP — real email delivery is server
/// work, research R9). Public mail domains and domains another company
/// holds are refused before any code is sent. Sent = pending, I am its HR
/// contact; Goora staff approve it once the paper contract is signed.
class RegisterCompanyScreen extends ConsumerStatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  ConsumerState<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

/// Why the form can't go on.
sealed class _Refusal {
  const _Refusal();
}

final class _PublicDomain extends _Refusal {
  const _PublicDomain(this.domain);
  final String domain;
}

final class _DomainTaken extends _Refusal {
  const _DomainTaken(this.domain);
  final String domain;
}

class _RegisterCompanyScreenState extends ConsumerState<RegisterCompanyScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _nameError = false;
  bool _emailError = false;
  bool _codeWrong = false;
  bool _busy = false;
  _Refusal? _refusal;

  /// The address the code went to; null = still on the form.
  String? _sentTo;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final domain = CompanyDomains.of(_email.text.trim());
    setState(() {
      _nameError = !Company.nameOk(_name.text);
      _emailError = domain == null || !domain.contains('.');
      _refusal = null;
    });
    if (_nameError || _emailError) return;
    if (CompanyDomains.isPublic(domain!)) return setState(() => _refusal = _PublicDomain(domain));
    setState(() => _busy = true);
    final taken = await ref.read(companyRepositoryProvider).companyForDomain(domain);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (taken != null) {
        _refusal = _DomainTaken(domain);
      } else {
        _sentTo = _email.text.trim().toLowerCase();
      }
    });
  }

  Future<void> _submit() async {
    if (_code.text.trim() != FakeOtpProvider.testCode) return setState(() => _codeWrong = true);
    setState(() {
      _codeWrong = false;
      _busy = true;
    });
    final email = _sentTo!;
    final result = await ref.read(companyRepositoryProvider).register(
          personId: ref.read(dailyCommuteRepositoryProvider).meId,
          name: _name.text.trim(),
          domains: [CompanyDomains.of(email)!],
          hrWorkEmail: email,
          now: ref.read(nowProvider)(),
        );
    if (!mounted) return;
    switch (result) {
      case Registered():
        ref.invalidate(companyAccountProvider);
        context.canPop() ? context.pop() : context.go(Routes.company);
      // Someone took the domain between the check and the send: back to the form.
      case PublicDomain(:final domain):
        _backToForm(_PublicDomain(domain));
      case DomainTaken(:final domain):
        _backToForm(_DomainTaken(domain));
      case EmailNotOnDomain():
        _backToForm(null, emailError: true);
    }
  }

  void _backToForm(_Refusal? refusal, {bool emailError = false}) {
    setState(() {
      _busy = false;
      _sentTo = null;
      _refusal = refusal;
      _emailError = emailError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sent = _sentTo != null;
    final refusal = _refusal;
    return OnboardingScaffold(
      key: const Key('company-register-screen'),
      title: l10n.companyRegisterCta,
      subtitle: l10n.companyRegisterSub,
      onBack: () => sent ? setState(() => _sentTo = null) : context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!sent) ...[
            GooraTextField(
              key: const Key('company-name'),
              controller: _name,
              label: l10n.companyNameLabel,
              maxLength: 60,
              errorText: _nameError ? l10n.companyNameError : null,
            ),
            const SizedBox(height: AppSpacing.md),
            GooraTextField(
              key: const Key('company-email'),
              controller: _email,
              label: l10n.companyWorkEmailLabel,
              ltr: true,
              keyboardType: TextInputType.emailAddress,
              // A refused domain is the email's fault: said right under it.
              errorText: switch (refusal) {
                _PublicDomain(:final domain) => l10n.companyPublicDomain(domain),
                _DomainTaken(:final domain) => l10n.companyDomainTaken(domain),
                null => _emailError ? l10n.companyEmailInvalid : null,
              },
            ),
          ] else ...[
            Text(l10n.companyCodeSent(_sentTo!), style: AppTypography.body.copyWith(color: AppColors.textBody)),
            const SizedBox(height: AppSpacing.md),
            GooraTextField(
              key: const Key('company-code'),
              controller: _code,
              label: l10n.companyCodeLabel,
              ltr: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: FakeOtpProvider.testCode.length,
              errorText: _codeWrong ? l10n.otpWrong : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.otpDevHint, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
      bottom: sent
          ? GooraPrimaryButton(
              key: const Key('company-submit'),
              label: l10n.companySubmit,
              onPressed: _busy ? null : _submit,
            )
          : GooraPrimaryButton(
              key: const Key('company-send-code'),
              label: l10n.companySendCode,
              onPressed: _busy ? null : _sendCode,
            ),
    );
  }
}
