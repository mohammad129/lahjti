import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/progress/domain/models/xp_models.dart';
import 'package:lahjti/features/progress/domain/services/xp_calculator.dart';

void main() {
  group('XpCalculator Domain Service Tests', () {
    const calculator = XpCalculator();

    test(
      '1. Valid lesson completion earns correct base XP and scales with accuracy',
      () {
        final perfectXp = calculator.calculateActivityXp(
          activityType: XpActivityType.lessonCompletion,
          accuracyPercentage: 100,
        );
        expect(perfectXp, 63); // 50 * 1.25 bonus

        final standardXp = calculator.calculateActivityXp(
          activityType: XpActivityType.lessonCompletion,
          accuracyPercentage: 70,
        );
        expect(standardXp, 50); // 50 base
      },
    );

    test('2. Vocabulary practice awards proportional XP per word learned', () {
      final xp10Words = calculator.calculateActivityXp(
        activityType: XpActivityType.vocabularyPractice,
        itemsCount: 10,
      );
      expect(xp10Words, 40); // 10 * 4

      final xpDuplicate = calculator.calculateActivityXp(
        activityType: XpActivityType.vocabularyPractice,
        isDuplicateAttempt: true,
      );
      expect(xpDuplicate, 4); // clamped anti-farming XP
    });

    test(
      '3. Exam completion scales with overall score and passes minimum threshold',
      () {
        final examHigh = calculator.calculateActivityXp(
          activityType: XpActivityType.examCompletion,
          accuracyPercentage: 90,
        );
        expect(examHigh, 125); // 100 * 1.25 bonus

        final examLow = calculator.calculateActivityXp(
          activityType: XpActivityType.examCompletion,
          accuracyPercentage: 20,
        );
        expect(examLow, 40); // 100 * 0.40 effort acknowledgement
      },
    );

    test('4. Anti-farming bounds prevent negative or unbounded XP', () {
      final emptyAttempt = calculator.calculateActivityXp(
        activityType: XpActivityType.lessonCompletion,
        accuracyPercentage: -50,
      );
      expect(emptyAttempt, 0); // 0 XP for empty/skipped attempt

      final duplicateLesson = calculator.calculateActivityXp(
        activityType: XpActivityType.lessonCompletion,
        isDuplicateAttempt: true,
      );
      expect(duplicateLesson, lessThanOrEqualTo(10));
    });

    test('5. LearnerLevel deterministic calculation across XP thresholds', () {
      expect(LearnerLevel.fromTotalXp(0).level, 1);
      expect(LearnerLevel.fromTotalXp(99).level, 1);
      expect(LearnerLevel.fromTotalXp(100).level, 2);
      expect(LearnerLevel.fromTotalXp(250).level, 3);
      expect(LearnerLevel.fromTotalXp(500).level, 4);
      expect(LearnerLevel.fromTotalXp(900).level, 5);
      expect(LearnerLevel.fromTotalXp(1500).level, 6);
      expect(LearnerLevel.fromTotalXp(2300).level, 7);
      expect(LearnerLevel.fromTotalXp(3300).level, 8);
    });
  });
}
