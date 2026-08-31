// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'दैवज्ञ समाज';

  @override
  String get appTagline => 'बैंगलोर · धरोहर पोर्टल';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navFamilyTree => 'वंश वृक्ष';

  @override
  String get navInvitations => 'आमंत्रण';

  @override
  String get navDirectory => 'निर्देशिका';

  @override
  String get navMatrimonial => 'वैवाहिक';

  @override
  String get navWelfare => 'कल्याण';

  @override
  String get navPurohit => 'पुरोहित';

  @override
  String get navLineageTree => 'वंशावली वृक्ष';

  @override
  String get navMemberRequests => 'सदस्य अनुरोध';

  @override
  String get navArchives => 'अभिलेख';

  @override
  String get navCommunity => 'समुदाय';

  @override
  String get navModeration => 'मॉडरेशन';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get navHome => 'होम';

  @override
  String get navTree => 'वृक्ष';

  @override
  String get navRequests => 'अनुरोध';

  @override
  String get navMembers => 'सदस्य';

  @override
  String get navArchive => 'अभिलेख';

  @override
  String get navMore => 'और';

  @override
  String get navPost => 'पोस्ट';

  @override
  String get navMessages => 'संदेश';

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get loginTitle => 'पोर्टल में प्रवेश करें';

  @override
  String get loginSubtitle => 'अपने पंजीकृत मोबाइल नंबर से लॉगिन करें।';

  @override
  String get loginPhoneLabel => 'पंजीकृत मोबाइल नंबर';

  @override
  String get loginSendOtp => 'OTP भेजें';

  @override
  String loginOtpSentTo(String phone) {
    return '$phone पर OTP भेजा गया';
  }

  @override
  String get loginOtpHint =>
      '6 अंकों का OTP दर्ज करें  ·  डेमो के लिए 121212 का उपयोग करें';

  @override
  String get loginButton => 'लॉगिन करें';

  @override
  String get loginChangeNumber => '← नंबर बदलें';

  @override
  String get loginAboutCommunity => 'दैवज्ञ समाज के बारे में';

  @override
  String get loginNewMember => 'नए सदस्य हैं?  ';

  @override
  String get loginCreateAccount => 'खाता बनाएं';

  @override
  String get loginHeroHeadline => 'आपकी वंशावली।\nआपकी विरासत। एक पोर्टल।';

  @override
  String get loginHeroBody =>
      '1,428 परिवारों से जुड़ें, अपनी पैतृक जड़ों का पता लगाएं, और सामुदायिक कल्याण में योगदान दें।';

  @override
  String get loginErrorInvalidPhone => 'एक मान्य 10-अंकीय फ़ोन नंबर दर्ज करें';

  @override
  String get loginErrorInvalidOtp => '6 अंकों का OTP दर्ज करें';

  @override
  String get loginErrorNotRegistered =>
      'यह नंबर पंजीकृत नहीं है। कृपया पहले खाता बनाएं।';

  @override
  String loginErrorServerUnreachable(String baseUrl) {
    return '$baseUrl पर सर्वर तक नहीं पहुंचा जा सका। जांचें कि बैकएंड चल रहा है।';
  }

  @override
  String get loginErrorNetwork => 'नेटवर्क त्रुटि। कृपया पुनः प्रयास करें।';

  @override
  String get registerHeroHeadline => 'आज ही अपनी वंशावली यात्रा शुरू करें।';

  @override
  String get registerHeroBody =>
      '1,428 परिवारों से जुड़ें जिन्होंने अपनी विरासत का दस्तावेजीकरण किया है और अपनी पैतृक जड़ों से जुड़े हैं।';

  @override
  String get registerJoinTitle => 'समाज में शामिल हों';

  @override
  String get registerJoinSubtitle =>
      'अपना खाता बनाएं और अपनी वंशावली का दस्तावेजीकरण शुरू करें';

  @override
  String get registerOtpNotice =>
      'आपके मोबाइल पर SMS के माध्यम से एक OTP भेजा जाएगा';

  @override
  String get registerFullName => 'पूरा नाम';

  @override
  String get registerAsPerAadhar => '(आधार के अनुसार)';

  @override
  String get registerFullNameHint => 'उदा. अदिति शानभाग राव';

  @override
  String get registerMobileNumber => 'मोबाइल नंबर';

  @override
  String get registerGender => 'लिंग';

  @override
  String get registerMale => 'पुरुष';

  @override
  String get registerFemale => 'महिला';

  @override
  String get registerGotra => 'गोत्र';

  @override
  String get registerKuladevata => 'कुलदेवता';

  @override
  String get registerOptional => '(वैकल्पिक)';

  @override
  String get registerSelectKuladevata => 'अपना कुलदेवता चुनें';

  @override
  String get registerIsPurohit => 'क्या आप पुरोहित हैं?';

  @override
  String get registerYes => 'हाँ';

  @override
  String get registerNo => 'नहीं';

  @override
  String get registerNativePlace => 'मूल स्थान (वैकल्पिक)';

  @override
  String get registerNativePlaceHint => 'उदा. कुंदापुरा, उडुपी, कर्नाटक';

  @override
  String get registerDigilockerDetailsDesc =>
      'वैकल्पिक - अभी सत्यापित करें और आपकी प्रोफ़ाइल पहले दिन से ही ✓ बैज प्राप्त करेगी। हम कभी भी आपका आधार नंबर नहीं मांगते या संग्रहीत नहीं करते, केवल DigiLocker द्वारा लौटाया गया छिपा हुआ संदर्भ।';

  @override
  String get registerContinue => 'जारी रखें';

  @override
  String get registerAlreadyMember => 'पहले से सदस्य हैं?  ';

  @override
  String get registerSignIn => 'साइन इन करें';

  @override
  String get registerBackToSignIn => '← साइन इन पर वापस जाएं';

  @override
  String get registerVerifyNumber => 'अपना नंबर सत्यापित करें';

  @override
  String get registerOtpSentToPrefix => 'OTP भेजा गया ';

  @override
  String registerOtpSentToPhone(String phone) {
    return '+91 $phone';
  }

  @override
  String get registerOtpHint =>
      '6 अंकों का OTP दर्ज करें  ·  डेमो के लिए 121212 का उपयोग करें';

  @override
  String get registerCreateAccountContinue => 'खाता बनाएं और जारी रखें';

  @override
  String get registerBack => '← वापस';

  @override
  String get registerAccountCreated => 'खाता बन गया';

  @override
  String get registerAllSet => 'सब कुछ तैयार है';

  @override
  String get registerVerifyIdentity => 'अपनी पहचान सत्यापित करें';

  @override
  String get registerAadhaarVerifiedSubtitle =>
      'आपका आधार सत्यापित है और आपकी प्रोफ़ाइल में सहेजा गया है - ✓ बैज पहले से आपका है।';

  @override
  String get registerAadhaarUnverifiedSubtitle =>
      'सरकारी DigiLocker के माध्यम से आधार KYC आपकी प्रोफ़ाइल को ✓ सत्यापित बैज दिलाता है और हमारे पैतृक रिकॉर्ड को विश्वसनीय बनाए रखता है। हम केवल एक छिपा हुआ संदर्भ संग्रहीत करते हैं - कभी भी आपका पूरा आधार नंबर नहीं।';

  @override
  String get registerDigilockerIdentityDesc =>
      'आधिकारिक DigiLocker पोर्टल में साइन इन करें और अपना आधार साझा करने के लिए सहमति दें। सत्यापन स्वचालित रूप से पुष्ट हो जाता है।';

  @override
  String get registerContinueToDashboard => 'डैशबोर्ड पर जारी रखें';

  @override
  String get registerSkipForNow => 'अभी के लिए छोड़ें - बाद में सत्यापित करें';

  @override
  String get registerKycVerifiedTitle =>
      'DigiLocker के माध्यम से आधार सत्यापित';

  @override
  String get registerKycSavedOnSignup =>
      'साइन अप पूरा करने पर आपके खाते में सहेजा जाएगा।';

  @override
  String get registerErrorName => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get registerErrorPhone =>
      'कृपया एक मान्य 10-अंकीय फ़ोन नंबर दर्ज करें';

  @override
  String get registerErrorInvalidOtp => 'अमान्य OTP। कृपया पुनः प्रयास करें।';

  @override
  String get registerErrorGeneric =>
      'पंजीकरण विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get registerErrorTimeout =>
      'सर्वर को प्रतिक्रिया देने में बहुत अधिक समय लगा';

  @override
  String registerErrorNetwork(String detail) {
    return 'नेटवर्क त्रुटि - $detail';
  }

  @override
  String get heritageStepLabel => 'चरण 3 का 3';

  @override
  String get heritageTitle => 'सांस्कृतिक प्रोफ़ाइल और विरासत';

  @override
  String get heritageSubtitle =>
      'दैवज्ञ समुदाय के भीतर अपनी विरासत का दस्तावेजीकरण करने का अंतिम चरण।';

  @override
  String heritageErrorPickFile(String error) {
    return 'फ़ाइल नहीं चुनी जा सकी: $error';
  }

  @override
  String get heritageGotra => 'गोत्र';

  @override
  String get heritageGotraHint => 'उदा. कश्यप';

  @override
  String get heritageNativePlace => 'मूल स्थान (कुल देवता स्थान)';

  @override
  String get heritageNativePlaceHint => 'उदा. गोकर्ण';

  @override
  String get heritageBio => 'व्यावसायिक बायो';

  @override
  String get heritageBioHint => 'समुदाय को अपने काम और कौशल के बारे में बताएं।';

  @override
  String get heritageMatrimonialOptIn => 'वैवाहिक हब में शामिल हों';

  @override
  String get heritageMatrimonialDesc =>
      'अपनी प्रोफ़ाइल को समाज के भीतर वैवाहिक संबंध खोजने वाले परिवारों के लिए खोज योग्य बनाएं। आप इस प्राथमिकता को कभी भी बदल सकते हैं।';

  @override
  String get heritageUploadNote =>
      'वैकल्पिक: पारिवारिक दस्तावेज़ अपलोड करें (जन्म प्रमाण पत्र, पुराने पत्र या विरासत - JPG / PNG)';

  @override
  String get heritageUploadPrompt =>
      'पारिवारिक दस्तावेज़ अपलोड करने के लिए क्लिक करें';

  @override
  String get heritageChange => 'बदलें';

  @override
  String get heritageBackToLineage => 'वंशावली पर वापस जाएं';

  @override
  String get heritageCompleteProfile => 'प्रोफ़ाइल पूर्ण करें ✓';

  @override
  String get heritageWelcomeTitle => 'समाज में आपका स्वागत है';

  @override
  String get heritageWelcomeBody =>
      'इस चरण को पूरा करके, आप हमारे जीवंत डिजिटल वृक्ष में एक सत्यापित सदस्य बन जाते हैं। आप दैवज्ञ समुदाय की सांस्कृतिक अखंडता और सामाजिक ताने-बाने को बनाए रखने में मदद करते हैं।';

  @override
  String get heritageBenefit1 => 'वैश्विक वंशावली निर्देशिका तक पहुंच';

  @override
  String get heritageBenefit2 => 'समाज शासन में भागीदारी';

  @override
  String get heritageBenefit3 => 'सामुदायिक कल्याण कार्यक्रम पात्रता';

  @override
  String get onboardStepIdentity => 'पहचान';

  @override
  String get onboardStepLineage => 'वंशावली';

  @override
  String get onboardStepHeritage => 'विरासत';

  @override
  String get identityStepLabel => 'चरण 1 का 3';

  @override
  String get identityTitle => 'अपनी पहचान सत्यापित करें';

  @override
  String get identitySubtitle =>
      'हमारे पैतृक रिकॉर्ड की पवित्रता बनाए रखने के लिए अपना आधार सत्यापित करें। आपके आधार से जुड़े मोबाइल पर एक OTP भेजा जाएगा। आपका डेटा एन्क्रिप्टेड है और कभी भी अन्य सदस्यों के साथ साझा नहीं किया जाता।';

  @override
  String get identityDigilockerDesc =>
      'सरकारी DigiLocker के माध्यम से सुरक्षित रूप से अपना आधार सत्यापित करें। आप DigiLocker में साइन इन करेंगे और अपना आधार साझा करने के लिए सहमति देंगे।';

  @override
  String identityErrorCapture(String error) {
    return 'छवि कैप्चर नहीं की जा सकी: $error';
  }

  @override
  String get identitySelfieVerification => 'सेल्फी सत्यापन';

  @override
  String get identitySelfieCaptured => 'सेल्फी सफलतापूर्वक कैप्चर की गई';

  @override
  String get identitySelfiePrompt =>
      'अपनी आईडी फ़ोटो से मिलान के लिए एक सेल्फी लें';

  @override
  String get identityOpenCamera => 'कैमरा खोलें';

  @override
  String get identityContinueToLineage => 'वंशावली पर जारी रखें';

  @override
  String get identityTrustSecurity => 'विश्वास और सुरक्षा';

  @override
  String get identityTrustEncryption => 'AES-256 एंड-टू-एंड एन्क्रिप्शन';

  @override
  String get identityTrustNeverShared =>
      'अन्य सदस्यों के साथ कभी साझा नहीं किया गया';

  @override
  String get identityTrustVault => 'आर्काइवल-ग्रेड सुरक्षित वॉल्ट';

  @override
  String get lineageStepLabel => 'चरण 2 का 3';

  @override
  String get lineageTitle => 'अपनी जड़ें खोजें';

  @override
  String get lineageSubtitle =>
      'दैवज्ञ समाज वृक्ष में मौजूदा शाखा खोजने के लिए अपने माता-पिता, गोत्र या पूर्वजों के गाँव की खोज करें।';

  @override
  String get lineageSearchHint =>
      'माता-पिता का नाम, गोत्र, या पूर्वजों का गाँव दर्ज करें…';

  @override
  String lineageResultsForQuery(String query) {
    return '\"$query\" के लिए परिणाम';
  }

  @override
  String get lineagePotentialConnections => 'संभावित कनेक्शन';

  @override
  String lineageResultsCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String lineageNoMatches(String query) {
    return '\"$query\" के लिए कोई मेल नहीं मिला';
  }

  @override
  String get lineageBack => 'वापस';

  @override
  String get lineageContinueToHeritage => 'विरासत पर जारी रखें';

  @override
  String lineageNominatedBy(String nominator) {
    return '✓ $nominator';
  }

  @override
  String get lineageRequested => '✓ अनुरोध किया गया';

  @override
  String get lineageConnect => 'कनेक्ट करें';

  @override
  String get lineageNewRootEstablished => 'नया रूट नोड स्थापित किया गया';

  @override
  String get lineageNewRootEstablishedDesc =>
      'आपके परिवार को एक नई शाखा के रूप में जोड़ा जाएगा। एक बुजुर्ग समीक्षा के दौरान इसे सत्यापित और लिंक करेंगे।';

  @override
  String get lineageUndo => 'पूर्ववत करें';

  @override
  String get lineageCantFindBranch => 'अपनी शाखा नहीं मिल रही?';

  @override
  String get lineageStartNewRootDesc =>
      'यदि आपके परिवार ने अभी तक पंजीकरण नहीं कराया है तो आप एक नया रूट नोड शुरू कर सकते हैं।';

  @override
  String get lineageEstablishNewRoot => 'नया रूट नोड स्थापित करें →';

  @override
  String get dashTitle => 'समाज फ़ीड';

  @override
  String get dashCouldNotLoadFeed => 'फ़ीड लोड नहीं हो सकी';

  @override
  String get dashNoPostsYet => 'अभी तक कोई पोस्ट नहीं';

  @override
  String get dashBeFirstToShare =>
      'समाज के साथ कुछ साझा करने वाले पहले व्यक्ति बनें।';

  @override
  String get dashAllCaughtUp => 'आप पूरी तरह अपडेट हैं ✦';

  @override
  String dashErrorCouldNotReachSuffix(String message, String baseUrl) {
    return '$message\n$baseUrl तक नहीं पहुंचा जा सका';
  }

  @override
  String dashErrorWithStatus(String message, String statusCode) {
    return '$message ($statusCode)';
  }

  @override
  String dashErrorServerUnreachable(String baseUrl) {
    return '$baseUrl पर सर्वर तक नहीं पहुंचा जा सका।\nजांचें कि बैकएंड चल रहा है, या --dart-define=API_BASE_URL=<host> पास करें।';
  }

  @override
  String dashErrorGeneric(String error) {
    return 'फ़ीड लोड नहीं की जा सकी।\n$error';
  }

  @override
  String get dashCamera => 'कैमरा';

  @override
  String get dashSelectFile => 'फ़ाइल चुनें';

  @override
  String dashCouldNotPickMedia(String error) {
    return 'मीडिया नहीं चुना जा सका: $error';
  }

  @override
  String get dashFamilyUpdates => 'परिवार अपडेट';

  @override
  String get dashYourStory => 'आपकी स्टोरी';

  @override
  String get dashYou => 'आप';

  @override
  String get dashReel => 'रील';

  @override
  String get postMenuDelete => 'पोस्ट हटाएं';

  @override
  String get postMenuEditCaption => 'कैप्शन संपादित करें';

  @override
  String get postMenuReport => 'पोस्ट की रिपोर्ट करें';

  @override
  String get postMenuHide => 'फ़ीड से छिपाएं';

  @override
  String get postMenuCopyLink => 'लिंक कॉपी करें';

  @override
  String get postHidden => 'पोस्ट छिपाई गई';

  @override
  String get linkCopied => 'लिंक क्लिपबोर्ड पर कॉपी हो गया';

  @override
  String get reportThanks => 'धन्यवाद - हम इस पोस्ट को देखेंगे';

  @override
  String get deletePostTitle => 'पोस्ट हटाएं?';

  @override
  String get deletePostBody => 'यह इसे समाज के सभी सदस्यों के लिए हटा देगा।';

  @override
  String get postDelete => 'हटाएं';

  @override
  String get couldNotDeletePost => 'पोस्ट हटाई नहीं जा सकी';

  @override
  String get writeACaption => 'एक कैप्शन लिखें…';

  @override
  String get cantEditCaptionYet =>
      'अपलोड पूरा होने तक कैप्शन संपादित नहीं किया जा सकता।';

  @override
  String get captionUpdated => 'कैप्शन अपडेट किया गया';

  @override
  String get couldNotUpdateCaption => 'कैप्शन अपडेट नहीं किया जा सका';

  @override
  String get couldNotUpdateLike => 'लाइक अपडेट नहीं की जा सकी';

  @override
  String get savedToProfile => 'आपकी प्रोफ़ाइल में सहेजा गया';

  @override
  String get removedFromSaved => 'सहेजे गए से हटाया गया';

  @override
  String get uploadingEllipsis => 'अपलोड हो रहा है…';

  @override
  String get uploadFailed => 'अपलोड विफल';

  @override
  String get discard => 'छोड़ें';

  @override
  String get stillOffline => 'अभी भी ऑफ़लाइन';

  @override
  String get timeJustNow => 'अभी';

  @override
  String get timeRecently => 'हाल ही में';

  @override
  String timeMinutesAgo(int n) {
    return '$n मिनट पहले';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n घंटे पहले';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n दिन पहले';
  }

  @override
  String timeWeeksAgo(int n) {
    return '$n सप्ताह पहले';
  }

  @override
  String get profileRelative => 'रिश्तेदार';

  @override
  String get profilePendingInvitation => 'लंबित आमंत्रण';

  @override
  String get profileFamilyMember => 'परिवार के सदस्य';

  @override
  String get profileViewInFamilyTree => 'वंश वृक्ष में देखें';

  @override
  String get profilePleaseSignIn => 'अपनी प्रोफ़ाइल देखने के लिए साइन इन करें।';

  @override
  String get profileGoToLogin => 'लॉगिन पर जाएं';

  @override
  String get profileElderAdmin => 'बुजुर्ग और समाज व्यवस्थापक';

  @override
  String get profileSamajMember => 'समाज सदस्य';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileMatrimonialDetails => 'वैवाहिक विवरण';

  @override
  String get profileVerifyIdentityOptional => 'पहचान सत्यापित करें (वैकल्पिक)';

  @override
  String get profileVerifiedPill => 'सत्यापित';

  @override
  String get profileAadhaarVerified => 'आधार सत्यापित';

  @override
  String get profileVerifiedViaDigilocker => 'DigiLocker के माध्यम से सत्यापित';

  @override
  String profileViaDigilockerMasked(String masked) {
    return 'DigiLocker के माध्यम से · $masked';
  }

  @override
  String get profileAboutOccupation => 'बारे में और व्यवसाय';

  @override
  String get profileOccupation => 'व्यवसाय';

  @override
  String get profileBirthYear => 'जन्म वर्ष';

  @override
  String get profileStatus => 'स्थिति';

  @override
  String get profileInMemoriam => 'स्मृति में';

  @override
  String get profileActiveMember => 'सक्रिय सदस्य';

  @override
  String get profileLate => 'स्वर्गीय';

  @override
  String get profileActive => 'सक्रिय';

  @override
  String profilePassedAway(String date) {
    return '$date को निधन हुआ';
  }

  @override
  String profileAt(String place) {
    return '$place में';
  }

  @override
  String get profileFamilyRelations => 'पारिवारिक संबंध';

  @override
  String get profileFullTree => 'पूरा वृक्ष →';

  @override
  String get profileNoConnectedRelations => 'अभी तक कोई जुड़े रिश्तेदार नहीं';

  @override
  String get profileNotJoinedYet => 'अभी तक शामिल नहीं हुए';

  @override
  String get profileLifeArchive => 'जीवन अभिलेख';

  @override
  String get profileQuickStats => 'त्वरित आँकड़े';

  @override
  String get profileGotra => 'गोत्र';

  @override
  String get profileNative => 'मूल स्थान';

  @override
  String get profileStanding => 'स्थिति';

  @override
  String get profileAncestor => 'पूर्वज';

  @override
  String get profileMember => 'सदस्य';

  @override
  String get profileSamajId => 'समाज आईडी';

  @override
  String profileSamajIdCopied(String id) {
    return 'समाज आईडी $id कॉपी की गई';
  }

  @override
  String get profilePhoneNumber => 'फ़ोन नंबर';

  @override
  String get profileShareWithMembers => 'सदस्यों के साथ साझा करें';

  @override
  String get profilePhoneVisibleDesc =>
      'जो सदस्य आपकी प्रोफ़ाइल खोलते हैं वे आपका नंबर देख और कॉल कर सकते हैं।';

  @override
  String get profilePhoneHiddenDesc =>
      'आपका नंबर निजी रहता है। सदस्य फिर भी ऐप में आपको संदेश भेज सकते हैं।';

  @override
  String get profileVisibleToMembers => 'सदस्यों को दिखाई देता है';

  @override
  String get profileHiddenFromMembers => 'अन्य सदस्यों से छिपा हुआ';

  @override
  String get profileCouldNotSave =>
      'इसे सहेजा नहीं जा सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get profileSaved => 'सहेजे गए';

  @override
  String get profileNoSavedPostsYet =>
      'अभी तक कोई सहेजी गई पोस्ट नहीं। इसे यहाँ रखने के लिए किसी भी रील या पोस्ट पर बुकमार्क टैप करें।';

  @override
  String get editProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editAddPhotoRequired =>
      'एक प्रोफ़ाइल फ़ोटो जोड़ें - वैवाहिक अनुभाग के लिए आवश्यक';

  @override
  String get editTapCameraToChange =>
      'अपनी फ़ोटो बदलने के लिए कैमरे पर टैप करें';

  @override
  String get editSectionBasicDetails => 'बुनियादी विवरण';

  @override
  String get editSectionCurrentAddress => 'वर्तमान पता';

  @override
  String get editSectionAbout => 'बारे में';

  @override
  String get editFullName => 'पूरा नाम';

  @override
  String get editNameTooShort => 'नाम कम से कम 2 अक्षरों का होना चाहिए';

  @override
  String get editNativePlace => 'मूल स्थान';

  @override
  String get editNativePlaceHint => 'उदा. कुमटा, कर्नाटक';

  @override
  String get editOccupation => 'व्यवसाय';

  @override
  String get editOccupationHint => 'उदा. सॉफ्टवेयर इंजीनियर';

  @override
  String get editCountry => 'देश';

  @override
  String get editCountryHint => 'उदा. भारत';

  @override
  String get editState => 'राज्य';

  @override
  String get editStateHint => 'उदा. कर्नाटक';

  @override
  String get editDistrict => 'जिला';

  @override
  String get editDistrictHint => 'उदा. बैंगलोर शहरी';

  @override
  String get editTaluk => 'तालुक';

  @override
  String get editTalukHint => 'उदा. बैंगलोर उत्तर';

  @override
  String get editCity => 'शहर / कस्बा / गाँव';

  @override
  String get editCityHint => 'उदा. बैंगलोर';

  @override
  String get editArea => 'क्षेत्र / इलाका';

  @override
  String get editAreaHint => 'उदा. राजाजीनगर';

  @override
  String get editStreet => 'गली';

  @override
  String get editStreetHint => 'उदा. तीसरा क्रॉस, पाँचवीं मेन';

  @override
  String get editLandmark => 'लैंडमार्क';

  @override
  String get editLandmarkHint => 'उदा. नवरंग थियेटर के सामने';

  @override
  String get editPincode => 'पिन कोड';

  @override
  String get editPincodeHint => '6 अंक';

  @override
  String get editPincodeInvalid => 'पिन कोड 6 अंकों का होना चाहिए';

  @override
  String get editBio => 'बायो';

  @override
  String get editAddressOldSingleLine => 'पता (पुराना, एक पंक्ति)';

  @override
  String get editSaving => 'सहेजा जा रहा है…';

  @override
  String get editSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get editAadhaarOptionalNote =>
      'आधार सत्यापन वैकल्पिक है। यहाँ हर विवरण हाथ से दर्ज किया जा सकता है - सत्यापन केवल कुछ को स्वतः भर देता है।';

  @override
  String get editGotPositionFillParts =>
      'आपकी स्थिति मिल गई - पते के हिस्से भरें';

  @override
  String get editAddressFilledFromLocation => 'आपके स्थान से पता भर दिया गया';

  @override
  String get editCouldNotReadLocation => 'आपका स्थान नहीं पढ़ा जा सका';

  @override
  String editCouldNotPickImage(String error) {
    return 'छवि नहीं चुनी जा सकी: $error';
  }

  @override
  String get editPhotoUpdated => 'फ़ोटो अपडेट की गई';

  @override
  String get editCouldNotUploadPhoto => 'फ़ोटो अपलोड नहीं की जा सकी';

  @override
  String get editDobHelpText => 'जन्म तिथि';

  @override
  String get editProfileSaved => 'प्रोफ़ाइल सहेजी गई';

  @override
  String get editCouldNotSaveProfile => 'आपकी प्रोफ़ाइल सहेजी नहीं जा सकी';

  @override
  String editPinnedAt(String lat, String lng) {
    return '$lat, $lng पर पिन किया गया';
  }

  @override
  String get editAlreadyOnMap =>
      'पहले से ही नक्शे पर है। पता संपादित करने पर सहेजने के समय इसे फिर से पिन किया जाएगा।';

  @override
  String get editCoordinatesFromAddress =>
      'सहेजते समय पते से निर्देशांक निकाले जाते हैं।';

  @override
  String get editLocating => 'स्थान ढूंढा जा रहा है…';

  @override
  String get editUseCurrentLocation => 'मेरा वर्तमान स्थान उपयोग करें';

  @override
  String get editGotra => 'गोत्र';

  @override
  String get editSelectGotra => 'अपना गोत्र चुनें';

  @override
  String get editKuladevata => 'कुलदेवता';

  @override
  String get editSelectKuladevata => 'अपना कुलदेवता चुनें';

  @override
  String get editNotSet => 'सेट नहीं है';

  @override
  String get editGender => 'लिंग';

  @override
  String get editMale => 'पुरुष';

  @override
  String get editFemale => 'महिला';

  @override
  String editAgeYears(int age) {
    return '$age वर्ष';
  }

  @override
  String get verifyIdentityTitle => 'पहचान सत्यापित करें';

  @override
  String get verifyIdentityHeading => 'पहचान सत्यापन';

  @override
  String get verifyIdentitySubtitle =>
      'सरकारी DigiLocker के माध्यम से सुरक्षित रूप से अपना आधार सत्यापित करें। जब तक यह पूर्ण नहीं होता आपकी प्रोफ़ाइल असत्यापित रहती है। हम कभी भी आपका पूरा आधार नंबर नहीं देखते या संग्रहीत नहीं करते - केवल एक छिपा हुआ संदर्भ।';

  @override
  String get verifyBackToDashboard => 'डैशबोर्ड पर वापस जाएं';

  @override
  String get verifyTrustGovBacked => 'सरकार समर्थित DigiLocker सहमति';

  @override
  String get verifyTrustNeverStored =>
      'पूरा आधार नंबर कभी संग्रहीत नहीं किया जाता';

  @override
  String get verifyTrustMaskedOnly => 'केवल एक छिपा हुआ संदर्भ रखा जाता है';

  @override
  String get ftTitle => 'वंश वृक्ष';

  @override
  String get ftUnableToLoad => 'लोड करने में असमर्थ';

  @override
  String get ftLoadError =>
      'वंश वृक्ष लोड नहीं किया जा सका। अपना कनेक्शन जांचें।';

  @override
  String get ftEmptyTitle => 'आपका वंश वृक्ष खाली है';

  @override
  String get ftEmptyBody =>
      'अपने निकटतम परिवार को जोड़ें - पिता, माता, जीवनसाथी, भाई-बहन, बच्चे। जैसे-जैसे वे शामिल होंगे उनके वृक्ष आपसे जुड़ जाएंगे।';

  @override
  String get ftAddFamilyMember => 'परिवार सदस्य जोड़ें';

  @override
  String get ftTruncatedBanner =>
      'वृक्ष का एक हिस्सा दिखाया जा रहा है — इसमें एक दृश्य में समाने से अधिक रिश्तेदार हैं।';

  @override
  String get ftHeaderKicker => 'दैवज्ञ समाज · वंशावली';

  @override
  String get ftHeaderTitle => 'वंश वृक्ष';

  @override
  String get ftAddMember => 'सदस्य जोड़ें';

  @override
  String get ftRequests => 'अनुरोध';

  @override
  String get ftInvites => 'आमंत्रण';

  @override
  String get ftAlerts => 'सूचनाएं';

  @override
  String get ftManageLinks => 'संबंध प्रबंधित करें';

  @override
  String get ftCompactView => 'संक्षिप्त दृश्य';

  @override
  String get ftExpandAll => 'सभी विस्तृत करें';

  @override
  String ftGenRow(String roman) {
    return 'पीढ़ी $roman';
  }

  @override
  String get ftDefaultInviteMessage => 'आपके पास एक लंबित आमंत्रण है।';

  @override
  String ftMoreCount(int n) {
    return '  (+$n और)';
  }

  @override
  String get ftReview => 'समीक्षा करें';

  @override
  String get ftYourGeneration => 'आपकी पीढ़ी';

  @override
  String get ftOneGenAbove => 'एक पीढ़ी ऊपर';

  @override
  String ftGenerationsAbove(int n) {
    return '$n पीढ़ी ऊपर';
  }

  @override
  String get ftOneGenBelow => 'एक पीढ़ी नीचे';

  @override
  String ftGenerationsBelow(int n) {
    return '$n पीढ़ी नीचे';
  }

  @override
  String get ftRelative => 'रिश्तेदार';

  @override
  String get ftYou => 'आप';

  @override
  String ftDerivedFrom(String path) {
    return 'इससे निकला: आपके $path';
  }

  @override
  String ftShowTheirFamily(int n) {
    return 'उनका परिवार दिखाएं ($n)';
  }

  @override
  String get ftHideTheirFamily => 'उनका परिवार छिपाएं';

  @override
  String get ftViewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get ftWithdrawThisRequest => 'यह अनुरोध वापस लें';

  @override
  String get ftRemoveThisRelationship => 'यह संबंध हटाएं';

  @override
  String get ftVerifiedDeceased => 'सत्यापित दिवंगत';

  @override
  String get ftVerifiedDeceasedDesc =>
      'सीधे वृक्ष में जोड़ा गया - किसी स्वीकृति की आवश्यकता नहीं।';

  @override
  String get ftPendingInvitation => 'लंबित आमंत्रण';

  @override
  String get ftPendingInvitationDesc =>
      'यह व्यक्ति अभी तक शामिल नहीं हुआ है। पंजीकरण और स्वीकृति के बाद संबंध सक्रिय हो जाता है।';

  @override
  String get ftActiveMember => 'सक्रिय सदस्य';

  @override
  String get ftActiveMemberDesc => 'एक सत्यापित सदस्य खाते से जुड़ा हुआ।';

  @override
  String get ftInMemoriam => 'स्मृति में';

  @override
  String get ftLatePrefix => 'स्वर्गीय ';

  @override
  String ftInviteDialogTitle(String name) {
    return '$name को आमंत्रित करें';
  }

  @override
  String get ftInviteDialogBody =>
      'एक प्लेसहोल्डर जोड़ा गया और संबंध लंबित है। यह आमंत्रण साझा करें ताकि वे शामिल होकर आपसे जुड़ सकें।';

  @override
  String get ftClose => 'बंद करें';

  @override
  String get ftCopyLink => 'लिंक कॉपी करें';

  @override
  String get ftInviteLinkCopied => 'आमंत्रण लिंक कॉपी किया गया';

  @override
  String get ftYourRelative => 'आपका रिश्तेदार';

  @override
  String get ftMemberAdded => 'सदस्य जोड़ा गया';

  @override
  String get ftWithdrawRequestTitle => 'क्या यह अनुरोध वापस लें?';

  @override
  String get ftRemoveLinkTitle => 'क्या यह संबंध हटाएं?';

  @override
  String ftWithdrawRequestBody(String name, String relation) {
    return '$name से अब आपके $relation के रूप में शामिल होने के लिए नहीं कहा जाएगा।';
  }

  @override
  String ftRemoveLinkBody(String name, String relation) {
    return '$name अब आपका/आपकी $relation नहीं रहेगा/रहेगी। यह संबंध दोनों वृक्षों से हट जाएगा, साथ ही जो लोग केवल इसी के माध्यम से पहुंचे थे वे भी। आप सही संबंध के साथ फिर से जोड़ सकते हैं।';
  }

  @override
  String get ftOptionalNoteHint =>
      'उन्हें वैकल्पिक टिप्पणी — जैसे \"गलत संबंध\"';

  @override
  String get ftRequestWithdrawn => 'अनुरोध वापस लिया गया';

  @override
  String get ftRelationshipRemoved => 'संबंध हटाया गया';

  @override
  String get ftCouldNotRemoveRelationship => 'संबंध हटाया नहीं जा सका';

  @override
  String get ftManageRelationships => 'संबंध प्रबंधित करें';

  @override
  String get ftNoRelationshipsYet => 'अभी तक कोई संबंध नहीं';

  @override
  String get ftNoRelationshipsYetDesc =>
      'आपके जोड़े गए लिंक — या कोई रिश्तेदार आपका नाम लेकर जोड़े गए लिंक — यहां दिखते हैं, और किसी भी पक्ष से हटाए जा सकते हैं।';

  @override
  String get ftRemovingLinkNote =>
      'लिंक हटाने से यह दोनों वृक्षों से हट जाता है, साथ ही जो कोई केवल इसी से पहुंचा था वह भी। जोड़ी सही संबंध के साथ फिर से जोड़ी जा सकती है।';

  @override
  String get ftNotAcceptedYet => 'अभी स्वीकृत नहीं';

  @override
  String ftYourRelation(String relation) {
    return 'आपका/आपकी $relation';
  }

  @override
  String get ftRelationFather => 'पिता';

  @override
  String get ftRelationMother => 'माता';

  @override
  String get ftRelationSpouse => 'जीवनसाथी';

  @override
  String get ftRelationBrother => 'भाई';

  @override
  String get ftRelationSister => 'बहन';

  @override
  String get ftRelationSon => 'पुत्र';

  @override
  String get ftRelationDaughter => 'पुत्री';

  @override
  String get ftRelationshipToYou => 'आपसे संबंध *';

  @override
  String get ftHasAccount => 'खाता है';

  @override
  String get ftNewProfile => 'नई प्रोफ़ाइल';

  @override
  String get ftFindByNamePhone => 'उन्हें नाम, फ़ोन या समाज आईडी से खोजें';

  @override
  String get ftSearchHint => 'उदा. 9876543210 या रमेश';

  @override
  String get ftSearch => 'खोजें';

  @override
  String get ftAccountRequestNote =>
      'खाते वाले जीवित सदस्य को संबंध दोनों वृक्षों में दिखने से पहले आपका अनुरोध स्वीकार करना होगा।';

  @override
  String get ftFullName => 'पूरा नाम *';

  @override
  String get ftFullNameHint => 'उदा. रमेश हलदणकर';

  @override
  String get ftGender => 'लिंग';

  @override
  String get ftMale => 'पुरुष';

  @override
  String get ftFemale => 'महिला';

  @override
  String get ftStatus => 'स्थिति';

  @override
  String get ftAlive => 'जीवित';

  @override
  String get ftDeceased => 'दिवंगत';

  @override
  String get ftDeceasedNote =>
      'एक दिवंगत व्यक्ति तुरंत जोड़ा जाता है - कोई आमंत्रण या स्वीकृति नहीं।';

  @override
  String get ftAliveNote =>
      'एक जीवित व्यक्ति को आमंत्रित किया जाता है: वे शामिल होकर संबंध की पुष्टि करते हैं।';

  @override
  String get ftPhoneOptional => 'फ़ोन (वैकल्पिक)';

  @override
  String get ftPhoneLinkNote =>
      'पंजीकरण के समय उनके खाते से जोड़ने के लिए उपयोग किया जाता है।';

  @override
  String get ftDateOfBirth => 'जन्म तिथि *';

  @override
  String get ftDateOfDeath => 'मृत्यु तिथि';

  @override
  String get ftPlaceOfDeath => 'मृत्यु का स्थान';

  @override
  String get ftPlaceOfDeathHint => 'उदा. कुंदापुरा';

  @override
  String get ftBiography => 'जीवनी';

  @override
  String get ftBiographyHint => 'उनके जीवन के बारे में कुछ शब्द…';

  @override
  String get ftSelect => 'चुनें';

  @override
  String get ftSendRequest => 'अनुरोध भेजें';

  @override
  String get ftAddToFamilyTree => 'वंश वृक्ष में जोड़ें';

  @override
  String get ftCreateAndInvite => 'बनाएं और आमंत्रित करें';

  @override
  String get ftSelectPersonToRequest => 'अनुरोध भेजने के लिए व्यक्ति चुनें';

  @override
  String get ftNameRequired => 'नाम आवश्यक है';

  @override
  String get ftDobRequired => 'जन्म तिथि आवश्यक है';

  @override
  String get ftSearchFailed => 'खोज विफल रही। अपना कनेक्शन जांचें।';

  @override
  String get ftCouldNotAddMember =>
      'सदस्य नहीं जोड़ा जा सका। अपना कनेक्शन जांचें।';

  @override
  String get ftDefaultMemberName => 'सदस्य';

  @override
  String ftAlreadyConnected(String name) {
    return 'आप पहले से $name से जुड़े हैं।';
  }

  @override
  String ftRequestSent(String name) {
    return '$name को अनुरोध भेजा गया - स्वीकार करने पर वे दिखाई देंगे।';
  }

  @override
  String ftInvited(String name) {
    return '$name को आमंत्रित किया गया - लिंक साझा करें ताकि वे शामिल हो सकें।';
  }

  @override
  String ftAddedToTree(String name) {
    return '$name को वंश वृक्ष में जोड़ा गया।';
  }

  @override
  String ftAdded(String name) {
    return '$name जोड़ा गया।';
  }

  @override
  String get ftRelationshipRequests => 'संबंध अनुरोध';

  @override
  String get ftNoPendingRequests => 'कोई लंबित अनुरोध नहीं';

  @override
  String get ftNoPendingRequestsDesc =>
      'जब कोई रिश्तेदार आपसे जुड़ने का अनुरोध करता है, तो वह यहां दिखता है।';

  @override
  String get ftWaitingOnThem => 'उनकी प्रतीक्षा में';

  @override
  String get ftWaitingOnThemDesc =>
      'जब तक दूसरा व्यक्ति स्वीकार नहीं करता, ये वृक्ष से बाहर रहते हैं।';

  @override
  String ftAddedAsYourRelation(String relation) {
    return 'आपके $relation के रूप में जोड़ा गया';
  }

  @override
  String get ftCopyInvite => 'आमंत्रण कॉपी करें';

  @override
  String get ftWithdraw => 'वापस लें';

  @override
  String get ftCouldNotWithdrawRequest => 'अनुरोध वापस नहीं लिया जा सका';

  @override
  String get ftCouldNotUpdateRequest => 'अनुरोध अपडेट नहीं किया जा सका';

  @override
  String ftWantsToConnect(String name) {
    return '$name जुड़ना चाहते हैं।';
  }

  @override
  String get ftDecline => 'अस्वीकार करें';

  @override
  String get ftAccept => 'स्वीकार करें';

  @override
  String get ftYourInvitations => 'आपके आमंत्रण';

  @override
  String get ftAllSet => 'सब तैयार है';

  @override
  String get ftConnectedTreesMerged =>
      'जुड़ गए - आपके वृक्ष अब विलय हो गए हैं।';

  @override
  String get ftDone => 'पूर्ण।';

  @override
  String get ftInvitationsDeclined => 'आमंत्रण अस्वीकार किए गए।';

  @override
  String get ftCouldNotUpdateInvitations => 'आमंत्रण अपडेट नहीं किए जा सके';

  @override
  String get ftNoInvitations => 'कोई आमंत्रण नहीं';

  @override
  String get ftNoInvitationsDesc =>
      'आपके नंबर पर भेजे गए आमंत्रण यहां दिखाई देंगे।';

  @override
  String get ftAcceptingMergesNote =>
      'स्वीकार करने से पुष्टि होती है कि ये लोग आपके परिवार हैं और उनकी प्लेसहोल्डर प्रोफ़ाइलें आपके खाते में विलय हो जाती हैं।';

  @override
  String get ftAcceptAndConnect => 'स्वीकार करें और जुड़ें';

  @override
  String get ftNotifications => 'सूचनाएं';

  @override
  String get ftMarkAllRead => 'सभी को पढ़ा हुआ चिह्नित करें';

  @override
  String get ftNoNotifications => 'कोई सूचना नहीं';

  @override
  String get ftNoNotificationsDesc =>
      'संबंध गतिविधि - अनुरोध, शामिल होना, विलय - यहां दिखाई देती है।';

  @override
  String get ftAccepted => 'स्वीकृत';

  @override
  String get ftDeclined => 'अस्वीकृत';

  @override
  String get ftSomeone => 'कोई';

  @override
  String get invTitle => 'आमंत्रण';

  @override
  String get invCouldNotLoadMap => 'नक्शा लोड नहीं किया जा सका';

  @override
  String get invRoutePlanError => 'मार्ग की योजना नहीं बनाई जा सकी';

  @override
  String get invCouldNotReadLocation => 'आपका स्थान नहीं पढ़ा जा सका';

  @override
  String get invSelectAtLeastOne =>
      'शुरू करने के लिए कम से कम एक परिवार चुनें।';

  @override
  String get invNoMapsApp => 'कोई नक्शा ऐप मार्ग नहीं खोल सका';

  @override
  String invNavigatingFirst10(int dropped) {
    return 'पहले 10 पड़ावों पर नेविगेट किया जा रहा है - नक्शे एक बार में केवल उतने ही ले सकते हैं (अगली यात्रा के लिए $dropped शेष)।';
  }

  @override
  String get invCouldNotOpenMapsApp => 'एक नक्शा ऐप नहीं खोला जा सका';

  @override
  String get invCheckConnectionRetry =>
      'अपना कनेक्शन जांचें और फिर से प्रयास करें।';

  @override
  String get invRetry => 'पुनः प्रयास करें';

  @override
  String get invRefresh => 'ताज़ा करें';

  @override
  String get invNoMembersYet => 'अभी तक नक्शे पर कोई सदस्य नहीं';

  @override
  String invNoMembersMatch(String query) {
    return '\"$query\" से कोई सदस्य मेल नहीं खाता';
  }

  @override
  String get invNoMembersYetDetail =>
      'एक सदस्य यहां तब दिखता है जब वे अपना वर्तमान पता सहेजते हैं - पता ही उन्हें नक्शे पर लाता है।';

  @override
  String get invSearchMatchesDetail =>
      'खोज समाज आईडी, उपयोगकर्ता नाम या फ़ोन नंबर से मेल खाती है।';

  @override
  String get invSmartPlanner => 'स्मार्ट आमंत्रण योजनाकार';

  @override
  String get invRoutePlanner => 'मार्ग योजनाकार';

  @override
  String get invSelectFamiliesSubtitle =>
      'परिवार चुनें · मार्ग खुद व्यवस्थित हो जाता है';

  @override
  String invShowingNearest(int shown, int total) {
    return '$total मैप किए गए सदस्यों में से निकटतम $shown दिखा रहे हैं।';
  }

  @override
  String get invStartFrom => 'यहां से शुरू करें';

  @override
  String get invLocating => 'स्थान ढूंढा जा रहा है…';

  @override
  String get invWaitingForLocation => 'आपके स्थान की प्रतीक्षा';

  @override
  String invCurrentLocation(String lat, String lng) {
    return 'वर्तमान स्थान · $lat, $lng';
  }

  @override
  String get invUpdate => 'अपडेट करें';

  @override
  String get invSearchHint => 'नाम, क्षेत्र या समाज आईडी से खोजें';

  @override
  String get invLoadingMap => 'नक्शा लोड हो रहा है…';

  @override
  String get invSelectFamiliesToPlan =>
      'मार्ग की योजना बनाने के लिए परिवार चुनें';

  @override
  String invFromTheStart(String km) {
    return 'शुरुआत से $km';
  }

  @override
  String invFromStopN(String km, int n) {
    return 'पड़ाव $n से $km';
  }

  @override
  String invAway(String km) {
    return '$km दूर';
  }

  @override
  String get invOptimisingRoute => 'मार्ग को अनुकूलित किया जा रहा है…';

  @override
  String get invPickFamilies => 'मिलने के लिए परिवार चुनें';

  @override
  String get invStraightLineEstimate => ' (सीधी-रेखा अनुमान)';

  @override
  String get invStop => 'पड़ाव';

  @override
  String get invStops => 'पड़ाव';

  @override
  String get invStartNavigation => 'नेविगेशन शुरू करें';

  @override
  String get dirTitle => 'सदस्य निर्देशिका';

  @override
  String get dirSearchHint => 'सदस्यों, गोत्रों, या स्थानों को खोजें…';

  @override
  String get dirAdvancedFiltersSoon => 'उन्नत फ़िल्टर जल्द आ रहे हैं';

  @override
  String get dirAllMembers => 'सभी सदस्य';

  @override
  String get dirByArea => 'क्षेत्र के अनुसार';

  @override
  String get dirByGotra => 'गोत्र के अनुसार';

  @override
  String get dirByOccupation => 'व्यवसाय के अनुसार';

  @override
  String get dirMapView => 'नक्शा दृश्य';

  @override
  String get dirNearbyMembers => 'आस-पास के सदस्य';

  @override
  String get dirViewAll => 'सभी देखें →';

  @override
  String get dirFromNativePlaceFirst => 'पहले आपके मूल स्थान से';

  @override
  String get dirNoOtherMembersYet => 'अभी तक कोई अन्य सदस्य नहीं।';

  @override
  String get dirSuggestedConnections => 'सुझाए गए कनेक्शन';

  @override
  String get dirNoMembersYet => 'अभी तक कोई सदस्य नहीं';

  @override
  String get dirNoMembersFound => 'कोई सदस्य नहीं मिला';

  @override
  String get dirMembersAppearHere =>
      'जैसे-जैसे आपका वंश वृक्ष बढ़ता है, सदस्य यहां दिखाई देते हैं।';

  @override
  String dirGotraSuffix(String gotra) {
    return '$gotra गोत्र';
  }

  @override
  String get dirMessage => 'संदेश';

  @override
  String get dirConnect => 'कनेक्ट करें';

  @override
  String get dirSameGotra => 'एक ही गोत्र';

  @override
  String dirReasonWithOcc(String occ, String gotra) {
    return '$occ · आपके $gotra गोत्र को साझा करते हैं।';
  }

  @override
  String dirReasonNoOcc(String gotra, String place) {
    return 'आपके $gotra गोत्र को साझा करते हैं, $place में निहित।';
  }

  @override
  String get dirViewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get dirCommunityMap => 'सामुदायिक नक्शा';

  @override
  String dirMembersCount(int n) {
    return '$n सदस्य';
  }

  @override
  String get dirExploreRegion => 'क्षेत्र खोजें';

  @override
  String get dirSamajMember => 'समाज सदस्य';

  @override
  String get dirGroupOther => 'अन्य';

  @override
  String get dirGroupNotSpecified => 'निर्दिष्ट नहीं';

  @override
  String get dirNumberCopied => 'नंबर कॉपी किया गया';

  @override
  String get dirGotra => 'गोत्र';

  @override
  String get dirNative => 'मूल स्थान';

  @override
  String get dirOccupation => 'व्यवसाय';

  @override
  String get dirPhone => 'फ़ोन';

  @override
  String dirPhoneCopied(String phone) {
    return '$phone कॉपी किया गया';
  }

  @override
  String get dirNoMembersToPlace => 'नक्शे पर रखने के लिए कोई सदस्य नहीं';

  @override
  String dirPhoneDisabled(String name) {
    return '$name ने अपना फ़ोन नंबर अक्षम कर दिया है। आप उन्हें कॉल नहीं कर सकते - इसके बजाय संदेश भेजें।';
  }

  @override
  String get dirThisMember => 'यह सदस्य';

  @override
  String dirCouldNotOpenDialer(String phone) {
    return '$phone के लिए डायलर नहीं खोला जा सका';
  }

  @override
  String get dirDefaultMemberName => 'सदस्य';

  @override
  String get matTitle => 'वैवाहिक';

  @override
  String get matCouldNotReachServer => 'सर्वर तक नहीं पहुंचा जा सका';

  @override
  String get matProfileLive => 'आपकी प्रोफ़ाइल वैवाहिक हब में लाइव है';

  @override
  String get matCouldNotPublish => 'प्रकाशित नहीं किया जा सका';

  @override
  String get matCouldNotLoad => 'लोड नहीं किया जा सका';

  @override
  String get matTryAgain => 'फिर से प्रयास करें';

  @override
  String get matAddDob => 'अपनी जन्म तिथि जोड़ें';

  @override
  String get matNotAvailable => 'उपलब्ध नहीं';

  @override
  String matAgeRangeAddDob(String min, String max) {
    return 'वैवाहिक अनुभाग $min-$max आयु के सदस्यों के लिए खुला है। जारी रखने के लिए अपनी प्रोफ़ाइल में अपनी जन्म तिथि जोड़ें।';
  }

  @override
  String matAgeRangeYourAge(String min, String max, String age) {
    return 'वैवाहिक अनुभाग $min-$max आयु के सदस्यों के लिए खुला है। आपकी आयु $age है।';
  }

  @override
  String get matGoToMyProfile => 'मेरी प्रोफ़ाइल पर जाएं';

  @override
  String get matReadyToPublish => 'प्रकाशित करने के लिए तैयार';

  @override
  String get matDetailsCompletePublish =>
      'आपका विवरण पूर्ण है। हब में प्रवेश करने के लिए अपनी प्रोफ़ाइल प्रकाशित करें।';

  @override
  String matDetailsCompleteNote(String note) {
    return 'आपका विवरण पूर्ण है। इस प्रोफ़ाइल पर पहले की टिप्पणी: $note';
  }

  @override
  String get matPublishMyProfile => 'मेरी प्रोफ़ाइल प्रकाशित करें';

  @override
  String get matHubTitle => 'वैवाहिक हब';

  @override
  String get matProfileCompletePublish =>
      'आपकी प्रोफ़ाइल पूर्ण है। हब में प्रवेश करने के लिए इसे प्रकाशित करें।';

  @override
  String get matCompleteToEnter =>
      'प्रवेश करने के लिए अपनी प्रोफ़ाइल पूर्ण करें। नीचे दिया गया हर फ़ील्ड संभावित मेल को दिखाया जाता है, ताकि हब सभी के लिए विश्वसनीय बना रहे।';

  @override
  String get matStillToFill => 'अभी भरना बाकी है';

  @override
  String matRemaining(int n) {
    return '$n शेष';
  }

  @override
  String get matInYourProfile => 'आपकी प्रोफ़ाइल में';

  @override
  String get matEditMyProfile => 'मेरी प्रोफ़ाइल संपादित करें';

  @override
  String get matInYourMatrimonialDetails => 'आपके वैवाहिक विवरण में';

  @override
  String get matAddMatrimonialDetails => 'वैवाहिक विवरण जोड़ें';

  @override
  String get matAllDetailsFilledIn => 'सभी आवश्यक विवरण भरे गए हैं।';

  @override
  String get matPublishing => 'प्रकाशित हो रहा है…';

  @override
  String get matOptionalAadhaarNote =>
      'आधार सत्यापन वैकल्पिक है - हर विवरण हाथ से दर्ज किया जा सकता है। आपका विवरण केवल उन सदस्यों को दिखाई देता है जिन्होंने अपनी प्रोफ़ाइल पूर्ण और प्रकाशित की है, और आप कभी भी अपनी प्रोफ़ाइल वापस ले सकते हैं।';

  @override
  String get matCouldNotLoadProfiles => 'प्रोफ़ाइलें लोड नहीं की जा सकीं';

  @override
  String get matDiscoverMatches => 'मेल खोजें';

  @override
  String get matShowingBrides => 'दुल्हनें दिखा रहे हैं';

  @override
  String get matShowingGrooms => 'दूल्हे दिखा रहे हैं';

  @override
  String get matShowingAllProfiles => 'सभी प्रोफ़ाइलें दिखा रहे हैं';

  @override
  String matProfilesCount(int n) {
    return '$n प्रोफ़ाइलें';
  }

  @override
  String get matNoProfilesYet => 'अभी तक कोई प्रोफ़ाइल नहीं';

  @override
  String get matBride => 'दुल्हन';

  @override
  String get matGroom => 'दूल्हा';

  @override
  String get matVerified => 'सत्यापित';

  @override
  String get matFree => 'मुफ़्त';

  @override
  String get matPremium => 'प्रीमियम';

  @override
  String get matViewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get matCandidateProfile => 'उम्मीदवार प्रोफ़ाइल';

  @override
  String get matProfileNotFound => 'प्रोफ़ाइल नहीं मिली';

  @override
  String get matBackToHub => 'वैवाहिक हब पर वापस जाएं';

  @override
  String get matMatchSummary => 'मेल सारांश';

  @override
  String get matProfessional => 'व्यावसायिक';

  @override
  String get matEducation => 'शिक्षा';

  @override
  String get matCompany => 'कंपनी';

  @override
  String get matDesignation => 'पदनाम';

  @override
  String get matAnnualIncome => 'वार्षिक आय';

  @override
  String get matPersonal => 'व्यक्तिगत';

  @override
  String get matHeight => 'ऊंचाई';

  @override
  String get matComplexion => 'रंग';

  @override
  String get matFamilyType => 'परिवार का प्रकार';

  @override
  String get matFamily => 'परिवार';

  @override
  String get matFather => 'पिता';

  @override
  String get matMother => 'माता';

  @override
  String get matSiblings => 'भाई-बहन';

  @override
  String get matHoroscope => 'जन्म कुंडली';

  @override
  String get matStarNakshatra => 'तारा / नक्षत्र';

  @override
  String get matRashi => 'राशि';

  @override
  String get matMangal => 'मंगल';

  @override
  String get matMangalik => 'मांगलिक';

  @override
  String get matNonMangalik => 'गैर-मांगलिक';

  @override
  String get matGotraSurname => 'गोत्र / उपनाम';

  @override
  String get matTimeOfBirth => 'जन्म का समय';

  @override
  String get matAbout => 'बारे में';

  @override
  String get matInterests => 'रुचियां';

  @override
  String get matPartnerExpectations => 'साथी की अपेक्षाएं';

  @override
  String get matPremiumProfileTitle => 'प्रीमियम प्रोफ़ाइल';

  @override
  String get matPremiumProfileBody =>
      'यह एक प्रीमियम प्रोफ़ाइल है। कनेक्शन केवल बुजुर्ग समिति के माध्यम से व्यवस्थित किए जाते हैं। परिचय के लिए कृपया एक समाज बुजुर्ग से संपर्क करें।';

  @override
  String get matUnderstood => 'समझ गया';

  @override
  String get matPremiumConnectViaElder =>
      'प्रीमियम - बुजुर्ग समिति के माध्यम से जुड़ें';

  @override
  String get matCheckCompatibility => 'अनुकूलता जांचें';

  @override
  String get matIntentionSoon => 'जल्द';

  @override
  String get matIntentionOneToTwoYears => '1-2 वर्ष';

  @override
  String get matIntentionNotDecided => 'तय नहीं';

  @override
  String get matChildrenWant => 'चाहते हैं';

  @override
  String get matChildrenDontWant => 'नहीं चाहते';

  @override
  String get matChildrenOpen => 'खुले विचार';

  @override
  String get matFamilyJoint => 'संयुक्त';

  @override
  String get matFamilyNuclear => 'एकल';

  @override
  String get matFamilyFlexible => 'लचीला';

  @override
  String get matRelocationYes => 'हाँ';

  @override
  String get matRelocationNo => 'नहीं';

  @override
  String get matRelocationMaybe => 'शायद';

  @override
  String get matFoodVegetarian => 'शाकाहारी';

  @override
  String get matFoodNonVegetarian => 'मांसाहारी';

  @override
  String get matFoodEggetarian => 'अंडाहारी';

  @override
  String get matFoodOther => 'अन्य';

  @override
  String get matInterestTravel => 'यात्रा';

  @override
  String get matInterestMusic => 'संगीत';

  @override
  String get matInterestMovies => 'फ़िल्में';

  @override
  String get matInterestFitness => 'फ़िटनेस';

  @override
  String get matInterestSports => 'खेल';

  @override
  String get matInterestReading => 'पढ़ना';

  @override
  String get matInterestCooking => 'खाना बनाना';

  @override
  String get matInterestSpirituality => 'आध्यात्मिकता';

  @override
  String get matEditTitle => 'वैवाहिक विवरण';

  @override
  String get matCouldNotLoadDetails => 'आपका विवरण लोड नहीं किया जा सका';

  @override
  String get matAgeFromToError =>
      'पसंदीदा साथी आयु: \"से\" \"तक\" से अधिक नहीं हो सकता';

  @override
  String get matDetailsSaved => 'वैवाहिक विवरण सहेजा गया';

  @override
  String get matCouldNotSaveDetails => 'आपका विवरण सहेजा नहीं जा सका';

  @override
  String get matSectionCareer => 'करियर';

  @override
  String get matEducationHint => 'उदा. एमबीए फाइनेंस, आईआईएम बैंगलोर';

  @override
  String get matCompanyOrg => 'कंपनी / संगठन';

  @override
  String get matIncomeRange => 'आय सीमा';

  @override
  String get matIncomeRangeHint => 'उदा. ₹22-28L';

  @override
  String get matSectionPhysical => 'शारीरिक';

  @override
  String get matComplexionFair => 'गोरा';

  @override
  String get matComplexionWheatish => 'गेहुआं';

  @override
  String get matComplexionDusky => 'सांवला';

  @override
  String get matComplexionDark => 'काला';

  @override
  String get matSectionFamily => 'परिवार';

  @override
  String get matFamilyTypeLabel => 'परिवार का प्रकार';

  @override
  String get matFathersOccupation => 'पिता का व्यवसाय';

  @override
  String get matMothersOccupation => 'माता का व्यवसाय';

  @override
  String get matSiblingsHint => 'उदा. 1 छोटा भाई, बी.टेक';

  @override
  String get matSectionHoroscope => 'जन्म कुंडली';

  @override
  String get matStarNakshatraLabel => 'तारा (नक्षत्र)';

  @override
  String get matStarHint => 'उदा. रोहिणी';

  @override
  String get matRashiHint => 'उदा. वृषभ';

  @override
  String get matTimeOfBirthLabel => 'जन्म का समय';

  @override
  String get matTimeOfBirthHint => 'उदा. सुबह 10:45';

  @override
  String get matSectionCompatibility => 'अनुकूलता';

  @override
  String get matAddBirthDetailsLink => 'अनुकूलता के लिए जन्म विवरण जोड़ें →';

  @override
  String get matManageConsentLink => 'अनुकूलता सहमति प्रबंधित करें →';

  @override
  String get matSectionAboutYou => 'आपके बारे में';

  @override
  String get matAboutYouLabel => 'आपके बारे में';

  @override
  String get matSectionLookingFor => 'आप क्या खोज रहे हैं';

  @override
  String get matPartnerExpectationsLabel => 'साथी की अपेक्षाएं';

  @override
  String get matOnePerLine => 'प्रति पंक्ति एक';

  @override
  String get matPreferredLocationsOptional => 'पसंदीदा स्थान (वैकल्पिक)';

  @override
  String get matPreferredLocationsHint =>
      'अल्पविराम से अलग करें, उदा. बैंगलोर, मंगलुरु';

  @override
  String get matGotrasToExcludeOptional => 'बाहर रखने के लिए गोत्र (वैकल्पिक)';

  @override
  String get matGotrasToExcludeHint =>
      'अल्पविराम से अलग करें। आपका अपना गोत्र हमेशा बाहर रखा जाता है।';

  @override
  String get matSectionMarriagePreferences => 'विवाह प्राथमिकताएं';

  @override
  String get matMarriageIntention => 'विवाह का इरादा';

  @override
  String get matChildren => 'बच्चे';

  @override
  String get matFamily2 => 'परिवार';

  @override
  String get matRelocation => 'स्थानांतरण';

  @override
  String get matSectionLifestyle => 'जीवनशैली';

  @override
  String get matFoodPreference => 'भोजन वरीयता';

  @override
  String get matSectionInterests => 'रुचियां';

  @override
  String get matSaving2 => 'सहेजा जा रहा है…';

  @override
  String get matSaveDetails => 'विवरण सहेजें';

  @override
  String get matSavedAsDraftNote =>
      'निजी रूप से मसौदे के रूप में सहेजा गया। जब सब कुछ भर जाए तो आप इसे वैवाहिक अनुभाग से प्रकाशित करें।';

  @override
  String get matHeightCm => 'ऊंचाई (सेमी)';

  @override
  String get matHeightHint => 'उदा. 163';

  @override
  String get matEnterNumberInCm => 'सेंटीमीटर में एक संख्या दर्ज करें';

  @override
  String get matHeightRangeError => 'ऊंचाई 120 से 250 सेमी के बीच होनी चाहिए';

  @override
  String get matMangalDosha => 'मंगल दोष';

  @override
  String get matPartnerAgeFrom => 'साथी की आयु से';

  @override
  String get matPartnerAgeTo => 'साथी की आयु तक';

  @override
  String get welfareTitle => 'कल्याण';

  @override
  String get welfareStartCampaign => 'अभियान शुरू करें';

  @override
  String get welfareKicker => 'सामुदायिक कल्याण और विकास';

  @override
  String get welfareHeroLine => 'समाज वृक्ष का निर्माण करें, एक योगदान के साथ।';

  @override
  String get welfareTotalRaised => 'कुल जुटाया गया';

  @override
  String get welfareTotalBackers => 'कुल समर्थक';

  @override
  String get welfareActiveCampaigns => 'सक्रिय धन जुटाने के अभियान';

  @override
  String welfareRaised(String amount) {
    return '$amount जुटाए गए';
  }

  @override
  String welfareOfGoalPct(String goal, int pct) {
    return '$goal में से · $pct%';
  }

  @override
  String welfareDaysLeft(int n) {
    return '$n दिन शेष';
  }

  @override
  String welfareBackers(int n) {
    return '$n समर्थक';
  }

  @override
  String get welfareDonate => 'दान करें';

  @override
  String get welfareImpactTitle => 'विरासत प्रभाव 2024-25';

  @override
  String get welfareImpactBody =>
      'देखें कि हर रुपया कहां जाता है - पूर्ण पारदर्शिता रिपोर्ट।';

  @override
  String get welfareViewImpactReport => 'प्रभाव रिपोर्ट देखें';

  @override
  String get welfareDhanyavaad => 'धन्यवाद! 🙏';

  @override
  String welfareThankYouReceived(String title) {
    return 'धन्यवाद! $title के लिए आपका योगदान प्राप्त हो गया है।';
  }

  @override
  String get welfareBackToWelfare => 'कल्याण पर वापस जाएं';

  @override
  String get welfareMakeContribution => 'योगदान करें';

  @override
  String get welfareCampaignNotFound => 'अभियान नहीं मिला';

  @override
  String welfarePctLabel(int pct) {
    return '$pct%';
  }

  @override
  String welfareDaysLeftContributors(int days, int backers) {
    return '$days दिन शेष · $backers योगदानकर्ता';
  }

  @override
  String get welfareTransparencyPledge => 'पारदर्शिता प्रतिज्ञा';

  @override
  String get welfareTransparencyPledgeBody =>
      'आपके योगदान का 100% सीधे एक निगरानी वाले समिति खाते में जाता है, जो त्रैमासिक प्रभाव रिपोर्ट में प्रकाशित होता है।';

  @override
  String get welfareSelectAmount => 'राशि चुनें (₹)';

  @override
  String get welfareEnterCustomAmount => 'कस्टम राशि दर्ज करें';

  @override
  String get welfareDonorName => 'दानकर्ता का नाम';

  @override
  String get welfareAnonymous => 'गुमनाम';

  @override
  String get welfareYourName => 'आपका नाम';

  @override
  String get welfareDonateAnonymously => 'गुमनाम रूप से दान करें';

  @override
  String get welfarePaymentMethod => 'भुगतान का तरीका';

  @override
  String get welfareUpiQr => 'UPI / QR कोड';

  @override
  String get welfareCreditDebitCard => 'क्रेडिट / डेबिट कार्ड';

  @override
  String get welfareNetBanking => 'नेट बैंकिंग';

  @override
  String welfareDonateAmount(String amount) {
    return '₹$amount दान करें';
  }

  @override
  String get welfareImpactReport => 'प्रभाव रिपोर्ट';

  @override
  String get welfareAnnualReportKicker =>
      'दैवज्ञ समाज बैंगलोर - वार्षिक पारदर्शिता रिपोर्ट';

  @override
  String get welfareRecordOfContributions =>
      'हमारे समुदाय के उदार योगदान और उनके मापने योग्य परिणामों का एक रिकॉर्ड।';

  @override
  String get welfareFamiliesHelped => 'परिवारों की मदद की गई';

  @override
  String get welfareCampaignsFunded => 'अभियानों को वित्तपोषित किया गया';

  @override
  String get welfareScholarships => 'छात्रवृत्तियां';

  @override
  String get welfareCategoryBreakdown => 'श्रेणी विवरण';

  @override
  String get welfareCategoryBreakdownSubtitle =>
      'अभियान श्रेणी के अनुसार जुटाई गई निधि का हिस्सा';

  @override
  String get welfareFundAllocation => 'निधि आवंटन';

  @override
  String get welfareAuditQuote =>
      '\"हर रुपया दर्ज। हर निर्णय पारदर्शी।\" - दैवज्ञ लेखा समिति';

  @override
  String get welfareGuardianDonors => 'संरक्षक दानकर्ता';

  @override
  String get welfareSupportCampaign => 'एक अभियान का समर्थन करें';

  @override
  String get welfareAllocTempleHeritage => 'मंदिर और विरासत';

  @override
  String get welfareAllocEducation => 'शिक्षा';

  @override
  String get welfareAllocHealthWelfare => 'स्वास्थ्य और कल्याण';

  @override
  String get welfareAllocCulturalEvents => 'सांस्कृतिक कार्यक्रम';

  @override
  String get welfareDonorHeadRole => 'बुजुर्ग समिति प्रमुख';

  @override
  String get welfareDonorPatronRole => 'समाज जीवन संरक्षक';

  @override
  String get welfareDonorItRole => 'आईटी पेशेवर चैप्टर';

  @override
  String get welfareDonorEntrepreneurRole => 'उद्यमी, बैंगलोर';

  @override
  String get welfareTestimonial1 =>
      '\"यह मंदिर इस बात का प्रमाण है कि हमारा समाज अपनी जड़ों को कभी नहीं भूलता।\"';

  @override
  String get welfareTestimonial1Author => 'प्रिया के., सामुदायिक सदस्य';

  @override
  String get welfareTestimonial2 =>
      '\"छात्रवृत्ति ने मुझे अपनी इंजीनियरिंग की डिग्री पूरी करने दी। मैं समाज का हमेशा आभारी रहूंगी।\"';

  @override
  String get welfareTestimonial2Author => 'आशा एच., गोकर्ण';

  @override
  String get welfareCampaignSubmitted => 'अभियान सबमिट किया गया!';

  @override
  String get welfareCampaignReviewNote =>
      'आपके अभियान की समीक्षा बुजुर्ग समिति द्वारा की जाएगी। आपको 48 घंटों के भीतर सूचना प्राप्त होगी।';

  @override
  String get welfareLaunchNewCampaign => 'नया अभियान शुरू करें';

  @override
  String get welfareTransparencyNoteTitle => 'पारदर्शिता पर एक नोट';

  @override
  String get welfareTransparencyNoteBody =>
      'प्रत्येक अभियान की जांच बुजुर्ग उप-समिति द्वारा विरासत संरेखण और वित्तीय अखंडता सुनिश्चित करने के लिए की जाती है।';

  @override
  String get welfareCampaignTitle => 'अभियान का शीर्षक';

  @override
  String get welfareCampaignTitleHint => 'उदा. विरासत पुस्तकालय का जीर्णोद्धार';

  @override
  String get welfareCategory => 'श्रेणी';

  @override
  String get welfareCampaignStory => 'अभियान की कहानी';

  @override
  String get welfareCampaignStoryHint =>
      'इतिहास, आवश्यकता और हमारे समुदाय पर प्रभाव का वर्णन करें…';

  @override
  String get welfareFundraisingGoal => 'धन जुटाने का लक्ष्य (₹)';

  @override
  String get welfareFundraisingGoalHint => 'उदा. 500000';

  @override
  String get welfareDuration => 'अवधि';

  @override
  String welfareDurationDays(int n) {
    return '$n दिन';
  }

  @override
  String get welfareChooseIcon => 'एक आइकन चुनें';

  @override
  String get welfareVerificationChecklist => 'सत्यापन चेकलिस्ट';

  @override
  String get welfareCheckCommunityBenefit => 'अभियान सामुदायिक लाभ के लिए है';

  @override
  String get welfareCheckFundsManaged =>
      'धन का प्रबंधन समिति द्वारा किया जाएगा';

  @override
  String get welfareCheckMonthlyReports => 'मासिक प्रगति रिपोर्ट साझा की जाएगी';

  @override
  String get welfareCheckEldersInformed =>
      'बुजुर्ग उप-समिति को सूचित किया गया है';

  @override
  String get welfareSubmitForReview => 'समीक्षा के लिए सबमिट करें';

  @override
  String get welfareCategoryInfrastructure => 'बुनियादी ढांचा';

  @override
  String get welfareCategoryCulturalHeritage => 'सांस्कृतिक विरासत';

  @override
  String get welfareCategoryEducation => 'शिक्षा';

  @override
  String get welfareCategoryEmergency => 'आपातकाल';

  @override
  String get welfareCategoryHealthcare => 'स्वास्थ्य सेवा';

  @override
  String get elderDefaultName => 'बुजुर्ग';

  @override
  String get elderHighRisk => 'उच्च जोखिम';

  @override
  String get elderMedRisk => 'मध्यम जोखिम';

  @override
  String get elderLowRisk => 'कम जोखिम';

  @override
  String get elderLineageTree => 'वंशावली वृक्ष';

  @override
  String get elderPortalKicker => 'बुजुर्ग पोर्टल · दैवज्ञ समाज';

  @override
  String elderWelcomeBack(String name) {
    return 'वापसी पर स्वागत है, $name';
  }

  @override
  String get elderGuardianOfTree => 'वृक्ष के संरक्षक';

  @override
  String get elderDashboardBlurb =>
      'आपका वंशावली निरीक्षण और सामुदायिक प्रबंधन डैशबोर्ड। लंबित सत्यापन की समीक्षा करें, विवादों को सुलझाएं, और समाज का मार्गदर्शन करें।';

  @override
  String get elderPendingVerifications => 'लंबित सत्यापन';

  @override
  String get elderActiveConflicts => 'सक्रिय विवाद';

  @override
  String get elderTotalMembers => 'कुल सदस्य';

  @override
  String get elderActiveBranches => 'सक्रिय शाखाएं';

  @override
  String get elderPendingMemberRequests => 'लंबित सदस्य अनुरोध';

  @override
  String get elderReview => 'समीक्षा करें →';

  @override
  String elderVouches(int have, int required) {
    return 'गवाही: $have/$required';
  }

  @override
  String get elderTreeAlertsConflicts => 'वृक्ष अलर्ट और विवाद';

  @override
  String get elderAlertSample =>
      '\"अनंत राव (1892-1954)\" मैसूर और बैंगलोर दोनों शाखाओं में परस्पर विरोधी पितृत्व के साथ दिखाई देते हैं।';

  @override
  String get elderResolveNow => 'अभी हल करें →';

  @override
  String get elderMemberDirectory => 'सदस्य निर्देशिका';

  @override
  String get elderDigitalArchive => 'डिजिटल अभिलेखागार';

  @override
  String get elderManageEvents => 'कार्यक्रम प्रबंधित करें';

  @override
  String get elderVerifications => 'सत्यापन';

  @override
  String get elderManagement => 'प्रबंधन';

  @override
  String get elderLineageWisdom => 'वंशावली ज्ञान';

  @override
  String get elderLineageQuote =>
      '\"जड़ों के बिना एक पेड़ सिर्फ लकड़ी है; इतिहास के बिना एक समुदाय सिर्फ भीड़ है।\"';

  @override
  String get elderMemberRequests => 'सदस्य अनुरोध';

  @override
  String get elderRiskLevel => 'जोखिम स्तर';

  @override
  String get elderAadhaarStatus => 'आधार स्थिति';

  @override
  String get elderAll => 'सभी';

  @override
  String elderPendingClaims(int n) {
    return 'लंबित दावे ($n)';
  }

  @override
  String get elderMale => 'पुरुष';

  @override
  String get elderFemale => 'महिला';

  @override
  String elderAgeGenderGotra(String age, String gender, String gotra) {
    return 'आयु: $age · $gender · $gotra गोत्र';
  }

  @override
  String get elderLineageNode => 'वंशावली नोड';

  @override
  String get elderRelation => 'संबंध';

  @override
  String get elderVouchesLabel => 'गवाही';

  @override
  String elderVouchesOfRequired(int have, int required) {
    return '$have / $required';
  }

  @override
  String elderAadhaarPrefix(String status) {
    return 'आधार: $status';
  }

  @override
  String elderSubmittedOn(String date) {
    return '$date को सबमिट किया गया';
  }

  @override
  String get elderNoRequestsMatchFilter =>
      'आपके फ़िल्टर से कोई अनुरोध मेल नहीं खाता';

  @override
  String get elderMediumRisk => 'मध्यम जोखिम';

  @override
  String get elderVerificationDetail => 'सत्यापन विवरण';

  @override
  String get elderVerificationNotFound => 'सत्यापन अनुरोध नहीं मिला';

  @override
  String get elderBackToQueue => 'कतार पर वापस जाएं';

  @override
  String get elderLineageClaim => 'वंशावली दावा';

  @override
  String get elderClaimingFrom => 'से दावा';

  @override
  String get elderClaimingAncestor => 'दावा किया गया पूर्वज';

  @override
  String get elderStatedRelation => 'बताया गया संबंध';

  @override
  String get elderSubmittedOnLabel => 'सबमिट किया गया';

  @override
  String get elderIdentity => 'पहचान';

  @override
  String get elderAadhaarStatusLabel => 'आधार स्थिति';

  @override
  String elderPhoneColon(String phone) {
    return 'फ़ोन: $phone';
  }

  @override
  String get elderSubmittedDocuments => 'सबमिट किए गए दस्तावेज़';

  @override
  String get elderReceived => 'प्राप्त हुआ';

  @override
  String elderPeerVouchesConfirmed(int have, int required) {
    return 'साथी गवाही ($have/$required पुष्टि की गई)';
  }

  @override
  String elderYrsGenderGotra(String age, String gender, String gotra) {
    return '$age वर्ष · $gender · $gotra गोत्र';
  }

  @override
  String get elderOccupation => 'व्यवसाय';

  @override
  String get elderLocation => 'स्थान';

  @override
  String get elderPhoneMasked => 'फ़ोन (छिपा हुआ)';

  @override
  String elderRiskAssessment(String level) {
    return 'जोखिम मूल्यांकन: $level';
  }

  @override
  String get elderCommitteeNotes => 'बुजुर्ग समिति टिप्पणियाँ';

  @override
  String get elderApprove => 'स्वीकृत करें';

  @override
  String get elderRequestMoreInfo => 'अधिक जानकारी मांगें';

  @override
  String get elderReject => 'अस्वीकार करें';

  @override
  String get elderVerificationApproved => 'सत्यापन स्वीकृत';

  @override
  String elderVerificationApprovedBody(String name) {
    return '$name को आधिकारिक रूप से समाज रजिस्ट्री में जोड़ा जाएगा। आवेदक को एक सूचना भेजी जाएगी।';
  }

  @override
  String get elderInfoRequested => 'जानकारी का अनुरोध किया गया';

  @override
  String elderInfoRequestedBody(String name) {
    return '$name को अतिरिक्त दस्तावेज़ या स्पष्टीकरण के अनुरोध के साथ एक प्रश्न भेजा गया है। प्रतिक्रिया की प्रतीक्षा में मामला रोका गया।';
  }

  @override
  String get elderRequestRejected => 'अनुरोध अस्वीकृत';

  @override
  String elderRequestRejectedBody(String name) {
    return '$name के लिए सत्यापन अनुरोध अस्वीकार कर दिया गया है। आवेदक को कारण सहित सूचित किया जाएगा।';
  }

  @override
  String get elderCommunity => 'समुदाय';

  @override
  String get elderSearchByNameGotraOcc => 'नाम, गोत्र, व्यवसाय से खोजें…';

  @override
  String get elderVerifiedMembersOnly => 'केवल सत्यापित सदस्य';

  @override
  String elderShownCount(int n) {
    return '$n दिखाए गए';
  }

  @override
  String get elderRegistryKicker => 'दैवज्ञ समाज बैंगलोर';

  @override
  String get elderCommunityMemberRegistry => 'सामुदायिक सदस्य रजिस्ट्री';

  @override
  String elderShowingOfTotal(int shown) {
    return '1,428 पंजीकृत सदस्यों में से $shown दिखा रहे हैं';
  }

  @override
  String get elderStatTotal => 'कुल';

  @override
  String get elderStatVerified => 'सत्यापित';

  @override
  String get elderStatPending => 'लंबित';

  @override
  String get elderStatBranches => 'शाखाएं';

  @override
  String get elderUnverified => 'असत्यापित';

  @override
  String elderYrsGender(String age, String gender) {
    return '$age वर्ष · $gender';
  }

  @override
  String elderBranchSuffix(String branch) {
    return '$branch शाखा';
  }

  @override
  String elderGotraSuffix(String gotra) {
    return '$gotra गोत्र';
  }

  @override
  String elderSinceYear(String year) {
    return '$year से';
  }

  @override
  String get elderViewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get elderPromoteToElder => 'बुजुर्ग के रूप में पदोन्नत करें';

  @override
  String get elderSuspendMember => 'सदस्य को निलंबित करें';

  @override
  String get elderNoMembersMatchFilter =>
      'आपके फ़िल्टर से कोई सदस्य मेल नहीं खाता';

  @override
  String get elderArchives => 'अभिलेखागार';

  @override
  String get elderHeritageMemoryArchive => 'विरासत स्मृति अभिलेखागार';

  @override
  String get elderOurLivingHistory => 'हमारा जीवंत इतिहास';

  @override
  String get elderLivingHistorySubtitle =>
      'दैवज्ञ समाज की तस्वीरें, चार्टर और मौखिक इतिहास';

  @override
  String get elderUploadMemory => 'स्मृति अपलोड करें';

  @override
  String get elderUploadMemoryToast =>
      'स्मृति अपलोड - योगदानकर्ता फ़ॉर्म खुल रहा है';

  @override
  String elderContributedBy(String name) {
    return '$name द्वारा योगदान किया गया';
  }

  @override
  String get elderClose => 'बंद करें';

  @override
  String get elderTagCultural => 'सांस्कृतिक';

  @override
  String get elderTagHeritage => 'विरासत';

  @override
  String get elderTagLineage => 'वंशावली';

  @override
  String get elderTagDevotional => 'आध्यात्मिक';

  @override
  String get elderMem1Title => '1968 कुमटा में समाज उत्सव';

  @override
  String get elderMem1Caption =>
      'पहला अंतर-गाँव समाज उत्सव जिसने कुमटा, कुंदापुरा और होन्नावर के स्वर्णकार परिवारों को एक साथ लाया।';

  @override
  String get elderMem1Contributor => 'वेंकटेश हलदणकर';

  @override
  String get elderMem2Title => 'पहला समाज भवन, 1974';

  @override
  String get elderMem2Caption =>
      'बसवनगुडी में समुदाय द्वारा निर्मित समाज भवन का उद्घाटन - पूरी तरह सदस्यों के योगदान से वित्तपोषित।';

  @override
  String get elderMem2Contributor => 'श्री नारायणराव सुवर्ण';

  @override
  String get elderMem3Title => 'स्वर्णकार गिल्ड चार्टर, 1952';

  @override
  String get elderMem3Caption =>
      'दैवज्ञ स्वर्णकार गिल्ड का संस्थापक चार्टर, तटीय जिलों के 28 मास्टर कारीगरों द्वारा हस्ताक्षरित।';

  @override
  String get elderMem3Contributor => 'समाज अभिलेखागार समिति';

  @override
  String get elderMem4Title => 'वार्षिक उत्सव 1992';

  @override
  String get elderMem4Caption =>
      'कर्नाटक संगीत प्रस्तुतियाँ और बुजुर्ग सम्मान समारोह जिसने तीन पीढ़ियों में 600 से अधिक सदस्यों को आकर्षित किया।';

  @override
  String get elderMem4Contributor => 'रेखा दिवाकर';

  @override
  String get elderMem5Title => 'बुजुर्ग सम्मान समारोह 2008';

  @override
  String get elderMem5Caption =>
      'प्रत्येक शाखा के सबसे वरिष्ठ सदस्यों को शॉल और पारंपरिक स्वर्ण पदक से सम्मानित करना।';

  @override
  String get elderMem5Contributor => 'लक्ष्मी रेवणकर';

  @override
  String get elderMem6Title => 'मंदिर कुम्भाभिषेक 1981';

  @override
  String get elderMem6Caption =>
      'नवीनीकरण के बाद सामुदायिक मंदिर का अभिषेक, कुंदापुरा और उडुपी के पुजारियों के साथ।';

  @override
  String get elderMem6Contributor => 'पार्वती शिरोडकर';

  @override
  String get elderSettings => 'सेटिंग्स';

  @override
  String get elderManageEventsEyebrow => 'कार्यक्रम प्रबंधित करें';

  @override
  String get elderCommunityEvents => 'सामुदायिक कार्यक्रम';

  @override
  String get elderEventsSubtitle => 'सभी शाखाओं में दैवज्ञ समाज कार्यक्रम';

  @override
  String get elderAddEvent => 'कार्यक्रम जोड़ें';

  @override
  String get elderAddEventToast =>
      'नया कार्यक्रम - कार्यक्रम फ़ॉर्म खुल रहा है';

  @override
  String elderAttendeesExpected(int n) {
    return '$n उपस्थितगण अपेक्षित';
  }

  @override
  String get elderRsvp => 'RSVP';

  @override
  String get elderManage => 'प्रबंधित करें';

  @override
  String elderRsvpConfirmed(String title) {
    return 'RSVP पुष्टि की गई · $title';
  }

  @override
  String elderManaging(String title) {
    return 'प्रबंधित कर रहे हैं · $title';
  }

  @override
  String get elderCommitteePreferences => 'समिति प्राथमिकताएं';

  @override
  String get elderCommitteePreferencesSubtitle =>
      'बुजुर्ग समिति के लिए अधिसूचना और रजिस्ट्री सेटिंग्स';

  @override
  String get elderEventReminders => 'कार्यक्रम अनुस्मारक';

  @override
  String get elderEventRemindersSubtitle =>
      'प्रत्येक कार्यक्रम से 7 दिन पहले सभी शाखा प्रमुखों को सूचित करें';

  @override
  String get elderEventRemindersOn => 'कार्यक्रम अनुस्मारक चालू';

  @override
  String get elderEventRemindersOff => 'कार्यक्रम अनुस्मारक बंद';

  @override
  String get elderAutoApproveRsvps => 'स्वतः-स्वीकृत RSVP';

  @override
  String get elderAutoApproveRsvpsSubtitle =>
      'सत्यापित सदस्यों की बिना समीक्षा पुष्टि की जाती है';

  @override
  String get elderAutoApproveOn => 'स्वतः-स्वीकृति चालू';

  @override
  String get elderAutoApproveOff => 'स्वतः-स्वीकृति बंद';

  @override
  String get elderPublishToPublicCalendar =>
      'सार्वजनिक कैलेंडर पर प्रकाशित करें';

  @override
  String get elderPublishToPublicCalendarSubtitle =>
      'पोर्टल लैंडिंग पेज पर आगामी समाज कार्यक्रम दिखाएं';

  @override
  String get elderPublicCalendarOn => 'सार्वजनिक कैलेंडर चालू';

  @override
  String get elderPublicCalendarOff => 'सार्वजनिक कैलेंडर बंद';

  @override
  String get elderTypeCultural => 'सांस्कृतिक';

  @override
  String get elderTypeAdmin => 'प्रशासन';

  @override
  String get elderTypeEducation => 'शिक्षा';

  @override
  String get elderTypeCommunity => 'समुदाय';

  @override
  String get elderStatusUpcoming => 'आगामी';

  @override
  String get elderStatusPlanning => 'योजना';

  @override
  String get elderEvent1Title => 'वार्षिक समाज उत्सव 2025';

  @override
  String get elderEvent1Venue => 'समाज भवन, बसवनगुडी, बैंगलोर';

  @override
  String get elderEvent2Title => 'बुजुर्ग समिति बैठक - तिमाही 3';

  @override
  String get elderEvent2Venue => 'समिति कक्ष, समाज भवन';

  @override
  String get elderEvent3Title => 'विद्या निधि छात्रवृत्ति दिवस';

  @override
  String get elderEvent3Venue => 'एसडीएम कॉलेज सभागार, मंगलुरु';

  @override
  String get elderEvent4Title => 'दैवज्ञ वैवाहिक मिलन';

  @override
  String get elderEvent4Venue => 'वीआर मॉल कन्वेंशन, बैंगलोर';

  @override
  String get elderConflictResolution => 'विवाद समाधान';

  @override
  String get elderConflictNotFound => 'विवाद मामला नहीं मिला';

  @override
  String get elderBackToOverview => 'अवलोकन पर वापस जाएं';

  @override
  String elderCaseId(String id) {
    return 'मामला #$id';
  }

  @override
  String elderBornDied(String born, String died) {
    return '$born - $died';
  }

  @override
  String get elderResolution => 'समाधान';

  @override
  String get elderMergeResolve => 'मर्ज करें और हल करें';

  @override
  String get elderMergeSubmitted => 'रिकॉर्ड मर्ज समीक्षा के लिए सबमिट किए गए';

  @override
  String get elderEscalate => 'आगे बढ़ाएं';

  @override
  String get elderEscalated => 'मामला बुजुर्ग समिति को भेजा गया';

  @override
  String get elderOnlyEldersResolve =>
      'केवल सत्यापित बुजुर्ग ही विवाद हल कर सकते हैं';

  @override
  String get elderDiscussionThread => 'बुजुर्ग चर्चा थ्रेड';

  @override
  String get elderAddCommitteeNote => 'अपनी समिति टिप्पणी जोड़ें…';

  @override
  String get elderNotePosted => 'टिप्पणी थ्रेड पर पोस्ट की गई';

  @override
  String elderBackedByRecords(int n) {
    return 'रिकॉर्ड द्वारा समर्थित · $n गवाही';
  }

  @override
  String get elderEvidence => 'प्रमाण';

  @override
  String get elderSubmittedThisVersion => 'यह संस्करण सबमिट किया';

  @override
  String elderSupportThisVersion(int n) {
    return 'इस संस्करण का समर्थन करें ($n)';
  }

  @override
  String elderYouSupported(String label) {
    return 'आपने $label का समर्थन किया';
  }

  @override
  String get compConsentTitle => 'अनुकूलता सहमति';

  @override
  String get compConsentLoadError => 'आपकी सहमति सेटिंग्स लोड नहीं की जा सकीं';

  @override
  String get compBirthDataMatching => 'जन्म-डेटा मिलान';

  @override
  String get compBirthDataMatchingDesc =>
      'किसी अन्य सदस्य के साथ पारंपरिक जातक (10 पोरुथम) अनुकूलता की गणना के लिए आपकी जन्म तिथि, समय और स्थान का उपयोग करें।';

  @override
  String get compCouldNotSaveRetry =>
      'इसे सहेजा नहीं जा सका। फिर से प्रयास करें।';

  @override
  String get compPolicyUpdatedNote =>
      'पिछली बार आपकी सहमति के बाद से हमारी सहमति नीति अपडेट की गई है - फिर से पुष्टि करने के लिए इसे वापस चालू करें।';

  @override
  String get compAllowed => 'अनुमति है';

  @override
  String get compNotAllowed => 'अनुमति नहीं है';

  @override
  String compGrantedOn(String date) {
    return '$date को दी गई';
  }

  @override
  String get compReportTitle => 'अनुकूलता रिपोर्ट';

  @override
  String get compReportLoadError => 'अनुकूलता रिपोर्ट लोड नहीं की जा सकी';

  @override
  String get compTryAgain => 'फिर से प्रयास करें';

  @override
  String get compYou => 'आप';

  @override
  String get compThisMember => 'यह सदस्य';

  @override
  String get compErrorGenericMissingRoleMine =>
      'पहले प्रोफ़ाइल → संपादित करें में अपना लिंग जोड़ें - यह आपकी पारंपरिक दुल्हन/दूल्हे की भूमिका तय करता है।';

  @override
  String get compErrorGenericMissingRoleTheirs =>
      'इस सदस्य की प्रोफ़ाइल में लिंग दर्ज नहीं है, इसलिए उनकी पारंपरिक भूमिका निर्धारित नहीं की जा सकती।';

  @override
  String get compErrorCalcFailed => 'अभी अनुकूलता की गणना नहीं की जा सकी।';

  @override
  String get compRecalculate => 'पुनः गणना करें';

  @override
  String get compRetry => 'पुनः प्रयास करें';

  @override
  String get compCalculateCompatibility => 'अनुकूलता की गणना करें';

  @override
  String get compYourConsentBirthData => 'आपकी सहमति · जन्म-डेटा मिलान';

  @override
  String get compAllowedRequiredForCalc => 'अनुमति है - इस गणना के लिए आवश्यक।';

  @override
  String get compPolicyChangedReconfirm =>
      'हमारी सहमति नीति बदल गई - कृपया फिर से पुष्टि करें।';

  @override
  String get compNotAllowedYet => 'अभी अनुमति नहीं है - गणना से पहले आवश्यक।';

  @override
  String get compManage => 'प्रबंधित करें';

  @override
  String get compReview => 'समीक्षा करें';

  @override
  String get compTraditionalRoleUnknown => 'पारंपरिक भूमिका अज्ञात';

  @override
  String get compGoToProfile => 'प्रोफ़ाइल पर जाएं';

  @override
  String get compYourBirthDetailsIncomplete => 'आपके जन्म विवरण अधूरे हैं';

  @override
  String get compTheirBirthDetailsIncomplete => 'उनके जन्म विवरण अधूरे हैं';

  @override
  String get compAddBirthDetailsBody =>
      'जातक मिलान की गणना के लिए अपना सटीक जन्म समय और स्थान जोड़ें।';

  @override
  String get compTheirBirthDetailsBody =>
      'यह सदस्य अभी तक अपने जन्म विवरण पूरे नहीं किए हैं - बाद में देखें।';

  @override
  String get compAddBirthDetailsAction => 'जन्म विवरण जोड़ें';

  @override
  String get compYourConsentNeeded => 'आपकी सहमति की आवश्यकता है';

  @override
  String get compTheirConsentNeeded => 'उनकी सहमति की आवश्यकता है';

  @override
  String get compYourConsentNeededBody =>
      'आपने अभी तक जन्म-डेटा मिलान की अनुमति नहीं दी है - यह जांच चलाने के लिए समीक्षा करें और अनुमति दें।';

  @override
  String get compTheirConsentNeededBody =>
      'इस सदस्य ने अभी तक जन्म-डेटा मिलान की अनुमति नहीं दी है।';

  @override
  String get compReviewConsent => 'सहमति की समीक्षा करें';

  @override
  String get compSomethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get compCheckReadinessError =>
      'अनुकूलता तत्परता की जांच नहीं की जा सकी';

  @override
  String get compCheckCompatibilityTitle => 'अनुकूलता जांचें';

  @override
  String compYouAnd(String name) {
    return 'आप × $name';
  }

  @override
  String get compSeeJatakaProfile => 'अपनी जातक और प्रोफ़ाइल अनुकूलता देखें।';

  @override
  String get compProfileCompatibility => 'प्रोफ़ाइल अनुकूलता';

  @override
  String get compSouthIndianJataka => 'दक्षिण भारतीय जातक';

  @override
  String get compChecking => 'अनुकूलता जांची जा रही है...';

  @override
  String get compCompleteHighlighted =>
      'अनुकूलता जांचने के लिए ऊपर हाइलाइट किए गए अनुभागों को पूरा करें।';

  @override
  String get compCantCheckYet =>
      'इस प्रोफ़ाइल के साथ अनुकूलता अभी जांची नहीं जा सकती।';

  @override
  String get compVerificationRequired => 'सत्यापन आवश्यक है।';

  @override
  String get compDataNotAvailableYet =>
      'इस अनुभाग के लिए अनुकूलता डेटा अभी उपलब्ध नहीं है।';

  @override
  String get compReady => 'तैयार';

  @override
  String get compMoreInfoNeeded => 'अधिक जानकारी आवश्यक है';

  @override
  String get compNotAvailableYet => 'अभी उपलब्ध नहीं';

  @override
  String get compCheckingEllipsis => 'अनुकूलता जांची जा रही है...';

  @override
  String get compBirthDetailsRequired => 'जन्म विवरण आवश्यक है।';

  @override
  String get compAddBirthDetailsBtn => 'जन्म विवरण जोड़ें';

  @override
  String get compPermissionRequired => 'अनुकूलता अनुमति आवश्यक है।';

  @override
  String get compManageConsent => 'सहमति प्रबंधित करें';

  @override
  String get compCompleteAFewQuestions => 'कुछ अनुकूलता प्रश्न पूरे करें।';

  @override
  String get compCompleteQuestions => 'प्रश्न पूरे करें';

  @override
  String get compFamilyTreeIncompleteBody =>
      'इसे सक्षम करने के लिए कुछ और पारिवारिक संबंध जोड़ें।';

  @override
  String get compUpdateFamilyTree => 'वंश वृक्ष अपडेट करें';

  @override
  String get compDashboardLoadError => 'अनुकूलता डैशबोर्ड लोड नहीं किया जा सका';

  @override
  String get compMarriageCompatibility => 'विवाह अनुकूलता';

  @override
  String compPdfSaved(String name) {
    return 'PDF सहेजा गया: $name';
  }

  @override
  String get compDownloadNotifTitle => 'डाउनलोड पूर्ण';

  @override
  String compDownloadNotifBody(String name) {
    return '$name तैयार है - खोलने के लिए टैप करें';
  }

  @override
  String get compPdfGenerateError =>
      'PDF जनरेट नहीं किया जा सका। कृपया पुनः प्रयास करें।';

  @override
  String get compPdfShareError =>
      'PDF साझा नहीं किया जा सका। कृपया पुनः प्रयास करें।';

  @override
  String compShareSubject(String myName, String otherName) {
    return 'विवाह अनुकूलता रिपोर्ट - $myName × $otherName';
  }

  @override
  String get compRetryAction => 'पुनः प्रयास करें';

  @override
  String get compOverallCompatibility => 'समग्र अनुकूलता';

  @override
  String get compAstrologyCompatibility => 'ज्योतिष अनुकूलता';

  @override
  String get compNotEnoughProfileInfo => 'पर्याप्त प्रोफ़ाइल जानकारी नहीं';

  @override
  String get compNotEnoughAstrologyInfo => 'पर्याप्त ज्योतिष जानकारी नहीं';

  @override
  String get compAstrologySummary => 'ज्योतिष सारांश';

  @override
  String get compKarnatakaPorutham => 'कर्नाटक 10 पोरुथम';

  @override
  String get compAshtakootaGuna => 'अष्टकूट 36 गुण';

  @override
  String get compUnavailable => 'अनुपलब्ध';

  @override
  String get compViewDetailedReport => 'विस्तृत रिपोर्ट देखें';

  @override
  String get compGenerating => 'जनरेट हो रहा है…';

  @override
  String get compDownloadPdf => 'PDF डाउनलोड करें';

  @override
  String get compShareReport => 'रिपोर्ट साझा करें';

  @override
  String get compCalculated => 'गणना की गई';

  @override
  String get compReviewRequired => 'समीक्षा आवश्यक';

  @override
  String get compNotAvailable => 'उपलब्ध नहीं';

  @override
  String get discSortBestMatch => 'सर्वश्रेष्ठ मेल';

  @override
  String get discSortNewest => 'नवीनतम';

  @override
  String get discSortAgeLowHigh => 'आयु: कम से अधिक';

  @override
  String get discSortAgeHighLow => 'आयु: अधिक से कम';

  @override
  String get discTitle => 'मेल खोजें';

  @override
  String get discCouldNotLoad => 'मेल लोड नहीं किए जा सके';

  @override
  String get discCouldNotLoadMore => 'और मेल लोड नहीं किए जा सके';

  @override
  String get discMatch => ' मेल';

  @override
  String get discMatches => ' मेल';

  @override
  String discFilterCount(int n) {
    return 'फ़िल्टर ($n)';
  }

  @override
  String get discFilter => 'फ़िल्टर';

  @override
  String discSortLabel(String label) {
    return 'क्रमबद्ध करें: $label';
  }

  @override
  String get discLoadMore => 'और लोड करें';

  @override
  String get discNoMatchesYet => 'अभी दिखाने के लिए कोई मेल नहीं';

  @override
  String get discCompletePreferences =>
      'बेहतर मेल के लिए अपनी विवाह प्राथमिकताएं और रुचियां पूरी करें।';

  @override
  String get discNoMatchesForFilters =>
      'इन फ़िल्टरों के लिए कोई मेल नहीं मिला।';

  @override
  String get discClearFilters => 'फ़िल्टर साफ़ करें';

  @override
  String get discIntroBody =>
      'आपकी विवाह प्राथमिकताओं, भोजन, रुचियों, स्थान और आयु के अनुसार प्रत्येक प्रोफ़ाइल कितनी उपयुक्त है, उसके अनुसार क्रमबद्ध - सबसे अच्छा मेल पहले।';

  @override
  String get discMatchLabel => 'मेल';

  @override
  String get discViewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get purohitTitle => 'पुरोहित';

  @override
  String get purohitCouldNotLoad => 'पुरोहित लोड नहीं हो सके।';

  @override
  String get purohitCouldNotLoadTitle => 'पुरोहित लोड नहीं हो सके';

  @override
  String get purohitNoneYet => 'अभी तक कोई पुरोहित नहीं';

  @override
  String get purohitNoneYetBody =>
      'जो सदस्य पंजीकरण के समय स्वयं को पुरोहित बताते हैं, वे यहाँ दिखाई देंगे।';

  @override
  String purohitKmAway(String km) {
    return '$km किमी दूर';
  }

  @override
  String get jatakaTitle => 'साउथ इंडियन जातक';

  @override
  String get jatakaLoadError => 'अभी साउथ इंडियन जातक परिणाम लोड नहीं हो सका।';

  @override
  String get jatakaReviewRequired => 'समीक्षा आवश्यक';

  @override
  String get jatakaReviewRequiredBody =>
      'जन्म-समय की अनिश्चितता के कारण कुछ गणनाओं की समीक्षा आवश्यक है।';

  @override
  String get jatakaNotCalculableTitle => 'अभी गणना योग्य नहीं';

  @override
  String get jatakaNotCalculableBody =>
      'साउथ इंडियन जातक अनुकूलता की गणना नहीं की जा सकी। आमतौर पर ऐसा तब होता है जब जन्म विवरण अनुपलब्ध हो, आवश्यक सहमति न दी गई हो, या ज्योतिष नियम अभी प्रकाशित न हुए हों।';

  @override
  String get jatakaNoKarnatakaTitle => 'कोई कर्नाटक पोरुथम परिणाम नहीं';

  @override
  String get jatakaNoKarnatakaBody =>
      'इस रिपोर्ट में साउथ इंडियन जातक परिणाम शामिल नहीं है।';

  @override
  String get jatakaSectionLabel => 'साउथ इंडियन जातक';

  @override
  String get jatakaKarnataka10Porutham => 'कर्नाटक 10 पोरुथम';

  @override
  String jatakaMatchedOf(String matched, String total) {
    return '$matched/$total मेल';
  }

  @override
  String jatakaRuleVersion(String version) {
    return 'नियम संस्करण: $version';
  }

  @override
  String get jatakaChipMatched => 'मेल';

  @override
  String get jatakaChipPartial => 'आंशिक';

  @override
  String get jatakaChipNotMatched => 'मेल नहीं';

  @override
  String get jatakaChipReview => 'समीक्षा';

  @override
  String get jatakaChipUnavailable => 'अनुपलब्ध';

  @override
  String get jatakaCriticalChecks => 'महत्वपूर्ण जाँच';

  @override
  String get jatakaRajju => 'रज्जु';

  @override
  String get jatakaVedha => 'वेध';

  @override
  String get jatakaStatusMatched => 'मेल';

  @override
  String get jatakaStatusPartial => 'आंशिक';

  @override
  String get jatakaStatusNotMatched => 'मेल नहीं';

  @override
  String get jatakaStatusReviewRequired => 'समीक्षा आवश्यक';

  @override
  String get jatakaStatusUnavailable => 'अनुपलब्ध';

  @override
  String get jatakaStatusUnknown => 'अज्ञात';

  @override
  String get jatakaThe10Poruthams => '10 पोरुथम';

  @override
  String get jatakaAshtakootaLabel => 'अष्टकूट / 36 गुण';

  @override
  String get jatakaAshtakootaUnavailable => 'अष्टकूट गणना फिलहाल अनुपलब्ध है।';

  @override
  String get jatakaOverallScore => 'समग्र ज्योतिष स्कोर';

  @override
  String get birthTitle => 'जन्म विवरण';

  @override
  String get birthCouldNotLoad => 'आपका जन्म विवरण लोड नहीं हो सका';

  @override
  String get birthCouldNotSave => 'आपका जन्म विवरण सहेजा नहीं जा सका';

  @override
  String get birthDisclaimer =>
      'केवल साउथ इंडियन जातक और कुंडली अनुकूलता जाँच के लिए उपयोग किया जाता है - आपकी सार्वजनिक प्रोफ़ाइल पर कभी नहीं दिखाया जाता।';

  @override
  String get birthFromProfile => 'आपकी प्रोफ़ाइल से';

  @override
  String get birthDateOfBirth => 'जन्म तिथि';

  @override
  String get birthNotSet => 'सेट नहीं';

  @override
  String get birthTraditionalRole => 'पारंपरिक भूमिका';

  @override
  String get birthSetGender =>
      'प्रोफ़ाइल → संपादित करें में अपना लिंग सेट करें';

  @override
  String get birthBirthplace => 'जन्मस्थान';

  @override
  String get birthCityLabel => 'जन्म शहर';

  @override
  String get birthCityHint => 'उदा. मैसूरु, कर्नाटक, भारत';

  @override
  String get birthTimeOfBirth => 'जन्म का समय';

  @override
  String get birthTimePickerHelp => 'जन्म का समय';

  @override
  String get birthDerivedAutomatically => 'स्वचालित रूप से प्राप्त';

  @override
  String birthLatLon(String lat, String lon, String tz) {
    return 'अक्षांश/देशांतर: $lat, $lon\nसमय क्षेत्र: $tz';
  }

  @override
  String get birthTimeAccuracy => 'जन्म-समय की सटीकता';

  @override
  String get birthSelectAccuracy => 'सटीकता चुनें';

  @override
  String get birthSaving => 'सहेजा जा रहा है…';

  @override
  String get birthSaveButton => 'जन्म विवरण सहेजें';

  @override
  String get birthSaved => 'जन्म विवरण सहेजा गया';

  @override
  String get birthAddDob =>
      'पहले प्रोफ़ाइल → संपादित करें में अपनी जन्मतिथि जोड़ें।';

  @override
  String get birthAddGender =>
      'पहले प्रोफ़ाइल → संपादित करें में अपना लिंग जोड़ें - यह आपकी पारंपरिक वर/वधू भूमिका तय करता है।';

  @override
  String get birthSearchPlace =>
      'अपने जन्मस्थान की खोज करें और सुझावों में से चुनें।';

  @override
  String get birthInvalidLatitude =>
      'उस जन्मस्थान का अक्षांश अमान्य है - फिर से खोजने का प्रयास करें।';

  @override
  String get birthInvalidLongitude =>
      'उस जन्मस्थान का देशांतर अमान्य है - फिर से खोजने का प्रयास करें।';

  @override
  String get birthNoTimezone =>
      'उस स्थान के लिए समय क्षेत्र निर्धारित नहीं किया जा सका - देश सहित अधिक विशिष्ट खोज करें।';

  @override
  String get birthChooseAccuracy =>
      'चुनें कि आप जन्म के समय के बारे में कितने आश्वस्त हैं।';

  @override
  String get birthAddTimeOrUnknown =>
      'जन्म का समय जोड़ें, या यदि यह वास्तव में ज्ञात नहीं है तो सटीकता को \"अज्ञात\" पर सेट करें।';

  @override
  String get birthAccuracyExactDocument =>
      'सटीक - किसी दस्तावेज़ (जैसे जन्म प्रमाण पत्र) द्वारा सत्यापित';

  @override
  String get birthAccuracyExactFamily => 'सटीक - परिवार द्वारा पुष्टि की गई';

  @override
  String get birthAccuracyApprox15 => 'अनुमानित - 15 मिनट के भीतर';

  @override
  String get birthAccuracyApprox30 => 'अनुमानित - 30 मिनट के भीतर';

  @override
  String get birthAccuracyApprox60 => 'अनुमानित - 60 मिनट के भीतर';

  @override
  String get birthAccuracyUnknown => 'अज्ञात';

  @override
  String get cameraNoneAvailable => 'इस डिवाइस पर कोई कैमरा उपलब्ध नहीं है।';

  @override
  String cameraUnavailable(String error) {
    return 'कैमरा अनुपलब्ध: $error';
  }

  @override
  String get cameraPermissionRequired =>
      'कैमरा अनुमति आवश्यक है। इसे सेटिंग्स में सक्षम करें।';

  @override
  String cameraCouldNotStart(String error) {
    return 'कैमरा शुरू नहीं हो सका: $error';
  }

  @override
  String get cameraCouldNotTakePhoto => 'फोटो नहीं लिया जा सका।';

  @override
  String get cameraCouldNotStartRecording => 'रिकॉर्डिंग शुरू नहीं हो सकी।';

  @override
  String get cameraCouldNotSaveRecording => 'रिकॉर्डिंग सहेजी नहीं जा सकी।';

  @override
  String get cameraReleaseToStop => 'रोकने के लिए छोड़ें';

  @override
  String get cameraTapOrHold =>
      'फोटो के लिए टैप करें  ·  रिकॉर्ड करने के लिए दबाए रखें';

  @override
  String get digilockerVerifyTitle => 'डिजिलॉकर से सत्यापित करें';

  @override
  String postCouldNotPickMedia(String error) {
    return 'मीडिया चुना नहीं जा सका: $error';
  }

  @override
  String get postAuthorFallback => 'आप';

  @override
  String get postReelShared => 'रील साझा की गई 🎬';

  @override
  String get postShared => 'पोस्ट साझा की गई ✨';

  @override
  String postUploadFailed(String reason) {
    return 'अपलोड विफल: $reason';
  }

  @override
  String get postCheckConnection => 'अपना कनेक्शन जाँचें';

  @override
  String get postNewReel => 'नई रील';

  @override
  String get postNewPost => 'नई पोस्ट';

  @override
  String get postCaptionHint => 'कैप्शन लिखें…';

  @override
  String get postDefaultReelCaption => 'नई रील';

  @override
  String get postDefaultPostCaption => 'नई पोस्ट';

  @override
  String get postLocating => 'स्थान ढूँढा जा रहा है…';

  @override
  String get postCurrentLocation => 'वर्तमान स्थान';

  @override
  String get postCouldNotGetLocation => 'आपका स्थान प्राप्त नहीं हो सका।';

  @override
  String get postRemoveLocation => 'स्थान हटाएं';

  @override
  String get postShareButton => 'साझा करें';

  @override
  String get storyVisFamilyFollowers => 'परिवार और फ़ॉलोअर्स';

  @override
  String get storyVisOnlyMe => 'केवल मैं';

  @override
  String get storyVisCommunity => 'वंश समुदाय';

  @override
  String get storyTagFamilyMembers => 'परिवार के सदस्यों को टैग करें';

  @override
  String get storyLinkAncestor => 'किसी पूर्वज से लिंक करें';

  @override
  String get storyWhoCanSee => 'इस स्टोरी को कौन देख सकता है?';

  @override
  String get storyVisCommunityDesc => 'समाज में सभी';

  @override
  String get storyVisFollowersDesc => 'आपसे जुड़े लोग';

  @override
  String get storyVisPrivateDesc => 'निजी - कोई और नहीं देख सकता';

  @override
  String get storyShared => 'स्टोरी साझा की गई - 24 घंटे के लिए लाइव ✨';

  @override
  String storyCouldNotPost(String reason) {
    return 'पोस्ट नहीं हो सकी: $reason';
  }

  @override
  String get storyPleaseTryAgain => 'कृपया पुनः प्रयास करें';

  @override
  String storyComingSoon(String label) {
    return '$label - जल्द आ रहा है';
  }

  @override
  String get storyShareTitle => 'स्टोरी साझा करें';

  @override
  String get storyHelp => 'सहायता';

  @override
  String get storyReviewRecording => 'अपनी रिकॉर्डिंग की समीक्षा करें';

  @override
  String get storyReviewPhoto => 'अपनी फोटो की समीक्षा करें';

  @override
  String get storyCaption => 'कैप्शन';

  @override
  String get storyCaptionHint =>
      'इस पारिवारिक स्मृति के बारे में एक कैप्शन लिखें…';

  @override
  String get storySearchVamshaVruksha => 'अपने वंश वृक्ष में खोजें';

  @override
  String get storyAddLocation => 'स्थान जोड़ें';

  @override
  String get storyLocationSubtitle => 'गाँव, मंदिर, या सामुदायिक केंद्र';

  @override
  String get storyLinkToTreeNode => 'वंश वृक्ष नोड से लिंक करें';

  @override
  String get storyAttachAncestor => 'इस स्टोरी को किसी पूर्वज से जोड़ें';

  @override
  String storyLinkedTo(String name) {
    return '$name से जुड़ा हुआ';
  }

  @override
  String get storyAdvancedSettings => 'उन्नत सेटिंग्स';

  @override
  String get storyVisibleTo => 'इन्हें दिखाई देगा';

  @override
  String get storyPostToCommunity => 'समुदाय में पोस्ट करें';

  @override
  String get storyDrafts => 'ड्राफ्ट';

  @override
  String get storyLocationHint => 'उदा. कुमटा, महालसा मंदिर…';

  @override
  String get storyKindVillage => 'गाँव';

  @override
  String get storyKindTemple => 'मंदिर';

  @override
  String get storyKindCommunityCenter => 'सामुदायिक केंद्र';

  @override
  String get storyKindOther => 'अन्य';

  @override
  String storyAgoMinutesCompact(int n) {
    return '$nमि';
  }

  @override
  String storyAgoHoursCompact(int n) {
    return '$nघं';
  }

  @override
  String storyAgoDaysCompact(int n) {
    return '$nदि';
  }

  @override
  String get storyDeleteTitle => 'स्टोरी हटाएं?';

  @override
  String get storyDeleteBody => 'यह इसे सभी के लिए हटा देगा।';

  @override
  String get storyDeleteAction => 'हटाएं';

  @override
  String get storyNoViewsYet => 'अभी तक कोई दृश्य नहीं';

  @override
  String storySeenByCount(int n) {
    return '$n ने देखा';
  }

  @override
  String get storyViewers => 'देखने वाले';

  @override
  String storyViewersCount(int n) {
    return 'देखने वाले · $n';
  }

  @override
  String get storyNoOneViewedYet => 'अभी तक किसी ने यह स्टोरी नहीं देखी है।';

  @override
  String get storyMemberFallback => 'सदस्य';

  @override
  String get chatMessageNotSent => 'संदेश नहीं भेजा गया';

  @override
  String get chatPhotosVideos => 'फोटो/वीडियो';

  @override
  String get chatCamera => 'कैमरा';

  @override
  String get chatDocuments => 'दस्तावेज़';

  @override
  String get chatCouldNotSendFile => 'फ़ाइल नहीं भेजी जा सकी';

  @override
  String get chatSayHello => 'नमस्ते कहें 👋';

  @override
  String get chatMessageHint => 'संदेश…';

  @override
  String get chatNoAppForFile => 'इस फ़ाइल को कोई ऐप नहीं खोल सका';

  @override
  String get chatDocumentFallback => 'दस्तावेज़';

  @override
  String get convMemberFallback => 'सदस्य';

  @override
  String get convMessages => 'संदेश';

  @override
  String get convNoMessagesYet => 'अभी तक कोई संदेश नहीं';

  @override
  String get convStartChatHint =>
      'चैट शुरू करने के लिए डायरेक्टरी से किसी सदस्य को संदेश भेजें।';

  @override
  String get convVideoLabel => '🎥 वीडियो';

  @override
  String get convDocumentLabel => '📄 दस्तावेज़';

  @override
  String get convPhotoLabel => '📷 फोटो';

  @override
  String get convTapToChat => 'चैट करने के लिए टैप करें';

  @override
  String commentCouldNotPost(String reason) {
    return 'टिप्पणी पोस्ट नहीं हो सकी: $reason';
  }

  @override
  String get commentCheckConnection => 'अपना कनेक्शन जाँचें';

  @override
  String get commentTitle => 'टिप्पणियाँ';

  @override
  String get commentNoneYet => 'अभी तक कोई टिप्पणी नहीं';

  @override
  String get commentStartConversation => 'बातचीत शुरू करें।';

  @override
  String get commentHint => 'एक टिप्पणी जोड़ें…  (टैग करने के लिए @ टाइप करें)';

  @override
  String get commentPosting => 'पोस्ट हो रहा है…';

  @override
  String get commentPost => 'पोस्ट करें';

  @override
  String commentLikeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n लाइक्स',
      one: '$n लाइक',
    );
    return '$_temp0';
  }

  @override
  String commentCouldNotLike(String reason) {
    return 'लाइक नहीं हो सका: $reason';
  }

  @override
  String get shareReel => 'रील';

  @override
  String get sharePost => 'पोस्ट';

  @override
  String get shareTitle => 'साझा करें';

  @override
  String get shareSendTo => 'इन्हें भेजें';

  @override
  String get shareLinkCopied => 'लिंक क्लिपबोर्ड पर कॉपी हो गया';

  @override
  String shareSentToMembers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n सदस्यों को भेजा गया 📩',
      one: '$n सदस्य को भेजा गया 📩',
    );
    return '$_temp0';
  }

  @override
  String get shareSendButton => 'भेजें';

  @override
  String get shareCopyLink => 'लिंक कॉपी करें';

  @override
  String get shareAddToStory => 'स्टोरी में जोड़ें';

  @override
  String get shareAddedToStory => 'आपकी स्टोरी में जोड़ा गया';

  @override
  String get shareViaEllipsis => 'इसके माध्यम से साझा करें…';

  @override
  String shareTextTemplate(
    String author,
    String kind,
    String caption,
    String link,
  ) {
    return '$author ने समाज पर एक $kind साझा की\n\"$caption\"\n\n$link';
  }

  @override
  String shareSubjectTemplate(String kind) {
    return 'समाज से एक $kind';
  }

  @override
  String get landOrgName => 'दैवज्ञ समाज';

  @override
  String get landEyebrow => 'दैवज्ञ समाज बैंगलोर - स्थापना 2024';

  @override
  String get landHeadline =>
      'अपनी जड़ों को संरक्षित करना,\nहमारे भविष्य का पोषण करना';

  @override
  String get landSubtitle =>
      'दैवज्ञ समाज का आधिकारिक डिजिटल आश्रय स्थल - पीढ़ियों को जोड़ना, विरासत को संरक्षित करना, और एक जीवंत वंश वृक्ष के माध्यम से सामुदायिक कल्याण का निर्माण करना।';

  @override
  String get landBeginJourney => 'अपनी यात्रा शुरू करें';

  @override
  String get landAccessPortal => 'पोर्टल एक्सेस करें';

  @override
  String get landFamilyLineagePreview => 'पारिवारिक वंशावली पूर्वावलोकन';

  @override
  String get landGenerationsTag => '4 पीढ़ियाँ';

  @override
  String get landMembersTag => '6 सदस्य';

  @override
  String get landUdupiBranch => 'उडुपी शाखा';

  @override
  String get landPillarFamilyTreeTitle => 'वंश वृक्ष';

  @override
  String get landPillarFamilyTreeDesc =>
      'पीढ़ियों में अपनी पारिवारिक वंशावली का दस्तावेज़ीकरण करें। फोटो अभिलेखागार, जीवन कहानियों और पैतृक संबंधों के साथ इंटरैक्टिव वृक्ष दृश्य।';

  @override
  String get landPillarWelfareTitle => 'सामुदायिक कल्याण';

  @override
  String get landPillarWelfareDesc =>
      'समाज विकास के लिए पारदर्शी क्राउडफंडिंग। हर रुपये का हिसाब - सामुदायिक केंद्र, छात्रवृत्ति, आपातकालीन सहायता।';

  @override
  String get landPillarMatrimonialTitle => 'वैवाहिक केंद्र';

  @override
  String get landPillarMatrimonialDesc =>
      'वंश और सांस्कृतिक समन्वय का सम्मान करने वाले बुजुर्ग-मध्यस्थ वैवाहिक संबंध। पूर्ण पारिवारिक पृष्ठभूमि के साथ सत्यापित प्रोफ़ाइल।';

  @override
  String get landPillarElderTitle => 'बुजुर्ग शासन';

  @override
  String get landPillarElderDesc =>
      'हमारे सम्मानित बुजुर्गों द्वारा निर्देशित सामुदायिक-संचालित निर्णय। संघर्षों को हल करें, सदस्यों को सत्यापित करें, और पीढ़ीगत ज्ञान के साथ शासन करें।';

  @override
  String get landExplore => 'अन्वेषण करें';

  @override
  String get landTrustEyebrow => 'पूर्ण विश्वास का एक घेरा';

  @override
  String get landTrustTitle => 'हर सदस्य, हर संबंध - सत्यापित।';

  @override
  String get landTrustAadhaarTitle => 'आधार सत्यापन';

  @override
  String get landTrustAadhaarDesc =>
      'हर सदस्य सरकार द्वारा जारी पहचान पत्र प्रस्तुत करता है। आधार-मिलान और डिजिटल रूप से पंजीकृत।';

  @override
  String get landTrustPeerTitle => 'सहकर्मी समर्थन';

  @override
  String get landTrustPeerDesc =>
      'नए सदस्यों की समाज नेटवर्क के भीतर 3 मौजूदा सत्यापित परिवार सदस्यों द्वारा पुष्टि की जाती है।';

  @override
  String get landTrustElderTitle => 'बुजुर्ग स्वीकृति';

  @override
  String get landTrustElderDesc =>
      'बुजुर्ग उप-समिति सभी वंश संबंधों और वैवाहिक अनुरोधों की समीक्षा और स्वीकृति देती है।';

  @override
  String get landQuote =>
      '\"एक वृक्ष उतना ही मजबूत होता है जितनी उसकी जड़ें। सत्यापन यह सुनिश्चित करता है कि आप जो विरासत बना रहे हैं वह प्रामाणिक और स्थायी है।\"';

  @override
  String get landQuoteAuthor => '- समाज विरासत परिषद';

  @override
  String get landFooterTagline => 'दैवज्ञ समाज सामुदायिक पोर्टल';

  @override
  String get landFooterPrivacy => 'गोपनीयता नीति';

  @override
  String get landFooterTerms => 'सेवा की शर्तें';

  @override
  String get landFooterHeritage => 'विरासत दिशानिर्देश';

  @override
  String get landFooterContact => 'व्यवस्थापक से संपर्क करें';

  @override
  String get landFooterGovernance => 'सामुदायिक शासन';

  @override
  String get landFooterCopyright =>
      '© 2024 दैवज्ञ समाज - पीढ़ियों के लिए विरासतों का संरक्षण।';

  @override
  String get reelSavedToProfile => 'आपकी प्रोफ़ाइल में सहेजा गया';

  @override
  String get reelRemovedFromSaved => 'सहेजे गए से हटाया गया';

  @override
  String get matchLevelExcellent => 'उत्कृष्ट मेल';

  @override
  String get matchLevelHigh => 'उच्च मेल';

  @override
  String get matchLevelGood => 'अच्छा मेल';

  @override
  String get matchLevelModerate => 'मध्यम मेल';

  @override
  String get matchLevelLow => 'कम मेल';

  @override
  String get matchBadgeMatch => 'मेल';

  @override
  String get matchFactorMarriageIntention => 'विवाह इरादा';

  @override
  String get matchFactorChildren => 'बच्चे';

  @override
  String get matchFactorFamilyType => 'परिवार प्रकार';

  @override
  String get matchFactorRelocation => 'स्थानांतरण';

  @override
  String get matchFactorFoodPreference => 'भोजन वरीयता';

  @override
  String get matchFactorInterests => 'रुचियाँ';

  @override
  String get matchFactorLocation => 'स्थान';

  @override
  String get matchFactorAge => 'आयु';

  @override
  String matchFactorNotEnoughInfo(String label) {
    return '$label - तुलना के लिए पर्याप्त जानकारी नहीं';
  }

  @override
  String matchFactorAligned(String label, int percentage) {
    return '$label - $percentage% मेल';
  }

  @override
  String get discFilterIntentionSoon => 'जल्द ही';

  @override
  String get discFilterIntentionOneToTwoYears => '1-2 वर्ष';

  @override
  String get discFilterIntentionNotDecided => 'तय नहीं';

  @override
  String get discFilterFoodVegetarian => 'शाकाहारी';

  @override
  String get discFilterFoodNonVegetarian => 'मांसाहारी';

  @override
  String get discFilterFoodEggetarian => 'अंडाहारी';

  @override
  String get discFilterFoodOther => 'अन्य';

  @override
  String get discFilterInterestTravel => 'यात्रा';

  @override
  String get discFilterInterestMusic => 'संगीत';

  @override
  String get discFilterInterestMovies => 'फिल्में';

  @override
  String get discFilterInterestFitness => 'फिटनेस';

  @override
  String get discFilterInterestSports => 'खेल';

  @override
  String get discFilterInterestReading => 'पढ़ना';

  @override
  String get discFilterInterestCooking => 'खाना बनाना';

  @override
  String get discFilterInterestSpirituality => 'आध्यात्मिकता';

  @override
  String get discFilterAny => 'कोई भी';

  @override
  String get discFilterTitle => 'फ़िल्टर';

  @override
  String get discFilterAgeSection => 'आयु';

  @override
  String get discFilterAgeFrom => 'आयु से';

  @override
  String get discFilterAgeTo => 'आयु तक';

  @override
  String get discFilterLocationSection => 'स्थान';

  @override
  String get discFilterLocationHint => 'पसंदीदा स्थान';

  @override
  String get discFilterMinMatchSection => 'न्यूनतम मेल';

  @override
  String get discFilterIntentionSection => 'विवाह इरादा';

  @override
  String get discFilterFoodSection => 'भोजन वरीयता';

  @override
  String get discFilterInterestsSection => 'रुचियाँ';

  @override
  String get discFilterClearAll => 'सभी साफ़ करें';

  @override
  String get discFilterApply => 'फ़िल्टर लागू करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonRemove => 'हटाएं';

  @override
  String get commonKeep => 'रखें';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonDone => 'पूर्ण';

  @override
  String get commonNext => 'अगला';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonSearch => 'खोजें';

  @override
  String get commonLanguage => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageKannada => 'ಕನ್ನಡ';

  @override
  String get permIntroTitle => 'शुरू करने से पहले';

  @override
  String get permIntroBody =>
      'कुछ अनुमतियाँ ऐप को सुचारू रूप से चलाने में मदद करती हैं। आप इन्हें बाद में अपने फ़ोन की सेटिंग्स में बदल सकते हैं।';

  @override
  String get permMediaTitle => 'फ़ोटो और वीडियो';

  @override
  String get permMediaBody =>
      'अपनी पोस्ट, स्टोरी और प्रोफ़ाइल में फ़ोटो और वीडियो जोड़ने के लिए।';

  @override
  String get permNotificationTitle => 'सूचनाएं';

  @override
  String get permNotificationBody =>
      'परिवार अनुरोध, संदेश और सामुदायिक अपडेट के बारे में बताने के लिए।';

  @override
  String get permLocationTitle => 'स्थान';

  @override
  String get permLocationBody =>
      'आपकी पोस्ट पर स्थान टैग करने और आस-पास के समाज सदस्यों को खोजने के लिए।';

  @override
  String get permRequesting => 'अनुरोध किया जा रहा है…';

  @override
  String get permContinue => 'जारी रखें';

  @override
  String get permSkip => 'अभी के लिए छोड़ें';
}
