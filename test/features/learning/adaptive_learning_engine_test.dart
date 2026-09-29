import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/curriculum/starter_curriculum.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_recommendation.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/domain/services/adaptive_learning_engine.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('AdaptiveLearningEngine Unit Tests', () {
    const engine = AdaptiveLearningEngine();
    final now = DateTime(2026, 9, 17, 12, 0);

    test('1. Performance >= 80% recommends difficulty advance', () {
      final decision = engine.evaluatePerformance(
        accuracy: 0.85,
        detectedErrors: const [],
        currentLevel: CefrLevel.a1,
      );

      expect(decision.action, 'advance');
      expect(decision.shouldAdvanceDifficulty, isTrue);
      expect(decision.feedbackArabic, contains('متميز'));
    });

    test(
      '2. Performance between 50% and 79% recommends concept reinforcement',
      () {
        final decision = engine.evaluatePerformance(
          accuracy: 0.65,
          detectedErrors: const ['Minor tense slip'],
          currentLevel: CefrLevel.a1,
          primarySkill: LearningSkill.grammar,
        );

        expect(decision.action, 'reinforce');
        expect(decision.shouldAdvanceDifficulty, isFalse);
        expect(decision.focusSkill, LearningSkill.grammar);
      },
    );

    test('3. Performance < 50% recommends step-by-step review', () {
      final decision = engine.evaluatePerformance(
        accuracy: 0.40,
        detectedErrors: const ['Multiple comprehension errors'],
        currentLevel: CefrLevel.a1,
      );

      expect(decision.action, 'review');
      expect(decision.shouldAdvanceDifficulty, isFalse);
      expect(decision.feedbackArabic, contains('نراجع'));
    });

    test(
      '4. Spaced review calculates intervals deterministically on correct answers',
      () {
        const initialItem = VocabularyItem(
          id: 'v1',
          term: 'Hello',
          translationArabic: 'مرحبًا',
          exampleSentence: 'Hello there!',
          exampleTranslationArabic: 'مرحبًا بك!',
          difficulty: CefrLevel.a1,
          category: 'Greetings',
        );

        // 1st correct answer -> 1 day interval
        final step1 = engine.computeNextReview(
          item: initialItem,
          wasCorrect: true,
          now: now,
        );
        expect(step1.correctStreak, 1);
        expect(step1.nextReview, now.add(const Duration(days: 1)));
        expect(step1.status, MasteryStatus.learning);

        // 2nd correct answer -> 3 days interval
        final step2 = engine.computeNextReview(
          item: step1,
          wasCorrect: true,
          now: now.add(const Duration(days: 1)),
        );
        expect(step2.correctStreak, 2);
        expect(step2.nextReview, now.add(const Duration(days: 4)));
        expect(step2.status, MasteryStatus.reviewing);

        // 3rd correct answer -> 7 days interval
        final step3 = engine.computeNextReview(
          item: step2,
          wasCorrect: true,
          now: now.add(const Duration(days: 4)),
        );
        expect(step3.correctStreak, 3);
        expect(step3.status, MasteryStatus.reviewing);

        // 4th correct answer -> 14 days interval, mastered
        final step4 = engine.computeNextReview(
          item: step3,
          wasCorrect: true,
          now: now.add(const Duration(days: 11)),
        );
        expect(step4.correctStreak, 4);
        expect(step4.status, MasteryStatus.mastered);
      },
    );

    test(
      '5. Spaced review resets streak to 0 on incorrect answer with 4-hour review',
      () {
        final masteredItem = VocabularyItem(
          id: 'v1',
          term: 'Went',
          translationArabic: 'ذهب',
          exampleSentence: 'I went home.',
          exampleTranslationArabic: 'ذهبت للمنزل.',
          difficulty: CefrLevel.a1,
          category: 'Verbs',
          correctStreak: 4,
          status: MasteryStatus.mastered,
        );

        final failedStep = engine.computeNextReview(
          item: masteredItem,
          wasCorrect: false,
          now: now,
        );

        expect(failedStep.correctStreak, 0);
        expect(failedStep.status, MasteryStatus.learning);
        expect(failedStep.incorrectAttempts, 1);
        expect(failedStep.nextReview, now.add(const Duration(hours: 4)));
      },
    );

    test(
      '6. Overdue vocabulary items take top priority for daily recommendation',
      () {
        final profile = LearningProfile.defaultProfile();
        final progress = LearnerProgress(lastSessionDate: now);

        final overdueItem = VocabularyItem(
          id: 'v_overdue',
          term: 'Book',
          translationArabic: 'كتاب',
          exampleSentence: 'Read a book.',
          exampleTranslationArabic: 'اقرأ كتابًا.',
          difficulty: CefrLevel.a1,
          category: 'Nouns',
          nextReview: now.subtract(const Duration(hours: 2)), // Overdue!
        );

        final recommendation = engine.generateDailyRecommendation(
          profile: profile,
          progress: progress,
          vocabularyItems: [overdueItem],
          availableLessons:
              StarterCurriculum.modules.expand((m) => m.lessons).toList(),
          currentTime: now,
        );

        expect(recommendation.type, RecommendationType.reviewVocabulary);
        expect(recommendation.urgencyScore, 90);
        expect(recommendation.actionRoute, '/vocabulary');
      },
    );

    test(
      '7. Incomplete active lesson is recommended when no vocabulary is due',
      () {
        final profile = LearningProfile.defaultProfile(userId: 'u1');
        final progress = LearnerProgress(lastSessionDate: now);

        final allLessons =
            StarterCurriculum.modules.expand((m) => m.lessons).toList();

        final recommendation = engine.generateDailyRecommendation(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: allLessons,
          currentTime: now,
        );

        expect(recommendation.type, RecommendationType.continueLesson);
        expect(recommendation.targetLessonId, 'lesson_1_1');
        expect(recommendation.actionRoute, '/learning');
      },
    );
  });
}
