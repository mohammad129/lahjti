import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/l10n/app_localizations.dart';

void main() {
  group('Localization Tests', () {
    test(
      '3. Arabic localization loads properly with natural phrasing',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('ar'),
        );

        expect(localizations.appName, 'لهجتي');
        expect(localizations.welcome, 'أهلاً بك');
        expect(localizations.startYourJourney, 'ابدأ رحلتك');
        expect(localizations.chooseYourLanguage, 'اختر لغتك');
        expect(localizations.continueText, 'متابعة');
        expect(localizations.back, 'رجوع');
        expect(localizations.next, 'التالي');
        expect(localizations.home, 'الرئيسية');
        expect(localizations.tutor, 'المعلم');
        expect(localizations.learning, 'التعلم');
        expect(localizations.vocabulary, 'المفردات');
        expect(localizations.exams, 'الاختبارات');
        expect(localizations.progress, 'التقدم');
        expect(localizations.profile, 'الملف الشخصي');
        expect(localizations.subscription, 'الاشتراك');
        expect(localizations.loading, 'جاري التحميل...');
        expect(
          localizations.somethingWentWrong,
          'صار معنا خلل بسيط. جرب مرة ثانية.',
        );
        expect(localizations.tryAgain, 'إعادة المحاولة');
        expect(localizations.welcomeTagline, 'احكيها... مش بس احفظها.');
        expect(
          localizations.welcomeSubtitle,
          'مدربك AI معك، يسمعك، يحكي معك، ويصححلك.',
        );
        expect(localizations.welcomeButtonCta, 'ابدأ رحلتك 🚀');
        expect(localizations.targetLanguageTitle, 'شو اللغة اللي بدك تتعلمها؟');
        expect(localizations.ageGroupTitle, 'كم عمرك؟');
        expect(localizations.nativeLanguageTitle, 'شو لغتك الأم؟');
        expect(localizations.learningGoalTitle, 'ليش بدك تتعلم اللغة؟');
        expect(localizations.experienceTitle, 'قديش بتعرف عن اللغة؟');
        expect(localizations.registerTitle, 'أنشئ حسابك');
        expect(localizations.valNameRequired, 'اكتب اسمك أولاً.');
        expect(localizations.valEmailInvalid, 'تأكد من البريد الإلكتروني.');
        expect(
          localizations.valPasswordWeak,
          'كلمة المرور لازم تكون أقوى (6 خانات على الأقل).',
        );
        expect(
          localizations.valPasswordsDoNotMatch,
          'كلمتا المرور غير متطابقتين.',
        );
        expect(localizations.tutorSelectionTitle, 'مين بدك يكون مدربك؟');
        expect(localizations.tutorAbbasName, 'عباس');
        expect(localizations.tutorDunyaName, 'دنيا');
        expect(localizations.completionTitle, 'جاهزين! 🚀');
        expect(localizations.letsStart, 'خلينا نبدأ');
      },
    );

    test('4. English localization loads properly', () async {
      final localizations = await AppLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(localizations.appName, 'Lahjti');
      expect(localizations.welcome, 'Welcome');
      expect(localizations.startYourJourney, 'Start your journey');
      expect(localizations.chooseYourLanguage, 'Choose your language');
      expect(localizations.continueText, 'Continue');
      expect(localizations.back, 'Back');
      expect(localizations.next, 'Next');
      expect(localizations.home, 'Home');
      expect(localizations.tutor, 'Tutor');
      expect(localizations.learning, 'Learning');
      expect(localizations.vocabulary, 'Vocabulary');
      expect(localizations.exams, 'Exams');
      expect(localizations.progress, 'Progress');
      expect(localizations.profile, 'Profile');
      expect(localizations.subscription, 'Subscription');
      expect(localizations.loading, 'Loading...');
      expect(localizations.tryAgain, 'Try again');
      expect(
        localizations.targetLanguageTitle,
        'Which language do you want to learn?',
      );
      expect(localizations.ageGroupTitle, 'How old are you?');
      expect(
        localizations.nativeLanguageTitle,
        'What is your native language?',
      );
      expect(
        localizations.learningGoalTitle,
        'Why do you want to learn this language?',
      );
      expect(
        localizations.experienceTitle,
        'How much do you know about the language?',
      );
      expect(localizations.registerTitle, 'Create Your Account');
      expect(
        localizations.tutorSelectionTitle,
        'Who would you like your tutor to be?',
      );
      expect(localizations.tutorAbbasName, 'Abbas');
      expect(localizations.tutorDunyaName, 'Dunya');
      expect(localizations.completionTitle, "You're All Set! 🚀");
      expect(localizations.letsStart, "Let's Get Started");
    });
  });
}
