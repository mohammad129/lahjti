import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/school/data/repositories/remote_school_learning_repository.dart';
import 'package:lahjti/features/school/domain/models/daily_task.dart';
import 'package:lahjti/features/school/domain/models/game_models.dart';
import 'package:lahjti/features/school/presentation/providers/student_providers.dart';

class MockDioAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{"success": true, "data": {}}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('STEP 24 — RemoteSchoolLearningRepository & Backend Integration Tests', () {
    late Dio dio;
    late MockDioAdapter mockAdapter;
    late ApiClient apiClient;
    late RemoteSchoolLearningRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      mockAdapter = MockDioAdapter();
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(dio);
      repository = RemoteSchoolLearningRepository(apiClient);
    });

    test(
      '1. getDailyTasks parses server response into domain models correctly',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/student/tasks');
          expect(options.method, 'GET');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": [
              {
                "id": "task_server_01",
                "title": "إكمال الدرس اليومي",
                "titleArabic": "إكمال الدرس اليومي",
                "titleEnglish": "Complete Daily Lesson",
                "description": "درس القواعد والمحادثة الأساسية",
                "descriptionArabic": "درس القواعد والمحادثة الأساسية",
                "descriptionEnglish": "Core grammar and conversation practice",
                "type": "lesson",
                "skill": "grammar",
                "difficulty": "intermediate",
                "durationMinutes": 10,
                "status": "pending",
                "progress": 0.0,
                "xpReward": 25,
                "actionRoute": "/learning/lesson",
                "lessonId": "lesson_1_2",
                "isForChild": false
              }
            ]
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final tasks = await repository.getDailyTasks(
          studentId: 'user_student_alpha',
          schoolCode: 'ALPHA101',
        );

        expect(tasks.length, 1);
        final task = tasks.first;
        expect(task.id, 'task_server_01');
        expect(task.titleArabic, 'إكمال الدرس اليومي');
        expect(task.type, DailyTaskType.lesson);
        expect(task.skill, LearningSkill.grammar);
        expect(task.xpReward, 25);
        expect(task.completed, false);
        expect(task.status, DailyTaskStatus.pending);
      },
    );

    test('2. completeDailyTask sends POST and parses completed task', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/student/tasks/task_server_01/complete');
        expect(options.method, 'POST');
        return ResponseBody.fromString(
          '''
          {
            "success": true,
            "data": {
              "earnedXp": 25,
              "task": {
                "id": "task_server_01",
                "title": "إكمال الدرس اليومي",
                "titleArabic": "إكمال الدرس اليومي",
                "titleEnglish": "Complete Daily Lesson",
                "description": "درس القواعد والمحادثة الأساسية",
                "descriptionArabic": "درس القواعد والمحادثة الأساسية",
                "descriptionEnglish": "Core grammar and conversation practice",
                "type": "lesson",
                "skill": "grammar",
                "difficulty": "intermediate",
                "durationMinutes": 10,
                "status": "completed",
                "progress": 1.0,
                "xpReward": 25,
                "actionRoute": "/learning/lesson",
                "lessonId": "lesson_1_2",
                "isForChild": false
              }
            }
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final completedTask = await repository.completeDailyTask(
        studentId: 'user_student_alpha',
        taskId: 'task_server_01',
        schoolCode: 'ALPHA101',
      );

      expect(completedTask.id, 'task_server_01');
      expect(completedTask.completed, true);
      expect(completedTask.status, DailyTaskStatus.completed);
      expect(completedTask.progress, 1.0);
    });

    test(
      '3. submitGameResult posts result and updates server-calculated earned XP',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/student/games/result');
          expect(options.method, 'POST');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": {
              "earnedXp": 18,
              "gameResult": {
                "id": "game_res_123",
                "gameId": "game_word_match",
                "score": 90,
                "correctAnswers": 9,
                "incorrectAnswers": 1,
                "skill": "vocabulary",
                "earnedXp": 18
              }
            }
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final result = GameResult(
          gameId: 'game_word_match',
          gameType: GameType.wordMatch,
          scorePercentage: 90.0,
          totalQuestions: 10,
          correctAnswers: 9,
          incorrectAnswers: 1,
          skill: LearningSkill.vocabulary,
          completedAt: DateTime.now(),
          passed: true,
          earnedXp: 0, // Client initial 0 XP
        );

        final returned = await repository.submitGameResult(
          studentId: 'user_student_alpha',
          schoolCode: 'ALPHA101',
          result: result,
        );

        expect(returned.earnedXp, 18);
        expect(returned.scorePercentage, 90.0);
      },
    );

    test(
      '4. getStudentProgressSummary maps server home data correctly',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/student/home');
          expect(options.method, 'GET');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": {
              "student": {
                "displayName": "سارة خالد",
                "grade": "الصف السابع",
                "section": "أ",
                "schoolName": "Alpha International School",
                "cefrLevel": "A2",
                "xp": 340,
                "streak": 5
              },
              "currentLearning": {
                "currentLesson": "lesson_1_2",
                "currentUnit": "Unit 2",
                "recommendation": "Practice vocabulary"
              },
              "dailyTasks": [
                {
                  "id": "t1",
                  "title": "مهمة 1",
                  "titleArabic": "مهمة 1",
                  "titleEnglish": "Task 1",
                  "description": "وصف المهمة",
                  "type": "lesson",
                  "skill": "grammar",
                  "durationMinutes": 5,
                  "status": "completed",
                  "progress": 1.0,
                  "xpReward": 20
                },
                {
                  "id": "t2",
                  "title": "مهمة 2",
                  "titleArabic": "مهمة 2",
                  "titleEnglish": "Task 2",
                  "description": "وصف المهمة",
                  "type": "vocabulary",
                  "skill": "vocabulary",
                  "durationMinutes": 5,
                  "status": "pending",
                  "progress": 0.0,
                  "xpReward": 15
                }
              ],
              "vocabularyReview": {
                "dueCount": 4
              }
            }
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final summary = await repository.getStudentProgressSummary(
          studentId: 'user_student_alpha',
          schoolCode: 'ALPHA101',
        );

        expect(summary.totalXp, 340);
        expect(summary.streakDays, 5);
        expect(summary.currentLevel, 'A2');
        expect(summary.completedTasksTodayCount, 1);
        expect(summary.totalTasksTodayCount, 2);
      },
    );

    test(
      '5. Gracefully falls back to local deterministic tasks when backend fails',
      () async {
        mockAdapter.handler = (options) {
          return ResponseBody.fromString(
            '{"error": "Server unavailable"}',
            500,
          );
        };

        final tasks = await repository.getDailyTasks(
          studentId: 'user_student_alpha',
          schoolCode: 'ALPHA101',
        );

        expect(tasks, isNotEmpty);
        expect(tasks.first.titleArabic, isNotEmpty);
      },
    );

    test(
      '6. Riverpod StudentActionsNotifier executes completion and invalidates providers',
      () async {
        mockAdapter.handler = (options) {
          if (options.path.contains('/student/tasks/')) {
            return ResponseBody.fromString(
              '''
            {
              "success": true,
              "data": {
                "earnedXp": 20,
                "task": {
                  "id": "task_riverpod_01",
                  "title": "Daily Grammar",
                  "type": "lesson",
                  "skill": "grammar",
                  "durationMinutes": 5,
                  "status": "completed",
                  "progress": 1.0,
                  "xpReward": 20
                }
              }
            }
            ''',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString(
            '{"success": true, "data": []}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final container = ProviderContainer(
          overrides: [
            studentDashboardRepositoryProvider.overrideWithValue(repository),
            apiClientProvider.overrideWithValue(apiClient),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(studentActionsProvider.notifier);
        await notifier.completeTask('task_riverpod_01');

        final actionState = container.read(studentActionsProvider);
        expect(actionState.hasError, false);
      },
    );
  });
}
