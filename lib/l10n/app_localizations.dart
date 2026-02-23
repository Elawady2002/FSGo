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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'في السكة'**
  String get appName;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @personalData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية'**
  String get personalData;

  /// No description provided for @mySubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكي'**
  String get mySubscription;

  /// No description provided for @wallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة والدفع'**
  String get wallet;

  /// No description provided for @walletBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد المحفظة'**
  String get walletBalance;

  /// No description provided for @rideHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الرحلات'**
  String get rideHistory;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @helpCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUs;

  /// No description provided for @termsAndConditions.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsAndConditions;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get chooseLanguage;

  /// No description provided for @upcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In ar, this message translates to:
  /// **'السابقة'**
  String get past;

  /// No description provided for @subscriptions.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراكات'**
  String get subscriptions;

  /// No description provided for @egp.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get egp;

  /// No description provided for @goodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير،'**
  String get goodMorning;

  /// No description provided for @friend.
  ///
  /// In ar, this message translates to:
  /// **'يا صديقي'**
  String get friend;

  /// No description provided for @activeSubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك النشط'**
  String get activeSubscription;

  /// No description provided for @nextTrip.
  ///
  /// In ar, this message translates to:
  /// **'رحلتك الجاية'**
  String get nextTrip;

  /// No description provided for @routePath.
  ///
  /// In ar, this message translates to:
  /// **'مسار الرحلة'**
  String get routePath;

  /// No description provided for @readyToBook.
  ///
  /// In ar, this message translates to:
  /// **'جاهز لحجز رحلتك الجديدة؟'**
  String get readyToBook;

  /// No description provided for @bookNow.
  ///
  /// In ar, this message translates to:
  /// **'احجز رحلتك'**
  String get bookNow;

  /// No description provided for @noBookedTrips.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رحلات محجوزة'**
  String get noBookedTrips;

  /// No description provided for @bookNowDescription.
  ///
  /// In ar, this message translates to:
  /// **'احجز رحلتك الجاية دلوقتي عشان تضمن مكانك'**
  String get bookNowDescription;

  /// No description provided for @confirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get confirmed;

  /// No description provided for @soon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get soon;

  /// No description provided for @tripRoute.
  ///
  /// In ar, this message translates to:
  /// **'مسار الرحلة'**
  String get tripRoute;

  /// No description provided for @guc.
  ///
  /// In ar, this message translates to:
  /// **'الجامعة الألمانية (GUC)'**
  String get guc;

  /// No description provided for @madinaty.
  ///
  /// In ar, this message translates to:
  /// **'مدينتي'**
  String get madinaty;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'امتى؟'**
  String get date;

  /// No description provided for @tripType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الرحلة'**
  String get tripType;

  /// No description provided for @departureOnly.
  ///
  /// In ar, this message translates to:
  /// **'إلى الجامعة'**
  String get departureOnly;

  /// No description provided for @returnOnly.
  ///
  /// In ar, this message translates to:
  /// **'من الجامعة'**
  String get returnOnly;

  /// No description provided for @roundTrip.
  ///
  /// In ar, this message translates to:
  /// **'رحلة'**
  String get roundTrip;

  /// No description provided for @addBooking.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حجز'**
  String get addBooking;

  /// No description provided for @editBooking.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الحجز'**
  String get editBooking;

  /// No description provided for @confirmSchedule.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الجدول'**
  String get confirmSchedule;

  /// No description provided for @bookings.
  ///
  /// In ar, this message translates to:
  /// **'الحجوزات'**
  String get bookings;

  /// No description provided for @noBookingOnThisDay.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حجز في هذا اليوم'**
  String get noBookingOnThisDay;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم غير مسجل الدخول'**
  String get userNotLoggedIn;

  /// No description provided for @selectDepartureTimeError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار ميعاد الذهاب'**
  String get selectDepartureTimeError;

  /// No description provided for @selectReturnTimeError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى اختيار ميعاد العودة'**
  String get selectReturnTimeError;

  /// No description provided for @clickToEditTimes.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتعديل المواعيد'**
  String get clickToEditTimes;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String errorOccurred(String error);

  /// No description provided for @bookYourTrip.
  ///
  /// In ar, this message translates to:
  /// **'احجز رحلتك'**
  String get bookYourTrip;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تسجيل الدخول أولاً'**
  String get pleaseLoginFirst;

  /// No description provided for @errorDeductingAmount.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء خصم المبلغ'**
  String get errorDeductingAmount;

  /// No description provided for @errorCreatingBooking.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إنشاء الحجز'**
  String get errorCreatingBooking;

  /// No description provided for @noTripsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رحلات متاحة لهذه الجامعة'**
  String get noTripsAvailable;

  /// No description provided for @tripTime.
  ///
  /// In ar, this message translates to:
  /// **'الرحلة الساعة كام؟'**
  String get tripTime;

  /// No description provided for @selectTripTime.
  ///
  /// In ar, this message translates to:
  /// **'اختار ميعاد الرحلة'**
  String get selectTripTime;

  /// No description provided for @successfullyBooked.
  ///
  /// In ar, this message translates to:
  /// **'تم الحجز بنجاح - {type}'**
  String successfullyBooked(String type);

  /// No description provided for @priceLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر: {price} ج.م'**
  String priceLabel(String price);

  /// No description provided for @errorLoadingTrips.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل الرحلات'**
  String get errorLoadingTrips;

  /// No description provided for @from.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get to;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @january.
  ///
  /// In ar, this message translates to:
  /// **'يناير'**
  String get january;

  /// No description provided for @february.
  ///
  /// In ar, this message translates to:
  /// **'فبراير'**
  String get february;

  /// No description provided for @march.
  ///
  /// In ar, this message translates to:
  /// **'مارس'**
  String get march;

  /// No description provided for @april.
  ///
  /// In ar, this message translates to:
  /// **'أبريل'**
  String get april;

  /// No description provided for @may.
  ///
  /// In ar, this message translates to:
  /// **'مايو'**
  String get may;

  /// No description provided for @june.
  ///
  /// In ar, this message translates to:
  /// **'يونيو'**
  String get june;

  /// No description provided for @july.
  ///
  /// In ar, this message translates to:
  /// **'يوليو'**
  String get july;

  /// No description provided for @august.
  ///
  /// In ar, this message translates to:
  /// **'أغسطس'**
  String get august;

  /// No description provided for @september.
  ///
  /// In ar, this message translates to:
  /// **'سبتمبر'**
  String get september;

  /// No description provided for @october.
  ///
  /// In ar, this message translates to:
  /// **'أكتوبر'**
  String get october;

  /// No description provided for @november.
  ///
  /// In ar, this message translates to:
  /// **'نوفمبر'**
  String get november;

  /// No description provided for @december.
  ///
  /// In ar, this message translates to:
  /// **'ديسمبر'**
  String get december;

  /// No description provided for @startDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get startDate;

  /// No description provided for @fromYourAreaTo.
  ///
  /// In ar, this message translates to:
  /// **'من منطقتك إلى {university}'**
  String fromYourAreaTo(String university);

  /// No description provided for @whereAreYouGoing.
  ///
  /// In ar, this message translates to:
  /// **'رايح فين؟'**
  String get whereAreYouGoing;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدينة'**
  String get selectCity;

  /// No description provided for @university.
  ///
  /// In ar, this message translates to:
  /// **'الجامعة'**
  String get university;

  /// No description provided for @selectUniversity.
  ///
  /// In ar, this message translates to:
  /// **'اختر الجامعة'**
  String get selectUniversity;

  /// No description provided for @pickupPoint.
  ///
  /// In ar, this message translates to:
  /// **'محطة الركوب'**
  String get pickupPoint;

  /// No description provided for @selectPickupPoint.
  ///
  /// In ar, this message translates to:
  /// **'اختر محطة الركوب'**
  String get selectPickupPoint;

  /// No description provided for @arrivalPoint.
  ///
  /// In ar, this message translates to:
  /// **'محطة الوصول'**
  String get arrivalPoint;

  /// No description provided for @selectArrivalPoint.
  ///
  /// In ar, this message translates to:
  /// **'اختر محطة الوصول'**
  String get selectArrivalPoint;

  /// No description provided for @emptyPickupStation.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محطة ركوب'**
  String get emptyPickupStation;

  /// No description provided for @emptyArrivalStation.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محطة وصول'**
  String get emptyArrivalStation;

  /// No description provided for @toUniversity.
  ///
  /// In ar, this message translates to:
  /// **'إلى الجامعة'**
  String get toUniversity;

  /// No description provided for @fromUniversity.
  ///
  /// In ar, this message translates to:
  /// **'من الجامعة'**
  String get fromUniversity;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @selectLocation.
  ///
  /// In ar, this message translates to:
  /// **'اختار موقعك'**
  String get selectLocation;

  /// No description provided for @selectLocationSub.
  ///
  /// In ar, this message translates to:
  /// **'حدد المدينة، الجامعة، والمحطة'**
  String get selectLocationSub;

  /// No description provided for @selectLocationSubAlt.
  ///
  /// In ar, this message translates to:
  /// **'حدد المدينة، محطة الركوب، والوصول'**
  String get selectLocationSubAlt;

  /// No description provided for @stationToStation.
  ///
  /// In ar, this message translates to:
  /// **'من موقف لموقف'**
  String get stationToStation;

  /// No description provided for @forUniversity.
  ///
  /// In ar, this message translates to:
  /// **'للجامعة'**
  String get forUniversity;

  /// No description provided for @station.
  ///
  /// In ar, this message translates to:
  /// **'المحطة'**
  String get station;

  /// No description provided for @pickupStation.
  ///
  /// In ar, this message translates to:
  /// **'موقف الركوب'**
  String get pickupStation;

  /// No description provided for @arrivalStation.
  ///
  /// In ar, this message translates to:
  /// **'موقف الوصول'**
  String get arrivalStation;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @continueText.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueText;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @scanQrCode.
  ///
  /// In ar, this message translates to:
  /// **'امسح الكود'**
  String get scanQrCode;

  /// No description provided for @noUpcomingRides.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رحلات قادمة'**
  String get noUpcomingRides;

  /// No description provided for @noPastRides.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رحلات سابقة'**
  String get noPastRides;

  /// No description provided for @noSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اشتراكات'**
  String get noSubscriptions;

  /// No description provided for @plan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get plan;

  /// No description provided for @daysRemaining.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المتبقية'**
  String get daysRemaining;

  /// No description provided for @departureTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التحرك'**
  String get departureTime;

  /// No description provided for @returnTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت العودة'**
  String get returnTime;

  /// No description provided for @errorLoadingData.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل البيانات'**
  String get errorLoadingData;

  /// No description provided for @insufficientBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد غير كافي'**
  String get insufficientBalance;

  /// No description provided for @insufficientBalanceDesc.
  ///
  /// In ar, this message translates to:
  /// **'رصيدك الحالي لا يكفي لإتمام العملية.\nيرجى شحن المحفظة للمتابعة.'**
  String get insufficientBalanceDesc;

  /// No description provided for @topUp.
  ///
  /// In ar, this message translates to:
  /// **'شحن الرصيد'**
  String get topUp;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get pending;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completed;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @underReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get underReview;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get day;

  /// No description provided for @selectStation.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحطة'**
  String get selectStation;

  /// No description provided for @departure.
  ///
  /// In ar, this message translates to:
  /// **'ذهاب'**
  String get departure;

  /// No description provided for @returnText.
  ///
  /// In ar, this message translates to:
  /// **'عودة'**
  String get returnText;

  /// No description provided for @selectDestination.
  ///
  /// In ar, this message translates to:
  /// **'اختار وجهتك'**
  String get selectDestination;

  /// No description provided for @now.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get now;

  /// No description provided for @bookingType.
  ///
  /// In ar, this message translates to:
  /// **'عايز تحجز ازاي؟'**
  String get bookingType;

  /// No description provided for @individualSeat.
  ///
  /// In ar, this message translates to:
  /// **'كرسي'**
  String get individualSeat;

  /// No description provided for @fullCar.
  ///
  /// In ar, this message translates to:
  /// **'المكروباص كله'**
  String get fullCar;

  /// No description provided for @seats.
  ///
  /// In ar, this message translates to:
  /// **'كراسي'**
  String get seats;

  /// No description provided for @passengerCount.
  ///
  /// In ar, this message translates to:
  /// **'انتو كام واحد؟'**
  String get passengerCount;

  /// No description provided for @preferences.
  ///
  /// In ar, this message translates to:
  /// **'عايزهم ازاي'**
  String get preferences;

  /// No description provided for @sameCar.
  ///
  /// In ar, this message translates to:
  /// **'في نفس العربية'**
  String get sameCar;

  /// No description provided for @splitCars.
  ///
  /// In ar, this message translates to:
  /// **'عربيات مختلفة'**
  String get splitCars;
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
