import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/placement/domain/models/placement_answer.dart';
import 'package:lahjti/features/placement/domain/models/placement_evaluation.dart';
import 'package:lahjti/features/placement/domain/models/placement_session.dart';
import 'package:lahjti/features/placement/domain/providers/placement_engine.dart';

void main() {
  group('PlacementEngine Unit Tests', () {
    const engine = PlacementEngine();

    PlacementSession createTestSession({
      ExperienceLevel selfAssessment = ExperienceLevel.zero,
      CefrLevel difficulty = CefrLevel.preA1,
      List<PlacementAnswer> answers = const [],
      List<PlacementEvaluation> evaluations = const [],
    }) {
      return PlacementSession(
        id: 'test_session',
        userId: 'u_test',
        targetLanguage: const SupportedLanguage(
          id: 'en',
          nameEn: 'English',
          nameAr: 'الإنجليزية',
          flagEmoji: '🇬🇧',
        ),
        nativeLanguage: NativeLanguage.arabic,
        ageGroup: AgeGroup.age19_25,
        learningGoal: const LearningGoal(id: 'conversation', icon: '🗣️'),
        initialSelfAssessment: selfAssessment,
        currentDifficulty: difficulty,
        startedAt: DateTime.now(),
        answers: answers,
        evaluations: evaluations,
      );
    }

    test('1 & 2. Beginner ("ولا كلمة تقريبًا") starts at PreA1', () {
      final diffZero = engine.determineInitialDifficulty(ExperienceLevel.zero);
      expect(diffZero, CefrLevel.preA1);

      final diffBasic = engine.determineInitialDifficulty(
        ExperienceLevel.basic,
      );
      expect(diffBasic, CefrLevel.a1);

      final diffAdv = engine.determineInitialDifficulty(
        ExperienceLevel.advanced,
      );
      expect(diffAdv, CefrLevel.b2);
    });

    test('3. Strong answer increases difficulty', () {
      final session = createTestSession(difficulty: CefrLevel.a1);

      const strongEval = PlacementEvaluation(
        semanticScore: 90,
        grammarScore: 85,
        vocabularyScore: 90,
        comprehensionScore: 90,
        fluencyScore: 85,
        pronunciationScore: null,
        confidence: 0.9,
        explanationArabic: 'ممتاز',
        wasUnderstandable: true,
        shouldIncreaseDifficulty: true,
        shouldDecreaseDifficulty: false,
      );

      final nextDiff = engine.calculateNextDifficulty(session, strongEval);
      expect(nextDiff, CefrLevel.a2);
    });

    test('4. Weak answer decreases difficulty', () {
      final session = createTestSession(difficulty: CefrLevel.b1);

      const weakEval = PlacementEvaluation(
        semanticScore: 20,
        grammarScore: 20,
        vocabularyScore: 20,
        comprehensionScore: 20,
        fluencyScore: 20,
        pronunciationScore: null,
        confidence: 0.8,
        explanationArabic: 'بسيط',
        wasUnderstandable: false,
        shouldIncreaseDifficulty: false,
        shouldDecreaseDifficulty: true,
      );

      final nextDiff = engine.calculateNextDifficulty(session, weakEval);
      expect(nextDiff, CefrLevel.a2);
    });

    test('5. Difficulty stays within allowed bounds (PreA1 to C2)', () {
      final minSession = createTestSession(difficulty: CefrLevel.preA1);
      const weakEval = PlacementEvaluation(
        semanticScore: 10,
        grammarScore: 10,
        vocabularyScore: 10,
        comprehensionScore: 10,
        fluencyScore: 10,
        confidence: 0.9,
        explanationArabic: 'ضعيف',
        wasUnderstandable: false,
        shouldIncreaseDifficulty: false,
        shouldDecreaseDifficulty: true,
      );
      expect(
        engine.calculateNextDifficulty(minSession, weakEval),
        CefrLevel.preA1,
      );

      final maxSession = createTestSession(difficulty: CefrLevel.c2);
      const strongEval = PlacementEvaluation(
        semanticScore: 95,
        grammarScore: 95,
        vocabularyScore: 95,
        comprehensionScore: 95,
        fluencyScore: 95,
        confidence: 0.9,
        explanationArabic: 'ممتاز',
        wasUnderstandable: true,
        shouldIncreaseDifficulty: true,
        shouldDecreaseDifficulty: false,
      );
      expect(
        engine.calculateNextDifficulty(maxSession, strongEval),
        CefrLevel.c2,
      );
    });

    test('6 & 7. Stopping criteria enforces min and max question bounds', () {
      // Below minQuestions (3 answers) -> should NOT stop
      final shortAnswers = List.generate(
        3,
        (i) => PlacementAnswer(
          questionId: 'q$i',
          userResponse: 'Answer $i',
          responseDuration: const Duration(seconds: 4),
          skipped: false,
          submittedAt: DateTime.now(),
        ),
      );
      final sessionShort = createTestSession(answers: shortAnswers);
      expect(engine.shouldStop(sessionShort), isFalse);

      // Above maxQuestions (12 answers) -> MUST stop
      final maxAnswers = List.generate(
        12,
        (i) => PlacementAnswer(
          questionId: 'q$i',
          userResponse: 'Answer $i',
          responseDuration: const Duration(seconds: 4),
          skipped: false,
          submittedAt: DateTime.now(),
        ),
      );
      final sessionMax = createTestSession(answers: maxAnswers);
      expect(engine.shouldStop(sessionMax), isTrue);
    });

    test('8. Typed text responses have no fake pronunciation score', () {
      final session = createTestSession(
        evaluations: [
          const PlacementEvaluation(
            semanticScore: 80,
            grammarScore: 80,
            vocabularyScore: 80,
            comprehensionScore: 80,
            fluencyScore: 80,
            pronunciationScore: null, // Strictly null
            confidence: 0.9,
            explanationArabic: 'جيد',
            wasUnderstandable: true,
            shouldIncreaseDifficulty: false,
            shouldDecreaseDifficulty: false,
          ),
        ],
      );

      final result = engine.calculateFinalResult(session);
      expect(result.pronunciationScore, isNull);
    });

    test('10 & 11. PlacementResult converts to LearningProfile', () {
      final session = createTestSession(
        difficulty: CefrLevel.a2,
        evaluations: [
          const PlacementEvaluation(
            semanticScore: 75,
            grammarScore: 70,
            vocabularyScore: 80,
            comprehensionScore: 85,
            fluencyScore: 75,
            confidence: 0.85,
            explanationArabic: 'ممتاز',
            wasUnderstandable: true,
            shouldIncreaseDifficulty: false,
            shouldDecreaseDifficulty: false,
          ),
        ],
      );

      final result = engine.calculateFinalResult(session);
      expect(result.estimatedCefrLevel, CefrLevel.a2);
      expect(result.comprehensionScore, 85);
      expect(result.vocabularyScore, 80);

      final profile = result.toLearningProfile(
        userId: 'user_456',
        targetLanguage: 'en',
      );
      expect(profile.userId, 'user_456');
      expect(profile.targetLanguage, 'en');
      expect(profile.estimatedCefrLevel, CefrLevel.a2);
      expect(profile.pronunciationScore, isNull);
    });
  });
}
