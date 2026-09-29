import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/data/repositories/local_learning_repository.dart';
import 'package:lahjti/features/learning/presentation/providers/learning_providers.dart';
import 'package:lahjti/features/progress/domain/models/streak_models.dart';
import 'package:lahjti/features/progress/presentation/providers/progress_providers.dart';

void main() {
  group('Progress Providers State & Aggregation Tests', () {
    test(
      '1. LearnerLevel provider calculates levels correctly based on total XP',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(learnerProgressProvider.notifier).state = container
            .read(learnerProgressProvider)
            .copyWith(totalXp: 50);

        final level1 = container.read(learnerLevelProvider);
        expect(level1.level, 1);

        container.read(learnerProgressProvider.notifier).state = container
            .read(learnerProgressProvider)
            .copyWith(totalXp: 180);

        final level2 = container.read(learnerLevelProvider);
        expect(level2.level, 2);
        expect(level2.titleArabic, contains('متعلم شغوف'));
      },
    );

    test(
      '2. DailyGoal provider computes XP goal progress and remaining points',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final goal = container.read(dailyGoalProvider);
        expect(goal.targetXp, 50);
        expect(goal.isCompleted, isFalse);
        expect(goal.remainingXp, greaterThanOrEqualTo(0));
      },
    );

    test('3. StreakData provider reflects current active streak', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final streak = container.read(streakDataProvider);
      expect(streak.currentStreak, 1);

      container.read(learnerProgressProvider.notifier).state = container
          .read(learnerProgressProvider)
          .copyWith(
            streakData: const StreakData(
              currentStreak: 3,
              longestStreak: 5,
              totalActiveDays: 8,
            ),
          );

      final updatedStreak = container.read(streakDataProvider);
      expect(updatedStreak.currentStreak, 3);
      expect(updatedStreak.longestStreak, 5);
    });

    test(
      '4. Daily and Weekly progress summaries fetch successfully from repository',
      () async {
        final repo = LocalLearningRepository();
        final container = ProviderContainer(
          overrides: [learningRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final daily = await container.read(dailyProgressSummaryProvider.future);
        expect(daily.xpEarned, greaterThan(0));

        final weekly = await container.read(
          weeklyProgressSummaryProvider.future,
        );
        expect(weekly.activeDaysMap.length, 7);
        expect(weekly.activeDaysCount, greaterThanOrEqualTo(0));
      },
    );
  });
}
