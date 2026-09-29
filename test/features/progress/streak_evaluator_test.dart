import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/progress/domain/models/streak_models.dart';
import 'package:lahjti/features/progress/domain/services/streak_evaluator.dart';

void main() {
  group('StreakEvaluator Domain Service Tests', () {
    const evaluator = StreakEvaluator();

    test('1. First ever learning activity initializes streak to 1', () {
      final initial = StreakData.initial();
      final now = DateTime(2026, 9, 1);

      final result = evaluator.evaluateActivity(
        currentStreak: initial,
        activityTime: now,
      );

      expect(result.updatedStreak.currentStreak, 1);
      expect(result.updatedStreak.longestStreak, 1);
      expect(result.updatedStreak.totalActiveDays, 1);
      expect(result.didIncrement, isTrue);
      expect(result.didBreakLongestRecord, isTrue);
    });

    test(
      '2. Multiple activities on the same calendar day do not duplicate streak increment',
      () {
        final day1 = DateTime(2026, 9, 1, 9, 0);
        final day1Later = DateTime(2026, 9, 1, 18, 30);

        final streak1 = StreakData(
          currentStreak: 3,
          longestStreak: 5,
          lastActiveDate: day1,
          totalActiveDays: 10,
        );

        final result = evaluator.evaluateActivity(
          currentStreak: streak1,
          activityTime: day1Later,
        );

        expect(result.updatedStreak.currentStreak, 3);
        expect(result.updatedStreak.longestStreak, 5);
        expect(result.updatedStreak.totalActiveDays, 10);
        expect(result.didIncrement, isFalse);
      },
    );

    test(
      '3. Next consecutive calendar day increments streak by 1 and updates record',
      () {
        final day1 = DateTime(2026, 9, 1, 20, 0);
        final day2 = DateTime(2026, 9, 2, 8, 0);

        final streak = StreakData(
          currentStreak: 4,
          longestStreak: 4,
          lastActiveDate: day1,
          totalActiveDays: 8,
        );

        final result = evaluator.evaluateActivity(
          currentStreak: streak,
          activityTime: day2,
        );

        expect(result.updatedStreak.currentStreak, 5);
        expect(result.updatedStreak.longestStreak, 5);
        expect(result.updatedStreak.totalActiveDays, 9);
        expect(result.didIncrement, isTrue);
        expect(result.didBreakLongestRecord, isTrue);
      },
    );

    test(
      '4. Missed day resets current streak smoothly to 1 while preserving longest record',
      () {
        final day1 = DateTime(2026, 9, 1);
        final day4 = DateTime(2026, 9, 4); // 3 days later

        final streak = StreakData(
          currentStreak: 6,
          longestStreak: 12,
          lastActiveDate: day1,
          totalActiveDays: 20,
        );

        final result = evaluator.evaluateActivity(
          currentStreak: streak,
          activityTime: day4,
        );

        expect(result.updatedStreak.currentStreak, 1);
        expect(result.updatedStreak.longestStreak, 12);
        expect(result.updatedStreak.totalActiveDays, 21);
        expect(result.didBreakLongestRecord, isFalse);
      },
    );

    test(
      '5. Past date or clock manipulation protects streak without crashing',
      () {
        final day5 = DateTime(2026, 9, 5);
        final pastDate = DateTime(2026, 9, 2);

        final streak = StreakData(
          currentStreak: 5,
          longestStreak: 5,
          lastActiveDate: day5,
          totalActiveDays: 10,
        );

        final result = evaluator.evaluateActivity(
          currentStreak: streak,
          activityTime: pastDate,
        );

        expect(result.updatedStreak.currentStreak, 5);
        expect(result.didIncrement, isFalse);
      },
    );
  });
}
