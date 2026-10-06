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

  /// No description provided for @planSubline.
  ///
  /// In ar, this message translates to:
  /// **'تدفع لأول مرة بعد ما نلقى جروبك — ولقيناه.'**
  String get planSubline;

  /// No description provided for @planMonthlyTitle.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get planMonthlyTitle;

  /// No description provided for @planMonthlySub.
  ///
  /// In ar, this message translates to:
  /// **'129 جنيه/الشهر'**
  String get planMonthlySub;

  /// No description provided for @planYearlyTitle.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get planYearlyTitle;

  /// No description provided for @planYearlySub.
  ///
  /// In ar, this message translates to:
  /// **'1,290 جنيه/السنة'**
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

  /// No description provided for @planCtaStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الشهر المجاني'**
  String get planCtaStart;

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
  /// **'{count, plural, =0{لسه مش بيغطي أي رحلة} =1{بيغطي حوالي رحلة واحدة} other{بيغطي حوالي {count} رحلات}}'**
  String coversTrips(int count);

  /// No description provided for @planChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get planChange;

  /// No description provided for @planFreeUntil.
  ///
  /// In ar, this message translates to:
  /// **'مجاني لحد {date} · بعدها {price} جنيه/الشهر'**
  String planFreeUntil(String date, int price);

  /// No description provided for @planActiveLine.
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة · {price} جنيه/الشهر'**
  String planActiveLine(int price);

  /// No description provided for @planCompanyActive.
  ///
  /// In ar, this message translates to:
  /// **'مجانية · شركتك بتدفعها'**
  String get planCompanyActive;

  /// No description provided for @planDueTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك محتاجة تجديد'**
  String get planDueTitle;

  /// No description provided for @planDueBody.
  ///
  /// In ar, this message translates to:
  /// **'اشحن محفظتك أو حوّل لخطة الشركة علشان مكانك يفضل متأكد.'**
  String get planDueBody;

  /// No description provided for @howPayTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزاي الدفع بيشتغل'**
  String get howPayTitle;

  /// No description provided for @howPayRule1.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك بيغطي ترشيح الجروب والسواق البديل وأدوات الأمان.'**
  String get howPayRule1;

  /// No description provided for @howPayRule2.
  ///
  /// In ar, this message translates to:
  /// **'البنزين والرسوم بتروح كلها للسواق على طول — جورة مالهاش نسبة.'**
  String get howPayRule2;

  /// No description provided for @howPayRule3.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء المتأخر والغياب من غير اعتذار بتدفعهم من محفظتك.'**
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
  /// **'بتدفع كام في الرحلة'**
  String get breakdownTitle;

  /// No description provided for @breakdownFuel.
  ///
  /// In ar, this message translates to:
  /// **'البنزين والرسوم'**
  String get breakdownFuel;

  /// No description provided for @breakdownFees.
  ///
  /// In ar, this message translates to:
  /// **'رسوم جورة: ضمن اشتراكك'**
  String get breakdownFees;

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

  /// No description provided for @recoveredTitle.
  ///
  /// In ar, this message translates to:
  /// **'اتجمّع الأسبوع ده'**
  String get recoveredTitle;

  /// No description provided for @payoutNote.
  ///
  /// In ar, this message translates to:
  /// **'بيتصرف كل خميس · من غير أي رسوم عليك'**
  String get payoutNote;

  /// No description provided for @withdraw.
  ///
  /// In ar, this message translates to:
  /// **'اسحب على InstaPay'**
  String get withdraw;

  /// No description provided for @withdrawSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسحب على InstaPay'**
  String get withdrawSheetTitle;

  /// No description provided for @withdrawConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أكّد السحب'**
  String get withdrawConfirm;

  /// No description provided for @withdrawFailTitle.
  ///
  /// In ar, this message translates to:
  /// **'السحب ملحقش يتم'**
  String get withdrawFailTitle;

  /// No description provided for @withdrawFailBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة تحرّكت — جرّب تاني.'**
  String get withdrawFailBody;

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
