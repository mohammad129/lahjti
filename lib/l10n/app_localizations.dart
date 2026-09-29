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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lahjti'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @startYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey'**
  String get startYourJourney;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseYourLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tutor.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get tutor;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'A minor glitch occurred. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature is currently in development.'**
  String get comingSoonDesc;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Speak it... don\'t just memorize it.'**
  String get welcomeTagline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI tutor is with you: listens, speaks, and corrects you.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeButtonCta.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey 🚀'**
  String get welcomeButtonCta;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get connectionError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @unauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get unauthorizedError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again shortly.'**
  String get serverError;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No Data Found'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'There is nothing here yet.'**
  String get emptyStateMessage;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @targetLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Which language do you want to learn?'**
  String get targetLanguageTitle;

  /// No description provided for @targetLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you want to speak with confidence.'**
  String get targetLanguageSubtitle;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @langItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get langItalian;

  /// No description provided for @langTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get langTurkish;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJapanese;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get langChinese;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKorean;

  /// No description provided for @ageGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get ageGroupTitle;

  /// No description provided for @ageGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will use your age to tailor the learning style and content for you.'**
  String get ageGroupSubtitle;

  /// No description provided for @age6_10.
  ///
  /// In en, this message translates to:
  /// **'6–10'**
  String get age6_10;

  /// No description provided for @age11_14.
  ///
  /// In en, this message translates to:
  /// **'11–14'**
  String get age11_14;

  /// No description provided for @age15_18.
  ///
  /// In en, this message translates to:
  /// **'15–18'**
  String get age15_18;

  /// No description provided for @age19_25.
  ///
  /// In en, this message translates to:
  /// **'19–25'**
  String get age19_25;

  /// No description provided for @age26_35.
  ///
  /// In en, this message translates to:
  /// **'26–35'**
  String get age26_35;

  /// No description provided for @age36_50.
  ///
  /// In en, this message translates to:
  /// **'36–50'**
  String get age36_50;

  /// No description provided for @age50Plus.
  ///
  /// In en, this message translates to:
  /// **'50+'**
  String get age50Plus;

  /// No description provided for @nativeLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your native language?'**
  String get nativeLanguageTitle;

  /// No description provided for @nativeLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us explain and translate concepts in the clearest way.'**
  String get nativeLanguageSubtitle;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @langOther.
  ///
  /// In en, this message translates to:
  /// **'Other Language'**
  String get langOther;

  /// No description provided for @learningGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to learn this language?'**
  String get learningGoalTitle;

  /// No description provided for @learningGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will focus your conversations and exercises around your primary goal.'**
  String get learningGoalSubtitle;

  /// No description provided for @goalStudy.
  ///
  /// In en, this message translates to:
  /// **'Academics & Study'**
  String get goalStudy;

  /// No description provided for @goalStudyDesc.
  ///
  /// In en, this message translates to:
  /// **'For university, school, and academic examinations'**
  String get goalStudyDesc;

  /// No description provided for @goalWork.
  ///
  /// In en, this message translates to:
  /// **'Career & Work'**
  String get goalWork;

  /// No description provided for @goalWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'For business meetings, workplace, and job interviews'**
  String get goalWorkDesc;

  /// No description provided for @goalTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel & Exploration'**
  String get goalTravel;

  /// No description provided for @goalTravelDesc.
  ///
  /// In en, this message translates to:
  /// **'For airports, hotels, and exploring countries with ease'**
  String get goalTravelDesc;

  /// No description provided for @goalConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversational Fluency'**
  String get goalConversation;

  /// No description provided for @goalConversationDesc.
  ///
  /// In en, this message translates to:
  /// **'To overcome hesitation and speak naturally with people'**
  String get goalConversationDesc;

  /// No description provided for @goalDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Life'**
  String get goalDaily;

  /// No description provided for @goalDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'To connect with friends and enjoy media/content'**
  String get goalDailyDesc;

  /// No description provided for @goalHobby.
  ///
  /// In en, this message translates to:
  /// **'Personal Interest'**
  String get goalHobby;

  /// No description provided for @goalHobbyDesc.
  ///
  /// In en, this message translates to:
  /// **'A passion for learning a rich and exciting new language'**
  String get goalHobbyDesc;

  /// No description provided for @goalComprehensive.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Mastery'**
  String get goalComprehensive;

  /// No description provided for @goalComprehensiveDesc.
  ///
  /// In en, this message translates to:
  /// **'To build all skills including grammar, vocabulary, and pronunciation'**
  String get goalComprehensiveDesc;

  /// No description provided for @experienceTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you know about the language?'**
  String get experienceTitle;

  /// No description provided for @experienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries, this simply helps us start you in the right place.'**
  String get experienceSubtitle;

  /// No description provided for @expZeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost not a word'**
  String get expZeroTitle;

  /// No description provided for @expZeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Awesome! We will start with you from the very beginning.'**
  String get expZeroDesc;

  /// No description provided for @expBasicTitle.
  ///
  /// In en, this message translates to:
  /// **'I know basic words'**
  String get expBasicTitle;

  /// No description provided for @expBasicDesc.
  ///
  /// In en, this message translates to:
  /// **'Great! We will build upon the vocabulary you already know.'**
  String get expBasicDesc;

  /// No description provided for @expIntermediateTitle.
  ///
  /// In en, this message translates to:
  /// **'I understand & speak a bit'**
  String get expIntermediateTitle;

  /// No description provided for @expIntermediateDesc.
  ///
  /// In en, this message translates to:
  /// **'Nice! We will focus on speech flow and conversational speed.'**
  String get expIntermediateDesc;

  /// No description provided for @expConversationalTitle.
  ///
  /// In en, this message translates to:
  /// **'I can have simple conversations'**
  String get expConversationalTitle;

  /// No description provided for @expConversationalDesc.
  ///
  /// In en, this message translates to:
  /// **'Great! We will level you up to deeper topics and richer phrases.'**
  String get expConversationalDesc;

  /// No description provided for @expAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'I am advanced'**
  String get expAdvancedTitle;

  /// No description provided for @expAdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Excellent! We will polish your dialect and bring you to native fluency.'**
  String get expAdvancedDesc;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress and practice with your tutor anytime.'**
  String get registerSubtitle;

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

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get confirmPasswordHint;

  /// No description provided for @valNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get valNameRequired;

  /// No description provided for @valEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get valEmailInvalid;

  /// No description provided for @valPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get valPasswordWeak;

  /// No description provided for @valPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get valPasswordsDoNotMatch;

  /// No description provided for @tutorSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Who would you like your tutor to be?'**
  String get tutorSelectionTitle;

  /// No description provided for @tutorSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the persona you feel most comfortable speaking with.'**
  String get tutorSelectionSubtitle;

  /// No description provided for @tutorAbbasName.
  ///
  /// In en, this message translates to:
  /// **'Abbas'**
  String get tutorAbbasName;

  /// No description provided for @tutorAbbasRole.
  ///
  /// In en, this message translates to:
  /// **'AI Language Coach'**
  String get tutorAbbasRole;

  /// No description provided for @tutorAbbasDesc.
  ///
  /// In en, this message translates to:
  /// **'A friendly, energetic, and witty AI language tutor who encourages you to speak naturally 😂'**
  String get tutorAbbasDesc;

  /// No description provided for @tutorAbbasTrait1.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get tutorAbbasTrait1;

  /// No description provided for @tutorAbbasTrait2.
  ///
  /// In en, this message translates to:
  /// **'Witty'**
  String get tutorAbbasTrait2;

  /// No description provided for @tutorAbbasTrait3.
  ///
  /// In en, this message translates to:
  /// **'Encouraging'**
  String get tutorAbbasTrait3;

  /// No description provided for @tutorAbbasTrait4.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get tutorAbbasTrait4;

  /// No description provided for @tutorDunyaName.
  ///
  /// In en, this message translates to:
  /// **'Dunya'**
  String get tutorDunyaName;

  /// No description provided for @tutorDunyaRole.
  ///
  /// In en, this message translates to:
  /// **'AI Language Coach'**
  String get tutorDunyaRole;

  /// No description provided for @tutorDunyaDesc.
  ///
  /// In en, this message translates to:
  /// **'A warm, patient, and confident AI language tutor who helps you build conversational confidence.'**
  String get tutorDunyaDesc;

  /// No description provided for @tutorDunyaTrait1.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get tutorDunyaTrait1;

  /// No description provided for @tutorDunyaTrait2.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get tutorDunyaTrait2;

  /// No description provided for @tutorDunyaTrait3.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get tutorDunyaTrait3;

  /// No description provided for @tutorDunyaTrait4.
  ///
  /// In en, this message translates to:
  /// **'Encouraging'**
  String get tutorDunyaTrait4;

  /// No description provided for @completionTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set! 🚀'**
  String get completionTitle;

  /// No description provided for @completionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From now on, we will build your learning journey based on your level and goals.'**
  String get completionSubtitle;

  /// No description provided for @letsStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get letsStart;

  /// No description provided for @placementIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see where to start 🎯'**
  String get placementIntroTitle;

  /// No description provided for @placementIntroDesc1.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a school exam, and there is no pass or fail. We just want to find your starting point so we don\'t waste your time on things that are too easy.'**
  String get placementIntroDesc1;

  /// No description provided for @placementIntroDesc2.
  ///
  /// In en, this message translates to:
  /// **'Answer as much as you can, and if you don\'t know, that\'s completely fine.'**
  String get placementIntroDesc2;

  /// No description provided for @placementIntroCta.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Begin'**
  String get placementIntroCta;

  /// No description provided for @placementIntroAbbas.
  ///
  /// In en, this message translates to:
  /// **'I\'m Abbas, and I\'ll walk with you step by step. If you don\'t know an answer, it\'s not the end of the world 😂'**
  String get placementIntroAbbas;

  /// No description provided for @placementIntroDunya.
  ///
  /// In en, this message translates to:
  /// **'I\'m Dunya, and in just a few minutes we\'ll find the best starting point for you.'**
  String get placementIntroDunya;

  /// No description provided for @tutorCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Tutor Conversation'**
  String get tutorCallTitle;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to Speak'**
  String get tapToSpeak;

  /// No description provided for @listeningPrompt.
  ///
  /// In en, this message translates to:
  /// **'Listening to you... Speak freely'**
  String get listeningPrompt;

  /// No description provided for @processingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Understanding what you said...'**
  String get processingPrompt;

  /// No description provided for @speakingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tutor is speaking...'**
  String get speakingPrompt;

  /// No description provided for @stopSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Stop Speaking'**
  String get stopSpeaking;

  /// No description provided for @retryVoice.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retryVoice;

  /// No description provided for @typeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get typeInstead;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to practice speaking.'**
  String get micPermissionDenied;

  /// No description provided for @sttUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device.'**
  String get sttUnavailable;

  /// No description provided for @ttsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio speech playback is not available.'**
  String get ttsUnavailable;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @tutorGreetingAbbas.
  ///
  /// In en, this message translates to:
  /// **'Hey! Ready to practice real speaking? Tap the mic whenever you\'re ready! 🔥'**
  String get tutorGreetingAbbas;

  /// No description provided for @tutorGreetingDunya.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m so excited to practice with you. Tap the mic whenever you\'re ready! 🌟'**
  String get tutorGreetingDunya;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @answerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get answerSubmit;

  /// No description provided for @answerDontKnow.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know'**
  String get answerDontKnow;

  /// No description provided for @answerHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get answerHint;

  /// No description provided for @answerInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get answerInputHint;

  /// No description provided for @evalFeedbackStrong.
  ///
  /// In en, this message translates to:
  /// **'Awesome 👏 Let\'s level up slightly.'**
  String get evalFeedbackStrong;

  /// No description provided for @evalFeedbackPartial.
  ///
  /// In en, this message translates to:
  /// **'Very close! I understood you, just one small detail.'**
  String get evalFeedbackPartial;

  /// No description provided for @evalFeedbackWeak.
  ///
  /// In en, this message translates to:
  /// **'No worries, let\'s try something simpler.'**
  String get evalFeedbackWeak;

  /// No description provided for @evalFeedbackSkipped.
  ///
  /// In en, this message translates to:
  /// **'Totally fine. This helps me understand where we should start.'**
  String get evalFeedbackSkipped;

  /// No description provided for @evalErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'A glitch occurred while evaluating your response. Please try again.'**
  String get evalErrorRetry;

  /// No description provided for @placementResultTitle.
  ///
  /// In en, this message translates to:
  /// **'We found your starting point! 🎯'**
  String get placementResultTitle;

  /// No description provided for @placementResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated Level'**
  String get placementResultSubtitle;

  /// No description provided for @placementResultDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is an initial estimate, and we\'ll fine-tune your level as you speak and learn with us.'**
  String get placementResultDisclaimer;

  /// No description provided for @placementSkillComprehension.
  ///
  /// In en, this message translates to:
  /// **'Comprehension'**
  String get placementSkillComprehension;

  /// No description provided for @placementSkillVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get placementSkillVocabulary;

  /// No description provided for @placementSkillGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar & Structure'**
  String get placementSkillGrammar;

  /// No description provided for @placementSkillCommunication.
  ///
  /// In en, this message translates to:
  /// **'General Communication'**
  String get placementSkillCommunication;

  /// No description provided for @pronunciationNotice.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation: We\'ll evaluate it during our first voice call 🎙️'**
  String get pronunciationNotice;

  /// No description provided for @strengthsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Strongest Areas'**
  String get strengthsTitle;

  /// No description provided for @weaknessesTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll Focus More On'**
  String get weaknessesTitle;

  /// No description provided for @continueJourney.
  ///
  /// In en, this message translates to:
  /// **'Continue My Journey'**
  String get continueJourney;

  /// No description provided for @cefrPreA1.
  ///
  /// In en, this message translates to:
  /// **'Starting from Scratch'**
  String get cefrPreA1;

  /// No description provided for @cefrA1.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get cefrA1;

  /// No description provided for @cefrA2.
  ///
  /// In en, this message translates to:
  /// **'Strong Basics'**
  String get cefrA2;

  /// No description provided for @cefrB1.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get cefrB1;

  /// No description provided for @cefrB2.
  ///
  /// In en, this message translates to:
  /// **'Upper Intermediate'**
  String get cefrB2;

  /// No description provided for @cefrC1.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cefrC1;

  /// No description provided for @cefrC2.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get cefrC2;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress & Achievements'**
  String get progressTitle;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get currentStreak;

  /// No description provided for @streakDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String streakDaysCount(int count);

  /// No description provided for @streakDaySingle.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get streakDaySingle;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @xpPoints.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String xpPoints(int xp);

  /// No description provided for @learnerLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}: {title}'**
  String learnerLevel(int level, String title);

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @dailyGoalMet.
  ///
  /// In en, this message translates to:
  /// **'Awesome! You reached today\'s goal 🎯'**
  String get dailyGoalMet;

  /// No description provided for @dailyGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP remaining to reach today\'s goal'**
  String dailyGoalRemaining(int xp);

  /// No description provided for @skillsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Skills Breakdown'**
  String get skillsBreakdown;

  /// No description provided for @learningRoadmap.
  ///
  /// In en, this message translates to:
  /// **'3-Month Learning Roadmap'**
  String get learningRoadmap;

  /// No description provided for @month1Title.
  ///
  /// In en, this message translates to:
  /// **'Month 1: Foundation'**
  String get month1Title;

  /// No description provided for @month2Title.
  ///
  /// In en, this message translates to:
  /// **'Month 2: Real Life'**
  String get month2Title;

  /// No description provided for @month3Title.
  ///
  /// In en, this message translates to:
  /// **'Month 3: Fluency'**
  String get month3Title;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements & Badges'**
  String get achievementsTitle;

  /// No description provided for @unlockedAchievements.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} Unlocked'**
  String unlockedAchievements(int unlocked, int total);

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @activeDaysThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} of 7 active days this week'**
  String activeDaysThisWeek(int count);

  /// No description provided for @insufficientEvidence.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data yet'**
  String get insufficientEvidence;

  /// No description provided for @assessedAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count} assessments'**
  String assessedAttempts(int count);

  /// No description provided for @unlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String unlockedOn(String date);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @startRecommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Start Recommended Activity'**
  String get startRecommendedAction;

  /// No description provided for @viewFullProgress.
  ///
  /// In en, this message translates to:
  /// **'View Full Progress'**
  String get viewFullProgress;

  /// No description provided for @streakLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak: {days} days'**
  String streakLongest(int days);

  /// No description provided for @totalLearningDays.
  ///
  /// In en, this message translates to:
  /// **'Total Learning Days: {days} days'**
  String totalLearningDays(int days);

  /// No description provided for @accountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeTitle;

  /// No description provided for @accountTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to use Lahjti'**
  String get accountTypeSubtitle;

  /// No description provided for @accountIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual Learner'**
  String get accountIndividual;

  /// No description provided for @accountIndividualDesc.
  ///
  /// In en, this message translates to:
  /// **'Self-paced personalized learning with AI Tutor'**
  String get accountIndividualDesc;

  /// No description provided for @accountSchool.
  ///
  /// In en, this message translates to:
  /// **'School / Institution'**
  String get accountSchool;

  /// No description provided for @accountSchoolDesc.
  ///
  /// In en, this message translates to:
  /// **'Account linked to your school or classroom'**
  String get accountSchoolDesc;

  /// No description provided for @schoolRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your role?'**
  String get schoolRoleTitle;

  /// No description provided for @schoolRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get schoolRoleSubtitle;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Join your class, complete exercises, and speak with AI Tutor'**
  String get roleStudentDesc;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleTeacherDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your classes, students, and learning plans'**
  String get roleTeacherDesc;

  /// No description provided for @schoolCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'School Code'**
  String get schoolCodeLabel;

  /// No description provided for @schoolCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. SCH-1001 or LAH-EDU-2026'**
  String get schoolCodeHint;

  /// No description provided for @schoolCodeVerifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get schoolCodeVerifyBtn;

  /// No description provided for @schoolCodeValid.
  ///
  /// In en, this message translates to:
  /// **'School verified successfully ✅'**
  String get schoolCodeValid;

  /// No description provided for @schoolCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or inactive school code ❌'**
  String get schoolCodeInvalid;

  /// No description provided for @schoolCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter and verify your school code'**
  String get schoolCodeRequired;

  /// No description provided for @schoolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolNameLabel;

  /// No description provided for @studentGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade Level'**
  String get studentGradeLabel;

  /// No description provided for @studentGradeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 5, Grade 10'**
  String get studentGradeHint;

  /// No description provided for @studentSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Class / Section'**
  String get studentSectionLabel;

  /// No description provided for @studentSectionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Section A, Room 102'**
  String get studentSectionHint;

  /// No description provided for @studentInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Classroom Details'**
  String get studentInfoTitle;

  /// No description provided for @studentInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your grade and class section'**
  String get studentInfoSubtitle;

  /// No description provided for @teacherSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject / Language Taught'**
  String get teacherSubjectLabel;

  /// No description provided for @teacherSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English, Conversational Skills'**
  String get teacherSubjectHint;

  /// No description provided for @teacherGradesLabel.
  ///
  /// In en, this message translates to:
  /// **'Grades Taught'**
  String get teacherGradesLabel;

  /// No description provided for @teacherGradesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grades 7, 8, 9'**
  String get teacherGradesHint;

  /// No description provided for @teacherSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Profile Setup'**
  String get teacherSetupTitle;

  /// No description provided for @teacherSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the subject and grades you teach'**
  String get teacherSetupSubtitle;

  /// No description provided for @teacherHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Hub'**
  String get teacherHomeTitle;

  /// No description provided for @teacherHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Teacher {name}'**
  String teacherHomeSubtitle(String name);

  /// No description provided for @teacherClassroomsPreview.
  ///
  /// In en, this message translates to:
  /// **'Classrooms & Students (Coming in next step)'**
  String get teacherClassroomsPreview;

  /// No description provided for @teacherCurriculumPreview.
  ///
  /// In en, this message translates to:
  /// **'Curriculum & Lesson Plans'**
  String get teacherCurriculumPreview;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Access'**
  String get subscriptionTitle;

  /// No description provided for @trialActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Free Trial Active'**
  String get trialActiveBadge;

  /// No description provided for @trialDaysRemainingText.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining in trial'**
  String trialDaysRemainingText(int days);

  /// No description provided for @subscriptionPriceNote.
  ///
  /// In en, this message translates to:
  /// **'\$10/month after trial ends'**
  String get subscriptionPriceNote;

  /// No description provided for @schoolAccessBadge.
  ///
  /// In en, this message translates to:
  /// **'School Access'**
  String get schoolAccessBadge;

  /// No description provided for @schoolAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account is active via {schoolName}'**
  String schoolAccessDesc(String schoolName);

  /// No description provided for @welcomeSchoolButton.
  ///
  /// In en, this message translates to:
  /// **'🏫 School Portal (Student / Teacher)'**
  String get welcomeSchoolButton;

  /// No description provided for @teacherDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Dashboard'**
  String get teacherDashboardTitle;

  /// No description provided for @myClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get myClassesTitle;

  /// No description provided for @totalStudentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudentsLabel;

  /// No description provided for @activeTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get activeTodayLabel;

  /// No description provided for @tasksCompletedTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed Today\'s Tasks'**
  String get tasksCompletedTodayLabel;

  /// No description provided for @averageProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Progress'**
  String get averageProgressLabel;

  /// No description provided for @notEnoughDataYet.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get notEnoughDataYet;

  /// No description provided for @noClassesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No classes assigned yet'**
  String get noClassesAssigned;

  /// No description provided for @noStudentsInClass.
  ///
  /// In en, this message translates to:
  /// **'No students have joined this class yet.'**
  String get noStudentsInClass;

  /// No description provided for @classStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Students'**
  String get classStudentsTitle;

  /// No description provided for @studentProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Educational Progress'**
  String get studentProgressTitle;

  /// No description provided for @learningOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Overview'**
  String get learningOverviewTitle;

  /// No description provided for @cefrLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Language Level (CEFR)'**
  String get cefrLevelLabel;

  /// No description provided for @lessonsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lessons Completed'**
  String get lessonsCompletedLabel;

  /// No description provided for @vocabularyMasteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Mastered'**
  String get vocabularyMasteredLabel;

  /// No description provided for @examsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Exams Completed'**
  String get examsCompletedLabel;

  /// No description provided for @totalMinutesLearnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning Minutes'**
  String get totalMinutesLearnedLabel;

  /// No description provided for @skillProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill Progress'**
  String get skillProgressTitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityTitle;

  /// No description provided for @needsAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get needsAttentionTitle;

  /// No description provided for @noAttentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'No warnings. The student is progressing well 👏'**
  String get noAttentionNeeded;

  /// No description provided for @studentCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentCountLabel(int count);

  /// No description provided for @tasksCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed today\'s tasks ✅'**
  String get tasksCompletedStatus;

  /// No description provided for @tasksPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Tasks pending for today ⏳'**
  String get tasksPendingStatus;

  /// No description provided for @viewDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsBtn;

  /// No description provided for @evidenceSufficientBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Evidence'**
  String get evidenceSufficientBadge;

  /// No description provided for @evidenceInsufficientBadge.
  ///
  /// In en, this message translates to:
  /// **'Preliminary Data'**
  String get evidenceInsufficientBadge;

  /// No description provided for @privacyProtectionNotice.
  ///
  /// In en, this message translates to:
  /// **'🔒 Showing educational performance metrics only for privacy protection'**
  String get privacyProtectionNotice;

  /// No description provided for @studentListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No students in this class currently'**
  String get studentListEmpty;

  /// No description provided for @studentSchoolHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Home'**
  String get studentSchoolHomeTitle;

  /// No description provided for @studentGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello {name} 👋'**
  String studentGreeting(String name);

  /// No description provided for @whatToDoToday.
  ///
  /// In en, this message translates to:
  /// **'What to do today?'**
  String get whatToDoToday;

  /// No description provided for @todayTaskMission.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Mission'**
  String get todayTaskMission;

  /// No description provided for @todayTaskMissionSub.
  ///
  /// In en, this message translates to:
  /// **'Complete {count} activities to earn {xp} XP'**
  String todayTaskMissionSub(int count, int xp);

  /// No description provided for @todayTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasksTitle;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks left for today, great job! 🎉'**
  String get noTasksToday;

  /// No description provided for @continueLesson.
  ///
  /// In en, this message translates to:
  /// **'Continue Lessons'**
  String get continueLesson;

  /// No description provided for @vocabularyReview.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Review'**
  String get vocabularyReview;

  /// No description provided for @educationalGames.
  ///
  /// In en, this message translates to:
  /// **'Educational Games'**
  String get educationalGames;

  /// No description provided for @talkToTutors.
  ///
  /// In en, this message translates to:
  /// **'Talk to Abbas & Dunya'**
  String get talkToTutors;

  /// No description provided for @childModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Kids Interactive Mode 🎈'**
  String get childModeBanner;

  /// No description provided for @gamesHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Educational Games'**
  String get gamesHubTitle;

  /// No description provided for @gamesHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play, learn, and earn XP!'**
  String get gamesHubSubtitle;

  /// No description provided for @wordMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Match'**
  String get wordMatchTitle;

  /// No description provided for @listenAndChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen & Choose'**
  String get listenAndChooseTitle;

  /// No description provided for @sentenceBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentence Builder'**
  String get sentenceBuilderTitle;

  /// No description provided for @memoryVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory Vocabulary'**
  String get memoryVocabTitle;

  /// No description provided for @quickQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Quiz'**
  String get quickQuizTitle;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get playNow;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskCompleted;

  /// No description provided for @taskPending.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get taskPending;

  /// No description provided for @gameGreatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job! 🌟'**
  String get gameGreatJob;

  /// No description provided for @gameTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again 💪'**
  String get gameTryAgain;

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Completed! 🎉'**
  String get gameOverTitle;

  /// No description provided for @earnedXpMessage.
  ///
  /// In en, this message translates to:
  /// **'You earned {xp} XP'**
  String earnedXpMessage(int xp);

  /// No description provided for @scoreResult.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String scoreResult(int score);

  /// No description provided for @backToTasks.
  ///
  /// In en, this message translates to:
  /// **'Back to Daily Tasks'**
  String get backToTasks;

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get checkAnswer;

  /// No description provided for @tapToMatch.
  ///
  /// In en, this message translates to:
  /// **'Tap a word to match'**
  String get tapToMatch;

  /// No description provided for @arrangeSentence.
  ///
  /// In en, this message translates to:
  /// **'Arrange the words to make a sentence'**
  String get arrangeSentence;

  /// No description provided for @safeAiNotice.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Safe, educational AI chat with strict privacy'**
  String get safeAiNotice;

  /// No description provided for @trialExpiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Trial Expired'**
  String get trialExpiredBadge;

  /// No description provided for @trialExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your 3-day free individual learning trial has ended.'**
  String get trialExpiredDesc;

  /// No description provided for @subscriptionPriceTag.
  ///
  /// In en, this message translates to:
  /// **'10 USD / month'**
  String get subscriptionPriceTag;

  /// No description provided for @subscriptionFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s included in full Lahjti?'**
  String get subscriptionFeaturesTitle;

  /// No description provided for @subscriptionFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited voice conversations with Abbas & Dunya'**
  String get subscriptionFeature1;

  /// No description provided for @subscriptionFeature2.
  ///
  /// In en, this message translates to:
  /// **'Interactive dialect curriculum, games & vocabulary'**
  String get subscriptionFeature2;

  /// No description provided for @subscriptionFeature3.
  ///
  /// In en, this message translates to:
  /// **'Smart pronunciation analysis & daily progress tracking'**
  String get subscriptionFeature3;

  /// No description provided for @subscriptionComingSoonBtn.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions Coming Soon (No charges applied)'**
  String get subscriptionComingSoonBtn;

  /// No description provided for @schoolTrialBadge.
  ///
  /// In en, this message translates to:
  /// **'Educational School Trial (10 Days)'**
  String get schoolTrialBadge;

  /// No description provided for @schoolTrialDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account is activated through your school for 10 free educational days'**
  String get schoolTrialDesc;

  /// No description provided for @developerCredit.
  ///
  /// In en, this message translates to:
  /// **'Developed by: Mohammad Abu Abbas • Phoenix Technical Group (PTG)'**
  String get developerCredit;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesDevNotice.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases will be available with official payment integrations'**
  String get restorePurchasesDevNotice;

  /// No description provided for @activeSubscriptionBadge.
  ///
  /// In en, this message translates to:
  /// **'Active Individual Subscription'**
  String get activeSubscriptionBadge;

  /// No description provided for @activeSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'\$10/month • Full access to all Lahjti features'**
  String get activeSubscriptionDesc;

  /// No description provided for @pastDueBadge.
  ///
  /// In en, this message translates to:
  /// **'Payment Past Due'**
  String get pastDueBadge;

  /// No description provided for @cancelledGraceBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto-Renewal Cancelled'**
  String get cancelledGraceBadge;

  /// No description provided for @accountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Subscription'**
  String get accountProfileTitle;

  /// No description provided for @accountAccessStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Status'**
  String get accountAccessStatusLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Context'**
  String get accountTypeLabel;

  /// No description provided for @schoolAccessActive.
  ///
  /// In en, this message translates to:
  /// **'School Access Active'**
  String get schoolAccessActive;

  /// No description provided for @trialEndedSubscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Trial ended • Subscription required to continue'**
  String get trialEndedSubscriptionRequired;

  /// No description provided for @trialActiveDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Trial active • {days} days remaining'**
  String trialActiveDaysRemaining(int days);

  /// No description provided for @continueLearningCta.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning ➔'**
  String get continueLearningCta;

  /// No description provided for @todaysTasksHeader.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Learning Tasks'**
  String get todaysTasksHeader;

  /// No description provided for @todaysTasksHeaderSub.
  ///
  /// In en, this message translates to:
  /// **'Complete tasks to achieve your daily learning goal'**
  String get todaysTasksHeaderSub;

  /// No description provided for @dueVocabCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} words due for review'**
  String dueVocabCountLabel(int count);

  /// No description provided for @reviewVocabAction.
  ///
  /// In en, this message translates to:
  /// **'Start Vocabulary Review ({minutes}m)'**
  String reviewVocabAction(int minutes);

  /// No description provided for @finishLessonBtn.
  ///
  /// In en, this message translates to:
  /// **'Complete Lesson (+30 XP) 🎉'**
  String get finishLessonBtn;

  /// No description provided for @emptyTasksCelebration.
  ///
  /// In en, this message translates to:
  /// **'Great job! You finished all tasks for today 🎉'**
  String get emptyTasksCelebration;

  /// No description provided for @firstDayStartLesson.
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson today 🚀'**
  String get firstDayStartLesson;

  /// No description provided for @allTasksCompletedEnrichment.
  ///
  /// In en, this message translates to:
  /// **'You finished all daily goals! Enjoy an open chat with your AI tutor.'**
  String get allTasksCompletedEnrichment;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
