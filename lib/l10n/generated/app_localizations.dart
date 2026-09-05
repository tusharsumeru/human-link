import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Samaja'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Bangalore · Heritage Portal'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get navFamilyTree;

  /// No description provided for @navInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get navInvitations;

  /// No description provided for @navDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get navDirectory;

  /// No description provided for @navMatrimonial.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial'**
  String get navMatrimonial;

  /// No description provided for @navWelfare.
  ///
  /// In en, this message translates to:
  /// **'Welfare'**
  String get navWelfare;

  /// No description provided for @navPurohit.
  ///
  /// In en, this message translates to:
  /// **'Purohit'**
  String get navPurohit;

  /// No description provided for @navLineageTree.
  ///
  /// In en, this message translates to:
  /// **'Lineage Tree'**
  String get navLineageTree;

  /// No description provided for @navMemberRequests.
  ///
  /// In en, this message translates to:
  /// **'Member Requests'**
  String get navMemberRequests;

  /// No description provided for @navArchives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get navArchives;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get navModeration;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get navTree;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get navMembers;

  /// No description provided for @navArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get navArchive;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navPost;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Access the Portal'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login with your registered mobile number.'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered Mobile Number'**
  String get loginPhoneLabel;

  /// No description provided for @loginSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get loginSendOtp;

  /// No description provided for @loginOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String loginOtpSentTo(String phone);

  /// No description provided for @loginOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP  ·  use 121212 for this demo'**
  String get loginOtpHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'← Change number'**
  String get loginChangeNumber;

  /// No description provided for @loginAboutCommunity.
  ///
  /// In en, this message translates to:
  /// **'About the Daivajna Samaja'**
  String get loginAboutCommunity;

  /// No description provided for @loginNewMember.
  ///
  /// In en, this message translates to:
  /// **'New member?  '**
  String get loginNewMember;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// No description provided for @loginHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your lineage.\nYour legacy. One portal.'**
  String get loginHeroHeadline;

  /// No description provided for @loginHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Connect with 1,428 families, trace your ancestral roots, and contribute to community welfare.'**
  String get loginHeroBody;

  /// No description provided for @loginErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get loginErrorInvalidPhone;

  /// No description provided for @loginErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP'**
  String get loginErrorInvalidOtp;

  /// No description provided for @loginErrorNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This number isn\'t registered. Please create an account first.'**
  String get loginErrorNotRegistered;

  /// No description provided for @loginErrorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server at {baseUrl}. Check that the backend is running.'**
  String loginErrorServerUnreachable(String baseUrl);

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get loginErrorNetwork;

  /// No description provided for @registerHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Begin your lineage journey today.'**
  String get registerHeroHeadline;

  /// No description provided for @registerHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Join 1,428 families who have documented their heritage and connected with their ancestral roots.'**
  String get registerHeroBody;

  /// No description provided for @registerJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the Samaj'**
  String get registerJoinTitle;

  /// No description provided for @registerJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account and begin documenting your lineage'**
  String get registerJoinSubtitle;

  /// No description provided for @registerOtpNotice.
  ///
  /// In en, this message translates to:
  /// **'An OTP will be sent to your mobile via SMS'**
  String get registerOtpNotice;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullName;

  /// No description provided for @registerAsPerAadhar.
  ///
  /// In en, this message translates to:
  /// **'(as per aadhar)'**
  String get registerAsPerAadhar;

  /// No description provided for @registerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aditi Shanbhag Rao'**
  String get registerFullNameHint;

  /// No description provided for @registerMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get registerMobileNumber;

  /// No description provided for @registerGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get registerGender;

  /// No description provided for @registerMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get registerMale;

  /// No description provided for @registerFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get registerFemale;

  /// No description provided for @registerMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get registerMaritalStatus;

  /// No description provided for @registerMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get registerMarried;

  /// No description provided for @registerUnmarried.
  ///
  /// In en, this message translates to:
  /// **'Unmarried'**
  String get registerUnmarried;

  /// No description provided for @registerDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get registerDivorced;

  /// No description provided for @registerGotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get registerGotra;

  /// No description provided for @registerKuladevata.
  ///
  /// In en, this message translates to:
  /// **'Kuladevata'**
  String get registerKuladevata;

  /// No description provided for @registerOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get registerOptional;

  /// No description provided for @registerSelectKuladevata.
  ///
  /// In en, this message translates to:
  /// **'Select your Kuladevata'**
  String get registerSelectKuladevata;

  /// No description provided for @registerIsPurohit.
  ///
  /// In en, this message translates to:
  /// **'Are you a purohit?'**
  String get registerIsPurohit;

  /// No description provided for @registerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get registerYes;

  /// No description provided for @registerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get registerNo;

  /// No description provided for @registerNativePlace.
  ///
  /// In en, this message translates to:
  /// **'Native Place (optional)'**
  String get registerNativePlace;

  /// No description provided for @registerNativePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kundapura, Udupi, Karnataka'**
  String get registerNativePlaceHint;

  /// No description provided for @registerDigilockerDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional - verify now and your profile carries the ✓ badge from day one. We never ask for or store your Aadhaar number, only the masked reference DigiLocker returns.'**
  String get registerDigilockerDetailsDesc;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?  '**
  String get registerAlreadyMember;

  /// No description provided for @registerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerSignIn;

  /// No description provided for @registerBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'← Back to Sign in'**
  String get registerBackToSignIn;

  /// No description provided for @registerVerifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get registerVerifyNumber;

  /// No description provided for @registerOtpSentToPrefix.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to '**
  String get registerOtpSentToPrefix;

  /// No description provided for @registerOtpSentToPhone.
  ///
  /// In en, this message translates to:
  /// **'+91 {phone}'**
  String registerOtpSentToPhone(String phone);

  /// No description provided for @registerOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP  ·  use 121212 for this demo'**
  String get registerOtpHint;

  /// No description provided for @registerCreateAccountContinue.
  ///
  /// In en, this message translates to:
  /// **'Create Account & Continue'**
  String get registerCreateAccountContinue;

  /// No description provided for @registerBack.
  ///
  /// In en, this message translates to:
  /// **'← Back'**
  String get registerBack;

  /// No description provided for @registerAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get registerAccountCreated;

  /// No description provided for @registerAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get registerAllSet;

  /// No description provided for @registerVerifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get registerVerifyIdentity;

  /// No description provided for @registerAadhaarVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Aadhaar is verified and saved to your profile - the ✓ badge is already yours.'**
  String get registerAadhaarVerifiedSubtitle;

  /// No description provided for @registerAadhaarUnverifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar KYC through the government DigiLocker earns your profile the ✓ verified badge and keeps our ancestral records trustworthy. We store only a masked reference - never your full Aadhaar number.'**
  String get registerAadhaarUnverifiedSubtitle;

  /// No description provided for @registerDigilockerIdentityDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the official DigiLocker portal and consent to share your Aadhaar. Verification is confirmed automatically.'**
  String get registerDigilockerIdentityDesc;

  /// No description provided for @registerContinueToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Continue to Dashboard'**
  String get registerContinueToDashboard;

  /// No description provided for @registerSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now - verify later'**
  String get registerSkipForNow;

  /// No description provided for @registerKycVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verified via DigiLocker'**
  String get registerKycVerifiedTitle;

  /// No description provided for @registerKycSavedOnSignup.
  ///
  /// In en, this message translates to:
  /// **'Saved to your account when you finish signing up.'**
  String get registerKycSavedOnSignup;

  /// No description provided for @registerErrorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get registerErrorName;

  /// No description provided for @registerErrorPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get registerErrorPhone;

  /// No description provided for @registerErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get registerErrorInvalidOtp;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerErrorGeneric;

  /// No description provided for @registerErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'the server took too long to respond'**
  String get registerErrorTimeout;

  /// No description provided for @registerErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error - {detail}'**
  String registerErrorNetwork(String detail);

  /// No description provided for @heritageStepLabel.
  ///
  /// In en, this message translates to:
  /// **'STEP 3 OF 3'**
  String get heritageStepLabel;

  /// No description provided for @heritageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cultural Profile & Heritage'**
  String get heritageTitle;

  /// No description provided for @heritageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The final step to documenting your legacy within the Daivajna community.'**
  String get heritageSubtitle;

  /// No description provided for @heritageErrorPickFile.
  ///
  /// In en, this message translates to:
  /// **'Could not pick file: {error}'**
  String heritageErrorPickFile(String error);

  /// No description provided for @heritageGotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get heritageGotra;

  /// No description provided for @heritageGotraHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kashyap'**
  String get heritageGotraHint;

  /// No description provided for @heritageNativePlace.
  ///
  /// In en, this message translates to:
  /// **'Native Place (Kula Devata Location)'**
  String get heritageNativePlace;

  /// No description provided for @heritageNativePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gokarna'**
  String get heritageNativePlaceHint;

  /// No description provided for @heritageBio.
  ///
  /// In en, this message translates to:
  /// **'Professional Bio'**
  String get heritageBio;

  /// No description provided for @heritageBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the community about your work and skills.'**
  String get heritageBioHint;

  /// No description provided for @heritageMatrimonialOptIn.
  ///
  /// In en, this message translates to:
  /// **'Opt-in to Matrimonial Hub'**
  String get heritageMatrimonialOptIn;

  /// No description provided for @heritageMatrimonialDesc.
  ///
  /// In en, this message translates to:
  /// **'Make your profile discoverable to families seeking matrimonial connections within the Samaj. You can change this preference anytime.'**
  String get heritageMatrimonialDesc;

  /// No description provided for @heritageUploadNote.
  ///
  /// In en, this message translates to:
  /// **'Optional: Upload Family Documents (birth certificate, old letters or heirlooms - JPG / PNG)'**
  String get heritageUploadNote;

  /// No description provided for @heritageUploadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Click to upload family documents'**
  String get heritageUploadPrompt;

  /// No description provided for @heritageChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get heritageChange;

  /// No description provided for @heritageBackToLineage.
  ///
  /// In en, this message translates to:
  /// **'Back to Lineage'**
  String get heritageBackToLineage;

  /// No description provided for @heritageCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile ✓'**
  String get heritageCompleteProfile;

  /// No description provided for @heritageWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Samaj'**
  String get heritageWelcomeTitle;

  /// No description provided for @heritageWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'By completing this step, you become a verified member in our living digital tree. You help maintain the cultural integrity and social fabric of the Daivajna community.'**
  String get heritageWelcomeBody;

  /// No description provided for @heritageBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Access to the Global Lineage Directory'**
  String get heritageBenefit1;

  /// No description provided for @heritageBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Participation in Samaja Governance'**
  String get heritageBenefit2;

  /// No description provided for @heritageBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Community Welfare Program Eligibility'**
  String get heritageBenefit3;

  /// No description provided for @onboardStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get onboardStepIdentity;

  /// No description provided for @onboardStepLineage.
  ///
  /// In en, this message translates to:
  /// **'Lineage'**
  String get onboardStepLineage;

  /// No description provided for @onboardStepHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get onboardStepHeritage;

  /// No description provided for @identityStepLabel.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 OF 3'**
  String get identityStepLabel;

  /// No description provided for @identityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get identityTitle;

  /// No description provided for @identitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your Aadhaar to maintain the sanctity of our ancestral records. An OTP will be sent to your Aadhaar-linked mobile. Your data is encrypted and never shared with other members.'**
  String get identitySubtitle;

  /// No description provided for @identityDigilockerDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your Aadhaar securely through the government DigiLocker. You\'ll sign in to DigiLocker and consent to share your Aadhaar.'**
  String get identityDigilockerDesc;

  /// No description provided for @identityErrorCapture.
  ///
  /// In en, this message translates to:
  /// **'Could not capture image: {error}'**
  String identityErrorCapture(String error);

  /// No description provided for @identitySelfieVerification.
  ///
  /// In en, this message translates to:
  /// **'Selfie Verification'**
  String get identitySelfieVerification;

  /// No description provided for @identitySelfieCaptured.
  ///
  /// In en, this message translates to:
  /// **'Selfie captured successfully'**
  String get identitySelfieCaptured;

  /// No description provided for @identitySelfiePrompt.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie to match your ID photo'**
  String get identitySelfiePrompt;

  /// No description provided for @identityOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get identityOpenCamera;

  /// No description provided for @identityContinueToLineage.
  ///
  /// In en, this message translates to:
  /// **'Continue to Lineage'**
  String get identityContinueToLineage;

  /// No description provided for @identityTrustSecurity.
  ///
  /// In en, this message translates to:
  /// **'Trust & Security'**
  String get identityTrustSecurity;

  /// No description provided for @identityTrustEncryption.
  ///
  /// In en, this message translates to:
  /// **'AES-256 end-to-end encryption'**
  String get identityTrustEncryption;

  /// No description provided for @identityTrustNeverShared.
  ///
  /// In en, this message translates to:
  /// **'Never shared with other members'**
  String get identityTrustNeverShared;

  /// No description provided for @identityTrustVault.
  ///
  /// In en, this message translates to:
  /// **'Archival-grade secure vault'**
  String get identityTrustVault;

  /// No description provided for @lineageStepLabel.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 OF 3'**
  String get lineageStepLabel;

  /// No description provided for @lineageTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Your Roots'**
  String get lineageTitle;

  /// No description provided for @lineageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for your parents, gotra, or ancestor village to find an existing branch in the Daivajna Samaja tree.'**
  String get lineageSubtitle;

  /// No description provided for @lineageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a parent name, Gotra, or ancestor village…'**
  String get lineageSearchHint;

  /// No description provided for @lineageResultsForQuery.
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String lineageResultsForQuery(String query);

  /// No description provided for @lineagePotentialConnections.
  ///
  /// In en, this message translates to:
  /// **'Potential Connections'**
  String get lineagePotentialConnections;

  /// No description provided for @lineageResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String lineageResultsCount(String label, int count);

  /// No description provided for @lineageNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found for \"{query}\"'**
  String lineageNoMatches(String query);

  /// No description provided for @lineageBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get lineageBack;

  /// No description provided for @lineageContinueToHeritage.
  ///
  /// In en, this message translates to:
  /// **'Continue to Heritage'**
  String get lineageContinueToHeritage;

  /// No description provided for @lineageNominatedBy.
  ///
  /// In en, this message translates to:
  /// **'✓ {nominator}'**
  String lineageNominatedBy(String nominator);

  /// No description provided for @lineageRequested.
  ///
  /// In en, this message translates to:
  /// **'✓ Requested'**
  String get lineageRequested;

  /// No description provided for @lineageConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get lineageConnect;

  /// No description provided for @lineageNewRootEstablished.
  ///
  /// In en, this message translates to:
  /// **'New Root Node Established'**
  String get lineageNewRootEstablished;

  /// No description provided for @lineageNewRootEstablishedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your family will be added as a new branch. An elder will verify and link it during review.'**
  String get lineageNewRootEstablishedDesc;

  /// No description provided for @lineageUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get lineageUndo;

  /// No description provided for @lineageCantFindBranch.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your branch?'**
  String get lineageCantFindBranch;

  /// No description provided for @lineageStartNewRootDesc.
  ///
  /// In en, this message translates to:
  /// **'You can start a new root node if your family hasn\'t registered yet.'**
  String get lineageStartNewRootDesc;

  /// No description provided for @lineageEstablishNewRoot.
  ///
  /// In en, this message translates to:
  /// **'Establish New Root Node →'**
  String get lineageEstablishNewRoot;

  /// No description provided for @dashTitle.
  ///
  /// In en, this message translates to:
  /// **'Samaj Feed'**
  String get dashTitle;

  /// No description provided for @dashCouldNotLoadFeed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the feed'**
  String get dashCouldNotLoadFeed;

  /// No description provided for @dashNoPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get dashNoPostsYet;

  /// No description provided for @dashBeFirstToShare.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share something with the Samaj.'**
  String get dashBeFirstToShare;

  /// No description provided for @dashAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up ✦'**
  String get dashAllCaughtUp;

  /// No description provided for @dashFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get dashFollow;

  /// No description provided for @dashFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get dashFollowing;

  /// No description provided for @dashErrorCouldNotReachSuffix.
  ///
  /// In en, this message translates to:
  /// **'{message}\nCould not reach {baseUrl}'**
  String dashErrorCouldNotReachSuffix(String message, String baseUrl);

  /// No description provided for @dashErrorWithStatus.
  ///
  /// In en, this message translates to:
  /// **'{message} ({statusCode})'**
  String dashErrorWithStatus(String message, String statusCode);

  /// No description provided for @dashErrorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server at {baseUrl}.\nCheck that the backend is running, or pass --dart-define=API_BASE_URL=<host>.'**
  String dashErrorServerUnreachable(String baseUrl);

  /// No description provided for @dashErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not load the feed.\n{error}'**
  String dashErrorGeneric(String error);

  /// No description provided for @dashCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get dashCamera;

  /// No description provided for @dashSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get dashSelectFile;

  /// No description provided for @dashCouldNotPickMedia.
  ///
  /// In en, this message translates to:
  /// **'Could not pick media: {error}'**
  String dashCouldNotPickMedia(String error);

  /// No description provided for @dashFamilyUpdates.
  ///
  /// In en, this message translates to:
  /// **'FAMILY UPDATES'**
  String get dashFamilyUpdates;

  /// No description provided for @dashYourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get dashYourStory;

  /// No description provided for @dashYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get dashYou;

  /// No description provided for @dashReel.
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get dashReel;

  /// No description provided for @postMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get postMenuDelete;

  /// No description provided for @postMenuEditCaption.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get postMenuEditCaption;

  /// No description provided for @postMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get postMenuReport;

  /// No description provided for @postMenuHide.
  ///
  /// In en, this message translates to:
  /// **'Hide from feed'**
  String get postMenuHide;

  /// No description provided for @postMenuCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get postMenuCopyLink;

  /// No description provided for @postHidden.
  ///
  /// In en, this message translates to:
  /// **'Post hidden'**
  String get postHidden;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks - we\'ll take a look at this post'**
  String get reportThanks;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it for everyone in the Samaj.'**
  String get deletePostBody;

  /// No description provided for @postDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get postDelete;

  /// No description provided for @couldNotDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Could not delete post'**
  String get couldNotDeletePost;

  /// No description provided for @writeACaption.
  ///
  /// In en, this message translates to:
  /// **'Write a caption…'**
  String get writeACaption;

  /// No description provided for @cantEditCaptionYet.
  ///
  /// In en, this message translates to:
  /// **'Can\'t edit the caption until the upload finishes.'**
  String get cantEditCaptionYet;

  /// No description provided for @captionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Caption updated'**
  String get captionUpdated;

  /// No description provided for @couldNotUpdateCaption.
  ///
  /// In en, this message translates to:
  /// **'Could not update caption'**
  String get couldNotUpdateCaption;

  /// No description provided for @couldNotUpdateLike.
  ///
  /// In en, this message translates to:
  /// **'Could not update like'**
  String get couldNotUpdateLike;

  /// No description provided for @couldNotUpdateFollow.
  ///
  /// In en, this message translates to:
  /// **'Could not update follow status'**
  String get couldNotUpdateFollow;

  /// No description provided for @savedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved to your profile'**
  String get savedToProfile;

  /// No description provided for @removedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get removedFromSaved;

  /// No description provided for @uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadingEllipsis;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @stillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still offline'**
  String get stillOffline;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get timeRecently;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}w ago'**
  String timeWeeksAgo(int n);

  /// No description provided for @profileRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get profileRelative;

  /// No description provided for @profilePendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitation'**
  String get profilePendingInvitation;

  /// No description provided for @profileFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Family Member'**
  String get profileFamilyMember;

  /// No description provided for @profileViewInFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'View in Family Tree'**
  String get profileViewInFamilyTree;

  /// No description provided for @profilePleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your profile.'**
  String get profilePleaseSignIn;

  /// No description provided for @profileGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get profileGoToLogin;

  /// No description provided for @profileElderAdmin.
  ///
  /// In en, this message translates to:
  /// **'Elder & Samaj Admin'**
  String get profileElderAdmin;

  /// No description provided for @profileSamajMember.
  ///
  /// In en, this message translates to:
  /// **'Samaj Member'**
  String get profileSamajMember;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileMatrimonialDetails.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial Details'**
  String get profileMatrimonialDetails;

  /// No description provided for @profileVerifyIdentityOptional.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity (optional)'**
  String get profileVerifyIdentityOptional;

  /// No description provided for @profileVerifiedPill.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerifiedPill;

  /// No description provided for @profileAadhaarVerified.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Verified'**
  String get profileAadhaarVerified;

  /// No description provided for @profileVerifiedViaDigilocker.
  ///
  /// In en, this message translates to:
  /// **'Verified via DigiLocker'**
  String get profileVerifiedViaDigilocker;

  /// No description provided for @profileViaDigilockerMasked.
  ///
  /// In en, this message translates to:
  /// **'via DigiLocker · {masked}'**
  String profileViaDigilockerMasked(String masked);

  /// No description provided for @profileAboutOccupation.
  ///
  /// In en, this message translates to:
  /// **'About & Occupation'**
  String get profileAboutOccupation;

  /// No description provided for @profileOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileOccupation;

  /// No description provided for @profileBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Birth Year'**
  String get profileBirthYear;

  /// No description provided for @profileStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileStatus;

  /// No description provided for @profileInMemoriam.
  ///
  /// In en, this message translates to:
  /// **'In Memoriam'**
  String get profileInMemoriam;

  /// No description provided for @profileActiveMember.
  ///
  /// In en, this message translates to:
  /// **'Active Member'**
  String get profileActiveMember;

  /// No description provided for @profileLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get profileLate;

  /// No description provided for @profileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileActive;

  /// No description provided for @profilePassedAway.
  ///
  /// In en, this message translates to:
  /// **'Passed away {date}'**
  String profilePassedAway(String date);

  /// No description provided for @profileAt.
  ///
  /// In en, this message translates to:
  /// **'at {place}'**
  String profileAt(String place);

  /// No description provided for @profileFamilyRelations.
  ///
  /// In en, this message translates to:
  /// **'Family Relations'**
  String get profileFamilyRelations;

  /// No description provided for @profileFullTree.
  ///
  /// In en, this message translates to:
  /// **'Full Tree →'**
  String get profileFullTree;

  /// No description provided for @profileNoConnectedRelations.
  ///
  /// In en, this message translates to:
  /// **'No connected relations yet'**
  String get profileNoConnectedRelations;

  /// No description provided for @profileNotJoinedYet.
  ///
  /// In en, this message translates to:
  /// **'not joined yet'**
  String get profileNotJoinedYet;

  /// No description provided for @profileLifeArchive.
  ///
  /// In en, this message translates to:
  /// **'Life Archive'**
  String get profileLifeArchive;

  /// No description provided for @profileQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get profileQuickStats;

  /// No description provided for @profileGotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get profileGotra;

  /// No description provided for @profileNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get profileNative;

  /// No description provided for @profileStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get profileStanding;

  /// No description provided for @profileAncestor.
  ///
  /// In en, this message translates to:
  /// **'Ancestor'**
  String get profileAncestor;

  /// No description provided for @profileMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get profileMember;

  /// No description provided for @profileSamajId.
  ///
  /// In en, this message translates to:
  /// **'Samaj ID'**
  String get profileSamajId;

  /// No description provided for @profileSamajIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Samaj ID {id} copied'**
  String profileSamajIdCopied(String id);

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @profileShareWithMembers.
  ///
  /// In en, this message translates to:
  /// **'Share with members'**
  String get profileShareWithMembers;

  /// No description provided for @profilePhoneVisibleDesc.
  ///
  /// In en, this message translates to:
  /// **'Members who open your profile can see and call your number.'**
  String get profilePhoneVisibleDesc;

  /// No description provided for @profilePhoneHiddenDesc.
  ///
  /// In en, this message translates to:
  /// **'Your number stays private. Members can still message you in the app.'**
  String get profilePhoneHiddenDesc;

  /// No description provided for @profileVisibleToMembers.
  ///
  /// In en, this message translates to:
  /// **'Visible to members'**
  String get profileVisibleToMembers;

  /// No description provided for @profileHiddenFromMembers.
  ///
  /// In en, this message translates to:
  /// **'Hidden from other members'**
  String get profileHiddenFromMembers;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileAppearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app looks.'**
  String get profileAppearanceDesc;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @profileCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Check your connection and try again.'**
  String get profileCouldNotSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @profileNoSavedPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet. Tap the bookmark on any reel or post to keep it here.'**
  String get profileNoSavedPostsYet;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editAddPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo - required for the matrimonial section'**
  String get editAddPhotoRequired;

  /// No description provided for @editTapCameraToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera to change your photo'**
  String get editTapCameraToChange;

  /// No description provided for @editSectionBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'BASIC DETAILS'**
  String get editSectionBasicDetails;

  /// No description provided for @editSectionCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'CURRENT ADDRESS'**
  String get editSectionCurrentAddress;

  /// No description provided for @editSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get editSectionAbout;

  /// No description provided for @editFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get editFullName;

  /// No description provided for @editNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get editNameTooShort;

  /// No description provided for @editNativePlace.
  ///
  /// In en, this message translates to:
  /// **'Native place'**
  String get editNativePlace;

  /// No description provided for @editNativePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kumta, Karnataka'**
  String get editNativePlaceHint;

  /// No description provided for @editOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get editOccupation;

  /// No description provided for @editOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineer'**
  String get editOccupationHint;

  /// No description provided for @editCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get editCountry;

  /// No description provided for @editCountryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. India'**
  String get editCountryHint;

  /// No description provided for @editState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get editState;

  /// No description provided for @editStateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Karnataka'**
  String get editStateHint;

  /// No description provided for @editDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get editDistrict;

  /// No description provided for @editDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bangalore Urban'**
  String get editDistrictHint;

  /// No description provided for @editTaluk.
  ///
  /// In en, this message translates to:
  /// **'Taluk'**
  String get editTaluk;

  /// No description provided for @editTalukHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bangalore North'**
  String get editTalukHint;

  /// No description provided for @editCity.
  ///
  /// In en, this message translates to:
  /// **'City / Town / Village'**
  String get editCity;

  /// No description provided for @editCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bangalore'**
  String get editCityHint;

  /// No description provided for @editArea.
  ///
  /// In en, this message translates to:
  /// **'Area / Locality'**
  String get editArea;

  /// No description provided for @editAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rajajinagar'**
  String get editAreaHint;

  /// No description provided for @editStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get editStreet;

  /// No description provided for @editStreetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3rd Cross, 5th Main'**
  String get editStreetHint;

  /// No description provided for @editLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get editLandmark;

  /// No description provided for @editLandmarkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Opposite Navrang Theatre'**
  String get editLandmarkHint;

  /// No description provided for @editPincode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get editPincode;

  /// No description provided for @editPincodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get editPincodeHint;

  /// No description provided for @editPincodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'PIN code must be 6 digits'**
  String get editPincodeInvalid;

  /// No description provided for @editBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editBio;

  /// No description provided for @editAddressOldSingleLine.
  ///
  /// In en, this message translates to:
  /// **'Address (old, single line)'**
  String get editAddressOldSingleLine;

  /// No description provided for @editSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editSaving;

  /// No description provided for @editSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editSaveChanges;

  /// No description provided for @editAadhaarOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verification is optional. Every detail here can be entered by hand - verifying only fills some of them in for you.'**
  String get editAadhaarOptionalNote;

  /// No description provided for @editGotPositionFillParts.
  ///
  /// In en, this message translates to:
  /// **'Got your position - fill in the address parts'**
  String get editGotPositionFillParts;

  /// No description provided for @editAddressFilledFromLocation.
  ///
  /// In en, this message translates to:
  /// **'Address filled in from your location'**
  String get editAddressFilledFromLocation;

  /// No description provided for @editCouldNotReadLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not read your location'**
  String get editCouldNotReadLocation;

  /// No description provided for @editCouldNotPickImage.
  ///
  /// In en, this message translates to:
  /// **'Could not pick an image: {error}'**
  String editCouldNotPickImage(String error);

  /// No description provided for @editPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get editPhotoUpdated;

  /// No description provided for @editCouldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the photo'**
  String get editCouldNotUploadPhoto;

  /// No description provided for @editDobHelpText.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get editDobHelpText;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get editProfileSaved;

  /// No description provided for @editCouldNotSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile'**
  String get editCouldNotSaveProfile;

  /// No description provided for @editPinnedAt.
  ///
  /// In en, this message translates to:
  /// **'Pinned at {lat}, {lng}'**
  String editPinnedAt(String lat, String lng);

  /// No description provided for @editAlreadyOnMap.
  ///
  /// In en, this message translates to:
  /// **'Already on the map. Editing the address re-pins it when you save.'**
  String get editAlreadyOnMap;

  /// No description provided for @editCoordinatesFromAddress.
  ///
  /// In en, this message translates to:
  /// **'Coordinates are worked out from the address when you save.'**
  String get editCoordinatesFromAddress;

  /// No description provided for @editLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get editLocating;

  /// No description provided for @editUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get editUseCurrentLocation;

  /// No description provided for @editGotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get editGotra;

  /// No description provided for @editSelectGotra.
  ///
  /// In en, this message translates to:
  /// **'Select your gotra'**
  String get editSelectGotra;

  /// No description provided for @editBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get editBloodGroup;

  /// No description provided for @editSelectBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Select blood group'**
  String get editSelectBloodGroup;

  /// No description provided for @editMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get editMaritalStatus;

  /// No description provided for @editSelectMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Select marital status'**
  String get editSelectMaritalStatus;

  /// No description provided for @editMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get editMarried;

  /// No description provided for @editUnmarried.
  ///
  /// In en, this message translates to:
  /// **'Unmarried'**
  String get editUnmarried;

  /// No description provided for @editDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get editDivorced;

  /// No description provided for @editKuladevata.
  ///
  /// In en, this message translates to:
  /// **'Kuladevata'**
  String get editKuladevata;

  /// No description provided for @editSelectKuladevata.
  ///
  /// In en, this message translates to:
  /// **'Select your Kuladevata'**
  String get editSelectKuladevata;

  /// No description provided for @editNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get editNotSet;

  /// No description provided for @editGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get editGender;

  /// No description provided for @editMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get editMale;

  /// No description provided for @editFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get editFemale;

  /// No description provided for @editAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String editAgeYears(int age);

  /// No description provided for @verifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Identity'**
  String get verifyIdentityTitle;

  /// No description provided for @verifyIdentityHeading.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get verifyIdentityHeading;

  /// No description provided for @verifyIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your Aadhaar securely through the government DigiLocker. Your profile stays Not Verified until this is complete. We never see or store your full Aadhaar number - only a masked reference.'**
  String get verifyIdentitySubtitle;

  /// No description provided for @verifyBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get verifyBackToDashboard;

  /// No description provided for @verifyTrustGovBacked.
  ///
  /// In en, this message translates to:
  /// **'Government-backed DigiLocker consent'**
  String get verifyTrustGovBacked;

  /// No description provided for @verifyTrustNeverStored.
  ///
  /// In en, this message translates to:
  /// **'Full Aadhaar number is never stored'**
  String get verifyTrustNeverStored;

  /// No description provided for @verifyTrustMaskedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a masked reference is kept'**
  String get verifyTrustMaskedOnly;

  /// No description provided for @ftTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get ftTitle;

  /// No description provided for @ftUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get ftUnableToLoad;

  /// No description provided for @ftLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the family tree. Check your connection.'**
  String get ftLoadError;

  /// No description provided for @ftEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your family tree is empty'**
  String get ftEmptyTitle;

  /// No description provided for @ftEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your immediate family - father, mother, spouse, siblings, children. Their trees connect to yours as they join.'**
  String get ftEmptyBody;

  /// No description provided for @ftAddFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get ftAddFamilyMember;

  /// No description provided for @ftTruncatedBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing part of the tree — it has more relatives than one view can hold.'**
  String get ftTruncatedBanner;

  /// No description provided for @ftHeaderKicker.
  ///
  /// In en, this message translates to:
  /// **'DAIVAJNA SAMAJA · LINEAGE'**
  String get ftHeaderKicker;

  /// No description provided for @ftHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Vamsha Vruksha'**
  String get ftHeaderTitle;

  /// No description provided for @ftAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get ftAddMember;

  /// No description provided for @ftRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get ftRequests;

  /// No description provided for @ftInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get ftInvites;

  /// No description provided for @ftAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get ftAlerts;

  /// No description provided for @ftManageLinks.
  ///
  /// In en, this message translates to:
  /// **'Manage links'**
  String get ftManageLinks;

  /// No description provided for @ftCompactView.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get ftCompactView;

  /// No description provided for @ftExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get ftExpandAll;

  /// No description provided for @ftGenRow.
  ///
  /// In en, this message translates to:
  /// **'GEN {roman}'**
  String ftGenRow(String roman);

  /// No description provided for @ftDefaultInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'You have a pending invitation.'**
  String get ftDefaultInviteMessage;

  /// No description provided for @ftMoreCount.
  ///
  /// In en, this message translates to:
  /// **'  (+{n} more)'**
  String ftMoreCount(int n);

  /// No description provided for @ftReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get ftReview;

  /// No description provided for @ftYourGeneration.
  ///
  /// In en, this message translates to:
  /// **'Your generation'**
  String get ftYourGeneration;

  /// No description provided for @ftOneGenAbove.
  ///
  /// In en, this message translates to:
  /// **'One generation above'**
  String get ftOneGenAbove;

  /// No description provided for @ftGenerationsAbove.
  ///
  /// In en, this message translates to:
  /// **'{n} generations above'**
  String ftGenerationsAbove(int n);

  /// No description provided for @ftOneGenBelow.
  ///
  /// In en, this message translates to:
  /// **'One generation below'**
  String get ftOneGenBelow;

  /// No description provided for @ftGenerationsBelow.
  ///
  /// In en, this message translates to:
  /// **'{n} generations below'**
  String ftGenerationsBelow(int n);

  /// No description provided for @ftRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get ftRelative;

  /// No description provided for @ftYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get ftYou;

  /// No description provided for @ftDerivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Derived from: your {path}'**
  String ftDerivedFrom(String path);

  /// No description provided for @ftShowTheirFamily.
  ///
  /// In en, this message translates to:
  /// **'Show their family ({n})'**
  String ftShowTheirFamily(int n);

  /// No description provided for @ftHideTheirFamily.
  ///
  /// In en, this message translates to:
  /// **'Hide their family'**
  String get ftHideTheirFamily;

  /// No description provided for @ftViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get ftViewProfile;

  /// No description provided for @ftWithdrawThisRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this request'**
  String get ftWithdrawThisRequest;

  /// No description provided for @ftRemoveThisRelationship.
  ///
  /// In en, this message translates to:
  /// **'Remove this relationship'**
  String get ftRemoveThisRelationship;

  /// No description provided for @ftVerifiedDeceased.
  ///
  /// In en, this message translates to:
  /// **'Verified Deceased'**
  String get ftVerifiedDeceased;

  /// No description provided for @ftVerifiedDeceasedDesc.
  ///
  /// In en, this message translates to:
  /// **'Added directly to the tree - no approval needed.'**
  String get ftVerifiedDeceasedDesc;

  /// No description provided for @ftPendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitation'**
  String get ftPendingInvitation;

  /// No description provided for @ftPendingInvitationDesc.
  ///
  /// In en, this message translates to:
  /// **'This person has not joined yet. The relationship activates when they register and accept.'**
  String get ftPendingInvitationDesc;

  /// No description provided for @ftActiveMember.
  ///
  /// In en, this message translates to:
  /// **'Active Member'**
  String get ftActiveMember;

  /// No description provided for @ftActiveMemberDesc.
  ///
  /// In en, this message translates to:
  /// **'Linked to a verified member account.'**
  String get ftActiveMemberDesc;

  /// No description provided for @ftInMemoriam.
  ///
  /// In en, this message translates to:
  /// **'In Memoriam'**
  String get ftInMemoriam;

  /// No description provided for @ftLatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Late '**
  String get ftLatePrefix;

  /// No description provided for @ftInviteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite {name}'**
  String ftInviteDialogTitle(String name);

  /// No description provided for @ftInviteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'A placeholder was added and the relationship is pending. Share this invite so they can join and connect back to you.'**
  String get ftInviteDialogBody;

  /// No description provided for @ftClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ftClose;

  /// No description provided for @ftCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get ftCopyLink;

  /// No description provided for @ftInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get ftInviteLinkCopied;

  /// No description provided for @ftYourRelative.
  ///
  /// In en, this message translates to:
  /// **'Your relative'**
  String get ftYourRelative;

  /// No description provided for @ftMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'Member added'**
  String get ftMemberAdded;

  /// No description provided for @ftWithdrawRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this request?'**
  String get ftWithdrawRequestTitle;

  /// No description provided for @ftRemoveLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this link?'**
  String get ftRemoveLinkTitle;

  /// No description provided for @ftWithdrawRequestBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be asked to join as your {relation}.'**
  String ftWithdrawRequestBody(String name, String relation);

  /// No description provided for @ftRemoveLinkBody.
  ///
  /// In en, this message translates to:
  /// **'{name} stops being your {relation}. The link leaves both trees, along with everyone who was only reached through it. You can add each other again with the correct relation.'**
  String ftRemoveLinkBody(String name, String relation);

  /// No description provided for @ftOptionalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note to them — e.g. \"wrong relation\"'**
  String get ftOptionalNoteHint;

  /// No description provided for @ftRequestWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn'**
  String get ftRequestWithdrawn;

  /// No description provided for @ftRelationshipRemoved.
  ///
  /// In en, this message translates to:
  /// **'Relationship removed'**
  String get ftRelationshipRemoved;

  /// No description provided for @ftCouldNotRemoveRelationship.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the relationship'**
  String get ftCouldNotRemoveRelationship;

  /// No description provided for @ftManageRelationships.
  ///
  /// In en, this message translates to:
  /// **'Manage Relationships'**
  String get ftManageRelationships;

  /// No description provided for @ftNoRelationshipsYet.
  ///
  /// In en, this message translates to:
  /// **'No relationships yet'**
  String get ftNoRelationshipsYet;

  /// No description provided for @ftNoRelationshipsYetDesc.
  ///
  /// In en, this message translates to:
  /// **'Links you add — or that a relative adds naming you — show up here, and can be removed from either side.'**
  String get ftNoRelationshipsYetDesc;

  /// No description provided for @ftRemovingLinkNote.
  ///
  /// In en, this message translates to:
  /// **'Removing a link takes it out of both trees, along with anyone who was only reached through it. The pair can be added again with the correct relation.'**
  String get ftRemovingLinkNote;

  /// No description provided for @ftNotAcceptedYet.
  ///
  /// In en, this message translates to:
  /// **'Not accepted yet'**
  String get ftNotAcceptedYet;

  /// No description provided for @ftYourRelation.
  ///
  /// In en, this message translates to:
  /// **'Your {relation}'**
  String ftYourRelation(String relation);

  /// No description provided for @ftRelationFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get ftRelationFather;

  /// No description provided for @ftRelationMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get ftRelationMother;

  /// No description provided for @ftRelationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get ftRelationSpouse;

  /// No description provided for @ftRelationBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get ftRelationBrother;

  /// No description provided for @ftRelationSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get ftRelationSister;

  /// No description provided for @ftRelationSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get ftRelationSon;

  /// No description provided for @ftRelationDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get ftRelationDaughter;

  /// No description provided for @ftRelationshipToYou.
  ///
  /// In en, this message translates to:
  /// **'Relationship to you *'**
  String get ftRelationshipToYou;

  /// No description provided for @ftHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Has an account'**
  String get ftHasAccount;

  /// No description provided for @ftNewProfile.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get ftNewProfile;

  /// No description provided for @ftFindByNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Find them by name, phone or Samaj ID'**
  String get ftFindByNamePhone;

  /// No description provided for @ftSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9876543210 or Ramesh'**
  String get ftSearchHint;

  /// No description provided for @ftSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get ftSearch;

  /// No description provided for @ftAccountRequestNote.
  ///
  /// In en, this message translates to:
  /// **'A living member with an account must accept your request before the relationship shows in both trees.'**
  String get ftAccountRequestNote;

  /// No description provided for @ftFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get ftFullName;

  /// No description provided for @ftFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Haldankar'**
  String get ftFullNameHint;

  /// No description provided for @ftGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get ftGender;

  /// No description provided for @ftMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get ftMale;

  /// No description provided for @ftFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get ftFemale;

  /// No description provided for @ftStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ftStatus;

  /// No description provided for @ftAlive.
  ///
  /// In en, this message translates to:
  /// **'Alive'**
  String get ftAlive;

  /// No description provided for @ftDeceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get ftDeceased;

  /// No description provided for @ftDeceasedNote.
  ///
  /// In en, this message translates to:
  /// **'A deceased person is added immediately - no invitation or approval.'**
  String get ftDeceasedNote;

  /// No description provided for @ftAliveNote.
  ///
  /// In en, this message translates to:
  /// **'A living person is invited: they join and confirm the relationship.'**
  String get ftAliveNote;

  /// No description provided for @ftPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get ftPhoneOptional;

  /// No description provided for @ftPhoneLinkNote.
  ///
  /// In en, this message translates to:
  /// **'Used to link their account when they register.'**
  String get ftPhoneLinkNote;

  /// No description provided for @ftDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth *'**
  String get ftDateOfBirth;

  /// No description provided for @ftDateOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Date of Death'**
  String get ftDateOfDeath;

  /// No description provided for @ftPlaceOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Place of Death'**
  String get ftPlaceOfDeath;

  /// No description provided for @ftPlaceOfDeathHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kundapura'**
  String get ftPlaceOfDeathHint;

  /// No description provided for @ftBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get ftBiography;

  /// No description provided for @ftBiographyHint.
  ///
  /// In en, this message translates to:
  /// **'A few words about their life…'**
  String get ftBiographyHint;

  /// No description provided for @ftSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get ftSelect;

  /// No description provided for @ftSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get ftSendRequest;

  /// No description provided for @ftAddToFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'Add to Family Tree'**
  String get ftAddToFamilyTree;

  /// No description provided for @ftCreateAndInvite.
  ///
  /// In en, this message translates to:
  /// **'Create & Invite'**
  String get ftCreateAndInvite;

  /// No description provided for @ftSelectPersonToRequest.
  ///
  /// In en, this message translates to:
  /// **'Select the person to send a request to'**
  String get ftSelectPersonToRequest;

  /// No description provided for @ftNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get ftNameRequired;

  /// No description provided for @ftDobRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get ftDobRequired;

  /// No description provided for @ftSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection.'**
  String get ftSearchFailed;

  /// No description provided for @ftCouldNotAddMember.
  ///
  /// In en, this message translates to:
  /// **'Could not add the member. Check your connection.'**
  String get ftCouldNotAddMember;

  /// No description provided for @ftDefaultMemberName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get ftDefaultMemberName;

  /// No description provided for @ftAlreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'You are already connected to {name}.'**
  String ftAlreadyConnected(String name);

  /// No description provided for @ftRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name} - they’ll appear once they accept.'**
  String ftRequestSent(String name);

  /// No description provided for @ftInvited.
  ///
  /// In en, this message translates to:
  /// **'{name} invited - share the link so they can join.'**
  String ftInvited(String name);

  /// No description provided for @ftAddedToTree.
  ///
  /// In en, this message translates to:
  /// **'{name} added to the family tree.'**
  String ftAddedToTree(String name);

  /// No description provided for @ftAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added.'**
  String ftAdded(String name);

  /// No description provided for @ftRelationshipRequests.
  ///
  /// In en, this message translates to:
  /// **'Relationship Requests'**
  String get ftRelationshipRequests;

  /// No description provided for @ftNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get ftNoPendingRequests;

  /// No description provided for @ftNoPendingRequestsDesc.
  ///
  /// In en, this message translates to:
  /// **'When a relative asks to connect with you, it shows up here.'**
  String get ftNoPendingRequestsDesc;

  /// No description provided for @ftWaitingOnThem.
  ///
  /// In en, this message translates to:
  /// **'Waiting on them'**
  String get ftWaitingOnThem;

  /// No description provided for @ftWaitingOnThemDesc.
  ///
  /// In en, this message translates to:
  /// **'These stay out of the tree until the other person accepts.'**
  String get ftWaitingOnThemDesc;

  /// No description provided for @ftAddedAsYourRelation.
  ///
  /// In en, this message translates to:
  /// **'Added as your {relation}'**
  String ftAddedAsYourRelation(String relation);

  /// No description provided for @ftCopyInvite.
  ///
  /// In en, this message translates to:
  /// **'Copy invite'**
  String get ftCopyInvite;

  /// No description provided for @ftWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get ftWithdraw;

  /// No description provided for @ftCouldNotWithdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not withdraw the request'**
  String get ftCouldNotWithdrawRequest;

  /// No description provided for @ftCouldNotUpdateRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not update the request'**
  String get ftCouldNotUpdateRequest;

  /// No description provided for @ftWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to connect.'**
  String ftWantsToConnect(String name);

  /// No description provided for @ftDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get ftDecline;

  /// No description provided for @ftAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get ftAccept;

  /// No description provided for @ftYourInvitations.
  ///
  /// In en, this message translates to:
  /// **'Your Invitations'**
  String get ftYourInvitations;

  /// No description provided for @ftAllSet.
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get ftAllSet;

  /// No description provided for @ftConnectedTreesMerged.
  ///
  /// In en, this message translates to:
  /// **'Connected - your trees are now merged.'**
  String get ftConnectedTreesMerged;

  /// No description provided for @ftDone.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get ftDone;

  /// No description provided for @ftInvitationsDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitations declined.'**
  String get ftInvitationsDeclined;

  /// No description provided for @ftCouldNotUpdateInvitations.
  ///
  /// In en, this message translates to:
  /// **'Could not update the invitations'**
  String get ftCouldNotUpdateInvitations;

  /// No description provided for @ftNoInvitations.
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get ftNoInvitations;

  /// No description provided for @ftNoInvitationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Invitations others send to your number will appear here.'**
  String get ftNoInvitationsDesc;

  /// No description provided for @ftAcceptingMergesNote.
  ///
  /// In en, this message translates to:
  /// **'Accepting confirms these people are your family and merges their placeholder profiles into your account.'**
  String get ftAcceptingMergesNote;

  /// No description provided for @ftAcceptAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Accept & Connect'**
  String get ftAcceptAndConnect;

  /// No description provided for @ftNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get ftNotifications;

  /// No description provided for @ftMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get ftMarkAllRead;

  /// No description provided for @ftNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get ftNoNotifications;

  /// No description provided for @ftNoNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Relationship activity - requests, joins, merges - appears here.'**
  String get ftNoNotificationsDesc;

  /// No description provided for @ftAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get ftAccepted;

  /// No description provided for @ftDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get ftDeclined;

  /// No description provided for @ftSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get ftSomeone;

  /// No description provided for @invTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invTitle;

  /// No description provided for @invCouldNotLoadMap.
  ///
  /// In en, this message translates to:
  /// **'Could not load the map'**
  String get invCouldNotLoadMap;

  /// No description provided for @invRoutePlanError.
  ///
  /// In en, this message translates to:
  /// **'Could not plan the route'**
  String get invRoutePlanError;

  /// No description provided for @invCouldNotReadLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not read your location'**
  String get invCouldNotReadLocation;

  /// No description provided for @invSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one family to begin.'**
  String get invSelectAtLeastOne;

  /// No description provided for @invNoMapsApp.
  ///
  /// In en, this message translates to:
  /// **'No maps app could open the route'**
  String get invNoMapsApp;

  /// No description provided for @invNavigatingFirst10.
  ///
  /// In en, this message translates to:
  /// **'Navigating the first 10 stops - maps can only take that many at once ({dropped} left for the next trip).'**
  String invNavigatingFirst10(int dropped);

  /// No description provided for @invCouldNotOpenMapsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open a maps app'**
  String get invCouldNotOpenMapsApp;

  /// No description provided for @invCheckConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get invCheckConnectionRetry;

  /// No description provided for @invRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get invRetry;

  /// No description provided for @invRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get invRefresh;

  /// No description provided for @invNoMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members on the map yet'**
  String get invNoMembersYet;

  /// No description provided for @invNoMembersMatch.
  ///
  /// In en, this message translates to:
  /// **'No members match \"{query}\"'**
  String invNoMembersMatch(String query);

  /// No description provided for @invNoMembersYetDetail.
  ///
  /// In en, this message translates to:
  /// **'A member appears here once they save their current address - the address is what puts them on the map.'**
  String get invNoMembersYetDetail;

  /// No description provided for @invSearchMatchesDetail.
  ///
  /// In en, this message translates to:
  /// **'Search matches Samaj ID, username or phone number.'**
  String get invSearchMatchesDetail;

  /// No description provided for @invSmartPlanner.
  ///
  /// In en, this message translates to:
  /// **'SMART INVITATION PLANNER'**
  String get invSmartPlanner;

  /// No description provided for @invRoutePlanner.
  ///
  /// In en, this message translates to:
  /// **'Route Planner'**
  String get invRoutePlanner;

  /// No description provided for @invSelectFamiliesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select families · the route orders itself'**
  String get invSelectFamiliesSubtitle;

  /// No description provided for @invShowingNearest.
  ///
  /// In en, this message translates to:
  /// **'Showing the {shown} nearest of {total} mapped members.'**
  String invShowingNearest(int shown, int total);

  /// No description provided for @invStartFrom.
  ///
  /// In en, this message translates to:
  /// **'START FROM'**
  String get invStartFrom;

  /// No description provided for @invLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get invLocating;

  /// No description provided for @invWaitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your location'**
  String get invWaitingForLocation;

  /// No description provided for @invCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location · {lat}, {lng}'**
  String invCurrentLocation(String lat, String lng);

  /// No description provided for @invUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get invUpdate;

  /// No description provided for @invSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, area or Samaj ID'**
  String get invSearchHint;

  /// No description provided for @invLoadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading the map…'**
  String get invLoadingMap;

  /// No description provided for @invSelectFamiliesToPlan.
  ///
  /// In en, this message translates to:
  /// **'Select families to plan a route'**
  String get invSelectFamiliesToPlan;

  /// No description provided for @invFromTheStart.
  ///
  /// In en, this message translates to:
  /// **'{km} from the start'**
  String invFromTheStart(String km);

  /// No description provided for @invFromStopN.
  ///
  /// In en, this message translates to:
  /// **'{km} from stop {n}'**
  String invFromStopN(String km, int n);

  /// No description provided for @invAway.
  ///
  /// In en, this message translates to:
  /// **'{km} away'**
  String invAway(String km);

  /// No description provided for @invOptimisingRoute.
  ///
  /// In en, this message translates to:
  /// **'Optimising the route…'**
  String get invOptimisingRoute;

  /// No description provided for @invPickFamilies.
  ///
  /// In en, this message translates to:
  /// **'Pick the families to visit'**
  String get invPickFamilies;

  /// No description provided for @invStraightLineEstimate.
  ///
  /// In en, this message translates to:
  /// **' (straight-line estimate)'**
  String get invStraightLineEstimate;

  /// No description provided for @invStop.
  ///
  /// In en, this message translates to:
  /// **'stop'**
  String get invStop;

  /// No description provided for @invStops.
  ///
  /// In en, this message translates to:
  /// **'stops'**
  String get invStops;

  /// No description provided for @invStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get invStartNavigation;

  /// No description provided for @dirTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Directory'**
  String get dirTitle;

  /// No description provided for @dirSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search members, gotras, or locations…'**
  String get dirSearchHint;

  /// No description provided for @dirAdvancedFiltersSoon.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters coming soon'**
  String get dirAdvancedFiltersSoon;

  /// No description provided for @dirAllMembers.
  ///
  /// In en, this message translates to:
  /// **'All Members'**
  String get dirAllMembers;

  /// No description provided for @dirNearbyMe.
  ///
  /// In en, this message translates to:
  /// **'Nearby Me'**
  String get dirNearbyMe;

  /// No description provided for @dirByArea.
  ///
  /// In en, this message translates to:
  /// **'By Area'**
  String get dirByArea;

  /// No description provided for @dirByGotra.
  ///
  /// In en, this message translates to:
  /// **'By Gotra'**
  String get dirByGotra;

  /// No description provided for @dirByOccupation.
  ///
  /// In en, this message translates to:
  /// **'By Occupation'**
  String get dirByOccupation;

  /// No description provided for @dirMapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get dirMapView;

  /// No description provided for @dirNearbyMembers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Members'**
  String get dirNearbyMembers;

  /// No description provided for @dirViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All →'**
  String get dirViewAll;

  /// No description provided for @dirFromNativePlaceFirst.
  ///
  /// In en, this message translates to:
  /// **'From your native place first'**
  String get dirFromNativePlaceFirst;

  /// No description provided for @dirNoOtherMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No other members yet.'**
  String get dirNoOtherMembersYet;

  /// No description provided for @dirSuggestedConnections.
  ///
  /// In en, this message translates to:
  /// **'Suggested Connections'**
  String get dirSuggestedConnections;

  /// No description provided for @dirNoMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get dirNoMembersYet;

  /// No description provided for @dirNoMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get dirNoMembersFound;

  /// No description provided for @dirMembersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Members appear here as your Vamsha Vruksha grows.'**
  String get dirMembersAppearHere;

  /// No description provided for @dirGotraSuffix.
  ///
  /// In en, this message translates to:
  /// **'{gotra} Gotra'**
  String dirGotraSuffix(String gotra);

  /// No description provided for @dirMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get dirMessage;

  /// No description provided for @dirConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get dirConnect;

  /// No description provided for @dirSameGotra.
  ///
  /// In en, this message translates to:
  /// **'SAME GOTRA'**
  String get dirSameGotra;

  /// No description provided for @dirReasonWithOcc.
  ///
  /// In en, this message translates to:
  /// **'{occ} · shares your {gotra} gotra.'**
  String dirReasonWithOcc(String occ, String gotra);

  /// No description provided for @dirReasonNoOcc.
  ///
  /// In en, this message translates to:
  /// **'Shares your {gotra} gotra, rooted in {place}.'**
  String dirReasonNoOcc(String gotra, String place);

  /// No description provided for @dirViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get dirViewProfile;

  /// No description provided for @dirCommunityMap.
  ///
  /// In en, this message translates to:
  /// **'Community Map'**
  String get dirCommunityMap;

  /// No description provided for @dirMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{n} members'**
  String dirMembersCount(int n);

  /// No description provided for @dirExploreRegion.
  ///
  /// In en, this message translates to:
  /// **'Explore Region'**
  String get dirExploreRegion;

  /// No description provided for @dirSamajMember.
  ///
  /// In en, this message translates to:
  /// **'Samaj member'**
  String get dirSamajMember;

  /// No description provided for @dirGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dirGroupOther;

  /// No description provided for @dirGroupNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get dirGroupNotSpecified;

  /// No description provided for @dirNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get dirNumberCopied;

  /// No description provided for @dirGotra.
  ///
  /// In en, this message translates to:
  /// **'Gotra'**
  String get dirGotra;

  /// No description provided for @dirNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get dirNative;

  /// No description provided for @dirOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get dirOccupation;

  /// No description provided for @dirPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get dirPhone;

  /// No description provided for @dirPhoneCopied.
  ///
  /// In en, this message translates to:
  /// **'{phone} copied'**
  String dirPhoneCopied(String phone);

  /// No description provided for @dirNoMembersToPlace.
  ///
  /// In en, this message translates to:
  /// **'No members to place on the map'**
  String get dirNoMembersToPlace;

  /// No description provided for @dirPhoneDisabled.
  ///
  /// In en, this message translates to:
  /// **'{name} has disabled their phone number. You cannot call them - send a message instead.'**
  String dirPhoneDisabled(String name);

  /// No description provided for @dirThisMember.
  ///
  /// In en, this message translates to:
  /// **'This member'**
  String get dirThisMember;

  /// No description provided for @dirCouldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open the dialer for {phone}'**
  String dirCouldNotOpenDialer(String phone);

  /// No description provided for @dirDefaultMemberName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get dirDefaultMemberName;

  /// No description provided for @matTitle.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial'**
  String get matTitle;

  /// No description provided for @matCouldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server'**
  String get matCouldNotReachServer;

  /// No description provided for @matProfileLive.
  ///
  /// In en, this message translates to:
  /// **'Your profile is live in the Matrimonial Hub'**
  String get matProfileLive;

  /// No description provided for @matCouldNotPublish.
  ///
  /// In en, this message translates to:
  /// **'Could not publish'**
  String get matCouldNotPublish;

  /// No description provided for @matCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get matCouldNotLoad;

  /// No description provided for @matTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get matTryAgain;

  /// No description provided for @matAddDob.
  ///
  /// In en, this message translates to:
  /// **'Add your date of birth'**
  String get matAddDob;

  /// No description provided for @matNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get matNotAvailable;

  /// No description provided for @matAgeRangeAddDob.
  ///
  /// In en, this message translates to:
  /// **'The matrimonial section is open to members aged {min}-{max}. Add your date of birth in your profile to continue.'**
  String matAgeRangeAddDob(String min, String max);

  /// No description provided for @matAgeRangeYourAge.
  ///
  /// In en, this message translates to:
  /// **'The matrimonial section is open to members aged {min}-{max}. Your age is {age}.'**
  String matAgeRangeYourAge(String min, String max, String age);

  /// No description provided for @matGoToMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to my profile'**
  String get matGoToMyProfile;

  /// No description provided for @matNotForMarried.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get matNotForMarried;

  /// No description provided for @matNotForMarriedBody.
  ///
  /// In en, this message translates to:
  /// **'The matrimonial hub is only for unmarried or divorced members. You told us you\'re married — you can change this in your profile if that\'s changed.'**
  String get matNotForMarriedBody;

  /// No description provided for @matReadyToPublish.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish'**
  String get matReadyToPublish;

  /// No description provided for @matDetailsCompletePublish.
  ///
  /// In en, this message translates to:
  /// **'Your details are complete. Publish your profile to enter the hub.'**
  String get matDetailsCompletePublish;

  /// No description provided for @matDetailsCompleteNote.
  ///
  /// In en, this message translates to:
  /// **'Your details are complete. Earlier note on this profile: {note}'**
  String matDetailsCompleteNote(String note);

  /// No description provided for @matPublishMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Publish my profile'**
  String get matPublishMyProfile;

  /// No description provided for @matHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial Hub'**
  String get matHubTitle;

  /// No description provided for @matProfileCompletePublish.
  ///
  /// In en, this message translates to:
  /// **'Your profile is complete. Publish it to enter the hub.'**
  String get matProfileCompletePublish;

  /// No description provided for @matCompleteToEnter.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to enter. Every field below is shown to prospective matches, so the hub stays trustworthy for everyone.'**
  String get matCompleteToEnter;

  /// No description provided for @matStillToFill.
  ///
  /// In en, this message translates to:
  /// **'STILL TO FILL'**
  String get matStillToFill;

  /// No description provided for @matRemaining.
  ///
  /// In en, this message translates to:
  /// **'{n} remaining'**
  String matRemaining(int n);

  /// No description provided for @matInYourProfile.
  ///
  /// In en, this message translates to:
  /// **'In your profile'**
  String get matInYourProfile;

  /// No description provided for @matEditMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit my profile'**
  String get matEditMyProfile;

  /// No description provided for @matInYourMatrimonialDetails.
  ///
  /// In en, this message translates to:
  /// **'In your matrimonial details'**
  String get matInYourMatrimonialDetails;

  /// No description provided for @matAddMatrimonialDetails.
  ///
  /// In en, this message translates to:
  /// **'Add matrimonial details'**
  String get matAddMatrimonialDetails;

  /// No description provided for @matAllDetailsFilledIn.
  ///
  /// In en, this message translates to:
  /// **'All required details are filled in.'**
  String get matAllDetailsFilledIn;

  /// No description provided for @matPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get matPublishing;

  /// No description provided for @matOptionalAadhaarNote.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verification is optional - every detail can be entered by hand. Your details are visible only to other members who have completed and published their own profile, and you can withdraw yours at any time.'**
  String get matOptionalAadhaarNote;

  /// No description provided for @matCouldNotLoadProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not load profiles'**
  String get matCouldNotLoadProfiles;

  /// No description provided for @matDiscoverMatches.
  ///
  /// In en, this message translates to:
  /// **'Discover Matches'**
  String get matDiscoverMatches;

  /// No description provided for @matShowingBrides.
  ///
  /// In en, this message translates to:
  /// **'Showing Brides'**
  String get matShowingBrides;

  /// No description provided for @matShowingGrooms.
  ///
  /// In en, this message translates to:
  /// **'Showing Grooms'**
  String get matShowingGrooms;

  /// No description provided for @matShowingAllProfiles.
  ///
  /// In en, this message translates to:
  /// **'Showing All Profiles'**
  String get matShowingAllProfiles;

  /// No description provided for @matProfilesCount.
  ///
  /// In en, this message translates to:
  /// **'{n} profiles'**
  String matProfilesCount(int n);

  /// No description provided for @matNoProfilesYet.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet'**
  String get matNoProfilesYet;

  /// No description provided for @matBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get matBride;

  /// No description provided for @matGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get matGroom;

  /// No description provided for @matVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get matVerified;

  /// No description provided for @matFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get matFree;

  /// No description provided for @matPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get matPremium;

  /// No description provided for @matViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get matViewProfile;

  /// No description provided for @matCandidateProfile.
  ///
  /// In en, this message translates to:
  /// **'Candidate Profile'**
  String get matCandidateProfile;

  /// No description provided for @matProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get matProfileNotFound;

  /// No description provided for @matBackToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Matrimonial Hub'**
  String get matBackToHub;

  /// No description provided for @matMatchSummary.
  ///
  /// In en, this message translates to:
  /// **'Match Summary'**
  String get matMatchSummary;

  /// No description provided for @matProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get matProfessional;

  /// No description provided for @matEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get matEducation;

  /// No description provided for @matCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get matCompany;

  /// No description provided for @matDesignation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get matDesignation;

  /// No description provided for @matAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get matAnnualIncome;

  /// No description provided for @matPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get matPersonal;

  /// No description provided for @matHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get matHeight;

  /// No description provided for @matComplexion.
  ///
  /// In en, this message translates to:
  /// **'Complexion'**
  String get matComplexion;

  /// No description provided for @matFamilyType.
  ///
  /// In en, this message translates to:
  /// **'Family Type'**
  String get matFamilyType;

  /// No description provided for @matFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get matFamily;

  /// No description provided for @matFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get matFather;

  /// No description provided for @matMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get matMother;

  /// No description provided for @matSiblings.
  ///
  /// In en, this message translates to:
  /// **'Number of siblings'**
  String get matSiblings;

  /// No description provided for @matHoroscope.
  ///
  /// In en, this message translates to:
  /// **'Horoscope'**
  String get matHoroscope;

  /// No description provided for @matStarNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Star / Nakshatra'**
  String get matStarNakshatra;

  /// No description provided for @matRashi.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get matRashi;

  /// No description provided for @matMangal.
  ///
  /// In en, this message translates to:
  /// **'Mangal'**
  String get matMangal;

  /// No description provided for @matMangalik.
  ///
  /// In en, this message translates to:
  /// **'Mangalik'**
  String get matMangalik;

  /// No description provided for @matNonMangalik.
  ///
  /// In en, this message translates to:
  /// **'Non-Mangalik'**
  String get matNonMangalik;

  /// No description provided for @matGotraSurname.
  ///
  /// In en, this message translates to:
  /// **'Gotra / Surname'**
  String get matGotraSurname;

  /// No description provided for @matTimeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Time of Birth'**
  String get matTimeOfBirth;

  /// No description provided for @matAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get matAbout;

  /// No description provided for @matInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get matInterests;

  /// No description provided for @matPartnerExpectations.
  ///
  /// In en, this message translates to:
  /// **'Partner Expectations'**
  String get matPartnerExpectations;

  /// No description provided for @matPremiumProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Profile'**
  String get matPremiumProfileTitle;

  /// No description provided for @matPremiumProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This is a premium profile. Connections are arranged exclusively through the Elder Committee. Please contact a Samaj elder to proceed with an introduction.'**
  String get matPremiumProfileBody;

  /// No description provided for @matUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get matUnderstood;

  /// No description provided for @matPremiumConnectViaElder.
  ///
  /// In en, this message translates to:
  /// **'Premium - Connect via Elder Committee'**
  String get matPremiumConnectViaElder;

  /// No description provided for @matCheckCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Check Compatibility'**
  String get matCheckCompatibility;

  /// No description provided for @matIntentionSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get matIntentionSoon;

  /// No description provided for @matIntentionOneToTwoYears.
  ///
  /// In en, this message translates to:
  /// **'1-2 Years'**
  String get matIntentionOneToTwoYears;

  /// No description provided for @matIntentionNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Not Decided'**
  String get matIntentionNotDecided;

  /// No description provided for @matChildrenWant.
  ///
  /// In en, this message translates to:
  /// **'Want'**
  String get matChildrenWant;

  /// No description provided for @matChildrenDontWant.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Want'**
  String get matChildrenDontWant;

  /// No description provided for @matChildrenOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get matChildrenOpen;

  /// No description provided for @matFamilyJoint.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get matFamilyJoint;

  /// No description provided for @matFamilyNuclear.
  ///
  /// In en, this message translates to:
  /// **'Nuclear'**
  String get matFamilyNuclear;

  /// No description provided for @matFamilyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get matFamilyFlexible;

  /// No description provided for @matRelocationYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get matRelocationYes;

  /// No description provided for @matRelocationNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get matRelocationNo;

  /// No description provided for @matRelocationMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get matRelocationMaybe;

  /// No description provided for @matFoodVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get matFoodVegetarian;

  /// No description provided for @matFoodNonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-Vegetarian'**
  String get matFoodNonVegetarian;

  /// No description provided for @matFoodEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get matFoodEggetarian;

  /// No description provided for @matFoodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get matFoodOther;

  /// No description provided for @matInterestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get matInterestTravel;

  /// No description provided for @matInterestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get matInterestMusic;

  /// No description provided for @matInterestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get matInterestMovies;

  /// No description provided for @matInterestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get matInterestFitness;

  /// No description provided for @matInterestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get matInterestSports;

  /// No description provided for @matInterestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get matInterestReading;

  /// No description provided for @matInterestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get matInterestCooking;

  /// No description provided for @matInterestSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get matInterestSpirituality;

  /// No description provided for @matEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial Details'**
  String get matEditTitle;

  /// No description provided for @matCouldNotLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load your details'**
  String get matCouldNotLoadDetails;

  /// No description provided for @matAgeFromToError.
  ///
  /// In en, this message translates to:
  /// **'Preferred partner age: \"from\" cannot be greater than \"to\"'**
  String get matAgeFromToError;

  /// No description provided for @matDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial details saved'**
  String get matDetailsSaved;

  /// No description provided for @matCouldNotSaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not save your details'**
  String get matCouldNotSaveDetails;

  /// No description provided for @matSectionCareer.
  ///
  /// In en, this message translates to:
  /// **'CAREER'**
  String get matSectionCareer;

  /// No description provided for @matEducationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MBA Finance, IIM Bangalore'**
  String get matEducationHint;

  /// No description provided for @matOccupationType.
  ///
  /// In en, this message translates to:
  /// **'Occupation type'**
  String get matOccupationType;

  /// No description provided for @matOccupationSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get matOccupationSalaried;

  /// No description provided for @matOccupationSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self Employed'**
  String get matOccupationSelfEmployed;

  /// No description provided for @matOccupationUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get matOccupationUnemployed;

  /// No description provided for @matCompanyOrg.
  ///
  /// In en, this message translates to:
  /// **'Company / organisation'**
  String get matCompanyOrg;

  /// No description provided for @matIncomeRange.
  ///
  /// In en, this message translates to:
  /// **'Income range'**
  String get matIncomeRange;

  /// No description provided for @matIncomeRangeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ₹22-28L'**
  String get matIncomeRangeHint;

  /// No description provided for @matSectionPhysical.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL'**
  String get matSectionPhysical;

  /// No description provided for @matComplexionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get matComplexionFair;

  /// No description provided for @matComplexionWheatish.
  ///
  /// In en, this message translates to:
  /// **'Wheatish'**
  String get matComplexionWheatish;

  /// No description provided for @matComplexionDusky.
  ///
  /// In en, this message translates to:
  /// **'Dusky'**
  String get matComplexionDusky;

  /// No description provided for @matComplexionDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get matComplexionDark;

  /// No description provided for @matSectionFamily.
  ///
  /// In en, this message translates to:
  /// **'FAMILY'**
  String get matSectionFamily;

  /// No description provided for @matFamilyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Family type'**
  String get matFamilyTypeLabel;

  /// No description provided for @matFathersOccupation.
  ///
  /// In en, this message translates to:
  /// **'Father\'s occupation'**
  String get matFathersOccupation;

  /// No description provided for @matMothersOccupation.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s occupation'**
  String get matMothersOccupation;

  /// No description provided for @matSiblingsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get matSiblingsHint;

  /// No description provided for @matSiblingsRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a number between 0 and 20'**
  String get matSiblingsRangeError;

  /// No description provided for @matSectionHoroscope.
  ///
  /// In en, this message translates to:
  /// **'HOROSCOPE'**
  String get matSectionHoroscope;

  /// No description provided for @matStarNakshatraLabel.
  ///
  /// In en, this message translates to:
  /// **'Star (nakshatra)'**
  String get matStarNakshatraLabel;

  /// No description provided for @matStarHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rohini'**
  String get matStarHint;

  /// No description provided for @matRashiHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vrishabha'**
  String get matRashiHint;

  /// No description provided for @matTimeOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get matTimeOfBirthLabel;

  /// No description provided for @matTimeOfBirthHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10:45 AM'**
  String get matTimeOfBirthHint;

  /// No description provided for @matSectionCompatibility.
  ///
  /// In en, this message translates to:
  /// **'COMPATIBILITY'**
  String get matSectionCompatibility;

  /// No description provided for @matAddBirthDetailsLink.
  ///
  /// In en, this message translates to:
  /// **'Add birth details for compatibility →'**
  String get matAddBirthDetailsLink;

  /// No description provided for @matManageConsentLink.
  ///
  /// In en, this message translates to:
  /// **'Manage compatibility consent →'**
  String get matManageConsentLink;

  /// No description provided for @matSectionAboutYou.
  ///
  /// In en, this message translates to:
  /// **'ABOUT YOU'**
  String get matSectionAboutYou;

  /// No description provided for @matAboutYouLabel.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get matAboutYouLabel;

  /// No description provided for @matSectionLookingFor.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU ARE LOOKING FOR'**
  String get matSectionLookingFor;

  /// No description provided for @matPartnerExpectationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner expectations'**
  String get matPartnerExpectationsLabel;

  /// No description provided for @matOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get matOnePerLine;

  /// No description provided for @matPreferredLocationsOptional.
  ///
  /// In en, this message translates to:
  /// **'Preferred locations (optional)'**
  String get matPreferredLocationsOptional;

  /// No description provided for @matPreferredLocationsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. Bengaluru, Mangaluru'**
  String get matPreferredLocationsHint;

  /// No description provided for @matGotrasToExcludeOptional.
  ///
  /// In en, this message translates to:
  /// **'Gotras to exclude (optional)'**
  String get matGotrasToExcludeOptional;

  /// No description provided for @matGotrasToExcludeHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated. Your own gotra is always excluded.'**
  String get matGotrasToExcludeHint;

  /// No description provided for @matSectionMarriagePreferences.
  ///
  /// In en, this message translates to:
  /// **'MARRIAGE PREFERENCES'**
  String get matSectionMarriagePreferences;

  /// No description provided for @matMarriageIntention.
  ///
  /// In en, this message translates to:
  /// **'Marriage intention'**
  String get matMarriageIntention;

  /// No description provided for @matChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get matChildren;

  /// No description provided for @matFamily2.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get matFamily2;

  /// No description provided for @matRelocation.
  ///
  /// In en, this message translates to:
  /// **'Relocation'**
  String get matRelocation;

  /// No description provided for @matSectionLifestyle.
  ///
  /// In en, this message translates to:
  /// **'LIFESTYLE'**
  String get matSectionLifestyle;

  /// No description provided for @matFoodPreference.
  ///
  /// In en, this message translates to:
  /// **'Food preference'**
  String get matFoodPreference;

  /// No description provided for @matSectionInterests.
  ///
  /// In en, this message translates to:
  /// **'INTERESTS'**
  String get matSectionInterests;

  /// No description provided for @matSaving2.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get matSaving2;

  /// No description provided for @matSaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get matSaveDetails;

  /// No description provided for @matSavedAsDraftNote.
  ///
  /// In en, this message translates to:
  /// **'Saved privately as a draft. You publish it from the Matrimonial section once everything is filled in.'**
  String get matSavedAsDraftNote;

  /// No description provided for @matHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get matHeightCm;

  /// No description provided for @matHeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 163'**
  String get matHeightHint;

  /// No description provided for @matEnterNumberInCm.
  ///
  /// In en, this message translates to:
  /// **'Enter a number in centimetres'**
  String get matEnterNumberInCm;

  /// No description provided for @matHeightRangeError.
  ///
  /// In en, this message translates to:
  /// **'Height must be between 120 and 250 cm'**
  String get matHeightRangeError;

  /// No description provided for @matHeightFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get matHeightFeet;

  /// No description provided for @matHeightFeetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5'**
  String get matHeightFeetHint;

  /// No description provided for @matHeightInches.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get matHeightInches;

  /// No description provided for @matHeightInchesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 7'**
  String get matHeightInchesHint;

  /// No description provided for @matHeightFeetRangeError.
  ///
  /// In en, this message translates to:
  /// **'Feet must be between 3 and 8'**
  String get matHeightFeetRangeError;

  /// No description provided for @matHeightInchesRangeError.
  ///
  /// In en, this message translates to:
  /// **'Inches must be between 0 and 11'**
  String get matHeightInchesRangeError;

  /// No description provided for @matMangalDosha.
  ///
  /// In en, this message translates to:
  /// **'Mangal dosha'**
  String get matMangalDosha;

  /// No description provided for @matPartnerAgeFrom.
  ///
  /// In en, this message translates to:
  /// **'Partner age from'**
  String get matPartnerAgeFrom;

  /// No description provided for @matPartnerAgeTo.
  ///
  /// In en, this message translates to:
  /// **'Partner age to'**
  String get matPartnerAgeTo;

  /// No description provided for @welfareTitle.
  ///
  /// In en, this message translates to:
  /// **'Welfare'**
  String get welfareTitle;

  /// No description provided for @welfareStartCampaign.
  ///
  /// In en, this message translates to:
  /// **'Start a Campaign'**
  String get welfareStartCampaign;

  /// No description provided for @welfareKicker.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY WELFARE & DEVELOPMENT'**
  String get welfareKicker;

  /// No description provided for @welfareHeroLine.
  ///
  /// In en, this message translates to:
  /// **'Build the Samaj tree, one contribution at a time.'**
  String get welfareHeroLine;

  /// No description provided for @welfareTotalRaised.
  ///
  /// In en, this message translates to:
  /// **'Total Raised'**
  String get welfareTotalRaised;

  /// No description provided for @welfareTotalBackers.
  ///
  /// In en, this message translates to:
  /// **'Total Backers'**
  String get welfareTotalBackers;

  /// No description provided for @welfareActiveCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Active Fundraising Campaigns'**
  String get welfareActiveCampaigns;

  /// No description provided for @welfareRaised.
  ///
  /// In en, this message translates to:
  /// **'{amount} raised'**
  String welfareRaised(String amount);

  /// No description provided for @welfareOfGoalPct.
  ///
  /// In en, this message translates to:
  /// **'of {goal} · {pct}%'**
  String welfareOfGoalPct(String goal, int pct);

  /// No description provided for @welfareDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} days left'**
  String welfareDaysLeft(int n);

  /// No description provided for @welfareBackers.
  ///
  /// In en, this message translates to:
  /// **'{n} backers'**
  String welfareBackers(int n);

  /// No description provided for @welfareDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get welfareDonate;

  /// No description provided for @welfareImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Heritage Impact 2024-25'**
  String get welfareImpactTitle;

  /// No description provided for @welfareImpactBody.
  ///
  /// In en, this message translates to:
  /// **'See exactly where every rupee goes - full transparency report.'**
  String get welfareImpactBody;

  /// No description provided for @welfareViewImpactReport.
  ///
  /// In en, this message translates to:
  /// **'View Impact Report'**
  String get welfareViewImpactReport;

  /// No description provided for @welfareDhanyavaad.
  ///
  /// In en, this message translates to:
  /// **'Dhanyavaad! 🙏'**
  String get welfareDhanyavaad;

  /// No description provided for @welfareThankYouReceived.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your contribution to {title} is received.'**
  String welfareThankYouReceived(String title);

  /// No description provided for @welfareBackToWelfare.
  ///
  /// In en, this message translates to:
  /// **'Back to Welfare'**
  String get welfareBackToWelfare;

  /// No description provided for @welfareMakeContribution.
  ///
  /// In en, this message translates to:
  /// **'Make a Contribution'**
  String get welfareMakeContribution;

  /// No description provided for @welfareCampaignNotFound.
  ///
  /// In en, this message translates to:
  /// **'Campaign not found'**
  String get welfareCampaignNotFound;

  /// No description provided for @welfarePctLabel.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String welfarePctLabel(int pct);

  /// No description provided for @welfareDaysLeftContributors.
  ///
  /// In en, this message translates to:
  /// **'{days} days left · {backers} contributors'**
  String welfareDaysLeftContributors(int days, int backers);

  /// No description provided for @welfareTransparencyPledge.
  ///
  /// In en, this message translates to:
  /// **'Transparency Pledge'**
  String get welfareTransparencyPledge;

  /// No description provided for @welfareTransparencyPledgeBody.
  ///
  /// In en, this message translates to:
  /// **'100% of your contribution flows directly to a monitored committee account, published quarterly in the Impact Report.'**
  String get welfareTransparencyPledgeBody;

  /// No description provided for @welfareSelectAmount.
  ///
  /// In en, this message translates to:
  /// **'SELECT AMOUNT (₹)'**
  String get welfareSelectAmount;

  /// No description provided for @welfareEnterCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter custom amount'**
  String get welfareEnterCustomAmount;

  /// No description provided for @welfareDonorName.
  ///
  /// In en, this message translates to:
  /// **'DONOR NAME'**
  String get welfareDonorName;

  /// No description provided for @welfareAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get welfareAnonymous;

  /// No description provided for @welfareYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get welfareYourName;

  /// No description provided for @welfareDonateAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Donate anonymously'**
  String get welfareDonateAnonymously;

  /// No description provided for @welfarePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get welfarePaymentMethod;

  /// No description provided for @welfareUpiQr.
  ///
  /// In en, this message translates to:
  /// **'UPI / QR Code'**
  String get welfareUpiQr;

  /// No description provided for @welfareCreditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get welfareCreditDebitCard;

  /// No description provided for @welfareNetBanking.
  ///
  /// In en, this message translates to:
  /// **'Net Banking'**
  String get welfareNetBanking;

  /// No description provided for @welfareDonateAmount.
  ///
  /// In en, this message translates to:
  /// **'Donate ₹{amount}'**
  String welfareDonateAmount(String amount);

  /// No description provided for @welfareImpactReport.
  ///
  /// In en, this message translates to:
  /// **'Impact Report'**
  String get welfareImpactReport;

  /// No description provided for @welfareAnnualReportKicker.
  ///
  /// In en, this message translates to:
  /// **'DAIVAJNA SAMAJA BANGALORE - ANNUAL TRANSPARENCY REPORT'**
  String get welfareAnnualReportKicker;

  /// No description provided for @welfareRecordOfContributions.
  ///
  /// In en, this message translates to:
  /// **'A record of our community’s generous contributions and their measurable outcomes.'**
  String get welfareRecordOfContributions;

  /// No description provided for @welfareFamiliesHelped.
  ///
  /// In en, this message translates to:
  /// **'Families Helped'**
  String get welfareFamiliesHelped;

  /// No description provided for @welfareCampaignsFunded.
  ///
  /// In en, this message translates to:
  /// **'Campaigns Funded'**
  String get welfareCampaignsFunded;

  /// No description provided for @welfareScholarships.
  ///
  /// In en, this message translates to:
  /// **'Scholarships'**
  String get welfareScholarships;

  /// No description provided for @welfareCategoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get welfareCategoryBreakdown;

  /// No description provided for @welfareCategoryBreakdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of funds raised by campaign category'**
  String get welfareCategoryBreakdownSubtitle;

  /// No description provided for @welfareFundAllocation.
  ///
  /// In en, this message translates to:
  /// **'Fund Allocation'**
  String get welfareFundAllocation;

  /// No description provided for @welfareAuditQuote.
  ///
  /// In en, this message translates to:
  /// **'“Every rupee documented. Every decision transparent.” - Daivajna Audit Committee'**
  String get welfareAuditQuote;

  /// No description provided for @welfareGuardianDonors.
  ///
  /// In en, this message translates to:
  /// **'Guardian Donors'**
  String get welfareGuardianDonors;

  /// No description provided for @welfareSupportCampaign.
  ///
  /// In en, this message translates to:
  /// **'Support a Campaign'**
  String get welfareSupportCampaign;

  /// No description provided for @welfareAllocTempleHeritage.
  ///
  /// In en, this message translates to:
  /// **'Temple & Heritage'**
  String get welfareAllocTempleHeritage;

  /// No description provided for @welfareAllocEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get welfareAllocEducation;

  /// No description provided for @welfareAllocHealthWelfare.
  ///
  /// In en, this message translates to:
  /// **'Health & Welfare'**
  String get welfareAllocHealthWelfare;

  /// No description provided for @welfareAllocCulturalEvents.
  ///
  /// In en, this message translates to:
  /// **'Cultural Events'**
  String get welfareAllocCulturalEvents;

  /// No description provided for @welfareDonorHeadRole.
  ///
  /// In en, this message translates to:
  /// **'Elder Committee Head'**
  String get welfareDonorHeadRole;

  /// No description provided for @welfareDonorPatronRole.
  ///
  /// In en, this message translates to:
  /// **'Samaj Life Patron'**
  String get welfareDonorPatronRole;

  /// No description provided for @welfareDonorItRole.
  ///
  /// In en, this message translates to:
  /// **'IT Professionals Chapter'**
  String get welfareDonorItRole;

  /// No description provided for @welfareDonorEntrepreneurRole.
  ///
  /// In en, this message translates to:
  /// **'Entrepreneur, Bengaluru'**
  String get welfareDonorEntrepreneurRole;

  /// No description provided for @welfareTestimonial1.
  ///
  /// In en, this message translates to:
  /// **'“This temple is proof that our Samaj never forgets its roots.”'**
  String get welfareTestimonial1;

  /// No description provided for @welfareTestimonial1Author.
  ///
  /// In en, this message translates to:
  /// **'Priya K., Community Member'**
  String get welfareTestimonial1Author;

  /// No description provided for @welfareTestimonial2.
  ///
  /// In en, this message translates to:
  /// **'“The scholarship let me finish my engineering degree. I am forever grateful to the Samaj.”'**
  String get welfareTestimonial2;

  /// No description provided for @welfareTestimonial2Author.
  ///
  /// In en, this message translates to:
  /// **'Asha H., Gokarna'**
  String get welfareTestimonial2Author;

  /// No description provided for @welfareCampaignSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Campaign Submitted!'**
  String get welfareCampaignSubmitted;

  /// No description provided for @welfareCampaignReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Your campaign will be reviewed by the Elder Committee. You’ll receive a notification within 48 hours.'**
  String get welfareCampaignReviewNote;

  /// No description provided for @welfareLaunchNewCampaign.
  ///
  /// In en, this message translates to:
  /// **'Launch a New Campaign'**
  String get welfareLaunchNewCampaign;

  /// No description provided for @welfareTransparencyNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'A Note on Transparency'**
  String get welfareTransparencyNoteTitle;

  /// No description provided for @welfareTransparencyNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Each campaign is vetted by the Elder sub-committee to ensure heritage alignment and financial integrity.'**
  String get welfareTransparencyNoteBody;

  /// No description provided for @welfareCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign Title'**
  String get welfareCampaignTitle;

  /// No description provided for @welfareCampaignTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Restoration of Heritage Library'**
  String get welfareCampaignTitleHint;

  /// No description provided for @welfareCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get welfareCategory;

  /// No description provided for @welfareCampaignStory.
  ///
  /// In en, this message translates to:
  /// **'Campaign Story'**
  String get welfareCampaignStory;

  /// No description provided for @welfareCampaignStoryHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the history, the need, and the impact on our community…'**
  String get welfareCampaignStoryHint;

  /// No description provided for @welfareFundraisingGoal.
  ///
  /// In en, this message translates to:
  /// **'Fundraising Goal (₹)'**
  String get welfareFundraisingGoal;

  /// No description provided for @welfareFundraisingGoalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500000'**
  String get welfareFundraisingGoalHint;

  /// No description provided for @welfareDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get welfareDuration;

  /// No description provided for @welfareDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String welfareDurationDays(int n);

  /// No description provided for @welfareChooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an Icon'**
  String get welfareChooseIcon;

  /// No description provided for @welfareVerificationChecklist.
  ///
  /// In en, this message translates to:
  /// **'Verification Checklist'**
  String get welfareVerificationChecklist;

  /// No description provided for @welfareCheckCommunityBenefit.
  ///
  /// In en, this message translates to:
  /// **'Campaign is for community benefit'**
  String get welfareCheckCommunityBenefit;

  /// No description provided for @welfareCheckFundsManaged.
  ///
  /// In en, this message translates to:
  /// **'Funds will be managed by committee'**
  String get welfareCheckFundsManaged;

  /// No description provided for @welfareCheckMonthlyReports.
  ///
  /// In en, this message translates to:
  /// **'Monthly progress reports will be shared'**
  String get welfareCheckMonthlyReports;

  /// No description provided for @welfareCheckEldersInformed.
  ///
  /// In en, this message translates to:
  /// **'Elder sub-committee has been informed'**
  String get welfareCheckEldersInformed;

  /// No description provided for @welfareSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get welfareSubmitForReview;

  /// No description provided for @welfareCategoryInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get welfareCategoryInfrastructure;

  /// No description provided for @welfareCategoryCulturalHeritage.
  ///
  /// In en, this message translates to:
  /// **'Cultural Heritage'**
  String get welfareCategoryCulturalHeritage;

  /// No description provided for @welfareCategoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get welfareCategoryEducation;

  /// No description provided for @welfareCategoryEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get welfareCategoryEmergency;

  /// No description provided for @welfareCategoryHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get welfareCategoryHealthcare;

  /// No description provided for @elderDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Elder'**
  String get elderDefaultName;

  /// No description provided for @elderHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get elderHighRisk;

  /// No description provided for @elderMedRisk.
  ///
  /// In en, this message translates to:
  /// **'Med Risk'**
  String get elderMedRisk;

  /// No description provided for @elderLowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get elderLowRisk;

  /// No description provided for @elderLineageTree.
  ///
  /// In en, this message translates to:
  /// **'Lineage Tree'**
  String get elderLineageTree;

  /// No description provided for @elderPortalKicker.
  ///
  /// In en, this message translates to:
  /// **'ELDER PORTAL · DAIVAJNA SAMAJA'**
  String get elderPortalKicker;

  /// No description provided for @elderWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String elderWelcomeBack(String name);

  /// No description provided for @elderGuardianOfTree.
  ///
  /// In en, this message translates to:
  /// **'Guardian of the Tree'**
  String get elderGuardianOfTree;

  /// No description provided for @elderDashboardBlurb.
  ///
  /// In en, this message translates to:
  /// **'Your lineage oversight and community management dashboard. Review pending verifications, resolve conflicts, and guide the Samaja.'**
  String get elderDashboardBlurb;

  /// No description provided for @elderPendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending Verifications'**
  String get elderPendingVerifications;

  /// No description provided for @elderActiveConflicts.
  ///
  /// In en, this message translates to:
  /// **'Active Conflicts'**
  String get elderActiveConflicts;

  /// No description provided for @elderTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get elderTotalMembers;

  /// No description provided for @elderActiveBranches.
  ///
  /// In en, this message translates to:
  /// **'Active Branches'**
  String get elderActiveBranches;

  /// No description provided for @elderPendingMemberRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Member Requests'**
  String get elderPendingMemberRequests;

  /// No description provided for @elderReview.
  ///
  /// In en, this message translates to:
  /// **'Review →'**
  String get elderReview;

  /// No description provided for @elderVouches.
  ///
  /// In en, this message translates to:
  /// **'Vouches: {have}/{required}'**
  String elderVouches(int have, int required);

  /// No description provided for @elderTreeAlertsConflicts.
  ///
  /// In en, this message translates to:
  /// **'Tree Alerts & Conflicts'**
  String get elderTreeAlertsConflicts;

  /// No description provided for @elderAlertSample.
  ///
  /// In en, this message translates to:
  /// **'\"Ananth Rao (1892-1954)\" appears in both Mysore and Bangalore branches with conflicting parentage.'**
  String get elderAlertSample;

  /// No description provided for @elderResolveNow.
  ///
  /// In en, this message translates to:
  /// **'Resolve Now →'**
  String get elderResolveNow;

  /// No description provided for @elderMemberDirectory.
  ///
  /// In en, this message translates to:
  /// **'Member Directory'**
  String get elderMemberDirectory;

  /// No description provided for @elderDigitalArchive.
  ///
  /// In en, this message translates to:
  /// **'Digital Archive'**
  String get elderDigitalArchive;

  /// No description provided for @elderManageEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get elderManageEvents;

  /// No description provided for @elderVerifications.
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get elderVerifications;

  /// No description provided for @elderManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get elderManagement;

  /// No description provided for @elderLineageWisdom.
  ///
  /// In en, this message translates to:
  /// **'LINEAGE WISDOM'**
  String get elderLineageWisdom;

  /// No description provided for @elderLineageQuote.
  ///
  /// In en, this message translates to:
  /// **'\"A tree without roots is just wood; a community without history is just a crowd.\"'**
  String get elderLineageQuote;

  /// No description provided for @elderMemberRequests.
  ///
  /// In en, this message translates to:
  /// **'Member Requests'**
  String get elderMemberRequests;

  /// No description provided for @elderRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'RISK LEVEL'**
  String get elderRiskLevel;

  /// No description provided for @elderAadhaarStatus.
  ///
  /// In en, this message translates to:
  /// **'AADHAAR STATUS'**
  String get elderAadhaarStatus;

  /// No description provided for @elderAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get elderAll;

  /// No description provided for @elderPendingClaims.
  ///
  /// In en, this message translates to:
  /// **'Pending Claims ({n})'**
  String elderPendingClaims(int n);

  /// No description provided for @elderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get elderMale;

  /// No description provided for @elderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get elderFemale;

  /// No description provided for @elderAgeGenderGotra.
  ///
  /// In en, this message translates to:
  /// **'Age: {age} · {gender} · {gotra} Gotra'**
  String elderAgeGenderGotra(String age, String gender, String gotra);

  /// No description provided for @elderLineageNode.
  ///
  /// In en, this message translates to:
  /// **'Lineage Node'**
  String get elderLineageNode;

  /// No description provided for @elderRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get elderRelation;

  /// No description provided for @elderVouchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Vouches'**
  String get elderVouchesLabel;

  /// No description provided for @elderVouchesOfRequired.
  ///
  /// In en, this message translates to:
  /// **'{have} / {required}'**
  String elderVouchesOfRequired(int have, int required);

  /// No description provided for @elderAadhaarPrefix.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar: {status}'**
  String elderAadhaarPrefix(String status);

  /// No description provided for @elderSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String elderSubmittedOn(String date);

  /// No description provided for @elderNoRequestsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No requests match your filter'**
  String get elderNoRequestsMatchFilter;

  /// No description provided for @elderMediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get elderMediumRisk;

  /// No description provided for @elderVerificationDetail.
  ///
  /// In en, this message translates to:
  /// **'Verification Detail'**
  String get elderVerificationDetail;

  /// No description provided for @elderVerificationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Verification request not found'**
  String get elderVerificationNotFound;

  /// No description provided for @elderBackToQueue.
  ///
  /// In en, this message translates to:
  /// **'Back to Queue'**
  String get elderBackToQueue;

  /// No description provided for @elderLineageClaim.
  ///
  /// In en, this message translates to:
  /// **'Lineage Claim'**
  String get elderLineageClaim;

  /// No description provided for @elderClaimingFrom.
  ///
  /// In en, this message translates to:
  /// **'Claiming From'**
  String get elderClaimingFrom;

  /// No description provided for @elderClaimingAncestor.
  ///
  /// In en, this message translates to:
  /// **'Claiming Ancestor'**
  String get elderClaimingAncestor;

  /// No description provided for @elderStatedRelation.
  ///
  /// In en, this message translates to:
  /// **'Stated Relation'**
  String get elderStatedRelation;

  /// No description provided for @elderSubmittedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted On'**
  String get elderSubmittedOnLabel;

  /// No description provided for @elderIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get elderIdentity;

  /// No description provided for @elderAadhaarStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Status'**
  String get elderAadhaarStatusLabel;

  /// No description provided for @elderPhoneColon.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String elderPhoneColon(String phone);

  /// No description provided for @elderSubmittedDocuments.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED DOCUMENTS'**
  String get elderSubmittedDocuments;

  /// No description provided for @elderReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get elderReceived;

  /// No description provided for @elderPeerVouchesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Peer Vouches ({have}/{required} confirmed)'**
  String elderPeerVouchesConfirmed(int have, int required);

  /// No description provided for @elderYrsGenderGotra.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs · {gender} · {gotra} Gotra'**
  String elderYrsGenderGotra(String age, String gender, String gotra);

  /// No description provided for @elderOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get elderOccupation;

  /// No description provided for @elderLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get elderLocation;

  /// No description provided for @elderPhoneMasked.
  ///
  /// In en, this message translates to:
  /// **'Phone (masked)'**
  String get elderPhoneMasked;

  /// No description provided for @elderRiskAssessment.
  ///
  /// In en, this message translates to:
  /// **'Risk Assessment: {level}'**
  String elderRiskAssessment(String level);

  /// No description provided for @elderCommitteeNotes.
  ///
  /// In en, this message translates to:
  /// **'Elder Committee Notes'**
  String get elderCommitteeNotes;

  /// No description provided for @elderApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get elderApprove;

  /// No description provided for @elderRequestMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Request More Info'**
  String get elderRequestMoreInfo;

  /// No description provided for @elderReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get elderReject;

  /// No description provided for @elderVerificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verification Approved'**
  String get elderVerificationApproved;

  /// No description provided for @elderVerificationApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be officially added to the Samaj registry. A notification will be sent to the applicant.'**
  String elderVerificationApprovedBody(String name);

  /// No description provided for @elderInfoRequested.
  ///
  /// In en, this message translates to:
  /// **'Information Requested'**
  String get elderInfoRequested;

  /// No description provided for @elderInfoRequestedBody.
  ///
  /// In en, this message translates to:
  /// **'A query has been sent to {name} requesting additional documents or clarification. Case paused pending response.'**
  String elderInfoRequestedBody(String name);

  /// No description provided for @elderRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get elderRequestRejected;

  /// No description provided for @elderRequestRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'The verification request for {name} has been rejected. The applicant will be notified with a reason.'**
  String elderRequestRejectedBody(String name);

  /// No description provided for @elderCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get elderCommunity;

  /// No description provided for @elderSearchByNameGotraOcc.
  ///
  /// In en, this message translates to:
  /// **'Search by name, gotra, occupation…'**
  String get elderSearchByNameGotraOcc;

  /// No description provided for @elderVerifiedMembersOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified members only'**
  String get elderVerifiedMembersOnly;

  /// No description provided for @elderShownCount.
  ///
  /// In en, this message translates to:
  /// **'{n} shown'**
  String elderShownCount(int n);

  /// No description provided for @elderRegistryKicker.
  ///
  /// In en, this message translates to:
  /// **'DAIVAJNA SAMAJA BANGALORE'**
  String get elderRegistryKicker;

  /// No description provided for @elderCommunityMemberRegistry.
  ///
  /// In en, this message translates to:
  /// **'Community Member Registry'**
  String get elderCommunityMemberRegistry;

  /// No description provided for @elderShowingOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of 1,428 registered members'**
  String elderShowingOfTotal(int shown);

  /// No description provided for @elderStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get elderStatTotal;

  /// No description provided for @elderStatVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get elderStatVerified;

  /// No description provided for @elderStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get elderStatPending;

  /// No description provided for @elderStatBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get elderStatBranches;

  /// No description provided for @elderUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get elderUnverified;

  /// No description provided for @elderYrsGender.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs · {gender}'**
  String elderYrsGender(String age, String gender);

  /// No description provided for @elderBranchSuffix.
  ///
  /// In en, this message translates to:
  /// **'{branch} Branch'**
  String elderBranchSuffix(String branch);

  /// No description provided for @elderGotraSuffix.
  ///
  /// In en, this message translates to:
  /// **'{gotra} Gotra'**
  String elderGotraSuffix(String gotra);

  /// No description provided for @elderSinceYear.
  ///
  /// In en, this message translates to:
  /// **'Since {year}'**
  String elderSinceYear(String year);

  /// No description provided for @elderViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get elderViewProfile;

  /// No description provided for @elderPromoteToElder.
  ///
  /// In en, this message translates to:
  /// **'Promote to Elder'**
  String get elderPromoteToElder;

  /// No description provided for @elderSuspendMember.
  ///
  /// In en, this message translates to:
  /// **'Suspend member'**
  String get elderSuspendMember;

  /// No description provided for @elderNoMembersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No members match your filter'**
  String get elderNoMembersMatchFilter;

  /// No description provided for @elderArchives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get elderArchives;

  /// No description provided for @elderHeritageMemoryArchive.
  ///
  /// In en, this message translates to:
  /// **'Heritage Memory Archive'**
  String get elderHeritageMemoryArchive;

  /// No description provided for @elderOurLivingHistory.
  ///
  /// In en, this message translates to:
  /// **'Our Living History'**
  String get elderOurLivingHistory;

  /// No description provided for @elderLivingHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photographs, charters and oral histories of the Daivajna Samaja'**
  String get elderLivingHistorySubtitle;

  /// No description provided for @elderUploadMemory.
  ///
  /// In en, this message translates to:
  /// **'Upload a Memory'**
  String get elderUploadMemory;

  /// No description provided for @elderUploadMemoryToast.
  ///
  /// In en, this message translates to:
  /// **'Memory upload - opening contributor form'**
  String get elderUploadMemoryToast;

  /// No description provided for @elderContributedBy.
  ///
  /// In en, this message translates to:
  /// **'Contributed by {name}'**
  String elderContributedBy(String name);

  /// No description provided for @elderClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get elderClose;

  /// No description provided for @elderTagCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get elderTagCultural;

  /// No description provided for @elderTagHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get elderTagHeritage;

  /// No description provided for @elderTagLineage.
  ///
  /// In en, this message translates to:
  /// **'Lineage'**
  String get elderTagLineage;

  /// No description provided for @elderTagDevotional.
  ///
  /// In en, this message translates to:
  /// **'Devotional'**
  String get elderTagDevotional;

  /// No description provided for @elderMem1Title.
  ///
  /// In en, this message translates to:
  /// **'1968 Samaj Utsava in Kumta'**
  String get elderMem1Title;

  /// No description provided for @elderMem1Caption.
  ///
  /// In en, this message translates to:
  /// **'The first inter-village Samaja Utsava bringing together goldsmith families from Kumta, Kundapura and Honnavar.'**
  String get elderMem1Caption;

  /// No description provided for @elderMem1Contributor.
  ///
  /// In en, this message translates to:
  /// **'Venkatesh Haldankar'**
  String get elderMem1Contributor;

  /// No description provided for @elderMem2Title.
  ///
  /// In en, this message translates to:
  /// **'First Samaj Bhavan, 1974'**
  String get elderMem2Title;

  /// No description provided for @elderMem2Caption.
  ///
  /// In en, this message translates to:
  /// **'Inauguration of the community-built Samaja Bhavan in Basavanagudi - funded entirely by member contributions.'**
  String get elderMem2Caption;

  /// No description provided for @elderMem2Contributor.
  ///
  /// In en, this message translates to:
  /// **'Shri Narayanarao Suvarna'**
  String get elderMem2Contributor;

  /// No description provided for @elderMem3Title.
  ///
  /// In en, this message translates to:
  /// **'Goldsmith Guild Charter, 1952'**
  String get elderMem3Title;

  /// No description provided for @elderMem3Caption.
  ///
  /// In en, this message translates to:
  /// **'The founding charter of the Daivajna goldsmith guild, signed by 28 master craftsmen of the coastal districts.'**
  String get elderMem3Caption;

  /// No description provided for @elderMem3Contributor.
  ///
  /// In en, this message translates to:
  /// **'Samaj Archives Committee'**
  String get elderMem3Contributor;

  /// No description provided for @elderMem4Title.
  ///
  /// In en, this message translates to:
  /// **'Annual Utsava 1992'**
  String get elderMem4Title;

  /// No description provided for @elderMem4Caption.
  ///
  /// In en, this message translates to:
  /// **'Carnatic recitals and the elder felicitation that drew over 600 members across three generations.'**
  String get elderMem4Caption;

  /// No description provided for @elderMem4Contributor.
  ///
  /// In en, this message translates to:
  /// **'Rekha Diwakar'**
  String get elderMem4Contributor;

  /// No description provided for @elderMem5Title.
  ///
  /// In en, this message translates to:
  /// **'Elder Felicitation 2008'**
  String get elderMem5Title;

  /// No description provided for @elderMem5Caption.
  ///
  /// In en, this message translates to:
  /// **'Honouring the senior-most members of each branch with shawls and the traditional gold medallion.'**
  String get elderMem5Caption;

  /// No description provided for @elderMem5Contributor.
  ///
  /// In en, this message translates to:
  /// **'Lakshmi Revankar'**
  String get elderMem5Contributor;

  /// No description provided for @elderMem6Title.
  ///
  /// In en, this message translates to:
  /// **'Temple Kumbhabhisheka 1981'**
  String get elderMem6Title;

  /// No description provided for @elderMem6Caption.
  ///
  /// In en, this message translates to:
  /// **'The consecration of the community temple after its renovation, with priests from Kundapura and Udupi.'**
  String get elderMem6Caption;

  /// No description provided for @elderMem6Contributor.
  ///
  /// In en, this message translates to:
  /// **'Parvati Shirodkar'**
  String get elderMem6Contributor;

  /// No description provided for @elderSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get elderSettings;

  /// No description provided for @elderManageEventsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get elderManageEventsEyebrow;

  /// No description provided for @elderCommunityEvents.
  ///
  /// In en, this message translates to:
  /// **'Community Events'**
  String get elderCommunityEvents;

  /// No description provided for @elderEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Samaja events across all branches'**
  String get elderEventsSubtitle;

  /// No description provided for @elderAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get elderAddEvent;

  /// No description provided for @elderAddEventToast.
  ///
  /// In en, this message translates to:
  /// **'New event - opening event form'**
  String get elderAddEventToast;

  /// No description provided for @elderAttendeesExpected.
  ///
  /// In en, this message translates to:
  /// **'{n} attendees expected'**
  String elderAttendeesExpected(int n);

  /// No description provided for @elderRsvp.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get elderRsvp;

  /// No description provided for @elderManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get elderManage;

  /// No description provided for @elderRsvpConfirmed.
  ///
  /// In en, this message translates to:
  /// **'RSVP confirmed · {title}'**
  String elderRsvpConfirmed(String title);

  /// No description provided for @elderManaging.
  ///
  /// In en, this message translates to:
  /// **'Managing · {title}'**
  String elderManaging(String title);

  /// No description provided for @elderCommitteePreferences.
  ///
  /// In en, this message translates to:
  /// **'Committee Preferences'**
  String get elderCommitteePreferences;

  /// No description provided for @elderCommitteePreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notification & registry settings for the elder committee'**
  String get elderCommitteePreferencesSubtitle;

  /// No description provided for @elderEventReminders.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get elderEventReminders;

  /// No description provided for @elderEventRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify all branch heads 7 days before each event'**
  String get elderEventRemindersSubtitle;

  /// No description provided for @elderEventRemindersOn.
  ///
  /// In en, this message translates to:
  /// **'Event reminders on'**
  String get elderEventRemindersOn;

  /// No description provided for @elderEventRemindersOff.
  ///
  /// In en, this message translates to:
  /// **'Event reminders off'**
  String get elderEventRemindersOff;

  /// No description provided for @elderAutoApproveRsvps.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve RSVPs'**
  String get elderAutoApproveRsvps;

  /// No description provided for @elderAutoApproveRsvpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified members are confirmed without review'**
  String get elderAutoApproveRsvpsSubtitle;

  /// No description provided for @elderAutoApproveOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve on'**
  String get elderAutoApproveOn;

  /// No description provided for @elderAutoApproveOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve off'**
  String get elderAutoApproveOff;

  /// No description provided for @elderPublishToPublicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Publish to public calendar'**
  String get elderPublishToPublicCalendar;

  /// No description provided for @elderPublishToPublicCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show upcoming Samaja events on the portal landing page'**
  String get elderPublishToPublicCalendarSubtitle;

  /// No description provided for @elderPublicCalendarOn.
  ///
  /// In en, this message translates to:
  /// **'Public calendar on'**
  String get elderPublicCalendarOn;

  /// No description provided for @elderPublicCalendarOff.
  ///
  /// In en, this message translates to:
  /// **'Public calendar off'**
  String get elderPublicCalendarOff;

  /// No description provided for @elderTypeCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get elderTypeCultural;

  /// No description provided for @elderTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get elderTypeAdmin;

  /// No description provided for @elderTypeEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get elderTypeEducation;

  /// No description provided for @elderTypeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get elderTypeCommunity;

  /// No description provided for @elderStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get elderStatusUpcoming;

  /// No description provided for @elderStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get elderStatusPlanning;

  /// No description provided for @elderEvent1Title.
  ///
  /// In en, this message translates to:
  /// **'Annual Samaja Utsava 2025'**
  String get elderEvent1Title;

  /// No description provided for @elderEvent1Venue.
  ///
  /// In en, this message translates to:
  /// **'Samaja Bhavan, Basavanagudi, Bengaluru'**
  String get elderEvent1Venue;

  /// No description provided for @elderEvent2Title.
  ///
  /// In en, this message translates to:
  /// **'Elder Committee Meeting - Q3'**
  String get elderEvent2Title;

  /// No description provided for @elderEvent2Venue.
  ///
  /// In en, this message translates to:
  /// **'Committee Room, Samaj Bhavan'**
  String get elderEvent2Venue;

  /// No description provided for @elderEvent3Title.
  ///
  /// In en, this message translates to:
  /// **'Vidya Nidhi Scholarship Day'**
  String get elderEvent3Title;

  /// No description provided for @elderEvent3Venue.
  ///
  /// In en, this message translates to:
  /// **'SDM College Auditorium, Mangaluru'**
  String get elderEvent3Venue;

  /// No description provided for @elderEvent4Title.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Matrimonial Meet'**
  String get elderEvent4Title;

  /// No description provided for @elderEvent4Venue.
  ///
  /// In en, this message translates to:
  /// **'VR Mall Convention, Bengaluru'**
  String get elderEvent4Venue;

  /// No description provided for @elderConflictResolution.
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution'**
  String get elderConflictResolution;

  /// No description provided for @elderConflictNotFound.
  ///
  /// In en, this message translates to:
  /// **'Conflict case not found'**
  String get elderConflictNotFound;

  /// No description provided for @elderBackToOverview.
  ///
  /// In en, this message translates to:
  /// **'Back to Overview'**
  String get elderBackToOverview;

  /// No description provided for @elderCaseId.
  ///
  /// In en, this message translates to:
  /// **'Case #{id}'**
  String elderCaseId(String id);

  /// No description provided for @elderBornDied.
  ///
  /// In en, this message translates to:
  /// **'{born} - {died}'**
  String elderBornDied(String born, String died);

  /// No description provided for @elderResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get elderResolution;

  /// No description provided for @elderMergeResolve.
  ///
  /// In en, this message translates to:
  /// **'Merge & Resolve'**
  String get elderMergeResolve;

  /// No description provided for @elderMergeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Records submitted for merge review'**
  String get elderMergeSubmitted;

  /// No description provided for @elderEscalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get elderEscalate;

  /// No description provided for @elderEscalated.
  ///
  /// In en, this message translates to:
  /// **'Case escalated to the elder committee'**
  String get elderEscalated;

  /// No description provided for @elderOnlyEldersResolve.
  ///
  /// In en, this message translates to:
  /// **'Only verified Elders can resolve conflicts'**
  String get elderOnlyEldersResolve;

  /// No description provided for @elderDiscussionThread.
  ///
  /// In en, this message translates to:
  /// **'Elder Discussion Thread'**
  String get elderDiscussionThread;

  /// No description provided for @elderAddCommitteeNote.
  ///
  /// In en, this message translates to:
  /// **'Add your committee note…'**
  String get elderAddCommitteeNote;

  /// No description provided for @elderNotePosted.
  ///
  /// In en, this message translates to:
  /// **'Note posted to the thread'**
  String get elderNotePosted;

  /// No description provided for @elderBackedByRecords.
  ///
  /// In en, this message translates to:
  /// **'Backed by records · {n} vouches'**
  String elderBackedByRecords(int n);

  /// No description provided for @elderEvidence.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE'**
  String get elderEvidence;

  /// No description provided for @elderSubmittedThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Submitted this version'**
  String get elderSubmittedThisVersion;

  /// No description provided for @elderSupportThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Support this version ({n})'**
  String elderSupportThisVersion(int n);

  /// No description provided for @elderYouSupported.
  ///
  /// In en, this message translates to:
  /// **'You supported {label}'**
  String elderYouSupported(String label);

  /// No description provided for @compConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Consent'**
  String get compConsentTitle;

  /// No description provided for @compConsentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your consent settings'**
  String get compConsentLoadError;

  /// No description provided for @compBirthDataMatching.
  ///
  /// In en, this message translates to:
  /// **'Birth-Data Matching'**
  String get compBirthDataMatching;

  /// No description provided for @compBirthDataMatchingDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your birth date, time and place to calculate traditional Jataka (10 Porutham) compatibility with another member.'**
  String get compBirthDataMatchingDesc;

  /// No description provided for @compCouldNotSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that. Try again.'**
  String get compCouldNotSaveRetry;

  /// No description provided for @compPolicyUpdatedNote.
  ///
  /// In en, this message translates to:
  /// **'Our consent policy was updated since you last agreed - switch this back on to confirm again.'**
  String get compPolicyUpdatedNote;

  /// No description provided for @compAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get compAllowed;

  /// No description provided for @compNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get compNotAllowed;

  /// No description provided for @compGrantedOn.
  ///
  /// In en, this message translates to:
  /// **'Granted {date}'**
  String compGrantedOn(String date);

  /// No description provided for @compReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Report'**
  String get compReportTitle;

  /// No description provided for @compReportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the compatibility report'**
  String get compReportLoadError;

  /// No description provided for @compTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get compTryAgain;

  /// No description provided for @compYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get compYou;

  /// No description provided for @compThisMember.
  ///
  /// In en, this message translates to:
  /// **'This member'**
  String get compThisMember;

  /// No description provided for @compErrorGenericMissingRoleMine.
  ///
  /// In en, this message translates to:
  /// **'Add your gender in Profile → Edit first - it decides your traditional bride/groom role.'**
  String get compErrorGenericMissingRoleMine;

  /// No description provided for @compErrorGenericMissingRoleTheirs.
  ///
  /// In en, this message translates to:
  /// **'This member\'s profile doesn\'t have a gender on file, so their traditional role can\'t be determined.'**
  String get compErrorGenericMissingRoleTheirs;

  /// No description provided for @compErrorCalcFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate compatibility right now.'**
  String get compErrorCalcFailed;

  /// No description provided for @compRecalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get compRecalculate;

  /// No description provided for @compRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get compRetry;

  /// No description provided for @compCalculateCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Calculate Compatibility'**
  String get compCalculateCompatibility;

  /// No description provided for @compYourConsentBirthData.
  ///
  /// In en, this message translates to:
  /// **'Your consent · Birth-data matching'**
  String get compYourConsentBirthData;

  /// No description provided for @compAllowedRequiredForCalc.
  ///
  /// In en, this message translates to:
  /// **'Allowed - required for this calculation.'**
  String get compAllowedRequiredForCalc;

  /// No description provided for @compPolicyChangedReconfirm.
  ///
  /// In en, this message translates to:
  /// **'Our consent policy changed - please re-confirm.'**
  String get compPolicyChangedReconfirm;

  /// No description provided for @compNotAllowedYet.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet - required before calculating.'**
  String get compNotAllowedYet;

  /// No description provided for @compManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get compManage;

  /// No description provided for @compReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get compReview;

  /// No description provided for @compTraditionalRoleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Traditional role unknown'**
  String get compTraditionalRoleUnknown;

  /// No description provided for @compGoToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile'**
  String get compGoToProfile;

  /// No description provided for @compYourBirthDetailsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Your birth details are incomplete'**
  String get compYourBirthDetailsIncomplete;

  /// No description provided for @compTheirBirthDetailsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Their birth details are incomplete'**
  String get compTheirBirthDetailsIncomplete;

  /// No description provided for @compAddBirthDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Add your exact birth time and place to calculate the Jataka match.'**
  String get compAddBirthDetailsBody;

  /// No description provided for @compTheirBirthDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'This member hasn\'t finished their birth details yet - check back later.'**
  String get compTheirBirthDetailsBody;

  /// No description provided for @compAddBirthDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Add birth details'**
  String get compAddBirthDetailsAction;

  /// No description provided for @compYourConsentNeeded.
  ///
  /// In en, this message translates to:
  /// **'Your consent is needed'**
  String get compYourConsentNeeded;

  /// No description provided for @compTheirConsentNeeded.
  ///
  /// In en, this message translates to:
  /// **'Their consent is needed'**
  String get compTheirConsentNeeded;

  /// No description provided for @compYourConsentNeededBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t allowed birth-data matching yet - review and grant it to run this check.'**
  String get compYourConsentNeededBody;

  /// No description provided for @compTheirConsentNeededBody.
  ///
  /// In en, this message translates to:
  /// **'This member hasn\'t allowed birth-data matching yet.'**
  String get compTheirConsentNeededBody;

  /// No description provided for @compReviewConsent.
  ///
  /// In en, this message translates to:
  /// **'Review consent'**
  String get compReviewConsent;

  /// No description provided for @compSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get compSomethingWentWrong;

  /// No description provided for @compCheckReadinessError.
  ///
  /// In en, this message translates to:
  /// **'Could not check compatibility readiness'**
  String get compCheckReadinessError;

  /// No description provided for @compCheckCompatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Compatibility'**
  String get compCheckCompatibilityTitle;

  /// No description provided for @compYouAnd.
  ///
  /// In en, this message translates to:
  /// **'You × {name}'**
  String compYouAnd(String name);

  /// No description provided for @compSeeJatakaProfile.
  ///
  /// In en, this message translates to:
  /// **'See your Jataka and profile compatibility.'**
  String get compSeeJatakaProfile;

  /// No description provided for @compProfileCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Compatibility'**
  String get compProfileCompatibility;

  /// No description provided for @compSouthIndianJataka.
  ///
  /// In en, this message translates to:
  /// **'South Indian Jataka'**
  String get compSouthIndianJataka;

  /// No description provided for @compChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking Compatibility...'**
  String get compChecking;

  /// No description provided for @compCompleteHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Complete the highlighted sections above to check compatibility.'**
  String get compCompleteHighlighted;

  /// No description provided for @compCantCheckYet.
  ///
  /// In en, this message translates to:
  /// **'Compatibility can\'t be checked with this profile yet.'**
  String get compCantCheckYet;

  /// No description provided for @compVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification required.'**
  String get compVerificationRequired;

  /// No description provided for @compDataNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Compatibility data is not available for this section yet.'**
  String get compDataNotAvailableYet;

  /// No description provided for @compReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get compReady;

  /// No description provided for @compMoreInfoNeeded.
  ///
  /// In en, this message translates to:
  /// **'More information needed'**
  String get compMoreInfoNeeded;

  /// No description provided for @compNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get compNotAvailableYet;

  /// No description provided for @compCheckingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Checking compatibility...'**
  String get compCheckingEllipsis;

  /// No description provided for @compBirthDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Birth details required.'**
  String get compBirthDetailsRequired;

  /// No description provided for @compAddBirthDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Birth Details'**
  String get compAddBirthDetailsBtn;

  /// No description provided for @compPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Compatibility permission required.'**
  String get compPermissionRequired;

  /// No description provided for @compManageConsent.
  ///
  /// In en, this message translates to:
  /// **'Manage Consent'**
  String get compManageConsent;

  /// No description provided for @compCompleteAFewQuestions.
  ///
  /// In en, this message translates to:
  /// **'Complete a few compatibility questions.'**
  String get compCompleteAFewQuestions;

  /// No description provided for @compCompleteQuestions.
  ///
  /// In en, this message translates to:
  /// **'Complete Questions'**
  String get compCompleteQuestions;

  /// No description provided for @compFamilyTreeIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Add a few more family relationships to enable this.'**
  String get compFamilyTreeIncompleteBody;

  /// No description provided for @compUpdateFamilyTree.
  ///
  /// In en, this message translates to:
  /// **'Update Family Tree'**
  String get compUpdateFamilyTree;

  /// No description provided for @compDashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the compatibility dashboard'**
  String get compDashboardLoadError;

  /// No description provided for @compMarriageCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Marriage Compatibility'**
  String get compMarriageCompatibility;

  /// No description provided for @compPdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved: {name}'**
  String compPdfSaved(String name);

  /// No description provided for @compDownloadNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get compDownloadNotifTitle;

  /// No description provided for @compDownloadNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready - tap to open'**
  String compDownloadNotifBody(String name);

  /// No description provided for @compPdfGenerateError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the PDF. Please try again.'**
  String get compPdfGenerateError;

  /// No description provided for @compPdfShareError.
  ///
  /// In en, this message translates to:
  /// **'Could not share the PDF. Please try again.'**
  String get compPdfShareError;

  /// No description provided for @compShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Marriage Compatibility Report - {myName} × {otherName}'**
  String compShareSubject(String myName, String otherName);

  /// No description provided for @compRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get compRetryAction;

  /// No description provided for @compOverallCompatibility.
  ///
  /// In en, this message translates to:
  /// **'OVERALL COMPATIBILITY'**
  String get compOverallCompatibility;

  /// No description provided for @compAstrologyCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Astrology Compatibility'**
  String get compAstrologyCompatibility;

  /// No description provided for @compNotEnoughProfileInfo.
  ///
  /// In en, this message translates to:
  /// **'Not enough profile information'**
  String get compNotEnoughProfileInfo;

  /// No description provided for @compNotEnoughAstrologyInfo.
  ///
  /// In en, this message translates to:
  /// **'Not enough astrology information'**
  String get compNotEnoughAstrologyInfo;

  /// No description provided for @compAstrologySummary.
  ///
  /// In en, this message translates to:
  /// **'ASTROLOGY SUMMARY'**
  String get compAstrologySummary;

  /// No description provided for @compKarnatakaPorutham.
  ///
  /// In en, this message translates to:
  /// **'Karnataka 10 Porutham'**
  String get compKarnatakaPorutham;

  /// No description provided for @compAshtakootaGuna.
  ///
  /// In en, this message translates to:
  /// **'Ashtakoota 36 Guna'**
  String get compAshtakootaGuna;

  /// No description provided for @compUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get compUnavailable;

  /// No description provided for @compViewDetailedReport.
  ///
  /// In en, this message translates to:
  /// **'View Detailed Report'**
  String get compViewDetailedReport;

  /// No description provided for @compGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get compGenerating;

  /// No description provided for @compDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get compDownloadPdf;

  /// No description provided for @compShareReport.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get compShareReport;

  /// No description provided for @compCalculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated'**
  String get compCalculated;

  /// No description provided for @compReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review required'**
  String get compReviewRequired;

  /// No description provided for @compNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get compNotAvailable;

  /// No description provided for @discSortBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best Match'**
  String get discSortBestMatch;

  /// No description provided for @discSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get discSortNewest;

  /// No description provided for @discSortAgeLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Age: Low to High'**
  String get discSortAgeLowHigh;

  /// No description provided for @discSortAgeHighLow.
  ///
  /// In en, this message translates to:
  /// **'Age: High to Low'**
  String get discSortAgeHighLow;

  /// No description provided for @discTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Matches'**
  String get discTitle;

  /// No description provided for @discCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load matches'**
  String get discCouldNotLoad;

  /// No description provided for @discCouldNotLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Could not load more matches'**
  String get discCouldNotLoadMore;

  /// No description provided for @discMatch.
  ///
  /// In en, this message translates to:
  /// **' match'**
  String get discMatch;

  /// No description provided for @discMatches.
  ///
  /// In en, this message translates to:
  /// **' matches'**
  String get discMatches;

  /// No description provided for @discFilterCount.
  ///
  /// In en, this message translates to:
  /// **'Filter ({n})'**
  String discFilterCount(int n);

  /// No description provided for @discFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get discFilter;

  /// No description provided for @discSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String discSortLabel(String label);

  /// No description provided for @discLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get discLoadMore;

  /// No description provided for @discNoMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches to show yet'**
  String get discNoMatchesYet;

  /// No description provided for @discCompletePreferences.
  ///
  /// In en, this message translates to:
  /// **'Complete your marriage preferences and interests for better matches.'**
  String get discCompletePreferences;

  /// No description provided for @discNoMatchesForFilters.
  ///
  /// In en, this message translates to:
  /// **'No matches found for these filters.'**
  String get discNoMatchesForFilters;

  /// No description provided for @discClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get discClearFilters;

  /// No description provided for @discIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Ranked by how well each profile fits your marriage preferences, food, interests, location and age - highest match first.'**
  String get discIntroBody;

  /// No description provided for @discMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get discMatchLabel;

  /// No description provided for @discViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get discViewProfile;

  /// No description provided for @purohitTitle.
  ///
  /// In en, this message translates to:
  /// **'Purohit'**
  String get purohitTitle;

  /// No description provided for @purohitCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load purohits.'**
  String get purohitCouldNotLoad;

  /// No description provided for @purohitCouldNotLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load purohits'**
  String get purohitCouldNotLoadTitle;

  /// No description provided for @purohitNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No purohits yet'**
  String get purohitNoneYet;

  /// No description provided for @purohitNoneYetBody.
  ///
  /// In en, this message translates to:
  /// **'Members who mark themselves as a purohit at registration will appear here.'**
  String get purohitNoneYetBody;

  /// No description provided for @purohitKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String purohitKmAway(String km);

  /// No description provided for @jatakaTitle.
  ///
  /// In en, this message translates to:
  /// **'South Indian Jataka'**
  String get jatakaTitle;

  /// No description provided for @jatakaLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the South Indian Jataka result right now.'**
  String get jatakaLoadError;

  /// No description provided for @jatakaReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review required'**
  String get jatakaReviewRequired;

  /// No description provided for @jatakaReviewRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Some calculations require review because of birth-time uncertainty.'**
  String get jatakaReviewRequiredBody;

  /// No description provided for @jatakaNotCalculableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not calculable yet'**
  String get jatakaNotCalculableTitle;

  /// No description provided for @jatakaNotCalculableBody.
  ///
  /// In en, this message translates to:
  /// **'South Indian Jataka compatibility could not be calculated. This is usually because birth details are missing, required consent isn\'t in place, or the astrology rules haven\'t been published yet.'**
  String get jatakaNotCalculableBody;

  /// No description provided for @jatakaNoKarnatakaTitle.
  ///
  /// In en, this message translates to:
  /// **'No Karnataka Porutham result'**
  String get jatakaNoKarnatakaTitle;

  /// No description provided for @jatakaNoKarnatakaBody.
  ///
  /// In en, this message translates to:
  /// **'This report does not include a South Indian Jataka result.'**
  String get jatakaNoKarnatakaBody;

  /// No description provided for @jatakaSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'SOUTH INDIAN JATAKA'**
  String get jatakaSectionLabel;

  /// No description provided for @jatakaKarnataka10Porutham.
  ///
  /// In en, this message translates to:
  /// **'Karnataka 10 Porutham'**
  String get jatakaKarnataka10Porutham;

  /// No description provided for @jatakaMatchedOf.
  ///
  /// In en, this message translates to:
  /// **'{matched}/{total} matched'**
  String jatakaMatchedOf(String matched, String total);

  /// No description provided for @jatakaRuleVersion.
  ///
  /// In en, this message translates to:
  /// **'Rule version: {version}'**
  String jatakaRuleVersion(String version);

  /// No description provided for @jatakaChipMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get jatakaChipMatched;

  /// No description provided for @jatakaChipPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get jatakaChipPartial;

  /// No description provided for @jatakaChipNotMatched.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get jatakaChipNotMatched;

  /// No description provided for @jatakaChipReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get jatakaChipReview;

  /// No description provided for @jatakaChipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get jatakaChipUnavailable;

  /// No description provided for @jatakaCriticalChecks.
  ///
  /// In en, this message translates to:
  /// **'Critical checks'**
  String get jatakaCriticalChecks;

  /// No description provided for @jatakaRajju.
  ///
  /// In en, this message translates to:
  /// **'Rajju'**
  String get jatakaRajju;

  /// No description provided for @jatakaVedha.
  ///
  /// In en, this message translates to:
  /// **'Vedha'**
  String get jatakaVedha;

  /// No description provided for @jatakaStatusMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get jatakaStatusMatched;

  /// No description provided for @jatakaStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get jatakaStatusPartial;

  /// No description provided for @jatakaStatusNotMatched.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get jatakaStatusNotMatched;

  /// No description provided for @jatakaStatusReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review required'**
  String get jatakaStatusReviewRequired;

  /// No description provided for @jatakaStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get jatakaStatusUnavailable;

  /// No description provided for @jatakaStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get jatakaStatusUnknown;

  /// No description provided for @jatakaThe10Poruthams.
  ///
  /// In en, this message translates to:
  /// **'The 10 Poruthams'**
  String get jatakaThe10Poruthams;

  /// No description provided for @jatakaAshtakootaLabel.
  ///
  /// In en, this message translates to:
  /// **'ASHTAKOOTA / 36 GUNA'**
  String get jatakaAshtakootaLabel;

  /// No description provided for @jatakaAshtakootaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ashtakoota calculation is currently unavailable.'**
  String get jatakaAshtakootaUnavailable;

  /// No description provided for @jatakaOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall astrology score'**
  String get jatakaOverallScore;

  /// No description provided for @birthTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth Details'**
  String get birthTitle;

  /// No description provided for @birthCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load your birth details'**
  String get birthCouldNotLoad;

  /// No description provided for @birthCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save your birth details'**
  String get birthCouldNotSave;

  /// No description provided for @birthDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Used only for the South Indian Jataka and horoscope compatibility check - never shown on your public profile.'**
  String get birthDisclaimer;

  /// No description provided for @birthFromProfile.
  ///
  /// In en, this message translates to:
  /// **'FROM YOUR PROFILE'**
  String get birthFromProfile;

  /// No description provided for @birthDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDateOfBirth;

  /// No description provided for @birthNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get birthNotSet;

  /// No description provided for @birthTraditionalRole.
  ///
  /// In en, this message translates to:
  /// **'Traditional role'**
  String get birthTraditionalRole;

  /// No description provided for @birthSetGender.
  ///
  /// In en, this message translates to:
  /// **'Set your gender in Profile → Edit'**
  String get birthSetGender;

  /// No description provided for @birthBirthplace.
  ///
  /// In en, this message translates to:
  /// **'BIRTHPLACE'**
  String get birthBirthplace;

  /// No description provided for @birthCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth city'**
  String get birthCityLabel;

  /// No description provided for @birthCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mysuru, Karnataka, India'**
  String get birthCityHint;

  /// No description provided for @birthTimeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'TIME OF BIRTH'**
  String get birthTimeOfBirth;

  /// No description provided for @birthTimePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get birthTimePickerHelp;

  /// No description provided for @birthDerivedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Derived automatically'**
  String get birthDerivedAutomatically;

  /// No description provided for @birthLatLon.
  ///
  /// In en, this message translates to:
  /// **'Lat/Lon: {lat}, {lon}\nTimezone: {tz}'**
  String birthLatLon(String lat, String lon, String tz);

  /// No description provided for @birthTimeAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Birth-time accuracy'**
  String get birthTimeAccuracy;

  /// No description provided for @birthSelectAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Select accuracy'**
  String get birthSelectAccuracy;

  /// No description provided for @birthSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get birthSaving;

  /// No description provided for @birthSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save birth details'**
  String get birthSaveButton;

  /// No description provided for @birthSaved.
  ///
  /// In en, this message translates to:
  /// **'Birth details saved'**
  String get birthSaved;

  /// No description provided for @birthAddDob.
  ///
  /// In en, this message translates to:
  /// **'Add your date of birth in Profile → Edit first.'**
  String get birthAddDob;

  /// No description provided for @birthAddGender.
  ///
  /// In en, this message translates to:
  /// **'Add your gender in Profile → Edit first - it decides your traditional bride/groom role.'**
  String get birthAddGender;

  /// No description provided for @birthSearchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for your birthplace and pick it from the suggestions.'**
  String get birthSearchPlace;

  /// No description provided for @birthInvalidLatitude.
  ///
  /// In en, this message translates to:
  /// **'That birthplace has an invalid latitude - try searching again.'**
  String get birthInvalidLatitude;

  /// No description provided for @birthInvalidLongitude.
  ///
  /// In en, this message translates to:
  /// **'That birthplace has an invalid longitude - try searching again.'**
  String get birthInvalidLongitude;

  /// No description provided for @birthNoTimezone.
  ///
  /// In en, this message translates to:
  /// **'Could not determine a timezone for that place - try a more specific search, including the country.'**
  String get birthNoTimezone;

  /// No description provided for @birthChooseAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Choose how confident you are about the time of birth.'**
  String get birthChooseAccuracy;

  /// No description provided for @birthAddTimeOrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Add the time of birth, or set the accuracy to \"Unknown\" if it\'s genuinely not known.'**
  String get birthAddTimeOrUnknown;

  /// No description provided for @birthAccuracyExactDocument.
  ///
  /// In en, this message translates to:
  /// **'Exact - verified by a document (e.g. birth certificate)'**
  String get birthAccuracyExactDocument;

  /// No description provided for @birthAccuracyExactFamily.
  ///
  /// In en, this message translates to:
  /// **'Exact - confirmed by family'**
  String get birthAccuracyExactFamily;

  /// No description provided for @birthAccuracyApprox15.
  ///
  /// In en, this message translates to:
  /// **'Approximate - within 15 minutes'**
  String get birthAccuracyApprox15;

  /// No description provided for @birthAccuracyApprox30.
  ///
  /// In en, this message translates to:
  /// **'Approximate - within 30 minutes'**
  String get birthAccuracyApprox30;

  /// No description provided for @birthAccuracyApprox60.
  ///
  /// In en, this message translates to:
  /// **'Approximate - within 60 minutes'**
  String get birthAccuracyApprox60;

  /// No description provided for @birthAccuracyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get birthAccuracyUnknown;

  /// No description provided for @cameraNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available on this device.'**
  String get cameraNoneAvailable;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable: {error}'**
  String cameraUnavailable(String error);

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required. Enable it in Settings.'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera: {error}'**
  String cameraCouldNotStart(String error);

  /// No description provided for @cameraCouldNotTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not take the photo.'**
  String get cameraCouldNotTakePhoto;

  /// No description provided for @cameraCouldNotStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording.'**
  String get cameraCouldNotStartRecording;

  /// No description provided for @cameraCouldNotSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not save the recording.'**
  String get cameraCouldNotSaveRecording;

  /// No description provided for @cameraReleaseToStop.
  ///
  /// In en, this message translates to:
  /// **'Release to stop'**
  String get cameraReleaseToStop;

  /// No description provided for @cameraTapOrHold.
  ///
  /// In en, this message translates to:
  /// **'Tap for photo  ·  Hold to record'**
  String get cameraTapOrHold;

  /// No description provided for @digilockerVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify with DigiLocker'**
  String get digilockerVerifyTitle;

  /// No description provided for @postCouldNotPickMedia.
  ///
  /// In en, this message translates to:
  /// **'Could not pick media: {error}'**
  String postCouldNotPickMedia(String error);

  /// No description provided for @postAuthorFallback.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get postAuthorFallback;

  /// No description provided for @postReelShared.
  ///
  /// In en, this message translates to:
  /// **'Reel shared 🎬'**
  String get postReelShared;

  /// No description provided for @postShared.
  ///
  /// In en, this message translates to:
  /// **'Post shared ✨'**
  String get postShared;

  /// No description provided for @postUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {reason}'**
  String postUploadFailed(String reason);

  /// No description provided for @postCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'check your connection'**
  String get postCheckConnection;

  /// No description provided for @postNewReel.
  ///
  /// In en, this message translates to:
  /// **'New Reel'**
  String get postNewReel;

  /// No description provided for @postNewPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get postNewPost;

  /// No description provided for @postCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a caption…'**
  String get postCaptionHint;

  /// No description provided for @postDefaultReelCaption.
  ///
  /// In en, this message translates to:
  /// **'New reel'**
  String get postDefaultReelCaption;

  /// No description provided for @postDefaultPostCaption.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get postDefaultPostCaption;

  /// No description provided for @postLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get postLocating;

  /// No description provided for @postCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get postCurrentLocation;

  /// No description provided for @postCouldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location.'**
  String get postCouldNotGetLocation;

  /// No description provided for @postRemoveLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get postRemoveLocation;

  /// No description provided for @postShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get postShareButton;

  /// No description provided for @storyVisFamilyFollowers.
  ///
  /// In en, this message translates to:
  /// **'Family & Followers'**
  String get storyVisFamilyFollowers;

  /// No description provided for @storyVisOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get storyVisOnlyMe;

  /// No description provided for @storyVisCommunity.
  ///
  /// In en, this message translates to:
  /// **'Vamsha Community'**
  String get storyVisCommunity;

  /// No description provided for @storyTagFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Tag Family Members'**
  String get storyTagFamilyMembers;

  /// No description provided for @storyLinkAncestor.
  ///
  /// In en, this message translates to:
  /// **'Link to an Ancestor'**
  String get storyLinkAncestor;

  /// No description provided for @storyWhoCanSee.
  ///
  /// In en, this message translates to:
  /// **'Who can see this story?'**
  String get storyWhoCanSee;

  /// No description provided for @storyVisCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the Samaj'**
  String get storyVisCommunityDesc;

  /// No description provided for @storyVisFollowersDesc.
  ///
  /// In en, this message translates to:
  /// **'People connected to you'**
  String get storyVisFollowersDesc;

  /// No description provided for @storyVisPrivateDesc.
  ///
  /// In en, this message translates to:
  /// **'Private - nobody else can see it'**
  String get storyVisPrivateDesc;

  /// No description provided for @storyShared.
  ///
  /// In en, this message translates to:
  /// **'Story shared - live for 24 hours ✨'**
  String get storyShared;

  /// No description provided for @storyCouldNotPost.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post: {reason}'**
  String storyCouldNotPost(String reason);

  /// No description provided for @storyPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'please try again'**
  String get storyPleaseTryAgain;

  /// No description provided for @storyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{label} - coming soon'**
  String storyComingSoon(String label);

  /// No description provided for @storyShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Story'**
  String get storyShareTitle;

  /// No description provided for @storyHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get storyHelp;

  /// No description provided for @storyReviewRecording.
  ///
  /// In en, this message translates to:
  /// **'Review your recording'**
  String get storyReviewRecording;

  /// No description provided for @storyReviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Review your photo'**
  String get storyReviewPhoto;

  /// No description provided for @storyCaption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get storyCaption;

  /// No description provided for @storyCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a caption about this family memory…'**
  String get storyCaptionHint;

  /// No description provided for @storySearchVamshaVruksha.
  ///
  /// In en, this message translates to:
  /// **'Search your Vamsha Vruksha'**
  String get storySearchVamshaVruksha;

  /// No description provided for @storyAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get storyAddLocation;

  /// No description provided for @storyLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Villages, temples, or community centers'**
  String get storyLocationSubtitle;

  /// No description provided for @storyLinkToTreeNode.
  ///
  /// In en, this message translates to:
  /// **'Link to Tree Node'**
  String get storyLinkToTreeNode;

  /// No description provided for @storyAttachAncestor.
  ///
  /// In en, this message translates to:
  /// **'Attach this story to an ancestor'**
  String get storyAttachAncestor;

  /// No description provided for @storyLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String storyLinkedTo(String name);

  /// No description provided for @storyAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED SETTINGS'**
  String get storyAdvancedSettings;

  /// No description provided for @storyVisibleTo.
  ///
  /// In en, this message translates to:
  /// **'Visible to'**
  String get storyVisibleTo;

  /// No description provided for @storyPostToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Post to Community'**
  String get storyPostToCommunity;

  /// No description provided for @storyDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get storyDrafts;

  /// No description provided for @storyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kumta, Mahalasa Temple…'**
  String get storyLocationHint;

  /// No description provided for @storyKindVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get storyKindVillage;

  /// No description provided for @storyKindTemple.
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get storyKindTemple;

  /// No description provided for @storyKindCommunityCenter.
  ///
  /// In en, this message translates to:
  /// **'Community Center'**
  String get storyKindCommunityCenter;

  /// No description provided for @storyKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storyKindOther;

  /// No description provided for @storyAgoMinutesCompact.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String storyAgoMinutesCompact(int n);

  /// No description provided for @storyAgoHoursCompact.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String storyAgoHoursCompact(int n);

  /// No description provided for @storyAgoDaysCompact.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String storyAgoDaysCompact(int n);

  /// No description provided for @storyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete story?'**
  String get storyDeleteTitle;

  /// No description provided for @storyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it for everyone.'**
  String get storyDeleteBody;

  /// No description provided for @storyDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storyDeleteAction;

  /// No description provided for @storyNoViewsYet.
  ///
  /// In en, this message translates to:
  /// **'No views yet'**
  String get storyNoViewsYet;

  /// No description provided for @storySeenByCount.
  ///
  /// In en, this message translates to:
  /// **'Seen by {n}'**
  String storySeenByCount(int n);

  /// No description provided for @storyViewers.
  ///
  /// In en, this message translates to:
  /// **'Viewers'**
  String get storyViewers;

  /// No description provided for @storyViewersCount.
  ///
  /// In en, this message translates to:
  /// **'Viewers · {n}'**
  String storyViewersCount(int n);

  /// No description provided for @storyNoOneViewedYet.
  ///
  /// In en, this message translates to:
  /// **'No one has viewed this story yet.'**
  String get storyNoOneViewedYet;

  /// No description provided for @storyMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get storyMemberFallback;

  /// No description provided for @chatMessageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Message not sent'**
  String get chatMessageNotSent;

  /// No description provided for @chatPhotosVideos.
  ///
  /// In en, this message translates to:
  /// **'Photos/Videos'**
  String get chatPhotosVideos;

  /// No description provided for @chatCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatCamera;

  /// No description provided for @chatDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get chatDocuments;

  /// No description provided for @chatCouldNotSendFile.
  ///
  /// In en, this message translates to:
  /// **'Could not send file'**
  String get chatCouldNotSendFile;

  /// No description provided for @chatSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get chatSayHello;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatMessageHint;

  /// No description provided for @chatNoAppForFile.
  ///
  /// In en, this message translates to:
  /// **'No app could open this file'**
  String get chatNoAppForFile;

  /// No description provided for @chatDocumentFallback.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get chatDocumentFallback;

  /// No description provided for @convMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get convMemberFallback;

  /// No description provided for @convMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get convMessages;

  /// No description provided for @convNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get convNoMessagesYet;

  /// No description provided for @convStartChatHint.
  ///
  /// In en, this message translates to:
  /// **'Message a member from the directory to start a chat.'**
  String get convStartChatHint;

  /// No description provided for @convVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'🎥 Video'**
  String get convVideoLabel;

  /// No description provided for @convDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'📄 Document'**
  String get convDocumentLabel;

  /// No description provided for @convPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get convPhotoLabel;

  /// No description provided for @convTapToChat.
  ///
  /// In en, this message translates to:
  /// **'Tap to chat'**
  String get convTapToChat;

  /// No description provided for @commentCouldNotPost.
  ///
  /// In en, this message translates to:
  /// **'Could not post comment: {reason}'**
  String commentCouldNotPost(String reason);

  /// No description provided for @commentCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'check your connection'**
  String get commentCheckConnection;

  /// No description provided for @commentTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentTitle;

  /// No description provided for @commentNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get commentNoneYet;

  /// No description provided for @commentStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation.'**
  String get commentStartConversation;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…  (type @ to tag)'**
  String get commentHint;

  /// No description provided for @commentPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get commentPosting;

  /// No description provided for @commentPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commentPost;

  /// No description provided for @commentLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} like} other{{n} likes}}'**
  String commentLikeCount(int n);

  /// No description provided for @commentCouldNotLike.
  ///
  /// In en, this message translates to:
  /// **'Could not like: {reason}'**
  String commentCouldNotLike(String reason);

  /// No description provided for @shareReel.
  ///
  /// In en, this message translates to:
  /// **'reel'**
  String get shareReel;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'post'**
  String get sharePost;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareTitle;

  /// No description provided for @shareSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get shareSendTo;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get shareLinkCopied;

  /// No description provided for @shareSentToMembers.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Sent to {n} member 📩} other{Sent to {n} members 📩}}'**
  String shareSentToMembers(int n);

  /// No description provided for @shareSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shareSendButton;

  /// No description provided for @shareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareCopyLink;

  /// No description provided for @shareAddToStory.
  ///
  /// In en, this message translates to:
  /// **'Add to story'**
  String get shareAddToStory;

  /// No description provided for @shareAddedToStory.
  ///
  /// In en, this message translates to:
  /// **'Added to your story'**
  String get shareAddedToStory;

  /// No description provided for @shareViaEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Share via…'**
  String get shareViaEllipsis;

  /// No description provided for @shareTextTemplate.
  ///
  /// In en, this message translates to:
  /// **'{author} shared a {kind} on Samaj\n\"{caption}\"\n\n{link}'**
  String shareTextTemplate(
    String author,
    String kind,
    String caption,
    String link,
  );

  /// No description provided for @shareSubjectTemplate.
  ///
  /// In en, this message translates to:
  /// **'A {kind} from the Samaj'**
  String shareSubjectTemplate(String kind);

  /// No description provided for @landOrgName.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Samaja'**
  String get landOrgName;

  /// No description provided for @landEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Samaja Bangalore - Est. 2024'**
  String get landEyebrow;

  /// No description provided for @landHeadline.
  ///
  /// In en, this message translates to:
  /// **'Preserving our Roots,\nNurturing our Future'**
  String get landHeadline;

  /// No description provided for @landSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The official digital sanctuary for the Daivajna Samaja - connecting generations, preserving heritage, and building community welfare through a living family tree.'**
  String get landSubtitle;

  /// No description provided for @landBeginJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin Your Journey'**
  String get landBeginJourney;

  /// No description provided for @landAccessPortal.
  ///
  /// In en, this message translates to:
  /// **'Access Portal'**
  String get landAccessPortal;

  /// No description provided for @landFamilyLineagePreview.
  ///
  /// In en, this message translates to:
  /// **'FAMILY LINEAGE PREVIEW'**
  String get landFamilyLineagePreview;

  /// No description provided for @landGenerationsTag.
  ///
  /// In en, this message translates to:
  /// **'4 Generations'**
  String get landGenerationsTag;

  /// No description provided for @landMembersTag.
  ///
  /// In en, this message translates to:
  /// **'6 Members'**
  String get landMembersTag;

  /// No description provided for @landUdupiBranch.
  ///
  /// In en, this message translates to:
  /// **'Udupi Branch'**
  String get landUdupiBranch;

  /// No description provided for @landPillarFamilyTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get landPillarFamilyTreeTitle;

  /// No description provided for @landPillarFamilyTreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Document your family lineage across generations. Interactive tree visualization with photo archives, life stories, and ancestral connections.'**
  String get landPillarFamilyTreeDesc;

  /// No description provided for @landPillarWelfareTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Welfare'**
  String get landPillarWelfareTitle;

  /// No description provided for @landPillarWelfareDesc.
  ///
  /// In en, this message translates to:
  /// **'Transparent crowdfunding for Samaj development. Every rupee accounted for - community center, scholarships, emergency support.'**
  String get landPillarWelfareDesc;

  /// No description provided for @landPillarMatrimonialTitle.
  ///
  /// In en, this message translates to:
  /// **'Matrimonial Hub'**
  String get landPillarMatrimonialTitle;

  /// No description provided for @landPillarMatrimonialDesc.
  ///
  /// In en, this message translates to:
  /// **'Elder-mediated matrimonial connections that honour lineage and cultural alignment. Verified profiles with complete family background.'**
  String get landPillarMatrimonialDesc;

  /// No description provided for @landPillarElderTitle.
  ///
  /// In en, this message translates to:
  /// **'Elder Governance'**
  String get landPillarElderTitle;

  /// No description provided for @landPillarElderDesc.
  ///
  /// In en, this message translates to:
  /// **'Community-driven decisions guided by our respected elders. Resolve conflicts, verify members, and govern with generational wisdom.'**
  String get landPillarElderDesc;

  /// No description provided for @landExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get landExplore;

  /// No description provided for @landTrustEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A circle of absolute trust'**
  String get landTrustEyebrow;

  /// No description provided for @landTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Every member, every connection - verified.'**
  String get landTrustTitle;

  /// No description provided for @landTrustAadhaarTitle.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Verification'**
  String get landTrustAadhaarTitle;

  /// No description provided for @landTrustAadhaarDesc.
  ///
  /// In en, this message translates to:
  /// **'Every member submits a government-issued ID. Aadhaar-matched and digitally registered.'**
  String get landTrustAadhaarDesc;

  /// No description provided for @landTrustPeerTitle.
  ///
  /// In en, this message translates to:
  /// **'Peer Vouching'**
  String get landTrustPeerTitle;

  /// No description provided for @landTrustPeerDesc.
  ///
  /// In en, this message translates to:
  /// **'New members are vouched by 3 existing verified family members within the Samaj network.'**
  String get landTrustPeerDesc;

  /// No description provided for @landTrustElderTitle.
  ///
  /// In en, this message translates to:
  /// **'Elder Approval'**
  String get landTrustElderTitle;

  /// No description provided for @landTrustElderDesc.
  ///
  /// In en, this message translates to:
  /// **'Elder sub-committee reviews and approves all lineage connections and matrimonial requests.'**
  String get landTrustElderDesc;

  /// No description provided for @landQuote.
  ///
  /// In en, this message translates to:
  /// **'\"A tree is only as strong as its roots. Verification ensures the legacy you build is authentic and lasting.\"'**
  String get landQuote;

  /// No description provided for @landQuoteAuthor.
  ///
  /// In en, this message translates to:
  /// **'- Samaj Heritage Council'**
  String get landQuoteAuthor;

  /// No description provided for @landFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'Daivajna Samaja Community Portal'**
  String get landFooterTagline;

  /// No description provided for @landFooterPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get landFooterPrivacy;

  /// No description provided for @landFooterTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get landFooterTerms;

  /// No description provided for @landFooterHeritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage Guidelines'**
  String get landFooterHeritage;

  /// No description provided for @landFooterContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin'**
  String get landFooterContact;

  /// No description provided for @landFooterGovernance.
  ///
  /// In en, this message translates to:
  /// **'Community Governance'**
  String get landFooterGovernance;

  /// No description provided for @landFooterCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Daivajna Samaja - Preserving Legacies for Generations.'**
  String get landFooterCopyright;

  /// No description provided for @reelSavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved to your profile'**
  String get reelSavedToProfile;

  /// No description provided for @reelRemovedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get reelRemovedFromSaved;

  /// No description provided for @matchLevelExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent Match'**
  String get matchLevelExcellent;

  /// No description provided for @matchLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High Match'**
  String get matchLevelHigh;

  /// No description provided for @matchLevelGood.
  ///
  /// In en, this message translates to:
  /// **'Good Match'**
  String get matchLevelGood;

  /// No description provided for @matchLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate Match'**
  String get matchLevelModerate;

  /// No description provided for @matchLevelLow.
  ///
  /// In en, this message translates to:
  /// **'Low Match'**
  String get matchLevelLow;

  /// No description provided for @matchBadgeMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchBadgeMatch;

  /// No description provided for @matchFactorMarriageIntention.
  ///
  /// In en, this message translates to:
  /// **'Marriage Intention'**
  String get matchFactorMarriageIntention;

  /// No description provided for @matchFactorChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get matchFactorChildren;

  /// No description provided for @matchFactorFamilyType.
  ///
  /// In en, this message translates to:
  /// **'Family Type'**
  String get matchFactorFamilyType;

  /// No description provided for @matchFactorRelocation.
  ///
  /// In en, this message translates to:
  /// **'Relocation'**
  String get matchFactorRelocation;

  /// No description provided for @matchFactorFoodPreference.
  ///
  /// In en, this message translates to:
  /// **'Food Preference'**
  String get matchFactorFoodPreference;

  /// No description provided for @matchFactorInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get matchFactorInterests;

  /// No description provided for @matchFactorLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get matchFactorLocation;

  /// No description provided for @matchFactorAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get matchFactorAge;

  /// No description provided for @matchFactorNotEnoughInfo.
  ///
  /// In en, this message translates to:
  /// **'{label} - not enough information to compare'**
  String matchFactorNotEnoughInfo(String label);

  /// No description provided for @matchFactorAligned.
  ///
  /// In en, this message translates to:
  /// **'{label} - {percentage}% aligned'**
  String matchFactorAligned(String label, int percentage);

  /// No description provided for @discFilterIntentionSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get discFilterIntentionSoon;

  /// No description provided for @discFilterIntentionOneToTwoYears.
  ///
  /// In en, this message translates to:
  /// **'1-2 Years'**
  String get discFilterIntentionOneToTwoYears;

  /// No description provided for @discFilterIntentionNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Not Decided'**
  String get discFilterIntentionNotDecided;

  /// No description provided for @discFilterFoodVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get discFilterFoodVegetarian;

  /// No description provided for @discFilterFoodNonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-Vegetarian'**
  String get discFilterFoodNonVegetarian;

  /// No description provided for @discFilterFoodEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get discFilterFoodEggetarian;

  /// No description provided for @discFilterFoodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get discFilterFoodOther;

  /// No description provided for @discFilterInterestTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get discFilterInterestTravel;

  /// No description provided for @discFilterInterestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get discFilterInterestMusic;

  /// No description provided for @discFilterInterestMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get discFilterInterestMovies;

  /// No description provided for @discFilterInterestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get discFilterInterestFitness;

  /// No description provided for @discFilterInterestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get discFilterInterestSports;

  /// No description provided for @discFilterInterestReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get discFilterInterestReading;

  /// No description provided for @discFilterInterestCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get discFilterInterestCooking;

  /// No description provided for @discFilterInterestSpirituality.
  ///
  /// In en, this message translates to:
  /// **'Spirituality'**
  String get discFilterInterestSpirituality;

  /// No description provided for @discFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get discFilterAny;

  /// No description provided for @discFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get discFilterTitle;

  /// No description provided for @discFilterAgeSection.
  ///
  /// In en, this message translates to:
  /// **'AGE'**
  String get discFilterAgeSection;

  /// No description provided for @discFilterAgeFrom.
  ///
  /// In en, this message translates to:
  /// **'Age From'**
  String get discFilterAgeFrom;

  /// No description provided for @discFilterAgeTo.
  ///
  /// In en, this message translates to:
  /// **'Age To'**
  String get discFilterAgeTo;

  /// No description provided for @discFilterLocationSection.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get discFilterLocationSection;

  /// No description provided for @discFilterLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Preferred location'**
  String get discFilterLocationHint;

  /// No description provided for @discFilterMinMatchSection.
  ///
  /// In en, this message translates to:
  /// **'MINIMUM MATCH'**
  String get discFilterMinMatchSection;

  /// No description provided for @discFilterIntentionSection.
  ///
  /// In en, this message translates to:
  /// **'MARRIAGE INTENTION'**
  String get discFilterIntentionSection;

  /// No description provided for @discFilterFoodSection.
  ///
  /// In en, this message translates to:
  /// **'FOOD PREFERENCE'**
  String get discFilterFoodSection;

  /// No description provided for @discFilterInterestsSection.
  ///
  /// In en, this message translates to:
  /// **'INTERESTS'**
  String get discFilterInterestsSection;

  /// No description provided for @discFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get discFilterClearAll;

  /// No description provided for @discFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get discFilterApply;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get commonKeep;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageKannada.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get languageKannada;

  /// No description provided for @permIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get permIntroTitle;

  /// No description provided for @permIntroBody.
  ///
  /// In en, this message translates to:
  /// **'A few permissions make the app work smoothly. You can change any of these later in your phone\'s Settings.'**
  String get permIntroBody;

  /// No description provided for @permMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos & Videos'**
  String get permMediaTitle;

  /// No description provided for @permMediaBody.
  ///
  /// In en, this message translates to:
  /// **'To attach photos and videos to your posts, stories, and profile.'**
  String get permMediaBody;

  /// No description provided for @permNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotificationTitle;

  /// No description provided for @permNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'To let you know about family requests, messages, and community updates.'**
  String get permNotificationBody;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In en, this message translates to:
  /// **'To tag a place on your posts and find nearby Samaj members.'**
  String get permLocationBody;

  /// No description provided for @permRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get permRequesting;

  /// No description provided for @permContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permContinue;

  /// No description provided for @permSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get permSkip;
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
      <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
