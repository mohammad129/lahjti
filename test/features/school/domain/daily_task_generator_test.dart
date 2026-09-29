import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/learning/domain/models/learner_progress.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/lesson_models.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/school/domain/models/daily_task.dart';
import 'package:lahjti/features/school/domain/services/daily_task_generator.dart';

void main() {
  group('DailyTaskGenerator Unit Tests', () {
    const generator = DailyTaskGenerator();

    final mockProfile = LearningProfile(
      userId: 'stu_01',
      targetLanguage: 'ar_levantine',
      estimatedCefrLevel: CefrLevel.a2,
      overallScore: 80,
      comprehensionScore: 85,
      vocabularyScore: 80,
      grammarScore: 80,
      listeningScore: 85,
      speakingScore: 78,
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 9, 21),
    );

    final mockProgress = LearnerProgress(
      completedLessonIds: const [],
      lastSessionDate: DateTime(2026, 9, 21),
      totalXp: 400,
      dailyStreak: 4,
    );

    const mockLessons = [
      Lesson(
        id: 'les_01',
        moduleId: 'mod_01',
        month: 1,
        order: 1,
        title: 'Ordering Food',
        titleArabic: 'طلب الطعام',
        description: 'Learn restaurant phrases',
        descriptionArabic: 'تعلم عبارات المطعم',
        cefrLevel: CefrLevel.a2,
        primarySkill: LearningSkill.speaking,
        estimatedMinutes: 8,
        steps: [],
      ),
    ];

    test('1. Generates manageable set of 5 deterministic daily tasks', () {
      final tasks = generator.generateDailyTasks(
        profile: mockProfile,
        progress: mockProgress,
        vocabularyList: const [],
        availableLessons: mockLessons,
        isChild: false,
      );

      expect(tasks.length, 5);
      expect(tasks.any((t) => t.type == DailyTaskType.lesson), isTrue);
      expect(tasks.any((t) => t.type == DailyTaskType.vocabulary), isTrue);
      expect(tasks.any((t) => t.type == DailyTaskType.game), isTrue);
      expect(tasks.any((t) => t.type == DailyTaskType.conversation), isTrue);
    });

    test(
      '2. Adapts targeted task to grammar reinforcement when grammarScore is weak (<65)',
      () {
        final weakGrammarProfile = mockProfile.copyWith(grammarScore: 50);
        final tasks = generator.generateDailyTasks(
          profile: weakGrammarProfile,
          progress: mockProgress,
          vocabularyList: const [],
          availableLessons: mockLessons,
          isChild: false,
        );

        final grammarTask = tasks.firstWhere(
          (t) => t.skill == LearningSkill.grammar,
        );
        expect(grammarTask.id, 'task_adaptive_grammar');
        expect(grammarTask.type, DailyTaskType.grammar);
      },
    );

    test(
      '3. Child mode generates kid-friendly titles, visual emojis, and shorter durations',
      () {
        final childTasks = generator.generateDailyTasks(
          profile: mockProfile,
          progress: mockProgress,
          vocabularyList: const [],
          availableLessons: mockLessons,
          isChild: true,
        );

        expect(childTasks.every((t) => t.isForChild), isTrue);
        expect(childTasks.first.titleArabic, contains('مغامرة الدرس'));
        expect(childTasks.every((t) => t.estimatedMinutes <= 6), isTrue);
      },
    );
  });
}
