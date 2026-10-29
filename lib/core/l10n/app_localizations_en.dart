// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'Go together. Every day.';

  @override
  String get getStarted => 'Get started';

  @override
  String get login => 'Log in';

  @override
  String get howTravel => 'How do you travel?';

  @override
  String get canDrive => 'I can drive';

  @override
  String get needRide => 'I need a ride';

  @override
  String get freqTitle => 'Every day or just once?';

  @override
  String get fRegular => 'Every day';

  @override
  String get fOnce => 'Just one trip';

  @override
  String get fTag => 'Best value';

  @override
  String get extraTrip => 'Need an extra trip? Book a seat';

  @override
  String get subNote => 'Included in your plan · no fees';

  @override
  String get whereGo => 'Where do you go every day?';

  @override
  String get dirBoth => 'Both ways';

  @override
  String get dirGoing => 'Going only';

  @override
  String get dirRet => 'Return only';

  @override
  String get findCommute => 'Find my commute';

  @override
  String get foundGroup => 'We found your commute group!';

  @override
  String get join => 'Join this group';

  @override
  String get confirmed => 'Your ride is confirmed';

  @override
  String get covered => 'Covered';

  @override
  String get cantCome => 'I can\'t come tomorrow';

  @override
  String get arrivedBtn => 'I\'ve arrived at Main Gate';

  @override
  String get pickedUp => 'Picked up';

  @override
  String get noShow => 'No-show';

  @override
  String get planTitle => 'Subscribe and pay no fees';

  @override
  String get planSubline => 'No service fee on any trip or seat.';

  @override
  String get planMonthlyTitle => 'Monthly';

  @override
  String get planMonthlySub => '149 EGP/month';

  @override
  String get planYearlyTitle => 'Yearly';

  @override
  String get planYearlySub => '1,490 EGP/year';

  @override
  String get planYearlyChip => '2 months free';

  @override
  String get planCompanyTitle => 'Through my company';

  @override
  String get planCompanySub => 'Free — verify your work email';

  @override
  String get planIncludedTitle => 'What\'s included';

  @override
  String get planIncludedMatch => 'Matching with your daily group';

  @override
  String get planIncludedBackup => 'A backup driver when yours can\'t make it';

  @override
  String get planIncludedTrust => 'Reliability tracking and SOS safety tools';

  @override
  String get planFuelNote =>
      'The fuel & tolls you pay each trip go straight to your driver, in full.';

  @override
  String get planCtaVerify => 'Verify work email';

  @override
  String get planFooter => 'Cancel anytime. Goora is free for drivers.';

  @override
  String get verifyEmailTitle => 'Verify your work email';

  @override
  String verifyEmailBody(String company) {
    return '$company will cover your Goora plan once your work email is verified.';
  }

  @override
  String get verifyConfirm => 'Confirm';

  @override
  String get verifyNotVerified => 'Verify your work email in Trust first.';

  @override
  String get balanceLabel => 'Wallet balance';

  @override
  String get topUp => 'Top up';

  @override
  String coversTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Covers about $count trips',
      one: 'Covers about 1 trip',
      zero: 'Pays Goora\'s fee, never the driver\'s share',
    );
    return '$_temp0';
  }

  @override
  String get planChange => 'Change';

  @override
  String get planCompanyActive => 'Free · paid by your company';

  @override
  String get howPayTitle => 'How paying works';

  @override
  String get howPayRule1 =>
      'You pay your driver\'s share directly, by cash or InstaPay. Goora adds only a service fee of up to 10% per trip; subscribers pay no fee.';

  @override
  String get howPayRule1Company =>
      'You pay your driver\'s share directly, by cash or InstaPay. Your company plan covers Goora\'s fee, so you pay no service fee.';

  @override
  String get howPayRule2 =>
      'The driver\'s share goes straight to them. Goora never holds it or takes a cut.';

  @override
  String get howPayRule3 =>
      'Late cancellations and no-shows are paid to the driver directly, with no service fee.';

  @override
  String get topUpSheetTitle => 'Top up your wallet';

  @override
  String get topUpMethodInstaPay => 'InstaPay';

  @override
  String get topUpMethodVodafone => 'Vodafone Cash';

  @override
  String get topUpMethodCard => 'Card';

  @override
  String get topUpConfirm => 'Confirm top-up';

  @override
  String get topUpFailTitle => 'Top-up didn\'t go through';

  @override
  String get topUpFailBody => 'Nothing was charged — try again.';

  @override
  String get changePlanTitle => 'Change your plan';

  @override
  String get changePlanNote =>
      'Takes effect on your next billing date — nothing changes for your current period.';

  @override
  String get changePlanConfirm => 'Confirm change';

  @override
  String get breakdownTitle => 'What you pay per trip';

  @override
  String get breakdownFuel => 'Fuel & tolls';

  @override
  String get breakdownTotal => 'Total';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmpty => 'No activity yet';

  @override
  String get actTopUp => 'Top-up';

  @override
  String get actTripDeduction => 'Trip cost';

  @override
  String get actLateCancelCharge => 'Late cancel';

  @override
  String get actFreeCancelZero => 'Free cancellation';

  @override
  String get actTripIncome => 'Trip income';

  @override
  String actFeeReceivedFrom(String name) {
    return '$name\'s fee';
  }

  @override
  String get actWithdrawal => 'Withdrawal';

  @override
  String get driverBreakdownTitle => 'Your trip cost';

  @override
  String get driverBreakdownCost => 'Trip cost';

  @override
  String get driverBreakdownReceived => 'You receive from riders';

  @override
  String get driverBreakdownGap => 'What you pay yourself';

  @override
  String get driverBreakdownFree => 'Goora is free for drivers';

  @override
  String get postReq => 'Post your trip';

  @override
  String get seeYourRequest => 'See your request';

  @override
  String get offerBtn => 'Offer a trip';

  @override
  String get reqsOnRoute => 'Requests on your route';

  @override
  String get browseBtn => 'Find riders';

  @override
  String get browseTitle => 'Requests near you';

  @override
  String get tripsLeftA => 'Trips left today';

  @override
  String get tabToday => 'Today';

  @override
  String get tabWeek => 'Week';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabTrust => 'Trust';

  @override
  String get sos => 'SOS';

  @override
  String get langBtn => 'عربي';

  @override
  String get langAria => 'التبديل للعربية';

  @override
  String get back => 'Back';

  @override
  String get continueBtn => 'Continue';

  @override
  String get taglineOther => 'مشوارك.. سوا.';

  @override
  String get splashSub =>
      'Your daily commute, organized with people going your way. No searching every morning.';

  @override
  String get switchAnytime => 'You can switch anytime.';

  @override
  String get canDriveSub => 'I have empty seats and want to share costs';

  @override
  String get needRideSub => 'I\'m looking for a ride to my destination';

  @override
  String get freqSub => 'You can always do the other one later.';

  @override
  String get fRegRider =>
      'A fixed group for your daily commute. Your first 5 trips have no Goora fee.';

  @override
  String get fOnceRider =>
      'Book an empty seat or post your trip. No subscription.';

  @override
  String get fRegDriver =>
      'Share your daily commute with a fixed group. Always free.';

  @override
  String get fOnceDriver =>
      'Offer your empty seats on a trip you\'re already making.';

  @override
  String get toDriver => 'Switch to driver mode';

  @override
  String get toRider => 'Switch to rider mode';

  @override
  String get emptySeatsTitle => 'Empty seats';

  @override
  String get offerTitle => 'Offer a trip';

  @override
  String get backupTitle => 'Ahmed can\'t drive on Tuesday';

  @override
  String get backupBody =>
      'Mohamed will drive instead. Your commute is still covered — nothing for you to do.';

  @override
  String get gotIt => 'Got it';

  @override
  String get pickupIn => 'Pickup in 12 min';

  @override
  String get verifiedMember => 'Verified member · 4.9 ★';

  @override
  String get phoneTitle => 'What\'s your mobile number?';

  @override
  String get phoneSub => 'We\'ll text you a code to confirm it\'s yours.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => 'An Egyptian mobile: 11 digits starting with 01';

  @override
  String get sendCode => 'Send me the code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String get otpWrong => 'That code doesn\'t match. Try again.';

  @override
  String get otpResend => 'Send a new code';

  @override
  String get otpDevHint => 'Test code: 123456';

  @override
  String get changeNumber => 'Change number';

  @override
  String get networkError =>
      'We couldn\'t send the code right now. Check your connection and try again.';

  @override
  String get retry => 'Try again';

  @override
  String get profileTitle => 'Let\'s get to know you';

  @override
  String get profileSub => 'So your group knows who they\'re riding with.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get genderLabel => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get genderNote =>
      'Used only for the women-only option. No one else sees it.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get roleLabel => 'How you travel';

  @override
  String get comingSoonTitle => 'This screen is coming soon';

  @override
  String get comingSoonBody => 'We\'re building it now. Your choice is saved.';

  @override
  String get openSettings => 'Settings';

  @override
  String get galleryTitle => 'Design gallery';

  @override
  String get galleryColors => 'Colors';

  @override
  String get galleryType => 'Type';

  @override
  String get galleryShape => 'Shape & spacing';

  @override
  String get galleryButtons => 'Buttons';

  @override
  String get galleryCards => 'Cards';

  @override
  String get gallerySelection => 'Selection';

  @override
  String get galleryFeedback => 'Banners';

  @override
  String get galleryPeople => 'People';

  @override
  String get galleryNav => 'Navigation';

  @override
  String get galleryDecrease => 'Decrease';

  @override
  String get galleryIncrease => 'Increase';

  @override
  String otpSub(String phone) {
    return 'We sent it to $phone';
  }

  @override
  String otpResendIn(int seconds) {
    return 'You can ask for a new code in ${seconds}s';
  }

  @override
  String stepperValue(String value) {
    return '$value EGP';
  }

  @override
  String get navMain => 'Main';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get home => 'Home';

  @override
  String get work => 'Work / study';

  @override
  String get areaSheikhZayed => 'Sheikh Zayed';

  @override
  String get areaOctober => '6th of October';

  @override
  String get areaSmartVillage => 'Smart Village';

  @override
  String get areaNewCairo => 'New Cairo';

  @override
  String get areaNasrCity => 'Nasr City';

  @override
  String get areaHeliopolis => 'Heliopolis';

  @override
  String get areaObour => 'Obour';

  @override
  String get areaTenthOfRamadan => '10th of Ramadan';

  @override
  String get areaIsmailia => 'Ismailia';

  @override
  String get pickHome => 'Where\'s home?';

  @override
  String get pickWork => 'Where\'s work?';

  @override
  String get choosePlace => 'Choose a place';

  @override
  String get whenTravel => 'When do you travel?';

  @override
  String get departure => 'Departure';

  @override
  String get returnT => 'Return';

  @override
  String get workingDays => 'Working days';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get sunThu => 'Sun – Thu';

  @override
  String get seatsQ => 'Empty seats in your car';

  @override
  String get pickTime => 'Pick a time';

  @override
  String get fewerSeats => 'One seat fewer';

  @override
  String get moreSeats => 'One more seat';

  @override
  String get whichTrips => 'Which trips do you drive?';

  @override
  String get otherTripNote =>
      'Riders get the other trip from another driver in the group.';

  @override
  String get contribTitle => 'Your contribution per rider';

  @override
  String get lowerContribution => 'Lower contribution';

  @override
  String get raiseContribution => 'Raise contribution';

  @override
  String get suggestedPrice => 'Suggested price';

  @override
  String get contribNote =>
      'Based on distance, fuel and tolls. Riders see it before joining, and it stays fixed for the month.';

  @override
  String get recoverDay => 'You recover per day';

  @override
  String get earlier => '5 minutes earlier';

  @override
  String get later => '5 minutes later';

  @override
  String get sameAreaHint => 'Choose a work place more than 1.5 km from home.';

  @override
  String get returnHint => 'Return must be after departure.';

  @override
  String get noDaysHint => 'Pick at least one day.';

  @override
  String get mapAria => 'Route map';

  @override
  String get foundSub => 'People going your way, at your time.';

  @override
  String get statDrivers => 'drivers';

  @override
  String get statRiders => 'riders';

  @override
  String get statFixed => 'fixed';

  @override
  String get egpTrip => 'EGP/trip';

  @override
  String get whyGroup => 'Why this group';

  @override
  String get otherMatches => 'Other matches';

  @override
  String get chooseThisGroup => 'Choose this group';

  @override
  String get seeOthers => 'See other options';

  @override
  String get hideOthers => 'Hide other options';

  @override
  String get reasonSameDeparture => 'Same departure time';

  @override
  String get reasonCompanyReturn => 'Same company · similar return time';

  @override
  String get reasonCompany => 'Same company';

  @override
  String get reasonCompound => 'Same compound';

  @override
  String get reasonReturn => 'Similar return time';

  @override
  String get verifiedRider => 'Verified rider';

  @override
  String get verifiedRiderWoman => 'Verified rider (woman)';

  @override
  String egpAmount(int amount) {
    return '$amount EGP';
  }

  @override
  String aboveSuggested(int amount) {
    return '$amount EGP above suggested';
  }

  @override
  String belowSuggested(int amount) {
    return '$amount EGP below suggested';
  }

  @override
  String suggestedShort(int amount) {
    return 'Suggested $amount';
  }

  @override
  String timeAm(String time) {
    return '$time AM';
  }

  @override
  String timePm(String time) {
    return '$time PM';
  }

  @override
  String matchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String perWeek(int count) {
    return '$count/wk';
  }

  @override
  String reasonDestination(String area) {
    return 'Same destination: $area';
  }

  @override
  String reasonDeparture(int minutes) {
    return '$minutes-minute departure difference';
  }

  @override
  String reasonPickup(int meters) {
    return 'Pickup $meters m from home';
  }

  @override
  String reasonDays(int count) {
    return '$count shared working days';
  }

  @override
  String reasonRating(String rating) {
    return 'Members rated $rating ★';
  }

  @override
  String otherMeta(String time, int meters) {
    return '$time · $meters m';
  }

  @override
  String returnLeg(String time) {
    return 'Return with the $time group';
  }

  @override
  String noMatch(int position, String from, String to) {
    return 'You\'re #$position on the $from → $to list — we\'ll notify you as soon as we have a match';
  }

  @override
  String routeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String timeDays(String time, String days) {
    return '$time · $days';
  }

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get todaySub => 'Here\'s your commute for today.';

  @override
  String nextRide(String day) {
    return 'Your next ride · $day';
  }

  @override
  String get relToday => 'today';

  @override
  String get relTomorrow => 'tomorrow';

  @override
  String relTomorrowDay(String day) {
    return 'tomorrow ($day)';
  }

  @override
  String relOn(String day) {
    return 'on $day';
  }

  @override
  String get heroToday => 'Today';

  @override
  String get heroTomorrow => 'Tomorrow';

  @override
  String get legGoing => 'Going';

  @override
  String get legReturn => 'Return';

  @override
  String legRow(String leg, String driver, String time) {
    return '$leg: $driver · $time';
  }

  @override
  String get youWord => 'You';

  @override
  String get noDriverYet => 'No driver yet';

  @override
  String get legsNote =>
      'Going and return are separate trips — they can have different drivers.';

  @override
  String goingLeg(String time) {
    return 'Going with the $time group';
  }

  @override
  String pickupInMin(int minutes) {
    return 'Pickup in $minutes min';
  }

  @override
  String get callDriver => 'Call driver';

  @override
  String callName(String name) {
    return 'Call $name';
  }

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String carLine(String car, String colour, String rating) {
    return '$car · $colour · $rating ★';
  }

  @override
  String get colourWhite => 'White';

  @override
  String get colourSilver => 'Silver';

  @override
  String get colourBlack => 'Black';

  @override
  String get colourGrey => 'Grey';

  @override
  String get colourRed => 'Red';

  @override
  String get colourBlue => 'Blue';

  @override
  String get stopMainGate => 'Main Gate';

  @override
  String get stopCentralSt => 'Central St.';

  @override
  String get stopGasStation => 'Gas station, 26th of July';

  @override
  String get stopSmartVillageGate2 => 'Smart Village, Gate 2';

  @override
  String get stopNewCairoMeet => 'New Cairo, 90th Street';

  @override
  String get stopNasrCityMeet => 'Nasr City, City Stars';

  @override
  String get stopHeliopolisMeet => 'Heliopolis, Korba Square';

  @override
  String get stopObourMeet => 'Obour, Obour Market';

  @override
  String get stopTenthOfRamadanMeet => '10th of Ramadan, 1st District';

  @override
  String get stopIsmailiaMeet => 'Ismailia, El Mamar Square';

  @override
  String tlPickup(String time) {
    return 'Pickup · $time';
  }

  @override
  String get tlOnTheWay => 'On the way';

  @override
  String tlPassengers(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
    );
    return '$_temp0 · $names';
  }

  @override
  String tlArrival(String time) {
    return 'Arrival · $time';
  }

  @override
  String get listSep => ', ';

  @override
  String get returnTime => 'Return time';

  @override
  String get noReturnTrip => 'No return trip';

  @override
  String get payPerTrip => 'You pay per trip';

  @override
  String get shareTrip => 'Share trip';

  @override
  String get cantComeNote =>
      'Free before 9 PM · after that you pay half your share';

  @override
  String offTitle(String when) {
    return 'You\'re off $when';
  }

  @override
  String offLegTitle(String trip, String when) {
    return 'You\'re skipping $trip $when';
  }

  @override
  String get tripGoing => 'the going trip';

  @override
  String get tripReturn => 'the return trip';

  @override
  String get offBody =>
      'Cancelled before 9 PM — no charge. Your seat was offered to the waitlist.';

  @override
  String lateOffBody(int amount) {
    return 'Cancelled after 9 PM — $amount EGP to the driver.';
  }

  @override
  String get undo => 'Undo, I\'m coming';

  @override
  String get undoRefused =>
      'Your seat went to the waitlist, so we can\'t undo this. You can book an empty seat if you need one.';

  @override
  String get undoTooLate => 'Pickup time has passed, so this can\'t be undone.';

  @override
  String get cantComeTitle => 'Which trips can\'t you make?';

  @override
  String legAt(String leg, String time) {
    return '$leg · $time';
  }

  @override
  String get freeCancelPreview => 'Before 9 PM: free';

  @override
  String lateCancelPreview(int amount) {
    return 'After 9 PM: you\'ll pay $amount EGP to the driver';
  }

  @override
  String get confirmCancel => 'Confirm cancel';

  @override
  String get pickOneTrip => 'Pick at least one trip';

  @override
  String get cancelAfterPickup =>
      'Pickup time has passed. If you don\'t come, the driver will mark a no-show.';

  @override
  String get notNextWeek => 'Not coming next week';

  @override
  String get notNextWeekConfirm =>
      'We\'ll mark every day next week off. Days still before 9 PM are free.';

  @override
  String get notNextWeekDone => 'Done — next week is marked off.';

  @override
  String get keepIt => 'No, keep it';

  @override
  String get headsUp => 'Heads up';

  @override
  String get noShowWarning =>
      'You missed 2 pickups this month. A third will remove you from the group.';

  @override
  String get removedTitle => 'You\'re no longer in the group';

  @override
  String get removedNotice =>
      'You were removed from the group after 3 no-shows this month. Your commute is saved and we can find you a new group.';

  @override
  String get findNewGroup => 'Find me a new group';

  @override
  String drivingWhen(String when) {
    return 'You\'re driving $when.';
  }

  @override
  String get notDrivingSoon => 'No drives for you in the coming days.';

  @override
  String heroDriver(String when, String direction, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
      zero: 'no passengers',
    );
    return '$when · $direction · $_temp0';
  }

  @override
  String pickupN(int n, String stop) {
    return 'Pickup $n — $stop';
  }

  @override
  String returnFrom(String place) {
    return 'Return from $place';
  }

  @override
  String get estContrib => 'Estimated contribution';

  @override
  String get confirmDrive => 'Confirm tomorrow’s drive';

  @override
  String get confirmDriveToday => 'Confirm today’s drive';

  @override
  String confirmDriveDay(String day) {
    return 'Confirm the drive on $day';
  }

  @override
  String get confirmedNote => 'Confirmed. Your passengers have been notified.';

  @override
  String get undoConfirm => 'Undo confirmation';

  @override
  String get reportDelay => 'Report delay';

  @override
  String get cantDrive => 'Can\'t drive';

  @override
  String get cantDriveConfirm =>
      'Sure? We\'ll look for a backup driver for your riders.';

  @override
  String get cantDriveYes => 'Yes, I can\'t drive';

  @override
  String get keepDriving => 'No, I\'ll drive';

  @override
  String cantDriveDone(String when) {
    return 'We told the group you can\'t drive $when. We\'re looking for a backup driver.';
  }

  @override
  String get delayTitle => 'How late will you be?';

  @override
  String delayMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String delaySent(String time) {
    return 'Riders were told the new time: $time';
  }

  @override
  String get reqPrivacy =>
      'Requests show only if your detour is under 10 minutes. The price is fixed by Goora.';

  @override
  String get reqsPlaceholder =>
      'Riders\' requests on your route will show here.';

  @override
  String rideWith(String day, String driver) {
    return 'Riding $day with $driver';
  }

  @override
  String get checkin => 'Pickup check-in';

  @override
  String arrivedAt(String stop) {
    return 'I\'ve arrived at $stop';
  }

  @override
  String get arrivedNote => 'Passengers get notified. You wait 5 minutes max.';

  @override
  String stWaiting(String time) {
    return 'Notified · waiting $time';
  }

  @override
  String get stNotArrived => 'Not arrived yet';

  @override
  String get stNoShow => 'No-show · full share charged';

  @override
  String noShowAvailableIn(String time) {
    return 'Available in $time';
  }

  @override
  String get noShowNote =>
      'No-show after 5 minutes: the rider still pays their full share.';

  @override
  String ratingStars(String rating) {
    return '$rating ★';
  }

  @override
  String get startTrip => 'Start trip';

  @override
  String get endTrip => 'End trip';

  @override
  String get tripOnWay => 'Trip started. Drive safe.';

  @override
  String get tripEndedNote => 'Trip ended. Thanks!';

  @override
  String get refusedNoShowEarly => 'Wait until the 5 minutes are up.';

  @override
  String get refusedTripStarted =>
      'The trip has started, so marks can\'t change.';

  @override
  String get inboxTitle => 'Notifications';

  @override
  String get inboxEmpty => 'No notifications yet';

  @override
  String get inboxEmptyBody =>
      'We\'ll tell you here about any change to your rides.';

  @override
  String inboxAria(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get sentToRiders => 'Sent to your riders';

  @override
  String nDriverConfirmed(String day) {
    return 'The driver confirmed $day\'s drive.';
  }

  @override
  String nDriverUnconfirmed(String day) {
    return 'The driver undid the confirmation for $day.';
  }

  @override
  String nDelay(int minutes, String time) {
    return 'The driver is running $minutes min late. New pickup time: $time.';
  }

  @override
  String nDriverArrived(String stop) {
    return 'The driver is at $stop. Please come within 5 minutes.';
  }

  @override
  String nLateCancel(String day, int amount) {
    return 'Late cancel on $day: $amount EGP to the driver.';
  }

  @override
  String nNoShow(String day, int amount) {
    return 'No-show on $day: $amount EGP to the driver.';
  }

  @override
  String nSeatOffered(String day) {
    return 'Your seat on $day was offered to the waitlist.';
  }

  @override
  String backupTitleFor(String driver, String day) {
    return '$driver can\'t drive on $day';
  }

  @override
  String backupBodyFor(String cover) {
    return '$cover will drive instead. Your commute is still covered — nothing for you to do.';
  }

  @override
  String noCoverTitle(String when) {
    return 'No driver $when';
  }

  @override
  String noCoverBody(String driver) {
    return '$driver can\'t drive and we found no cover. Pick what suits you:';
  }

  @override
  String get noCoverDayOff => 'Take the day off — free';

  @override
  String get sosTitle => 'Need help?';

  @override
  String get sosCall => 'Call 122';

  @override
  String get sosAlert => 'Alert my trusted contacts';

  @override
  String get sosAlertSent => 'We sent them your trip link';

  @override
  String get sosNoContacts =>
      'Add a trusted contact so we can alert them in an emergency';

  @override
  String get trustedTitle => 'Trusted contacts';

  @override
  String get trustedAdd => 'Add contact';

  @override
  String get trustedMax => 'You can add up to 3';

  @override
  String shareMessage(
    String driver,
    String car,
    String from,
    String to,
    String time,
    String link,
  ) {
    return 'I\'m on my commute with $driver ($car) from $from to $to, arriving around $time. Follow along: $link';
  }

  @override
  String get scheduleTitle => 'Your commute schedule';

  @override
  String get rotateNote =>
      'Goora rotates drivers fairly and fills gaps automatically when someone can\'t make it.';

  @override
  String drivesName(String name) {
    return '$name drives';
  }

  @override
  String get youDrive => 'You drive';

  @override
  String get youRide => 'You ride';

  @override
  String get youOff => 'You\'re off';

  @override
  String get offNote => 'Cancelled before 9 PM · no charge';

  @override
  String lateOffNote(int amount) {
    return 'Cancelled after 9 PM · $amount EGP to the driver';
  }

  @override
  String backupName(String name) {
    return '$name (backup)';
  }

  @override
  String memberRating(String rating) {
    return 'Member · $rating ★';
  }

  @override
  String verifiedMemberRating(String rating) {
    return 'Verified member · $rating ★';
  }

  @override
  String get reliability => 'Reliability';

  @override
  String relLateCancels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late cancels this month.',
      one: '1 late cancel this month.',
    );
    return '$_temp0';
  }

  @override
  String relNoShows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no-shows this month.',
      one: '1 no-show this month.',
    );
    return '$_temp0';
  }

  @override
  String get relRule => '3 no-shows in a month removes you from the group.';

  @override
  String get whoRide => 'Who can ride with me';

  @override
  String get checkPhone => 'Phone number';

  @override
  String get checkNationalId => 'National ID';

  @override
  String get checkWorkEmail => 'Work email';

  @override
  String get checkLicense => 'Driving license';

  @override
  String get checkVehicle => 'Vehicle';

  @override
  String get notNeeded => 'Not needed';

  @override
  String get privacyVerified => 'Verified users';

  @override
  String get privacyCompany => 'Same company';

  @override
  String get privacyCompound => 'Same compound';

  @override
  String get privacyWomen => 'Women only';

  @override
  String get privacyNote =>
      'This applies to future groups, not your current one.';

  @override
  String get needWorkEmail => 'Verify your work email first';

  @override
  String get needCompound => 'Add your compound first';

  @override
  String get driverNeedsDocs =>
      'To drive, your license and vehicle need to be verified.';

  @override
  String get demoSection => 'Demo (developers)';

  @override
  String demoNow(String time) {
    return 'Time now: $time';
  }

  @override
  String get demoRideDay => 'Ride day · 7:15 AM';

  @override
  String get demo855 => 'Before 9 PM · 8:55 PM';

  @override
  String get demo905 => 'After 9 PM · 9:05 PM';

  @override
  String get demoRealTime => 'Real time';

  @override
  String get demoReset => 'Reset demo data';

  @override
  String get noRidesSoon => 'No rides in the coming days.';

  @override
  String get loadingToday => 'Getting your commute…';

  @override
  String get todayError => 'We couldn\'t load your commute right now.';

  @override
  String nDriverNoShow(String day) {
    return 'You didn\'t check in for $day\'s drive, so it counts as a no-show.';
  }

  @override
  String carColour(String car, String colour) {
    return '$car · $colour';
  }

  @override
  String demoNowValue(String day, String date, String time) {
    return '$day $date · $time';
  }

  @override
  String get noCoverEmptySeat => 'Book an empty seat';

  @override
  String get offNoCoverBody => 'No driver that day, so there\'s no charge.';

  @override
  String get noCoverNote => 'No driver · no charge';

  @override
  String get demoBackup => 'Driver can\'t drive next Tuesday';

  @override
  String get demoNoCover => 'Driver can\'t drive — no cover';

  @override
  String weekRiderLine(String going, String ret) {
    return 'Going: $going · Return: $ret';
  }

  @override
  String weekLegLine(String leg, String time) {
    return '$leg: $time';
  }

  @override
  String weekDriveLine(String direction, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
      zero: 'no passengers',
    );
    return '$direction · $_temp0';
  }

  @override
  String get weekEmpty => 'No commute days this week.';

  @override
  String get verificationTitle => 'Verification';

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String trustedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
      zero: 'None yet',
    );
    return '$_temp0';
  }

  @override
  String get contactName => 'Name';

  @override
  String removeContact(String name) {
    return 'Remove $name';
  }

  @override
  String arrivalInMin(int minutes) {
    return 'Arriving in $minutes min';
  }

  @override
  String get mapLiveAria => 'Route map · your driver is on the way';

  @override
  String get demoDriverArrives => 'Driver arrives at my stop';

  @override
  String get shareNoTrip => 'No trip to share right now.';

  @override
  String priceWithFee(int price, int fee) {
    return '$price EGP to the driver + $fee EGP Goora fee';
  }

  @override
  String priceNoFee(int price) {
    return '$price EGP to the driver · no service fee';
  }

  @override
  String priceSubscribed(int price) {
    return '$price EGP · no fees (subscribed)';
  }

  @override
  String priceCompany(int price) {
    return '$price EGP · no fees (company)';
  }

  @override
  String priceCash(int price) {
    return 'Pay $price EGP cash to the driver';
  }

  @override
  String get payMethodTitle => 'How will you pay the driver?';

  @override
  String get payMethodSub =>
      'You pay the driver directly. Your first 5 trips have no Goora fee.';

  @override
  String get payCash => 'Cash';

  @override
  String get payCashSub => 'Hand it to the driver in the car.';

  @override
  String get payWallet => 'InstaPay';

  @override
  String get subscribeLink => 'Subscribe and pay no fees';

  @override
  String subscribeCta(int price) {
    return 'Subscribe · $price EGP';
  }

  @override
  String subNeedsTopUp(int gap, int balance) {
    return 'Top up $gap EGP first — your wallet has $balance EGP.';
  }

  @override
  String get subscribe => 'Subscribe';

  @override
  String get planPayPerTrip => 'Pay per trip';

  @override
  String planPerTripLine(int fee) {
    return '$fee EGP service fee per trip';
  }

  @override
  String get planPerTripNoFeeLine => 'No service fee on your trips';

  @override
  String planBundleLine(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your bundle covers Goora\'s fee · $count trips left',
      one: 'Your bundle covers Goora\'s fee · 1 trip left',
    );
    return '$_temp0';
  }

  @override
  String planSubscribedLine(String date) {
    return 'Subscribed until $date · no fees';
  }

  @override
  String get planLapsedLine => 'Subscription ended · back to pay per trip';

  @override
  String cashTripsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fee-free trips left',
      one: '1 fee-free trip left',
      zero: 'No fee-free trips left',
    );
    return '$_temp0';
  }

  @override
  String get cashTopUpBanner =>
      'After these, each trip has a small Goora fee, or subscribe and pay no fees.';

  @override
  String get cashEnded =>
      'Your fee-free trips are done. Each trip now has a small Goora fee.';

  @override
  String get cashOff =>
      'Your fee-free trips ended after 2 trips were marked unpaid.';

  @override
  String get needsTopUp => 'Top up to keep riding';

  @override
  String feeSavings(int fees) {
    return 'You paid $fees EGP in fees this month. The subscription is 149, with a guaranteed seat and a backup if your driver can\'t come.';
  }

  @override
  String get actTrip => 'Trip';

  @override
  String get actCashTrip => 'Fee-free trip';

  @override
  String get actSubscription => 'Subscription';

  @override
  String cashPaidLine(int price) {
    return '$price EGP to the driver directly';
  }

  @override
  String get notChargedCash => 'Not charged during the cash trial';

  @override
  String get breakdownShare => 'Driver\'s share';

  @override
  String get breakdownFee => 'Service fee';

  @override
  String get breakdownNoFee => 'Service fee: none';

  @override
  String cashReceived(int price) {
    return 'Received $price EGP';
  }

  @override
  String get didNotPay => 'Didn\'t get it';

  @override
  String get cashMarkedReceived => 'Received';

  @override
  String get cashMarkedUnpaid => 'Marked unpaid';

  @override
  String get cashReceivedTitle => 'Received directly this month';

  @override
  String get cashReceivedNote =>
      'Paid to you by passengers. Goora never holds it.';

  @override
  String needsTopUpBody(int total) {
    return 'Your balance is below one trip ($total EGP).';
  }

  @override
  String priceDriver(int price) {
    return '$price EGP to you per passenger · Goora is free for drivers';
  }

  @override
  String seatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats left',
      one: '1 seat left',
    );
    return '$_temp0';
  }

  @override
  String get bookSeat => 'Book seat';

  @override
  String get seatRule =>
      'Subscribers get priority on empty seats. If a subscriber takes your seat before 9 PM the evening before, you get back everything you paid.';

  @override
  String get nothingFits => 'Nothing fits your time? Post your trip';

  @override
  String get alreadyRiding => 'You already have a ride on this trip.';

  @override
  String get seatBookedTitle => 'Seat booked';

  @override
  String get upsellDaily => 'Liked it? Make it your daily commute';

  @override
  String get backToToday => 'Back to today';

  @override
  String get lateBookingNote =>
      'It\'s past 9 PM the evening before, so cancelling now means paying half your share.';

  @override
  String topUpFirst(int gap) {
    return 'Top up $gap EGP first';
  }

  @override
  String get seatJustTaken =>
      'That seat was just taken. Here\'s the updated list.';

  @override
  String get justOnce => 'Just once';

  @override
  String get everyWorkday => 'Every workday';

  @override
  String get ruleNoBidding => 'The price is set by Goora — no bargaining';

  @override
  String get ruleCostShare => 'Drivers share costs, they don\'t profit';

  @override
  String get ruleRoute => 'Only people on your route see it';

  @override
  String get post => 'Post';

  @override
  String sentToDrivers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent to $count drivers on your route',
      one: 'Sent to 1 driver on your route',
    );
    return '$_temp0';
  }

  @override
  String get waitingDriver => 'Waiting for a driver to accept';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get requestAccepted => 'A driver accepted your trip';

  @override
  String get nowGroup => 'You\'re now a commute group';

  @override
  String get requestExpired =>
      'No driver took this trip in time. Nothing was charged.';

  @override
  String get postAgain => 'Post again';

  @override
  String get seeEmptySeats => 'See empty seats';

  @override
  String get dailyNeedsNoGroup => 'You\'re already in a daily group';

  @override
  String verifyChip(String item) {
    return '$item not verified — verify';
  }

  @override
  String get publish => 'Publish';

  @override
  String get dailyLimitReached => 'Daily limit reached';

  @override
  String joinsTripInstead(String time) {
    return 'This joins your trip at $time';
  }

  @override
  String seatsBooked(int booked, int seats) {
    return '$booked of $seats seats booked';
  }

  @override
  String get carFull => 'Your car is full!';

  @override
  String get newRider => 'New';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String tripCancelledRefund(String driver) {
    return '$driver cancelled the trip. You got back everything you paid.';
  }

  @override
  String get leavingFrom => 'Leaving from';

  @override
  String get allAreas => 'All';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String createsTrip(String route, String time, int count) {
    return 'This creates your trip: $route · $time. Trips left after this: $count';
  }

  @override
  String get doesntFit => 'Doesn\'t fit your trip';

  @override
  String get yourCarFull => 'Your car is full';

  @override
  String get oneGroupOnly => 'You already drive a daily group';

  @override
  String get overlapTrip => 'You have another trip at that time';

  @override
  String get accept => 'Accept';

  @override
  String get accepted => 'Accepted ✓';

  @override
  String demandBanner(int count, String route, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'in the morning',
      'evening': 'in the evening',
      'other': '',
    });
    return '$count people want $route $_temp0';
  }

  @override
  String detourMin(int min) {
    return '+$min min detour';
  }

  @override
  String get noRequests =>
      'No requests on your route right now. We\'ll show them here as they come in.';

  @override
  String get privacyCaption => 'You\'ll see names when riders board.';

  @override
  String seatReclaimed(String day, int amount) {
    return 'A subscriber took your seat on $day. You got back $amount EGP.';
  }

  @override
  String seatReclaimedCash(String day) {
    return 'A subscriber took your seat on $day. There was no fee on it, so there\'s nothing to refund.';
  }

  @override
  String get reclaimTooLate => 'Too late to reclaim — this booking is final.';

  @override
  String get oneOffTrips => 'One-off trips';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get noGroupYet => 'No daily group yet';

  @override
  String get demoAcceptRequest => 'A driver accepts your request';

  @override
  String get demoBookSeat => 'A rider books your seat';

  @override
  String get demoReclaim => 'A subscriber takes this seat';

  @override
  String get demoVerifyDriver => 'Verify my driver documents';

  @override
  String get nSeatBooked => 'A rider booked a seat on your trip.';

  @override
  String nRequestAccepted(String driver, String time) {
    return '$driver accepted your trip at $time.';
  }

  @override
  String get actSeatBooked => 'Seat';

  @override
  String get actSeatRefund => 'Refund';

  @override
  String get noSeatsOnRoute => 'No seats on your route right now';

  @override
  String get seatPayFailed =>
      'The payment didn\'t go through. Nothing was charged.';

  @override
  String get seatChosen => 'Your pick';

  @override
  String get cancelFreeNote =>
      'Cancel free until 9 PM the evening before. After that you pay half your share.';

  @override
  String get offerFromLabel => 'Leaving from';

  @override
  String get offerToLabel => 'Heading to';

  @override
  String get offerTimeLabel => 'Leaving at';

  @override
  String riderPaysLine(int amount) {
    return 'Riders pay $amount EGP';
  }

  @override
  String get dailyOfferNote =>
      'Once someone books, this becomes your daily commute group.';

  @override
  String get noRidersYet =>
      'No one has booked yet. Riders appear here as they book.';

  @override
  String get tripDepartedState => 'On the way. Rider names show now.';

  @override
  String get tripDoneState => 'Trip finished.';

  @override
  String get tripCancelledState =>
      'You cancelled this trip. Every rider got back everything they paid.';

  @override
  String get cancelTripConfirm =>
      'Cancel this trip? Every rider gets back everything they paid.';

  @override
  String get keepTrip => 'Keep the trip';

  @override
  String get demoNothingToDo => 'Nothing to do yet. Publish a trip first.';

  @override
  String get demoBookSeatFirst =>
      'Nothing to do yet. Book an empty seat first.';

  @override
  String get demoPostTripFirst => 'Nothing to do yet. Post your trip first.';

  @override
  String get seeAll => 'See all';

  @override
  String get acceptConfirm => 'Yes, accept';

  @override
  String get requestWithdrawn =>
      'You had an unpaid share when a driver accepted, so the request was withdrawn. Nothing was charged.';

  @override
  String get requestGone =>
      'That request is no longer open. Here\'s the updated list.';

  @override
  String get dailyBlockedNote =>
      'Every workday is off while you ride in a daily group.';

  @override
  String get findRidersLink => 'Or find riders who already posted';

  @override
  String priceInstapay(int price) {
    return 'Pay $price EGP to the driver by InstaPay';
  }

  @override
  String get payInstapaySub =>
      'Send it to the driver\'s InstaPay after the trip.';

  @override
  String owesDriver(int amount, String name) {
    return 'You owe $name $amount EGP';
  }

  @override
  String owesDriverBody(String name) {
    return '$name marked your share as not received. Pay $name first, then you can book again.';
  }

  @override
  String get iPaid => 'I paid';

  @override
  String iPaidSent(String name) {
    return 'We told $name you paid. Waiting for them to confirm.';
  }

  @override
  String shareDisputed(String name) {
    return '$name says they paid';
  }

  @override
  String get shareAutoReceived => 'Confirmed automatically';

  @override
  String get sharePending => 'Waiting for your answer';

  @override
  String get shareChange => 'Change';

  @override
  String get paymentsTitle => 'Payments from passengers';

  @override
  String get paymentsEmpty =>
      'No payments yet. After a trip, confirm what each passenger paid you.';

  @override
  String feeOwed(int amount) {
    return 'You owe Goora $amount EGP in fees';
  }

  @override
  String get instapayHandleLabel => 'Your InstaPay handle';

  @override
  String get instapayHandleHint =>
      'Passengers see it only after their booking is confirmed.';

  @override
  String get instapaySave => 'Save';

  @override
  String get instapaySaved => 'Saved';

  @override
  String instapayOfDriver(String name, String handle) {
    return '$name\'s InstaPay: $handle';
  }

  @override
  String get copyHandle => 'Copy';

  @override
  String get copiedHandle => 'Copied';

  @override
  String get cashOnly => 'Cash only';

  @override
  String get feeOwedBody =>
      'Pay it any time. At 150 EGP, or at month end from 30 EGP, it falls due.';

  @override
  String feeDueLine(String date) {
    return 'Due $date. Pay within 3 days to keep booking.';
  }

  @override
  String get feeOverdueBody =>
      'Pay it to book again. Trips you already booked still run.';

  @override
  String get payNow => 'Pay';

  @override
  String get settleTitle => 'Pay Goora fees';

  @override
  String settleConfirm(int amount) {
    return 'Pay $amount EGP';
  }

  @override
  String get settleFailTitle => 'The payment didn\'t go through';

  @override
  String get settleFailBody => 'Nothing was charged. Try again.';

  @override
  String get methodFawry => 'Fawry';

  @override
  String fawryCode(String code) {
    return 'Fawry code: $code';
  }

  @override
  String get fawryPaid => 'I paid at Fawry';

  @override
  String get bundleTitle => '20-trip bundle';

  @override
  String get bundleSub =>
      '75 EGP once. It never expires and covers Goora\'s fee, not the driver\'s share.';

  @override
  String bundleLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bundle trips left',
      one: '1 bundle trip left',
      zero: 'No bundle trips left',
    );
    return '$_temp0';
  }

  @override
  String get bundleBuy => 'Buy for 75 EGP';

  @override
  String get actSettlement => 'Fees paid';

  @override
  String get actBundle => 'Trip bundle';

  @override
  String get actBundleTrip => 'Bundle trip';

  @override
  String get idCheckTitle => 'Check your ID';

  @override
  String get idCheckSub =>
      'We need to check your ID before your first trip, for everyone\'s safety.';

  @override
  String get idFront => 'Photograph the front';

  @override
  String get idBack => 'Photograph the back';

  @override
  String get idCaptured => 'Captured';

  @override
  String get idSubmit => 'Send for checking';

  @override
  String get idPending =>
      'We\'re checking your ID. You can book as soon as it\'s confirmed.';

  @override
  String nCompanyPlanStarted(String company) {
    return 'Your $company plan is on: no Goora fee on your trips.';
  }

  @override
  String nCompanyPlanEnded(String company) {
    return 'Your $company plan has ended. The usual Goora fee applies to your trips.';
  }

  @override
  String get nCompanyPlanPaused =>
      'Your company plan is paused for now; the usual Goora fee applies to your trips.';

  @override
  String get nCompanyPlanResumed =>
      'Your company plan is back on: no Goora fee on your trips again.';

  @override
  String nPersonalPlanBack(int days) {
    return 'Your own plan is back, with $days days left.';
  }

  @override
  String get companyAccountTitle => 'Company account';

  @override
  String get companyAccountSub =>
      'Register your company if you\'re in HR, or see your company plan';

  @override
  String get companyRegisterCta => 'Register your company';

  @override
  String get companyRegisterIntro =>
      'In HR? Register your company so your employees ride with no Goora fee.';

  @override
  String get companyRegisterSub =>
      'We check your work email. The Goora team turns the account on once the contract is signed.';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get companyNameError => 'Use 2 to 60 characters';

  @override
  String get companyWorkEmailLabel => 'Your work email';

  @override
  String get companyEmailInvalid =>
      'Enter a valid email, like name@company.com';

  @override
  String companyPublicDomain(String domain) {
    return '$domain is a public email service anyone can sign up to. Use your work email.';
  }

  @override
  String companyDomainTaken(String domain) {
    return '$domain is already registered to another company on Goora.';
  }

  @override
  String get companySendCode => 'Send me a code';

  @override
  String companyCodeSent(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get companyCodeLabel => 'Code';

  @override
  String get companySubmit => 'Send the request';

  @override
  String get companyStatusPending => 'Waiting for Goora';

  @override
  String get companyStatusActive => 'Active';

  @override
  String get companyStatusSuspended => 'Paused until paid';

  @override
  String get companyStatusEnded => 'Contract ended';

  @override
  String companyPendingBody(String company) {
    return 'We got $company\'s request. We\'ll turn the account on once the contract is signed.';
  }

  @override
  String companyDomainsLine(String domains) {
    return 'Domain: $domains';
  }

  @override
  String companyMinSeats(int count) {
    return 'Billed for at least $count employees';
  }

  @override
  String companyPriceLine(int amount) {
    return '$amount EGP to Goora per employee a month';
  }

  @override
  String companyContractLine(String start, String end) {
    return 'Contract $start to $end';
  }

  @override
  String get companyHomeNote =>
      'The company never sees employees\' trips or pickup points.';

  @override
  String get companyMineTitle => 'Your company plan';

  @override
  String companyEnrolledLine(String company, String date) {
    return 'On $company\'s plan since $date';
  }

  @override
  String companyCanEnrollLine(String company) {
    return '$company pays Goora\'s fee for you on every trip.';
  }

  @override
  String companyJoinCta(String company) {
    return 'Join through $company';
  }

  @override
  String get companyNotOnGoora => 'Your company isn\'t on Goora yet';

  @override
  String get companyNotOnGooraBody =>
      'Tell your HR about Goora. Until they join, you can pay per trip or subscribe yourself.';

  @override
  String get companyTellHr => 'Tell your HR';

  @override
  String companyShareText(String link) {
    return 'Goora groups colleagues into one daily commute, and they share the cost. With its company plan, the company pays Goora\'s fee and employees ride with no fee. $link';
  }

  @override
  String consentTitle(String company) {
    return 'Before you join through $company';
  }

  @override
  String get consentSeesTitle => 'Your company will see';

  @override
  String get consentSeesName => 'Your name';

  @override
  String get consentSeesEmail => 'Your work email';

  @override
  String get consentSeesSince => 'Since when you joined';

  @override
  String get consentNeverTitle => 'It will never see';

  @override
  String get consentNeverTrips => 'Your trips or their times';

  @override
  String get consentNeverPlace => 'Your home or pickup point';

  @override
  String get consentNeverWho => 'Who rides with you';

  @override
  String get consentNeverMoney => 'Your money or what you paid the driver';

  @override
  String get consentFeeLine =>
      'Goora\'s fee on your trips becomes 0. You still pay the driver\'s share to the driver.';

  @override
  String consentPausedLine(int days) {
    return 'Your own plan ($days days left) pauses and comes back if you leave your company.';
  }

  @override
  String get consentAgree => 'Agree and join';

  @override
  String get consentDecline => 'Not now';

  @override
  String planCompanyOf(String company) {
    return 'Company · $company';
  }

  @override
  String planCompanyPaused(int days) {
    return 'Your own plan is paused: $days days left, back if you leave your company.';
  }

  @override
  String get companyLeave => 'Leave the company plan';

  @override
  String companyLeaveTitle(String company) {
    return 'Leave $company\'s plan?';
  }

  @override
  String get companyLeaveBody =>
      'From now on Goora\'s fee applies to your trips. Trips you already took don\'t change.';

  @override
  String get companyLeaveConfirm => 'Yes, leave';

  @override
  String get demoApproveCompany => 'Goora approves my company';

  @override
  String get demoMakeMeHr => 'Make me Valeo\'s HR contact';

  @override
  String get companyInvoicesCta => 'Invoices';

  @override
  String get companyInvoicesTitle => 'Company invoices';

  @override
  String get companyInvoicesEmpty =>
      'No invoices yet. The first one is issued at the start of next month.';

  @override
  String companyInvoiceMonthLabel(String month) {
    return 'Invoice $month';
  }

  @override
  String companyInvoiceMath(int seats, int price, String total) {
    return '$seats employees × $price EGP = $total EGP';
  }

  @override
  String companyInvoicePeak(int count) {
    return 'Most employees enrolled in the month: $count';
  }

  @override
  String get companyInvoicePaid => 'Paid';

  @override
  String get companyInvoiceWaiting => 'Waiting for payment';

  @override
  String get companyInvoiceOverdue => 'Overdue';

  @override
  String companyInvoiceDue(String date) {
    return 'Pay by $date';
  }

  @override
  String get companyInvoiceReferenceTitle => 'Write this on the transfer';

  @override
  String get companyInvoiceBankTitle => 'Goora\'s bank account';

  @override
  String companyInvoiceSuspendNote(String date) {
    return 'If this is still unpaid on $date, the company plan pauses until it is paid and Goora\'s fee applies to employees\' trips.';
  }

  @override
  String companyInvoicePaidOn(String date, String ref) {
    return 'Paid on $date · bank reference $ref';
  }

  @override
  String get demoMarkInvoicePaid => 'Goora marks the invoice paid';

  @override
  String get demoSkipToSuspension => 'Skip to the day the company plan pauses';

  @override
  String get companyRosterCta => 'Enrolled employees';

  @override
  String get companyRosterTitle => 'Enrolled employees';

  @override
  String companyRosterCount(int count) {
    return '$count enrolled now';
  }

  @override
  String get companyRosterNote =>
      'This is all the company sees: name, email and since when.';

  @override
  String companyRosterSince(String date) {
    return 'Since $date';
  }

  @override
  String companyRosterLeft(String date) {
    return 'Left on $date';
  }

  @override
  String get companyRosterEmpty =>
      'No employees enrolled yet. Tell your colleagues to join through the company in Goora.';

  @override
  String get companyRosterRemove => 'Remove';

  @override
  String companyRosterRemoveTitle(String name) {
    return 'Remove $name from the company plan?';
  }

  @override
  String get companyRosterRemoveBody =>
      'From now on Goora\'s fee applies to their trips; trips already taken don\'t change. They still count on this month\'s invoice.';

  @override
  String get companyRosterRemoveConfirm => 'Yes, remove';

  @override
  String get companyLogCta => 'Change log';

  @override
  String get companyLogTitle => 'Change log';

  @override
  String get companyLogEmpty => 'No changes yet.';

  @override
  String companyLogMeta(String actor, String date) {
    return '$actor · $date';
  }

  @override
  String get companyLogByHr => 'HR';

  @override
  String get companyLogByEmployee => 'Employee';

  @override
  String get companyLogByGoora => 'Goora';

  @override
  String get companyLogApproved => 'Account approved';

  @override
  String companyLogDomainAdded(String domain) {
    return 'Domain added: $domain';
  }

  @override
  String companyLogDomainRemoved(String domain) {
    return 'Domain removed: $domain';
  }

  @override
  String companyLogEmployeeRemoved(String name) {
    return 'Removed from the plan: $name';
  }

  @override
  String companyLogEmployeeLeft(String name) {
    return 'Left the plan: $name';
  }

  @override
  String companyLogInvoiceIssued(String month) {
    return 'Invoice issued: $month';
  }

  @override
  String companyLogInvoicePaid(String month) {
    return 'Invoice paid: $month';
  }

  @override
  String get companyLogSuspended => 'Plan paused until paid';

  @override
  String get companyLogResumed => 'Plan back on';

  @override
  String get companyLogContractEnded => 'Contract ended';

  @override
  String get companyLogHrChanged => 'HR contact changed';

  @override
  String get companyDomainsTitle => 'Domains';

  @override
  String get companyDomainsNote =>
      'Anyone whose work email is on these domains can join through the company.';

  @override
  String get companyAddDomain => 'Add a domain';

  @override
  String get companyDomainLabel => 'Domain';

  @override
  String get companyDomainInvalid => 'Enter a valid domain, like company.com';

  @override
  String get companyDomainAddCta => 'Add';

  @override
  String companyDomainRemove(String domain) {
    return 'Remove $domain';
  }

  @override
  String companyDomainRemoveTitle(String domain) {
    return 'Remove $domain?';
  }

  @override
  String companyDomainRemoveBody(String domain) {
    return 'Employees enrolled with a $domain email leave the plan now, and Goora\'s fee applies to their trips.';
  }

  @override
  String get demoEndContract => 'Goora ends Valeo\'s contract';

  @override
  String get demoHrLeft => 'Valeo\'s HR contact left the company';

  @override
  String get companyDashboardCta => 'Company numbers';

  @override
  String get companyDashboardTitle => 'Company numbers';

  @override
  String companyDashboardSoFar(String month) {
    return '$month (so far)';
  }

  @override
  String get companyDashboardNote =>
      'Totals only. No employee\'s name, trip or pickup point.';

  @override
  String get companyDashboardEmpty =>
      'Numbers appear once the account is active.';

  @override
  String get companyDashboardFewer => 'Fewer than 5';

  @override
  String get companyDashboardFewerNote =>
      'A figure from fewer than 5 employees is hidden, so no one can be picked out.';

  @override
  String get companyDashboardEnrolled => 'Employees enrolled';

  @override
  String get companyDashboardActive => 'Active employees this month';

  @override
  String get companyDashboardActiveMethod =>
      'Active means at least one trip as a passenger or driver.';

  @override
  String get companyDashboardCarpool => 'Carpool rate';

  @override
  String get companyDashboardCarpoolMethod => 'Active ÷ enrolled.';

  @override
  String get companyDashboardGroups => 'Commute groups with employees';

  @override
  String get companyDashboardTrips => 'Trips shared';

  @override
  String get companyDashboardTripsMethod =>
      'Each trip counts once, however many employees were in the car.';

  @override
  String get companyDashboardSaved => 'Estimated savings';

  @override
  String get companyDashboardSavedMethod =>
      'What driving alone would cost minus the seat share paid. An estimate.';

  @override
  String get companyDashboardCo2 => 'CO₂ avoided (estimate)';

  @override
  String get companyDashboardCo2Method =>
      'Kilometres × 0.1645 kg CO₂ per km, an average petrol car. An estimate, not a measurement.';

  @override
  String companyDashboardKg(String kg) {
    return '$kg kg';
  }

  @override
  String companyDashboardMoney(String amount) {
    return '$amount EGP';
  }

  @override
  String companyDashboardPercent(int pct) {
    return '$pct%';
  }

  @override
  String get companyDashboardParking => 'Parking spaces freed per workday';

  @override
  String get companyDashboardParkingMethod =>
      'Going trips as a passenger ÷ workdays (Sun–Thu). Assumes each passenger would otherwise drive alone.';

  @override
  String get companyDashboardGapsTitle => 'Areas with employees but no group';

  @override
  String companyDashboardGapRow(String area, int count) {
    return '$area · $count employees waiting';
  }

  @override
  String get companyDashboardGapsEmpty =>
      'No area has 5 or more employees waiting for a group.';

  @override
  String get companyHrShareTitle => 'Share my trips with HR';

  @override
  String get companyHrShareSees =>
      'Your company will see: your name, the date of each trip you rode as a passenger, going or return, and the share you paid the driver. It never sees the pickup point, the time or the driver.';

  @override
  String get companyHrShareOffLine =>
      'Off. Your company doesn\'t see your trips.';

  @override
  String get companyHrShareOnLine =>
      'On. Your company gets last month\'s statement on the 1st of each month.';

  @override
  String get companyHrShareStopTitle => 'Stop sharing your trips with HR?';

  @override
  String get companyHrShareStopBody =>
      'Statements your company already received stay as they are. The next one, and every one after, leaves your trips out.';

  @override
  String get companyHrShareStopConfirm => 'Yes, stop';

  @override
  String get companyStatementCta => 'Trips statement';

  @override
  String get companyStatementTitle => 'Monthly trips statement';

  @override
  String get companyStatementNote =>
      'Only employees who agreed to share their trips appear here. No one else is listed, not even a name.';

  @override
  String companyStatementFee(String amount) {
    return 'Goora\'s fee on these trips: $amount. Each share was paid straight to the driver.';
  }

  @override
  String companyStatementPerson(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0 · $amount EGP';
  }

  @override
  String companyStatementShare(String amount) {
    return '$amount EGP to the driver';
  }

  @override
  String companyStatementTotal(String amount) {
    return 'Total shares: $amount EGP';
  }

  @override
  String get companyStatementEmpty =>
      'No employee shared their trips for this month.';

  @override
  String get companyStatementNoMonths =>
      'The first statement appears once the first month has ended.';
}
