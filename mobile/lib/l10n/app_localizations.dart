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

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @savedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItems;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @navigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation Error'**
  String get navigationError;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @searchingArea.
  ///
  /// In en, this message translates to:
  /// **'Searching area...'**
  String get searchingArea;

  /// No description provided for @fitnessCenter.
  ///
  /// In en, this message translates to:
  /// **'Fitness Center'**
  String get fitnessCenter;

  /// No description provided for @healthyFood.
  ///
  /// In en, this message translates to:
  /// **'Healthy Food'**
  String get healthyFood;

  /// No description provided for @personalTrainer.
  ///
  /// In en, this message translates to:
  /// **'Personal Trainer'**
  String get personalTrainer;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @aboutGym.
  ///
  /// In en, this message translates to:
  /// **'About the Gym'**
  String get aboutGym;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @errorLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details'**
  String get errorLoadingDetails;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @crowdLow.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get crowdLow;

  /// No description provided for @crowdMedium.
  ///
  /// In en, this message translates to:
  /// **'A bit Crowded'**
  String get crowdMedium;

  /// No description provided for @crowdHigh.
  ///
  /// In en, this message translates to:
  /// **'Very Crowded'**
  String get crowdHigh;

  /// No description provided for @liveStatus.
  ///
  /// In en, this message translates to:
  /// **'Live Status'**
  String get liveStatus;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @viewAllReviews.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllReviews;

  /// No description provided for @earnPoints.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get earnPoints;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @temporarilyClosed.
  ///
  /// In en, this message translates to:
  /// **'Temporarily Closed'**
  String get temporarilyClosed;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search gyms, trainers...'**
  String get searchPlaces;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @highestRating.
  ///
  /// In en, this message translates to:
  /// **'Highest Rating'**
  String get highestRating;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @trainer.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get trainer;

  /// No description provided for @cityOrRegion.
  ///
  /// In en, this message translates to:
  /// **'City / Region'**
  String get cityOrRegion;

  /// No description provided for @searchRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'Search Radius (km)'**
  String get searchRadiusKm;

  /// No description provided for @specialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get specialties;

  /// No description provided for @dietaryOptions.
  ///
  /// In en, this message translates to:
  /// **'Dietary Options'**
  String get dietaryOptions;

  /// No description provided for @equipmentCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get equipmentCategories;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get selectRegion;

  /// No description provided for @allRegions.
  ///
  /// In en, this message translates to:
  /// **'All Regions'**
  String get allRegions;

  /// No description provided for @locationWarningText.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services for better results'**
  String get locationWarningText;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @gyms.
  ///
  /// In en, this message translates to:
  /// **'Gyms'**
  String get gyms;

  /// No description provided for @trainers.
  ///
  /// In en, this message translates to:
  /// **'Trainers'**
  String get trainers;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @filtersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Filters'**
  String filtersCount(Object count);

  /// No description provided for @anyDistance.
  ///
  /// In en, this message translates to:
  /// **'Any Distance'**
  String get anyDistance;

  /// No description provided for @anyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any Price'**
  String get anyPrice;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All (+{count})'**
  String showAll(Object count);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @maxPriceLimit.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPriceLimit;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get nameRequired;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name (3-50 letters, no symbols)'**
  String get invalidName;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 chars, include uppercase, lowercase, number, and symbol'**
  String get invalidPassword;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @verifyingEmail.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email'**
  String get verifyingEmail;

  /// No description provided for @verificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email Verified Successfully'**
  String get verificationSuccess;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// No description provided for @invalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid or missing verification token'**
  String get invalidToken;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goHome;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we secure your account'**
  String get pleaseWait;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To ensure a safe environment and comply with gym regulations, please verify your identity. This one-time step is required to activate your membership.'**
  String get completeProfileSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'05XXXXXXXX'**
  String get phoneNumberHint;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Saudi phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @idCardImage.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get idCardImage;

  /// No description provided for @uploadIdCard.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload ID'**
  String get uploadIdCard;

  /// No description provided for @faceImage.
  ///
  /// In en, this message translates to:
  /// **'Face Photo'**
  String get faceImage;

  /// No description provided for @uploadFaceImage.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie'**
  String get uploadFaceImage;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full address'**
  String get addressHint;

  /// No description provided for @submitProfile.
  ///
  /// In en, this message translates to:
  /// **'Submit Profile'**
  String get submitProfile;

  /// No description provided for @imagesRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Both ID and Face images are required'**
  String get imagesRequiredError;

  /// No description provided for @locationFetched.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationFetched;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Get current location'**
  String get refreshLocation;

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please login or create an account to proceed with your subscription.'**
  String get authRequiredSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @registrationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registrationSuccessTitle;

  /// No description provided for @registrationSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification link to your email. Please check your inbox and click the link to activate your account.'**
  String get registrationSuccessMsg;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @awaitingVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get awaitingVerificationTitle;

  /// No description provided for @awaitingVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to your email. Please check your inbox and click the link to activate your account.'**
  String get awaitingVerificationSubtitle;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend Link'**
  String get resendLink;

  /// No description provided for @resendLinkCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend Link in {seconds}s'**
  String resendLinkCooldown(Object seconds);

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent successfully.'**
  String get verificationSent;

  /// No description provided for @profileIncompleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Email verified! Please complete your profile later to purchase subscriptions.'**
  String get profileIncompleteWarning;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @enterOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterOtpTitle;

  /// No description provided for @enterOtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to {email}. Please enter it below.'**
  String enterOtpSubtitle(Object email);

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccount;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get invalidOtp;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get otpHint;

  /// No description provided for @fetchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Fetching your address...'**
  String get fetchingAddress;

  /// No description provided for @searchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search for city, street, or neighborhood...'**
  String get searchLocationHint;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @useThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Use this address'**
  String get useThisAddress;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your FitZone account to continue your fitness journey.'**
  String get loginSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredError;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to unlock all features'**
  String get loginToContinue;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;
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
