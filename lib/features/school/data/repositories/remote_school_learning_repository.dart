import 'dart:convert';
import 'dart:developer' as developer;
import '../../../../core/network/api_client.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../domain/models/daily_task.dart';
import '../../domain/models/game_models.dart';
import '../../domain/models/student_progress_summary.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import 'in_memory_student_dashboard_repository.dart';

/// Real backend implementation of [StudentDashboardRepository] connecting to the authenticated API.
///
/// Follows Clean Architecture:
/// UI -> Riverpod -> RemoteSchoolLearningRepository -> ApiClient (Dio) -> Backend Server -> PostgreSQL.
/// Identity is derived strictly server-side from JWT tokens.
class RemoteSchoolLearningRepository implements StudentDashboardRepository {
  final ApiClient _apiClient;
  final InMemoryStudentDashboardRepository _localCatalogFallback;

  RemoteSchoolLearningRepository(
    this._apiClient, {
    InMemoryStudentDashboardRepository? localCatalogFallback,
  }) : _localCatalogFallback =
           localCatalogFallback ?? InMemoryStudentDashboardRepository();

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  /// 1. Fetch deterministic daily tasks from server
  @override
  Future<List<DailyTask>> getDailyTasks({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  }) async {
    try {
      final response = await _apiClient.get('/student/tasks');
      final bodyMap = _extractMap(response.data);
      final rawList = bodyMap?['data'] as List<dynamic>?;
      if (rawList != null && rawList.isNotEmpty) {
        return rawList.map((item) {
          final map = item as Map<String, dynamic>;
          return _mapTaskFromJson(map);
        }).toList();
      }
    } catch (e) {
      developer.log(
        'RemoteSchoolLearningRepository.getDailyTasks network error: $e',
        name: 'RemoteSchoolLearningRepository',
      );
    }

    // Fallback to deterministic local generator if network is unavailable
    return _localCatalogFallback.getDailyTasks(
      studentId: studentId,
      schoolCode: schoolCode,
      isChild: isChild,
    );
  }

  /// 2. Complete daily task with server-authoritative XP and anti-farming
  @override
  Future<DailyTask> completeDailyTask({
    required String studentId,
    required String taskId,
    required String schoolCode,
  }) async {
    try {
      final response = await _apiClient.post('/student/tasks/$taskId/complete');
      final bodyMap = _extractMap(response.data);
      final data = bodyMap?['data'] as Map<String, dynamic>?;
      if (data != null && data['task'] != null) {
        final taskMap = data['task'] as Map<String, dynamic>;
        return _mapTaskFromJson(taskMap);
      }
    } catch (e) {
      developer.log(
        'RemoteSchoolLearningRepository.completeDailyTask network error: $e',
        name: 'RemoteSchoolLearningRepository',
      );
    }

    return _localCatalogFallback.completeDailyTask(
      studentId: studentId,
      taskId: taskId,
      schoolCode: schoolCode,
    );
  }

  /// 3. Get available educational mini-games
  @override
  Future<List<GameActivity>> getAvailableGames({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  }) async {
    return _localCatalogFallback.getAvailableGames(
      studentId: studentId,
      schoolCode: schoolCode,
      isChild: isChild,
    );
  }

  /// 4. Get game by ID
  @override
  Future<GameActivity?> getGameById({
    required String gameId,
    required String studentId,
    required String schoolCode,
  }) async {
    return _localCatalogFallback.getGameById(
      gameId: gameId,
      studentId: studentId,
      schoolCode: schoolCode,
    );
  }

  /// 5. Submit game result to backend
  @override
  Future<GameResult> submitGameResult({
    required String studentId,
    required String schoolCode,
    required GameResult result,
  }) async {
    try {
      final response = await _apiClient.post(
        '/student/games/result',
        data: {
          'gameId': result.gameId,
          if (result.taskId != null) 'taskId': result.taskId,
          'score': result.scorePercentage.round(),
          'correctAnswers': result.correctAnswers,
          'incorrectAnswers': result.incorrectAnswers,
          'skill': result.skill?.name ?? 'vocabulary',
          'vocabularyIds': result.vocabularyIds,
        },
      );

      final bodyMap = _extractMap(response.data);
      final data = bodyMap?['data'] as Map<String, dynamic>?;
      if (data != null) {
        final earnedXp = data['earnedXp'] as int? ?? result.earnedXp;
        return result.copyWith(earnedXp: earnedXp);
      }
    } catch (e) {
      developer.log(
        'RemoteSchoolLearningRepository.submitGameResult network error: $e',
        name: 'RemoteSchoolLearningRepository',
      );
    }

    return _localCatalogFallback.submitGameResult(
      studentId: studentId,
      schoolCode: schoolCode,
      result: result,
    );
  }

