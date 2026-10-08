// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tagline => 'مشوارك.. سوا.';

  @override
  String get getStarted => 'يلا نبدأ';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get howTravel => 'بتتحرك إزاي؟';

  @override
  String get canDrive => 'معايا عربية';

  @override
  String get needRide => 'محتاج توصيلة';

  @override
  String get freqTitle => 'كل يوم ولا مشوار واحد؟';

  @override
  String get fRegular => 'كل يوم';

  @override
  String get fOnce => 'مشوار واحد بس';

  @override
  String get fTag => 'الأوفر';

  @override
  String get extraTrip => 'عايز مشوار زيادة؟ احجز كرسي';

  @override
  String get subNote => 'ضمن اشتراكك · من غير رسوم';

  @override
  String get whereGo => 'بتروح فين كل يوم؟';

  @override
  String get dirBoth => 'رايح جاي';

  @override
  String get dirGoing => 'رايح بس';

  @override
  String get dirRet => 'راجع بس';

  @override
  String get findCommute => 'دوّرلي على مشواري';

  @override
  String get foundGroup => 'لقينالك مجموعة مشوارك!';

  @override
  String get join => 'انضم للمجموعة';

  @override
  String get confirmed => 'توصيلتك متأكدة';

  @override
  String get covered => 'متغطّي';

  @override
  String get cantCome => 'مش هقدر آجي بكرة';

  @override
  String get arrivedBtn => 'وصلت البوابة الرئيسية';

  @override
  String get pickedUp => 'ركب';

  @override
  String get noShow => 'مجاش';

  @override
  String get planTitle => 'اشترك ومن غير رسوم';

  @override
  String get planSubline => 'من غير رسوم خدمة على أي مشوار أو كرسي.';

  @override
  String get planMonthlyTitle => 'شهري';

  @override
  String get planMonthlySub => '129 جنيه/الشهر';

  @override
  String get planYearlyTitle => 'سنوي';

  @override
  String get planYearlySub => '1,290 جنيه/السنة';

  @override
  String get planYearlyChip => 'شهرين مجانًا';

  @override
  String get planCompanyTitle => 'عن طريق شركتي';

  @override
  String get planCompanySub => 'مجاني — أكّد إيميل الشغل';

  @override
  String get planIncludedTitle => 'هتحصل على';

  @override
  String get planIncludedMatch => 'ترشيح يومي لجروب ركوبتك';

  @override
  String get planIncludedBackup => 'سواق بدّل لو سواقك اتأخر';

  @override
  String get planIncludedTrust => 'تتبّع الالتزام وأدوات أمان SOS';

  @override
  String get planFuelNote =>
      'مصاريف البنزين والرسوم اللي تدفعها كل رحلة تروح كلها للسواق.';

  @override
  String get planCtaVerify => 'أكّد إيميل الشغل';

  @override
  String get planFooter => 'تقدر تلغي في أي وقت. جورة مجانية للسواقين.';

  @override
  String get verifyEmailTitle => 'أكّد إيميل شغلك';

  @override
  String verifyEmailBody(String company) {
    return '$company هتدفع خطة جورة بتاعتك بعد تأكيد إيميل شغلك.';
  }

  @override
  String get verifyConfirm => 'تأكيد';

  @override
  String get verifyNotVerified => 'أكّد إيميل شغلك من تبويب الموثوقية الأول.';

  @override
  String get balanceLabel => 'رصيد المحفظة';

  @override
  String get topUp => 'اشحن';

  @override
  String coversTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بيغطي حوالي $count رحلات',
      one: 'بيغطي حوالي رحلة واحدة',
      zero: 'لسه مش بيغطي أي رحلة',
    );
    return '$_temp0';
  }

  @override
  String get planChange => 'تغيير';

  @override
  String get planCompanyActive => 'مجانية · شركتك بتدفعها';

  @override
  String get howPayTitle => 'إزاي الدفع بيشتغل';

  @override
  String get howPayRule1 =>
      'بتدفع نصيب السواق + رسوم خدمة لحد 10% على كل مشوار. المشتركين من غير رسوم.';

  @override
  String get howPayRule2 =>
      'البنزين والرسوم بتروح كلها للسواق على طول — جورة مالهاش نسبة.';

  @override
  String get howPayRule3 =>
      'الإلغاء المتأخر والغياب بيروحوا للسواق من غير رسوم خدمة.';

  @override
  String get topUpSheetTitle => 'اشحن محفظتك';

  @override
  String get topUpMethodInstaPay => 'InstaPay';

  @override
  String get topUpMethodVodafone => 'فودافون كاش';

  @override
  String get topUpMethodCard => 'كارت';

  @override
  String get topUpConfirm => 'أكّد الشحن';

  @override
  String get topUpFailTitle => 'الشحن ملحقش يتم';

  @override
  String get topUpFailBody => 'مفيش حاجة اتحصلت — جرّب تاني.';

  @override
  String get changePlanTitle => 'غيّر خطتك';

  @override
  String get changePlanNote =>
      'الخطة الجديدة تتفعل من تاريخ الفوترة الجاي — مفيش تغيير في الفترة الحالية.';

  @override
  String get changePlanConfirm => 'أكّد التغيير';

  @override
  String get breakdownTitle => 'بتدفع كام في الرحلة';

  @override
  String get breakdownFuel => 'البنزين والرسوم';

  @override
  String get breakdownTotal => 'الإجمالي';

  @override
  String get activityTitle => 'الحركة';

  @override
  String get activityEmpty => 'لسه مفيش حركة';

  @override
  String get actTopUp => 'شحن';

  @override
  String get actTripDeduction => 'تكلفة رحلة';

  @override
  String get actLateCancelCharge => 'إلغاء متأخر';

  @override
  String get actFreeCancelZero => 'إلغاء مجاني';

  @override
  String get actTripIncome => 'دخل الرحلة';

  @override
  String actFeeReceivedFrom(String name) {
    return 'رسوم $name';
  }

  @override
  String get actWithdrawal => 'سحب';

  @override
  String get recoveredTitle => 'اتجمّع الأسبوع ده';

  @override
  String get payoutNote => 'بيتصرف كل خميس · من غير أي رسوم عليك';

  @override
  String get withdraw => 'اسحب على InstaPay';

  @override
  String get withdrawSheetTitle => 'اسحب على InstaPay';

  @override
  String get withdrawConfirm => 'أكّد السحب';

  @override
  String get withdrawFailTitle => 'السحب ملحقش يتم';

  @override
  String get withdrawFailBody => 'مفيش حاجة تحرّكت — جرّب تاني.';

  @override
  String get driverBreakdownTitle => 'تكلفة رحلتك';

  @override
  String get driverBreakdownCost => 'تكلفة الرحلة';

  @override
  String get driverBreakdownReceived => 'بتستلم من الركاب';

  @override
  String get driverBreakdownGap => 'بتدفعه من جيبك';

  @override
  String get driverBreakdownFree => 'جورة مجانية للسواقين';

  @override
  String get postReq => 'انشر مشوارك';

  @override
  String get offerBtn => 'اعرض مشوار';

  @override
  String get reqsOnRoute => 'طلبات على خطك';

  @override
  String get browseBtn => 'دوّر على ركاب';

  @override
  String get browseTitle => 'طلبات قريبة منك';

  @override
  String get tripsLeftA => 'المشاوير الباقية النهارده';

  @override
  String get tabToday => 'النهارده';

  @override
  String get tabWeek => 'الأسبوع';

  @override
  String get tabWallet => 'المحفظة';

  @override
  String get tabTrust => 'الأمان';

  @override
  String get sos => 'استغاثة';

  @override
  String get langBtn => 'English';

  @override
  String get langAria => 'Switch to English';

  @override
  String get back => 'رجوع';

  @override
  String get continueBtn => 'كمّل';

  @override
  String get taglineOther => 'Go together. Every day.';

  @override
  String get splashSub =>
      'مشوارك اليومي متنظّم مع ناس رايحة نفس سكتك. من غير ما تدوّر كل يوم الصبح.';

  @override
  String get switchAnytime => 'تقدر تغيّر في أي وقت.';

  @override
  String get canDriveSub => 'عندي كراسي فاضية وعايز أشارك التكلفة';

  @override
  String get needRideSub => 'بدوّر على حد رايح نفس مكاني';

  @override
  String get freqSub => 'تقدر تعمل التاني في أي وقت بعدين.';

  @override
  String get fRegRider => 'مجموعة ثابتة لمشوارك اليومي. أول شهر مجاني.';

  @override
  String get fOnceRider => 'احجز كرسي فاضي أو انشر مشوارك. من غير اشتراك.';

  @override
  String get fRegDriver => 'شارك مشوارك اليومي مع مجموعة ثابتة. مجاني دايمًا.';

  @override
  String get fOnceDriver => 'اعرض كراسيك الفاضية في مشوار إنت رايحه أصلًا.';

  @override
  String get toDriver => 'حوّل لوضع السواق';

  @override
  String get toRider => 'حوّل لوضع الراكب';

  @override
  String get emptySeatsTitle => 'كراسي فاضية النهارده';

  @override
  String get offerTitle => 'اعرض مشوار';

  @override
  String get backupTitle => 'أحمد مش هيقدر يسوق يوم التلات';

  @override
  String get backupBody =>
      'محمد هيسوق بداله. مشوارك متغطّي، ومش محتاج تعمل حاجة.';

  @override
  String get gotIt => 'تمام';

  @override
  String get pickupIn => 'التجمع بعد 12 دقيقة';

  @override
  String get verifiedMember => 'عضو موثّق · 4.9 ★';

  @override
  String get phoneTitle => 'رقم موبايلك إيه؟';

  @override
  String get phoneSub => 'هنبعتلك كود في رسالة عشان نتأكد إنه رقمك.';

  @override
  String get phoneLabel => 'رقم الموبايل';

  @override
  String get phoneHint => 'رقم موبايل مصري: 11 رقم بيبدأ بـ 01';

  @override
  String get sendCode => 'ابعتلي الكود';

  @override
  String get otpTitle => 'اكتب الكود';

  @override
  String get otpWrong => 'الكود ده مش مظبوط. جرّب تاني.';

  @override
  String get otpResend => 'ابعت كود جديد';

  @override
  String get otpDevHint => 'كود التجربة: 123456';

  @override
  String get changeNumber => 'غيّر الرقم';

  @override
  String get networkError =>
      'مقدرناش نبعت الكود دلوقتي. اتأكد من النت وجرّب تاني.';

  @override
  String get retry => 'جرّب تاني';

  @override
  String get profileTitle => 'نتعرّف عليك';

  @override
  String get profileSub => 'عشان مجموعتك تعرف هتركب مع مين.';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العيلة';

  @override
  String get genderLabel => 'النوع';

  @override
  String get male => 'راجل';

  @override
  String get female => 'ست';

  @override
  String get genderNote => 'بنستخدمه بس لاختيار «سيدات فقط»، ومحدش بيشوفه.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get roleLabel => 'بتتحرك إزاي';

  @override
  String get comingSoonTitle => 'الشاشة دي جاية قريب';

  @override
  String get comingSoonBody => 'بنجهّزها دلوقتي. اختيارك اتحفظ.';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get galleryTitle => 'معرض التصميم';

  @override
  String get galleryColors => 'الألوان';

  @override
  String get galleryType => 'الخطوط';

  @override
  String get galleryShape => 'الأشكال والمسافات';

  @override
  String get galleryButtons => 'الأزرار';

  @override
  String get galleryCards => 'الكروت';

  @override
  String get gallerySelection => 'الاختيار';

  @override
  String get galleryFeedback => 'التنبيهات';

  @override
  String get galleryPeople => 'الناس';

  @override
  String get galleryNav => 'التنقّل';

  @override
  String get galleryDecrease => 'قلّل';

  @override
  String get galleryIncrease => 'زوّد';

  @override
  String otpSub(String phone) {
    return 'بعتناه على $phone';
  }

  @override
  String otpResendIn(int seconds) {
    return 'تقدر تطلب كود جديد بعد $seconds ثانية';
  }

  @override
  String stepperValue(String value) {
    return '$value ج';
  }

  @override
  String get navMain => 'القائمة الرئيسية';

  @override
  String stepOf(int current, int total) {
    return 'خطوة $current من $total';
  }

  @override
  String get home => 'البيت';

  @override
  String get work => 'الشغل / الجامعة';

  @override
  String get areaSheikhZayed => 'الشيخ زايد';

  @override
  String get areaOctober => '6 أكتوبر';

  @override
  String get areaSmartVillage => 'القرية الذكية';

  @override
  String get pickHome => 'البيت فين؟';

  @override
  String get pickWork => 'الشغل فين؟';

  @override
  String get choosePlace => 'اختار المكان';

  @override
  String get whenTravel => 'بتتحرك إمتى؟';

  @override
  String get departure => 'الذهاب';

  @override
  String get returnT => 'الرجوع';

  @override
  String get workingDays => 'أيام الشغل';

  @override
  String get daySun => 'حد';

  @override
  String get dayMon => 'اتنين';

  @override
  String get dayTue => 'تلات';

  @override
  String get dayWed => 'أربع';

  @override
  String get dayThu => 'خميس';

  @override
  String get dayFri => 'جمعة';

  @override
  String get daySat => 'سبت';

  @override
  String get sunThu => 'الحد – الخميس';

  @override
  String get seatsQ => 'الكراسي الفاضية في عربيتك';

  @override
  String get fewerSeats => 'كرسي أقل';

  @override
  String get moreSeats => 'كرسي زيادة';

  @override
  String get whichTrips => 'هتسوق في أنهي مشوار؟';

  @override
  String get otherTripNote =>
      'الركاب بياخدوا المشوار التاني مع سواق تاني في المجموعة.';

  @override
  String get contribTitle => 'مساهمة كل راكب';

  @override
  String get lowerContribution => 'قلّل المساهمة';

  @override
  String get raiseContribution => 'زوّد المساهمة';

  @override
  String get suggestedPrice => 'السعر المقترح';

  @override
  String get contribNote =>
      'محسوبة على المسافة والبنزين والكارتة. الراكب بيشوفها قبل ما ينضم، وبتفضل ثابتة طول الشهر.';

  @override
  String get recoverDay => 'بتسترد في اليوم';

  @override
  String get earlier => 'أبدري 5 دقايق';

  @override
  String get later => 'أتأخر 5 دقايق';

  @override
  String get sameAreaHint => 'اختار مكان شغل أبعد من 1.5 كم عن البيت.';

  @override
  String get returnHint => 'ميعاد الرجوع لازم يكون بعد الذهاب.';

  @override
  String get noDaysHint => 'اختار يوم واحد على الأقل.';

  @override
  String get mapAria => 'خريطة المشوار';

  @override
  String get foundSub => 'ناس رايحة نفس سكتك، في نفس ميعادك.';

  @override
  String get statDrivers => 'سواقين';

  @override
  String get statRiders => 'ركاب';

  @override
  String get statFixed => 'ثابت';

  @override
  String get egpTrip => 'ج/مشوار';

  @override
  String get whyGroup => 'ليه المجموعة دي';

  @override
  String get otherMatches => 'ترشيحات تانية';

  @override
  String get chooseThisGroup => 'اختار المجموعة دي';

  @override
  String get seeOthers => 'شوف اختيارات تانية';

  @override
  String get hideOthers => 'اخفي الاختيارات التانية';

  @override
  String get reasonSameDeparture => 'نفس ميعاد الخروج';

  @override
  String get reasonCompanyReturn => 'نفس الشركة · ميعاد رجوع قريب';

  @override
  String get reasonCompany => 'نفس الشركة';

  @override
  String get reasonCompound => 'نفس الكمبوند';

  @override
  String get reasonReturn => 'ميعاد رجوع قريب';

  @override
  String get verifiedRider => 'راكب موثّق';

  @override
  String get verifiedRiderWoman => 'راكبة موثّقة';

  @override
  String egpAmount(int amount) {
    return '$amount ج';
  }

  @override
  String aboveSuggested(int amount) {
    return '$amount ج أعلى من المقترح';
  }

  @override
  String belowSuggested(int amount) {
    return '$amount ج أقل من المقترح';
  }

  @override
  String suggestedShort(int amount) {
    return 'المقترح $amount';
  }

  @override
  String timeAm(String time) {
    return '$time ص';
  }

  @override
  String timePm(String time) {
    return '$time م';
  }

  @override
  String matchPercent(int percent) {
    return 'توافق $percent%';
  }

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      few: '$count أعضاء',
      two: 'عضوين',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String perWeek(int count) {
    return '$count/أسبوع';
  }

  @override
  String reasonDestination(String area) {
    return 'نفس المكان: $area';
  }

  @override
  String reasonDeparture(int minutes) {
    return 'فرق $minutes دقايق في ميعاد الخروج';
  }

  @override
  String reasonPickup(int meters) {
    return 'نقطة التجمع على بعد $meters متر';
  }

  @override
  String reasonDays(int count) {
    return '$count أيام شغل مشتركة';
  }

  @override
  String reasonRating(String rating) {
    return 'الأعضاء متقيّمين $rating ★';
  }

  @override
  String otherMeta(String time, int meters) {
    return '$time · $meters م';
  }

  @override
  String returnLeg(String time) {
    return 'الرجوع مع مجموعة $time';
  }

  @override
  String noMatch(int position, String from, String to) {
    return 'إنت رقم $position على قايمة $from ← $to — هنبلّغك أول ما نلاقيلك مجموعة';
  }

  @override
  String routeLine(String from, String to) {
    return '$from ← $to';
  }

  @override
  String timeDays(String time, String days) {
    return '$time · $days';
  }

  @override
  String goodMorning(String name) {
    return 'صباح الخير يا $name';
  }

  @override
  String goodEvening(String name) {
    return 'مساء الخير يا $name';
  }

  @override
  String get todaySub => 'ده مشوارك النهارده.';

  @override
  String nextRide(String day) {
    return 'مشوارك الجاي · $day';
  }

  @override
  String get relToday => 'النهارده';

  @override
  String get relTomorrow => 'بكرة';

  @override
  String relTomorrowDay(String day) {
    return 'بكرة ($day)';
  }

  @override
  String relOn(String day) {
    return 'يوم $day';
  }

  @override
  String get heroToday => 'النهارده';

  @override
  String get heroTomorrow => 'بكرة';

  @override
  String get legGoing => 'الذهاب';

  @override
  String get legReturn => 'الرجوع';

  @override
  String legRow(String leg, String driver, String time) {
    return '$leg: $driver · $time';
  }

  @override
  String get youWord => 'إنت';

  @override
  String get noDriverYet => 'لسه مفيش سواق';

  @override
  String get legsNote =>
      'الذهاب والرجوع مشوارين منفصلين، وممكن كل واحد يبقى بسواق.';

  @override
  String goingLeg(String time) {
    return 'الذهاب مع مجموعة $time';
  }

  @override
  String pickupInMin(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقايق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return 'التجمع بعد $_temp0';
  }

  @override
  String get callDriver => 'كلّم السواق';

  @override
  String callName(String name) {
    return 'كلّم $name';
  }

  @override
  String get verified => 'موثّق';

  @override
  String get notVerified => 'مش موثّق';

  @override
  String carLine(String car, String colour, String rating) {
    return '$car · $colour · $rating ★';
  }

  @override
  String get colourWhite => 'أبيض';

  @override
  String get colourSilver => 'فضي';

  @override
  String get colourBlack => 'أسود';

  @override
  String get colourGrey => 'رمادي';

  @override
  String get colourRed => 'أحمر';

  @override
  String get colourBlue => 'أزرق';

  @override
  String get stopMainGate => 'البوابة الرئيسية';

  @override
  String get stopCentralSt => 'الشارع الرئيسي';

  @override
  String get stopGasStation => 'بنزينة 26 يوليو';

  @override
  String get stopSmartVillageGate2 => 'القرية الذكية، بوابة 2';

  @override
  String tlPickup(String time) {
    return 'التجمع · $time';
  }

  @override
  String get tlOnTheWay => 'في الطريق';

  @override
  String tlPassengers(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count راكب',
      few: '$count ركاب',
      two: 'راكبين',
      one: 'راكب واحد',
    );
    return '$_temp0 · $names';
  }

  @override
  String tlArrival(String time) {
    return 'الوصول · $time';
  }

  @override
  String get listSep => '، ';

  @override
  String get returnTime => 'ميعاد الرجوع';

  @override
  String get noReturnTrip => 'مفيش رجوع';

  @override
  String get payPerTrip => 'بتدفع في المشوار';

  @override
  String get shareTrip => 'شارك المشوار';

  @override
  String get cantComeNote => 'مجاني قبل 9 بالليل · بعدها تدفع نص مساهمتك';

  @override
  String offTitle(String when) {
    return 'إنت مش جاي $when';
  }

  @override
  String offLegTitle(String trip, String when) {
    return 'مش جاي في $trip $when';
  }

  @override
  String get tripGoing => 'رحلة الذهاب';

  @override
  String get tripReturn => 'رحلة الرجوع';

  @override
  String get offBody =>
      'اعتذرت قبل 9 بالليل، فمفيش أي رسوم. كرسيك اتعرض على قائمة الانتظار.';

  @override
  String lateOffBody(int amount) {
    return 'اعتذرت بعد 9 بالليل — $amount ج للسواق.';
  }

  @override
  String get undo => 'لأ، أنا جاي';

  @override
  String get undoRefused =>
      'الكرسي اتاخد من قايمة الانتظار، فمش هينفع نرجّعه. ممكن تحجز كرسي فاضي لو محتاج.';

  @override
  String get undoTooLate => 'عدّى ميعاد التجمع، فمش هينفع نرجّع الإلغاء.';

  @override
  String get cantComeTitle => 'إيه المشاوير اللي مش هتلحقها؟';

  @override
  String legAt(String leg, String time) {
    return '$leg · $time';
  }

  @override
  String get freeCancelPreview => 'قبل 9 بالليل: من غير فلوس';

  @override
  String lateCancelPreview(int amount) {
    return 'بعد 9 بالليل: هتدفع $amount ج للسواق';
  }

  @override
  String get confirmCancel => 'أكّد الإلغاء';

  @override
  String get pickOneTrip => 'اختار مشوار واحد على الأقل';

  @override
  String get cancelAfterPickup =>
      'عدّى ميعاد التجمع. لو مجتش، السواق هيسجّلك غياب.';

  @override
  String get notNextWeek => 'مش جاي الأسبوع الجاي';

  @override
  String get notNextWeekConfirm =>
      'هنعلّم كل أيام الأسبوع الجاي إجازة. الأيام اللي لسه قبل 9 بالليل من غير فلوس.';

  @override
  String get notNextWeekDone => 'تمام، علّمنا الأسبوع الجاي إجازة.';

  @override
  String get keepIt => 'لأ، سيبه';

  @override
  String get headsUp => 'خلي بالك';

  @override
  String get noShowWarning =>
      'مجتش مرتين الشهر ده. المرة التالتة هتخرجك من المجموعة.';

  @override
  String get removedTitle => 'مبقتش في المجموعة';

  @override
  String get removedNotice =>
      'خرجناك من المجموعة عشان مجتش 3 مرات الشهر ده. مشوارك متسجّل، ونقدر ندوّرلك على مجموعة جديدة.';

  @override
  String get findNewGroup => 'دوّرلي على مجموعة جديدة';

  @override
  String drivingWhen(String when) {
    return 'إنت اللي هتسوق $when.';
  }

  @override
  String get notDrivingSoon => 'مفيش سواقة عليك الأيام الجاية.';

  @override
  String heroDriver(String when, String direction, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count راكب',
      few: '$count ركاب',
      two: 'راكبين',
      one: 'راكب واحد',
      zero: 'مفيش ركاب',
    );
    return '$when · $direction · $_temp0';
  }

  @override
  String pickupN(int n, String stop) {
    return 'تجمع $n — $stop';
  }

  @override
  String returnFrom(String place) {
    return 'الرجوع من $place';
  }

  @override
  String get estContrib => 'المساهمة المتوقعة';

  @override
  String get confirmDrive => 'أكّد مشوار بكرة';

  @override
  String get confirmDriveToday => 'أكّد مشوار النهارده';

  @override
  String confirmDriveDay(String day) {
    return 'أكّد مشوار يوم $day';
  }

  @override
  String get confirmedNote => 'اتأكد. الركاب وصلهم إشعار.';

  @override
  String get undoConfirm => 'إلغاء التأكيد';

  @override
  String get reportDelay => 'هتأخر';

  @override
  String get cantDrive => 'مش هقدر أسوق';

  @override
  String get cantDriveConfirm => 'متأكد؟ هندوّر على سواق بديل لركابك.';

  @override
  String get cantDriveYes => 'أيوه، مش هقدر';

  @override
  String get keepDriving => 'لأ، هسوق';

  @override
  String cantDriveDone(String when) {
    return 'قلنا للمجموعة إنك مش هتسوق $when. بندوّر على سواق بديل.';
  }

  @override
  String get delayTitle => 'هتتأخر قد إيه؟';

  @override
  String delayMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقايق',
    );
    return '$_temp0';
  }

  @override
  String delaySent(String time) {
    return 'بلّغنا الركاب بالميعاد الجديد: $time';
  }

  @override
  String get reqPrivacy =>
      'الطلبات بتظهرلك بس لو لفّتك أقل من 10 دقايق. والسعر ثابت من Goora.';

  @override
  String get reqsPlaceholder => 'طلبات الركاب اللي على خطك هتظهر هنا.';

  @override
  String rideWith(String day, String driver) {
    return 'راكب $day مع $driver';
  }

  @override
  String get checkin => 'تسجيل الوصول';

  @override
  String arrivedAt(String stop) {
    return 'وصلت $stop';
  }

  @override
  String get arrivedNote => 'الركاب هيوصلهم إشعار. هتستنى 5 دقايق بالكتير.';

  @override
  String stWaiting(String time) {
    return 'وصله إشعار · مستنيين $time';
  }

  @override
  String get stNotArrived => 'لسه موصلتش';

  @override
  String get stNoShow => 'مجاش · اتحسبت مساهمته كاملة';

  @override
  String noShowAvailableIn(String time) {
    return 'متاح بعد $time';
  }

  @override
  String get noShowNote => 'لو الراكب مجاش بعد 5 دقايق، بيدفع مساهمته كاملة.';

  @override
  String ratingStars(String rating) {
    return '$rating ★';
  }

  @override
  String get startTrip => 'يلا نتحرك';

  @override
  String get endTrip => 'وصلنا';

  @override
  String get tripOnWay => 'المشوار بدأ. سوق بالراحة.';

  @override
  String get tripEndedNote => 'المشوار خلص. شكرًا!';

  @override
  String get refusedNoShowEarly => 'استنى لحد ما الـ 5 دقايق يخلصوا.';

  @override
  String get refusedTripStarted => 'المشوار بدأ، فمش هينفع تغيّر.';

  @override
  String get inboxTitle => 'الإشعارات';

  @override
  String get inboxEmpty => 'مفيش إشعارات لسه';

  @override
  String get inboxEmptyBody => 'هنبلغك هنا بأي تغيير في مشاويرك.';

  @override
  String inboxAria(int count) {
    return 'الإشعارات، $count مش مقروءة';
  }

  @override
  String get sentToRiders => 'اتبعت لركابك';

  @override
  String nDriverConfirmed(String day) {
    return 'السواق أكّد مشوار $day.';
  }

  @override
  String nDriverUnconfirmed(String day) {
    return 'السواق لغى تأكيد مشوار $day.';
  }

  @override
  String nDelay(int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقايق',
    );
    return 'السواق هيتأخر $_temp0. الميعاد الجديد $time.';
  }

  @override
  String nDriverArrived(String stop) {
    return 'السواق وصل $stop. تعالى في خلال 5 دقايق.';
  }

  @override
  String nLateCancel(String day, int amount) {
    return 'إلغاء متأخر يوم $day: $amount ج للسواق.';
  }

  @override
  String nNoShow(String day, int amount) {
    return 'غياب يوم $day: $amount ج للسواق.';
  }

  @override
  String nSeatOffered(String day) {
    return 'كرسيك يوم $day اتعرض على قائمة الانتظار.';
  }

  @override
  String backupTitleFor(String driver, String day) {
    return '$driver مش هيقدر يسوق يوم $day';
  }

  @override
  String backupBodyFor(String cover) {
    return '$cover هيسوق بداله. مشوارك متغطّي، ومش محتاج تعمل حاجة.';
  }

  @override
  String noCoverTitle(String when) {
    return 'مفيش سواق $when';
  }

  @override
  String noCoverBody(String driver) {
    return '$driver مش هيقدر يسوق، وملقيناش بديل. اختار اللي يناسبك:';
  }

  @override
  String get noCoverDayOff => 'خد اليوم إجازة — من غير فلوس';

  @override
  String get sosTitle => 'محتاج مساعدة؟';

  @override
  String get sosCall => 'اتصل بـ 122';

  @override
  String get sosAlert => 'بلّغ الناس اللي بثق فيهم';

  @override
  String get sosAlertSent => 'بعتنالهم لينك المشوار';

  @override
  String get sosNoContacts => 'ضيف حد بتثق فيه عشان نبلّغه وقت الطوارئ';

  @override
  String get trustedTitle => 'ناس بثق فيهم';

  @override
  String get trustedAdd => 'ضيف حد';

  @override
  String get trustedMax => 'ممكن تضيف لحد 3';

  @override
  String shareMessage(
    String driver,
    String car,
    String from,
    String to,
    String time,
    String link,
  ) {
    return 'أنا في مشواري مع $driver ($car) من $from لـ $to، هوصل حوالي $time. تابعني: $link';
  }

  @override
  String get scheduleTitle => 'جدول مشاويرك';

  @override
  String get rotateNote =>
      'Goora بيوزّع السواقة بالعدل، ولو حد اعتذر بيسد مكانه تلقائي.';

  @override
  String drivesName(String name) {
    return '$name بيسوق';
  }

  @override
  String get youDrive => 'إنت بتسوق';

  @override
  String get youRide => 'إنت راكب';

  @override
  String get youOff => 'إنت مش جاي';

  @override
  String get offNote => 'اعتذرت قبل 9 بالليل · من غير رسوم';

  @override
  String lateOffNote(int amount) {
    return 'اعتذرت بعد 9 بالليل · $amount ج للسواق';
  }

  @override
  String backupName(String name) {
    return '$name (بديل)';
  }

  @override
  String verifiedMemberRating(String rating) {
    return 'عضو موثّق · $rating ★';
  }

  @override
  String get reliability => 'الالتزام';

  @override
  String relLateCancels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إلغاء متأخر الشهر ده.',
      few: '$count إلغاءات متأخرة الشهر ده.',
      two: 'إلغاءين متأخرين الشهر ده.',
      one: 'إلغاء متأخر واحد الشهر ده.',
    );
    return '$_temp0';
  }

  @override
  String relNoShows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة غياب الشهر ده.',
      few: '$count مرات غياب الشهر ده.',
      two: 'غيابين الشهر ده.',
      one: 'غياب واحد الشهر ده.',
    );
    return '$_temp0';
  }

  @override
  String get relRule => '3 مرات غياب في الشهر بتخرّجك من المجموعة.';

  @override
  String get whoRide => 'مين يركب معايا';

  @override
  String get checkPhone => 'رقم الموبايل';

  @override
  String get checkNationalId => 'البطاقة';

  @override
  String get checkWorkEmail => 'إيميل الشغل';

  @override
  String get checkLicense => 'رخصة السواقة';

  @override
  String get checkVehicle => 'العربية';

  @override
  String get notNeeded => 'مش مطلوب';

  @override
  String get privacyVerified => 'الموثّقين بس';

  @override
  String get privacyCompany => 'نفس الشركة';

  @override
  String get privacyCompound => 'نفس الكمبوند';

  @override
  String get privacyWomen => 'سيدات فقط';

  @override
  String get privacyNote =>
      'الاختيار ده هيتطبّق على المجموعات الجاية، مش مجموعتك الحالية.';

  @override
  String get needWorkEmail => 'وثّق إيميل الشغل الأول';

  @override
  String get needCompound => 'ضيف اسم الكمبوند الأول';

  @override
  String get driverNeedsDocs =>
      'عشان تسوق، لازم الرخصة والعربية يكونوا موثّقين.';

  @override
  String get demoSection => 'تجربة (للمطورين)';

  @override
  String demoNow(String time) {
    return 'الوقت دلوقتي: $time';
  }

  @override
  String get demoRideDay => 'يوم مشوار · 7:15 ص';

  @override
  String get demo855 => 'قبل 9 بالليل · 8:55 م';

  @override
  String get demo905 => 'بعد 9 بالليل · 9:05 م';

  @override
  String get demoRealTime => 'الوقت الحقيقي';

  @override
  String get demoReset => 'امسح بيانات التجربة';

  @override
  String get noRidesSoon => 'مفيش مشاوير الأيام الجاية.';

  @override
  String get loadingToday => 'بنجهّز مشوارك…';

  @override
  String get todayError => 'معرفناش نجيب مشوارك دلوقتي.';

  @override
  String nDriverNoShow(String day) {
    return 'مسجّلتش وصولك لمشوار يوم $day، فاتحسب إنك مجتش.';
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
  String get noCoverEmptySeat => 'احجز كرسي فاضي';

  @override
  String get offNoCoverBody => 'مفيش سواق اليوم ده، فمن غير رسوم.';

  @override
  String get noCoverNote => 'مفيش سواق · من غير رسوم';

  @override
  String get demoBackup => 'السواق مش هيقدر يسوق الثلاثاء الجاي';

  @override
  String get demoNoCover => 'السواق مش هيقدر يسوق — من غير بديل';

  @override
  String weekRiderLine(String going, String ret) {
    return 'الذهاب: $going · الرجوع: $ret';
  }

  @override
  String weekDriveLine(String direction, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count راكب',
      few: '$count ركاب',
      two: 'راكبين',
      one: 'راكب واحد',
      zero: 'مفيش ركاب',
    );
    return '$direction · $_temp0';
  }

  @override
  String get weekEmpty => 'مفيش أيام مشاوير الأسبوع ده.';

  @override
  String get verificationTitle => 'التوثيق';

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String trustedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص',
      few: '$count أشخاص',
      two: 'شخصين',
      one: 'شخص واحد',
      zero: 'لسه مفيش حد',
    );
    return '$_temp0';
  }

  @override
  String get contactName => 'الاسم';

  @override
  String removeContact(String name) {
    return 'شيل $name';
  }

  @override
  String arrivalInMin(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقايق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return 'الوصول بعد $_temp0';
  }

  @override
  String get mapLiveAria => 'خريطة المشوار · السواق في الطريق';

  @override
  String get demoDriverArrives => 'السواق وصل محطتي';

  @override
  String get shareNoTrip => 'مفيش مشوار تشاركه دلوقتي.';

  @override
  String priceWithFee(int price, int fee) {
    return '$price ج للسواق + $fee ج رسوم خدمة';
  }

  @override
  String priceNoFee(int price) {
    return '$price ج للسواق · من غير رسوم خدمة';
  }

  @override
  String priceSubscribed(int price) {
    return '$price ج · من غير رسوم (مشترك)';
  }

  @override
  String priceCompany(int price) {
    return '$price ج · من غير رسوم (الشركة)';
  }

  @override
  String priceCash(int price) {
    return 'ادفع $price ج كاش للسواق';
  }

  @override
  String get payMethodTitle => 'هتدفع إزاي؟';

  @override
  String get payMethodSub => 'تقدر تشحن المحفظة أو تشترك في أي وقت.';

  @override
  String get payCash => 'ادفع كاش للسواق (أول 10 مشاوير)';

  @override
  String get payCashSub => 'من غير رسوم خدمة على مشاوير الكاش.';

  @override
  String get payWallet => 'ادفع من المحفظة';

  @override
  String get subscribeLink => 'اشترك ومن غير رسوم';

  @override
  String subscribeCta(int price) {
    return 'اشترك · $price ج';
  }

  @override
  String subNeedsTopUp(int gap, int balance) {
    return 'اشحن $gap ج الأول — محفظتك فيها $balance ج.';
  }

  @override
  String get subscribe => 'اشترك';

  @override
  String get planPayPerTrip => 'بالمشوار';

  @override
  String planPerTripLine(int fee) {
    return '$fee ج رسوم خدمة على كل مشوار';
  }

  @override
  String get planPerTripNoFeeLine => 'من غير رسوم خدمة على مشاويرك';

  @override
  String planSubscribedLine(String date) {
    return 'مشترك لحد $date · من غير رسوم';
  }

  @override
  String get planLapsedLine => 'الاشتراك خلص · رجعت بالمشوار';

  @override
  String cashTripsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فاضل $count مشوار كاش',
      few: 'فاضل $count مشاوير كاش',
      two: 'فاضل مشوارين كاش',
      one: 'فاضل مشوار كاش واحد',
      zero: 'خلصت مشاوير الكاش',
    );
    return '$_temp0';
  }

  @override
  String get cashTopUpBanner =>
      'اشحن محفظتك عشان تكمّل مشاويرك — سواق بديل وكرسي مضمون وفلوسك ترجعلك.';

  @override
  String get cashEnded => 'مشاوير الكاش خلصت — اشحن محفظتك عشان تكمّل.';

  @override
  String get cashOff =>
      'الكاش اتقفل بعد ما مشوارين اتسجّلوا من غير دفع — اشحن محفظتك عشان تكمّل.';

  @override
  String get needsTopUp => 'اشحن عشان تكمّل مشاويرك';

  @override
  String feeSavings(int fees) {
    return 'دفعت $fees ج رسوم الشهر ده. بالاشتراك هتدفع 129 بس.';
  }

  @override
  String get actTrip => 'مشوار';

  @override
  String get actCashTrip => 'مشوار كاش';

  @override
  String get actSubscription => 'اشتراك';

  @override
  String cashPaidLine(int price) {
    return 'دفعت $price ج كاش للسواق';
  }

  @override
  String get notChargedCash => 'مش محسوبة في فترة الكاش';

  @override
  String get breakdownShare => 'نصيب السواق';

  @override
  String get breakdownFee => 'رسوم الخدمة';

  @override
  String get breakdownNoFee => 'رسوم الخدمة: مفيش';

  @override
  String cashReceived(int price) {
    return 'استلمت $price ج كاش';
  }

  @override
  String get didNotPay => 'مدفعش';

  @override
  String get cashMarkedReceived => 'الكاش وصل';

  @override
  String get cashMarkedUnpaid => 'اتسجّل إنه مدفعش';

  @override
  String get cashReceivedTitle => 'الكاش اللي استلمته';

  @override
  String get cashReceivedNote => 'متسجّل بس — مش بيتسحب';

  @override
  String needsTopUpBody(int total) {
    return 'رصيدك أقل من تمن مشوار واحد ($total ج).';
  }

  @override
  String priceDriver(int price) {
    return '$price ج ليك من كل راكب · جورة مجانية للسواقين';
  }
}
