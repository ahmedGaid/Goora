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
  static const settings = '/settings';
  static const gallery = '/debug/gallery';

  static const phoneParam = 'phone';

  static String forDestination(Destination d) => switch (d) {
        Destination.commuteSetup => commuteSetup,
        Destination.emptySeatsToday => emptySeats,
        Destination.offerTrip => offerTrip,
      };
}
