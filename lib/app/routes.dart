import '../features/commute/domain/commute_profile.dart';
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
  static const findRiders = '/find-riders';
  static const plan = '/plan';
  static const payMethod = '/pay-method';

  /// 009: a rider's ID check before their first trip; `?next=` returns them.
  static const idCheck = '/id-check';
  static String idCheckThen(String next) => '$idCheck?next=${Uri.encodeQueryComponent(next)}';
  static const today = '/today';
  static const week = '/week';
  static const wallet = '/wallet';
  static const trust = '/trust';
  static const settings = '/settings';

  /// 010: the company account (register / pending / HR home / my enrollment).
  static const company = '/company';
  static const companyRegister = '/company/register';
  static const companyInvoices = '/company/invoices';
  static const companyInvoice = '/company/invoice';
  static const companyRoster = '/company/roster';
  static const companyLog = '/company/log';
  static const companyDashboard = '/company/dashboard';
  static const companyStatement = '/company/statement';
  static const gallery = '/debug/gallery';

  static const phoneParam = 'phone';

  /// Empty seats on one leg (`leg=going|return`).
  static String emptySeatsOn(Leg leg) => '$emptySeats?leg=${leg == Leg.ret ? 'return' : 'going'}';

  /// Post your trip with the rider's edits (area names, minutes of the day,
  /// repeat name), so a detour to pick a payment method comes back to the
  /// same form (F13).
  static String postTripDraft({required String from, required String to, required int at, required String repeat}) =>
      '$postTrip?from=$from&to=$to&at=$at&repeat=$repeat';

  static String forDestination(Destination d) => switch (d) {
        Destination.commuteSetup => commuteSetup,
        Destination.offerTrip => offerTrip,
        Destination.today => today,
      };
}
