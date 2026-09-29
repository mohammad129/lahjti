import 'package:flutter/foundation.dart';

/// Immutable summary of a school student's daily progress and gamification state.
@immutable
class StudentProgressSummary {
  final String studentId;
  final int totalXp;
  final int streakDays;
  final int completedTasksTodayCount;
  final int totalTasksTodayCount;
  final double todayProgressRatio; // 0.0 to 1.0
  final String currentLevel;
  final bool hasCompletedDailyGoal;
  final int dailyGoalTarget;

  const StudentProgressSummary({
    required this.studentId,
    required this.totalXp,
    required this.streakDays,
    required this.completedTasksTodayCount,
    required this.totalTasksTodayCount,
    required this.todayProgressRatio,
    required this.currentLevel,
    required this.hasCompletedDailyGoal,
    this.dailyGoalTarget = 3,
  });

  factory StudentProgressSummary.initial(String studentId) {
    return StudentProgressSummary(
      studentId: studentId,
      totalXp: 450,
      streakDays: 5,
      completedTasksTodayCount: 1,
      totalTasksTodayCount: 5,
      todayProgressRatio: 0.20,
      currentLevel: 'A2 - مبتدئ متقدم',
      hasCompletedDailyGoal: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'totalXp': totalXp,
      'streakDays': streakDays,
      'completedTasksTodayCount': completedTasksTodayCount,
      'totalTasksTodayCount': totalTasksTodayCount,
      'todayProgressRatio': todayProgressRatio,
      'currentLevel': currentLevel,
      'hasCompletedDailyGoal': hasCompletedDailyGoal,
      'dailyGoalTarget': dailyGoalTarget,
    };
  }

  factory StudentProgressSummary.fromJson(Map<String, dynamic> json) {
    return StudentProgressSummary(
      studentId: json['studentId'] as String,
      totalXp: json['totalXp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      completedTasksTodayCount: json['completedTasksTodayCount'] as int? ?? 0,
      totalTasksTodayCount: json['totalTasksTodayCount'] as int? ?? 5,
      todayProgressRatio:
          (json['todayProgressRatio'] as num?)?.toDouble() ?? 0.0,
      currentLevel: json['currentLevel'] as String? ?? 'A1',
      hasCompletedDailyGoal: json['hasCompletedDailyGoal'] as bool? ?? false,
      dailyGoalTarget: json['dailyGoalTarget'] as int? ?? 3,
    );
  }
}
