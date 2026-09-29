import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/school/domain/models/daily_task.dart';
import 'package:lahjti/features/school/domain/models/student_progress_summary.dart';

void main() {
  group('DailyTask & Student Progress Domain Models Tests', () {
    test('1. DailyTask properties, copyWith, and JSON serialization', () {
      final now = DateTime(2026, 9, 21);
      final task = DailyTask(
        id: 'task_01',
        titleArabic: 'مراجعة الكلمات',
        titleEnglish: 'Review Words',
        descriptionArabic: 'تثبيت المفردات',
        descriptionEnglish: 'Review vocabulary',
        type: DailyTaskType.vocabulary,
        skill: LearningSkill.vocabulary,
        estimatedMinutes: 5,
        xpReward: 20,
        completed: false,
        progress: 0.0,
        dueDate: now,
        actionRoute: '/vocabulary/practice',
        isForChild: false,
      );

      expect(task.id, 'task_01');
      expect(task.type.iconEmoji, '🗂️');
      expect(task.localizedTitle(true), 'مراجعة الكلمات');
      expect(task.localizedTitle(false), 'Review Words');

      final json = task.toJson();
      final fromJson = DailyTask.fromJson(json);

      expect(fromJson.id, task.id);
      expect(fromJson.type, DailyTaskType.vocabulary);
      expect(fromJson.xpReward, 20);
      expect(fromJson.completed, isFalse);

      final completedTask = task.copyWith(completed: true, progress: 1.0);
      expect(completedTask.completed, isTrue);
      expect(completedTask.progress, 1.0);
    });

    test('2. DailyTaskType enum parsing and icon emojis', () {
      expect(DailyTaskType.fromString('game'), DailyTaskType.game);
      expect(
        DailyTaskType.fromString('conversation'),
        DailyTaskType.conversation,
      );
      expect(DailyTaskType.fromString('unknown'), DailyTaskType.lesson);

      expect(DailyTaskType.game.iconEmoji, '🎮');
      expect(DailyTaskType.speaking.iconEmoji, '🎙️');
      expect(DailyTaskType.listening.iconEmoji, '🎧');
    });

    test(
      '3. StudentProgressSummary calculates ratio and daily goal completion',
      () {
        final summary = StudentProgressSummary(
          studentId: 'stu_01',
          totalXp: 500,
          streakDays: 4,
          completedTasksTodayCount: 3,
          totalTasksTodayCount: 5,
          todayProgressRatio: 0.60,
          currentLevel: 'A2',
          hasCompletedDailyGoal: true,
          dailyGoalTarget: 3,
        );

        expect(summary.hasCompletedDailyGoal, isTrue);
        expect(summary.todayProgressRatio, 0.60);

        final json = summary.toJson();
        final fromJson = StudentProgressSummary.fromJson(json);
        expect(fromJson.totalXp, 500);
        expect(fromJson.streakDays, 4);
      },
    );
  });
}