  /// 6. Get student progress summary from server
  @override
  Future<StudentProgressSummary> getStudentProgressSummary({
    required String studentId,
    required String schoolCode,
  }) async {
    try {
      final response = await _apiClient.get('/student/home');
      final bodyMap = _extractMap(response.data);
      final data = bodyMap?['data'] as Map<String, dynamic>?;
      if (data != null) {
        final studentMap = data['student'] as Map<String, dynamic>? ?? {};
        final tasksList = data['dailyTasks'] as List<dynamic>? ?? [];
        final parsedTasks =
            tasksList
                .map((t) => _mapTaskFromJson(t as Map<String, dynamic>))
                .toList();

        final completedCount = parsedTasks.where((t) => t.completed).length;
        final totalCount = parsedTasks.isNotEmpty ? parsedTasks.length : 3;

        return StudentProgressSummary(
          studentId: studentId,
          totalXp: studentMap['xp'] as int? ?? 0,
          streakDays: studentMap['streak'] as int? ?? 1,
          completedTasksTodayCount: completedCount,
          totalTasksTodayCount: totalCount,
          todayProgressRatio:
              totalCount > 0 ? (completedCount / totalCount) : 0.0,
          currentLevel: studentMap['cefrLevel'] as String? ?? 'A1',
          hasCompletedDailyGoal: completedCount >= 3,
          dailyGoalTarget: 3,
        );
      }
    } catch (e) {
      developer.log(
        'RemoteSchoolLearningRepository.getStudentProgressSummary network error: $e',
        name: 'RemoteSchoolLearningRepository',
      );
    }

    return _localCatalogFallback.getStudentProgressSummary(
      studentId: studentId,
      schoolCode: schoolCode,
    );
  }

  /// 7. Get unlocked achievements
  @override
  Future<List<String>> getStudentAchievements({
    required String studentId,
    required String schoolCode,
  }) async {
    try {
      final response = await _apiClient.get('/student/progress');
      final bodyMap = _extractMap(response.data);
      final data = bodyMap?['data'] as Map<String, dynamic>?;
      final achievements = data?['achievements'] as List<dynamic>?;
      if (achievements != null) {
        return achievements
            .where((a) => (a as Map<String, dynamic>)['isUnlocked'] == true)
            .map((a) => (a as Map<String, dynamic>)['achievementId'] as String)
            .toList();
      }
    } catch (e) {
      developer.log(
        'RemoteSchoolLearningRepository.getStudentAchievements network error: $e',
        name: 'RemoteSchoolLearningRepository',
      );
    }

    return _localCatalogFallback.getStudentAchievements(
      studentId: studentId,
      schoolCode: schoolCode,
    );
  }

  /// Helper: Map JSON task to domain DailyTask
  DailyTask _mapTaskFromJson(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'pending';
    final isCompleted =
        statusStr == 'completed' || (map['progress'] as num? ?? 0.0) >= 1.0;

    return DailyTask(
      id:
          map['id'] as String? ??
          'task_${DateTime.now().millisecondsSinceEpoch}',
      titleArabic:
          map['titleArabic'] as String? ??
          map['title'] as String? ??
          'مهمة يومية',
      titleEnglish:
          map['titleEnglish'] as String? ??
          map['title'] as String? ??
          'Daily Task',
      descriptionArabic:
          map['descriptionArabic'] as String? ??
          map['description'] as String? ??
          'ممارسة تعليمية لتعزيز المهارات',
      descriptionEnglish:
          map['descriptionEnglish'] as String? ??
          map['description'] as String? ??
          'Educational daily practice to build fluency',
      type: DailyTaskType.fromString(map['type'] as String? ?? 'lesson'),
      skill: LearningSkill.values.firstWhere(
        (s) => s.name == map['skill'],
        orElse: () => LearningSkill.grammar,
      ),
      difficulty: map['difficulty'] as String? ?? 'beginner',
      estimatedMinutes:
          map['durationMinutes'] as int? ??
          map['estimatedMinutes'] as int? ??
          5,
      xpReward: map['xpReward'] as int? ?? 15,
      completed: isCompleted,
      status: DailyTaskStatus.fromString(statusStr),
      progress:
          (map['progress'] as num?)?.toDouble() ?? (isCompleted ? 1.0 : 0.0),
      dueDate:
          map['dueDate'] != null
              ? DateTime.tryParse(map['dueDate'] as String) ?? DateTime.now()
              : DateTime.now(),
      lessonId: map['lessonId'] as String?,
      gameId: map['gameId'] as String?,
      actionRoute: map['actionRoute'] as String? ?? '/learning',
      isForChild: map['isForChild'] as bool? ?? false,
    );
  }
}
