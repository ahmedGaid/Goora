import '../features/onboarding/domain/onboarding_flow.dart';

abstract final class Routes {
  static const welcome = '/';
  static const phone = '/phone';
  static const otp = '/otp';
  static const profile = '/profile';
  static const role = '/role';
  static const frequency = '/frequency';
  static const commuteSetup = '/commute-setup';
  static const emptySeats = '/empty-seats';
  static const offerTrip = '/offer-trip';
  static const match = '/match';
  static const noMatch = '/no-match';
  static const postTrip = '/post-trip';
  static const plan = '/plan';
  static const payMethod = '/pay-method';
  static const today = '/today';
  static const week = '/week';
  static const wallet = '/wallet';
  static const trust = '/trust';
  static const settings = '/settings';
  static const gallery = '/debug/gallery';

  static const phoneParam = 'phone';

  static String forDestination(Destination d) => switch (d) {
        Destination.commuteSetup => commuteSetup,
        Destination.emptySeatsToday => emptySeats,
        Destination.offerTrip => offerTrip,
      };
}
