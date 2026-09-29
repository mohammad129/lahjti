import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/curriculum/starter_curriculum.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';

void main() {
  group('LearningProfile & Curriculum Domain Tests', () {
    test(
      '1. LearningProfile preserves null pronunciationScore for text placement baseline',
      () {
        final profile = LearningProfile.defaultProfile(
          userId: 'u_test_1',
          targetLanguage: 'english',
          level: CefrLevel.a1,
        );

        expect(profile.userId, 'u_test_1');
        expect(profile.targetLanguage, 'english');
        expect(profile.estimatedCefrLevel, CefrLevel.a1);
        expect(profile.pronunciationScore, isNull);
        expect(profile.strengths, isNotEmpty);
        expect(profile.weaknesses, isNotEmpty);
        expect(profile.recommendedFocusAreas, isNotEmpty);
      },
    );

    test(
      '2. LearnerProgress tracks completed lessons and total learning time',
      () {
        final initial = LearnerProgress(lastSessionDate: DateTime.now());
        expect(initial.completedLessonIds, isEmpty);
        expect(initial.isLessonCompleted('lesson_1_1'), isFalse);

        final updated = initial.copyWith(
          completedLessonIds: ['lesson_1_1'],
          totalMinutesLearned: 8,
        );

        expect(updated.completedLessonIds.length, 1);
        expect(updated.isLessonCompleted('lesson_1_1'), isTrue);
        expect(updated.totalMinutesLearned, 8);
      },
    );

    test(
      '3. StarterCurriculum provides 3-Month modules and structured lesson steps',
      () {
        final modules = StarterCurriculum.modules;
        expect(modules.length, greaterThanOrEqualTo(3));

        // Month 1 Foundation
        final month1Modules = modules.where((m) => m.month == 1).toList();
        expect(month1Modules, isNotEmpty);
        expect(month1Modules.first.themeArabic, contains('التحيات'));

        // Month 2 Real Life
        final month2Modules = modules.where((m) => m.month == 2).toList();
        expect(month2Modules, isNotEmpty);

        // Month 3 Communication
        final month3Modules = modules.where((m) => m.month == 3).toList();
        expect(month3Modules, isNotEmpty);

        // Lesson 1.1 structure
        final lesson1 = month1Modules.first.lessons.first;
        expect(lesson1.steps, isNotEmpty);
        expect(lesson1.primarySkill, LearningSkill.speaking);
        expect(lesson1.targetVocabulary, contains('hello'));
      },
    );
  });
}
