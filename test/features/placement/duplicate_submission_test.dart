import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/onboarding_data.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/placement/domain/models/placement_answer.dart';
import 'package:lahjti/features/placement/domain/models/placement_evaluation.dart';
import 'package:lahjti/features/placement/domain/models/placement_question.dart';
import 'package:lahjti/features/placement/domain/models/question_type.dart';
import 'package:lahjti/features/placement/domain/providers/language_evaluation_provider.dart';
import 'package:lahjti/features/placement/domain/providers/placement_content_provider.dart';
import 'package:lahjti/features/placement/domain/providers/placement_engine.dart';
import 'package:lahjti/features/placement/presentation/providers/placement_provider.dart';

class SlowMockEvaluationProvider implements LanguageEvaluationProvider {
  int callCount = 0;
  Completer<PlacementEvaluation>? pendingCompleter;

  @override
  Future<PlacementEvaluation> evaluate({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required PlacementQuestion question,
    required PlacementAnswer answer,
  }) async {
    callCount++;
    pendingCompleter = Completer<PlacementEvaluation>();
    return pendingCompleter!.future;
  }
}

class FastMockContentProvider implements PlacementContentProvider {
  @override
  Future<PlacementQuestion> getNextQuestion({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required CefrLevel difficulty,
    required List<String> previousQuestionIds,
  }) async {
    return const PlacementQuestion(
      id: 'q_dup_01',
      type: QuestionType.comprehension,
      targetLanguage: 'en',
      difficulty: CefrLevel.a1,
      prompt: 'Hello world',
      promptArabic: 'مرحبًا بالعالم',
    );
  }
}

void main() {
  group('Duplicate Submission & Concurrency Protection Tests', () {
    late SlowMockEvaluationProvider evalProvider;
    late FastMockContentProvider contentProvider;
    late PlacementEngine engine;
    late PlacementNotifier notifier;

    const testLanguage = SupportedLanguage(
      id: 'en',
      nameEn: 'English',
      nameAr: 'الإنجليزية',
      flagEmoji: '🇬🇧',
    );

    const testGoal = LearningGoal(id: 'conversation', icon: '🗣️');

    setUp(() async {
      evalProvider = SlowMockEvaluationProvider();
      contentProvider = FastMockContentProvider();
      engine = const PlacementEngine();
      notifier = PlacementNotifier(
        contentProvider: contentProvider,
        evaluationProvider: evalProvider,
        engine: engine,
      );

      // Start session
      await notifier.startSession(
        const OnboardingData(
          targetLanguage: testLanguage,
          nativeLanguage: NativeLanguage.arabic,
          ageGroup: AgeGroup.age26_35,
          learningGoal: testGoal,
          experienceLevel: ExperienceLevel.basic,
        ),
      );
    });

    test(
      '21. Prevents duplicate answer submissions while evaluation is active',
      () async {
        expect(notifier.state.status, PlacementStatus.questionReady);
        expect(notifier.state.isSubmitting, isFalse);

        // First submit
        final future1 = notifier.submitAnswer(response: 'First answer');

        // State is now evaluating and isSubmitting is true
        expect(notifier.state.status, PlacementStatus.evaluating);
        expect(notifier.state.isSubmitting, isTrue);
        expect(evalProvider.callCount, 1);

        // Rapid second and third submit attempts (simulating rapid double clicks)
        final future2 = notifier.submitAnswer(response: 'Second rapid answer');
        final future3 = notifier.submitAnswer(response: 'Third rapid answer');

        // Call count must remain 1
        expect(evalProvider.callCount, 1);

        // Complete the pending evaluation
        evalProvider.pendingCompleter?.complete(
          const PlacementEvaluation(
            semanticScore: 80,
            grammarScore: 80,
            vocabularyScore: 80,
            comprehensionScore: 80,
            fluencyScore: 80,
            pronunciationScore: null,
            confidence: 0.9,
            explanationArabic: 'ممتاز',
            wasUnderstandable: true,
            shouldIncreaseDifficulty: true,
            shouldDecreaseDifficulty: false,
          ),
        );

        await Future.wait([future1, future2, future3]);

        // Verify that after completion, callCount was strictly 1
        expect(evalProvider.callCount, 1);
        expect(notifier.state.isSubmitting, isFalse);
      },
    );
  });
}
