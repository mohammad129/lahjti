import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/progress/domain/models/achievement_models.dart';
import 'package:lahjti/features/progress/domain/services/achievement_evaluator.dart';

void main() {
  group('AchievementEvaluator Domain Service Tests', () {
    const evaluator = AchievementEvaluator();

    test('1. Default achievements catalog contains 9 standard milestones', () {
      final defaults = evaluator.defaultAchievements;
      expect(defaults.length, 9);
      expect(defaults.every((a) => !a.isUnlocked), isTrue);
      expect(defaults.every((a) => a.currentValue == 0), isTrue);
    });

    test(
      '2. Completing first lesson unlocks first_lesson achievement with timestamp',
      () {
        final now = DateTime(2026, 9, 10);
        final evaluated = evaluator.evaluateAchievements(
          currentList: const [],
          completedLessonsCount: 1,
          masteredVocabCount: 0,
          currentStreak: 1,
          completedExamsCount: 0,
          tutorTurnsCount: 0,
          totalXp: 50,
          now: now,
        );

        final firstLesson = evaluated.firstWhere((a) => a.id == 'first_lesson');
        expect(firstLesson.isUnlocked, isTrue);
        expect(firstLesson.unlockedAt, now);
        expect(firstLesson.currentValue, 1);
      },
    );

    test(
      '3. Reaching 25 mastered vocabulary words unlocks vocab_25 but keeps vocab_50 in progress',
      () {
        final now = DateTime(2026, 9, 10);
        final evaluated = evaluator.evaluateAchievements(
          currentList: const [],
          completedLessonsCount: 2,
          masteredVocabCount: 25,
          currentStreak: 2,
          completedExamsCount: 0,
          tutorTurnsCount: 0,
          totalXp: 180,
          now: now,
        );

        final vocab25 = evaluated.firstWhere((a) => a.id == 'vocab_25');
        final vocab50 = evaluated.firstWhere((a) => a.id == 'vocab_50');

        expect(vocab25.isUnlocked, isTrue);
        expect(vocab25.progressRatio, 1.0);

        expect(vocab50.isUnlocked, isFalse);
        expect(vocab50.currentValue, 25);
        expect(vocab50.progressRatio, 0.5);
      },
    );

    test('4. Streak of 3 and 7 days unlock respective badges', () {
      final now = DateTime(2026, 9, 10);
      final evaluated3 = evaluator.evaluateAchievements(
        currentList: const [],
        completedLessonsCount: 3,
        masteredVocabCount: 10,
        currentStreak: 3,
        completedExamsCount: 1,
        tutorTurnsCount: 2,
        totalXp: 300,
        now: now,
      );

      final streak3 = evaluated3.firstWhere((a) => a.id == 'streak_3');
      final streak7 = evaluated3.firstWhere((a) => a.id == 'streak_7');

      expect(streak3.isUnlocked, isTrue);
      expect(streak7.isUnlocked, isFalse);
      expect(streak7.currentValue, 3);
    });

    test(
      '5. Already unlocked achievements preserve original unlock date and state',
      () {
        final originalDate = DateTime(2026, 9, 1);
        final newDate = DateTime(2026, 9, 15);

        final unlockedAchievement = Achievement(
          id: 'first_lesson',
          titleArabic: 'الخطوة الأولى',
          titleEnglish: 'First Step',
          descriptionArabic: 'أول درس',
          descriptionEnglish: 'First lesson',
          iconEmoji: '🚀',
          category: AchievementCategory.lessons,
          isUnlocked: true,
          unlockedAt: originalDate,
          currentValue: 1,
          targetValue: 1,
        );

        final evaluated = evaluator.evaluateAchievements(
          currentList: [unlockedAchievement],
          completedLessonsCount: 5,
          masteredVocabCount: 0,
          currentStreak: 1,
          completedExamsCount: 0,
          tutorTurnsCount: 0,
          totalXp: 200,
          now: newDate,
        );

        final result = evaluated.firstWhere((a) => a.id == 'first_lesson');
        expect(result.isUnlocked, isTrue);
        expect(result.unlockedAt, originalDate);
      },
    );
  });
}
