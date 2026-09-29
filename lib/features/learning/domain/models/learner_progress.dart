import 'package:flutter/foundation.dart';
import '../../../progress/domain/models/achievement_models.dart';
import '../../../progress/domain/models/streak_models.dart';
import '../../../progress/domain/models/xp_models.dart';
import 'learning_skill.dart';

/// Progress record for a specific learning skill.
@immutable
class SkillProgress {
  final LearningSkill skill;
  final int levelScore; // 0 - 100
  final int assessedAttempts;
  final DateTime lastUpdated;

  const SkillProgress({
    required this.skill,
    required this.levelScore,
    this.assessedAttempts = 1,
    required this.lastUpdated,
  });

  bool get hasSufficientEvidence => assessedAttempts >= 2;

  SkillProgress copyWith({
    LearningSkill? skill,
    int? levelScore,
    int? assessedAttempts,
    DateTime? lastUpdated,
  }) {
    return SkillProgress(
      skill: skill ?? this.skill,
      levelScore: levelScore ?? this.levelScore,
      assessedAttempts: assessedAttempts ?? this.assessedAttempts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Holistic progress container for the active student.
@immutable
class LearnerProgress {
  final List<String> completedLessonIds;
  final String? inProgressLessonId;
  final int masteredVocabCount;
  final int reviewQueueCount;
  final Map<LearningSkill, SkillProgress> skillProgressMap;
  final int totalMinutesLearned;
  final DateTime lastSessionDate;
  final int totalXp;
  final StreakData streakData;
  final List<Achievement> achievements;
  final List<XpTransaction> xpTransactions;
  final int tutorTurnsCount;
  final int completedExamsCount;

  LearnerProgress({
    this.completedLessonIds = const [],
    this.inProgressLessonId,
    this.masteredVocabCount = 0,
    this.reviewQueueCount = 0,
    this.skillProgressMap = const {},
    int? dailyStreak,
    this.totalMinutesLearned = 0,
    required this.lastSessionDate,
    this.totalXp = 120,
    StreakData? streakData,
    this.achievements = const [],
    this.xpTransactions = const [],
    this.tutorTurnsCount = 0,
    this.completedExamsCount = 0,
  }) : streakData =
           streakData ??
           StreakData(
             currentStreak: dailyStreak ?? 1,
             longestStreak: dailyStreak ?? 1,
             lastActiveDate: lastSessionDate,
             totalActiveDays: dailyStreak ?? 1,
           );

  int get dailyStreak => streakData.currentStreak;

  bool isLessonCompleted(String lessonId) =>
      completedLessonIds.contains(lessonId);

  LearnerProgress copyWith({
    List<String>? completedLessonIds,
    String? inProgressLessonId,
    int? masteredVocabCount,
    int? reviewQueueCount,
    Map<LearningSkill, SkillProgress>? skillProgressMap,
    int? dailyStreak,
    int? totalMinutesLearned,
    DateTime? lastSessionDate,
    int? totalXp,
    StreakData? streakData,
    List<Achievement>? achievements,
    List<XpTransaction>? xpTransactions,
    int? tutorTurnsCount,
    int? completedExamsCount,
  }) {
    return LearnerProgress(
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      inProgressLessonId: inProgressLessonId ?? this.inProgressLessonId,
      masteredVocabCount: masteredVocabCount ?? this.masteredVocabCount,
      reviewQueueCount: reviewQueueCount ?? this.reviewQueueCount,
      skillProgressMap: skillProgressMap ?? this.skillProgressMap,
      totalMinutesLearned: totalMinutesLearned ?? this.totalMinutesLearned,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalXp: totalXp ?? this.totalXp,
      streakData:
          streakData ??
          (dailyStreak != null
              ? this.streakData.copyWith(currentStreak: dailyStreak)
              : this.streakData),
      achievements: achievements ?? this.achievements,
      xpTransactions: xpTransactions ?? this.xpTransactions,
      tutorTurnsCount: tutorTurnsCount ?? this.tutorTurnsCount,
      completedExamsCount: completedExamsCount ?? this.completedExamsCount,
    );
  }
}
