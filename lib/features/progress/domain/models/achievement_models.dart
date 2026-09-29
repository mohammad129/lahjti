import 'package:flutter/foundation.dart';

/// Categories of student badges and achievements.
enum AchievementCategory {
  /// Overall onboarding, milestones, and initial progress.
  milestones,

  /// Curriculum lesson completion.
  lessons,

  /// Vocabulary acquisition and spaced repetition.
  vocabulary,

  /// Daily learning habit and streak maintenance.
  streaks,

  /// Assessment and milestone exams.
  exams,

  /// Voice conversations with AI Tutor Abbas and Dunya.
  tutor,
}

/// An individual verifiable achievement or badge.
@immutable
class Achievement {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final String iconEmoji;
  final AchievementCategory category;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentValue;
  final int targetValue;

  const Achievement({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.iconEmoji,
    required this.category,
    this.xpReward = 50,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentValue = 0,
    required this.targetValue,
  });

  double get progressRatio =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Achievement copyWith({
    String? id,
    String? titleArabic,
    String? titleEnglish,
    String? descriptionArabic,
    String? descriptionEnglish,
    String? iconEmoji,
    AchievementCategory? category,
    int? xpReward,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentValue,
    int? targetValue,
  }) {
    return Achievement(
      id: id ?? this.id,
      titleArabic: titleArabic ?? this.titleArabic,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      descriptionArabic: descriptionArabic ?? this.descriptionArabic,
      descriptionEnglish: descriptionEnglish ?? this.descriptionEnglish,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
    );
  }
}
