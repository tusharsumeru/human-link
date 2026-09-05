// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Daivajna Samaja';

  @override
  String get appTagline => 'Bangalore · Heritage Portal';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navFamilyTree => 'Family Tree';

  @override
  String get navInvitations => 'Invitations';

  @override
  String get navDirectory => 'Directory';

  @override
  String get navMatrimonial => 'Matrimonial';

  @override
  String get navWelfare => 'Welfare';

  @override
  String get navPurohit => 'Purohit';

  @override
  String get navLineageTree => 'Lineage Tree';

  @override
  String get navMemberRequests => 'Member Requests';

  @override
  String get navArchives => 'Archives';

  @override
  String get navCommunity => 'Community';

  @override
  String get navModeration => 'Moderation';

  @override
  String get navSettings => 'Settings';

  @override
  String get navHome => 'Home';

  @override
  String get navTree => 'Tree';

  @override
  String get navRequests => 'Requests';

  @override
  String get navMembers => 'Members';

  @override
  String get navArchive => 'Archive';

  @override
  String get navMore => 'More';

  @override
  String get navPost => 'Post';

  @override
  String get navMessages => 'Messages';

  @override
  String get myProfile => 'My Profile';

  @override
  String get logout => 'Logout';

  @override
  String get loginTitle => 'Access the Portal';

  @override
  String get loginSubtitle => 'Login with your registered mobile number.';

  @override
  String get loginPhoneLabel => 'Registered Mobile Number';

  @override
  String get loginSendOtp => 'Send OTP';

  @override
  String loginOtpSentTo(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get loginOtpHint =>
      'Enter the 6-digit OTP  ·  use 121212 for this demo';

  @override
  String get loginButton => 'Login';

  @override
  String get loginChangeNumber => '← Change number';

  @override
  String get loginAboutCommunity => 'About the Daivajna Samaja';

  @override
  String get loginNewMember => 'New member?  ';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get loginHeroHeadline => 'Your lineage.\nYour legacy. One portal.';

  @override
  String get loginHeroBody =>
      'Connect with 1,428 families, trace your ancestral roots, and contribute to community welfare.';

  @override
  String get loginErrorInvalidPhone => 'Enter a valid 10-digit phone number';

  @override
  String get loginErrorInvalidOtp => 'Enter the 6-digit OTP';

  @override
  String get loginErrorNotRegistered =>
      'This number isn\'t registered. Please create an account first.';

  @override
  String loginErrorServerUnreachable(String baseUrl) {
    return 'Can\'t reach the server at $baseUrl. Check that the backend is running.';
  }

  @override
  String get loginErrorNetwork => 'Network error. Please try again.';

  @override
  String get registerHeroHeadline => 'Begin your lineage journey today.';

  @override
  String get registerHeroBody =>
      'Join 1,428 families who have documented their heritage and connected with their ancestral roots.';

  @override
  String get registerJoinTitle => 'Join the Samaj';

  @override
  String get registerJoinSubtitle =>
      'Create your account and begin documenting your lineage';

  @override
  String get registerOtpNotice => 'An OTP will be sent to your mobile via SMS';

  @override
  String get registerFullName => 'Full Name';

  @override
  String get registerAsPerAadhar => '(as per aadhar)';

  @override
  String get registerFullNameHint => 'e.g. Aditi Shanbhag Rao';

  @override
  String get registerMobileNumber => 'Mobile Number';

  @override
  String get registerGender => 'Gender';

  @override
  String get registerMale => 'Male';

  @override
  String get registerFemale => 'Female';

  @override
  String get registerMaritalStatus => 'Marital Status';

  @override
  String get registerMarried => 'Married';

  @override
  String get registerUnmarried => 'Unmarried';

  @override
  String get registerDivorced => 'Divorced';

  @override
  String get registerGotra => 'Gotra';

  @override
  String get registerKuladevata => 'Kuladevata';

  @override
  String get registerOptional => '(optional)';

  @override
  String get registerSelectKuladevata => 'Select your Kuladevata';

  @override
  String get registerIsPurohit => 'Are you a purohit?';

  @override
  String get registerYes => 'Yes';

  @override
  String get registerNo => 'No';

  @override
  String get registerNativePlace => 'Native Place (optional)';

  @override
  String get registerNativePlaceHint => 'e.g. Kundapura, Udupi, Karnataka';

  @override
  String get registerDigilockerDetailsDesc =>
      'Optional - verify now and your profile carries the ✓ badge from day one. We never ask for or store your Aadhaar number, only the masked reference DigiLocker returns.';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerAlreadyMember => 'Already a member?  ';

  @override
  String get registerSignIn => 'Sign in';

  @override
  String get registerBackToSignIn => '← Back to Sign in';

  @override
  String get registerVerifyNumber => 'Verify your number';

  @override
  String get registerOtpSentToPrefix => 'OTP sent to ';

  @override
  String registerOtpSentToPhone(String phone) {
    return '+91 $phone';
  }

  @override
  String get registerOtpHint =>
      'Enter the 6-digit OTP  ·  use 121212 for this demo';

  @override
  String get registerCreateAccountContinue => 'Create Account & Continue';

  @override
  String get registerBack => '← Back';

  @override
  String get registerAccountCreated => 'Account created';

  @override
  String get registerAllSet => 'You\'re all set';

  @override
  String get registerVerifyIdentity => 'Verify your identity';

  @override
  String get registerAadhaarVerifiedSubtitle =>
      'Your Aadhaar is verified and saved to your profile - the ✓ badge is already yours.';

  @override
  String get registerAadhaarUnverifiedSubtitle =>
      'Aadhaar KYC through the government DigiLocker earns your profile the ✓ verified badge and keeps our ancestral records trustworthy. We store only a masked reference - never your full Aadhaar number.';

  @override
  String get registerDigilockerIdentityDesc =>
      'Sign in to the official DigiLocker portal and consent to share your Aadhaar. Verification is confirmed automatically.';

  @override
  String get registerContinueToDashboard => 'Continue to Dashboard';

  @override
  String get registerSkipForNow => 'Skip for now - verify later';

  @override
  String get registerKycVerifiedTitle => 'Aadhaar verified via DigiLocker';

  @override
  String get registerKycSavedOnSignup =>
      'Saved to your account when you finish signing up.';

  @override
  String get registerErrorName => 'Please enter your full name';

  @override
  String get registerErrorPhone => 'Please enter a valid 10-digit phone number';

  @override
  String get registerErrorInvalidOtp => 'Invalid OTP. Please try again.';

  @override
  String get registerErrorGeneric => 'Registration failed. Please try again.';

  @override
  String get registerErrorTimeout => 'the server took too long to respond';

  @override
  String registerErrorNetwork(String detail) {
    return 'Network error - $detail';
  }

  @override
  String get heritageStepLabel => 'STEP 3 OF 3';

  @override
  String get heritageTitle => 'Cultural Profile & Heritage';

  @override
  String get heritageSubtitle =>
      'The final step to documenting your legacy within the Daivajna community.';

  @override
  String heritageErrorPickFile(String error) {
    return 'Could not pick file: $error';
  }

  @override
  String get heritageGotra => 'Gotra';

  @override
  String get heritageGotraHint => 'e.g. Kashyap';

  @override
  String get heritageNativePlace => 'Native Place (Kula Devata Location)';

  @override
  String get heritageNativePlaceHint => 'e.g. Gokarna';

  @override
  String get heritageBio => 'Professional Bio';

  @override
  String get heritageBioHint =>
      'Tell the community about your work and skills.';

  @override
  String get heritageMatrimonialOptIn => 'Opt-in to Matrimonial Hub';

  @override
  String get heritageMatrimonialDesc =>
      'Make your profile discoverable to families seeking matrimonial connections within the Samaj. You can change this preference anytime.';

  @override
  String get heritageUploadNote =>
      'Optional: Upload Family Documents (birth certificate, old letters or heirlooms - JPG / PNG)';

  @override
  String get heritageUploadPrompt => 'Click to upload family documents';

  @override
  String get heritageChange => 'Change';

  @override
  String get heritageBackToLineage => 'Back to Lineage';

  @override
  String get heritageCompleteProfile => 'Complete Profile ✓';

  @override
  String get heritageWelcomeTitle => 'Welcome to the Samaj';

  @override
  String get heritageWelcomeBody =>
      'By completing this step, you become a verified member in our living digital tree. You help maintain the cultural integrity and social fabric of the Daivajna community.';

  @override
  String get heritageBenefit1 => 'Access to the Global Lineage Directory';

  @override
  String get heritageBenefit2 => 'Participation in Samaja Governance';

  @override
  String get heritageBenefit3 => 'Community Welfare Program Eligibility';

  @override
  String get onboardStepIdentity => 'Identity';

  @override
  String get onboardStepLineage => 'Lineage';

  @override
  String get onboardStepHeritage => 'Heritage';

  @override
  String get identityStepLabel => 'STEP 1 OF 3';

  @override
  String get identityTitle => 'Verify Your Identity';

  @override
  String get identitySubtitle =>
      'Verify your Aadhaar to maintain the sanctity of our ancestral records. An OTP will be sent to your Aadhaar-linked mobile. Your data is encrypted and never shared with other members.';

  @override
  String get identityDigilockerDesc =>
      'Verify your Aadhaar securely through the government DigiLocker. You\'ll sign in to DigiLocker and consent to share your Aadhaar.';

  @override
  String identityErrorCapture(String error) {
    return 'Could not capture image: $error';
  }

  @override
  String get identitySelfieVerification => 'Selfie Verification';

  @override
  String get identitySelfieCaptured => 'Selfie captured successfully';

  @override
  String get identitySelfiePrompt => 'Take a selfie to match your ID photo';

  @override
  String get identityOpenCamera => 'Open Camera';

  @override
  String get identityContinueToLineage => 'Continue to Lineage';

  @override
  String get identityTrustSecurity => 'Trust & Security';

  @override
  String get identityTrustEncryption => 'AES-256 end-to-end encryption';

  @override
  String get identityTrustNeverShared => 'Never shared with other members';

  @override
  String get identityTrustVault => 'Archival-grade secure vault';

  @override
  String get lineageStepLabel => 'STEP 2 OF 3';

  @override
  String get lineageTitle => 'Find Your Roots';

  @override
  String get lineageSubtitle =>
      'Search for your parents, gotra, or ancestor village to find an existing branch in the Daivajna Samaja tree.';

  @override
  String get lineageSearchHint =>
      'Enter a parent name, Gotra, or ancestor village…';

  @override
  String lineageResultsForQuery(String query) {
    return 'Results for \"$query\"';
  }

  @override
  String get lineagePotentialConnections => 'Potential Connections';

  @override
  String lineageResultsCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String lineageNoMatches(String query) {
    return 'No matches found for \"$query\"';
  }

  @override
  String get lineageBack => 'Back';

  @override
  String get lineageContinueToHeritage => 'Continue to Heritage';

  @override
  String lineageNominatedBy(String nominator) {
    return '✓ $nominator';
  }

  @override
  String get lineageRequested => '✓ Requested';

  @override
  String get lineageConnect => 'Connect';

  @override
  String get lineageNewRootEstablished => 'New Root Node Established';

  @override
  String get lineageNewRootEstablishedDesc =>
      'Your family will be added as a new branch. An elder will verify and link it during review.';

  @override
  String get lineageUndo => 'Undo';

  @override
  String get lineageCantFindBranch => 'Can\'t find your branch?';

  @override
  String get lineageStartNewRootDesc =>
      'You can start a new root node if your family hasn\'t registered yet.';

  @override
  String get lineageEstablishNewRoot => 'Establish New Root Node →';

  @override
  String get dashTitle => 'Samaj Feed';

  @override
  String get dashCouldNotLoadFeed => 'Couldn\'t load the feed';

  @override
  String get dashNoPostsYet => 'No posts yet';

  @override
  String get dashBeFirstToShare =>
      'Be the first to share something with the Samaj.';

  @override
  String get dashAllCaughtUp => 'You\'re all caught up ✦';

  @override
  String get dashFollow => 'Follow';

  @override
  String get dashFollowing => 'Following';

  @override
  String dashErrorCouldNotReachSuffix(String message, String baseUrl) {
    return '$message\nCould not reach $baseUrl';
  }

  @override
  String dashErrorWithStatus(String message, String statusCode) {
    return '$message ($statusCode)';
  }

  @override
  String dashErrorServerUnreachable(String baseUrl) {
    return 'Can\'t reach the server at $baseUrl.\nCheck that the backend is running, or pass --dart-define=API_BASE_URL=<host>.';
  }

  @override
  String dashErrorGeneric(String error) {
    return 'Could not load the feed.\n$error';
  }

  @override
  String get dashCamera => 'Camera';

  @override
  String get dashSelectFile => 'Select file';

  @override
  String dashCouldNotPickMedia(String error) {
    return 'Could not pick media: $error';
  }

  @override
  String get dashFamilyUpdates => 'FAMILY UPDATES';

  @override
  String get dashYourStory => 'Your Story';

  @override
  String get dashYou => 'You';

  @override
  String get dashReel => 'Reel';

  @override
  String get postMenuDelete => 'Delete post';

  @override
  String get postMenuEditCaption => 'Edit caption';

  @override
  String get postMenuReport => 'Report post';

  @override
  String get postMenuHide => 'Hide from feed';

  @override
  String get postMenuCopyLink => 'Copy link';

  @override
  String get postHidden => 'Post hidden';

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get reportThanks => 'Thanks - we\'ll take a look at this post';

  @override
  String get deletePostTitle => 'Delete post?';

  @override
  String get deletePostBody => 'This removes it for everyone in the Samaj.';

  @override
  String get postDelete => 'Delete';

  @override
  String get couldNotDeletePost => 'Could not delete post';

  @override
  String get writeACaption => 'Write a caption…';

  @override
  String get cantEditCaptionYet =>
      'Can\'t edit the caption until the upload finishes.';

  @override
  String get captionUpdated => 'Caption updated';

  @override
  String get couldNotUpdateCaption => 'Could not update caption';

  @override
  String get couldNotUpdateLike => 'Could not update like';

  @override
  String get couldNotUpdateFollow => 'Could not update follow status';

  @override
  String get savedToProfile => 'Saved to your profile';

  @override
  String get removedFromSaved => 'Removed from saved';

  @override
  String get uploadingEllipsis => 'Uploading…';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get discard => 'Discard';

  @override
  String get stillOffline => 'Still offline';

  @override
  String get timeJustNow => 'Just now';

  @override
  String get timeRecently => 'Recently';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String timeWeeksAgo(int n) {
    return '${n}w ago';
  }

  @override
  String get profileRelative => 'Relative';

  @override
  String get profilePendingInvitation => 'Pending Invitation';

  @override
  String get profileFamilyMember => 'Family Member';

  @override
  String get profileViewInFamilyTree => 'View in Family Tree';

  @override
  String get profilePleaseSignIn => 'Please sign in to view your profile.';

  @override
  String get profileGoToLogin => 'Go to Login';

  @override
  String get profileElderAdmin => 'Elder & Samaj Admin';

  @override
  String get profileSamajMember => 'Samaj Member';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileMatrimonialDetails => 'Matrimonial Details';

  @override
  String get profileVerifyIdentityOptional => 'Verify Identity (optional)';

  @override
  String get profileVerifiedPill => 'Verified';

  @override
  String get profileAadhaarVerified => 'Aadhaar Verified';

  @override
  String get profileVerifiedViaDigilocker => 'Verified via DigiLocker';

  @override
  String profileViaDigilockerMasked(String masked) {
    return 'via DigiLocker · $masked';
  }

  @override
  String get profileAboutOccupation => 'About & Occupation';

  @override
  String get profileOccupation => 'Occupation';

  @override
  String get profileBirthYear => 'Birth Year';

  @override
  String get profileStatus => 'Status';

  @override
  String get profileInMemoriam => 'In Memoriam';

  @override
  String get profileActiveMember => 'Active Member';

  @override
  String get profileLate => 'Late';

  @override
  String get profileActive => 'Active';

  @override
  String profilePassedAway(String date) {
    return 'Passed away $date';
  }

  @override
  String profileAt(String place) {
    return 'at $place';
  }

  @override
  String get profileFamilyRelations => 'Family Relations';

  @override
  String get profileFullTree => 'Full Tree →';

  @override
  String get profileNoConnectedRelations => 'No connected relations yet';

  @override
  String get profileNotJoinedYet => 'not joined yet';

  @override
  String get profileLifeArchive => 'Life Archive';

  @override
  String get profileQuickStats => 'Quick Stats';

  @override
  String get profileGotra => 'Gotra';

  @override
  String get profileNative => 'Native';

  @override
  String get profileStanding => 'Standing';

  @override
  String get profileAncestor => 'Ancestor';

  @override
  String get profileMember => 'Member';

  @override
  String get profileSamajId => 'Samaj ID';

  @override
  String profileSamajIdCopied(String id) {
    return 'Samaj ID $id copied';
  }

  @override
  String get profilePhoneNumber => 'Phone Number';

  @override
  String get profileShareWithMembers => 'Share with members';

  @override
  String get profilePhoneVisibleDesc =>
      'Members who open your profile can see and call your number.';

  @override
  String get profilePhoneHiddenDesc =>
      'Your number stays private. Members can still message you in the app.';

  @override
  String get profileVisibleToMembers => 'Visible to members';

  @override
  String get profileHiddenFromMembers => 'Hidden from other members';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileAppearanceDesc => 'Choose how the app looks.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileCouldNotSave =>
      'Couldn\'t save that. Check your connection and try again.';

  @override
  String get profileSaved => 'Saved';

  @override
  String get profileNoSavedPostsYet =>
      'No saved posts yet. Tap the bookmark on any reel or post to keep it here.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editAddPhotoRequired =>
      'Add a profile photo - required for the matrimonial section';

  @override
  String get editTapCameraToChange => 'Tap the camera to change your photo';

  @override
  String get editSectionBasicDetails => 'BASIC DETAILS';

  @override
  String get editSectionCurrentAddress => 'CURRENT ADDRESS';

  @override
  String get editSectionAbout => 'ABOUT';

  @override
  String get editFullName => 'Full name';

  @override
  String get editNameTooShort => 'Name must be at least 2 characters';

  @override
  String get editNativePlace => 'Native place';

  @override
  String get editNativePlaceHint => 'e.g. Kumta, Karnataka';

  @override
  String get editOccupation => 'Occupation';

  @override
  String get editOccupationHint => 'e.g. Software Engineer';

  @override
  String get editCountry => 'Country';

  @override
  String get editCountryHint => 'e.g. India';

  @override
  String get editState => 'State';

  @override
  String get editStateHint => 'e.g. Karnataka';

  @override
  String get editDistrict => 'District';

  @override
  String get editDistrictHint => 'e.g. Bangalore Urban';

  @override
  String get editTaluk => 'Taluk';

  @override
  String get editTalukHint => 'e.g. Bangalore North';

  @override
  String get editCity => 'City / Town / Village';

  @override
  String get editCityHint => 'e.g. Bangalore';

  @override
  String get editArea => 'Area / Locality';

  @override
  String get editAreaHint => 'e.g. Rajajinagar';

  @override
  String get editStreet => 'Street';

  @override
  String get editStreetHint => 'e.g. 3rd Cross, 5th Main';

  @override
  String get editLandmark => 'Landmark';

  @override
  String get editLandmarkHint => 'e.g. Opposite Navrang Theatre';

  @override
  String get editPincode => 'PIN code';

  @override
  String get editPincodeHint => '6 digits';

  @override
  String get editPincodeInvalid => 'PIN code must be 6 digits';

  @override
  String get editBio => 'Bio';

  @override
  String get editAddressOldSingleLine => 'Address (old, single line)';

  @override
  String get editSaving => 'Saving…';

  @override
  String get editSaveChanges => 'Save changes';

  @override
  String get editAadhaarOptionalNote =>
      'Aadhaar verification is optional. Every detail here can be entered by hand - verifying only fills some of them in for you.';

  @override
  String get editGotPositionFillParts =>
      'Got your position - fill in the address parts';

  @override
  String get editAddressFilledFromLocation =>
      'Address filled in from your location';

  @override
  String get editCouldNotReadLocation => 'Could not read your location';

  @override
  String editCouldNotPickImage(String error) {
    return 'Could not pick an image: $error';
  }

  @override
  String get editPhotoUpdated => 'Photo updated';

  @override
  String get editCouldNotUploadPhoto => 'Could not upload the photo';

  @override
  String get editDobHelpText => 'Date of birth';

  @override
  String get editProfileSaved => 'Profile saved';

  @override
  String get editCouldNotSaveProfile => 'Could not save your profile';

  @override
  String editPinnedAt(String lat, String lng) {
    return 'Pinned at $lat, $lng';
  }

  @override
  String get editAlreadyOnMap =>
      'Already on the map. Editing the address re-pins it when you save.';

  @override
  String get editCoordinatesFromAddress =>
      'Coordinates are worked out from the address when you save.';

  @override
  String get editLocating => 'Locating…';

  @override
  String get editUseCurrentLocation => 'Use my current location';

  @override
  String get editGotra => 'Gotra';

  @override
  String get editSelectGotra => 'Select your gotra';

  @override
  String get editBloodGroup => 'Blood group';

  @override
  String get editSelectBloodGroup => 'Select blood group';

  @override
  String get editMaritalStatus => 'Marital status';

  @override
  String get editSelectMaritalStatus => 'Select marital status';

  @override
  String get editMarried => 'Married';

  @override
  String get editUnmarried => 'Unmarried';

  @override
  String get editDivorced => 'Divorced';

  @override
  String get editKuladevata => 'Kuladevata';

  @override
  String get editSelectKuladevata => 'Select your Kuladevata';

  @override
  String get editNotSet => 'Not set';

  @override
  String get editGender => 'Gender';

  @override
  String get editMale => 'Male';

  @override
  String get editFemale => 'Female';

  @override
  String editAgeYears(int age) {
    return '$age years';
  }

  @override
  String get verifyIdentityTitle => 'Verify Identity';

  @override
  String get verifyIdentityHeading => 'Identity Verification';

  @override
  String get verifyIdentitySubtitle =>
      'Verify your Aadhaar securely through the government DigiLocker. Your profile stays Not Verified until this is complete. We never see or store your full Aadhaar number - only a masked reference.';

  @override
  String get verifyBackToDashboard => 'Back to Dashboard';

  @override
  String get verifyTrustGovBacked => 'Government-backed DigiLocker consent';

  @override
  String get verifyTrustNeverStored => 'Full Aadhaar number is never stored';

  @override
  String get verifyTrustMaskedOnly => 'Only a masked reference is kept';

  @override
  String get ftTitle => 'Family Tree';

  @override
  String get ftUnableToLoad => 'Unable to load';

  @override
  String get ftLoadError =>
      'Could not load the family tree. Check your connection.';

  @override
  String get ftEmptyTitle => 'Your family tree is empty';

  @override
  String get ftEmptyBody =>
      'Add your immediate family - father, mother, spouse, siblings, children. Their trees connect to yours as they join.';

  @override
  String get ftAddFamilyMember => 'Add Family Member';

  @override
  String get ftTruncatedBanner =>
      'Showing part of the tree — it has more relatives than one view can hold.';

  @override
  String get ftHeaderKicker => 'DAIVAJNA SAMAJA · LINEAGE';

  @override
  String get ftHeaderTitle => 'Vamsha Vruksha';

  @override
  String get ftAddMember => 'Add Member';

  @override
  String get ftRequests => 'Requests';

  @override
  String get ftInvites => 'Invites';

  @override
  String get ftAlerts => 'Alerts';

  @override
  String get ftManageLinks => 'Manage links';

  @override
  String get ftCompactView => 'Compact view';

  @override
  String get ftExpandAll => 'Expand all';

  @override
  String ftGenRow(String roman) {
    return 'GEN $roman';
  }

  @override
  String get ftDefaultInviteMessage => 'You have a pending invitation.';

  @override
  String ftMoreCount(int n) {
    return '  (+$n more)';
  }

  @override
  String get ftReview => 'Review';

  @override
  String get ftYourGeneration => 'Your generation';

  @override
  String get ftOneGenAbove => 'One generation above';

  @override
  String ftGenerationsAbove(int n) {
    return '$n generations above';
  }

  @override
  String get ftOneGenBelow => 'One generation below';

  @override
  String ftGenerationsBelow(int n) {
    return '$n generations below';
  }

  @override
  String get ftRelative => 'Relative';

  @override
  String get ftYou => 'You';

  @override
  String ftDerivedFrom(String path) {
    return 'Derived from: your $path';
  }

  @override
  String ftShowTheirFamily(int n) {
    return 'Show their family ($n)';
  }

  @override
  String get ftHideTheirFamily => 'Hide their family';

  @override
  String get ftViewProfile => 'View Profile';

  @override
  String get ftWithdrawThisRequest => 'Withdraw this request';

  @override
  String get ftRemoveThisRelationship => 'Remove this relationship';

  @override
  String get ftVerifiedDeceased => 'Verified Deceased';

  @override
  String get ftVerifiedDeceasedDesc =>
      'Added directly to the tree - no approval needed.';

  @override
  String get ftPendingInvitation => 'Pending Invitation';

  @override
  String get ftPendingInvitationDesc =>
      'This person has not joined yet. The relationship activates when they register and accept.';

  @override
  String get ftActiveMember => 'Active Member';

  @override
  String get ftActiveMemberDesc => 'Linked to a verified member account.';

  @override
  String get ftInMemoriam => 'In Memoriam';

  @override
  String get ftLatePrefix => 'Late ';

  @override
  String ftInviteDialogTitle(String name) {
    return 'Invite $name';
  }

  @override
  String get ftInviteDialogBody =>
      'A placeholder was added and the relationship is pending. Share this invite so they can join and connect back to you.';

  @override
  String get ftClose => 'Close';

  @override
  String get ftCopyLink => 'Copy link';

  @override
  String get ftInviteLinkCopied => 'Invite link copied';

  @override
  String get ftYourRelative => 'Your relative';

  @override
  String get ftMemberAdded => 'Member added';

  @override
  String get ftWithdrawRequestTitle => 'Withdraw this request?';

  @override
  String get ftRemoveLinkTitle => 'Remove this link?';

  @override
  String ftWithdrawRequestBody(String name, String relation) {
    return '$name will no longer be asked to join as your $relation.';
  }

  @override
  String ftRemoveLinkBody(String name, String relation) {
    return '$name stops being your $relation. The link leaves both trees, along with everyone who was only reached through it. You can add each other again with the correct relation.';
  }

  @override
  String get ftOptionalNoteHint =>
      'Optional note to them — e.g. \"wrong relation\"';

  @override
  String get ftRequestWithdrawn => 'Request withdrawn';

  @override
  String get ftRelationshipRemoved => 'Relationship removed';

  @override
  String get ftCouldNotRemoveRelationship =>
      'Could not remove the relationship';

  @override
  String get ftManageRelationships => 'Manage Relationships';

  @override
  String get ftNoRelationshipsYet => 'No relationships yet';

  @override
  String get ftNoRelationshipsYetDesc =>
      'Links you add — or that a relative adds naming you — show up here, and can be removed from either side.';

  @override
  String get ftRemovingLinkNote =>
      'Removing a link takes it out of both trees, along with anyone who was only reached through it. The pair can be added again with the correct relation.';

  @override
  String get ftNotAcceptedYet => 'Not accepted yet';

  @override
  String ftYourRelation(String relation) {
    return 'Your $relation';
  }

  @override
  String get ftRelationFather => 'Father';

  @override
  String get ftRelationMother => 'Mother';

  @override
  String get ftRelationSpouse => 'Spouse';

  @override
  String get ftRelationBrother => 'Brother';

  @override
  String get ftRelationSister => 'Sister';

  @override
  String get ftRelationSon => 'Son';

  @override
  String get ftRelationDaughter => 'Daughter';

  @override
  String get ftRelationshipToYou => 'Relationship to you *';

  @override
  String get ftHasAccount => 'Has an account';

  @override
  String get ftNewProfile => 'New profile';

  @override
  String get ftFindByNamePhone => 'Find them by name, phone or Samaj ID';

  @override
  String get ftSearchHint => 'e.g. 9876543210 or Ramesh';

  @override
  String get ftSearch => 'Search';

  @override
  String get ftAccountRequestNote =>
      'A living member with an account must accept your request before the relationship shows in both trees.';

  @override
  String get ftFullName => 'Full Name *';

  @override
  String get ftFullNameHint => 'e.g. Ramesh Haldankar';

  @override
  String get ftGender => 'Gender';

  @override
  String get ftMale => 'Male';

  @override
  String get ftFemale => 'Female';

  @override
  String get ftStatus => 'Status';

  @override
  String get ftAlive => 'Alive';

  @override
  String get ftDeceased => 'Deceased';

  @override
  String get ftDeceasedNote =>
      'A deceased person is added immediately - no invitation or approval.';

  @override
  String get ftAliveNote =>
      'A living person is invited: they join and confirm the relationship.';

  @override
  String get ftPhoneOptional => 'Phone (optional)';

  @override
  String get ftPhoneLinkNote =>
      'Used to link their account when they register.';

  @override
  String get ftDateOfBirth => 'Date of Birth *';

  @override
  String get ftDateOfDeath => 'Date of Death';

  @override
  String get ftPlaceOfDeath => 'Place of Death';

  @override
  String get ftPlaceOfDeathHint => 'e.g. Kundapura';

  @override
  String get ftBiography => 'Biography';

  @override
  String get ftBiographyHint => 'A few words about their life…';

  @override
  String get ftSelect => 'Select';

  @override
  String get ftSendRequest => 'Send Request';

  @override
  String get ftAddToFamilyTree => 'Add to Family Tree';

  @override
  String get ftCreateAndInvite => 'Create & Invite';

  @override
  String get ftSelectPersonToRequest =>
      'Select the person to send a request to';

  @override
  String get ftNameRequired => 'Name is required';

  @override
  String get ftDobRequired => 'Date of birth is required';

  @override
  String get ftSearchFailed => 'Search failed. Check your connection.';

  @override
  String get ftCouldNotAddMember =>
      'Could not add the member. Check your connection.';

  @override
  String get ftDefaultMemberName => 'Member';

  @override
  String ftAlreadyConnected(String name) {
    return 'You are already connected to $name.';
  }

  @override
  String ftRequestSent(String name) {
    return 'Request sent to $name - they’ll appear once they accept.';
  }

  @override
  String ftInvited(String name) {
    return '$name invited - share the link so they can join.';
  }

  @override
  String ftAddedToTree(String name) {
    return '$name added to the family tree.';
  }

  @override
  String ftAdded(String name) {
    return '$name added.';
  }

  @override
  String get ftRelationshipRequests => 'Relationship Requests';

  @override
  String get ftNoPendingRequests => 'No pending requests';

  @override
  String get ftNoPendingRequestsDesc =>
      'When a relative asks to connect with you, it shows up here.';

  @override
  String get ftWaitingOnThem => 'Waiting on them';

  @override
  String get ftWaitingOnThemDesc =>
      'These stay out of the tree until the other person accepts.';

  @override
  String ftAddedAsYourRelation(String relation) {
    return 'Added as your $relation';
  }

  @override
  String get ftCopyInvite => 'Copy invite';

  @override
  String get ftWithdraw => 'Withdraw';

  @override
  String get ftCouldNotWithdrawRequest => 'Could not withdraw the request';

  @override
  String get ftCouldNotUpdateRequest => 'Could not update the request';

  @override
  String ftWantsToConnect(String name) {
    return '$name wants to connect.';
  }

  @override
  String get ftDecline => 'Decline';

  @override
  String get ftAccept => 'Accept';

  @override
  String get ftYourInvitations => 'Your Invitations';

  @override
  String get ftAllSet => 'All set';

  @override
  String get ftConnectedTreesMerged => 'Connected - your trees are now merged.';

  @override
  String get ftDone => 'Done.';

  @override
  String get ftInvitationsDeclined => 'Invitations declined.';

  @override
  String get ftCouldNotUpdateInvitations => 'Could not update the invitations';

  @override
  String get ftNoInvitations => 'No invitations';

  @override
  String get ftNoInvitationsDesc =>
      'Invitations others send to your number will appear here.';

  @override
  String get ftAcceptingMergesNote =>
      'Accepting confirms these people are your family and merges their placeholder profiles into your account.';

  @override
  String get ftAcceptAndConnect => 'Accept & Connect';

  @override
  String get ftNotifications => 'Notifications';

  @override
  String get ftMarkAllRead => 'Mark all read';

  @override
  String get ftNoNotifications => 'No notifications';

  @override
  String get ftNoNotificationsDesc =>
      'Relationship activity - requests, joins, merges - appears here.';

  @override
  String get ftAccepted => 'Accepted';

  @override
  String get ftDeclined => 'Declined';

  @override
  String get ftSomeone => 'Someone';

  @override
  String get invTitle => 'Invitations';

  @override
  String get invCouldNotLoadMap => 'Could not load the map';

  @override
  String get invRoutePlanError => 'Could not plan the route';

  @override
  String get invCouldNotReadLocation => 'Could not read your location';

  @override
  String get invSelectAtLeastOne => 'Select at least one family to begin.';

  @override
  String get invNoMapsApp => 'No maps app could open the route';

  @override
  String invNavigatingFirst10(int dropped) {
    return 'Navigating the first 10 stops - maps can only take that many at once ($dropped left for the next trip).';
  }

  @override
  String get invCouldNotOpenMapsApp => 'Could not open a maps app';

  @override
  String get invCheckConnectionRetry => 'Check your connection and try again.';

  @override
  String get invRetry => 'Retry';

  @override
  String get invRefresh => 'Refresh';

  @override
  String get invNoMembersYet => 'No members on the map yet';

  @override
  String invNoMembersMatch(String query) {
    return 'No members match \"$query\"';
  }

  @override
  String get invNoMembersYetDetail =>
      'A member appears here once they save their current address - the address is what puts them on the map.';

  @override
  String get invSearchMatchesDetail =>
      'Search matches Samaj ID, username or phone number.';

  @override
  String get invSmartPlanner => 'SMART INVITATION PLANNER';

  @override
  String get invRoutePlanner => 'Route Planner';

  @override
  String get invSelectFamiliesSubtitle =>
      'Select families · the route orders itself';

  @override
  String invShowingNearest(int shown, int total) {
    return 'Showing the $shown nearest of $total mapped members.';
  }

  @override
  String get invStartFrom => 'START FROM';

  @override
  String get invLocating => 'Locating…';

  @override
  String get invWaitingForLocation => 'Waiting for your location';

  @override
  String invCurrentLocation(String lat, String lng) {
    return 'Current location · $lat, $lng';
  }

  @override
  String get invUpdate => 'Update';

  @override
  String get invSearchHint => 'Search by name, area or Samaj ID';

  @override
  String get invLoadingMap => 'Loading the map…';

  @override
  String get invSelectFamiliesToPlan => 'Select families to plan a route';

  @override
  String invFromTheStart(String km) {
    return '$km from the start';
  }

  @override
  String invFromStopN(String km, int n) {
    return '$km from stop $n';
  }

  @override
  String invAway(String km) {
    return '$km away';
  }

  @override
  String get invOptimisingRoute => 'Optimising the route…';

  @override
  String get invPickFamilies => 'Pick the families to visit';

  @override
  String get invStraightLineEstimate => ' (straight-line estimate)';

  @override
  String get invStop => 'stop';

  @override
  String get invStops => 'stops';

  @override
  String get invStartNavigation => 'Start Navigation';

  @override
  String get dirTitle => 'Member Directory';

  @override
  String get dirSearchHint => 'Search members, gotras, or locations…';

  @override
  String get dirAdvancedFiltersSoon => 'Advanced filters coming soon';

  @override
  String get dirAllMembers => 'All Members';

  @override
  String get dirNearbyMe => 'Nearby Me';

  @override
  String get dirByArea => 'By Area';

  @override
  String get dirByGotra => 'By Gotra';

  @override
  String get dirByOccupation => 'By Occupation';

  @override
  String get dirMapView => 'Map View';

  @override
  String get dirNearbyMembers => 'Nearby Members';

  @override
  String get dirViewAll => 'View All →';

  @override
  String get dirFromNativePlaceFirst => 'From your native place first';

  @override
  String get dirNoOtherMembersYet => 'No other members yet.';

  @override
  String get dirSuggestedConnections => 'Suggested Connections';

  @override
  String get dirNoMembersYet => 'No members yet';

  @override
  String get dirNoMembersFound => 'No members found';

  @override
  String get dirMembersAppearHere =>
      'Members appear here as your Vamsha Vruksha grows.';

  @override
  String dirGotraSuffix(String gotra) {
    return '$gotra Gotra';
  }

  @override
  String get dirMessage => 'Message';

  @override
  String get dirConnect => 'Connect';

  @override
  String get dirSameGotra => 'SAME GOTRA';

  @override
  String dirReasonWithOcc(String occ, String gotra) {
    return '$occ · shares your $gotra gotra.';
  }

  @override
  String dirReasonNoOcc(String gotra, String place) {
    return 'Shares your $gotra gotra, rooted in $place.';
  }

  @override
  String get dirViewProfile => 'View Profile';

  @override
  String get dirCommunityMap => 'Community Map';

  @override
  String dirMembersCount(int n) {
    return '$n members';
  }

  @override
  String get dirExploreRegion => 'Explore Region';

  @override
  String get dirSamajMember => 'Samaj member';

  @override
  String get dirGroupOther => 'Other';

  @override
  String get dirGroupNotSpecified => 'Not specified';

  @override
  String get dirNumberCopied => 'Number copied';

  @override
  String get dirGotra => 'Gotra';

  @override
  String get dirNative => 'Native';

  @override
  String get dirOccupation => 'Occupation';

  @override
  String get dirPhone => 'Phone';

  @override
  String dirPhoneCopied(String phone) {
    return '$phone copied';
  }

  @override
  String get dirNoMembersToPlace => 'No members to place on the map';

  @override
  String dirPhoneDisabled(String name) {
    return '$name has disabled their phone number. You cannot call them - send a message instead.';
  }

  @override
  String get dirThisMember => 'This member';

  @override
  String dirCouldNotOpenDialer(String phone) {
    return 'Could not open the dialer for $phone';
  }

  @override
  String get dirDefaultMemberName => 'Member';

  @override
  String get matTitle => 'Matrimonial';

  @override
  String get matCouldNotReachServer => 'Could not reach the server';

  @override
  String get matProfileLive => 'Your profile is live in the Matrimonial Hub';

  @override
  String get matCouldNotPublish => 'Could not publish';

  @override
  String get matCouldNotLoad => 'Could not load';

  @override
  String get matTryAgain => 'Try again';

  @override
  String get matAddDob => 'Add your date of birth';

  @override
  String get matNotAvailable => 'Not available';

  @override
  String matAgeRangeAddDob(String min, String max) {
    return 'The matrimonial section is open to members aged $min-$max. Add your date of birth in your profile to continue.';
  }

  @override
  String matAgeRangeYourAge(String min, String max, String age) {
    return 'The matrimonial section is open to members aged $min-$max. Your age is $age.';
  }

  @override
  String get matGoToMyProfile => 'Go to my profile';

  @override
  String get matNotForMarried => 'Not applicable';

  @override
  String get matNotForMarriedBody =>
      'The matrimonial hub is only for unmarried or divorced members. You told us you\'re married — you can change this in your profile if that\'s changed.';

  @override
  String get matReadyToPublish => 'Ready to publish';

  @override
  String get matDetailsCompletePublish =>
      'Your details are complete. Publish your profile to enter the hub.';

  @override
  String matDetailsCompleteNote(String note) {
    return 'Your details are complete. Earlier note on this profile: $note';
  }

  @override
  String get matPublishMyProfile => 'Publish my profile';

  @override
  String get matHubTitle => 'Matrimonial Hub';

  @override
  String get matProfileCompletePublish =>
      'Your profile is complete. Publish it to enter the hub.';

  @override
  String get matCompleteToEnter =>
      'Complete your profile to enter. Every field below is shown to prospective matches, so the hub stays trustworthy for everyone.';

  @override
  String get matStillToFill => 'STILL TO FILL';

  @override
  String matRemaining(int n) {
    return '$n remaining';
  }

  @override
  String get matInYourProfile => 'In your profile';

  @override
  String get matEditMyProfile => 'Edit my profile';

  @override
  String get matInYourMatrimonialDetails => 'In your matrimonial details';

  @override
  String get matAddMatrimonialDetails => 'Add matrimonial details';

  @override
  String get matAllDetailsFilledIn => 'All required details are filled in.';

  @override
  String get matPublishing => 'Publishing…';

  @override
  String get matOptionalAadhaarNote =>
      'Aadhaar verification is optional - every detail can be entered by hand. Your details are visible only to other members who have completed and published their own profile, and you can withdraw yours at any time.';

  @override
  String get matCouldNotLoadProfiles => 'Could not load profiles';

  @override
  String get matDiscoverMatches => 'Discover Matches';

  @override
  String get matShowingBrides => 'Showing Brides';

  @override
  String get matShowingGrooms => 'Showing Grooms';

  @override
  String get matShowingAllProfiles => 'Showing All Profiles';

  @override
  String matProfilesCount(int n) {
    return '$n profiles';
  }

  @override
  String get matNoProfilesYet => 'No profiles yet';

  @override
  String get matBride => 'Bride';

  @override
  String get matGroom => 'Groom';

  @override
  String get matVerified => 'Verified';

  @override
  String get matFree => 'Free';

  @override
  String get matPremium => 'Premium';

  @override
  String get matViewProfile => 'View Profile';

  @override
  String get matCandidateProfile => 'Candidate Profile';

  @override
  String get matProfileNotFound => 'Profile not found';

  @override
  String get matBackToHub => 'Back to Matrimonial Hub';

  @override
  String get matMatchSummary => 'Match Summary';

  @override
  String get matProfessional => 'Professional';

  @override
  String get matEducation => 'Education';

  @override
  String get matCompany => 'Company';

  @override
  String get matDesignation => 'Designation';

  @override
  String get matAnnualIncome => 'Annual Income';

  @override
  String get matPersonal => 'Personal';

  @override
  String get matHeight => 'Height';

  @override
  String get matComplexion => 'Complexion';

  @override
  String get matFamilyType => 'Family Type';

  @override
  String get matFamily => 'Family';

  @override
  String get matFather => 'Father';

  @override
  String get matMother => 'Mother';

  @override
  String get matSiblings => 'Number of siblings';

  @override
  String get matHoroscope => 'Horoscope';

  @override
  String get matStarNakshatra => 'Star / Nakshatra';

  @override
  String get matRashi => 'Rashi';

  @override
  String get matMangal => 'Mangal';

  @override
  String get matMangalik => 'Mangalik';

  @override
  String get matNonMangalik => 'Non-Mangalik';

  @override
  String get matGotraSurname => 'Gotra / Surname';

  @override
  String get matTimeOfBirth => 'Time of Birth';

  @override
  String get matAbout => 'About';

  @override
  String get matInterests => 'Interests';

  @override
  String get matPartnerExpectations => 'Partner Expectations';

  @override
  String get matPremiumProfileTitle => 'Premium Profile';

  @override
  String get matPremiumProfileBody =>
      'This is a premium profile. Connections are arranged exclusively through the Elder Committee. Please contact a Samaj elder to proceed with an introduction.';

  @override
  String get matUnderstood => 'Understood';

  @override
  String get matPremiumConnectViaElder =>
      'Premium - Connect via Elder Committee';

  @override
  String get matCheckCompatibility => 'Check Compatibility';

  @override
  String get matIntentionSoon => 'Soon';

  @override
  String get matIntentionOneToTwoYears => '1-2 Years';

  @override
  String get matIntentionNotDecided => 'Not Decided';

  @override
  String get matChildrenWant => 'Want';

  @override
  String get matChildrenDontWant => 'Don\'t Want';

  @override
  String get matChildrenOpen => 'Open';

  @override
  String get matFamilyJoint => 'Joint';

  @override
  String get matFamilyNuclear => 'Nuclear';

  @override
  String get matFamilyFlexible => 'Flexible';

  @override
  String get matRelocationYes => 'Yes';

  @override
  String get matRelocationNo => 'No';

  @override
  String get matRelocationMaybe => 'Maybe';

  @override
  String get matFoodVegetarian => 'Vegetarian';

  @override
  String get matFoodNonVegetarian => 'Non-Vegetarian';

  @override
  String get matFoodEggetarian => 'Eggetarian';

  @override
  String get matFoodOther => 'Other';

  @override
  String get matInterestTravel => 'Travel';

  @override
  String get matInterestMusic => 'Music';

  @override
  String get matInterestMovies => 'Movies';

  @override
  String get matInterestFitness => 'Fitness';

  @override
  String get matInterestSports => 'Sports';

  @override
  String get matInterestReading => 'Reading';

  @override
  String get matInterestCooking => 'Cooking';

  @override
  String get matInterestSpirituality => 'Spirituality';

  @override
  String get matEditTitle => 'Matrimonial Details';

  @override
  String get matCouldNotLoadDetails => 'Could not load your details';

  @override
  String get matAgeFromToError =>
      'Preferred partner age: \"from\" cannot be greater than \"to\"';

  @override
  String get matDetailsSaved => 'Matrimonial details saved';

  @override
  String get matCouldNotSaveDetails => 'Could not save your details';

  @override
  String get matSectionCareer => 'CAREER';

  @override
  String get matEducationHint => 'e.g. MBA Finance, IIM Bangalore';

  @override
  String get matOccupationType => 'Occupation type';

  @override
  String get matOccupationSalaried => 'Salaried';

  @override
  String get matOccupationSelfEmployed => 'Self Employed';

  @override
  String get matOccupationUnemployed => 'Unemployed';

  @override
  String get matCompanyOrg => 'Company / organisation';

  @override
  String get matIncomeRange => 'Income range';

  @override
  String get matIncomeRangeHint => 'e.g. ₹22-28L';

  @override
  String get matSectionPhysical => 'PHYSICAL';

  @override
  String get matComplexionFair => 'Fair';

  @override
  String get matComplexionWheatish => 'Wheatish';

  @override
  String get matComplexionDusky => 'Dusky';

  @override
  String get matComplexionDark => 'Dark';

  @override
  String get matSectionFamily => 'FAMILY';

  @override
  String get matFamilyTypeLabel => 'Family type';

  @override
  String get matFathersOccupation => 'Father\'s occupation';

  @override
  String get matMothersOccupation => 'Mother\'s occupation';

  @override
  String get matSiblingsHint => 'e.g. 2';

  @override
  String get matSiblingsRangeError => 'Enter a number between 0 and 20';

  @override
  String get matSectionHoroscope => 'HOROSCOPE';

  @override
  String get matStarNakshatraLabel => 'Star (nakshatra)';

  @override
  String get matStarHint => 'e.g. Rohini';

  @override
  String get matRashiHint => 'e.g. Vrishabha';

  @override
  String get matTimeOfBirthLabel => 'Time of birth';

  @override
  String get matTimeOfBirthHint => 'e.g. 10:45 AM';

  @override
  String get matSectionCompatibility => 'COMPATIBILITY';

  @override
  String get matAddBirthDetailsLink => 'Add birth details for compatibility →';

  @override
  String get matManageConsentLink => 'Manage compatibility consent →';

  @override
  String get matSectionAboutYou => 'ABOUT YOU';

  @override
  String get matAboutYouLabel => 'About you';

  @override
  String get matSectionLookingFor => 'WHAT YOU ARE LOOKING FOR';

  @override
  String get matPartnerExpectationsLabel => 'Partner expectations';

  @override
  String get matOnePerLine => 'One per line';

  @override
  String get matPreferredLocationsOptional => 'Preferred locations (optional)';

  @override
  String get matPreferredLocationsHint =>
      'Comma separated, e.g. Bengaluru, Mangaluru';

  @override
  String get matGotrasToExcludeOptional => 'Gotras to exclude (optional)';

  @override
  String get matGotrasToExcludeHint =>
      'Comma separated. Your own gotra is always excluded.';

  @override
  String get matSectionMarriagePreferences => 'MARRIAGE PREFERENCES';

  @override
  String get matMarriageIntention => 'Marriage intention';

  @override
  String get matChildren => 'Children';

  @override
  String get matFamily2 => 'Family';

  @override
  String get matRelocation => 'Relocation';

  @override
  String get matSectionLifestyle => 'LIFESTYLE';

  @override
  String get matFoodPreference => 'Food preference';

  @override
  String get matSectionInterests => 'INTERESTS';

  @override
  String get matSaving2 => 'Saving…';

  @override
  String get matSaveDetails => 'Save details';

  @override
  String get matSavedAsDraftNote =>
      'Saved privately as a draft. You publish it from the Matrimonial section once everything is filled in.';

  @override
  String get matHeightCm => 'Height (cm)';

  @override
  String get matHeightHint => 'e.g. 163';

  @override
  String get matEnterNumberInCm => 'Enter a number in centimetres';

  @override
  String get matHeightRangeError => 'Height must be between 120 and 250 cm';

  @override
  String get matHeightFeet => 'Feet';

  @override
  String get matHeightFeetHint => 'e.g. 5';

  @override
  String get matHeightInches => 'Inches';

  @override
  String get matHeightInchesHint => 'e.g. 7';

  @override
  String get matHeightFeetRangeError => 'Feet must be between 3 and 8';

  @override
  String get matHeightInchesRangeError => 'Inches must be between 0 and 11';

  @override
  String get matMangalDosha => 'Mangal dosha';

  @override
  String get matPartnerAgeFrom => 'Partner age from';

  @override
  String get matPartnerAgeTo => 'Partner age to';

  @override
  String get welfareTitle => 'Welfare';

  @override
  String get welfareStartCampaign => 'Start a Campaign';

  @override
  String get welfareKicker => 'COMMUNITY WELFARE & DEVELOPMENT';

  @override
  String get welfareHeroLine =>
      'Build the Samaj tree, one contribution at a time.';

  @override
  String get welfareTotalRaised => 'Total Raised';

  @override
  String get welfareTotalBackers => 'Total Backers';

  @override
  String get welfareActiveCampaigns => 'Active Fundraising Campaigns';

  @override
  String welfareRaised(String amount) {
    return '$amount raised';
  }

  @override
  String welfareOfGoalPct(String goal, int pct) {
    return 'of $goal · $pct%';
  }

  @override
  String welfareDaysLeft(int n) {
    return '$n days left';
  }

  @override
  String welfareBackers(int n) {
    return '$n backers';
  }

  @override
  String get welfareDonate => 'Donate';

  @override
  String get welfareImpactTitle => 'Heritage Impact 2024-25';

  @override
  String get welfareImpactBody =>
      'See exactly where every rupee goes - full transparency report.';

  @override
  String get welfareViewImpactReport => 'View Impact Report';

  @override
  String get welfareDhanyavaad => 'Dhanyavaad! 🙏';

  @override
  String welfareThankYouReceived(String title) {
    return 'Thank you! Your contribution to $title is received.';
  }

  @override
  String get welfareBackToWelfare => 'Back to Welfare';

  @override
  String get welfareMakeContribution => 'Make a Contribution';

  @override
  String get welfareCampaignNotFound => 'Campaign not found';

  @override
  String welfarePctLabel(int pct) {
    return '$pct%';
  }

  @override
  String welfareDaysLeftContributors(int days, int backers) {
    return '$days days left · $backers contributors';
  }

  @override
  String get welfareTransparencyPledge => 'Transparency Pledge';

  @override
  String get welfareTransparencyPledgeBody =>
      '100% of your contribution flows directly to a monitored committee account, published quarterly in the Impact Report.';

  @override
  String get welfareSelectAmount => 'SELECT AMOUNT (₹)';

  @override
  String get welfareEnterCustomAmount => 'Enter custom amount';

  @override
  String get welfareDonorName => 'DONOR NAME';

  @override
  String get welfareAnonymous => 'Anonymous';

  @override
  String get welfareYourName => 'Your name';

  @override
  String get welfareDonateAnonymously => 'Donate anonymously';

  @override
  String get welfarePaymentMethod => 'PAYMENT METHOD';

  @override
  String get welfareUpiQr => 'UPI / QR Code';

  @override
  String get welfareCreditDebitCard => 'Credit / Debit Card';

  @override
  String get welfareNetBanking => 'Net Banking';

  @override
  String welfareDonateAmount(String amount) {
    return 'Donate ₹$amount';
  }

  @override
  String get welfareImpactReport => 'Impact Report';

  @override
  String get welfareAnnualReportKicker =>
      'DAIVAJNA SAMAJA BANGALORE - ANNUAL TRANSPARENCY REPORT';

  @override
  String get welfareRecordOfContributions =>
      'A record of our community’s generous contributions and their measurable outcomes.';

  @override
  String get welfareFamiliesHelped => 'Families Helped';

  @override
  String get welfareCampaignsFunded => 'Campaigns Funded';

  @override
  String get welfareScholarships => 'Scholarships';

  @override
  String get welfareCategoryBreakdown => 'Category Breakdown';

  @override
  String get welfareCategoryBreakdownSubtitle =>
      'Share of funds raised by campaign category';

  @override
  String get welfareFundAllocation => 'Fund Allocation';

  @override
  String get welfareAuditQuote =>
      '“Every rupee documented. Every decision transparent.” - Daivajna Audit Committee';

  @override
  String get welfareGuardianDonors => 'Guardian Donors';

  @override
  String get welfareSupportCampaign => 'Support a Campaign';

  @override
  String get welfareAllocTempleHeritage => 'Temple & Heritage';

  @override
  String get welfareAllocEducation => 'Education';

  @override
  String get welfareAllocHealthWelfare => 'Health & Welfare';

  @override
  String get welfareAllocCulturalEvents => 'Cultural Events';

  @override
  String get welfareDonorHeadRole => 'Elder Committee Head';

  @override
  String get welfareDonorPatronRole => 'Samaj Life Patron';

  @override
  String get welfareDonorItRole => 'IT Professionals Chapter';

  @override
  String get welfareDonorEntrepreneurRole => 'Entrepreneur, Bengaluru';

  @override
  String get welfareTestimonial1 =>
      '“This temple is proof that our Samaj never forgets its roots.”';

  @override
  String get welfareTestimonial1Author => 'Priya K., Community Member';

  @override
  String get welfareTestimonial2 =>
      '“The scholarship let me finish my engineering degree. I am forever grateful to the Samaj.”';

  @override
  String get welfareTestimonial2Author => 'Asha H., Gokarna';

  @override
  String get welfareCampaignSubmitted => 'Campaign Submitted!';

  @override
  String get welfareCampaignReviewNote =>
      'Your campaign will be reviewed by the Elder Committee. You’ll receive a notification within 48 hours.';

  @override
  String get welfareLaunchNewCampaign => 'Launch a New Campaign';

  @override
  String get welfareTransparencyNoteTitle => 'A Note on Transparency';

  @override
  String get welfareTransparencyNoteBody =>
      'Each campaign is vetted by the Elder sub-committee to ensure heritage alignment and financial integrity.';

  @override
  String get welfareCampaignTitle => 'Campaign Title';

  @override
  String get welfareCampaignTitleHint => 'e.g. Restoration of Heritage Library';

  @override
  String get welfareCategory => 'Category';

  @override
  String get welfareCampaignStory => 'Campaign Story';

  @override
  String get welfareCampaignStoryHint =>
      'Describe the history, the need, and the impact on our community…';

  @override
  String get welfareFundraisingGoal => 'Fundraising Goal (₹)';

  @override
  String get welfareFundraisingGoalHint => 'e.g. 500000';

  @override
  String get welfareDuration => 'Duration';

  @override
  String welfareDurationDays(int n) {
    return '$n days';
  }

  @override
  String get welfareChooseIcon => 'Choose an Icon';

  @override
  String get welfareVerificationChecklist => 'Verification Checklist';

  @override
  String get welfareCheckCommunityBenefit =>
      'Campaign is for community benefit';

  @override
  String get welfareCheckFundsManaged => 'Funds will be managed by committee';

  @override
  String get welfareCheckMonthlyReports =>
      'Monthly progress reports will be shared';

  @override
  String get welfareCheckEldersInformed =>
      'Elder sub-committee has been informed';

  @override
  String get welfareSubmitForReview => 'Submit for Review';

  @override
  String get welfareCategoryInfrastructure => 'Infrastructure';

  @override
  String get welfareCategoryCulturalHeritage => 'Cultural Heritage';

  @override
  String get welfareCategoryEducation => 'Education';

  @override
  String get welfareCategoryEmergency => 'Emergency';

  @override
  String get welfareCategoryHealthcare => 'Healthcare';

  @override
  String get elderDefaultName => 'Elder';

  @override
  String get elderHighRisk => 'High Risk';

  @override
  String get elderMedRisk => 'Med Risk';

  @override
  String get elderLowRisk => 'Low Risk';

  @override
  String get elderLineageTree => 'Lineage Tree';

  @override
  String get elderPortalKicker => 'ELDER PORTAL · DAIVAJNA SAMAJA';

  @override
  String elderWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get elderGuardianOfTree => 'Guardian of the Tree';

  @override
  String get elderDashboardBlurb =>
      'Your lineage oversight and community management dashboard. Review pending verifications, resolve conflicts, and guide the Samaja.';

  @override
  String get elderPendingVerifications => 'Pending Verifications';

  @override
  String get elderActiveConflicts => 'Active Conflicts';

  @override
  String get elderTotalMembers => 'Total Members';

  @override
  String get elderActiveBranches => 'Active Branches';

  @override
  String get elderPendingMemberRequests => 'Pending Member Requests';

  @override
  String get elderReview => 'Review →';

  @override
  String elderVouches(int have, int required) {
    return 'Vouches: $have/$required';
  }

  @override
  String get elderTreeAlertsConflicts => 'Tree Alerts & Conflicts';

  @override
  String get elderAlertSample =>
      '\"Ananth Rao (1892-1954)\" appears in both Mysore and Bangalore branches with conflicting parentage.';

  @override
  String get elderResolveNow => 'Resolve Now →';

  @override
  String get elderMemberDirectory => 'Member Directory';

  @override
  String get elderDigitalArchive => 'Digital Archive';

  @override
  String get elderManageEvents => 'Manage Events';

  @override
  String get elderVerifications => 'Verifications';

  @override
  String get elderManagement => 'Management';

  @override
  String get elderLineageWisdom => 'LINEAGE WISDOM';

  @override
  String get elderLineageQuote =>
      '\"A tree without roots is just wood; a community without history is just a crowd.\"';

  @override
  String get elderMemberRequests => 'Member Requests';

  @override
  String get elderRiskLevel => 'RISK LEVEL';

  @override
  String get elderAadhaarStatus => 'AADHAAR STATUS';

  @override
  String get elderAll => 'All';

  @override
  String elderPendingClaims(int n) {
    return 'Pending Claims ($n)';
  }

  @override
  String get elderMale => 'Male';

  @override
  String get elderFemale => 'Female';

  @override
  String elderAgeGenderGotra(String age, String gender, String gotra) {
    return 'Age: $age · $gender · $gotra Gotra';
  }

  @override
  String get elderLineageNode => 'Lineage Node';

  @override
  String get elderRelation => 'Relation';

  @override
  String get elderVouchesLabel => 'Vouches';

  @override
  String elderVouchesOfRequired(int have, int required) {
    return '$have / $required';
  }

  @override
  String elderAadhaarPrefix(String status) {
    return 'Aadhaar: $status';
  }

  @override
  String elderSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get elderNoRequestsMatchFilter => 'No requests match your filter';

  @override
  String get elderMediumRisk => 'Medium Risk';

  @override
  String get elderVerificationDetail => 'Verification Detail';

  @override
  String get elderVerificationNotFound => 'Verification request not found';

  @override
  String get elderBackToQueue => 'Back to Queue';

  @override
  String get elderLineageClaim => 'Lineage Claim';

  @override
  String get elderClaimingFrom => 'Claiming From';

  @override
  String get elderClaimingAncestor => 'Claiming Ancestor';

  @override
  String get elderStatedRelation => 'Stated Relation';

  @override
  String get elderSubmittedOnLabel => 'Submitted On';

  @override
  String get elderIdentity => 'Identity';

  @override
  String get elderAadhaarStatusLabel => 'Aadhaar Status';

  @override
  String elderPhoneColon(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get elderSubmittedDocuments => 'SUBMITTED DOCUMENTS';

  @override
  String get elderReceived => 'Received';

  @override
  String elderPeerVouchesConfirmed(int have, int required) {
    return 'Peer Vouches ($have/$required confirmed)';
  }

  @override
  String elderYrsGenderGotra(String age, String gender, String gotra) {
    return '$age yrs · $gender · $gotra Gotra';
  }

  @override
  String get elderOccupation => 'Occupation';

  @override
  String get elderLocation => 'Location';

  @override
  String get elderPhoneMasked => 'Phone (masked)';

  @override
  String elderRiskAssessment(String level) {
    return 'Risk Assessment: $level';
  }

  @override
  String get elderCommitteeNotes => 'Elder Committee Notes';

  @override
  String get elderApprove => 'Approve';

  @override
  String get elderRequestMoreInfo => 'Request More Info';

  @override
  String get elderReject => 'Reject';

  @override
  String get elderVerificationApproved => 'Verification Approved';

  @override
  String elderVerificationApprovedBody(String name) {
    return '$name will be officially added to the Samaj registry. A notification will be sent to the applicant.';
  }

  @override
  String get elderInfoRequested => 'Information Requested';

  @override
  String elderInfoRequestedBody(String name) {
    return 'A query has been sent to $name requesting additional documents or clarification. Case paused pending response.';
  }

  @override
  String get elderRequestRejected => 'Request Rejected';

  @override
  String elderRequestRejectedBody(String name) {
    return 'The verification request for $name has been rejected. The applicant will be notified with a reason.';
  }

  @override
  String get elderCommunity => 'Community';

  @override
  String get elderSearchByNameGotraOcc => 'Search by name, gotra, occupation…';

  @override
  String get elderVerifiedMembersOnly => 'Verified members only';

  @override
  String elderShownCount(int n) {
    return '$n shown';
  }

  @override
  String get elderRegistryKicker => 'DAIVAJNA SAMAJA BANGALORE';

  @override
  String get elderCommunityMemberRegistry => 'Community Member Registry';

  @override
  String elderShowingOfTotal(int shown) {
    return 'Showing $shown of 1,428 registered members';
  }

  @override
  String get elderStatTotal => 'Total';

  @override
  String get elderStatVerified => 'Verified';

  @override
  String get elderStatPending => 'Pending';

  @override
  String get elderStatBranches => 'Branches';

  @override
  String get elderUnverified => 'Unverified';

  @override
  String elderYrsGender(String age, String gender) {
    return '$age yrs · $gender';
  }

  @override
  String elderBranchSuffix(String branch) {
    return '$branch Branch';
  }

  @override
  String elderGotraSuffix(String gotra) {
    return '$gotra Gotra';
  }

  @override
  String elderSinceYear(String year) {
    return 'Since $year';
  }

  @override
  String get elderViewProfile => 'View profile';

  @override
  String get elderPromoteToElder => 'Promote to Elder';

  @override
  String get elderSuspendMember => 'Suspend member';

  @override
  String get elderNoMembersMatchFilter => 'No members match your filter';

  @override
  String get elderArchives => 'Archives';

  @override
  String get elderHeritageMemoryArchive => 'Heritage Memory Archive';

  @override
  String get elderOurLivingHistory => 'Our Living History';

  @override
  String get elderLivingHistorySubtitle =>
      'Photographs, charters and oral histories of the Daivajna Samaja';

  @override
  String get elderUploadMemory => 'Upload a Memory';

  @override
  String get elderUploadMemoryToast =>
      'Memory upload - opening contributor form';

  @override
  String elderContributedBy(String name) {
    return 'Contributed by $name';
  }

  @override
  String get elderClose => 'Close';

  @override
  String get elderTagCultural => 'Cultural';

  @override
  String get elderTagHeritage => 'Heritage';

  @override
  String get elderTagLineage => 'Lineage';

  @override
  String get elderTagDevotional => 'Devotional';

  @override
  String get elderMem1Title => '1968 Samaj Utsava in Kumta';

  @override
  String get elderMem1Caption =>
      'The first inter-village Samaja Utsava bringing together goldsmith families from Kumta, Kundapura and Honnavar.';

  @override
  String get elderMem1Contributor => 'Venkatesh Haldankar';

  @override
  String get elderMem2Title => 'First Samaj Bhavan, 1974';

  @override
  String get elderMem2Caption =>
      'Inauguration of the community-built Samaja Bhavan in Basavanagudi - funded entirely by member contributions.';

  @override
  String get elderMem2Contributor => 'Shri Narayanarao Suvarna';

  @override
  String get elderMem3Title => 'Goldsmith Guild Charter, 1952';

  @override
  String get elderMem3Caption =>
      'The founding charter of the Daivajna goldsmith guild, signed by 28 master craftsmen of the coastal districts.';

  @override
  String get elderMem3Contributor => 'Samaj Archives Committee';

  @override
  String get elderMem4Title => 'Annual Utsava 1992';

  @override
  String get elderMem4Caption =>
      'Carnatic recitals and the elder felicitation that drew over 600 members across three generations.';

  @override
  String get elderMem4Contributor => 'Rekha Diwakar';

  @override
  String get elderMem5Title => 'Elder Felicitation 2008';

  @override
  String get elderMem5Caption =>
      'Honouring the senior-most members of each branch with shawls and the traditional gold medallion.';

  @override
  String get elderMem5Contributor => 'Lakshmi Revankar';

  @override
  String get elderMem6Title => 'Temple Kumbhabhisheka 1981';

  @override
  String get elderMem6Caption =>
      'The consecration of the community temple after its renovation, with priests from Kundapura and Udupi.';

  @override
  String get elderMem6Contributor => 'Parvati Shirodkar';

  @override
  String get elderSettings => 'Settings';

  @override
  String get elderManageEventsEyebrow => 'Manage Events';

  @override
  String get elderCommunityEvents => 'Community Events';

  @override
  String get elderEventsSubtitle =>
      'Daivajna Samaja events across all branches';

  @override
  String get elderAddEvent => 'Add Event';

  @override
  String get elderAddEventToast => 'New event - opening event form';

  @override
  String elderAttendeesExpected(int n) {
    return '$n attendees expected';
  }

  @override
  String get elderRsvp => 'RSVP';

  @override
  String get elderManage => 'Manage';

  @override
  String elderRsvpConfirmed(String title) {
    return 'RSVP confirmed · $title';
  }

  @override
  String elderManaging(String title) {
    return 'Managing · $title';
  }

  @override
  String get elderCommitteePreferences => 'Committee Preferences';

  @override
  String get elderCommitteePreferencesSubtitle =>
      'Notification & registry settings for the elder committee';

  @override
  String get elderEventReminders => 'Event reminders';

  @override
  String get elderEventRemindersSubtitle =>
      'Notify all branch heads 7 days before each event';

  @override
  String get elderEventRemindersOn => 'Event reminders on';

  @override
  String get elderEventRemindersOff => 'Event reminders off';

  @override
  String get elderAutoApproveRsvps => 'Auto-approve RSVPs';

  @override
  String get elderAutoApproveRsvpsSubtitle =>
      'Verified members are confirmed without review';

  @override
  String get elderAutoApproveOn => 'Auto-approve on';

  @override
  String get elderAutoApproveOff => 'Auto-approve off';

  @override
  String get elderPublishToPublicCalendar => 'Publish to public calendar';

  @override
  String get elderPublishToPublicCalendarSubtitle =>
      'Show upcoming Samaja events on the portal landing page';

  @override
  String get elderPublicCalendarOn => 'Public calendar on';

  @override
  String get elderPublicCalendarOff => 'Public calendar off';

  @override
  String get elderTypeCultural => 'Cultural';

  @override
  String get elderTypeAdmin => 'Admin';

  @override
  String get elderTypeEducation => 'Education';

  @override
  String get elderTypeCommunity => 'Community';

  @override
  String get elderStatusUpcoming => 'Upcoming';

  @override
  String get elderStatusPlanning => 'Planning';

  @override
  String get elderEvent1Title => 'Annual Samaja Utsava 2025';

  @override
  String get elderEvent1Venue => 'Samaja Bhavan, Basavanagudi, Bengaluru';

  @override
  String get elderEvent2Title => 'Elder Committee Meeting - Q3';

  @override
  String get elderEvent2Venue => 'Committee Room, Samaj Bhavan';

  @override
  String get elderEvent3Title => 'Vidya Nidhi Scholarship Day';

  @override
  String get elderEvent3Venue => 'SDM College Auditorium, Mangaluru';

  @override
  String get elderEvent4Title => 'Daivajna Matrimonial Meet';

  @override
  String get elderEvent4Venue => 'VR Mall Convention, Bengaluru';

  @override
  String get elderConflictResolution => 'Conflict Resolution';

  @override
  String get elderConflictNotFound => 'Conflict case not found';

  @override
  String get elderBackToOverview => 'Back to Overview';

  @override
  String elderCaseId(String id) {
    return 'Case #$id';
  }

  @override
  String elderBornDied(String born, String died) {
    return '$born - $died';
  }

  @override
  String get elderResolution => 'Resolution';

  @override
  String get elderMergeResolve => 'Merge & Resolve';

  @override
  String get elderMergeSubmitted => 'Records submitted for merge review';

  @override
  String get elderEscalate => 'Escalate';

  @override
  String get elderEscalated => 'Case escalated to the elder committee';

  @override
  String get elderOnlyEldersResolve =>
      'Only verified Elders can resolve conflicts';

  @override
  String get elderDiscussionThread => 'Elder Discussion Thread';

  @override
  String get elderAddCommitteeNote => 'Add your committee note…';

  @override
  String get elderNotePosted => 'Note posted to the thread';

  @override
  String elderBackedByRecords(int n) {
    return 'Backed by records · $n vouches';
  }

  @override
  String get elderEvidence => 'EVIDENCE';

  @override
  String get elderSubmittedThisVersion => 'Submitted this version';

  @override
  String elderSupportThisVersion(int n) {
    return 'Support this version ($n)';
  }

  @override
  String elderYouSupported(String label) {
    return 'You supported $label';
  }

  @override
  String get compConsentTitle => 'Compatibility Consent';

  @override
  String get compConsentLoadError => 'Could not load your consent settings';

  @override
  String get compBirthDataMatching => 'Birth-Data Matching';

  @override
  String get compBirthDataMatchingDesc =>
      'Use your birth date, time and place to calculate traditional Jataka (10 Porutham) compatibility with another member.';

  @override
  String get compCouldNotSaveRetry => 'Couldn\'t save that. Try again.';

  @override
  String get compPolicyUpdatedNote =>
      'Our consent policy was updated since you last agreed - switch this back on to confirm again.';

  @override
  String get compAllowed => 'Allowed';

  @override
  String get compNotAllowed => 'Not allowed';

  @override
  String compGrantedOn(String date) {
    return 'Granted $date';
  }

  @override
  String get compReportTitle => 'Compatibility Report';

  @override
  String get compReportLoadError => 'Could not load the compatibility report';

  @override
  String get compTryAgain => 'Try again';

  @override
  String get compYou => 'You';

  @override
  String get compThisMember => 'This member';

  @override
  String get compErrorGenericMissingRoleMine =>
      'Add your gender in Profile → Edit first - it decides your traditional bride/groom role.';

  @override
  String get compErrorGenericMissingRoleTheirs =>
      'This member\'s profile doesn\'t have a gender on file, so their traditional role can\'t be determined.';

  @override
  String get compErrorCalcFailed =>
      'Could not calculate compatibility right now.';

  @override
  String get compRecalculate => 'Recalculate';

  @override
  String get compRetry => 'Retry';

  @override
  String get compCalculateCompatibility => 'Calculate Compatibility';

  @override
  String get compYourConsentBirthData => 'Your consent · Birth-data matching';

  @override
  String get compAllowedRequiredForCalc =>
      'Allowed - required for this calculation.';

  @override
  String get compPolicyChangedReconfirm =>
      'Our consent policy changed - please re-confirm.';

  @override
  String get compNotAllowedYet =>
      'Not allowed yet - required before calculating.';

  @override
  String get compManage => 'Manage';

  @override
  String get compReview => 'Review';

  @override
  String get compTraditionalRoleUnknown => 'Traditional role unknown';

  @override
  String get compGoToProfile => 'Go to Profile';

  @override
  String get compYourBirthDetailsIncomplete =>
      'Your birth details are incomplete';

  @override
  String get compTheirBirthDetailsIncomplete =>
      'Their birth details are incomplete';

  @override
  String get compAddBirthDetailsBody =>
      'Add your exact birth time and place to calculate the Jataka match.';

  @override
  String get compTheirBirthDetailsBody =>
      'This member hasn\'t finished their birth details yet - check back later.';

  @override
  String get compAddBirthDetailsAction => 'Add birth details';

  @override
  String get compYourConsentNeeded => 'Your consent is needed';

  @override
  String get compTheirConsentNeeded => 'Their consent is needed';

  @override
  String get compYourConsentNeededBody =>
      'You haven\'t allowed birth-data matching yet - review and grant it to run this check.';

  @override
  String get compTheirConsentNeededBody =>
      'This member hasn\'t allowed birth-data matching yet.';

  @override
  String get compReviewConsent => 'Review consent';

  @override
  String get compSomethingWentWrong => 'Something went wrong';

  @override
  String get compCheckReadinessError =>
      'Could not check compatibility readiness';

  @override
  String get compCheckCompatibilityTitle => 'Check Compatibility';

  @override
  String compYouAnd(String name) {
    return 'You × $name';
  }

  @override
  String get compSeeJatakaProfile =>
      'See your Jataka and profile compatibility.';

  @override
  String get compProfileCompatibility => 'Profile Compatibility';

  @override
  String get compSouthIndianJataka => 'South Indian Jataka';

  @override
  String get compChecking => 'Checking Compatibility...';

  @override
  String get compCompleteHighlighted =>
      'Complete the highlighted sections above to check compatibility.';

  @override
  String get compCantCheckYet =>
      'Compatibility can\'t be checked with this profile yet.';

  @override
  String get compVerificationRequired => 'Verification required.';

  @override
  String get compDataNotAvailableYet =>
      'Compatibility data is not available for this section yet.';

  @override
  String get compReady => 'Ready';

  @override
  String get compMoreInfoNeeded => 'More information needed';

  @override
  String get compNotAvailableYet => 'Not available yet';

  @override
  String get compCheckingEllipsis => 'Checking compatibility...';

  @override
  String get compBirthDetailsRequired => 'Birth details required.';

  @override
  String get compAddBirthDetailsBtn => 'Add Birth Details';

  @override
  String get compPermissionRequired => 'Compatibility permission required.';

  @override
  String get compManageConsent => 'Manage Consent';

  @override
  String get compCompleteAFewQuestions =>
      'Complete a few compatibility questions.';

  @override
  String get compCompleteQuestions => 'Complete Questions';

  @override
  String get compFamilyTreeIncompleteBody =>
      'Add a few more family relationships to enable this.';

  @override
  String get compUpdateFamilyTree => 'Update Family Tree';

  @override
  String get compDashboardLoadError =>
      'Could not load the compatibility dashboard';

  @override
  String get compMarriageCompatibility => 'Marriage Compatibility';

  @override
  String compPdfSaved(String name) {
    return 'PDF saved: $name';
  }

  @override
  String get compDownloadNotifTitle => 'Download complete';

  @override
  String compDownloadNotifBody(String name) {
    return '$name is ready - tap to open';
  }

  @override
  String get compPdfGenerateError =>
      'Could not generate the PDF. Please try again.';

  @override
  String get compPdfShareError => 'Could not share the PDF. Please try again.';

  @override
  String compShareSubject(String myName, String otherName) {
    return 'Marriage Compatibility Report - $myName × $otherName';
  }

  @override
  String get compRetryAction => 'Retry';

  @override
  String get compOverallCompatibility => 'OVERALL COMPATIBILITY';

  @override
  String get compAstrologyCompatibility => 'Astrology Compatibility';

  @override
  String get compNotEnoughProfileInfo => 'Not enough profile information';

  @override
  String get compNotEnoughAstrologyInfo => 'Not enough astrology information';

  @override
  String get compAstrologySummary => 'ASTROLOGY SUMMARY';

  @override
  String get compKarnatakaPorutham => 'Karnataka 10 Porutham';

  @override
  String get compAshtakootaGuna => 'Ashtakoota 36 Guna';

  @override
  String get compUnavailable => 'Unavailable';

  @override
  String get compViewDetailedReport => 'View Detailed Report';

  @override
  String get compGenerating => 'Generating…';

  @override
  String get compDownloadPdf => 'Download PDF';

  @override
  String get compShareReport => 'Share Report';

  @override
  String get compCalculated => 'Calculated';

  @override
  String get compReviewRequired => 'Review required';

  @override
  String get compNotAvailable => 'Not available';

  @override
  String get discSortBestMatch => 'Best Match';

  @override
  String get discSortNewest => 'Newest';

  @override
  String get discSortAgeLowHigh => 'Age: Low to High';

  @override
  String get discSortAgeHighLow => 'Age: High to Low';

  @override
  String get discTitle => 'Discover Matches';

  @override
  String get discCouldNotLoad => 'Could not load matches';

  @override
  String get discCouldNotLoadMore => 'Could not load more matches';

  @override
  String get discMatch => ' match';

  @override
  String get discMatches => ' matches';

  @override
  String discFilterCount(int n) {
    return 'Filter ($n)';
  }

  @override
  String get discFilter => 'Filter';

  @override
  String discSortLabel(String label) {
    return 'Sort: $label';
  }

  @override
  String get discLoadMore => 'Load more';

  @override
  String get discNoMatchesYet => 'No matches to show yet';

  @override
  String get discCompletePreferences =>
      'Complete your marriage preferences and interests for better matches.';

  @override
  String get discNoMatchesForFilters => 'No matches found for these filters.';

  @override
  String get discClearFilters => 'Clear Filters';

  @override
  String get discIntroBody =>
      'Ranked by how well each profile fits your marriage preferences, food, interests, location and age - highest match first.';

  @override
  String get discMatchLabel => 'Match';

  @override
  String get discViewProfile => 'View Profile';

  @override
  String get purohitTitle => 'Purohit';

  @override
  String get purohitCouldNotLoad => 'Could not load purohits.';

  @override
  String get purohitCouldNotLoadTitle => 'Couldn\'t load purohits';

  @override
  String get purohitNoneYet => 'No purohits yet';

  @override
  String get purohitNoneYetBody =>
      'Members who mark themselves as a purohit at registration will appear here.';

  @override
  String purohitKmAway(String km) {
    return '$km km away';
  }

  @override
  String get jatakaTitle => 'South Indian Jataka';

  @override
  String get jatakaLoadError =>
      'Could not load the South Indian Jataka result right now.';

  @override
  String get jatakaReviewRequired => 'Review required';

  @override
  String get jatakaReviewRequiredBody =>
      'Some calculations require review because of birth-time uncertainty.';

  @override
  String get jatakaNotCalculableTitle => 'Not calculable yet';

  @override
  String get jatakaNotCalculableBody =>
      'South Indian Jataka compatibility could not be calculated. This is usually because birth details are missing, required consent isn\'t in place, or the astrology rules haven\'t been published yet.';

  @override
  String get jatakaNoKarnatakaTitle => 'No Karnataka Porutham result';

  @override
  String get jatakaNoKarnatakaBody =>
      'This report does not include a South Indian Jataka result.';

  @override
  String get jatakaSectionLabel => 'SOUTH INDIAN JATAKA';

  @override
  String get jatakaKarnataka10Porutham => 'Karnataka 10 Porutham';

  @override
  String jatakaMatchedOf(String matched, String total) {
    return '$matched/$total matched';
  }

  @override
  String jatakaRuleVersion(String version) {
    return 'Rule version: $version';
  }

  @override
  String get jatakaChipMatched => 'Matched';

  @override
  String get jatakaChipPartial => 'Partial';

  @override
  String get jatakaChipNotMatched => 'Not matched';

  @override
  String get jatakaChipReview => 'Review';

  @override
  String get jatakaChipUnavailable => 'Unavailable';

  @override
  String get jatakaCriticalChecks => 'Critical checks';

  @override
  String get jatakaRajju => 'Rajju';

  @override
  String get jatakaVedha => 'Vedha';

  @override
  String get jatakaStatusMatched => 'Matched';

  @override
  String get jatakaStatusPartial => 'Partial';

  @override
  String get jatakaStatusNotMatched => 'Not matched';

  @override
  String get jatakaStatusReviewRequired => 'Review required';

  @override
  String get jatakaStatusUnavailable => 'Unavailable';

  @override
  String get jatakaStatusUnknown => 'Unknown';

  @override
  String get jatakaThe10Poruthams => 'The 10 Poruthams';

  @override
  String get jatakaAshtakootaLabel => 'ASHTAKOOTA / 36 GUNA';

  @override
  String get jatakaAshtakootaUnavailable =>
      'Ashtakoota calculation is currently unavailable.';

  @override
  String get jatakaOverallScore => 'Overall astrology score';

  @override
  String get birthTitle => 'Birth Details';

  @override
  String get birthCouldNotLoad => 'Could not load your birth details';

  @override
  String get birthCouldNotSave => 'Could not save your birth details';

  @override
  String get birthDisclaimer =>
      'Used only for the South Indian Jataka and horoscope compatibility check - never shown on your public profile.';

  @override
  String get birthFromProfile => 'FROM YOUR PROFILE';

  @override
  String get birthDateOfBirth => 'Date of birth';

  @override
  String get birthNotSet => 'Not set';

  @override
  String get birthTraditionalRole => 'Traditional role';

  @override
  String get birthSetGender => 'Set your gender in Profile → Edit';

  @override
  String get birthBirthplace => 'BIRTHPLACE';

  @override
  String get birthCityLabel => 'Birth city';

  @override
  String get birthCityHint => 'e.g. Mysuru, Karnataka, India';

  @override
  String get birthTimeOfBirth => 'TIME OF BIRTH';

  @override
  String get birthTimePickerHelp => 'Time of birth';

  @override
  String get birthDerivedAutomatically => 'Derived automatically';

  @override
  String birthLatLon(String lat, String lon, String tz) {
    return 'Lat/Lon: $lat, $lon\nTimezone: $tz';
  }

  @override
  String get birthTimeAccuracy => 'Birth-time accuracy';

  @override
  String get birthSelectAccuracy => 'Select accuracy';

  @override
  String get birthSaving => 'Saving…';

  @override
  String get birthSaveButton => 'Save birth details';

  @override
  String get birthSaved => 'Birth details saved';

  @override
  String get birthAddDob => 'Add your date of birth in Profile → Edit first.';

  @override
  String get birthAddGender =>
      'Add your gender in Profile → Edit first - it decides your traditional bride/groom role.';

  @override
  String get birthSearchPlace =>
      'Search for your birthplace and pick it from the suggestions.';

  @override
  String get birthInvalidLatitude =>
      'That birthplace has an invalid latitude - try searching again.';

  @override
  String get birthInvalidLongitude =>
      'That birthplace has an invalid longitude - try searching again.';

  @override
  String get birthNoTimezone =>
      'Could not determine a timezone for that place - try a more specific search, including the country.';

  @override
  String get birthChooseAccuracy =>
      'Choose how confident you are about the time of birth.';

  @override
  String get birthAddTimeOrUnknown =>
      'Add the time of birth, or set the accuracy to \"Unknown\" if it\'s genuinely not known.';

  @override
  String get birthAccuracyExactDocument =>
      'Exact - verified by a document (e.g. birth certificate)';

  @override
  String get birthAccuracyExactFamily => 'Exact - confirmed by family';

  @override
  String get birthAccuracyApprox15 => 'Approximate - within 15 minutes';

  @override
  String get birthAccuracyApprox30 => 'Approximate - within 30 minutes';

  @override
  String get birthAccuracyApprox60 => 'Approximate - within 60 minutes';

  @override
  String get birthAccuracyUnknown => 'Unknown';

  @override
  String get cameraNoneAvailable => 'No camera available on this device.';

  @override
  String cameraUnavailable(String error) {
    return 'Camera unavailable: $error';
  }

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required. Enable it in Settings.';

  @override
  String cameraCouldNotStart(String error) {
    return 'Could not start the camera: $error';
  }

  @override
  String get cameraCouldNotTakePhoto => 'Could not take the photo.';

  @override
  String get cameraCouldNotStartRecording => 'Could not start recording.';

  @override
  String get cameraCouldNotSaveRecording => 'Could not save the recording.';

  @override
  String get cameraReleaseToStop => 'Release to stop';

  @override
  String get cameraTapOrHold => 'Tap for photo  ·  Hold to record';

  @override
  String get digilockerVerifyTitle => 'Verify with DigiLocker';

  @override
  String postCouldNotPickMedia(String error) {
    return 'Could not pick media: $error';
  }

  @override
  String get postAuthorFallback => 'You';

  @override
  String get postReelShared => 'Reel shared 🎬';

  @override
  String get postShared => 'Post shared ✨';

  @override
  String postUploadFailed(String reason) {
    return 'Upload failed: $reason';
  }

  @override
  String get postCheckConnection => 'check your connection';

  @override
  String get postNewReel => 'New Reel';

  @override
  String get postNewPost => 'New Post';

  @override
  String get postCaptionHint => 'Write a caption…';

  @override
  String get postDefaultReelCaption => 'New reel';

  @override
  String get postDefaultPostCaption => 'New post';

  @override
  String get postLocating => 'Locating…';

  @override
  String get postCurrentLocation => 'Current location';

  @override
  String get postCouldNotGetLocation => 'Could not get your location.';

  @override
  String get postRemoveLocation => 'Remove location';

  @override
  String get postShareButton => 'Share';

  @override
  String get storyVisFamilyFollowers => 'Family & Followers';

  @override
  String get storyVisOnlyMe => 'Only me';

  @override
  String get storyVisCommunity => 'Vamsha Community';

  @override
  String get storyTagFamilyMembers => 'Tag Family Members';

  @override
  String get storyLinkAncestor => 'Link to an Ancestor';

  @override
  String get storyWhoCanSee => 'Who can see this story?';

  @override
  String get storyVisCommunityDesc => 'Everyone in the Samaj';

  @override
  String get storyVisFollowersDesc => 'People connected to you';

  @override
  String get storyVisPrivateDesc => 'Private - nobody else can see it';

  @override
  String get storyShared => 'Story shared - live for 24 hours ✨';

  @override
  String storyCouldNotPost(String reason) {
    return 'Couldn\'t post: $reason';
  }

  @override
  String get storyPleaseTryAgain => 'please try again';

  @override
  String storyComingSoon(String label) {
    return '$label - coming soon';
  }

  @override
  String get storyShareTitle => 'Share Story';

  @override
  String get storyHelp => 'HELP';

  @override
  String get storyReviewRecording => 'Review your recording';

  @override
  String get storyReviewPhoto => 'Review your photo';

  @override
  String get storyCaption => 'Caption';

  @override
  String get storyCaptionHint => 'Write a caption about this family memory…';

  @override
  String get storySearchVamshaVruksha => 'Search your Vamsha Vruksha';

  @override
  String get storyAddLocation => 'Add Location';

  @override
  String get storyLocationSubtitle => 'Villages, temples, or community centers';

  @override
  String get storyLinkToTreeNode => 'Link to Tree Node';

  @override
  String get storyAttachAncestor => 'Attach this story to an ancestor';

  @override
  String storyLinkedTo(String name) {
    return 'Linked to $name';
  }

  @override
  String get storyAdvancedSettings => 'ADVANCED SETTINGS';

  @override
  String get storyVisibleTo => 'Visible to';

  @override
  String get storyPostToCommunity => 'Post to Community';

  @override
  String get storyDrafts => 'Drafts';

  @override
  String get storyLocationHint => 'e.g. Kumta, Mahalasa Temple…';

  @override
  String get storyKindVillage => 'Village';

  @override
  String get storyKindTemple => 'Temple';

  @override
  String get storyKindCommunityCenter => 'Community Center';

  @override
  String get storyKindOther => 'Other';

  @override
  String storyAgoMinutesCompact(int n) {
    return '${n}m';
  }

  @override
  String storyAgoHoursCompact(int n) {
    return '${n}h';
  }

  @override
  String storyAgoDaysCompact(int n) {
    return '${n}d';
  }

  @override
  String get storyDeleteTitle => 'Delete story?';

  @override
  String get storyDeleteBody => 'This removes it for everyone.';

  @override
  String get storyDeleteAction => 'Delete';

  @override
  String get storyNoViewsYet => 'No views yet';

  @override
  String storySeenByCount(int n) {
    return 'Seen by $n';
  }

  @override
  String get storyViewers => 'Viewers';

  @override
  String storyViewersCount(int n) {
    return 'Viewers · $n';
  }

  @override
  String get storyNoOneViewedYet => 'No one has viewed this story yet.';

  @override
  String get storyMemberFallback => 'Member';

  @override
  String get chatMessageNotSent => 'Message not sent';

  @override
  String get chatPhotosVideos => 'Photos/Videos';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatDocuments => 'Documents';

  @override
  String get chatCouldNotSendFile => 'Could not send file';

  @override
  String get chatSayHello => 'Say hello 👋';

  @override
  String get chatMessageHint => 'Message…';

  @override
  String get chatNoAppForFile => 'No app could open this file';

  @override
  String get chatDocumentFallback => 'Document';

  @override
  String get convMemberFallback => 'Member';

  @override
  String get convMessages => 'Messages';

  @override
  String get convNoMessagesYet => 'No messages yet';

  @override
  String get convStartChatHint =>
      'Message a member from the directory to start a chat.';

  @override
  String get convVideoLabel => '🎥 Video';

  @override
  String get convDocumentLabel => '📄 Document';

  @override
  String get convPhotoLabel => '📷 Photo';

  @override
  String get convTapToChat => 'Tap to chat';

  @override
  String commentCouldNotPost(String reason) {
    return 'Could not post comment: $reason';
  }

  @override
  String get commentCheckConnection => 'check your connection';

  @override
  String get commentTitle => 'Comments';

  @override
  String get commentNoneYet => 'No comments yet';

  @override
  String get commentStartConversation => 'Start the conversation.';

  @override
  String get commentHint => 'Add a comment…  (type @ to tag)';

  @override
  String get commentPosting => 'Posting…';

  @override
  String get commentPost => 'Post';

  @override
  String commentLikeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n likes',
      one: '$n like',
    );
    return '$_temp0';
  }

  @override
  String commentCouldNotLike(String reason) {
    return 'Could not like: $reason';
  }

  @override
  String get shareReel => 'reel';

  @override
  String get sharePost => 'post';

  @override
  String get shareTitle => 'Share';

  @override
  String get shareSendTo => 'Send to';

  @override
  String get shareLinkCopied => 'Link copied to clipboard';

  @override
  String shareSentToMembers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sent to $n members 📩',
      one: 'Sent to $n member 📩',
    );
    return '$_temp0';
  }

  @override
  String get shareSendButton => 'Send';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareAddToStory => 'Add to story';

  @override
  String get shareAddedToStory => 'Added to your story';

  @override
  String get shareViaEllipsis => 'Share via…';

  @override
  String shareTextTemplate(
    String author,
    String kind,
    String caption,
    String link,
  ) {
    return '$author shared a $kind on Samaj\n\"$caption\"\n\n$link';
  }

  @override
  String shareSubjectTemplate(String kind) {
    return 'A $kind from the Samaj';
  }

  @override
  String get landOrgName => 'Daivajna Samaja';

  @override
  String get landEyebrow => 'Daivajna Samaja Bangalore - Est. 2024';

  @override
  String get landHeadline => 'Preserving our Roots,\nNurturing our Future';

  @override
  String get landSubtitle =>
      'The official digital sanctuary for the Daivajna Samaja - connecting generations, preserving heritage, and building community welfare through a living family tree.';

  @override
  String get landBeginJourney => 'Begin Your Journey';

  @override
  String get landAccessPortal => 'Access Portal';

  @override
  String get landFamilyLineagePreview => 'FAMILY LINEAGE PREVIEW';

  @override
  String get landGenerationsTag => '4 Generations';

  @override
  String get landMembersTag => '6 Members';

  @override
  String get landUdupiBranch => 'Udupi Branch';

  @override
  String get landPillarFamilyTreeTitle => 'Family Tree';

  @override
  String get landPillarFamilyTreeDesc =>
      'Document your family lineage across generations. Interactive tree visualization with photo archives, life stories, and ancestral connections.';

  @override
  String get landPillarWelfareTitle => 'Community Welfare';

  @override
  String get landPillarWelfareDesc =>
      'Transparent crowdfunding for Samaj development. Every rupee accounted for - community center, scholarships, emergency support.';

  @override
  String get landPillarMatrimonialTitle => 'Matrimonial Hub';

  @override
  String get landPillarMatrimonialDesc =>
      'Elder-mediated matrimonial connections that honour lineage and cultural alignment. Verified profiles with complete family background.';

  @override
  String get landPillarElderTitle => 'Elder Governance';

  @override
  String get landPillarElderDesc =>
      'Community-driven decisions guided by our respected elders. Resolve conflicts, verify members, and govern with generational wisdom.';

  @override
  String get landExplore => 'Explore';

  @override
  String get landTrustEyebrow => 'A circle of absolute trust';

  @override
  String get landTrustTitle => 'Every member, every connection - verified.';

  @override
  String get landTrustAadhaarTitle => 'Aadhaar Verification';

  @override
  String get landTrustAadhaarDesc =>
      'Every member submits a government-issued ID. Aadhaar-matched and digitally registered.';

  @override
  String get landTrustPeerTitle => 'Peer Vouching';

  @override
  String get landTrustPeerDesc =>
      'New members are vouched by 3 existing verified family members within the Samaj network.';

  @override
  String get landTrustElderTitle => 'Elder Approval';

  @override
  String get landTrustElderDesc =>
      'Elder sub-committee reviews and approves all lineage connections and matrimonial requests.';

  @override
  String get landQuote =>
      '\"A tree is only as strong as its roots. Verification ensures the legacy you build is authentic and lasting.\"';

  @override
  String get landQuoteAuthor => '- Samaj Heritage Council';

  @override
  String get landFooterTagline => 'Daivajna Samaja Community Portal';

  @override
  String get landFooterPrivacy => 'Privacy Policy';

  @override
  String get landFooterTerms => 'Terms of Service';

  @override
  String get landFooterHeritage => 'Heritage Guidelines';

  @override
  String get landFooterContact => 'Contact Admin';

  @override
  String get landFooterGovernance => 'Community Governance';

  @override
  String get landFooterCopyright =>
      '© 2024 Daivajna Samaja - Preserving Legacies for Generations.';

  @override
  String get reelSavedToProfile => 'Saved to your profile';

  @override
  String get reelRemovedFromSaved => 'Removed from saved';

  @override
  String get matchLevelExcellent => 'Excellent Match';

  @override
  String get matchLevelHigh => 'High Match';

  @override
  String get matchLevelGood => 'Good Match';

  @override
  String get matchLevelModerate => 'Moderate Match';

  @override
  String get matchLevelLow => 'Low Match';

  @override
  String get matchBadgeMatch => 'Match';

  @override
  String get matchFactorMarriageIntention => 'Marriage Intention';

  @override
  String get matchFactorChildren => 'Children';

  @override
  String get matchFactorFamilyType => 'Family Type';

  @override
  String get matchFactorRelocation => 'Relocation';

  @override
  String get matchFactorFoodPreference => 'Food Preference';

  @override
  String get matchFactorInterests => 'Interests';

  @override
  String get matchFactorLocation => 'Location';

  @override
  String get matchFactorAge => 'Age';

  @override
  String matchFactorNotEnoughInfo(String label) {
    return '$label - not enough information to compare';
  }

  @override
  String matchFactorAligned(String label, int percentage) {
    return '$label - $percentage% aligned';
  }

  @override
  String get discFilterIntentionSoon => 'Soon';

  @override
  String get discFilterIntentionOneToTwoYears => '1-2 Years';

  @override
  String get discFilterIntentionNotDecided => 'Not Decided';

  @override
  String get discFilterFoodVegetarian => 'Vegetarian';

  @override
  String get discFilterFoodNonVegetarian => 'Non-Vegetarian';

  @override
  String get discFilterFoodEggetarian => 'Eggetarian';

  @override
  String get discFilterFoodOther => 'Other';

  @override
  String get discFilterInterestTravel => 'Travel';

  @override
  String get discFilterInterestMusic => 'Music';

  @override
  String get discFilterInterestMovies => 'Movies';

  @override
  String get discFilterInterestFitness => 'Fitness';

  @override
  String get discFilterInterestSports => 'Sports';

  @override
  String get discFilterInterestReading => 'Reading';

  @override
  String get discFilterInterestCooking => 'Cooking';

  @override
  String get discFilterInterestSpirituality => 'Spirituality';

  @override
  String get discFilterAny => 'Any';

  @override
  String get discFilterTitle => 'Filters';

  @override
  String get discFilterAgeSection => 'AGE';

  @override
  String get discFilterAgeFrom => 'Age From';

  @override
  String get discFilterAgeTo => 'Age To';

  @override
  String get discFilterLocationSection => 'LOCATION';

  @override
  String get discFilterLocationHint => 'Preferred location';

  @override
  String get discFilterMinMatchSection => 'MINIMUM MATCH';

  @override
  String get discFilterIntentionSection => 'MARRIAGE INTENTION';

  @override
  String get discFilterFoodSection => 'FOOD PREFERENCE';

  @override
  String get discFilterInterestsSection => 'INTERESTS';

  @override
  String get discFilterClearAll => 'Clear All';

  @override
  String get discFilterApply => 'Apply Filters';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonKeep => 'Keep';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageKannada => 'ಕನ್ನಡ';

  @override
  String get permIntroTitle => 'Before you begin';

  @override
  String get permIntroBody =>
      'A few permissions make the app work smoothly. You can change any of these later in your phone\'s Settings.';

  @override
  String get permMediaTitle => 'Photos & Videos';

  @override
  String get permMediaBody =>
      'To attach photos and videos to your posts, stories, and profile.';

  @override
  String get permNotificationTitle => 'Notifications';

  @override
  String get permNotificationBody =>
      'To let you know about family requests, messages, and community updates.';

  @override
  String get permLocationTitle => 'Location';

  @override
  String get permLocationBody =>
      'To tag a place on your posts and find nearby Samaj members.';

  @override
  String get permRequesting => 'Requesting…';

  @override
  String get permContinue => 'Continue';

  @override
  String get permSkip => 'Skip for now';
}
