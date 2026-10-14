import 'package:flutter/foundation.dart';

/// Represents daily tutor session tracking for school students:
/// Up to 4 flexible sessions per day, bounded by a cumulative 1-hour (3600 seconds) limit.
@immutable
class StudentTutorSession {
  final bool isSchoolStudent;
  final int maxDailySessions;
  final int completedSessionsCount;
  final int currentSessionNumber;
  final int remainingSessions;
  final int maxDailySeconds;
  final int totalSecondsUsedToday;
  final int remainingSecondsToday;
  final String? activeSessionId;
  final int activeSessionDurationSeconds;
  final bool canStartOrContinueSession;
  final String? limitReason;

  const StudentTutorSession({
    this.isSchoolStudent = false,
    this.maxDailySessions = 4,
    this.completedSessionsCount = 0,
    this.currentSessionNumber = 1,
    this.remainingSessions = 4,
    this.maxDailySeconds = 3600,
    this.totalSecondsUsedToday = 0,
    this.remainingSecondsToday = 3600,
    this.activeSessionId,
    this.activeSessionDurationSeconds = 0,
    this.canStartOrContinueSession = true,
    this.limitReason,
  });

  factory StudentTutorSession.fromJson(Map<String, dynamic> json) {
    return StudentTutorSession(
      isSchoolStudent: json['isSchoolStudent'] as bool? ?? false,
      maxDailySessions: json['maxDailySessions'] as int? ?? 4,
      completedSessionsCount: json['completedSessionsCount'] as int? ?? 0,
      currentSessionNumber: json['currentSessionNumber'] as int? ?? 1,
      remainingSessions: json['remainingSessions'] as int? ?? 4,
      maxDailySeconds: json['maxDailySeconds'] as int? ?? 3600,
      totalSecondsUsedToday: (json['totalSecondsUsedToday'] as num?)?.toInt() ?? 0,
      remainingSecondsToday:
          (json['remainingSecondsToday'] as num?)?.toInt() ?? 3600,
      activeSessionId: json['activeSessionId'] as String?,
      activeSessionDurationSeconds:
          (json['activeSessionDurationSeconds'] as num?)?.toInt() ?? 0,
      canStartOrContinueSession:
          json['canStartOrContinueSession'] as bool? ?? true,
      limitReason: json['limitReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSchoolStudent': isSchoolStudent,
      'maxDailySessions': maxDailySessions,
      'completedSessionsCount': completedSessionsCount,
      'currentSessionNumber': currentSessionNumber,
      'remainingSessions': remainingSessions,
      'maxDailySeconds': maxDailySeconds,
      'totalSecondsUsedToday': totalSecondsUsedToday,
      'remainingSecondsToday': remainingSecondsToday,
      'activeSessionId': activeSessionId,
      'activeSessionDurationSeconds': activeSessionDurationSeconds,
      'canStartOrContinueSession': canStartOrContinueSession,
      'limitReason': limitReason,
    };
  }

  StudentTutorSession copyWith({
    bool? isSchoolStudent,
    int? maxDailySessions,
    int? completedSessionsCount,
    int? currentSessionNumber,
    int? remainingSessions,
    int? maxDailySeconds,
    int? totalSecondsUsedToday,
    int? remainingSecondsToday,
    String? activeSessionId,
    int? activeSessionDurationSeconds,
    bool? canStartOrContinueSession,
    String? limitReason,
  }) {
    return StudentTutorSession(
      isSchoolStudent: isSchoolStudent ?? this.isSchoolStudent,
      maxDailySessions: maxDailySessions ?? this.maxDailySessions,
      completedSessionsCount:
          completedSessionsCount ?? this.completedSessionsCount,
      currentSessionNumber: currentSessionNumber ?? this.currentSessionNumber,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      maxDailySeconds: maxDailySeconds ?? this.maxDailySeconds,
      totalSecondsUsedToday: totalSecondsUsedToday ?? this.totalSecondsUsedToday,
      remainingSecondsToday:
          remainingSecondsToday ?? this.remainingSecondsToday,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      activeSessionDurationSeconds:
          activeSessionDurationSeconds ?? this.activeSessionDurationSeconds,
      canStartOrContinueSession:
          canStartOrContinueSession ?? this.canStartOrContinueSession,
      limitReason: limitReason ?? this.limitReason,
    );
  }

  /// Formatted remaining minutes string (e.g. "45 دقيقة" or "45 min")
  String remainingMinutesText(bool isArabic) {
    final mins = (remainingSecondsToday / 60).ceil();
    if (mins <= 0) return isArabic ? '0 دقائق' : '0 min';
    return isArabic ? '$mins دقيقة' : '$mins min';
  }

  /// Formatted remaining time in mm:ss format
  String get remainingTimeFormatted {
    final clamped = remainingSecondsToday.clamp(0, 3600);
    final minutes = clamped ~/ 60;
    final seconds = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Session counter label (e.g. "الجلسة 2 من 4")
  String sessionProgressLabel(bool isArabic) {
    if (isArabic) {
      return 'الجلسة $currentSessionNumber من $maxDailySessions';
    }
    return 'Session $currentSessionNumber of $maxDailySessions';
  }

  /// Progress fraction of daily allowed hour (0.0 to 1.0)
  double get dailyUsedFraction {
    if (maxDailySeconds <= 0) return 1.0;
    return (totalSecondsUsedToday / maxDailySeconds).clamp(0.0, 1.0);
  }

  /// Check whether all 4 sessions or 1 hour is finished
  bool get isDailyLimitReached =>
      !canStartOrContinueSession ||
      completedSessionsCount >= maxDailySessions ||
      remainingSecondsToday <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentTutorSession &&
          runtimeType == other.runtimeType &&
          isSchoolStudent == other.isSchoolStudent &&
          completedSessionsCount == other.completedSessionsCount &&
          currentSessionNumber == other.currentSessionNumber &&
          totalSecondsUsedToday == other.totalSecondsUsedToday &&
          remainingSecondsToday == other.remainingSecondsToday &&
          activeSessionId == other.activeSessionId;

  @override
  int get hashCode => Object.hash(
    isSchoolStudent,
    completedSessionsCount,
    currentSessionNumber,
    totalSecondsUsedToday,
    remainingSecondsToday,
    activeSessionId,
  );
}
