import '../../../../core/network/api_client.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../../../progress/domain/models/achievement_models.dart';
import '../../../progress/domain/models/progress_summary_models.dart';
import '../../../progress/domain/models/streak_models.dart';
import '../../../progress/domain/models/xp_models.dart';
import '../../domain/models/learner_progress.dart';
import '../../domain/models/learning_profile.dart';
import '../../domain/models/learning_skill.dart';
import '../../domain/models/lesson_models.dart';
import '../../domain/models/vocabulary_item.dart';
import '../../domain/repositories/learning_repository.dart';
import '../curriculum/starter_curriculum.dart';

/// Real backend implementation of [LearningRepository] interacting with the authenticated API.
///
/// Follows Clean Architecture: UI -> Riverpod -> RemoteLearningRepository -> ApiClient (Dio) -> Backend -> PostgreSQL.
/// Identity is derived strictly server-side from authentication tokens.
class RemoteLearningRepository implements LearningRepository {
  final ApiClient _apiClient;

  const RemoteLearningRepository(this._apiClient);

  @override
  Future<LearningProfile> getLearningProfile(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/profile',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      return LearningProfile.defaultProfile(userId: userId);
    }
    return _mapProfileFromJson(data);
  }

  @override
  Future<void> updateLearningProfile(LearningProfile profile) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/learning/profile',
      data: {
        'targetLanguage': profile.targetLanguage,
        'estimatedCefrLevel': profile.estimatedCefrLevel.code,
        'overallScore': profile.overallScore,
        'comprehensionScore': profile.comprehensionScore,
        'vocabularyScore': profile.vocabularyScore,
        'grammarScore': profile.grammarScore,
        'speakingScore': profile.speakingScore,
        'listeningScore': profile.listeningScore,
        'pronunciationScore': profile.pronunciationScore,
        'fluencyScore': profile.fluencyScore,
        'strengths': profile.strengths,
        'weaknesses': profile.weaknesses,
        'recommendedFocusAreas': profile.recommendedFocusAreas,
        'currentLessonId': profile.currentLessonId,
      },
    );
  }

  @override
  Future<LearnerProgress> getLearnerProgress(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/progress',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      return LearnerProgress(
        completedLessonIds: const ['lesson_1_1'],
        inProgressLessonId: 'lesson_1_2',
        masteredVocabCount: 8,
        reviewQueueCount: 3,
        lastSessionDate: DateTime.now(),
        totalXp: 180,
      );
    }
    return _mapProgressFromJson(data);
  }

  @override
  Future<void> updateLearnerProgress(
    String userId,
    LearnerProgress progress,
  ) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/learning/progress',
      data: {
        'completedLessonIds': progress.completedLessonIds,
        'inProgressLessonId': progress.inProgressLessonId,
        'totalMinutesLearned': progress.totalMinutesLearned,
      },
    );
  }

  @override
  Future<List<CurriculumModule>> getCurriculumModules({
    required String language,
  }) async {
    // Curriculum structure is static catalog data for $0 zero-cost high performance
    return StarterCurriculum.modules;
  }

  @override
  Future<List<VocabularyItem>> getVocabularyList(String userId) async {
    final staticVocab = StarterCurriculum.starterVocabulary;
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/learning/vocabulary',
      );
      final rawList = response.data?['data'] as List<dynamic>? ?? [];

      final progressMap = <String, Map<String, dynamic>>{};
      for (final item in rawList) {
        if (item is Map<String, dynamic> && item['vocabularyId'] != null) {
          progressMap[item['vocabularyId'] as String] = item;
        }
      }

      return staticVocab.map((baseItem) {
        final prog = progressMap[baseItem.id];
        if (prog == null) return baseItem;

        final statusStr = prog['status'] as String? ?? 'learning';
        final status = _parseMasteryStatus(statusStr);
        final reps = prog['repetitions'] as int? ?? 0;
        final lastReviewed =
            prog['lastReviewedDate'] != null
                ? DateTime.tryParse(prog['lastReviewedDate'] as String)
                : null;
        final nextReview =
            prog['nextReviewDate'] != null
                ? DateTime.tryParse(prog['nextReviewDate'] as String)
                : null;

        return baseItem.copyWith(
          status: status,
          totalAttempts: reps,
          lastReviewed: lastReviewed,
          nextReview: nextReview,
        );
      }).toList();
    } catch (_) {
      // Return static vocabulary gracefully if network call fails
      return staticVocab;
    }
  }

  @override
  Future<void> updateVocabularyItem(String userId, VocabularyItem item) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/learning/vocabulary/progress',
      data: {
        'vocabularyId': item.id,
        'status':
            item.status == MasteryStatus.newWord
                ? 'learning'
                : item.status.name,
        'intervalDays':
            item.correctStreak > 0 ? (item.correctStreak * 2).clamp(1, 30) : 1,
        'easeFactor': 2.5,
        'repetitions': item.totalAttempts,
        'accuracyPercentage':
            item.totalAttempts > 0
                ? ((item.totalAttempts - item.incorrectAttempts) *
                        100 ~/
                        item.totalAttempts)
                    .clamp(0, 100)
                : 100,
        if (item.lastReviewed != null)
          'lastReviewedDate': item.lastReviewed!.toIso8601String(),
        if (item.nextReview != null)
          'nextReviewDate': item.nextReview!.toIso8601String(),
      },
    );
  }

  @override
  Future<List<ExamResult>> getExamResults(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/exams',
    );
    final rawList = response.data?['data'] as List<dynamic>? ?? [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(_mapExamResultFromJson)
        .toList();
  }

  @override
  Future<void> saveExamResult(String userId, ExamResult result) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/learning/exams/results',
      data: {
        'examId': result.examId,
        'examType': 'milestone',
        'titleArabic': result.examTitleArabic,
        'overallScore': result.overallScore,
        'earnedPoints': result.correctCount,
        'totalPoints': result.totalQuestions > 0 ? result.totalQuestions : 100,
        'isPassed': result.isPassing,
        'projectedCefrLevel': result.estimatedCefrLevel.code,
        'skillScores':
            result.skillScores
                .map(
                  (s) => {
                    'skill': s.skill.name,
                    'score': s.scorePercentage,
                    'pointsEarned': s.pointsEarned,
                    'pointsPossible': s.pointsPossible,
                  },
                )
                .toList(),
        'strengths': result.strengthsArabic,
        'improvementAreas': result.areasForImprovementArabic,
        'recommendations':
            result.recommendations
                .map(
                  (r) => {
                    'titleArabic': r.titleArabic,
                    'rationaleArabic': r.rationaleArabic,
                    'targetRoute': r.targetRoute,
                  },
                )
                .toList(),
        'completedAt': result.completedAt.toIso8601String(),
      },
    );
  }

  @override
  Future<DailyProgressSummary> getDailyProgress(
    String userId,
    DateTime date,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/daily',
      queryParameters: {'date': date.toIso8601String()},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      return DailyProgressSummary(date: date);
    }
    return DailyProgressSummary(
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? date,
      xpEarned: data['xpEarned'] as int? ?? 0,
      lessonsCompleted: data['lessonsCompleted'] as int? ?? 0,
      vocabPracticed: data['vocabPracticed'] as int? ?? 0,
      vocabReviewed: data['vocabReviewed'] as int? ?? 0,
      examsCompleted: data['examsCompleted'] as int? ?? 0,
      tutorTurns: data['tutorTurns'] as int? ?? 0,
      isGoalMet: data['isGoalMet'] as bool? ?? false,
    );
  }

  @override
  Future<WeeklyProgressSummary> getWeeklyProgress(
    String userId,
    DateTime weekStart,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/learning/weekly',
      queryParameters: {'weekStart': weekStart.toIso8601String()},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      return WeeklyProgressSummary(
        weekStartDate: weekStart,
        activeDaysCount: 0,
        totalXpEarned: 0,
        totalLessonsCompleted: 0,
        totalVocabPracticed: 0,
        totalExamsCompleted: 0,
        activeDaysMap: const {},
        dayXpMap: const {},
      );
    }

    final rawActiveMap = data['activeDaysMap'] as Map<String, dynamic>? ?? {};
    final activeDaysMap = <int, bool>{};
    rawActiveMap.forEach((k, v) {
      final key = int.tryParse(k);
      if (key != null) activeDaysMap[key] = v == true;
    });

    final rawXpMap = data['dayXpMap'] as Map<String, dynamic>? ?? {};
    final dayXpMap = <int, int>{};
    rawXpMap.forEach((k, v) {
      final key = int.tryParse(k);
      if (key != null && v is num) dayXpMap[key] = v.toInt();
    });

    return WeeklyProgressSummary(
      weekStartDate:
          DateTime.tryParse(data['weekStartDate'] as String? ?? '') ??
          weekStart,
      activeDaysCount: data['activeDaysCount'] as int? ?? 0,
      totalXpEarned: data['totalXpEarned'] as int? ?? 0,
      totalLessonsCompleted: data['totalLessonsCompleted'] as int? ?? 0,
      totalVocabPracticed: data['totalVocabPracticed'] as int? ?? 0,
      totalExamsCompleted: data['totalExamsCompleted'] as int? ?? 0,
      activeDaysMap: activeDaysMap,
      dayXpMap: dayXpMap,
    );
  }

  @override
  Future<void> recordLearningActivity(
    String userId,
    XpActivityType type, {
    int? accuracy,
    int? count,
    String? referenceId,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/learning/activity',
      data: {
        'activityType': type.name,
        if (accuracy != null) 'accuracy': accuracy,
        if (count != null) 'count': count,
        if (referenceId != null) 'referenceId': referenceId,
      },
    );
  }

  // --- Helpers for JSON Mapping ---

  LearningProfile _mapProfileFromJson(Map<String, dynamic> json) {
    return LearningProfile(
      userId: json['userId'] as String? ?? 'usr_active',
      targetLanguage: json['targetLanguage'] as String? ?? 'english',
      estimatedCefrLevel: CefrLevel.fromCode(
        json['estimatedCefrLevel'] as String?,
      ),
      overallScore: json['overallScore'] as int? ?? 65,
      comprehensionScore: json['comprehensionScore'] as int? ?? 70,
      vocabularyScore: json['vocabularyScore'] as int? ?? 65,
      grammarScore: json['grammarScore'] as int? ?? 60,
      speakingScore: json['speakingScore'] as int?,
      listeningScore: json['listeningScore'] as int?,
      pronunciationScore: json['pronunciationScore'] as int?,
      fluencyScore: json['fluencyScore'] as int?,
      strengths:
          (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      weaknesses:
          (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedFocusAreas:
          (json['recommendedFocusAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      currentLessonId: json['currentLessonId'] as String? ?? 'lesson_1_1',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  LearnerProgress _mapProgressFromJson(Map<String, dynamic> json) {
    final streakJson = json['streak'] as Map<String, dynamic>?;
    final streakData =
        streakJson != null
            ? StreakData(
              currentStreak: streakJson['currentStreak'] as int? ?? 1,
              longestStreak: streakJson['longestStreak'] as int? ?? 1,
              lastActiveDate:
                  streakJson['lastActiveDate'] != null
                      ? DateTime.tryParse(
                        streakJson['lastActiveDate'] as String,
                      )
                      : null,
              totalActiveDays: streakJson['totalActiveDays'] as int? ?? 1,
            )
            : null;

    final achievementsJson = json['achievements'] as List<dynamic>? ?? [];
    final achievements =
        achievementsJson
            .whereType<Map<String, dynamic>>()
            .map(
              (a) => Achievement(
                id: a['id'] as String? ?? 'ach',
                titleArabic: a['titleArabic'] as String? ?? '',
                titleEnglish: a['titleEnglish'] as String? ?? '',
                descriptionArabic: a['descriptionArabic'] as String? ?? '',
                descriptionEnglish: a['descriptionEnglish'] as String? ?? '',
                iconEmoji: a['iconEmoji'] as String? ?? '⭐',
                category: _parseAchievementCategory(a['category'] as String?),
                xpReward: a['xpReward'] as int? ?? 50,
                isUnlocked: a['isUnlocked'] as bool? ?? false,
                unlockedAt:
                    a['unlockedAt'] != null
                        ? DateTime.tryParse(a['unlockedAt'] as String)
                        : null,
                currentValue: a['currentValue'] as int? ?? 0,
                targetValue: a['targetValue'] as int? ?? 1,
              ),
            )
            .toList();

    final skillProgressMap = <LearningSkill, SkillProgress>{};
    final skillsJson = json['skills'] as Map<String, dynamic>?;
    if (skillsJson != null) {
      for (final entry in skillsJson.entries) {
        final skill = _parseLearningSkill(entry.key);
        if (skill != null && entry.value is Map<String, dynamic>) {
          final sData = entry.value as Map<String, dynamic>;
          skillProgressMap[skill] = SkillProgress(
            skill: skill,
            levelScore: sData['levelScore'] as int? ?? 50,
            assessedAttempts: sData['assessedAttempts'] as int? ?? 1,
            lastUpdated:
                DateTime.tryParse(sData['lastUpdated'] as String? ?? '') ??
                DateTime.now(),
          );
        }
      }
    }

    return LearnerProgress(
      completedLessonIds:
          (json['completedLessonIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      inProgressLessonId: json['inProgressLessonId'] as String?,
      masteredVocabCount: json['masteredVocabCount'] as int? ?? 0,
      reviewQueueCount: json['reviewQueueCount'] as int? ?? 0,
      skillProgressMap: skillProgressMap,
      totalMinutesLearned: json['totalMinutesLearned'] as int? ?? 0,
      lastSessionDate:
          DateTime.tryParse(json['lastSessionDate'] as String? ?? '') ??
          DateTime.now(),
      totalXp: json['totalXp'] as int? ?? 120,
      streakData: streakData,
      achievements: achievements,
      tutorTurnsCount: json['tutorTurnsCount'] as int? ?? 0,
      completedExamsCount: json['completedExamsCount'] as int? ?? 0,
    );
  }

  ExamResult _mapExamResultFromJson(Map<String, dynamic> json) {
    final skillScoresRaw = json['skillScores'] as List<dynamic>? ?? [];
    final skillScores =
        skillScoresRaw
            .whereType<Map<String, dynamic>>()
            .map(
              (s) => ExamSkillScore(
                skill:
                    _parseLearningSkill(s['skill'] as String?) ??
                    LearningSkill.grammar,
                scorePercentage: s['score'] as int? ?? 0,
                pointsEarned:
                    s['pointsEarned'] as int? ?? (s['correct'] as int? ?? 0),
                pointsPossible:
                    s['pointsPossible'] as int? ?? (s['total'] as int? ?? 100),
              ),
            )
            .toList();

    return ExamResult(
      id:
          json['id'] as String? ??
          'res_${DateTime.now().millisecondsSinceEpoch}',
      examId: json['examId'] as String? ?? 'exam_01',
      examTitleArabic: json['titleArabic'] as String? ?? 'تقييم شامل',
      examTitleEnglish: json['titleEnglish'] as String? ?? 'Assessment',
      overallScore: json['overallScore'] as int? ?? 0,
      estimatedCefrLevel: CefrLevel.fromCode(
        json['projectedCefrLevel'] as String?,
      ),
      skillScores: skillScores,
      answeredCount: json['earnedPoints'] as int? ?? 0,
      skippedCount: 0,
      correctCount: json['earnedPoints'] as int? ?? 0,
      totalQuestions: json['totalPoints'] as int? ?? 100,
      strengthsArabic:
          (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      areasForImprovementArabic:
          (json['improvementAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendations: const [],
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  MasteryStatus _parseMasteryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'mastered':
        return MasteryStatus.mastered;
      case 'reviewing':
        return MasteryStatus.reviewing;
      case 'learning':
        return MasteryStatus.learning;
      case 'newword':
      default:
        return MasteryStatus.newWord;
    }
  }

  AchievementCategory _parseAchievementCategory(String? category) {
    if (category == null) return AchievementCategory.milestones;
    for (final c in AchievementCategory.values) {
      if (c.name.toLowerCase() == category.toLowerCase()) return c;
    }
    return AchievementCategory.milestones;
  }

  LearningSkill? _parseLearningSkill(String? name) {
    if (name == null) return null;
    for (final s in LearningSkill.values) {
      if (s.name.toLowerCase() == name.toLowerCase()) return s;
    }
    return null;
  }
}
