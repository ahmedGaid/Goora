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
  /// **'ضمن اشتراكك · من غير رسوم'**
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
  /// **'اشترك ومن غير رسوم'**
  String get planTitle;

  /// No description provided for @planSubline.
  ///
  /// In ar, this message translates to:
  /// **'من غير رسوم خدمة على أي مشوار أو كرسي.'**
  String get planSubline;

  /// No description provided for @planMonthlyTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get planMonthlyTitle;

  /// No description provided for @planMonthlySub.
  ///
  /// In ar, this message translates to:
  /// **'149 جنيه/الشهر'**
  String get planMonthlySub;

  /// No description provided for @planYearlyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get planYearlyTitle;

  /// No description provided for @planYearlySub.
  ///
  /// In ar, this message translates to:
  /// **'1,490 جنيه/السنة'**
  String get planYearlySub;

  /// No description provided for @planYearlyChip.
  ///
  /// In ar, this message translates to:
  /// **'شهرين مجانًا'**
  String get planYearlyChip;

  /// No description provided for @planCompanyTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن طريق شركتي'**
  String get planCompanyTitle;

  /// No description provided for @planCompanySub.
  ///
  /// In ar, this message translates to:
  /// **'مجاني — أكّد إيميل الشغل'**
  String get planCompanySub;

  /// No description provided for @planIncludedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هتحصل على'**
  String get planIncludedTitle;

  /// No description provided for @planIncludedMatch.
  ///
  /// In ar, this message translates to:
  /// **'ترشيح يومي لجروب ركوبتك'**
  String get planIncludedMatch;

  /// No description provided for @planIncludedBackup.
  ///
  /// In ar, this message translates to:
  /// **'سواق بدّل لو سواقك اتأخر'**
  String get planIncludedBackup;

  /// No description provided for @planIncludedTrust.
  ///
  /// In ar, this message translates to:
  /// **'تتبّع الالتزام وأدوات أمان SOS'**
  String get planIncludedTrust;

  /// No description provided for @planFuelNote.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف البنزين والرسوم اللي تدفعها كل رحلة تروح كلها للسواق.'**
  String get planFuelNote;

  /// No description provided for @planCtaVerify.
  ///
  /// In ar, this message translates to:
  /// **'أكّد إيميل الشغل'**
  String get planCtaVerify;

  /// No description provided for @planFooter.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تلغي في أي وقت. جورة مجانية للسواقين.'**
  String get planFooter;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكّد إيميل شغلك'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In ar, this message translates to:
  /// **'{company} هتدفع خطة جورة بتاعتك بعد تأكيد إيميل شغلك.'**
  String verifyEmailBody(String company);

  /// No description provided for @verifyConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verifyConfirm;

  /// No description provided for @verifyNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'أكّد إيميل شغلك من تبويب الموثوقية الأول.'**
  String get verifyNotVerified;

  /// No description provided for @balanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'رصيد المحفظة'**
  String get balanceLabel;

  /// No description provided for @topUp.
  ///
  /// In ar, this message translates to:
  /// **'اشحن'**
  String get topUp;

  /// No description provided for @coversTrips.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{بيدفع رسوم جورة بس، مش نصيب السواق} =1{بيغطي حوالي مشوار واحد} =2{بيغطي حوالي مشوارين} few{بيغطي حوالي {count} مشاوير} many{بيغطي حوالي {count} مشوار} other{بيغطي حوالي {count} مشوار}}'**
  String coversTrips(int count);

  /// No description provided for @planChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get planChange;

  /// No description provided for @planCompanyActive.
  ///
  /// In ar, this message translates to:
  /// **'مجانية · شركتك بتدفعها'**
  String get planCompanyActive;

  /// No description provided for @howPayTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزاي الدفع بيشتغل'**
  String get howPayTitle;

  /// No description provided for @howPayRule1.
  ///
  /// In ar, this message translates to:
  /// **'بتدفع نصيب السواق ليه على طول، كاش أو InstaPay. جورة بتضيف بس رسوم خدمة لحد 10% على كل مشوار، والمشتركين من غير رسوم.'**
  String get howPayRule1;

  /// No description provided for @howPayRule1Company.
  ///
  /// In ar, this message translates to:
  /// **'بتدفع نصيب السواق ليه على طول، كاش أو InstaPay. خطة شركتك بتغطي رسوم جورة، فمفيش عليك رسوم خدمة.'**
  String get howPayRule1Company;

  /// No description provided for @howPayRule2.
  ///
  /// In ar, this message translates to:
  /// **'نصيب السواق بيروحله على طول. جورة مش بتمسكه ولا بتاخد منه نسبة.'**
  String get howPayRule2;

  /// No description provided for @howPayRule3.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء المتأخر والغياب بتدفعهم للسواق على طول، من غير رسوم خدمة.'**
  String get howPayRule3;

  /// No description provided for @topUpSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اشحن محفظتك'**
  String get topUpSheetTitle;

  /// No description provided for @topUpMethodInstaPay.
  ///
  /// In ar, this message translates to:
  /// **'InstaPay'**
  String get topUpMethodInstaPay;

  /// No description provided for @topUpMethodVodafone.
  ///
  /// In ar, this message translates to:
  /// **'فودافون كاش'**
  String get topUpMethodVodafone;

  /// No description provided for @topUpMethodCard.
  ///
  /// In ar, this message translates to:
  /// **'كارت'**
  String get topUpMethodCard;

  /// No description provided for @topUpConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أكّد الشحن'**
  String get topUpConfirm;

  /// No description provided for @topUpFailTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشحن ملحقش يتم'**
  String get topUpFailTitle;

  /// No description provided for @topUpFailBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة اتحصلت — جرّب تاني.'**
  String get topUpFailBody;

  /// No description provided for @changePlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'غيّر خطتك'**
  String get changePlanTitle;

  /// No description provided for @changePlanNote.
  ///
  /// In ar, this message translates to:
  /// **'الخطة الجديدة تتفعل من تاريخ الفوترة الجاي — مفيش تغيير في الفترة الحالية.'**
  String get changePlanNote;

  /// No description provided for @changePlanConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أكّد التغيير'**
  String get changePlanConfirm;

  /// No description provided for @breakdownTitle.
  ///
  /// In ar, this message translates to:
  /// **'بتدفع كام في المشوار'**
  String get breakdownTitle;

  /// No description provided for @breakdownFuel.
  ///
  /// In ar, this message translates to:
  /// **'البنزين والرسوم'**
  String get breakdownFuel;

  /// No description provided for @breakdownTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get breakdownTotal;

  /// No description provided for @activityTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحركة'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش حركة'**
  String get activityEmpty;

  /// No description provided for @actTopUp.
  ///
  /// In ar, this message translates to:
  /// **'شحن'**
  String get actTopUp;

  /// No description provided for @actTripDeduction.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة رحلة'**
  String get actTripDeduction;

  /// No description provided for @actLateCancelCharge.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء متأخر'**
  String get actLateCancelCharge;

  /// No description provided for @actFreeCancelZero.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء مجاني'**
  String get actFreeCancelZero;

  /// No description provided for @actTripIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل الرحلة'**
  String get actTripIncome;

  /// No description provided for @actFeeReceivedFrom.
  ///
  /// In ar, this message translates to:
  /// **'رسوم {name}'**
  String actFeeReceivedFrom(String name);

  /// No description provided for @actWithdrawal.
  ///
  /// In ar, this message translates to:
  /// **'سحب'**
  String get actWithdrawal;

  /// No description provided for @driverBreakdownTitle.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة رحلتك'**
  String get driverBreakdownTitle;

  /// No description provided for @driverBreakdownCost.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الرحلة'**
  String get driverBreakdownCost;

  /// No description provided for @driverBreakdownReceived.
  ///
  /// In ar, this message translates to:
  /// **'بتستلم من الركاب'**
  String get driverBreakdownReceived;

  /// No description provided for @driverBreakdownGap.
  ///
  /// In ar, this message translates to:
  /// **'بتدفعه من جيبك'**
  String get driverBreakdownGap;

  /// No description provided for @driverBreakdownFree.
  ///
  /// In ar, this message translates to:
  /// **'جورة مجانية للسواقين'**
  String get driverBreakdownFree;

  /// No description provided for @postReq.
  ///
  /// In ar, this message translates to:
  /// **'انشر مشوارك'**
  String get postReq;

  /// No description provided for @seeYourRequest.
  ///
  /// In ar, this message translates to:
  /// **'شوف طلبك'**
  String get seeYourRequest;

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
  /// **'مجموعة ثابتة لمشوارك اليومي. أول 5 مشاوير من غير رسوم جورة.'**
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
  /// **'كراسي فاضية'**
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
  /// **'بنستخدمه بس لاختيار «سيدات فقط»، ومحدش بيشوفه.'**
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

  /// No description provided for @areaNewCairo.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة الجديدة'**
  String get areaNewCairo;

  /// No description provided for @areaNasrCity.
  ///
  /// In ar, this message translates to:
  /// **'مدينة نصر'**
  String get areaNasrCity;

  /// No description provided for @areaHeliopolis.
  ///
  /// In ar, this message translates to:
  /// **'مصر الجديدة'**
  String get areaHeliopolis;

  /// No description provided for @areaObour.
  ///
  /// In ar, this message translates to:
  /// **'العبور'**
  String get areaObour;

  /// No description provided for @areaTenthOfRamadan.
  ///
  /// In ar, this message translates to:
  /// **'العاشر من رمضان'**
  String get areaTenthOfRamadan;

  /// No description provided for @areaIsmailia.
  ///
  /// In ar, this message translates to:
  /// **'الإسماعيلية'**
  String get areaIsmailia;

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

  /// No description provided for @pickTime.
  ///
  /// In ar, this message translates to:
  /// **'اختار الميعاد'**
  String get pickTime;

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

  /// No description provided for @chooseThisGroup.
  ///
  /// In ar, this message translates to:
  /// **'اختار المجموعة دي'**
  String get chooseThisGroup;

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

  /// No description provided for @goodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير يا {name}'**
  String goodMorning(String name);

  /// No description provided for @goodEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير يا {name}'**
  String goodEvening(String name);

  /// No description provided for @todaySub.
  ///
  /// In ar, this message translates to:
  /// **'ده مشوارك النهارده.'**
  String get todaySub;

  /// No description provided for @nextRide.
  ///
  /// In ar, this message translates to:
  /// **'مشوارك الجاي · {day}'**
  String nextRide(String day);

  /// No description provided for @relToday.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get relToday;

  /// No description provided for @relTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'بكرة'**
  String get relTomorrow;

  /// No description provided for @relTomorrowDay.
  ///
  /// In ar, this message translates to:
  /// **'بكرة ({day})'**
  String relTomorrowDay(String day);

  /// No description provided for @relOn.
  ///
  /// In ar, this message translates to:
  /// **'يوم {day}'**
  String relOn(String day);

  /// No description provided for @heroToday.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get heroToday;

  /// No description provided for @heroTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'بكرة'**
  String get heroTomorrow;

  /// No description provided for @legGoing.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب'**
  String get legGoing;

  /// No description provided for @legReturn.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع'**
  String get legReturn;

  /// No description provided for @legRow.
  ///
  /// In ar, this message translates to:
  /// **'{leg}: {driver} · {time}'**
  String legRow(String leg, String driver, String time);

  /// No description provided for @youWord.
  ///
  /// In ar, this message translates to:
  /// **'إنت'**
  String get youWord;

  /// No description provided for @noDriverYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش سواق'**
  String get noDriverYet;

  /// No description provided for @legsNote.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب والرجوع مشوارين منفصلين، وممكن كل واحد يبقى بسواق.'**
  String get legsNote;

  /// No description provided for @goingLeg.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب مع مجموعة {time}'**
  String goingLeg(String time);

  /// No description provided for @pickupInMin.
  ///
  /// In ar, this message translates to:
  /// **'التجمع بعد {minutes, plural, =1{دقيقة} =2{دقيقتين} few{{minutes} دقايق} other{{minutes} دقيقة}}'**
  String pickupInMin(int minutes);

  /// No description provided for @callDriver.
  ///
  /// In ar, this message translates to:
  /// **'كلّم السواق'**
  String get callDriver;

  /// No description provided for @callName.
  ///
  /// In ar, this message translates to:
  /// **'كلّم {name}'**
  String callName(String name);

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In ar, this message translates to:
  /// **'مش موثّق'**
  String get notVerified;

  /// No description provided for @carLine.
  ///
  /// In ar, this message translates to:
  /// **'{car} · {colour} · {rating} ★'**
  String carLine(String car, String colour, String rating);

  /// No description provided for @colourWhite.
  ///
  /// In ar, this message translates to:
  /// **'أبيض'**
  String get colourWhite;

  /// No description provided for @colourSilver.
  ///
  /// In ar, this message translates to:
  /// **'فضي'**
  String get colourSilver;

  /// No description provided for @colourBlack.
  ///
  /// In ar, this message translates to:
  /// **'أسود'**
  String get colourBlack;

  /// No description provided for @colourGrey.
  ///
  /// In ar, this message translates to:
  /// **'رمادي'**
  String get colourGrey;

  /// No description provided for @colourRed.
  ///
  /// In ar, this message translates to:
  /// **'أحمر'**
  String get colourRed;

  /// No description provided for @colourBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get colourBlue;

  /// No description provided for @stopMainGate.
  ///
  /// In ar, this message translates to:
  /// **'البوابة الرئيسية'**
  String get stopMainGate;

  /// No description provided for @stopCentralSt.
  ///
  /// In ar, this message translates to:
  /// **'الشارع الرئيسي'**
  String get stopCentralSt;

  /// No description provided for @stopGasStation.
  ///
  /// In ar, this message translates to:
  /// **'بنزينة 26 يوليو'**
  String get stopGasStation;

  /// No description provided for @stopSmartVillageGate2.
  ///
  /// In ar, this message translates to:
  /// **'القرية الذكية، بوابة 2'**
  String get stopSmartVillageGate2;

  /// No description provided for @stopNewCairoMeet.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة الجديدة، شارع التسعين'**
  String get stopNewCairoMeet;

  /// No description provided for @stopNasrCityMeet.
  ///
  /// In ar, this message translates to:
  /// **'مدينة نصر، سيتي ستارز'**
  String get stopNasrCityMeet;

  /// No description provided for @stopHeliopolisMeet.
  ///
  /// In ar, this message translates to:
  /// **'مصر الجديدة، ميدان الكوربة'**
  String get stopHeliopolisMeet;

  /// No description provided for @stopObourMeet.
  ///
  /// In ar, this message translates to:
  /// **'العبور، سوق العبور'**
  String get stopObourMeet;

  /// No description provided for @stopTenthOfRamadanMeet.
  ///
  /// In ar, this message translates to:
  /// **'العاشر من رمضان، الحي الأول'**
  String get stopTenthOfRamadanMeet;

  /// No description provided for @stopIsmailiaMeet.
  ///
  /// In ar, this message translates to:
  /// **'الإسماعيلية، ميدان الممر'**
  String get stopIsmailiaMeet;

  /// No description provided for @tlPickup.
  ///
  /// In ar, this message translates to:
  /// **'التجمع · {time}'**
  String tlPickup(String time);

  /// No description provided for @tlOnTheWay.
  ///
  /// In ar, this message translates to:
  /// **'في الطريق'**
  String get tlOnTheWay;

  /// No description provided for @tlPassengers.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{راكب واحد} =2{راكبين} few{{count} ركاب} other{{count} راكب}} · {names}'**
  String tlPassengers(int count, String names);

  /// No description provided for @tlArrival.
  ///
  /// In ar, this message translates to:
  /// **'الوصول · {time}'**
  String tlArrival(String time);

  /// No description provided for @listSep.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get listSep;

  /// No description provided for @returnTime.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد الرجوع'**
  String get returnTime;

  /// No description provided for @noReturnTrip.
  ///
  /// In ar, this message translates to:
  /// **'مفيش رجوع'**
  String get noReturnTrip;

  /// No description provided for @payPerTrip.
  ///
  /// In ar, this message translates to:
  /// **'بتدفع في المشوار'**
  String get payPerTrip;

  /// No description provided for @shareTrip.
  ///
  /// In ar, this message translates to:
  /// **'شارك المشوار'**
  String get shareTrip;

  /// No description provided for @cantComeNote.
  ///
  /// In ar, this message translates to:
  /// **'مجاني قبل 9 بالليل · بعدها تدفع نص مساهمتك'**
  String get cantComeNote;

  /// No description provided for @offTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنت مش جاي {when}'**
  String offTitle(String when);

  /// No description provided for @offLegTitle.
  ///
  /// In ar, this message translates to:
  /// **'مش جاي في {trip} {when}'**
  String offLegTitle(String trip, String when);

  /// No description provided for @tripGoing.
  ///
  /// In ar, this message translates to:
  /// **'رحلة الذهاب'**
  String get tripGoing;

  /// No description provided for @tripReturn.
  ///
  /// In ar, this message translates to:
  /// **'رحلة الرجوع'**
  String get tripReturn;

  /// No description provided for @offBody.
  ///
  /// In ar, this message translates to:
  /// **'اعتذرت قبل 9 بالليل، فمفيش أي رسوم. كرسيك اتعرض على قائمة الانتظار.'**
  String get offBody;

  /// No description provided for @lateOffBody.
  ///
  /// In ar, this message translates to:
  /// **'اعتذرت بعد 9 بالليل — {amount} ج للسواق.'**
  String lateOffBody(int amount);

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'لأ، أنا جاي'**
  String get undo;

  /// No description provided for @undoRefused.
  ///
  /// In ar, this message translates to:
  /// **'الكرسي اتاخد من قايمة الانتظار، فمش هينفع نرجّعه. ممكن تحجز كرسي فاضي لو محتاج.'**
  String get undoRefused;

  /// No description provided for @undoTooLate.
  ///
  /// In ar, this message translates to:
  /// **'عدّى ميعاد التجمع، فمش هينفع نرجّع الإلغاء.'**
  String get undoTooLate;

  /// No description provided for @cantComeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيه المشاوير اللي مش هتلحقها؟'**
  String get cantComeTitle;

  /// No description provided for @legAt.
  ///
  /// In ar, this message translates to:
  /// **'{leg} · {time}'**
  String legAt(String leg, String time);

  /// No description provided for @freeCancelPreview.
  ///
  /// In ar, this message translates to:
  /// **'قبل 9 بالليل: من غير فلوس'**
  String get freeCancelPreview;

  /// No description provided for @lateCancelPreview.
  ///
  /// In ar, this message translates to:
  /// **'بعد 9 بالليل: هتدفع {amount} ج للسواق'**
  String lateCancelPreview(int amount);

  /// No description provided for @confirmCancel.
  ///
  /// In ar, this message translates to:
  /// **'أكّد الإلغاء'**
  String get confirmCancel;

  /// No description provided for @pickOneTrip.
  ///
  /// In ar, this message translates to:
  /// **'اختار مشوار واحد على الأقل'**
  String get pickOneTrip;

  /// No description provided for @cancelAfterPickup.
  ///
  /// In ar, this message translates to:
  /// **'عدّى ميعاد التجمع. لو مجتش، السواق هيسجّلك غياب.'**
  String get cancelAfterPickup;

  /// No description provided for @notNextWeek.
  ///
  /// In ar, this message translates to:
  /// **'مش جاي الأسبوع الجاي'**
  String get notNextWeek;

  /// No description provided for @notNextWeekConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هنعلّم كل أيام الأسبوع الجاي إجازة. الأيام اللي لسه قبل 9 بالليل من غير فلوس.'**
  String get notNextWeekConfirm;

  /// No description provided for @notNextWeekDone.
  ///
  /// In ar, this message translates to:
  /// **'تمام، علّمنا الأسبوع الجاي إجازة.'**
  String get notNextWeekDone;

  /// No description provided for @keepIt.
  ///
  /// In ar, this message translates to:
  /// **'لأ، سيبه'**
  String get keepIt;

  /// No description provided for @headsUp.
  ///
  /// In ar, this message translates to:
  /// **'خلي بالك'**
  String get headsUp;

  /// No description provided for @noShowWarning.
  ///
  /// In ar, this message translates to:
  /// **'مجتش مرتين الشهر ده. المرة التالتة هتخرجك من المجموعة.'**
  String get noShowWarning;

  /// No description provided for @removedTitle.
  ///
  /// In ar, this message translates to:
  /// **'مبقتش في المجموعة'**
  String get removedTitle;

  /// No description provided for @removedNotice.
  ///
  /// In ar, this message translates to:
  /// **'خرجناك من المجموعة عشان مجتش 3 مرات الشهر ده. مشوارك متسجّل، ونقدر ندوّرلك على مجموعة جديدة.'**
  String get removedNotice;

  /// No description provided for @findNewGroup.
  ///
  /// In ar, this message translates to:
  /// **'دوّرلي على مجموعة جديدة'**
  String get findNewGroup;

  /// No description provided for @drivingWhen.
  ///
  /// In ar, this message translates to:
  /// **'إنت اللي هتسوق {when}.'**
  String drivingWhen(String when);

  /// No description provided for @notDrivingSoon.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سواقة عليك الأيام الجاية.'**
  String get notDrivingSoon;

  /// No description provided for @heroDriver.
  ///
  /// In ar, this message translates to:
  /// **'{when} · {direction} · {count, plural, =0{مفيش ركاب} =1{راكب واحد} =2{راكبين} few{{count} ركاب} other{{count} راكب}}'**
  String heroDriver(String when, String direction, int count);

  /// No description provided for @pickupN.
  ///
  /// In ar, this message translates to:
  /// **'تجمع {n} — {stop}'**
  String pickupN(int n, String stop);

  /// No description provided for @returnFrom.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع من {place}'**
  String returnFrom(String place);

  /// No description provided for @estContrib.
  ///
  /// In ar, this message translates to:
  /// **'المساهمة المتوقعة'**
  String get estContrib;

  /// No description provided for @confirmDrive.
  ///
  /// In ar, this message translates to:
  /// **'أكّد مشوار بكرة'**
  String get confirmDrive;

  /// No description provided for @confirmDriveToday.
  ///
  /// In ar, this message translates to:
  /// **'أكّد مشوار النهارده'**
  String get confirmDriveToday;

  /// No description provided for @confirmDriveDay.
  ///
  /// In ar, this message translates to:
  /// **'أكّد مشوار يوم {day}'**
  String confirmDriveDay(String day);

  /// No description provided for @confirmedNote.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد. الركاب وصلهم إشعار.'**
  String get confirmedNote;

  /// No description provided for @undoConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التأكيد'**
  String get undoConfirm;

  /// No description provided for @reportDelay.
  ///
  /// In ar, this message translates to:
  /// **'هتأخر'**
  String get reportDelay;

  /// No description provided for @cantDrive.
  ///
  /// In ar, this message translates to:
  /// **'مش هقدر أسوق'**
  String get cantDrive;

  /// No description provided for @cantDriveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'متأكد؟ هندوّر على سواق بديل لركابك.'**
  String get cantDriveConfirm;

  /// No description provided for @cantDriveYes.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، مش هقدر'**
  String get cantDriveYes;

  /// No description provided for @keepDriving.
  ///
  /// In ar, this message translates to:
  /// **'لأ، هسوق'**
  String get keepDriving;

  /// No description provided for @cantDriveDone.
  ///
  /// In ar, this message translates to:
  /// **'قلنا للمجموعة إنك مش هتسوق {when}. بندوّر على سواق بديل.'**
  String cantDriveDone(String when);

  /// No description provided for @delayTitle.
  ///
  /// In ar, this message translates to:
  /// **'هتتأخر قد إيه؟'**
  String get delayTitle;

  /// No description provided for @delayMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes, plural, few{{minutes} دقايق} other{{minutes} دقيقة}}'**
  String delayMinutes(int minutes);

  /// No description provided for @delaySent.
  ///
  /// In ar, this message translates to:
  /// **'بلّغنا الركاب بالميعاد الجديد: {time}'**
  String delaySent(String time);

  /// No description provided for @reqPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات بتظهرلك بس لو لفّتك أقل من 10 دقايق. والسعر ثابت من Goora.'**
  String get reqPrivacy;

  /// No description provided for @reqsPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الركاب اللي على خطك هتظهر هنا.'**
  String get reqsPlaceholder;

  /// No description provided for @rideWith.
  ///
  /// In ar, this message translates to:
  /// **'راكب {day} مع {driver}'**
  String rideWith(String day, String driver);

  /// No description provided for @checkin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الوصول'**
  String get checkin;

  /// No description provided for @arrivedAt.
  ///
  /// In ar, this message translates to:
  /// **'وصلت {stop}'**
  String arrivedAt(String stop);

  /// No description provided for @arrivedNote.
  ///
  /// In ar, this message translates to:
  /// **'الركاب هيوصلهم إشعار. هتستنى 5 دقايق بالكتير.'**
  String get arrivedNote;

  /// No description provided for @stWaiting.
  ///
  /// In ar, this message translates to:
  /// **'وصله إشعار · مستنيين {time}'**
  String stWaiting(String time);

  /// No description provided for @stNotArrived.
  ///
  /// In ar, this message translates to:
  /// **'لسه موصلتش'**
  String get stNotArrived;

  /// No description provided for @stNoShow.
  ///
  /// In ar, this message translates to:
  /// **'مجاش · اتحسبت مساهمته كاملة'**
  String get stNoShow;

  /// No description provided for @noShowAvailableIn.
  ///
  /// In ar, this message translates to:
  /// **'متاح بعد {time}'**
  String noShowAvailableIn(String time);

  /// No description provided for @noShowNote.
  ///
  /// In ar, this message translates to:
  /// **'لو الراكب مجاش بعد 5 دقايق، بيدفع مساهمته كاملة.'**
  String get noShowNote;

  /// No description provided for @ratingStars.
  ///
  /// In ar, this message translates to:
  /// **'{rating} ★'**
  String ratingStars(String rating);

  /// No description provided for @startTrip.
  ///
  /// In ar, this message translates to:
  /// **'يلا نتحرك'**
  String get startTrip;

  /// No description provided for @endTrip.
  ///
  /// In ar, this message translates to:
  /// **'وصلنا'**
  String get endTrip;

  /// No description provided for @tripOnWay.
  ///
  /// In ar, this message translates to:
  /// **'المشوار بدأ. سوق بالراحة.'**
  String get tripOnWay;

  /// No description provided for @tripEndedNote.
  ///
  /// In ar, this message translates to:
  /// **'المشوار خلص. شكرًا!'**
  String get tripEndedNote;

  /// No description provided for @refusedNoShowEarly.
  ///
  /// In ar, this message translates to:
  /// **'استنى لحد ما الـ 5 دقايق يخلصوا.'**
  String get refusedNoShowEarly;

  /// No description provided for @refusedTripStarted.
  ///
  /// In ar, this message translates to:
  /// **'المشوار بدأ، فمش هينفع تغيّر.'**
  String get refusedTripStarted;

  /// No description provided for @inboxTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get inboxTitle;

  /// No description provided for @inboxEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إشعارات لسه'**
  String get inboxEmpty;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'هنبلغك هنا بأي تغيير في مشاويرك.'**
  String get inboxEmptyBody;

  /// No description provided for @inboxAria.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات، {count} مش مقروءة'**
  String inboxAria(int count);

  /// No description provided for @sentToRiders.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت لركابك'**
  String get sentToRiders;

  /// No description provided for @nDriverConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'السواق أكّد مشوار {day}.'**
  String nDriverConfirmed(String day);

  /// No description provided for @nDriverUnconfirmed.
  ///
  /// In ar, this message translates to:
  /// **'السواق لغى تأكيد مشوار {day}.'**
  String nDriverUnconfirmed(String day);

  /// No description provided for @nDelay.
  ///
  /// In ar, this message translates to:
  /// **'السواق هيتأخر {minutes, plural, few{{minutes} دقايق} other{{minutes} دقيقة}}. الميعاد الجديد {time}.'**
  String nDelay(int minutes, String time);

  /// No description provided for @nDriverArrived.
  ///
  /// In ar, this message translates to:
  /// **'السواق وصل {stop}. تعالى في خلال 5 دقايق.'**
  String nDriverArrived(String stop);

  /// No description provided for @nLateCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء متأخر يوم {day}: {amount} ج للسواق.'**
  String nLateCancel(String day, int amount);

  /// No description provided for @nNoShow.
  ///
  /// In ar, this message translates to:
  /// **'غياب يوم {day}: {amount} ج للسواق.'**
  String nNoShow(String day, int amount);

  /// No description provided for @nSeatOffered.
  ///
  /// In ar, this message translates to:
  /// **'كرسيك يوم {day} اتعرض على قائمة الانتظار.'**
  String nSeatOffered(String day);

  /// No description provided for @backupTitleFor.
  ///
  /// In ar, this message translates to:
  /// **'{driver} مش هيقدر يسوق يوم {day}'**
  String backupTitleFor(String driver, String day);

  /// No description provided for @backupBodyFor.
  ///
  /// In ar, this message translates to:
  /// **'{cover} هيسوق بداله. مشوارك متغطّي، ومش محتاج تعمل حاجة.'**
  String backupBodyFor(String cover);

  /// No description provided for @noCoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سواق {when}'**
  String noCoverTitle(String when);

  /// No description provided for @noCoverBody.
  ///
  /// In ar, this message translates to:
  /// **'{driver} مش هيقدر يسوق، وملقيناش بديل. اختار اللي يناسبك:'**
  String noCoverBody(String driver);

  /// No description provided for @noCoverDayOff.
  ///
  /// In ar, this message translates to:
  /// **'خد اليوم إجازة — من غير فلوس'**
  String get noCoverDayOff;

  /// No description provided for @sosTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتاج مساعدة؟'**
  String get sosTitle;

  /// No description provided for @sosCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بـ 122'**
  String get sosCall;

  /// No description provided for @sosAlert.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ الناس اللي بثق فيهم'**
  String get sosAlert;

  /// No description provided for @sosAlertSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنالهم لينك المشوار'**
  String get sosAlertSent;

  /// No description provided for @sosNoContacts.
  ///
  /// In ar, this message translates to:
  /// **'ضيف حد بتثق فيه عشان نبلّغه وقت الطوارئ'**
  String get sosNoContacts;

  /// No description provided for @trustedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ناس بثق فيهم'**
  String get trustedTitle;

  /// No description provided for @trustedAdd.
  ///
  /// In ar, this message translates to:
  /// **'ضيف حد'**
  String get trustedAdd;

  /// No description provided for @trustedMax.
  ///
  /// In ar, this message translates to:
  /// **'ممكن تضيف لحد 3'**
  String get trustedMax;

  /// No description provided for @shareMessage.
  ///
  /// In ar, this message translates to:
  /// **'أنا في مشواري مع {driver} ({car}) من {from} لـ {to}، هوصل حوالي {time}. تابعني: {link}'**
  String shareMessage(
    String driver,
    String car,
    String from,
    String to,
    String time,
    String link,
  );

  /// No description provided for @scheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'جدول مشاويرك'**
  String get scheduleTitle;

  /// No description provided for @rotateNote.
  ///
  /// In ar, this message translates to:
  /// **'Goora بيوزّع السواقة بالعدل، ولو حد اعتذر بيسد مكانه تلقائي.'**
  String get rotateNote;

  /// No description provided for @drivesName.
  ///
  /// In ar, this message translates to:
  /// **'{name} بيسوق'**
  String drivesName(String name);

  /// No description provided for @youDrive.
  ///
  /// In ar, this message translates to:
  /// **'إنت بتسوق'**
  String get youDrive;

  /// No description provided for @youRide.
  ///
  /// In ar, this message translates to:
  /// **'إنت راكب'**
  String get youRide;

  /// No description provided for @youOff.
  ///
  /// In ar, this message translates to:
  /// **'إنت مش جاي'**
  String get youOff;

  /// No description provided for @offNote.
  ///
  /// In ar, this message translates to:
  /// **'اعتذرت قبل 9 بالليل · من غير رسوم'**
  String get offNote;

  /// No description provided for @lateOffNote.
  ///
  /// In ar, this message translates to:
  /// **'اعتذرت بعد 9 بالليل · {amount} ج للسواق'**
  String lateOffNote(int amount);

  /// No description provided for @backupName.
  ///
  /// In ar, this message translates to:
  /// **'{name} (بديل)'**
  String backupName(String name);

  /// No description provided for @memberRating.
  ///
  /// In ar, this message translates to:
  /// **'عضو · {rating} ★'**
  String memberRating(String rating);

  /// No description provided for @verifiedMemberRating.
  ///
  /// In ar, this message translates to:
  /// **'عضو موثّق · {rating} ★'**
  String verifiedMemberRating(String rating);

  /// No description provided for @reliability.
  ///
  /// In ar, this message translates to:
  /// **'الالتزام'**
  String get reliability;

  /// No description provided for @relLateCancels.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{إلغاء متأخر واحد الشهر ده.} =2{إلغاءين متأخرين الشهر ده.} few{{count} إلغاءات متأخرة الشهر ده.} other{{count} إلغاء متأخر الشهر ده.}}'**
  String relLateCancels(int count);

  /// No description provided for @relNoShows.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{غياب واحد الشهر ده.} =2{غيابين الشهر ده.} few{{count} مرات غياب الشهر ده.} other{{count} مرة غياب الشهر ده.}}'**
  String relNoShows(int count);

  /// No description provided for @relRule.
  ///
  /// In ar, this message translates to:
  /// **'3 مرات غياب في الشهر بتخرّجك من المجموعة.'**
  String get relRule;

  /// No description provided for @whoRide.
  ///
  /// In ar, this message translates to:
  /// **'مين يركب معايا'**
  String get whoRide;

  /// No description provided for @checkPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get checkPhone;

  /// No description provided for @checkNationalId.
  ///
  /// In ar, this message translates to:
  /// **'البطاقة'**
  String get checkNationalId;

  /// No description provided for @checkWorkEmail.
  ///
  /// In ar, this message translates to:
  /// **'إيميل الشغل'**
  String get checkWorkEmail;

  /// No description provided for @checkLicense.
  ///
  /// In ar, this message translates to:
  /// **'رخصة السواقة'**
  String get checkLicense;

  /// No description provided for @checkVehicle.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get checkVehicle;

  /// No description provided for @notNeeded.
  ///
  /// In ar, this message translates to:
  /// **'مش مطلوب'**
  String get notNeeded;

  /// No description provided for @privacyVerified.
  ///
  /// In ar, this message translates to:
  /// **'الموثّقين بس'**
  String get privacyVerified;

  /// No description provided for @privacyCompany.
  ///
  /// In ar, this message translates to:
  /// **'نفس الشركة'**
  String get privacyCompany;

  /// No description provided for @privacyCompound.
  ///
  /// In ar, this message translates to:
  /// **'نفس الكمبوند'**
  String get privacyCompound;

  /// No description provided for @privacyWomen.
  ///
  /// In ar, this message translates to:
  /// **'سيدات فقط'**
  String get privacyWomen;

  /// No description provided for @privacyNote.
  ///
  /// In ar, this message translates to:
  /// **'الاختيار ده هيتطبّق على المجموعات الجاية، مش مجموعتك الحالية.'**
  String get privacyNote;

  /// No description provided for @needWorkEmail.
  ///
  /// In ar, this message translates to:
  /// **'وثّق إيميل الشغل الأول'**
  String get needWorkEmail;

  /// No description provided for @needCompound.
  ///
  /// In ar, this message translates to:
  /// **'ضيف اسم الكمبوند الأول'**
  String get needCompound;

  /// No description provided for @driverNeedsDocs.
  ///
  /// In ar, this message translates to:
  /// **'عشان تسوق، لازم الرخصة والعربية يكونوا موثّقين.'**
  String get driverNeedsDocs;

  /// No description provided for @demoSection.
  ///
  /// In ar, this message translates to:
  /// **'تجربة (للمطورين)'**
  String get demoSection;

  /// No description provided for @demoNow.
  ///
  /// In ar, this message translates to:
  /// **'الوقت دلوقتي: {time}'**
  String demoNow(String time);

  /// No description provided for @demoRideDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم مشوار · 7:15 ص'**
  String get demoRideDay;

  /// No description provided for @demo855.
  ///
  /// In ar, this message translates to:
  /// **'قبل 9 بالليل · 8:55 م'**
  String get demo855;

  /// No description provided for @demo905.
  ///
  /// In ar, this message translates to:
  /// **'بعد 9 بالليل · 9:05 م'**
  String get demo905;

  /// No description provided for @demoRealTime.
  ///
  /// In ar, this message translates to:
  /// **'الوقت الحقيقي'**
  String get demoRealTime;

  /// No description provided for @demoCorridor.
  ///
  /// In ar, this message translates to:
  /// **'المسار التجريبي: {name} (دوس للتبديل)'**
  String demoCorridor(String name);

  /// No description provided for @demoReset.
  ///
  /// In ar, this message translates to:
  /// **'امسح بيانات التجربة'**
  String get demoReset;

  /// No description provided for @noRidesSoon.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مشاوير الأيام الجاية.'**
  String get noRidesSoon;

  /// No description provided for @loadingToday.
  ///
  /// In ar, this message translates to:
  /// **'بنجهّز مشوارك…'**
  String get loadingToday;

  /// No description provided for @todayError.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب مشوارك دلوقتي.'**
  String get todayError;

  /// No description provided for @nDriverNoShow.
  ///
  /// In ar, this message translates to:
  /// **'مسجّلتش وصولك لمشوار يوم {day}، فاتحسب إنك مجتش.'**
  String nDriverNoShow(String day);

  /// No description provided for @carColour.
  ///
  /// In ar, this message translates to:
  /// **'{car} · {colour}'**
  String carColour(String car, String colour);

  /// No description provided for @demoNowValue.
  ///
  /// In ar, this message translates to:
  /// **'{day} {date} · {time}'**
  String demoNowValue(String day, String date, String time);

  /// No description provided for @noCoverEmptySeat.
  ///
  /// In ar, this message translates to:
  /// **'احجز كرسي فاضي'**
  String get noCoverEmptySeat;

  /// No description provided for @offNoCoverBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سواق اليوم ده، فمن غير رسوم.'**
  String get offNoCoverBody;

  /// No description provided for @noCoverNote.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سواق · من غير رسوم'**
  String get noCoverNote;

  /// No description provided for @demoBackup.
  ///
  /// In ar, this message translates to:
  /// **'السواق مش هيقدر يسوق الثلاثاء الجاي'**
  String get demoBackup;

  /// No description provided for @demoNoCover.
  ///
  /// In ar, this message translates to:
  /// **'السواق مش هيقدر يسوق — من غير بديل'**
  String get demoNoCover;

  /// No description provided for @weekRiderLine.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب: {going} · الرجوع: {ret}'**
  String weekRiderLine(String going, String ret);

  /// No description provided for @weekLegLine.
  ///
  /// In ar, this message translates to:
  /// **'{leg}: {time}'**
  String weekLegLine(String leg, String time);

  /// No description provided for @weekDriveLine.
  ///
  /// In ar, this message translates to:
  /// **'{direction} · {count, plural, =0{مفيش ركاب} =1{راكب واحد} =2{راكبين} few{{count} ركاب} other{{count} راكب}}'**
  String weekDriveLine(String direction, int count);

  /// No description provided for @weekEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أيام مشاوير الأسبوع ده.'**
  String get weekEmpty;

  /// No description provided for @verificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوثيق'**
  String get verificationTitle;

  /// No description provided for @percentValue.
  ///
  /// In ar, this message translates to:
  /// **'{percent}%'**
  String percentValue(int percent);

  /// No description provided for @trustedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لسه مفيش حد} =1{شخص واحد} =2{شخصين} few{{count} أشخاص} other{{count} شخص}}'**
  String trustedCount(int count);

  /// No description provided for @contactName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get contactName;

  /// No description provided for @removeContact.
  ///
  /// In ar, this message translates to:
  /// **'شيل {name}'**
  String removeContact(String name);

  /// No description provided for @arrivalInMin.
  ///
  /// In ar, this message translates to:
  /// **'الوصول بعد {minutes, plural, =1{دقيقة} =2{دقيقتين} few{{minutes} دقايق} other{{minutes} دقيقة}}'**
  String arrivalInMin(int minutes);

  /// No description provided for @mapLiveAria.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المشوار · السواق في الطريق'**
  String get mapLiveAria;

  /// No description provided for @demoDriverArrives.
  ///
  /// In ar, this message translates to:
  /// **'السواق وصل محطتي'**
  String get demoDriverArrives;

  /// No description provided for @shareNoTrip.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مشوار تشاركه دلوقتي.'**
  String get shareNoTrip;

  /// No description provided for @priceWithFee.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج للسواق + {fee} ج رسوم خدمة لجورة'**
  String priceWithFee(int price, int fee);

  /// No description provided for @priceNoFee.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج للسواق · من غير رسوم خدمة'**
  String priceNoFee(int price);

  /// No description provided for @priceSubscribed.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج · من غير رسوم (مشترك)'**
  String priceSubscribed(int price);

  /// No description provided for @priceCompany.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج · من غير رسوم (الشركة)'**
  String priceCompany(int price);

  /// No description provided for @priceCash.
  ///
  /// In ar, this message translates to:
  /// **'ادفع {price} ج كاش للسواق'**
  String priceCash(int price);

  /// No description provided for @payMethodTitle.
  ///
  /// In ar, this message translates to:
  /// **'هتدفع للسواق إزاي؟'**
  String get payMethodTitle;

  /// No description provided for @payMethodSub.
  ///
  /// In ar, this message translates to:
  /// **'بتدفع للسواق على طول. أول 5 مشاوير من غير رسوم جورة.'**
  String get payMethodSub;

  /// No description provided for @payCash.
  ///
  /// In ar, this message translates to:
  /// **'كاش'**
  String get payCash;

  /// No description provided for @payCashSub.
  ///
  /// In ar, this message translates to:
  /// **'إديها للسواق في العربية.'**
  String get payCashSub;

  /// No description provided for @payWallet.
  ///
  /// In ar, this message translates to:
  /// **'InstaPay'**
  String get payWallet;

  /// No description provided for @subscribeLink.
  ///
  /// In ar, this message translates to:
  /// **'اشترك ومن غير رسوم'**
  String get subscribeLink;

  /// No description provided for @subscribeCta.
  ///
  /// In ar, this message translates to:
  /// **'اشترك · {price} ج'**
  String subscribeCta(int price);

  /// No description provided for @subNeedsTopUp.
  ///
  /// In ar, this message translates to:
  /// **'اشحن {gap} ج الأول — محفظتك فيها {balance} ج.'**
  String subNeedsTopUp(int gap, int balance);

  /// No description provided for @subscribe.
  ///
  /// In ar, this message translates to:
  /// **'اشترك'**
  String get subscribe;

  /// No description provided for @planPayPerTrip.
  ///
  /// In ar, this message translates to:
  /// **'بالمشوار'**
  String get planPayPerTrip;

  /// No description provided for @planPerTripLine.
  ///
  /// In ar, this message translates to:
  /// **'{fee} ج رسوم خدمة على كل مشوار'**
  String planPerTripLine(int fee);

  /// No description provided for @planPerTripNoFeeLine.
  ///
  /// In ar, this message translates to:
  /// **'من غير رسوم خدمة على مشاويرك'**
  String get planPerTripNoFeeLine;

  /// No description provided for @planBundleLine.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{الباقة بتغطي رسوم مشوارك — فاضل مشوار واحد} =2{الباقة بتغطي رسوم مشاويرك — فاضل مشوارين} few{الباقة بتغطي رسوم مشاويرك — فاضل {count} مشاوير} other{الباقة بتغطي رسوم مشاويرك — فاضل {count} مشوار}}'**
  String planBundleLine(num count);

  /// No description provided for @planSubscribedLine.
  ///
  /// In ar, this message translates to:
  /// **'مشترك لحد {date} · من غير رسوم'**
  String planSubscribedLine(String date);

  /// No description provided for @planLapsedLine.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك خلص · رجعت بالمشوار'**
  String get planLapsedLine;

  /// No description provided for @cashTripsLeft.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{خلصت المشاوير اللي من غير رسوم} =1{فاضل مشوار واحد من غير رسوم} =2{فاضل مشوارين من غير رسوم} few{فاضل {count} مشاوير من غير رسوم} other{فاضل {count} مشوار من غير رسوم}}'**
  String cashTripsLeft(int count);

  /// No description provided for @cashTopUpBanner.
  ///
  /// In ar, this message translates to:
  /// **'بعد كده كل مشوار عليه رسوم خدمة صغيرة لجورة، أو اشترك ومتدفعش رسوم.'**
  String get cashTopUpBanner;

  /// No description provided for @cashEnded.
  ///
  /// In ar, this message translates to:
  /// **'المشاوير اللي من غير رسوم خلصت. كل مشوار دلوقتي عليه رسوم خدمة صغيرة لجورة.'**
  String get cashEnded;

  /// No description provided for @cashOff.
  ///
  /// In ar, this message translates to:
  /// **'المشاوير اللي من غير رسوم خلصت بعد ما مشوارين اتسجّلوا من غير دفع.'**
  String get cashOff;

  /// No description provided for @needsTopUp.
  ///
  /// In ar, this message translates to:
  /// **'اشحن عشان تكمّل مشاويرك'**
  String get needsTopUp;

  /// No description provided for @feeSavings.
  ///
  /// In ar, this message translates to:
  /// **'دفعت {fees} ج رسوم الشهر ده، الاشتراك بـ 149 ومعاه مكان مضمون وبديل لو السواق غاب.'**
  String feeSavings(int fees);

  /// No description provided for @actTrip.
  ///
  /// In ar, this message translates to:
  /// **'مشوار'**
  String get actTrip;

  /// No description provided for @actCashTrip.
  ///
  /// In ar, this message translates to:
  /// **'مشوار من غير رسوم'**
  String get actCashTrip;

  /// No description provided for @actSubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك'**
  String get actSubscription;

  /// No description provided for @cashPaidLine.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج للسواق على طول'**
  String cashPaidLine(int price);

  /// No description provided for @notChargedCash.
  ///
  /// In ar, this message translates to:
  /// **'مش محسوبة في فترة الكاش'**
  String get notChargedCash;

  /// No description provided for @breakdownShare.
  ///
  /// In ar, this message translates to:
  /// **'نصيب السواق'**
  String get breakdownShare;

  /// No description provided for @breakdownFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الخدمة'**
  String get breakdownFee;

  /// No description provided for @breakdownNoFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الخدمة: مفيش'**
  String get breakdownNoFee;

  /// No description provided for @cashReceived.
  ///
  /// In ar, this message translates to:
  /// **'استلمت {price} ج'**
  String cashReceived(int price);

  /// No description provided for @didNotPay.
  ///
  /// In ar, this message translates to:
  /// **'ماستلمتش'**
  String get didNotPay;

  /// No description provided for @cashMarkedReceived.
  ///
  /// In ar, this message translates to:
  /// **'وصل'**
  String get cashMarkedReceived;

  /// No description provided for @cashMarkedUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّل إنه مدفعش'**
  String get cashMarkedUnpaid;

  /// No description provided for @cashReceivedTitle.
  ///
  /// In ar, this message translates to:
  /// **'استلمته على طول الشهر ده'**
  String get cashReceivedTitle;

  /// No description provided for @cashReceivedNote.
  ///
  /// In ar, this message translates to:
  /// **'الركاب دفعوهولك. جورة مش بتمسكه.'**
  String get cashReceivedNote;

  /// No description provided for @needsTopUpBody.
  ///
  /// In ar, this message translates to:
  /// **'رصيدك أقل من تمن مشوار واحد ({total} ج).'**
  String needsTopUpBody(int total);

  /// No description provided for @priceDriver.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج ليك من كل راكب · جورة مجانية للسواقين'**
  String priceDriver(int price);

  /// No description provided for @seatsLeft.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فاضي كرسي واحد} =2{فاضي كرسيين} few{فاضي {count} كراسي} other{فاضي {count} كرسي}}'**
  String seatsLeft(int count);

  /// No description provided for @bookSeat.
  ///
  /// In ar, this message translates to:
  /// **'احجز الكرسي'**
  String get bookSeat;

  /// No description provided for @seatRule.
  ///
  /// In ar, this message translates to:
  /// **'المشتركين ليهم الأولوية في الكراسي الفاضية. لو مشترك أخد كرسيك قبل 9 بالليل اليوم اللي قبله، فلوسك كلها بترجعلك.'**
  String get seatRule;

  /// No description provided for @nothingFits.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة على ميعادك؟ انشر مشوارك'**
  String get nothingFits;

  /// No description provided for @alreadyRiding.
  ///
  /// In ar, this message translates to:
  /// **'إنت عندك توصيلة في المشوار ده خلاص.'**
  String get alreadyRiding;

  /// No description provided for @seatBookedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الكرسي اتحجز'**
  String get seatBookedTitle;

  /// No description provided for @upsellDaily.
  ///
  /// In ar, this message translates to:
  /// **'عجبك؟ خليه مشوارك كل يوم'**
  String get upsellDaily;

  /// No description provided for @backToToday.
  ///
  /// In ar, this message translates to:
  /// **'ارجع للنهارده'**
  String get backToToday;

  /// No description provided for @lateBookingNote.
  ///
  /// In ar, this message translates to:
  /// **'عدّت 9 بالليل اليوم اللي قبله، فلو لغيت دلوقتي هتدفع نص نصيبك.'**
  String get lateBookingNote;

  /// No description provided for @topUpFirst.
  ///
  /// In ar, this message translates to:
  /// **'اشحن {gap} ج الأول'**
  String topUpFirst(int gap);

  /// No description provided for @seatJustTaken.
  ///
  /// In ar, this message translates to:
  /// **'الكرسي ده لسه محجوز حالًا. دي القايمة بعد التحديث.'**
  String get seatJustTaken;

  /// No description provided for @justOnce.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get justOnce;

  /// No description provided for @everyWorkday.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم شغل'**
  String get everyWorkday;

  /// No description provided for @ruleNoBidding.
  ///
  /// In ar, this message translates to:
  /// **'السعر بتحدده جورة — مفيش فصال'**
  String get ruleNoBidding;

  /// No description provided for @ruleCostShare.
  ///
  /// In ar, this message translates to:
  /// **'السواق بيشارك في التكلفة، مش بيكسب'**
  String get ruleCostShare;

  /// No description provided for @ruleRoute.
  ///
  /// In ar, this message translates to:
  /// **'اللي على خطك بس هيشوفوه'**
  String get ruleRoute;

  /// No description provided for @post.
  ///
  /// In ar, this message translates to:
  /// **'انشر'**
  String get post;

  /// No description provided for @sentToDrivers.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{اتبعت لسواق واحد على خطك} =2{اتبعت لسواقين على خطك} few{اتبعت لـ{count} سواقين على خطك} other{اتبعت لـ{count} سواق على خطك}}'**
  String sentToDrivers(int count);

  /// No description provided for @waitingDriver.
  ///
  /// In ar, this message translates to:
  /// **'مستنيين سواق يوافق'**
  String get waitingDriver;

  /// No description provided for @cancelRequest.
  ///
  /// In ar, this message translates to:
  /// **'الغي الطلب'**
  String get cancelRequest;

  /// No description provided for @requestAccepted.
  ///
  /// In ar, this message translates to:
  /// **'سواق وافق على مشوارك'**
  String get requestAccepted;

  /// No description provided for @nowGroup.
  ///
  /// In ar, this message translates to:
  /// **'بقيتوا مجموعة مشوار'**
  String get nowGroup;

  /// No description provided for @requestExpired.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سواق أخد المشوار في ميعاده. محدش خصم منك حاجة.'**
  String get requestExpired;

  /// No description provided for @postAgain.
  ///
  /// In ar, this message translates to:
  /// **'انشر تاني'**
  String get postAgain;

  /// No description provided for @seeEmptySeats.
  ///
  /// In ar, this message translates to:
  /// **'شوف الكراسي الفاضية'**
  String get seeEmptySeats;

  /// No description provided for @dailyNeedsNoGroup.
  ///
  /// In ar, this message translates to:
  /// **'إنت في مجموعة يومية خلاص'**
  String get dailyNeedsNoGroup;

  /// No description provided for @verifyChip.
  ///
  /// In ar, this message translates to:
  /// **'{item} مش موثّق — وثّقه'**
  String verifyChip(String item);

  /// No description provided for @publish.
  ///
  /// In ar, this message translates to:
  /// **'انشر المشوار'**
  String get publish;

  /// No description provided for @dailyLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'خلصت مشاوير النهارده'**
  String get dailyLimitReached;

  /// No description provided for @joinsTripInstead.
  ///
  /// In ar, this message translates to:
  /// **'ده هيدخل على مشوارك الساعة {time}'**
  String joinsTripInstead(String time);

  /// No description provided for @seatsBooked.
  ///
  /// In ar, this message translates to:
  /// **'{booked} من {seats} كراسي اتحجزوا'**
  String seatsBooked(int booked, int seats);

  /// No description provided for @carFull.
  ///
  /// In ar, this message translates to:
  /// **'عربيتك اتملت!'**
  String get carFull;

  /// No description provided for @newRider.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newRider;

  /// No description provided for @cancelTrip.
  ///
  /// In ar, this message translates to:
  /// **'الغي المشوار'**
  String get cancelTrip;

  /// No description provided for @tripCancelledRefund.
  ///
  /// In ar, this message translates to:
  /// **'{driver} لغى المشوار. فلوسك كلها رجعتلك.'**
  String tripCancelledRefund(String driver);

  /// No description provided for @leavingFrom.
  ///
  /// In ar, this message translates to:
  /// **'طالع من'**
  String get leavingFrom;

  /// No description provided for @allAreas.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allAreas;

  /// No description provided for @morning.
  ///
  /// In ar, this message translates to:
  /// **'الصبح'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In ar, this message translates to:
  /// **'بالليل'**
  String get evening;

  /// No description provided for @createsTrip.
  ///
  /// In ar, this message translates to:
  /// **'ده هيعمل مشوار جديد: {route} · {time}. {count, plural, =0{مش هيفضلك مشاوير بعده} =1{هيفضلك مشوار واحد بعده} other{هيفضلك {count} مشاوير بعده}}'**
  String createsTrip(String route, String time, int count);

  /// No description provided for @doesntFit.
  ///
  /// In ar, this message translates to:
  /// **'مش على مشوارك'**
  String get doesntFit;

  /// No description provided for @yourCarFull.
  ///
  /// In ar, this message translates to:
  /// **'عربيتك مليانة'**
  String get yourCarFull;

  /// No description provided for @oneGroupOnly.
  ///
  /// In ar, this message translates to:
  /// **'إنت سايق مجموعة يومية خلاص'**
  String get oneGroupOnly;

  /// No description provided for @overlapTrip.
  ///
  /// In ar, this message translates to:
  /// **'عندك مشوار تاني في نفس الوقت'**
  String get overlapTrip;

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'وافق'**
  String get accept;

  /// No description provided for @accepted.
  ///
  /// In ar, this message translates to:
  /// **'اتوافق ✓'**
  String get accepted;

  /// No description provided for @demandBanner.
  ///
  /// In ar, this message translates to:
  /// **'{count} واحد عايزين {route} {part, select, morning{الصبح} evening{بالليل} other{}}'**
  String demandBanner(int count, String route, String part);

  /// No description provided for @detourMin.
  ///
  /// In ar, this message translates to:
  /// **'{min, plural, =1{+دقيقة لفّة} =2{+دقيقتين لفّة} few{+{min} دقايق لفّة} other{+{min} دقيقة لفّة}}'**
  String detourMin(int min);

  /// No description provided for @noRequests.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات على خطك دلوقتي. هنعرضها هنا أول ما توصل.'**
  String get noRequests;

  /// No description provided for @privacyCaption.
  ///
  /// In ar, this message translates to:
  /// **'هتشوف الأسامي لما الركاب يركبوا.'**
  String get privacyCaption;

  /// No description provided for @seatReclaimed.
  ///
  /// In ar, this message translates to:
  /// **'مشترك أخد كرسيك يوم {day}. رجعلك {amount} ج.'**
  String seatReclaimed(String day, int amount);

  /// No description provided for @seatReclaimedCash.
  ///
  /// In ar, this message translates to:
  /// **'مشترك أخد كرسيك يوم {day}. الكرسي مكانش عليه رسوم، فمفيش حاجة ترجعلك.'**
  String seatReclaimedCash(String day);

  /// No description provided for @reclaimTooLate.
  ///
  /// In ar, this message translates to:
  /// **'فات الميعاد — الحجز ده نهائي.'**
  String get reclaimTooLate;

  /// No description provided for @oneOffTrips.
  ///
  /// In ar, this message translates to:
  /// **'مشاوير مرة واحدة'**
  String get oneOffTrips;

  /// No description provided for @cancelBooking.
  ///
  /// In ar, this message translates to:
  /// **'الغي الحجز'**
  String get cancelBooking;

  /// No description provided for @noGroupYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مجموعة يومية'**
  String get noGroupYet;

  /// No description provided for @demoAcceptRequest.
  ///
  /// In ar, this message translates to:
  /// **'سواق يوافق على طلبك'**
  String get demoAcceptRequest;

  /// No description provided for @demoBookSeat.
  ///
  /// In ar, this message translates to:
  /// **'راكب يحجز كرسي'**
  String get demoBookSeat;

  /// No description provided for @demoReclaim.
  ///
  /// In ar, this message translates to:
  /// **'مشترك ياخد الكرسي ده'**
  String get demoReclaim;

  /// No description provided for @demoVerifyDriver.
  ///
  /// In ar, this message translates to:
  /// **'وثّق أوراق السواقة'**
  String get demoVerifyDriver;

  /// No description provided for @nSeatBooked.
  ///
  /// In ar, this message translates to:
  /// **'راكب حجز كرسي في مشوارك.'**
  String get nSeatBooked;

  /// No description provided for @nRequestAccepted.
  ///
  /// In ar, this message translates to:
  /// **'{driver} وافق على مشوارك الساعة {time}.'**
  String nRequestAccepted(String driver, String time);

  /// No description provided for @actSeatBooked.
  ///
  /// In ar, this message translates to:
  /// **'كرسي'**
  String get actSeatBooked;

  /// No description provided for @actSeatRefund.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع'**
  String get actSeatRefund;

  /// No description provided for @noSeatsOnRoute.
  ///
  /// In ar, this message translates to:
  /// **'مفيش كراسي فاضية على طريقك دلوقتي'**
  String get noSeatsOnRoute;

  /// No description provided for @seatPayFailed.
  ///
  /// In ar, this message translates to:
  /// **'الدفع ماتمّش. ومخدناش منك حاجة.'**
  String get seatPayFailed;

  /// No description provided for @seatChosen.
  ///
  /// In ar, this message translates to:
  /// **'اختيارك'**
  String get seatChosen;

  /// No description provided for @cancelFreeNote.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء ببلاش لحد 9 بالليل اليوم اللي قبله. بعدها بتدفع نص حصتك.'**
  String get cancelFreeNote;

  /// No description provided for @offerFromLabel.
  ///
  /// In ar, this message translates to:
  /// **'طالع من'**
  String get offerFromLabel;

  /// No description provided for @offerToLabel.
  ///
  /// In ar, this message translates to:
  /// **'رايح'**
  String get offerToLabel;

  /// No description provided for @offerTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد الخروج'**
  String get offerTimeLabel;

  /// No description provided for @riderPaysLine.
  ///
  /// In ar, this message translates to:
  /// **'الراكب بيدفع {amount} ج'**
  String riderPaysLine(int amount);

  /// No description provided for @dailyOfferNote.
  ///
  /// In ar, this message translates to:
  /// **'أول ما حد يحجز، المشوار ده بيبقى مجموعة يومية.'**
  String get dailyOfferNote;

  /// No description provided for @noRidersYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه محدش حجز. الركاب هيظهروا هنا أول ما يحجزوا.'**
  String get noRidersYet;

  /// No description provided for @tripDepartedState.
  ///
  /// In ar, this message translates to:
  /// **'المشوار ماشي. أسامي الركاب ظاهرة دلوقتي.'**
  String get tripDepartedState;

  /// No description provided for @tripDoneState.
  ///
  /// In ar, this message translates to:
  /// **'المشوار خلص.'**
  String get tripDoneState;

  /// No description provided for @tripCancelledState.
  ///
  /// In ar, this message translates to:
  /// **'إنت لغيت المشوار. كل راكب فلوسه كلها رجعتله.'**
  String get tripCancelledState;

  /// No description provided for @cancelTripConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تلغي المشوار؟ كل راكب فلوسه كلها هترجعله.'**
  String get cancelTripConfirm;

  /// No description provided for @keepTrip.
  ///
  /// In ar, this message translates to:
  /// **'سيب المشوار'**
  String get keepTrip;

  /// No description provided for @demoNothingToDo.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة تتعمل لسه. انشر مشوار الأول.'**
  String get demoNothingToDo;

  /// No description provided for @demoBookSeatFirst.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة تتعمل لسه. احجز كرسي فاضي الأول.'**
  String get demoBookSeatFirst;

  /// No description provided for @demoPostTripFirst.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة تتعمل لسه. انشر مشوارك الأول.'**
  String get demoPostTripFirst;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'شوف الكل'**
  String get seeAll;

  /// No description provided for @acceptConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، وافق'**
  String get acceptConfirm;

  /// No description provided for @requestWithdrawn.
  ///
  /// In ar, this message translates to:
  /// **'كان عليك فلوس لسواق لما سواق وافق، فالطلب اتلغى. ومخدناش منك حاجة.'**
  String get requestWithdrawn;

  /// No description provided for @requestGone.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده مبقاش مفتوح. دي القايمة بعد التحديث.'**
  String get requestGone;

  /// No description provided for @dailyBlockedNote.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم شغل مقفول وإنت راكب في مجموعة يومية.'**
  String get dailyBlockedNote;

  /// No description provided for @findRidersLink.
  ///
  /// In ar, this message translates to:
  /// **'أو دوّر على ركاب نشروا مشاويرهم'**
  String get findRidersLink;

  /// No description provided for @priceInstapay.
  ///
  /// In ar, this message translates to:
  /// **'ادفع {price} ج للسواق بـ InstaPay'**
  String priceInstapay(int price);

  /// No description provided for @payInstapaySub.
  ///
  /// In ar, this message translates to:
  /// **'حوّلها على InstaPay بتاع السواق بعد المشوار.'**
  String get payInstapaySub;

  /// No description provided for @owesDriver.
  ///
  /// In ar, this message translates to:
  /// **'عليك {amount} ج لـ {name}'**
  String owesDriver(int amount, String name);

  /// No description provided for @owesDriverBody.
  ///
  /// In ar, this message translates to:
  /// **'{name} سجّل إن نصيبك موصلش. ادفع لـ {name} الأول، وبعدها تقدر تحجز تاني.'**
  String owesDriverBody(String name);

  /// No description provided for @iPaid.
  ///
  /// In ar, this message translates to:
  /// **'دفعت'**
  String get iPaid;

  /// No description provided for @iPaidSent.
  ///
  /// In ar, this message translates to:
  /// **'بلّغنا {name} إنك دفعت. مستنيين يأكّد.'**
  String iPaidSent(String name);

  /// No description provided for @shareDisputed.
  ///
  /// In ar, this message translates to:
  /// **'{name} بيقول إنه دفع'**
  String shareDisputed(String name);

  /// No description provided for @shareAutoReceived.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد تلقائي'**
  String get shareAutoReceived;

  /// No description provided for @sharePending.
  ///
  /// In ar, this message translates to:
  /// **'مستني ردّك'**
  String get sharePending;

  /// No description provided for @shareChange.
  ///
  /// In ar, this message translates to:
  /// **'غيّر'**
  String get shareChange;

  /// No description provided for @paymentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'فلوس الركاب'**
  String get paymentsTitle;

  /// No description provided for @paymentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش. بعد كل مشوار أكّد كل راكب دفعلك ولا لأ.'**
  String get paymentsEmpty;

  /// No description provided for @feeOwed.
  ///
  /// In ar, this message translates to:
  /// **'عليك {amount} ج رسوم لجورة'**
  String feeOwed(int amount);

  /// No description provided for @instapayHandleLabel.
  ///
  /// In ar, this message translates to:
  /// **'حساب InstaPay بتاعك'**
  String get instapayHandleLabel;

  /// No description provided for @instapayHandleHint.
  ///
  /// In ar, this message translates to:
  /// **'الركاب هيشوفوه بس بعد ما الحجز يتأكد.'**
  String get instapayHandleHint;

  /// No description provided for @instapaySave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get instapaySave;

  /// No description provided for @instapaySaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ'**
  String get instapaySaved;

  /// No description provided for @instapayOfDriver.
  ///
  /// In ar, this message translates to:
  /// **'InstaPay بتاع {name}: {handle}'**
  String instapayOfDriver(String name, String handle);

  /// No description provided for @copyHandle.
  ///
  /// In ar, this message translates to:
  /// **'انسخ'**
  String get copyHandle;

  /// No description provided for @copiedHandle.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ'**
  String get copiedHandle;

  /// No description provided for @cashOnly.
  ///
  /// In ar, this message translates to:
  /// **'كاش بس'**
  String get cashOnly;

  /// No description provided for @feeOwedBody.
  ///
  /// In ar, this message translates to:
  /// **'ادفعها في أي وقت. لما توصل 150 ج، أو آخر الشهر من 30 ج، بتبقى مستحقة.'**
  String get feeOwedBody;

  /// No description provided for @feeDueLine.
  ///
  /// In ar, this message translates to:
  /// **'مستحقة من {date}. ادفعها خلال 3 أيام عشان تفضل تحجز.'**
  String feeDueLine(String date);

  /// No description provided for @feeOverdueBody.
  ///
  /// In ar, this message translates to:
  /// **'ادفعها عشان تقدر تحجز تاني. المشاوير اللي حجزتها ماشية عادي.'**
  String get feeOverdueBody;

  /// No description provided for @payNow.
  ///
  /// In ar, this message translates to:
  /// **'ادفع'**
  String get payNow;

  /// No description provided for @settleTitle.
  ///
  /// In ar, this message translates to:
  /// **'ادفع رسوم جورة'**
  String get settleTitle;

  /// No description provided for @settleConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ادفع {amount} ج'**
  String settleConfirm(int amount);

  /// No description provided for @settleFailTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدفع ماتمّش'**
  String get settleFailTitle;

  /// No description provided for @settleFailBody.
  ///
  /// In ar, this message translates to:
  /// **'مخدناش منك حاجة. جرّب تاني.'**
  String get settleFailBody;

  /// No description provided for @methodFawry.
  ///
  /// In ar, this message translates to:
  /// **'فوري'**
  String get methodFawry;

  /// No description provided for @fawryCode.
  ///
  /// In ar, this message translates to:
  /// **'كود فوري: {code}'**
  String fawryCode(String code);

  /// No description provided for @fawryPaid.
  ///
  /// In ar, this message translates to:
  /// **'دفعت في فوري'**
  String get fawryPaid;

  /// No description provided for @bundleTitle.
  ///
  /// In ar, this message translates to:
  /// **'باقة 20 مشوار'**
  String get bundleTitle;

  /// No description provided for @bundleSub.
  ///
  /// In ar, this message translates to:
  /// **'75 ج مرة واحدة. مبتخلصش أبداً، وبتغطي رسوم جورة بس، مش نصيب السواق.'**
  String get bundleSub;

  /// No description provided for @bundleLeft.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{خلصت مشاوير الباقة} =1{فاضل مشوار واحد في الباقة} =2{فاضل مشوارين في الباقة} few{فاضل {count} مشاوير في الباقة} other{فاضل {count} مشوار في الباقة}}'**
  String bundleLeft(int count);

  /// No description provided for @bundleBuy.
  ///
  /// In ar, this message translates to:
  /// **'اشتريها بـ 75 ج'**
  String get bundleBuy;

  /// No description provided for @actSettlement.
  ///
  /// In ar, this message translates to:
  /// **'دفع رسوم'**
  String get actSettlement;

  /// No description provided for @actBundle.
  ///
  /// In ar, this message translates to:
  /// **'باقة مشاوير'**
  String get actBundle;

  /// No description provided for @actBundleTrip.
  ///
  /// In ar, this message translates to:
  /// **'مشوار من الباقة'**
  String get actBundleTrip;

  /// No description provided for @idCheckTitle.
  ///
  /// In ar, this message translates to:
  /// **'التأكد من البطاقة'**
  String get idCheckTitle;

  /// No description provided for @idCheckSub.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين نتأكد من بطاقتك قبل أول مشوار، عشان أمان الكل.'**
  String get idCheckSub;

  /// No description provided for @idFront.
  ///
  /// In ar, this message translates to:
  /// **'صوّر وش البطاقة'**
  String get idFront;

  /// No description provided for @idBack.
  ///
  /// In ar, this message translates to:
  /// **'صوّر ضهر البطاقة'**
  String get idBack;

  /// No description provided for @idCaptured.
  ///
  /// In ar, this message translates to:
  /// **'اتصوّرت'**
  String get idCaptured;

  /// No description provided for @idSubmit.
  ///
  /// In ar, this message translates to:
  /// **'ابعتها للتأكيد'**
  String get idSubmit;

  /// No description provided for @idPending.
  ///
  /// In ar, this message translates to:
  /// **'بنراجع بطاقتك. هتقدر تحجز أول ما تتأكد.'**
  String get idPending;

  /// No description provided for @nCompanyPlanStarted.
  ///
  /// In ar, this message translates to:
  /// **'خطة {company} شغّالة: مشاويرك من غير رسوم جورة.'**
  String nCompanyPlanStarted(String company);

  /// No description provided for @nCompanyPlanEnded.
  ///
  /// In ar, this message translates to:
  /// **'خطة {company} خلصت. رسوم جورة على المشوار رجعت عادي.'**
  String nCompanyPlanEnded(String company);

  /// No description provided for @nCompanyPlanPaused.
  ///
  /// In ar, this message translates to:
  /// **'خطة شركتك متوقفة دلوقتي، رسوم جورة على المشوار رجعت عادي.'**
  String get nCompanyPlanPaused;

  /// No description provided for @nCompanyPlanResumed.
  ///
  /// In ar, this message translates to:
  /// **'خطة شركتك رجعت تشتغل: مشاويرك من غير رسوم جورة تاني.'**
  String get nCompanyPlanResumed;

  /// No description provided for @nPersonalPlanBack.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك رجعلك، وفاضل فيه {days} يوم.'**
  String nPersonalPlanBack(int days);

  /// No description provided for @companyAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب الشركة'**
  String get companyAccountTitle;

  /// No description provided for @companyAccountSub.
  ///
  /// In ar, this message translates to:
  /// **'سجّل شركتك لو إنت HR، أو شوف خطة شركتك'**
  String get companyAccountSub;

  /// No description provided for @companyRegisterCta.
  ///
  /// In ar, this message translates to:
  /// **'سجّل شركتك'**
  String get companyRegisterCta;

  /// No description provided for @companyRegisterIntro.
  ///
  /// In ar, this message translates to:
  /// **'إنت من HR؟ سجّل شركتك، وموظفينكم يركبوا من غير رسوم جورة.'**
  String get companyRegisterIntro;

  /// No description provided for @companyRegisterSub.
  ///
  /// In ar, this message translates to:
  /// **'هنتأكد من إيميل شغلك، وفريق جورة هيفعّل الحساب بعد ما العقد يتمضي.'**
  String get companyRegisterSub;

  /// No description provided for @companyNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get companyNameLabel;

  /// No description provided for @companyNameError.
  ///
  /// In ar, this message translates to:
  /// **'الاسم لازم يكون من 2 لـ 60 حرف'**
  String get companyNameError;

  /// No description provided for @companyWorkEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'إيميل شغلك'**
  String get companyWorkEmailLabel;

  /// No description provided for @companyEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب إيميل صحيح، زي name@company.com'**
  String get companyEmailInvalid;

  /// No description provided for @companyPublicDomain.
  ///
  /// In ar, this message translates to:
  /// **'{domain} إيميل عام أي حد يقدر يعمل عليه حساب. استخدم إيميل الشغل.'**
  String companyPublicDomain(String domain);

  /// No description provided for @companyDomainTaken.
  ///
  /// In ar, this message translates to:
  /// **'{domain} متسجّل لشركة تانية على جورة.'**
  String companyDomainTaken(String domain);

  /// No description provided for @companySendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعتلي كود'**
  String get companySendCode;

  /// No description provided for @companyCodeSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا كود لـ {email}'**
  String companyCodeSent(String email);

  /// No description provided for @companyCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكود'**
  String get companyCodeLabel;

  /// No description provided for @companySubmit.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الطلب'**
  String get companySubmit;

  /// No description provided for @companyStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'مستني موافقة جورة'**
  String get companyStatusPending;

  /// No description provided for @companyStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'شغّال'**
  String get companyStatusActive;

  /// No description provided for @companyStatusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'متوقف لحد الدفع'**
  String get companyStatusSuspended;

  /// No description provided for @companyStatusEnded.
  ///
  /// In ar, this message translates to:
  /// **'العقد خلص'**
  String get companyStatusEnded;

  /// No description provided for @companyPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'طلب {company} وصلنا. هنفعّل الحساب أول ما العقد يتمضي.'**
  String companyPendingBody(String company);

  /// No description provided for @companyDomainsLine.
  ///
  /// In ar, this message translates to:
  /// **'الدومين: {domains}'**
  String companyDomainsLine(String domains);

  /// No description provided for @companyMinSeats.
  ///
  /// In ar, this message translates to:
  /// **'أقل عدد في الفاتورة: {count} موظف'**
  String companyMinSeats(int count);

  /// No description provided for @companyPriceLine.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج لجورة عن كل موظف في الشهر'**
  String companyPriceLine(int amount);

  /// No description provided for @companyContractLine.
  ///
  /// In ar, this message translates to:
  /// **'العقد من {start} لـ {end}'**
  String companyContractLine(String start, String end);

  /// No description provided for @companyHomeNote.
  ///
  /// In ar, this message translates to:
  /// **'الشركة عمرها ما بتشوف مشاوير الموظفين ولا أماكن ركوبهم.'**
  String get companyHomeNote;

  /// No description provided for @companyMineTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة شركتك'**
  String get companyMineTitle;

  /// No description provided for @companyEnrolledLine.
  ///
  /// In ar, this message translates to:
  /// **'مشترك في خطة {company} من {date}'**
  String companyEnrolledLine(String company, String date);

  /// No description provided for @companyCanEnrollLine.
  ///
  /// In ar, this message translates to:
  /// **'{company} بتدفع رسوم جورة عنك على كل مشوار.'**
  String companyCanEnrollLine(String company);

  /// No description provided for @companyJoinCta.
  ///
  /// In ar, this message translates to:
  /// **'اشترك من خلال {company}'**
  String companyJoinCta(String company);

  /// No description provided for @companyNotOnGoora.
  ///
  /// In ar, this message translates to:
  /// **'شركتك لسه مش على جورة'**
  String get companyNotOnGoora;

  /// No description provided for @companyNotOnGooraBody.
  ///
  /// In ar, this message translates to:
  /// **'قول لـ HR بتاعكم عن جورة. لحد ما يشتركوا، تقدر تدفع بالمشوار أو تشترك لوحدك.'**
  String get companyNotOnGooraBody;

  /// No description provided for @companyTellHr.
  ///
  /// In ar, this message translates to:
  /// **'ابعت لـ HR بتاعكم'**
  String get companyTellHr;

  /// No description provided for @companyShareText.
  ///
  /// In ar, this message translates to:
  /// **'جورة بيجمّع زمايل الشغل في مشوار يومي واحد، وبيقسموا التكلفة. وفيه خطة للشركات: الشركة تدفع رسوم جورة، والموظفين يركبوا من غير رسوم. {link}'**
  String companyShareText(String link);

  /// No description provided for @consentTitle.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تشترك من خلال {company}'**
  String consentTitle(String company);

  /// No description provided for @consentSeesTitle.
  ///
  /// In ar, this message translates to:
  /// **'شركتك هتشوف'**
  String get consentSeesTitle;

  /// No description provided for @consentSeesName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get consentSeesName;

  /// No description provided for @consentSeesEmail.
  ///
  /// In ar, this message translates to:
  /// **'إيميل شغلك'**
  String get consentSeesEmail;

  /// No description provided for @consentSeesSince.
  ///
  /// In ar, this message translates to:
  /// **'من إمتى مشترك'**
  String get consentSeesSince;

  /// No description provided for @consentNeverTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمرها ما هتشوف'**
  String get consentNeverTitle;

  /// No description provided for @consentNeverTrips.
  ///
  /// In ar, this message translates to:
  /// **'مشاويرك ومواعيدها'**
  String get consentNeverTrips;

  /// No description provided for @consentNeverPlace.
  ///
  /// In ar, this message translates to:
  /// **'بيتك أو مكان ركوبك'**
  String get consentNeverPlace;

  /// No description provided for @consentNeverWho.
  ///
  /// In ar, this message translates to:
  /// **'مين راكب معاك'**
  String get consentNeverWho;

  /// No description provided for @consentNeverMoney.
  ///
  /// In ar, this message translates to:
  /// **'فلوسك أو اللي دفعته للسواق'**
  String get consentNeverMoney;

  /// No description provided for @consentFeeLine.
  ///
  /// In ar, this message translates to:
  /// **'رسوم جورة على مشاويرك هتبقى 0. نصيب السواق بتدفعه له زي ما هو.'**
  String get consentFeeLine;

  /// No description provided for @consentPausedLine.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك الشخصي (فاضل {days} يوم) هيتوقف، ويرجعلك لو سبت الشركة.'**
  String consentPausedLine(int days);

  /// No description provided for @consentAgree.
  ///
  /// In ar, this message translates to:
  /// **'موافق، اشترك'**
  String get consentAgree;

  /// No description provided for @consentDecline.
  ///
  /// In ar, this message translates to:
  /// **'مش دلوقتي'**
  String get consentDecline;

  /// No description provided for @planCompanyOf.
  ///
  /// In ar, this message translates to:
  /// **'شركة · {company}'**
  String planCompanyOf(String company);

  /// No description provided for @planCompanyPaused.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك الشخصي متوقف: فاضل {days} يوم، يرجعلك لو سبت الشركة.'**
  String planCompanyPaused(int days);

  /// No description provided for @companyLeave.
  ///
  /// In ar, this message translates to:
  /// **'سيب خطة الشركة'**
  String get companyLeave;

  /// No description provided for @companyLeaveTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسيب خطة {company}؟'**
  String companyLeaveTitle(String company);

  /// No description provided for @companyLeaveBody.
  ///
  /// In ar, this message translates to:
  /// **'من دلوقتي رسوم جورة هترجع على مشاويرك. المشاوير اللي فاتت مش هتتغير.'**
  String get companyLeaveBody;

  /// No description provided for @companyLeaveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، سيبها'**
  String get companyLeaveConfirm;

  /// No description provided for @demoApproveCompany.
  ///
  /// In ar, this message translates to:
  /// **'جورة توافق على شركتي'**
  String get demoApproveCompany;

  /// No description provided for @demoMakeMeHr.
  ///
  /// In ar, this message translates to:
  /// **'خليني HR بتاع Valeo'**
  String get demoMakeMeHr;

  /// No description provided for @companyInvoicesCta.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get companyInvoicesCta;

  /// No description provided for @companyInvoicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'فواتير الشركة'**
  String get companyInvoicesTitle;

  /// No description provided for @companyInvoicesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش فواتير. أول فاتورة بتتعمل أول الشهر الجاي.'**
  String get companyInvoicesEmpty;

  /// No description provided for @companyInvoiceMonthLabel.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة {month}'**
  String companyInvoiceMonthLabel(String month);

  /// No description provided for @companyInvoiceMath.
  ///
  /// In ar, this message translates to:
  /// **'{seats} موظف × {price} ج = {total} ج'**
  String companyInvoiceMath(int seats, int price, String total);

  /// No description provided for @companyInvoicePeak.
  ///
  /// In ar, this message translates to:
  /// **'أكتر عدد موظفين اتسجلوا في الشهر: {count}'**
  String companyInvoicePeak(int count);

  /// No description provided for @companyInvoicePaid.
  ///
  /// In ar, this message translates to:
  /// **'اتدفعت'**
  String get companyInvoicePaid;

  /// No description provided for @companyInvoiceWaiting.
  ///
  /// In ar, this message translates to:
  /// **'مستنية الدفع'**
  String get companyInvoiceWaiting;

  /// No description provided for @companyInvoiceOverdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get companyInvoiceOverdue;

  /// No description provided for @companyInvoiceDue.
  ///
  /// In ar, this message translates to:
  /// **'آخر ميعاد للدفع {date}'**
  String companyInvoiceDue(String date);

  /// No description provided for @companyInvoiceReferenceTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرقم ده في التحويل'**
  String get companyInvoiceReferenceTitle;

  /// No description provided for @companyInvoiceBankTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب جورة'**
  String get companyInvoiceBankTitle;

  /// No description provided for @companyInvoiceSuspendNote.
  ///
  /// In ar, this message translates to:
  /// **'لو الفاتورة لسه ماتدفعتش في {date}، خطة الشركة بتتوقف لحد الدفع، ورسوم جورة بترجع على مشاوير الموظفين.'**
  String companyInvoiceSuspendNote(String date);

  /// No description provided for @companyInvoicePaidOn.
  ///
  /// In ar, this message translates to:
  /// **'اتدفعت يوم {date} · مرجع البنك {ref}'**
  String companyInvoicePaidOn(String date, String ref);

  /// No description provided for @demoMarkInvoicePaid.
  ///
  /// In ar, this message translates to:
  /// **'جورة تأكد دفع الفاتورة'**
  String get demoMarkInvoicePaid;

  /// No description provided for @demoSkipToSuspension.
  ///
  /// In ar, this message translates to:
  /// **'قدّم الساعة لحد يوم إيقاف خطة الشركة'**
  String get demoSkipToSuspension;

  /// No description provided for @companyRosterCta.
  ///
  /// In ar, this message translates to:
  /// **'الموظفين المشتركين'**
  String get companyRosterCta;

  /// No description provided for @companyRosterTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموظفين المشتركين'**
  String get companyRosterTitle;

  /// No description provided for @companyRosterCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مشترك دلوقتي'**
  String companyRosterCount(int count);

  /// No description provided for @companyRosterNote.
  ///
  /// In ar, this message translates to:
  /// **'ده كل اللي الشركة بتشوفه: الاسم والإيميل ومن إمتى مشترك.'**
  String get companyRosterNote;

  /// No description provided for @companyRosterSince.
  ///
  /// In ar, this message translates to:
  /// **'مشترك من {date}'**
  String companyRosterSince(String date);

  /// No description provided for @companyRosterLeft.
  ///
  /// In ar, this message translates to:
  /// **'آخر يوم في الخطة: {date}'**
  String companyRosterLeft(String date);

  /// No description provided for @companyRosterEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش موظفين مشتركين لسه. قول لزمايلك يشتركوا من خلال الشركة من جورة.'**
  String get companyRosterEmpty;

  /// No description provided for @companyRosterRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل'**
  String get companyRosterRemove;

  /// No description provided for @companyRosterRemoveTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشيل {name} من خطة الشركة؟'**
  String companyRosterRemoveTitle(String name);

  /// No description provided for @companyRosterRemoveBody.
  ///
  /// In ar, this message translates to:
  /// **'من دلوقتي رسوم جورة هترجع على مشاويرهم، والمشاوير اللي فاتت مش هتتغير. هيتحسبوا في فاتورة الشهر ده.'**
  String get companyRosterRemoveBody;

  /// No description provided for @companyRosterRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، شيل'**
  String get companyRosterRemoveConfirm;

  /// No description provided for @companyLogCta.
  ///
  /// In ar, this message translates to:
  /// **'سجل التغييرات'**
  String get companyLogCta;

  /// No description provided for @companyLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التغييرات'**
  String get companyLogTitle;

  /// No description provided for @companyLogEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تغييرات لسه.'**
  String get companyLogEmpty;

  /// No description provided for @companyLogMeta.
  ///
  /// In ar, this message translates to:
  /// **'{actor} · {date}'**
  String companyLogMeta(String actor, String date);

  /// No description provided for @companyLogByHr.
  ///
  /// In ar, this message translates to:
  /// **'HR'**
  String get companyLogByHr;

  /// No description provided for @companyLogByEmployee.
  ///
  /// In ar, this message translates to:
  /// **'الموظف'**
  String get companyLogByEmployee;

  /// No description provided for @companyLogByGoora.
  ///
  /// In ar, this message translates to:
  /// **'جورة'**
  String get companyLogByGoora;

  /// No description provided for @companyLogApproved.
  ///
  /// In ar, this message translates to:
  /// **'الحساب اتفعّل'**
  String get companyLogApproved;

  /// No description provided for @companyLogDomainAdded.
  ///
  /// In ar, this message translates to:
  /// **'دومين اتضاف: {domain}'**
  String companyLogDomainAdded(String domain);

  /// No description provided for @companyLogDomainRemoved.
  ///
  /// In ar, this message translates to:
  /// **'دومين اتشال: {domain}'**
  String companyLogDomainRemoved(String domain);

  /// No description provided for @companyLogEmployeeRemoved.
  ///
  /// In ar, this message translates to:
  /// **'اتشال من الخطة: {name}'**
  String companyLogEmployeeRemoved(String name);

  /// No description provided for @companyLogEmployeeLeft.
  ///
  /// In ar, this message translates to:
  /// **'خرج من الخطة: {name}'**
  String companyLogEmployeeLeft(String name);

  /// No description provided for @companyLogInvoiceIssued.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة اتعملت: {month}'**
  String companyLogInvoiceIssued(String month);

  /// No description provided for @companyLogInvoicePaid.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة اتدفعت: {month}'**
  String companyLogInvoicePaid(String month);

  /// No description provided for @companyLogSuspended.
  ///
  /// In ar, this message translates to:
  /// **'الخطة اتوقفت لحد الدفع'**
  String get companyLogSuspended;

  /// No description provided for @companyLogResumed.
  ///
  /// In ar, this message translates to:
  /// **'الخطة رجعت تشتغل'**
  String get companyLogResumed;

  /// No description provided for @companyLogContractEnded.
  ///
  /// In ar, this message translates to:
  /// **'العقد خلص'**
  String get companyLogContractEnded;

  /// No description provided for @companyLogHrChanged.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول HR اتغيّر'**
  String get companyLogHrChanged;

  /// No description provided for @companyDomainsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدومينات'**
  String get companyDomainsTitle;

  /// No description provided for @companyDomainsNote.
  ///
  /// In ar, this message translates to:
  /// **'أي حد إيميل شغله على الدومينات دي يقدر يشترك من خلال الشركة.'**
  String get companyDomainsNote;

  /// No description provided for @companyAddDomain.
  ///
  /// In ar, this message translates to:
  /// **'ضيف دومين'**
  String get companyAddDomain;

  /// No description provided for @companyDomainLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدومين'**
  String get companyDomainLabel;

  /// No description provided for @companyDomainInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب دومين صحيح، زي company.com'**
  String get companyDomainInvalid;

  /// No description provided for @companyDomainAddCta.
  ///
  /// In ar, this message translates to:
  /// **'ضيف'**
  String get companyDomainAddCta;

  /// No description provided for @companyDomainRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل {domain}'**
  String companyDomainRemove(String domain);

  /// No description provided for @companyDomainRemoveTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشيل {domain}؟'**
  String companyDomainRemoveTitle(String domain);

  /// No description provided for @companyDomainRemoveBody.
  ///
  /// In ar, this message translates to:
  /// **'الموظفين المشتركين بإيميل على {domain} هيخرجوا من الخطة دلوقتي، ورسوم جورة هترجع على مشاويرهم.'**
  String companyDomainRemoveBody(String domain);

  /// No description provided for @demoEndContract.
  ///
  /// In ar, this message translates to:
  /// **'جورة تنهي عقد Valeo'**
  String get demoEndContract;

  /// No description provided for @demoHrLeft.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول HR بتاع Valeo ساب الشركة'**
  String get demoHrLeft;

  /// No description provided for @companyDashboardCta.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الشركة'**
  String get companyDashboardCta;

  /// No description provided for @companyDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'أرقام الشركة'**
  String get companyDashboardTitle;

  /// No description provided for @companyDashboardSoFar.
  ///
  /// In ar, this message translates to:
  /// **'{month} (لحد دلوقتي)'**
  String companyDashboardSoFar(String month);

  /// No description provided for @companyDashboardNote.
  ///
  /// In ar, this message translates to:
  /// **'أرقام إجمالية بس. مفيش اسم ولا مشوار ولا مكان ركوب لأي موظف.'**
  String get companyDashboardNote;

  /// No description provided for @companyDashboardEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام بتظهر أول ما الحساب يتفعّل.'**
  String get companyDashboardEmpty;

  /// No description provided for @companyDashboardFewer.
  ///
  /// In ar, this message translates to:
  /// **'أقل من 5'**
  String get companyDashboardFewer;

  /// No description provided for @companyDashboardFewerNote.
  ///
  /// In ar, this message translates to:
  /// **'أي رقم طالع من أقل من 5 موظفين بنخبّيه، عشان محدش يتعرف.'**
  String get companyDashboardFewerNote;

  /// No description provided for @companyDashboardEnrolled.
  ///
  /// In ar, this message translates to:
  /// **'موظفين مشتركين'**
  String get companyDashboardEnrolled;

  /// No description provided for @companyDashboardActive.
  ///
  /// In ar, this message translates to:
  /// **'موظفين نشطين الشهر ده'**
  String get companyDashboardActive;

  /// No description provided for @companyDashboardActiveMethod.
  ///
  /// In ar, this message translates to:
  /// **'نشط يعني ركب أو سوّق مشوار واحد على الأقل.'**
  String get companyDashboardActiveMethod;

  /// No description provided for @companyDashboardCarpool.
  ///
  /// In ar, this message translates to:
  /// **'نسبة المشاركة'**
  String get companyDashboardCarpool;

  /// No description provided for @companyDashboardCarpoolMethod.
  ///
  /// In ar, this message translates to:
  /// **'النشطين ÷ المشتركين.'**
  String get companyDashboardCarpoolMethod;

  /// No description provided for @companyDashboardGroups.
  ///
  /// In ar, this message translates to:
  /// **'مجموعات مشاوير فيها موظفين'**
  String get companyDashboardGroups;

  /// No description provided for @companyDashboardTrips.
  ///
  /// In ar, this message translates to:
  /// **'مشاوير اتشاركت'**
  String get companyDashboardTrips;

  /// No description provided for @companyDashboardTripsMethod.
  ///
  /// In ar, this message translates to:
  /// **'كل مشوار بيتعد مرة واحدة، حتى لو كذا موظف في العربية.'**
  String get companyDashboardTripsMethod;

  /// No description provided for @companyDashboardSaved.
  ///
  /// In ar, this message translates to:
  /// **'توفير تقديري'**
  String get companyDashboardSaved;

  /// No description provided for @companyDashboardSavedMethod.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة المشوار لو سقت لوحدك ناقص حصة الكرسي اللي اتدفعت. تقدير.'**
  String get companyDashboardSavedMethod;

  /// No description provided for @companyDashboardCo2.
  ///
  /// In ar, this message translates to:
  /// **'كربون اتوفّر (تقدير)'**
  String get companyDashboardCo2;

  /// No description provided for @companyDashboardCo2Method.
  ///
  /// In ar, this message translates to:
  /// **'الكيلومترات × 0.1645 كجم كربون للكيلو، متوسط عربية بنزين. تقدير مش قياس.'**
  String get companyDashboardCo2Method;

  /// No description provided for @companyDashboardKg.
  ///
  /// In ar, this message translates to:
  /// **'{kg} كجم'**
  String companyDashboardKg(String kg);

  /// No description provided for @companyDashboardMoney.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج'**
  String companyDashboardMoney(String amount);

  /// No description provided for @companyDashboardPercent.
  ///
  /// In ar, this message translates to:
  /// **'{pct}%'**
  String companyDashboardPercent(int pct);

  /// No description provided for @companyDashboardParking.
  ///
  /// In ar, this message translates to:
  /// **'أماكن ركن فاضية كل يوم شغل'**
  String get companyDashboardParking;

  /// No description provided for @companyDashboardParkingMethod.
  ///
  /// In ar, this message translates to:
  /// **'مشاوير الذهاب كراكب ÷ أيام الشغل (الأحد–الخميس). بنفترض إن كل راكب كان هيسوق لوحده.'**
  String get companyDashboardParkingMethod;

  /// No description provided for @companyDashboardGapsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مناطق فيها موظفين من غير مجموعة'**
  String get companyDashboardGapsTitle;

  /// No description provided for @companyDashboardGapRow.
  ///
  /// In ar, this message translates to:
  /// **'{area} · {count} موظف مستنيين'**
  String companyDashboardGapRow(String area, int count);

  /// No description provided for @companyDashboardGapsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش منطقة فيها 5 موظفين أو أكتر مستنيين مجموعة.'**
  String get companyDashboardGapsEmpty;

  /// No description provided for @companyHrShareTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابعت مشاويري لـ HR'**
  String get companyHrShareTitle;

  /// No description provided for @companyHrShareSees.
  ///
  /// In ar, this message translates to:
  /// **'الشركة هتشوف: اسمك، وتاريخ كل مشوار ركبته كراكب، الذهاب ولا الرجوع، والحصة اللي دفعتها للسواق. مش هتشوف مكان الركوب ولا الميعاد ولا السواق.'**
  String get companyHrShareSees;

  /// No description provided for @companyHrShareOffLine.
  ///
  /// In ar, this message translates to:
  /// **'مقفول. الشركة مش بتشوف مشاويرك.'**
  String get companyHrShareOffLine;

  /// No description provided for @companyHrShareOnLine.
  ///
  /// In ar, this message translates to:
  /// **'شغال. الشركة بتستلم كشف الشهر اللي فات أول كل شهر.'**
  String get companyHrShareOnLine;

  /// No description provided for @companyHrShareStopTitle.
  ///
  /// In ar, this message translates to:
  /// **'توقّف إرسال مشاويرك لـ HR؟'**
  String get companyHrShareStopTitle;

  /// No description provided for @companyHrShareStopBody.
  ///
  /// In ar, this message translates to:
  /// **'الكشوف اللي الشركة استلمتها قبل كده هتفضل زي ما هي. الكشف الجاي وأي كشف بعده مش هيشمل مشاويرك.'**
  String get companyHrShareStopBody;

  /// No description provided for @companyHrShareStopConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، وقّف'**
  String get companyHrShareStopConfirm;

  /// No description provided for @companyStatementCta.
  ///
  /// In ar, this message translates to:
  /// **'كشف المشاوير'**
  String get companyStatementCta;

  /// No description provided for @companyStatementTitle.
  ///
  /// In ar, this message translates to:
  /// **'كشف المشاوير الشهري'**
  String get companyStatementTitle;

  /// No description provided for @companyStatementNote.
  ///
  /// In ar, this message translates to:
  /// **'الموظفين اللي وافقوا يشاركوا مشاويرهم بس هما اللي بيظهروا هنا. أي حد تاني مش موجود، ولا حتى اسمه.'**
  String get companyStatementNote;

  /// No description provided for @companyStatementFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم جورة على المشاوير دي: {amount}. كل حصة اتدفعت للسواق على طول.'**
  String companyStatementFee(String amount);

  /// No description provided for @companyStatementPerson.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{مشوار واحد} =2{مشوارين} few{{count} مشاوير} other{{count} مشوار}} · {amount} ج للسواق'**
  String companyStatementPerson(int count, String amount);

  /// No description provided for @companyStatementShare.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج للسواق'**
  String companyStatementShare(String amount);

  /// No description provided for @companyStatementTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي حصص السواق: {amount} ج'**
  String companyStatementTotal(String amount);

  /// No description provided for @companyStatementEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش موظف وافق يشارك مشاويره في الشهر ده.'**
  String get companyStatementEmpty;

  /// No description provided for @companyStatementNoMonths.
  ///
  /// In ar, this message translates to:
  /// **'أول كشف بيظهر بعد ما أول شهر يخلص.'**
  String get companyStatementNoMonths;
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
