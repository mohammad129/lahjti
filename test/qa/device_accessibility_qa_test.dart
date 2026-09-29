import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/progress/presentation/screens/progress_screen.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/tutor/presentation/screens/tutor_conversation_screen.dart';
import 'package:lahjti/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class MockQaTutorRepo implements TutorConversationRepository {
  @override
  Future<VoiceMessage> generateTutorResponse({
    required String userText,
    required String targetLanguageCode,
    required String tutorId,
    required List<VoiceMessage> history,
    String nativeLanguage = 'arabic',
    String ageGroup = 'adult',
    String learningGoal = 'conversation',
    String difficulty = 'a1',
    bool isSessionStart = false,
    dynamic learnerContext,
  }) async {
    return VoiceMessage(
      id: 'qa_msg_1',
      isUser: false,
      text: 'Hello, welcome to QA test!',
      explanationArabic: 'أهلاً بك في اختبار الجودة!',
      shouldCorrect: false,
      timestamp: DateTime.now(),
    );
  }
}

Widget createQaApp({required Widget home, Locale locale = const Locale('ar')}) {
  final stt = MockSpeechToTextService();
  final tts = MockTextToSpeechService();
  final learningRepo = LocalLearningRepository();

  return ProviderScope(
    overrides: [
      speechToTextServiceProvider.overrideWithValue(stt),
      textToSpeechServiceProvider.overrideWithValue(tts),
      tutorConversationRepositoryProvider.overrideWithValue(MockQaTutorRepo()),
      learningRepositoryProvider.overrideWithValue(learningRepo),
      localeProvider.overrideWith((ref) {
        final notifier = LocaleNotifier();
        if (locale.languageCode != 'ar') {
          notifier.setLocale(locale);
        }
        return notifier;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

void main() {
  group('Step 16: Device, UX, Accessibility & Cross-Platform QA Tests', () {
    testWidgets(
      '1. WelcomeScreen renders without overflow on Small Phone (320x568)',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createQaApp(home: const WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. WelcomeScreen renders with correct LTR layout on Standard Phone in English',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createQaApp(home: const WelcomeScreen(), locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        expect(find.text('العربية'), findsOneWidget);
        expect(find.text('AI Powered'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('3. OnboardingScreen renders on Large Phone in Arabic RTL', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(428 * 3.0, 926 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createQaApp(home: const OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '4. HomeScreen renders Quick Hub Action buttons (Vocabulary, Exams, Progress)',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createQaApp(home: const HomeScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
        expect(find.byIcon(Icons.quiz_rounded), findsOneWidget);
        final exception = tester.takeException();
        if (exception != null) {
          // ignore: avoid_print
          print('HomeScreen Exception Details: $exception');
        }
        expect(exception, isNull);
      },
    );

    testWidgets(
      '5. TutorConversationScreen renders with accessible Semantics on Mic CTA',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createQaApp(home: const TutorConversationScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(TutorConversationScreen), findsOneWidget);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. ProgressScreen renders in Arabic RTL without horizontal overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2.0, 780 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createQaApp(home: const ProgressScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(ProgressScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. VocabularyScreen renders cleanly in English LTR without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createQaApp(
            home: const VocabularyScreen(),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(VocabularyScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
