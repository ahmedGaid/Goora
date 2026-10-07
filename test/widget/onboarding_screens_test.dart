import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_icons.dart';
import 'package:goora/core/widgets/goora_progress_dots.dart';
import 'package:goora/core/widgets/goora_radio_card.dart';
import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/frequency_screen.dart';
import 'package:goora/features/onboarding/presentation/otp_screen.dart';
import 'package:goora/features/onboarding/presentation/phone_screen.dart';
import 'package:goora/features/onboarding/presentation/profile_screen.dart';
import 'package:goora/features/onboarding/presentation/role_screen.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/onboarding/presentation/welcome_screen.dart';
import 'package:goora/features/placeholder/presentation/placeholder_screen.dart';
import 'package:goora/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

final _phone = PhoneNumber.tryParse('01012345678')!;

Session _session({Role? role, Frequency? frequency, bool withProfile = true}) => Session(
      phone: _phone,
      profile: withProfile
          ? Profile(
              phone: _phone,
              firstName: 'Omar',
              lastName: 'Adel',
              gender: Gender.male,
              role: role,
              frequency: frequency,
            )
          : null,
    );

Future<void> _expectAccessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

void _expectDirection(WidgetTester tester, Locale locale) {
  expect(
    directionOf(tester, find.byType(Scaffold).first),
    locale == ar ? TextDirection.rtl : TextDirection.ltr,
  );
}

