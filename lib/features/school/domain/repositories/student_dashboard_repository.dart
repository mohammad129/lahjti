import '../models/daily_task.dart';
import '../models/game_models.dart';
import '../models/student_progress_summary.dart';

/// Contract for student school operations, tasks, games, and progress.
abstract class StudentDashboardRepository {
  /// Retrieves today's active daily tasks for a student.
  Future<List<DailyTask>> getDailyTasks({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  });

  /// Marks a daily task as completed, awards XP, and updates progress.
  Future<DailyTask> completeDailyTask({
    required String studentId,
    required String taskId,
    required String schoolCode,
  });

  /// Retrieves available educational mini-games catalog.
  Future<List<GameActivity>> getAvailableGames({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  });

  /// Retrieves a specific game activity by its ID.
  Future<GameActivity?> getGameById({
    required String gameId,
    required String studentId,
    required String schoolCode,
  });

  /// Submits the result of playing a mini-game, awards XP, and completes matching tasks.
  Future<GameResult> submitGameResult({
    required String studentId,
    required String schoolCode,
    required GameResult result,
  });

  /// Retrieves the student's daily progress and gamification summary.
  Future<StudentProgressSummary> getStudentProgressSummary({
    required String studentId,
    required String schoolCode,
  });

  /// Retrieves unlocked achievements for the student.
  Future<List<String>> getStudentAchievements({
    required String studentId,
    required String schoolCode,
  });
}
