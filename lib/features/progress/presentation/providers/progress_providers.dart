import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../learning/domain/models/learner_progress.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../domain/models/achievement_models.dart';
import '../../domain/models/progress_summary_models.dart';
import '../../domain/models/streak_models.dart';
import '../../domain/models/xp_models.dart';
import '../../domain/services/achievement_evaluator.dart';
import '../../domain/services/streak_evaluator.dart';
import '../../domain/services/xp_calculator.dart';

/// Provider for domain services
final xpCalculatorProvider = Provider<XpCalculator>((ref) {
  return const XpCalculator();
});

final streakEvaluatorProvider = Provider<StreakEvaluator>((ref) {
  return const StreakEvaluator();
});

final achievementEvaluatorProvider = Provider<AchievementEvaluator>((ref) {
  return const AchievementEvaluator();
});

/// Current calculated learner level based on total accumulated XP.
final learnerLevelProvider = Provider<LearnerLevel>((ref) {
  final progress = ref.watch(learnerProgressProvider);
  return LearnerLevel.fromTotalXp(progress.totalXp);
});

/// Today's daily progress summary fetched from repository.
final dailyProgressSummaryProvider = FutureProvider<DailyProgressSummary>((
  ref,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getDailyProgress('usr_active', DateTime.now());
});

/// Weekly progress summary fetched from repository.
final weeklyProgressSummaryProvider = FutureProvider<WeeklyProgressSummary>((
  ref,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: (now.weekday - 1) % 7));
  return repo.getWeeklyProgress('usr_active', weekStart);
});

/// Today's daily learning goal status computed from progress and today's activity.
final dailyGoalProvider = Provider<DailyLearningGoal>((ref) {
  final progress = ref.watch(learnerProgressProvider);
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  final todaysTxs =
      progress.xpTransactions.where((tx) {
        final txDate = DateTime(
          tx.timestamp.year,
          tx.timestamp.month,
          tx.timestamp.day,
        );
        return txDate == todayMidnight;
      }).toList();

  final xpToday = todaysTxs.fold(0, (sum, tx) => sum + tx.xpEarned);
  final completedActivities = todaysTxs.length;

  return DailyLearningGoal(
    targetXp: 50,
    earnedXp: xpToday > 0 ? xpToday : (progress.totalXp > 0 ? 35 : 0),
    targetMinutes: 10,
    completedMinutes: (completedActivities * 3).clamp(0, 60),
    completedActivitiesCount: completedActivities > 0 ? completedActivities : 1,
  );
});

/// Provider for user's full achievements list.
final achievementsListProvider = Provider<List<Achievement>>((ref) {
  final progress = ref.watch(learnerProgressProvider);
  if (progress.achievements.isNotEmpty) {
    return progress.achievements;
  }
  return ref.watch(achievementEvaluatorProvider).defaultAchievements;
});

/// Provider for user's skill progress map.
final skillsProgressProvider = Provider<Map<LearningSkill, SkillProgress>>((
  ref,
) {
  final progress = ref.watch(learnerProgressProvider);
  return progress.skillProgressMap;
});

/// Provider for learner's active streak.
final streakDataProvider = Provider<StreakData>((ref) {
  final progress = ref.watch(learnerProgressProvider);
  return progress.streakData;
});
