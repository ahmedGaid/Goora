import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/place.dart';
import '../domain/company.dart';
import '../domain/company_terms.dart';
import '../domain/employee_month_facts.dart';
import '../domain/enrollment.dart';

/// The company network's demo data (research R10). **Every number here is a
/// placeholder**, chosen so the demo shows each state: Valeo bills the
/// minimum 20 seats with 12 enrolled, 8 are active each month, and one
/// route-gap area has only 3 waiting employees, so the dashboard hides it.
/// Orange Business shows the pending state. The demo user becomes an
/// employee only by enrolling.
abstract final class CompanySeed {
  static const valeoId = 'co-1';
  static const orangeId = 'co-2';

  /// Index of the next registered company (`co-3`).
  static const nextIndex = 3;

  /// Valeo's HR contact, also an employee who rides.
  static const valeoHrId = 'valeo-01';
  static const orangeHrId = 'orange-hr';

  /// Leg trip cost − share on the demo corridor (160 − 40), per rider trip.
  static const _savedPerTrip = 120;

  /// One leg Sheikh Zayed ↔ Smart Village in km. **Unverified placeholder**
  /// (research R7: measure before the dashboard ships, T043).
  static const legKmPlaceholder = 20;

  static const _people = <({String id, String name, String email})>[
    (id: 'valeo-01', name: 'Mona Adel', email: 'mona.adel@valeo.com'),
    (id: 'valeo-02', name: 'Karim Fawzy', email: 'karim.fawzy@valeo.com'),
    (id: 'valeo-03', name: 'Dina Samir', email: 'dina.samir@valeo.com'),
    (id: 'valeo-04', name: 'Hossam Nabil', email: 'hossam.nabil@valeo.com'),
    (id: 'valeo-05', name: 'Yasmin Fouad', email: 'yasmin.fouad@valeo.com'),
    (id: 'valeo-06', name: 'Sherif Lotfy', email: 'sherif.lotfy@valeo.com'),
    (id: 'valeo-07', name: 'Rana Hamdy', email: 'rana.hamdy@valeo.com'),
    (id: 'valeo-08', name: 'Ali Mansour', email: 'ali.mansour@valeo.com'),
    (id: 'valeo-09', name: 'Nada Wagdy', email: 'nada.wagdy@valeo.com'),
    (id: 'valeo-10', name: 'Tamer Ezz', email: 'tamer.ezz@valeo.com'),
    (id: 'valeo-11', name: 'Salma Reda', email: 'salma.reda@valeo.com'),
    (id: 'valeo-12', name: 'Bassem Gad', email: 'bassem.gad@valeo.com'),
  ];

  /// One month of activity per Valeo employee, the same every month: 6
  /// riders and 2 drivers active; 3 in October with a commute profile and no
  /// group (a route gap below 5); 1 who never set a commute.
  static final valeoFacts = <EmployeeMonthFacts>[
    _rider('valeo-01', 36, Area.sheikhZayed),
    _driver('valeo-02', 40, Area.sheikhZayed),
    _rider('valeo-03', 30, Area.sheikhZayed),
    _rider('valeo-04', 24, Area.sheikhZayed),
    _rider('valeo-05', 20, Area.sheikhZayed),
    _driver('valeo-06', 36, Area.october),
    _rider('valeo-07', 16, Area.october),
    _rider('valeo-08', 6, Area.sheikhZayed),
    _waiting('valeo-09'),
    _waiting('valeo-10'),
    _waiting('valeo-11'),
    const EmployeeMonthFacts(
      personId: 'valeo-12',
      riderTrips: 0,
      riderGoingTrips: 0,
      driverTrips: 0,
      savedEgp: 0,
      km: 0,
      homeArea: Area.sheikhZayed,
      hasProfile: false,
      hasGroup: false,
    ),
  ];

  /// Approved at 09:00 on the 1st, two months before [now]'s month, so the
  /// demo opens with two closed (paid) months and a running one.
  static Company valeo(WallTime now) {
    final start = CalendarDate(now.date.year, now.date.month, 1).addMonths(-2);
    return Company(
      id: valeoId,
      name: 'Valeo',
      domains: const ['valeo.com'],
      status: CompanyStatus.active,
      hrContactId: valeoHrId,
      minimumSeats: CompanyTerms.minimumSeats,
      pricePerSeat: CompanyTerms.pricePerSeat,
      contractStart: start,
      contractEnd: start.addMonths(CompanyTerms.contractMonths),
      approvedAt: WallTime(start, const Clock.hm(9, 0)),
    );
  }

  static const orange = Company(
    id: orangeId,
    name: 'Orange Business',
    domains: ['orange.com'],
    status: CompanyStatus.pending,
    hrContactId: orangeHrId,
    minimumSeats: CompanyTerms.minimumSeats,
    pricePerSeat: CompanyTerms.pricePerSeat,
  );

  /// Everyone enrolls on the approval day, a few minutes apart.
  static List<Enrollment> valeoEnrollments(WallTime approvedAt) => [
        for (final (i, p) in _people.indexed)
          Enrollment(
            personId: p.id,
            companyId: valeoId,
            name: p.name,
            workEmail: p.email,
            enrolledAt: approvedAt.plusMinutes(10 + i * 5),
          ),
      ];

  static EmployeeMonthFacts _rider(String id, int trips, Area home) => EmployeeMonthFacts(
        personId: id,
        riderTrips: trips,
        riderGoingTrips: trips ~/ 2,
        driverTrips: 0,
        savedEgp: trips * _savedPerTrip,
        km: trips * legKmPlaceholder,
        homeArea: home,
        hasProfile: true,
        hasGroup: true,
      );

  static EmployeeMonthFacts _driver(String id, int trips, Area home) => EmployeeMonthFacts(
        personId: id,
        riderTrips: 0,
        riderGoingTrips: 0,
        driverTrips: trips,
        savedEgp: 0,
        km: 0,
        homeArea: home,
        hasProfile: true,
        hasGroup: true,
      );

  static EmployeeMonthFacts _waiting(String id) => EmployeeMonthFacts(
        personId: id,
        riderTrips: 0,
        riderGoingTrips: 0,
        driverTrips: 0,
        savedEgp: 0,
        km: 0,
        homeArea: Area.october,
        hasProfile: true,
        hasGroup: false,
      );
}
