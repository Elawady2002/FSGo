// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fi El Sekka';

  @override
  String get profile => 'Profile';

  @override
  String get personalData => 'Personal Data';

  @override
  String get mySubscription => 'My Subscription';

  @override
  String get wallet => 'Wallet & Payments';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get logout => 'Logout';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get egp => 'EGP';

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get friend => 'Friend';

  @override
  String get activeSubscription => 'Active Subscription';

  @override
  String get nextTrip => 'Next Trip';

  @override
  String get routePath => 'Route Path';

  @override
  String get readyToBook => 'Ready to book your next trip?';

  @override
  String get bookNow => 'Book Now';

  @override
  String get noBookedTrips => 'No booked trips';

  @override
  String get bookNowDescription =>
      'Book your next trip now to secure your seat';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get soon => 'Soon';

  @override
  String get tripRoute => 'Trip Route';

  @override
  String get guc => 'German University (GUC)';

  @override
  String get madinaty => 'Madinaty';

  @override
  String get date => 'Date';

  @override
  String get tripType => 'Select Trip';

  @override
  String get departureOnly => 'To University';

  @override
  String get returnOnly => 'From University';

  @override
  String get roundTrip => 'Trip';

  @override
  String get addBooking => 'Add Booking';

  @override
  String get editBooking => 'Edit Booking';

  @override
  String get confirmSchedule => 'Confirm Schedule';

  @override
  String get bookings => 'Bookings';

  @override
  String get noBookingOnThisDay => 'No booking on this day';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get selectDepartureTimeError => 'Please select departure time';

  @override
  String get selectReturnTimeError => 'Please select return time';

  @override
  String get clickToEditTimes => 'Click to edit times';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get bookYourTrip => 'Book Your Trip';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get errorDeductingAmount => 'Error deducting amount';

  @override
  String get errorCreatingBooking => 'Error creating booking';

  @override
  String get noTripsAvailable => 'No trips available for this university';

  @override
  String get tripTime => 'Trip Time';

  @override
  String get selectTripTime => 'Select Trip Time';

  @override
  String successfullyBooked(String type) {
    return 'Successfully booked - $type';
  }

  @override
  String priceLabel(String price) {
    return 'Price: $price EGP';
  }

  @override
  String get errorLoadingTrips => 'Error loading trips';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get startDate => 'Start Date';

  @override
  String fromYourAreaTo(String university) {
    return 'From your area to $university';
  }

  @override
  String get whereAreYouGoing => 'Where are you going?';

  @override
  String get city => 'City';

  @override
  String get selectCity => 'Select city';

  @override
  String get university => 'University';

  @override
  String get selectUniversity => 'Select university';

  @override
  String get pickupPoint => 'Pickup Point';

  @override
  String get selectPickupPoint => 'Select pickup point';

  @override
  String get arrivalPoint => 'Arrival Point';

  @override
  String get selectArrivalPoint => 'Select arrival point';

  @override
  String get toUniversity => 'To University';

  @override
  String get fromUniversity => 'From University';

  @override
  String get next => 'Next';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get selectLocationSub => 'Select city, university, and station';

  @override
  String get selectLocationSubAlt => 'Select city, pickup station, and arrival';

  @override
  String get stationToStation => 'Station to Station';

  @override
  String get forUniversity => 'For University';

  @override
  String get station => 'Station';

  @override
  String get pickupStation => 'Pickup Station';

  @override
  String get arrivalStation => 'Arrival Station';

  @override
  String get loading => 'Loading...';

  @override
  String get continueText => 'Continue';

  @override
  String get error => 'Error';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get noUpcomingRides => 'No upcoming rides';

  @override
  String get noPastRides => 'No past rides';

  @override
  String get noSubscriptions => 'No subscriptions';

  @override
  String get plan => 'Plan';

  @override
  String get daysRemaining => 'Days Remaining';

  @override
  String get departureTime => 'Departure Time';

  @override
  String get returnTime => 'Return Time';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get insufficientBalance => 'Insufficient Balance';

  @override
  String get insufficientBalanceDesc =>
      'Your current balance is not enough to complete the operation.\nPlease top up your wallet to continue.';

  @override
  String get topUp => 'Top Up';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get active => 'Active';

  @override
  String get underReview => 'Under Review';

  @override
  String get expired => 'Expired';

  @override
  String get day => 'Day';

  @override
  String get selectStation => 'Select Station';

  @override
  String get departure => 'Departure';

  @override
  String get returnText => 'Return';

  @override
  String get selectDestination => 'Select Destination';

  @override
  String get now => 'Now';

  @override
  String get bookingType => 'Booking Type';

  @override
  String get individualSeat => 'Individual Seat';

  @override
  String get fullCar => 'Full Microbus';

  @override
  String get seats => 'Seats';

  @override
  String get passengerCount => 'Passenger Count';

  @override
  String get preferences => 'Preferences';

  @override
  String get sameCar => 'Same Car';

  @override
  String get splitCars => 'Split Cars';
}
