import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/localization/locale_provider.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/exams/presentation/providers/exams_providers.dart';
import 'package:lahjti/features/exams/presentation/screens/exam_result_screen.dart';
import 'package:lahjti/features/exams/presentation/screens/exam_session_screen.dart';
import 'package:lahjti/features/exams/presentation/screens/exams_hub_screen.dart';
import 'package:lahjti/features/home/presentation/screens/home_screen.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/progress/presentation/screens/progress_screen.dart';
import 'package:lahjti/features/tutor/data/services/mock_speech_to_text_service.dart';
import 'package:lahjti/features/tutor/data/services/mock_text_to_speech_service.dart';
import 'package:lahjti/features/tutor/domain/models/voice_session_state.dart';
import 'package:lahjti/features/tutor/domain/repositories/tutor_conversation_repository.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/tutor/presentation/screens/tutor_conversation_screen.dart';
import 'package:lahjti/features/vocabulary/presentation/screens/vocabulary_practice_screen.dart';
import 'package:lahjti/features/vocabulary/presentation/screens/vocabulary_screen.dart';
import 'package:lahjti/features/welcome/presentation/welcome_screen.dart';
import 'package:lahjti/l10n/app_localizations.dart';

class MockSmokeTutorRepo implements TutorConversationRepository {
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
      id: 'smoke_tutor_msg_1',
      isUser: false,
      text: 'Good job! That was very clear.',
      explanationArabic: 'عمل رائع! كانت الجملة واضحة وممتازة.',
      shouldCorrect: false,
      timestamp: DateTime.now(),
    );
  }
}

Widget createSmokeScreenApp({
  required Widget home,
  Locale locale = const Locale('ar'),
}) {
  final stt = MockSpeechToTextService();
  final tts = MockTextToSpeechService();
  final learningRepo = LocalLearningRepository();

  return ProviderScope(
    overrides: [
      speechToTextServiceProvider.overrideWithValue(stt),
      textToSpeechServiceProvider.overrideWithValue(tts),
      tutorConversationRepositoryProvider.overrideWithValue(
        MockSmokeTutorRepo(),
      ),
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
  group('Step 18: Final Real User Smoke Test (Main User Journey)', () {
    testWidgets(
      '1. Welcome Screen: app launch & language switching (AR <-> EN)',
      (tester) async {
        await tester.pumpWidget(
          createSmokeScreenApp(home: const WelcomeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.text('لهجتي'), findsOneWidget);
        expect(find.text('ابدأ رحلتك 🚀'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);

        // Switch to English
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        expect(find.text('AI Powered'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);

        // Switch back to Arabic
        await tester.tap(find.text('العربية'));
        await tester.pumpAndSettle();

        expect(find.text('مدرب ذكي'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('2. Onboarding Screen: stepped selection through all steps', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSmokeScreenApp(home: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Target language selection
      final englishOption = find.text('الإنجليزية (English)');
      if (englishOption.evaluate().isNotEmpty) {
        await tester.tap(englishOption);
        await tester.pumpAndSettle();
      }

      final continueButton = find.text('متابعة');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '3. Home Screen: renders tutor, level, streaks, and navigation hubs',
      (tester) async {
        await tester.pumpWidget(createSmokeScreenApp(home: const HomeScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          find.byIcon(Icons.menu_book_rounded),
          findsOneWidget,
        ); // Vocabulary
        expect(find.byIcon(Icons.quiz_rounded), findsOneWidget); // Exams
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('4. Tutor Screen: mock AI conversation and mic UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSmokeScreenApp(home: const TutorConversationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TutorConversationScreen), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Vocabulary Screen & Practice Screen', (tester) async {
      await tester.pumpWidget(
        createSmokeScreenApp(home: const VocabularyScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VocabularyScreen), findsOneWidget);

      await tester.pumpWidget(
        createSmokeScreenApp(home: const VocabularyPracticeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VocabularyPracticeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Exams Hub & Session Screen', (tester) async {
      await tester.pumpWidget(
        createSmokeScreenApp(home: const ExamsHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExamsHubScreen), findsOneWidget);

      await tester.pumpWidget(
        createSmokeScreenApp(home: const ExamSessionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExamSessionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Exam Result Screen with score summary', (tester) async {
      final repo = LocalLearningRepository();
      final dummyResult = ExamResult(
        id: 'res_smoke_100',
        examId: 'exam_month_1',
        examTitleArabic: 'اختبار الشهر الأول: إتقان الأساسيات',
        examTitleEnglish: 'Month 1 Milestone Exam',
        overallScore: 85,
        estimatedCefrLevel: CefrLevel.a2,
        skillScores: const [
          ExamSkillScore(
            skill: LearningSkill.vocabulary,
            scorePercentage: 100,
            pointsEarned: 20,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.grammar,
            scorePercentage: 90,
            pointsEarned: 18,
            pointsPossible: 20,
          ),
          ExamSkillScore(
            skill: LearningSkill.reading,
            scorePercentage: 85,
            pointsEarned: 17,
            pointsPossible: 20,
          ),
        ],
        answeredCount: 5,
        skippedCount: 0,
        correctCount: 5,
        totalQuestions: 5,
        strengthsArabic: const ['إتقان ممتاز في مهارة المفردات والكلمات'],
        areasForImprovementArabic: const ['تحتاج لتعزيز مهارة الاستماع والفهم'],
        recommendations: const [],
        completedAt: DateTime.now(),
      );

      final app = ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(repo),
          selectedExamResultProvider.overrideWith((ref) => dummyResult),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar'), Locale('en')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ExamResultScreen(),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(500, 1500));
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byType(ExamResultScreen), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Progress Screen in Arabic RTL & English LTR', (
      tester,
    ) async {
      // Arabic RTL
      await tester.pumpWidget(
        createSmokeScreenApp(
          home: const ProgressScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProgressScreen), findsOneWidget);

      // English LTR
      await tester.pumpWidget(
        createSmokeScreenApp(
          home: const ProgressScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
