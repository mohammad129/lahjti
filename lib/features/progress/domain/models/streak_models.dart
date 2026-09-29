import 'package:flutter/foundation.dart';

/// Status of the learner's daily streak relative to the current calendar day.
enum DailyStreakStatus {
  /// The learner has already completed meaningful learning activity today.
  maintainedToday,

  /// The streak is active from yesterday, but learning activity is needed today to keep it.
  dueToday,

  /// More than 1 day has passed without activity; streak restarts smoothly on next activity.
  resetPending,
}

/// Immutable data model holding the student's daily learning streak statistics.
@immutable
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalActiveDays;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalActiveDays = 0,
  });

  factory StreakData.initial() => const StreakData();

  /// Evaluates whether the streak has been maintained on the given [now] date.
  bool isMaintainedToday(DateTime now) {
    if (lastActiveDate == null) return false;
    return lastActiveDate!.year == now.year &&
        lastActiveDate!.month == now.month &&
        lastActiveDate!.day == now.day;
  }

  /// Determines the current active streak status for [now].
  DailyStreakStatus getStatus(DateTime now) {
    if (lastActiveDate == null) return DailyStreakStatus.resetPending;
    if (isMaintainedToday(now)) return DailyStreakStatus.maintainedToday;

    final todayMidnight = DateTime(now.year, now.month, now.day);
    final lastMidnight = DateTime(
      lastActiveDate!.year,
      lastActiveDate!.month,
      lastActiveDate!.day,
    );
    final daysDifference = todayMidnight.difference(lastMidnight).inDays;

    if (daysDifference == 1) {
      return DailyStreakStatus.dueToday;
    } else {
      return DailyStreakStatus.resetPending;
    }
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
    );
  }
}

/// Detailed outcome of evaluating and updating a streak after a learning event.
@immutable
class StreakUpdateResult {
  final StreakData updatedStreak;
  final bool didIncrement;
  final bool didBreakLongestRecord;
  final String feedbackMessageArabic;
  final String feedbackMessageEnglish;

  const StreakUpdateResult({
    required this.updatedStreak,
    required this.didIncrement,
    required this.didBreakLongestRecord,
    required this.feedbackMessageArabic,
    required this.feedbackMessageEnglish,
  });
}
