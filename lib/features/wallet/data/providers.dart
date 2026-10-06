import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/domain/group.dart';
import '../../daily/data/providers.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/payment_provider.dart';
import '../domain/wallet_repository.dart';
import 'fake_payment_provider.dart';
import 'fake_wallet_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
PaymentProvider paymentProvider(Ref ref) => FakePaymentProvider();

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => FakeWalletRepository(
      ref.watch(sharedPreferencesProvider),
      daily: ref.watch(dailyCommuteRepositoryProvider),
      role: () => ref.read(sessionControllerProvider).profile!.role == Role.driver
          ? MemberRole.driver
          : MemberRole.rider,
      now: ref.watch(nowProvider),
      provider: ref.watch(paymentProviderProvider),
    );
