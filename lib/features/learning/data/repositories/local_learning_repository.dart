import '../../../exams/domain/models/exam_models.dart';
import '../../../progress/domain/models/progress_summary_models.dart';
import '../../../progress/domain/models/streak_models.dart';
import '../../../progress/domain/models/xp_models.dart';
import '../../../progress/domain/services/achievement_evaluator.dart';
import '../../../progress/domain/services/streak_evaluator.dart';
import '../../../progress/domain/services/xp_calculator.dart';
import '../../domain/models/learner_progress.dart';
import '../../domain/models/learning_profile.dart';
import '../../domain/models/lesson_models.dart';
import '../../domain/models/vocabulary_item.dart';
import '../../domain/repositories/learning_repository.dart';
import '../curriculum/starter_curriculum.dart';

/// In-memory & local repository implementation of [LearningRepository].
class LocalLearningRepository implements LearningRepository {
  final XpCalculator _xpCalculator;
  final StreakEvaluator _streakEvaluator;
  final AchievementEvaluator _achievementEvaluator;

  LearningProfile? _cachedProfile;
  LearnerProgress? _cachedProgress;
  final List<VocabularyItem> _vocabulary = List.from(
    StarterCurriculum.starterVocabulary,
  );
  final List<ExamResult> _examResults = [];
  final List<XpTransaction> _xpHistory = [];

  LocalLearningRepository({
    XpCalculator? xpCalculator,
    StreakEvaluator? streakEvaluator,
    AchievementEvaluator? achievementEvaluator,
  }) : _xpCalculator = xpCalculator ?? const XpCalculator(),
       _streakEvaluator = streakEvaluator ?? const StreakEvaluator(),
       _achievementEvaluator =
           achievementEvaluator ?? const AchievementEvaluator();

  @override
  Future<LearningProfile> getLearningProfile(String userId) async {
    _cachedProfile ??= LearningProfile.defaultProfile(userId: userId);
    return _cachedProfile!;
  }

  @override
  Future<void> updateLearningProfile(LearningProfile profile) async {
    _cachedProfile = profile;
  }

  @override
  Future<LearnerProgress> getLearnerProgress(String userId) async {
    if (_cachedProgress == null) {
      final now = DateTime.now();
      final initialStreak = StreakData(
        currentStreak: 2,
        longestStreak: 4,
        lastActiveDate: now.subtract(const Duration(hours: 3)),
        totalActiveDays: 6,
      );

      final initialAchievements = _achievementEvaluator.defaultAchievements;

      _cachedProgress = LearnerProgress(
        completedLessonIds: const ['lesson_1_1'],
        inProgressLessonId: 'lesson_1_2',
        masteredVocabCount: 8,
        reviewQueueCount: 3,
        lastSessionDate: now,
        totalXp: 180,
        streakData: initialStreak,
        achievements: initialAchievements,
        tutorTurnsCount: 2,
        completedExamsCount: 0,
      );
    }
    return _cachedProgress!;
  }

  @override
  Future<void> updateLearnerProgress(
    String userId,
    LearnerProgress progress,
  ) async {
    _cachedProgress = progress;
  }

  @override
  Future<List<CurriculumModule>> getCurriculumModules({
    required String language,
  }) async {
    return StarterCurriculum.modules;
  }

  @override
  Future<List<VocabularyItem>> getVocabularyList(String userId) async {
    return _vocabulary;
  }

  @override
  Future<void> updateVocabularyItem(String userId, VocabularyItem item) async {
    final index = _vocabulary.indexWhere((v) => v.id == item.id);
    if (index != -1) {
      _vocabulary[index] = item;
    } else {
      _vocabulary.add(item);
    }
  }

  @override
  Future<List<ExamResult>> getExamResults(String userId) async {
    return List.unmodifiable(_examResults);
  }

