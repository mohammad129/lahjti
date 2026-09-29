import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learner_context.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_recommendation.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/lesson_models.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/learning/domain/services/adaptive_learning_engine.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('LearnerContext & Unified Personalization Tests', () {
    test(
      '1. LearnerContext creates default values and serializes to gateway payload',
      () {
        const context = LearnerContext(
          targetLanguage: 'english',
          nativeLanguage: 'arabic',
          ageGroup: 'adult',
          cefrLevel: CefrLevel.a2,
          learningGoal: 'travel',
          currentLessonTitle: 'At the Airport',
          currentTopic: 'Travel & Transport',
          targetSkill: LearningSkill.speaking,
          targetVocabulary: ['passport', 'boarding pass', 'gate', 'flight'],
          weaknesses: ['past_tense', 'articles'],
          strengths: ['vocabulary_recall'],
        );

        final payload = context.toGatewayPayload();

        expect(payload['targetLanguage'], 'english');
        expect(payload['nativeLanguage'], 'arabic');
        expect(payload['ageGroup'], 'adult');
        expect(payload['difficulty'], 'a2');
        expect(payload['learningGoal'], 'travel');
        expect(payload['currentLessonTitle'], 'At the Airport');
        expect(payload['currentTopic'], 'Travel & Transport');
        expect(payload['targetSkill'], 'speaking');
        expect(payload['targetVocabulary'], contains('passport'));
        expect(payload['recentWeaknesses'], contains('past_tense'));
        expect(payload['recentStrengths'], contains('vocabulary_recall'));
      },
    );

    test(
      '2. Adaptive learning engine prioritizes vocabulary review when items are due',
      () {
        const engine = AdaptiveLearningEngine();
        final profile = LearningProfile.defaultProfile(userId: 'u1');
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          inProgressLessonId: 'lesson_1_2',
          masteredVocabCount: 5,
          reviewQueueCount: 3,
          lastSessionDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final dueItem = VocabularyItem(
          id: 'v1',
          term: 'apple',
          translationArabic: 'تفاحة',
          exampleSentence: 'I eat an apple.',
          exampleTranslationArabic: 'أنا آكل تفاحة.',
          difficulty: CefrLevel.a1,
          category: 'Food',
          nextReview: DateTime.now().subtract(const Duration(hours: 2)),
        );

        const lesson = Lesson(
          id: 'lesson_1_2',
          moduleId: 'mod_1',
          month: 1,
          title: 'Food & Drinks',
          titleArabic: 'الطعام والمشروبات',
          description: 'Order food and drinks',
          descriptionArabic: 'اطلب الطعام والمشروبات',
          primarySkill: LearningSkill.vocabulary,
          cefrLevel: CefrLevel.a1,
          order: 2,
          steps: [],
          targetVocabulary: ['apple', 'water'],
        );

        final recommendation = engine.generateDailyRecommendation(
          profile: profile,
          progress: progress,
          vocabularyItems: [dueItem],
          availableLessons: const [lesson],
        );

        expect(recommendation.type, RecommendationType.reviewVocabulary);
        expect(recommendation.titleArabic, contains('المفردات'));
      },
    );

    test(
      '3. Adaptive learning engine recommends continuing lesson when in progress',
      () {
        const engine = AdaptiveLearningEngine();
        final profile = LearningProfile.defaultProfile(
          userId: 'u1',
        ).copyWith(currentLessonId: 'lesson_1_2');
        final progress = LearnerProgress(
          completedLessonIds: const ['lesson_1_1'],
          inProgressLessonId: 'lesson_1_2',
          masteredVocabCount: 5,
          reviewQueueCount: 0,
          lastSessionDate: DateTime.now(),
        );

        const lesson = Lesson(
          id: 'lesson_1_2',
          moduleId: 'mod_1',
          month: 1,
          title: 'Food & Drinks',
          titleArabic: 'الطعام والمشروبات',
          description: 'Order food and drinks',
          descriptionArabic: 'اطلب الطعام والمشروبات',
          primarySkill: LearningSkill.vocabulary,
          cefrLevel: CefrLevel.a1,
          order: 2,
          steps: [],
        );

        final recommendation = engine.generateDailyRecommendation(
          profile: profile,
          progress: progress,
          vocabularyItems: const [],
          availableLessons: const [lesson],
        );

        expect(recommendation.type, RecommendationType.continueLesson);
        expect(recommendation.targetLessonId, 'lesson_1_2');
      },
    );

    test('4. LearnerContext copyWith updates targeted fields safely', () {
      const initial = LearnerContext(
        targetLanguage: 'english',
        cefrLevel: CefrLevel.a1,
        totalXp: 100,
      );

      final updated = initial.copyWith(
        cefrLevel: CefrLevel.b1,
        totalXp: 250,
        currentLessonTitle: 'New Lesson',
      );

      expect(updated.targetLanguage, 'english');
      expect(updated.cefrLevel, CefrLevel.b1);
      expect(updated.totalXp, 250);
      expect(updated.currentLessonTitle, 'New Lesson');
    });
  });
}
