import 'package:flutter/foundation.dart';

/// The active learner's daily learning target and progress.
@immutable
class DailyLearningGoal {
  final int targetXp;
  final int earnedXp;
  final int targetMinutes;
  final int completedMinutes;
  final int completedActivitiesCount;

  const DailyLearningGoal({
    this.targetXp = 50,
    this.earnedXp = 0,
    this.targetMinutes = 10,
    this.completedMinutes = 0,
    this.completedActivitiesCount = 0,
  });

  bool get isCompleted => earnedXp >= targetXp;

  double get progressRatio =>
      targetXp > 0 ? (earnedXp / targetXp).clamp(0.0, 1.0) : 0.0;

  int get remainingXp => (targetXp - earnedXp).clamp(0, 99999);
}

/// Comprehensive daily learning summary for a specific calendar date.
@immutable
class DailyProgressSummary {
  final DateTime date;
  final int xpEarned;
  final int lessonsCompleted;
  final int vocabPracticed;
  final int vocabReviewed;
  final int examsCompleted;
  final int tutorTurns;
  final bool isGoalMet;

  const DailyProgressSummary({
    required this.date,
    this.xpEarned = 0,
    this.lessonsCompleted = 0,
    this.vocabPracticed = 0,
    this.vocabReviewed = 0,
    this.examsCompleted = 0,
    this.tutorTurns = 0,
    this.isGoalMet = false,
  });
}

/// Aggregated 7-day weekly learning summary.
@immutable
class WeeklyProgressSummary {
  final DateTime weekStartDate;
  final int activeDaysCount;
  final int totalXpEarned;
  final int totalLessonsCompleted;
  final int totalVocabPracticed;
  final int totalExamsCompleted;
  final Map<int, bool> activeDaysMap; // 1 = Mon .. 7 = Sun
  final Map<int, int> dayXpMap;

  const WeeklyProgressSummary({
    required this.weekStartDate,
    required this.activeDaysCount,
    required this.totalXpEarned,
    required this.totalLessonsCompleted,
    required this.totalVocabPracticed,
    required this.totalExamsCompleted,
    required this.activeDaysMap,
    required this.dayXpMap,
  });
}