  @override
  Future<void> saveExamResult(String userId, ExamResult result) async {
    _examResults.insert(0, result);
    await recordLearningActivity(
      userId,
      XpActivityType.examCompletion,
      accuracy: result.overallScore,
      referenceId: result.examId,
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
    final now = DateTime.now();
    final progress = await getLearnerProgress(userId);

    // 1. Calculate and record XP
    final earnedXp = _xpCalculator.calculateActivityXp(
      activityType: type,
      accuracyPercentage: accuracy,
      itemsCount: count,
    );

    final transaction = XpTransaction(
      id: 'tx_${now.millisecondsSinceEpoch}',
      activityType: type,
      xpEarned: earnedXp,
      timestamp: now,
      referenceId: referenceId,
    );
    _xpHistory.insert(0, transaction);

    // 2. Evaluate Streak Update
    final streakResult = _streakEvaluator.evaluateActivity(
      currentStreak: progress.streakData,
      activityTime: now,
    );

    // 3. Update activity counts
    int tutorTurns = progress.tutorTurnsCount;
    int examCount = progress.completedExamsCount;
    int vocabCount = progress.masteredVocabCount;

    if (type == XpActivityType.tutorConversation) tutorTurns++;
    if (type == XpActivityType.examCompletion) examCount++;
    if (type == XpActivityType.vocabularyPractice && count != null) {
      vocabCount += count;
    }

    final newTotalXp = progress.totalXp + earnedXp;

    // 4. Evaluate Achievements
    final updatedAchievements = _achievementEvaluator.evaluateAchievements(
      currentList: progress.achievements,
      completedLessonsCount: progress.completedLessonIds.length,
      masteredVocabCount: vocabCount,
      currentStreak: streakResult.updatedStreak.currentStreak,
      completedExamsCount: examCount,
      tutorTurnsCount: tutorTurns,
      totalXp: newTotalXp,
      now: now,
    );

    _cachedProgress = progress.copyWith(
      totalXp: newTotalXp,
      streakData: streakResult.updatedStreak,
      lastSessionDate: now,
      achievements: updatedAchievements,
      xpTransactions: [transaction, ...progress.xpTransactions],
      tutorTurnsCount: tutorTurns,
      completedExamsCount: examCount,
      masteredVocabCount: vocabCount,
    );
  }

  @override
  Future<DailyProgressSummary> getDailyProgress(
    String userId,
    DateTime date,
  ) async {
    final progress = await getLearnerProgress(userId);
    final todayMidnight = DateTime(date.year, date.month, date.day);

    final todaysTxs =
        progress.xpTransactions.where((tx) {
          final txDate = DateTime(
            tx.timestamp.year,
            tx.timestamp.month,
            tx.timestamp.day,
          );
          return txDate == todayMidnight;
        }).toList();

    final xpEarned = todaysTxs.fold(0, (sum, tx) => sum + tx.xpEarned);
    final lessons =
        todaysTxs
            .where((tx) => tx.activityType == XpActivityType.lessonCompletion)
            .length;
    final vocab =
        todaysTxs
            .where((tx) => tx.activityType == XpActivityType.vocabularyPractice)
            .length;
    final reviews =
        todaysTxs
            .where((tx) => tx.activityType == XpActivityType.vocabularyReview)
            .length;
    final exams =
        todaysTxs
            .where((tx) => tx.activityType == XpActivityType.examCompletion)
            .length;
    final tutor =
        todaysTxs
            .where((tx) => tx.activityType == XpActivityType.tutorConversation)
            .length;

    return DailyProgressSummary(
      date: date,
      xpEarned: xpEarned > 0 ? xpEarned : 35, // default starter activity
      lessonsCompleted: lessons,
      vocabPracticed: vocab,
      vocabReviewed: reviews,
      examsCompleted: exams,
      tutorTurns: tutor,
      isGoalMet: xpEarned >= 50,
    );
  }

  @override
  Future<WeeklyProgressSummary> getWeeklyProgress(
    String userId,
    DateTime weekStart,
  ) async {
    final progress = await getLearnerProgress(userId);
    final activeMap = <int, bool>{};
    final xpMap = <int, int>{};

    for (int i = 1; i <= 7; i++) {
      activeMap[i] = i <= progress.streakData.currentStreak;
      xpMap[i] = i <= progress.streakData.currentStreak ? (i * 25) : 0;
    }

    final totalXp = xpMap.values.fold(0, (sum, v) => sum + v);

    return WeeklyProgressSummary(
      weekStartDate: weekStart,
      activeDaysCount: progress.streakData.currentStreak.clamp(0, 7),
      totalXpEarned: totalXp,
      totalLessonsCompleted: progress.completedLessonIds.length,
      totalVocabPracticed: progress.masteredVocabCount,
      totalExamsCompleted: progress.completedExamsCount,
      activeDaysMap: activeMap,
      dayXpMap: xpMap,
    );
  }
}
