import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'مشوارك.. سوا.'**
  String get tagline;

  /// No description provided for @getStarted.
  ///
  /// In ar, this message translates to:
  /// **'يلا نبدأ'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @howTravel.
  ///
  /// In ar, this message translates to:
  /// **'بتتحرك إزاي؟'**
  String get howTravel;

  /// No description provided for @canDrive.
  ///
  /// In ar, this message translates to:
  /// **'معايا عربية'**
  String get canDrive;

  /// No description provided for @needRide.
  ///
  /// In ar, this message translates to:
  /// **'محتاج توصيلة'**
  String get needRide;

  /// No description provided for @freqTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم ولا مشوار واحد؟'**
  String get freqTitle;

  /// No description provided for @fRegular.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم'**
  String get fRegular;

  /// No description provided for @fOnce.
  ///
  /// In ar, this message translates to:
  /// **'مشوار واحد بس'**
  String get fOnce;

  /// No description provided for @fTag.
  ///
  /// In ar, this message translates to:
  /// **'الأوفر'**
  String get fTag;

  /// No description provided for @extraTrip.
  ///
  /// In ar, this message translates to:
  /// **'عايز مشوار زيادة؟ احجز كرسي'**
  String get extraTrip;

  /// No description provided for @subNote.
  ///
  /// In ar, this message translates to:
  /// **'ضمن اشتراكك · من غير رسوم حجز'**
  String get subNote;

  /// No description provided for @whereGo.
  ///
  /// In ar, this message translates to:
  /// **'بتروح فين كل يوم؟'**
  String get whereGo;

  /// No description provided for @dirBoth.
  ///
  /// In ar, this message translates to:
  /// **'رايح جاي'**
  String get dirBoth;

  /// No description provided for @dirGoing.
  ///
  /// In ar, this message translates to:
  /// **'رايح بس'**
  String get dirGoing;

  /// No description provided for @dirRet.
  ///
  /// In ar, this message translates to:
  /// **'راجع بس'**
  String get dirRet;

  /// No description provided for @findCommute.
  ///
  /// In ar, this message translates to:
  /// **'دوّرلي على مشواري'**
  String get findCommute;

  /// No description provided for @foundGroup.
  ///
  /// In ar, this message translates to:
  /// **'لقينالك مجموعة مشوارك!'**
  String get foundGroup;

  /// No description provided for @join.
  ///
  /// In ar, this message translates to:
  /// **'انضم للمجموعة'**
  String get join;

  /// No description provided for @confirmed.
  ///
  /// In ar, this message translates to:
  /// **'توصيلتك متأكدة'**
  String get confirmed;

  /// No description provided for @covered.
  ///
  /// In ar, this message translates to:
  /// **'متغطّي'**
  String get covered;

  /// No description provided for @cantCome.
  ///
  /// In ar, this message translates to:
  /// **'مش هقدر آجي بكرة'**
  String get cantCome;

  /// No description provided for @arrivedBtn.
  ///
  /// In ar, this message translates to:
  /// **'وصلت البوابة الرئيسية'**
  String get arrivedBtn;

  /// No description provided for @pickedUp.
  ///
  /// In ar, this message translates to:
  /// **'ركب'**
  String get pickedUp;

  /// No description provided for @noShow.
  ///
  /// In ar, this message translates to:
  /// **'مجاش'**
  String get noShow;

  /// No description provided for @planTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ أول شهر مجانًا'**
  String get planTitle;

  /// No description provided for @postReq.
  ///
  /// In ar, this message translates to:
  /// **'انشر مشوارك'**
  String get postReq;

  /// No description provided for @offerBtn.
  ///
  /// In ar, this message translates to:
  /// **'اعرض مشوار'**
  String get offerBtn;

  /// No description provided for @reqsOnRoute.
  ///
  /// In ar, this message translates to:
  /// **'طلبات على خطك'**
  String get reqsOnRoute;

  /// No description provided for @browseBtn.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على ركاب'**
  String get browseBtn;

  /// No description provided for @browseTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات قريبة منك'**
  String get browseTitle;

  /// No description provided for @tripsLeftA.
  ///
  /// In ar, this message translates to:
  /// **'المشاوير الباقية النهارده'**
  String get tripsLeftA;

  /// No description provided for @tabToday.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get tabToday;

  /// No description provided for @tabWeek.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع'**
  String get tabWeek;

  /// No description provided for @tabWallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get tabWallet;

  /// No description provided for @tabTrust.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get tabTrust;

  /// No description provided for @sos.
  ///
  /// In ar, this message translates to:
  /// **'استغاثة'**
  String get sos;

  /// No description provided for @langBtn.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get langBtn;

  /// No description provided for @langAria.
  ///
  /// In ar, this message translates to:
  /// **'Switch to English'**
  String get langAria;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @continueBtn.
  ///
  /// In ar, this message translates to:
  /// **'كمّل'**
  String get continueBtn;

  /// No description provided for @taglineOther.
  ///
  /// In ar, this message translates to:
  /// **'Go together. Every day.'**
  String get taglineOther;

  /// No description provided for @splashSub.
  ///
  /// In ar, this message translates to:
  /// **'مشوارك اليومي متنظّم مع ناس رايحة نفس سكتك. من غير ما تدوّر كل يوم الصبح.'**
  String get splashSub;

  /// No description provided for @switchAnytime.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تغيّر في أي وقت.'**
  String get switchAnytime;

  /// No description provided for @canDriveSub.
  ///
  /// In ar, this message translates to:
  /// **'عندي كراسي فاضية وعايز أشارك التكلفة'**
  String get canDriveSub;

  /// No description provided for @needRideSub.
  ///
  /// In ar, this message translates to:
  /// **'بدوّر على حد رايح نفس مكاني'**
  String get needRideSub;

  /// No description provided for @freqSub.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تعمل التاني في أي وقت بعدين.'**
  String get freqSub;

  /// No description provided for @fRegRider.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة ثابتة لمشوارك اليومي. أول شهر مجاني.'**
  String get fRegRider;

  /// No description provided for @fOnceRider.
  ///
  /// In ar, this message translates to:
  /// **'احجز كرسي فاضي أو انشر مشوارك. من غير اشتراك.'**
  String get fOnceRider;

  /// No description provided for @fRegDriver.
  ///
  /// In ar, this message translates to:
  /// **'شارك مشوارك اليومي مع مجموعة ثابتة. مجاني دايمًا.'**
  String get fRegDriver;

  /// No description provided for @fOnceDriver.
  ///
  /// In ar, this message translates to:
  /// **'اعرض كراسيك الفاضية في مشوار إنت رايحه أصلًا.'**
  String get fOnceDriver;

  /// No description provided for @toDriver.
  ///
  /// In ar, this message translates to:
  /// **'حوّل لوضع السواق'**
  String get toDriver;

  /// No description provided for @toRider.
  ///
  /// In ar, this message translates to:
  /// **'حوّل لوضع الراكب'**
  String get toRider;

  /// No description provided for @emptySeatsTitle.
  ///
  /// In ar, this message translates to:
  /// **'كراسي فاضية النهارده'**
  String get emptySeatsTitle;

  /// No description provided for @offerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اعرض مشوار'**
  String get offerTitle;

  /// No description provided for @backupTitle.
  ///
  /// In ar, this message translates to:
  /// **'أحمد مش هيقدر يسوق يوم التلات'**
  String get backupTitle;

  /// No description provided for @backupBody.
  ///
  /// In ar, this message translates to:
  /// **'محمد هيسوق بداله. مشوارك متغطّي، ومش محتاج تعمل حاجة.'**
  String get backupBody;

  /// No description provided for @gotIt.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get gotIt;

  /// No description provided for @pickupIn.
  ///
  /// In ar, this message translates to:
  /// **'التجمع بعد 12 دقيقة'**
  String get pickupIn;

  /// No description provided for @verifiedMember.
  ///
  /// In ar, this message translates to:
  /// **'عضو موثّق · 4.9 ★'**
  String get verifiedMember;

  /// No description provided for @phoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'رقم موبايلك إيه؟'**
  String get phoneTitle;

  /// No description provided for @phoneSub.
  ///
  /// In ar, this message translates to:
  /// **'هنبعتلك كود في رسالة عشان نتأكد إنه رقمك.'**
  String get phoneSub;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم موبايل مصري: 11 رقم بيبدأ بـ 01'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعتلي الكود'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الكود'**
  String get otpTitle;

  /// No description provided for @otpWrong.
  ///
  /// In ar, this message translates to:
  /// **'الكود ده مش مظبوط. جرّب تاني.'**
  String get otpWrong;

  /// No description provided for @otpResend.
  ///
  /// In ar, this message translates to:
  /// **'ابعت كود جديد'**
  String get otpResend;

  /// No description provided for @otpDevHint.
  ///
  /// In ar, this message translates to:
  /// **'كود التجربة: 123456'**
  String get otpDevHint;

  /// No description provided for @changeNumber.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الرقم'**
  String get changeNumber;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نبعت الكود دلوقتي. اتأكد من النت وجرّب تاني.'**
  String get networkError;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تاني'**
  String get retry;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتعرّف عليك'**
  String get profileTitle;

  /// No description provided for @profileSub.
  ///
  /// In ar, this message translates to:
  /// **'عشان مجموعتك تعرف هتركب مع مين.'**
  String get profileSub;

  /// No description provided for @firstName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العيلة'**
  String get lastName;

  /// No description provided for @genderLabel.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get genderLabel;

  /// No description provided for @male.
  ///
  /// In ar, this message translates to:
  /// **'راجل'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ar, this message translates to:
  /// **'ست'**
  String get female;

  /// No description provided for @genderNote.
  ///
  /// In ar, this message translates to:
  /// **'بنستخدمه بس لاختيار «ستات بس»، ومحدش بيشوفه.'**
  String get genderNote;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageLabel;

  /// No description provided for @roleLabel.
  ///
  /// In ar, this message translates to:
  /// **'بتتحرك إزاي'**
  String get roleLabel;

  /// No description provided for @comingSoonTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة دي جاية قريب'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'بنجهّزها دلوقتي. اختيارك اتحفظ.'**
  String get comingSoonBody;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get openSettings;

  /// No description provided for @galleryTitle.
  ///
  /// In ar, this message translates to:
  /// **'معرض التصميم'**
  String get galleryTitle;

  /// No description provided for @galleryColors.
  ///
  /// In ar, this message translates to:
  /// **'الألوان'**
  String get galleryColors;

  /// No description provided for @galleryType.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط'**
  String get galleryType;

  /// No description provided for @galleryShape.
  ///
  /// In ar, this message translates to:
  /// **'الأشكال والمسافات'**
  String get galleryShape;

  /// No description provided for @galleryButtons.
  ///
  /// In ar, this message translates to:
  /// **'الأزرار'**
  String get galleryButtons;

  /// No description provided for @galleryCards.
  ///
  /// In ar, this message translates to:
  /// **'الكروت'**
  String get galleryCards;

  /// No description provided for @gallerySelection.
  ///
  /// In ar, this message translates to:
  /// **'الاختيار'**
  String get gallerySelection;

  /// No description provided for @galleryFeedback.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get galleryFeedback;

  /// No description provided for @galleryPeople.
  ///
  /// In ar, this message translates to:
  /// **'الناس'**
  String get galleryPeople;

  /// No description provided for @galleryNav.
  ///
  /// In ar, this message translates to:
  /// **'التنقّل'**
  String get galleryNav;

  /// No description provided for @galleryDecrease.
  ///
  /// In ar, this message translates to:
  /// **'قلّل'**
  String get galleryDecrease;

  /// No description provided for @galleryIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زوّد'**
  String get galleryIncrease;

  /// No description provided for @otpSub.
  ///
  /// In ar, this message translates to:
  /// **'بعتناه على {phone}'**
  String otpSub(String phone);

  /// No description provided for @otpResendIn.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تطلب كود جديد بعد {seconds} ثانية'**
  String otpResendIn(int seconds);

  /// No description provided for @stepperValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} ج'**
  String stepperValue(String value);

  /// No description provided for @navMain.
  ///
  /// In ar, this message translates to:
  /// **'القائمة الرئيسية'**
  String get navMain;

  /// No description provided for @stepOf.
  ///
  /// In ar, this message translates to:
  /// **'خطوة {current} من {total}'**
  String stepOf(int current, int total);

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'البيت'**
  String get home;

  /// No description provided for @work.
  ///
  /// In ar, this message translates to:
  /// **'الشغل / الجامعة'**
  String get work;

  /// No description provided for @areaSheikhZayed.
  ///
  /// In ar, this message translates to:
  /// **'الشيخ زايد'**
  String get areaSheikhZayed;

  /// No description provided for @areaOctober.
  ///
  /// In ar, this message translates to:
  /// **'6 أكتوبر'**
  String get areaOctober;

  /// No description provided for @areaSmartVillage.
  ///
  /// In ar, this message translates to:
  /// **'القرية الذكية'**
  String get areaSmartVillage;

  /// No description provided for @pickHome.
  ///
  /// In ar, this message translates to:
  /// **'البيت فين؟'**
  String get pickHome;

  /// No description provided for @pickWork.
  ///
  /// In ar, this message translates to:
  /// **'الشغل فين؟'**
  String get pickWork;

  /// No description provided for @choosePlace.
  ///
  /// In ar, this message translates to:
  /// **'اختار المكان'**
  String get choosePlace;

  /// No description provided for @whenTravel.
  ///
  /// In ar, this message translates to:
  /// **'بتتحرك إمتى؟'**
  String get whenTravel;

  /// No description provided for @departure.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب'**
  String get departure;

  /// No description provided for @returnT.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع'**
  String get returnT;

  /// No description provided for @workingDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام الشغل'**
  String get workingDays;

  /// No description provided for @daySun.
  ///
  /// In ar, this message translates to:
  /// **'حد'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In ar, this message translates to:
  /// **'اتنين'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ar, this message translates to:
  /// **'تلات'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ar, this message translates to:
  /// **'أربع'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ar, this message translates to:
  /// **'خميس'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ar, this message translates to:
  /// **'جمعة'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In ar, this message translates to:
  /// **'سبت'**
  String get daySat;

  /// No description provided for @sunThu.
  ///
  /// In ar, this message translates to:
  /// **'الحد – الخميس'**
  String get sunThu;

  /// No description provided for @seatsQ.
  ///
  /// In ar, this message translates to:
  /// **'الكراسي الفاضية في عربيتك'**
  String get seatsQ;

  /// No description provided for @fewerSeats.
  ///
  /// In ar, this message translates to:
  /// **'كرسي أقل'**
  String get fewerSeats;

  /// No description provided for @moreSeats.
  ///
  /// In ar, this message translates to:
  /// **'كرسي زيادة'**
  String get moreSeats;

  /// No description provided for @whichTrips.
  ///
  /// In ar, this message translates to:
  /// **'هتسوق في أنهي مشوار؟'**
  String get whichTrips;

  /// No description provided for @otherTripNote.
  ///
  /// In ar, this message translates to:
  /// **'الركاب بياخدوا المشوار التاني مع سواق تاني في المجموعة.'**
  String get otherTripNote;

  /// No description provided for @contribTitle.
  ///
  /// In ar, this message translates to:
  /// **'مساهمة كل راكب'**
  String get contribTitle;

  /// No description provided for @lowerContribution.
  ///
  /// In ar, this message translates to:
  /// **'قلّل المساهمة'**
  String get lowerContribution;

  /// No description provided for @raiseContribution.
  ///
  /// In ar, this message translates to:
  /// **'زوّد المساهمة'**
  String get raiseContribution;

  /// No description provided for @suggestedPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر المقترح'**
  String get suggestedPrice;

  /// No description provided for @contribNote.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة على المسافة والبنزين والكارتة. الراكب بيشوفها قبل ما ينضم، وبتفضل ثابتة طول الشهر.'**
  String get contribNote;

  /// No description provided for @recoverDay.
  ///
  /// In ar, this message translates to:
  /// **'بتسترد في اليوم'**
  String get recoverDay;

  /// No description provided for @earlier.
  ///
  /// In ar, this message translates to:
  /// **'أبدري 5 دقايق'**
  String get earlier;

  /// No description provided for @later.
  ///
  /// In ar, this message translates to:
  /// **'أتأخر 5 دقايق'**
  String get later;

  /// No description provided for @sameAreaHint.
  ///
  /// In ar, this message translates to:
  /// **'اختار مكان شغل أبعد من 1.5 كم عن البيت.'**
  String get sameAreaHint;

  /// No description provided for @returnHint.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد الرجوع لازم يكون بعد الذهاب.'**
  String get returnHint;

  /// No description provided for @noDaysHint.
  ///
  /// In ar, this message translates to:
  /// **'اختار يوم واحد على الأقل.'**
  String get noDaysHint;

  /// No description provided for @mapAria.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المشوار'**
  String get mapAria;

  /// No description provided for @foundSub.
  ///
  /// In ar, this message translates to:
  /// **'ناس رايحة نفس سكتك، في نفس ميعادك.'**
  String get foundSub;

  /// No description provided for @statDrivers.
  ///
  /// In ar, this message translates to:
  /// **'سواقين'**
  String get statDrivers;

  /// No description provided for @statRiders.
  ///
  /// In ar, this message translates to:
  /// **'ركاب'**
  String get statRiders;

  /// No description provided for @statFixed.
  ///
  /// In ar, this message translates to:
  /// **'ثابت'**
  String get statFixed;

  /// No description provided for @egpTrip.
  ///
  /// In ar, this message translates to:
  /// **'ج/مشوار'**
  String get egpTrip;

  /// No description provided for @whyGroup.
  ///
  /// In ar, this message translates to:
  /// **'ليه المجموعة دي'**
  String get whyGroup;

  /// No description provided for @otherMatches.
  ///
  /// In ar, this message translates to:
  /// **'ترشيحات تانية'**
  String get otherMatches;

  /// No description provided for @seeOthers.
  ///
  /// In ar, this message translates to:
  /// **'شوف اختيارات تانية'**
  String get seeOthers;

  /// No description provided for @hideOthers.
  ///
  /// In ar, this message translates to:
  /// **'اخفي الاختيارات التانية'**
  String get hideOthers;

  /// No description provided for @reasonSameDeparture.
  ///
  /// In ar, this message translates to:
  /// **'نفس ميعاد الخروج'**
  String get reasonSameDeparture;

  /// No description provided for @reasonCompanyReturn.
  ///
  /// In ar, this message translates to:
  /// **'نفس الشركة · ميعاد رجوع قريب'**
  String get reasonCompanyReturn;

  /// No description provided for @reasonCompany.
  ///
  /// In ar, this message translates to:
  /// **'نفس الشركة'**
  String get reasonCompany;

  /// No description provided for @reasonCompound.
  ///
  /// In ar, this message translates to:
  /// **'نفس الكمبوند'**
  String get reasonCompound;

  /// No description provided for @reasonReturn.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد رجوع قريب'**
  String get reasonReturn;

  /// No description provided for @verifiedRider.
  ///
  /// In ar, this message translates to:
  /// **'راكب موثّق'**
  String get verifiedRider;

  /// No description provided for @verifiedRiderWoman.
  ///
  /// In ar, this message translates to:
  /// **'راكبة موثّقة'**
  String get verifiedRiderWoman;

  /// No description provided for @egpAmount.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج'**
  String egpAmount(int amount);

  /// No description provided for @aboveSuggested.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج أعلى من المقترح'**
  String aboveSuggested(int amount);

  /// No description provided for @belowSuggested.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج أقل من المقترح'**
  String belowSuggested(int amount);

  /// No description provided for @suggestedShort.
  ///
  /// In ar, this message translates to:
  /// **'المقترح {amount}'**
  String suggestedShort(int amount);

  /// No description provided for @timeAm.
  ///
  /// In ar, this message translates to:
  /// **'{time} ص'**
  String timeAm(String time);

  /// No description provided for @timePm.
  ///
  /// In ar, this message translates to:
  /// **'{time} م'**
  String timePm(String time);

  /// No description provided for @matchPercent.
  ///
  /// In ar, this message translates to:
  /// **'توافق {percent}%'**
  String matchPercent(int percent);

  /// No description provided for @membersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{عضو واحد} =2{عضوين} few{{count} أعضاء} other{{count} عضو}}'**
  String membersCount(int count);

  /// No description provided for @perWeek.
  ///
  /// In ar, this message translates to:
  /// **'{count}/أسبوع'**
  String perWeek(int count);

  /// No description provided for @feeLine.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج للسواق · من غير رسوم على المشوار'**
  String feeLine(int price);

  /// No description provided for @reasonDestination.
  ///
  /// In ar, this message translates to:
  /// **'نفس المكان: {area}'**
  String reasonDestination(String area);

  /// No description provided for @reasonDeparture.
  ///
  /// In ar, this message translates to:
  /// **'فرق {minutes} دقايق في ميعاد الخروج'**
  String reasonDeparture(int minutes);

  /// No description provided for @reasonPickup.
  ///
  /// In ar, this message translates to:
  /// **'نقطة التجمع على بعد {meters} متر'**
  String reasonPickup(int meters);

  /// No description provided for @reasonDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام شغل مشتركة'**
  String reasonDays(int count);

  /// No description provided for @reasonRating.
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء متقيّمين {rating} ★'**
  String reasonRating(String rating);

  /// No description provided for @otherMeta.
  ///
  /// In ar, this message translates to:
  /// **'{time} · {meters} م'**
  String otherMeta(String time, int meters);

  /// No description provided for @returnLeg.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع مع مجموعة {time}'**
  String returnLeg(String time);

  /// No description provided for @noMatch.
  ///
  /// In ar, this message translates to:
  /// **'إنت رقم {position} على قايمة {from} ← {to} — هنبلّغك أول ما نلاقيلك مجموعة'**
  String noMatch(int position, String from, String to);

  /// No description provided for @routeLine.
  ///
  /// In ar, this message translates to:
  /// **'{from} ← {to}'**
  String routeLine(String from, String to);

  /// No description provided for @timeDays.
  ///
  /// In ar, this message translates to:
  /// **'{time} · {days}'**
  String timeDays(String time, String days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
