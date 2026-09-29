import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/errors/exceptions.dart';
import 'package:lahjti/core/network/api_client.dart';
import 'package:lahjti/features/exams/domain/models/exam_models.dart';
import 'package:lahjti/features/learning/data/repositories/remote_learning_repository.dart';
import 'package:lahjti/features/learning/domain/models/learning_profile.dart';
import 'package:lahjti/features/learning/domain/models/learning_skill.dart';
import 'package:lahjti/features/learning/domain/models/vocabulary_item.dart';
import 'package:lahjti/features/placement/domain/models/cefr_level.dart';
import 'package:lahjti/features/progress/domain/models/xp_models.dart';

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
  group('Step 12: RemoteLearningRepository Tests', () {
    late Dio dio;
    late MockDioAdapter mockAdapter;
    late ApiClient apiClient;
    late RemoteLearningRepository repository;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      mockAdapter = MockDioAdapter();
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(dio);
      repository = RemoteLearningRepository(apiClient);
    });

    test('1. getLearningProfile parses response correctly', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/learning/profile');
        expect(options.method, 'GET');
        return ResponseBody.fromString(
          '''
          {
            "success": true,
            "data": {
              "userId": "usr_alpha",
              "targetLanguage": "english",
              "estimatedCefrLevel": "b1",
              "overallScore": 78,
              "comprehensionScore": 80,
              "vocabularyScore": 75,
              "grammarScore": 70,
              "speakingScore": 82,
              "listeningScore": 79,
              "pronunciationScore": null,
              "fluencyScore": 85,
              "strengths": ["المفردات المتقدمة"],
              "weaknesses": ["الماضي التام"],
              "recommendedFocusAreas": ["المحادثة اليومية"],
              "currentLessonId": "lesson_2_1",
              "createdAt": "2026-09-17T12:00:00.000Z",
              "updatedAt": "2026-09-17T15:00:00.000Z"
            }
          }
          ''',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final profile = await repository.getLearningProfile('usr_alpha');
      expect(profile.userId, 'usr_alpha');
      expect(profile.targetLanguage, 'english');
      expect(profile.estimatedCefrLevel, CefrLevel.b1);
      expect(profile.overallScore, 78);
      expect(profile.strengths, contains('المفردات المتقدمة'));
      expect(profile.currentLessonId, 'lesson_2_1');
    });

    test('2. updateLearningProfile sends correct payload via PUT', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/learning/profile');
        expect(options.method, 'PUT');
        expect(options.data['targetLanguage'], 'spanish');
        expect(options.data['estimatedCefrLevel'], 'B2');
        return ResponseBody.fromString(
          '{"success": true, "data": {}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final updated = LearningProfile.defaultProfile(
        userId: 'usr_alpha',
        targetLanguage: 'spanish',
        level: CefrLevel.b2,
      );

      await repository.updateLearningProfile(updated);
    });

    test(
      '3. getLearnerProgress parses progress, streaks and achievements',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/learning/progress');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": {
              "userId": "usr_alpha",
              "completedLessonIds": ["lesson_1_1", "lesson_1_2"],
              "inProgressLessonId": "lesson_1_3",
              "masteredVocabCount": 15,
              "reviewQueueCount": 4,
              "totalMinutesLearned": 90,
              "totalXp": 450,
              "lastSessionDate": "2026-09-17T18:00:00.000Z",
              "streak": {
                "currentStreak": 5,
                "longestStreak": 8,
                "lastActiveDate": "2026-09-17T17:30:00.000Z",
                "totalActiveDays": 12
              },
              "skills": {
                "speaking": { "levelScore": 75, "assessedAttempts": 3, "lastUpdated": "2026-09-17T18:00:00.000Z" }
              },
              "achievements": [
                {
                  "id": "first_lesson",
                  "titleArabic": "الخطوة الأولى",
                  "titleEnglish": "First Step",
                  "descriptionArabic": "أكملت أول درس بنجاح",
                  "descriptionEnglish": "Completed your first lesson",
                  "iconEmoji": "🌱",
                  "category": "lessons",
                  "xpReward": 50,
                  "isUnlocked": true,
                  "unlockedAt": "2026-09-17T12:00:00.000Z",
                  "currentValue": 1,
                  "targetValue": 1
                }
              ],
              "tutorTurnsCount": 6,
              "completedExamsCount": 1
            }
          }
          ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        final progress = await repository.getLearnerProgress('usr_alpha');
        expect(progress.completedLessonIds, ['lesson_1_1', 'lesson_1_2']);
        expect(progress.totalXp, 450);
        expect(progress.streakData.currentStreak, 5);
        expect(progress.achievements.length, 1);
        expect(progress.achievements.first.id, 'first_lesson');
        expect(
          progress.skillProgressMap[LearningSkill.speaking]?.levelScore,
          75,
        );
      },
    );

    test(
      '4. getVocabularyList merges static catalog with server progress',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/learning/vocabulary');
          return ResponseBody.fromString(
            '''
          {
            "success": true,
            "data": [
              {
                "vocabularyId": "v_hello",
                "status": "mastered",
                "repetitions": 5,
                "intervalDays": 7,
                "easeFactor": 2.7,
                "lastReviewedDate": "2026-09-16T10:00:00.000Z",
                "nextReviewDate": "2026-09-23T10:00:00.000Z"
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

        final list = await repository.getVocabularyList('usr_alpha');
        expect(list.isNotEmpty, isTrue);

        final helloItem = list.firstWhere((item) => item.id == 'v_hello');
        expect(helloItem.status, MasteryStatus.mastered);
        expect(helloItem.totalAttempts, 5);
        expect(helloItem.nextReview, isNotNull);
      },
    );

    test('5. updateVocabularyItem sends progress payload', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/learning/vocabulary/progress');
        expect(options.method, 'POST');
        expect(options.data['vocabularyId'], 'v_hello');
        expect(options.data['status'], 'mastered');
        return ResponseBody.fromString(
          '{"success": true, "data": {}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      const item = VocabularyItem(
        id: 'v_hello',
        term: 'Hello',
        translationArabic: 'مرحبًا',
        exampleSentence: 'Hello world',
        exampleTranslationArabic: 'مرحبًا بالعالم',
        difficulty: CefrLevel.a1,
        category: 'Greetings',
        status: MasteryStatus.mastered,
        totalAttempts: 4,
        correctStreak: 3,
      );

      await repository.updateVocabularyItem('usr_alpha', item);
    });

    test('6. saveExamResult and getExamResults work reliably', () async {
      mockAdapter.handler = (options) {
        if (options.method == 'POST') {
          expect(options.path, '/learning/exams/results');
          expect(options.data['examId'], 'exam_m1');
          expect(options.data['overallScore'], 88);
          return ResponseBody.fromString(
            '{"success": true, "data": {}}',
            201,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          expect(options.path, '/learning/exams');
          return ResponseBody.fromString(
            '''
            {
              "success": true,
              "data": [
                {
                  "id": "res_101",
                  "examId": "exam_m1",
                  "titleArabic": "تقييم الشهر الأول",
                  "titleEnglish": "Month 1 Milestone",
                  "overallScore": 88,
                  "earnedPoints": 88,
                  "totalPoints": 100,
                  "projectedCefrLevel": "a2",
                  "skillScores": [
                    { "skill": "speaking", "score": 85, "correct": 8, "total": 10 }
                  ],
                  "strengths": ["المفردات"],
                  "improvementAreas": ["النطق"],
                  "completedAt": "2026-09-17T14:00:00.000Z"
                }
              ]
            }
            ''',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      };

      final examResult = ExamResult(
        id: 'res_101',
        examId: 'exam_m1',
        examTitleArabic: 'تقييم الشهر الأول',
        examTitleEnglish: 'Month 1 Milestone',
        overallScore: 88,
        estimatedCefrLevel: CefrLevel.a2,
        skillScores: const [
          ExamSkillScore(
            skill: LearningSkill.speaking,
            scorePercentage: 85,
            pointsEarned: 8,
            pointsPossible: 10,
          ),
        ],
        answeredCount: 10,
        skippedCount: 0,
        correctCount: 88,
        totalQuestions: 100,
        strengthsArabic: const ['المفردات'],
        areasForImprovementArabic: const ['النطق'],
        recommendations: const [],
        completedAt: DateTime.parse('2026-09-17T14:00:00.000Z'),
      );

      await repository.saveExamResult('usr_alpha', examResult);
      final results = await repository.getExamResults('usr_alpha');

      expect(results.length, 1);
      expect(results.first.examId, 'exam_m1');
      expect(results.first.overallScore, 88);
    });

    test(
      '7. recordLearningActivity sends activity payload to /learning/activity',
      () async {
        mockAdapter.handler = (options) {
          expect(options.path, '/learning/activity');
          expect(options.method, 'POST');
          expect(options.data['activityType'], 'lessonCompletion');
          expect(options.data['accuracy'], 95);
          expect(options.data['referenceId'], 'lesson_1_1');
          return ResponseBody.fromString(
            '{"success": true, "data": {"xpEarned": 63}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        await repository.recordLearningActivity(
          'usr_alpha',
          XpActivityType.lessonCompletion,
          accuracy: 95,
          referenceId: 'lesson_1_1',
        );
      },
    );

    test('8. Server failure throws AppException without crashing', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"error": {"code": "INTERNAL_SERVER_ERROR", "message": "Unexpected error"}}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      expect(
        () => repository.getLearningProfile('usr_alpha'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