void main() {
  for (final locale in locales) {
    final l10n = l10nFor(locale);
    final tag = locale.languageCode;

    group('[$tag]', () {
      testWidgets('welcome: taglines, two actions, language pill', (tester) async {
        await pumpScreen(tester, const WelcomeScreen(), locale: locale);
        _expectDirection(tester, locale);
        expect(find.text(l10n.tagline), findsOneWidget);
        expect(find.text(l10n.taglineOther), findsOneWidget);
        expect(find.text(l10n.splashSub), findsOneWidget);
        expect(find.text(l10n.getStarted), findsOneWidget);
        expect(find.text(l10n.login), findsOneWidget);
        expect(find.text(l10n.langBtn), findsOneWidget);
        expect(find.bySemanticsLabel('Goora'), findsOneWidget);
        final arrow = tester.widget<Icon>(find.byIcon(GooraIcons.forward));
        expect(arrow.icon!.matchTextDirection, isTrue);
        await _expectAccessible(tester);
      });

      testWidgets('phone: continue only for a valid Egyptian mobile', (tester) async {
        await pumpScreen(tester, const PhoneScreen(), locale: locale);
        _expectDirection(tester, locale);
        expect(find.text(l10n.phoneTitle), findsOneWidget);
        expect(find.text(l10n.phoneHint), findsOneWidget);
        Finder cta() => find.byKey(const Key('phone-continue'));
        expect(tester.widget<FilledButton>(find.descendant(of: cta(), matching: find.byType(FilledButton))).onPressed, isNull);
        await tester.enterText(find.byKey(const Key('phone-field')), '0131234567');
        await tester.pump();
        expect(tester.widget<FilledButton>(find.descendant(of: cta(), matching: find.byType(FilledButton))).onPressed, isNull);
        await tester.enterText(find.byKey(const Key('phone-field')), '010 1234 5678');
        await tester.pump();
        expect(tester.widget<FilledButton>(find.descendant(of: cta(), matching: find.byType(FilledButton))).onPressed, isNotNull);
        await _expectAccessible(tester);
      });

      testWidgets('phone: offline shows a calm error and a retry', (tester) async {
        final prefs = await testPrefs();
        await pumpScreen(
          tester,
          const PhoneScreen(),
          locale: locale,
          overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(prefs, simulateOffline: true))],
        );
        await tester.enterText(find.byKey(const Key('phone-field')), '01012345678');
        await tester.pump();
        await tester.tap(find.byKey(const Key('phone-continue')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.networkError), findsOneWidget);
        expect(find.text(l10n.retry), findsOneWidget);
      });

      testWidgets('otp: wrong code shows error; dev hint and resend timer shown', (tester) async {
        await pumpScreen(tester, OtpScreen(phone: _phone), locale: locale);
        _expectDirection(tester, locale);
        expect(find.text(l10n.otpSub(_phone.local)), findsOneWidget);
        expect(find.text(l10n.otpDevHint), findsOneWidget);
        expect(find.text(l10n.otpResendIn(60)), findsOneWidget);
        expect(find.textContaining('60'), findsOneWidget, reason: 'Western digits in both languages');
        expect(find.textContaining('٦٠'), findsNothing);
        await tester.enterText(find.byKey(const Key('otp-field')), '000000');
        await tester.pumpAndSettle();
        expect(find.text(l10n.otpWrong), findsOneWidget);
        await tester.pump(const Duration(seconds: 61));
        expect(find.text(l10n.otpResend), findsOneWidget);
        await _expectAccessible(tester);
      });

      testWidgets('profile: needs first, last name and gender', (tester) async {
        await pumpScreen(tester, const ProfileScreen(), locale: locale, session: _session(withProfile: false));
        _expectDirection(tester, locale);
        expect(find.text(l10n.genderNote), findsOneWidget);
        FilledButton cta() => tester.widget<FilledButton>(
              find.descendant(of: find.byKey(const Key('profile-continue')), matching: find.byType(FilledButton)),
            );
        await tester.enterText(find.byKey(const Key('first-name')), 'Omar');
        await tester.enterText(find.byKey(const Key('last-name')), 'Adel');
        await tester.pump();
        expect(cta().onPressed, isNull);
        await tester.tap(find.byKey(const Key('gender-male')));
        await tester.pump();
        expect(cta().onPressed, isNotNull);
        await _expectAccessible(tester);
      });

      testWidgets('role: two cards, dots step 1, continue needs a choice', (tester) async {
        await pumpScreen(tester, const RoleScreen(), locale: locale, session: _session());
        _expectDirection(tester, locale);
        expect(find.text(l10n.howTravel), findsOneWidget);
        expect(find.text(l10n.switchAnytime), findsOneWidget);
        expect(find.text(l10n.canDrive), findsOneWidget);
        expect(find.text(l10n.needRide), findsOneWidget);
        expect(find.byIcon(GooraIcons.car), findsOneWidget);
        expect(find.byIcon(GooraIcons.person), findsOneWidget);
        expect(tester.widget<GooraProgressDots>(find.byType(GooraProgressDots)).current, 0);
        FilledButton cta() => tester.widget<FilledButton>(
              find.descendant(of: find.byKey(const Key('role-continue')), matching: find.byType(FilledButton)),
            );
        expect(cta().onPressed, isNull);
        await tester.tap(find.byKey(const Key('role-rider')));
        await tester.pump();
        expect(cta().onPressed, isNotNull);
        await _expectAccessible(tester);
      });

      for (final role in Role.values) {
        testWidgets('frequency (${role.name}): default, chip, sublines', (tester) async {
          await pumpScreen(tester, const FrequencyScreen(), locale: locale, session: _session(role: role));
          _expectDirection(tester, locale);
          expect(find.text(l10n.freqTitle), findsOneWidget);
          expect(find.text(l10n.freqSub), findsOneWidget);
          expect(find.text(l10n.fTag), findsOneWidget);
          final driver = role == Role.driver;
          expect(find.text(driver ? l10n.fRegDriver : l10n.fRegRider), findsOneWidget);
          expect(find.text(driver ? l10n.fOnceDriver : l10n.fOnceRider), findsOneWidget);
          final cards = tester.widgetList<GooraRadioCard>(find.byType(GooraRadioCard)).toList();
          expect(cards.first.selected, isTrue, reason: 'Every day is preselected');
          expect(cards.last.selected, isFalse);
          expect(tester.widget<GooraProgressDots>(find.byType(GooraProgressDots)).current, 1);
          await _expectAccessible(tester);
        });
      }

      for (final kind in PlaceholderKind.values) {
        testWidgets('placeholder ${kind.name}', (tester) async {
          await pumpScreen(tester, PlaceholderScreen(kind: kind), locale: locale, session: _session());
          _expectDirection(tester, locale);
          expect(find.text(l10n.comingSoonTitle), findsOneWidget);
          final title = switch (kind) {
            PlaceholderKind.emptySeats => l10n.emptySeatsTitle,
            PlaceholderKind.offerTrip => l10n.offerTitle,
            PlaceholderKind.postTrip => l10n.postReq,
            PlaceholderKind.plan => l10n.planTitle,
          };
          expect(find.text(title), findsWidgets);
          await _expectAccessible(tester);
        });
      }

      testWidgets('settings: switch role and it persists', (tester) async {
        final container = await pumpScreen(
          tester,
          const SettingsScreen(),
          locale: locale,
          session: _session(role: Role.rider, frequency: Frequency.everyDay),
        );
        _expectDirection(tester, locale);
        expect(find.text(l10n.settingsTitle), findsOneWidget);
        expect(find.text(l10n.toDriver), findsOneWidget);
        await tester.tap(find.byKey(const Key('switch-role')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.toRider), findsOneWidget);
        final stored = container.read(sessionControllerProvider).profile!.role;
        expect(stored, Role.driver);
        final prefs = await SharedPreferences.getInstance();
        expect((jsonDecode(prefs.getString('profile')!) as Map<String, Object?>)['role'], 'driver');
        await _expectAccessible(tester);
      });

      testWidgets('screens fit at 1.3× text size', (tester) async {
        for (final screen in <Widget>[
          const WelcomeScreen(),
          const PhoneScreen(),
          OtpScreen(phone: _phone),
          const ProfileScreen(),
          const RoleScreen(),
          const FrequencyScreen(),
          const PlaceholderScreen(kind: PlaceholderKind.emptySeats),
          const SettingsScreen(),
        ]) {
          await pumpScreen(tester, screen, locale: locale, session: _session(role: Role.driver), textScale: 1.3);
          expect(tester.takeException(), isNull);
        }
      });
    });
  }

  testWidgets('language pill flips the screen and keeps the selection', (tester) async {
    await pumpScreen(tester, const RoleScreen(), session: _session());
    await tester.tap(find.byKey(const Key('role-rider')));
    await tester.pump();
    await tester.tap(find.text(l10nFor(ar).langBtn));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor(en).howTravel), findsOneWidget);
    expect(directionOf(tester, find.byType(Scaffold).first), TextDirection.ltr);
    final rider = tester.widget<GooraRadioCard>(find.byKey(const Key('role-rider')));
    expect(rider.selected, isTrue);
  });
}
