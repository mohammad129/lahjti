import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/school/data/repositories/in_memory_student_dashboard_repository.dart';
import 'package:lahjti/features/school/domain/models/game_models.dart';

void main() {
  group('InMemoryStudentDashboardRepository Unit Tests', () {
    late InMemoryStudentDashboardRepository repo;

    setUp(() {
      repo = InMemoryStudentDashboardRepository(seedDefaults: true);
    });

    test(
      '1. Retrieves seeded daily tasks and initial progress summary',
      () async {
        final tasks = await repo.getDailyTasks(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        expect(tasks, isNotEmpty);
        expect(tasks.length, 5);

        final summary = await repo.getStudentProgressSummary(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        expect(summary.studentId, 'stu_sami_01');
        expect(summary.totalXp, 450);
        expect(summary.streakDays, 5);
      },
    );

    test(
      '2. Completing a daily task awards XP and updates summary progress ratio',
      () async {
        final tasks = await repo.getDailyTasks(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        final taskToComplete = tasks.first;
        final completed = await repo.completeDailyTask(
          studentId: 'stu_sami_01',
          taskId: taskToComplete.id,
          schoolCode: 'SCH-1001',
        );

        expect(completed.completed, isTrue);
        expect(completed.progress, 1.0);

        final summary = await repo.getStudentProgressSummary(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        expect(summary.totalXp, 450 + taskToComplete.xpReward);
        expect(summary.completedTasksTodayCount, 1);
        expect(summary.todayProgressRatio, 1 / 5);
      },
    );

    test('3. Retrieves educational mini-games catalog', () async {
      final games = await repo.getAvailableGames(
        studentId: 'stu_sami_01',
        schoolCode: 'SCH-1001',
      );

      expect(games.length, greaterThanOrEqualTo(5));
      expect(games.any((g) => g.gameType == GameType.wordMatch), isTrue);
      expect(games.any((g) => g.gameType == GameType.listenAndChoose), isTrue);
      expect(
        games.any((g) => g.gameType == GameType.pictureWordSelect),
        isTrue,
      );
      expect(games.any((g) => g.gameType == GameType.sentenceBuilder), isTrue);
      expect(games.any((g) => g.gameType == GameType.memoryVocab), isTrue);
      expect(games.any((g) => g.gameType == GameType.quickQuiz), isTrue);
    });

    test(
      '4. Submitting a passed game result auto-completes matching game daily task and awards XP',
      () async {
        final result = GameResult(
          gameId: 'game_word_match',
          gameType: GameType.wordMatch,
          totalQuestions: 1,
          correctAnswers: 1,
          scorePercentage: 100.0,
          earnedXp: 30,
          completedAt: DateTime.now(),
          passed: true,
        );

        final submitted = await repo.submitGameResult(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
          result: result,
        );

        expect(submitted.passed, isTrue);

        final tasks = await repo.getDailyTasks(
          studentId: 'stu_sami_01',
          schoolCode: 'SCH-1001',
        );

        final gameTask = tasks.firstWhere((t) => t.gameId == 'game_word_match');
        expect(gameTask.completed, isTrue);
      },
    );
  });
}
