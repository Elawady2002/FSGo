// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'في السكة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get personalData => 'البيانات الشخصية';

  @override
  String get mySubscription => 'اشتراكي';

  @override
  String get wallet => 'المحفظة والدفع';

  @override
  String get walletBalance => 'رصيد المحفظة';

  @override
  String get rideHistory => 'سجل الرحلات';

  @override
  String get language => 'اللغة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get upcoming => 'القادمة';

  @override
  String get past => 'السابقة';

  @override
  String get subscriptions => 'الاشتراكات';

  @override
  String get egp => 'ج.م';

  @override
  String get goodMorning => 'صباح الخير،';

  @override
  String get friend => 'يا صديقي';

  @override
  String get activeSubscription => 'اشتراكك النشط';

  @override
  String get nextTrip => 'رحلتك الجاية';

  @override
  String get routePath => 'مسار الرحلة';

  @override
  String get readyToBook => 'جاهز لحجز رحلتك الجديدة؟';

  @override
  String get bookNow => 'احجز رحلتك';

  @override
  String get noBookedTrips => 'لا توجد رحلات محجوزة';

  @override
  String get bookNowDescription => 'احجز رحلتك الجاية دلوقتي عشان تضمن مكانك';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get soon => 'قريباً';

  @override
  String get date => 'التاريخ';

  @override
  String get tripType => 'نوع الرحلة';

  @override
  String get departureOnly => 'ذهاب فقط';

  @override
  String get returnOnly => 'عودة فقط';

  @override
  String get roundTrip => 'ذهاب وعودة';

  @override
  String priceLabel(String price) {
    return 'السعر: $price ج.م';
  }

  @override
  String get errorLoadingTrips => 'حدث خطأ في تحميل الرحلات';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get cancel => 'إلغاء';

  @override
  String get done => 'تم';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String fromYourAreaTo(String university) {
    return 'من منطقتك إلى $university';
  }

  @override
  String get whereAreYouGoing => 'رايح فين؟';

  @override
  String get city => 'المدينة';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get university => 'الجامعة';

  @override
  String get selectUniversity => 'اختر الجامعة';

  @override
  String get pickupPoint => 'نقطة الركوب';

  @override
  String get selectPickupPoint => 'اختر نقطة الركوب';

  @override
  String get arrivalPoint => 'نقطة الوصول';

  @override
  String get selectArrivalPoint => 'اختر نقطة الوصول';

  @override
  String get toUniversity => 'إلى الجامعة';

  @override
  String get fromUniversity => 'من الجامعة';

  @override
  String get next => 'التالي';

  @override
  String get selectLocation => 'اختار موقعك';

  @override
  String get selectLocationSub => 'حدد المدينة، الجامعة، والمحطة';

  @override
  String get selectLocationSubAlt => 'حدد المدينة، محطة الركوب، والوصول';

  @override
  String get stationToStation => 'من موقف لموقف';

  @override
  String get forUniversity => 'للجامعة';

  @override
  String get station => 'المحطة';

  @override
  String get pickupStation => 'موقف الركوب';

  @override
  String get arrivalStation => 'موقف الوصول';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get continueText => 'متابعة';

  @override
  String get madinaty => 'مدينتي';

  @override
  String get guc => 'الجامعة الألمانية (GUC)';

  @override
  String get error => 'خطأ';

  @override
  String get noUpcomingRides => 'لا توجد رحلات قادمة';

  @override
  String get noPastRides => 'لا توجد رحلات سابقة';

  @override
  String get noSubscriptions => 'لا توجد اشتراكات';

  @override
  String get plan => 'الخطة';

  @override
  String get daysRemaining => 'الأيام المتبقية';

  @override
  String get departureTime => 'وقت التحرك';

  @override
  String get returnTime => 'وقت العودة';

  @override
  String get errorLoadingData => 'حدث خطأ في تحميل البيانات';

  @override
  String get insufficientBalance => 'رصيد غير كافي';

  @override
  String get insufficientBalanceDesc =>
      'رصيدك الحالي لا يكفي لإتمام العملية.\nيرجى شحن المحفظة للمتابعة.';

  @override
  String get topUp => 'شحن الرصيد';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get cancelled => 'ملغي';

  @override
  String get completed => 'مكتمل';

  @override
  String get active => 'نشط';

  @override
  String get underReview => 'قيد المراجعة';

  @override
  String get expired => 'منتهي';

  @override
  String get day => 'يوم';

  @override
  String get selectStation => 'اختر المحطة';

  @override
  String get departure => 'ذهاب';

  @override
  String get returnText => 'عودة';
}
