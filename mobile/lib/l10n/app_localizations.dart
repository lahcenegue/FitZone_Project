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

  /// No description provided for @loyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get loyaltyPoints;

  /// No description provided for @pointsToPremium.
  ///
  /// In en, this message translates to:
  /// **'Earn more points to reach the Premium tier!'**
  String get pointsToPremium;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get mySubscriptions;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @supportAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Support & About'**
  String get supportAndAbout;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @activePlans.
  ///
  /// In en, this message translates to:
  /// **'Active Plans'**
  String get activePlans;

  /// No description provided for @membership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membership;

  /// No description provided for @basicMembership.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basicMembership;

  /// No description provided for @loyaltyOverview.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Overview'**
  String get loyaltyOverview;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pts;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection and try again.'**
  String get noInternetMessage;

  /// No description provided for @locationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get locationRequiredTitle;

  /// No description provided for @locationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'FitZone requires your location to find nearby gyms and services.'**
  String get locationRequiredMessage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @enableLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationButton;

  /// No description provided for @locationTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not detect exact location. Redirecting to map to browse manually.'**
  String get locationTimeoutMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address to receive a password reset code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email and your new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully. You can now login.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'If an account is associated with this email, a reset code has been sent.'**
  String get resetCodeSent;

  /// No description provided for @verifyAndReset.
  ///
  /// In en, this message translates to:
  /// **'Verify & Reset Password'**
  String get verifyAndReset;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request to server was cancelled.'**
  String get errorRequestCancelled;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout with server.'**
  String get errorConnectionTimeout;

  /// No description provided for @errorReceiveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receive timeout in connection with server.'**
  String get errorReceiveTimeout;

  /// No description provided for @errorSendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Send timeout in connection with server.'**
  String get errorSendTimeout;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoInternet;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnexpected;

  /// No description provided for @errorUnknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown status code error.'**
  String get errorUnknownStatus;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad request.'**
  String get errorBadRequest;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access. Please login again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden access.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Validation error.'**
  String get errorValidation;

  /// No description provided for @errorInternalServer.
  ///
  /// In en, this message translates to:
  /// **'Internal server error. Please try again later.'**
  String get errorInternalServer;

  /// No description provided for @errorBadGateway.
  ///
  /// In en, this message translates to:
  /// **'Bad gateway.'**
  String get errorBadGateway;

  /// No description provided for @errorOops.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong.'**
  String get errorOops;

  /// No description provided for @avatarUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully!'**
  String get avatarUpdatedSuccessfully;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @emailChangedWarning.
  ///
  /// In en, this message translates to:
  /// **'Email changed. Please verify it to continue.'**
  String get emailChangedWarning;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChangedSuccessfully;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account has been permanently deleted.'**
  String get accountDeletedSuccessfully;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get oldPassword;

  /// No description provided for @oldPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get oldPasswordRequired;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, subscriptions, and points will be permanently erased from our servers.'**
  String get deleteAccountWarningMessage;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Yes, Permanently Delete My Account'**
  String get confirmDeleteAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Action'**
  String get cancel;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new secure password to protect your account.'**
  String get changePasswordSubtitle;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Subscription activated!'**
  String get paymentSuccess;

  /// No description provided for @activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeSubscription;

  /// No description provided for @expiredSubscription.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredSubscription;

  /// No description provided for @scanQrToEnter.
  ///
  /// In en, this message translates to:
  /// **'Scan QR at the gate to enter'**
  String get scanQrToEnter;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get validUntil;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @noSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'You have no active subscriptions.'**
  String get noSubscriptions;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetails;

  /// No description provided for @validity.
  ///
  /// In en, this message translates to:
  /// **'Validity Period'**
  String get validity;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get daysRemaining;

  /// No description provided for @gymLocation.
  ///
  /// In en, this message translates to:
  /// **'Gym Location'**
  String get gymLocation;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @subscriptionProgress.
  ///
  /// In en, this message translates to:
  /// **'Subscription Progress'**
  String get subscriptionProgress;

  /// No description provided for @men.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get men;

  /// No description provided for @women.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get women;

  /// No description provided for @menSchedule.
  ///
  /// In en, this message translates to:
  /// **'Men Schedule'**
  String get menSchedule;

  /// No description provided for @womenSchedule.
  ///
  /// In en, this message translates to:
  /// **'Women Schdule'**
  String get womenSchedule;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No Reviews Yet'**
  String get noReviewsYet;

  /// No description provided for @beFirstToReview.
  ///
  /// In en, this message translates to:
  /// **'Be first to review'**
  String get beFirstToReview;

  /// No description provided for @otherBranches.
  ///
  /// In en, this message translates to:
  /// **'Other Branches'**
  String get otherBranches;

  /// No description provided for @nearbyGyms.
  ///
  /// In en, this message translates to:
  /// **'Nearby Gyms'**
  String get nearbyGyms;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @menOnly.
  ///
  /// In en, this message translates to:
  /// **'Men Only'**
  String get menOnly;

  /// No description provided for @womenOnly.
  ///
  /// In en, this message translates to:
  /// **'Women Only'**
  String get womenOnly;

  /// No description provided for @menAndWomen.
  ///
  /// In en, this message translates to:
  /// **'Men & Women'**
  String get menAndWomen;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsCount;

  /// No description provided for @distanceFromYou.
  ///
  /// In en, this message translates to:
  /// **'From you'**
  String get distanceFromYou;

  /// No description provided for @gymAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get gymAllocation;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @walletAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Rewards'**
  String get walletAndRewards;

  /// No description provided for @financialWallet.
  ///
  /// In en, this message translates to:
  /// **'Financial Wallet'**
  String get financialWallet;

  /// No description provided for @pointsWallet.
  ///
  /// In en, this message translates to:
  /// **'Points Wallet'**
  String get pointsWallet;

  /// No description provided for @fiatBalance.
  ///
  /// In en, this message translates to:
  /// **'Fiat Balance'**
  String get fiatBalance;

  /// No description provided for @withdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFunds;

  /// No description provided for @addBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Account'**
  String get addBankAccount;

  /// No description provided for @linkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked Account'**
  String get linkedAccount;

  /// No description provided for @transactionsHistory.
  ///
  /// In en, this message translates to:
  /// **'Transactions History'**
  String get transactionsHistory;

  /// No description provided for @buyPoints.
  ///
  /// In en, this message translates to:
  /// **'Buy Points'**
  String get buyPoints;

  /// No description provided for @rewardsHistory.
  ///
  /// In en, this message translates to:
  /// **'Rewards History'**
  String get rewardsHistory;

  /// No description provided for @competitionTrack.
  ///
  /// In en, this message translates to:
  /// **'Competition Track'**
  String get competitionTrack;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions available'**
  String get noTransactions;

  /// No description provided for @noRewards.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t received any rewards yet.'**
  String get noRewards;

  /// No description provided for @dashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your fiat balance, bank accounts, and track your rewards journey.'**
  String get dashboardDesc;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @trackOverview.
  ///
  /// In en, this message translates to:
  /// **'Your current location on the FitZone Rewards track.'**
  String get trackOverview;

  /// No description provided for @rewardDetails.
  ///
  /// In en, this message translates to:
  /// **'Reward Details'**
  String get rewardDetails;

  /// No description provided for @consumedBtn.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get consumedBtn;

  /// No description provided for @unlockedRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {title} Reward'**
  String unlockedRewardTitle(String title);

  /// No description provided for @unlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You have earned this reward.'**
  String get unlockedDesc;

  /// No description provided for @lockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn more points to unlock this awesome reward.'**
  String get lockedDesc;

  /// No description provided for @consumedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have already claimed this reward.'**
  String get consumedDesc;

  /// No description provided for @unlockedBtn.
  ///
  /// In en, this message translates to:
  /// **'Claim Now'**
  String get unlockedBtn;

  /// No description provided for @lockedBtn.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedBtn;

  /// No description provided for @achievementTrack.
  ///
  /// In en, this message translates to:
  /// **'Achievement Track'**
  String get achievementTrack;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @tapToSeeReward.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal reward'**
  String get tapToSeeReward;

  /// No description provided for @pointsToNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'Points to next level'**
  String get pointsToNextMilestone;

  /// No description provided for @levelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level Progress'**
  String get levelProgress;

  /// No description provided for @pointsPackages.
  ///
  /// In en, this message translates to:
  /// **'Points Packages'**
  String get pointsPackages;

  /// No description provided for @choosePackage.
  ///
  /// In en, this message translates to:
  /// **'Choose a Package'**
  String get choosePackage;

  /// No description provided for @levelUpRewards.
  ///
  /// In en, this message translates to:
  /// **'Level up your rewards and unlock exclusive perks!'**
  String get levelUpRewards;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get confirmPurchase;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Points purchased successfully!'**
  String get purchaseSuccessful;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment...'**
  String get processingPayment;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} SAR'**
  String payAmount(String amount);

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @beneficiaryName.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Name'**
  String get beneficiaryName;

  /// No description provided for @saveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save Account'**
  String get saveAccount;

  /// No description provided for @enterValidIban.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid IBAN'**
  String get enterValidIban;

  /// No description provided for @accountSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bank account saved successfully'**
  String get accountSavedSuccessfully;

  /// No description provided for @withdrawAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount to Withdraw'**
  String get withdrawAmount;

  /// No description provided for @minWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal is {amount} SAR'**
  String minWithdrawal(String amount);

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient available balance'**
  String get insufficientBalance;

  /// No description provided for @confirmWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Withdrawal'**
  String get confirmWithdrawal;

  /// No description provided for @withdrawalRequested.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted successfully. Under review.'**
  String get withdrawalRequested;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount'**
  String get amountRequired;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @pendingWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Pending Withdrawals'**
  String get pendingWithdrawals;

  /// No description provided for @completedWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Completed Withdrawals'**
  String get completedWithdrawals;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @deposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get deposits;

  /// No description provided for @withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @pointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get pointsHistory;

  /// No description provided for @myRewards.
  ///
  /// In en, this message translates to:
  /// **'My Rewards'**
  String get myRewards;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get pointsEarned;

  /// No description provided for @pointsRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get pointsRedeemed;

  /// No description provided for @rewardAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get rewardAvailable;

  /// No description provided for @rewardConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get rewardConsumed;

  /// No description provided for @pointsToNextTier.
  ///
  /// In en, this message translates to:
  /// **'points to reach'**
  String get pointsToNextTier;

  /// No description provided for @currentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier'**
  String get currentTier;

  /// No description provided for @lifetimePointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Points:'**
  String get lifetimePointsTitle;

  /// No description provided for @viewRoadmap.
  ///
  /// In en, this message translates to:
  /// **'View Roadmap'**
  String get viewRoadmap;

  /// No description provided for @myRewardsDesc.
  ///
  /// In en, this message translates to:
  /// **'View your gifts'**
  String get myRewardsDesc;

  /// No description provided for @claimRewardBtn.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get claimRewardBtn;

  /// No description provided for @useRewardBtn.
  ///
  /// In en, this message translates to:
  /// **'Use Reward'**
  String get useRewardBtn;

  /// No description provided for @claimedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reward is in your wallet, ready to be used.'**
  String get claimedDesc;

  /// No description provided for @qrScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please show this QR code to the receptionist to be scanned and grant access.'**
  String get qrScanInstruction;

  /// No description provided for @rewardQrCode.
  ///
  /// In en, this message translates to:
  /// **'Reward QR Code'**
  String get rewardQrCode;

  /// No description provided for @confirmConsumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Usage'**
  String get confirmConsumeTitle;

  /// No description provided for @confirmConsumeDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to activate and use this reward now? This action cannot be undone.'**
  String get confirmConsumeDesc;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Use'**
  String get confirmBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get couponCode;

  /// No description provided for @spendablePoints.
  ///
  /// In en, this message translates to:
  /// **'Spendable Points'**
  String get spendablePoints;

  /// No description provided for @lifetimePoints.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Points'**
  String get lifetimePoints;

  /// No description provided for @lifetimePointsDesc.
  ///
  /// In en, this message translates to:
  /// **'These points determine your level and never decrease when you consume rewards.'**
  String get lifetimePointsDesc;

  /// No description provided for @goToWalletBtn.
  ///
  /// In en, this message translates to:
  /// **'Go to Wallet to Use'**
  String get goToWalletBtn;

  /// No description provided for @discountValue.
  ///
  /// In en, this message translates to:
  /// **'Discount Value:'**
  String get discountValue;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Valid Until:'**
  String get expiresAt;

  /// No description provided for @rewardClaimedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed! Find it in your wallet.'**
  String get rewardClaimedSuccess;

  /// No description provided for @rewardConsumedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward consumed successfully!'**
  String get rewardConsumedSuccess;

  /// No description provided for @currentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current Level:'**
  String get currentLevel;

  /// No description provided for @unboxedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Reward Unboxed'**
  String get unboxedTitle;

  /// No description provided for @alreadyClaimedMsg.
  ///
  /// In en, this message translates to:
  /// **'You have already claimed this reward. Please go to your wallet to use it.'**
  String get alreadyClaimedMsg;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyToClipboard;

  /// No description provided for @copiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Copied successfully'**
  String get copiedSuccessfully;

  /// No description provided for @selectSubscription.
  ///
  /// In en, this message translates to:
  /// **'Select Subscription to Extend'**
  String get selectSubscription;

  /// No description provided for @extendSubscriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'Extend Subscription'**
  String get extendSubscriptionBtn;

  /// No description provided for @noActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions found'**
  String get noActiveSubscriptions;

  /// No description provided for @showToReception.
  ///
  /// In en, this message translates to:
  /// **'Please show this screen to the receptionist'**
  String get showToReception;

  /// No description provided for @rewardManualDesc.
  ///
  /// In en, this message translates to:
  /// **'This reward requires manual pickup at the branch.'**
  String get rewardManualDesc;

  /// No description provided for @tapToExpandQr.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand QR code'**
  String get tapToExpandQr;

  /// No description provided for @trackLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked Reward'**
  String get trackLockedTitle;

  /// No description provided for @trackLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect more points to unlock this awesome reward and enjoy its benefits.'**
  String get trackLockedDesc;

  /// No description provided for @trackUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Ready!'**
  String get trackUnlockedTitle;

  /// No description provided for @trackUnlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You reached this level. Claim your reward now to use it.'**
  String get trackUnlockedDesc;

  /// No description provided for @trackClaimedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already Claimed'**
  String get trackClaimedTitle;

  /// No description provided for @trackClaimedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have already claimed this reward. Please go to your Rewards Wallet to use it.'**
  String get trackClaimedDesc;

  /// No description provided for @rewardIncludes.
  ///
  /// In en, this message translates to:
  /// **'This reward includes:'**
  String get rewardIncludes;

  /// No description provided for @pointsNeeded.
  ///
  /// In en, this message translates to:
  /// **'points left to unlock'**
  String get pointsNeeded;

  /// No description provided for @successUnboxedTitle.
  ///
  /// In en, this message translates to:
  /// **'Awesome! Reward Claimed'**
  String get successUnboxedTitle;

  /// No description provided for @successUnboxedDesc.
  ///
  /// In en, this message translates to:
  /// **'The reward has been successfully added to your wallet. You can use it anytime.'**
  String get successUnboxedDesc;

  /// No description provided for @checkWalletBtn.
  ///
  /// In en, this message translates to:
  /// **'Check Wallet Now'**
  String get checkWalletBtn;

  /// No description provided for @continueDiscoveringBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue Progress'**
  String get continueDiscoveringBtn;

  /// No description provided for @pointsNeededToUnlock.
  ///
  /// In en, this message translates to:
  /// **'more points to unlock'**
  String get pointsNeededToUnlock;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currency;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @freeShipping.
  ///
  /// In en, this message translates to:
  /// **'Free Shipping'**
  String get freeShipping;

  /// No description provided for @fixedAmountDiscount.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount Discount'**
  String get fixedAmountDiscount;

  /// No description provided for @percentageDiscount.
  ///
  /// In en, this message translates to:
  /// **'Percentage Discount'**
  String get percentageDiscount;

  /// No description provided for @bogoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Get 1 Free'**
  String get bogoDiscount;

  /// No description provided for @freeItem.
  ///
  /// In en, this message translates to:
  /// **'Free Item'**
  String get freeItem;

  /// No description provided for @rewardValue.
  ///
  /// In en, this message translates to:
  /// **'Reward Value:'**
  String get rewardValue;

  /// No description provided for @nextTier.
  ///
  /// In en, this message translates to:
  /// **'Next Tier'**
  String get nextTier;

  /// No description provided for @virtualCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Points Balance'**
  String get virtualCardTitle;

  /// No description provided for @quickActionBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get quickActionBuy;

  /// No description provided for @quickActionRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get quickActionRewards;

  /// No description provided for @quickActionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get quickActionHistory;

  /// No description provided for @goToTrackBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Gamified Track'**
  String get goToTrackBannerTitle;

  /// No description provided for @goToTrackBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your level and claim rewards'**
  String get goToTrackBannerSubtitle;

  /// No description provided for @unlockedRewardsBadge.
  ///
  /// In en, this message translates to:
  /// **'You have {count} waiting rewards!'**
  String unlockedRewardsBadge(String count);

  /// No description provided for @editBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Bank Account'**
  String get editBankAccount;

  /// No description provided for @manageYourBank.
  ///
  /// In en, this message translates to:
  /// **'Manage your approved bank account for withdrawals'**
  String get manageYourBank;

  /// No description provided for @maxTierAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'Max Tier Achieved'**
  String get maxTierAchievedTitle;

  /// No description provided for @maxTierAchievedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have reached the top of our loyalty program! Enjoy your exclusive rewards.'**
  String get maxTierAchievedDesc;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join FitZone and start your fitness journey today.'**
  String get registerSubtitle;

  /// No description provided for @locationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select your location on the map first'**
  String get locationRequiredError;

  /// Label for the crowd level filter
  ///
  /// In en, this message translates to:
  /// **'Crowd Level'**
  String get crowdLevel;

  /// Low crowd level option
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowCrowd;

  /// Medium crowd level option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumCrowd;

  /// High crowd level option
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highCrowd;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;
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
