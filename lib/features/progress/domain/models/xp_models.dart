import 'package:flutter/foundation.dart';

/// Meaningful learning activity types that reward XP.
enum XpActivityType {
  /// Completing an interactive structured curriculum lesson.
  lessonCompletion,

  /// Completing a session of new vocabulary practice.
  vocabularyPractice,

  /// Reviewing spaced-repetition due vocabulary words.
  vocabularyReview,

  /// Completing a skill checkpoint or milestone exam.
  examCompletion,

  /// Engaging in meaningful voice conversation with AI Tutor Abbas/Dunya.
  tutorConversation,

  /// Achieving major learning milestones or monthly goals.
  milestoneBonus,
}

/// Extension providing localized names and base XP points.
extension XpActivityTypeX on XpActivityType {
  String get nameArabic {
    switch (this) {
      case XpActivityType.lessonCompletion:
        return 'إكمال درس تعليمي';
      case XpActivityType.vocabularyPractice:
        return 'تدريب المفردات الجديدة';
      case XpActivityType.vocabularyReview:
        return 'مراجعة الكلمات المستحقة';
      case XpActivityType.examCompletion:
        return 'اجتياز اختبار تقييمي';
      case XpActivityType.tutorConversation:
        return 'محادثة صوتية مع المعلم';
      case XpActivityType.milestoneBonus:
        return 'مكافأة إنجاز مرحلي';
    }
  }

  String get nameEnglish {
    switch (this) {
      case XpActivityType.lessonCompletion:
        return 'Lesson Completion';
      case XpActivityType.vocabularyPractice:
        return 'Vocabulary Practice';
      case XpActivityType.vocabularyReview:
        return 'Vocabulary Review';
      case XpActivityType.examCompletion:
        return 'Exam Completion';
      case XpActivityType.tutorConversation:
        return 'Tutor Conversation';
      case XpActivityType.milestoneBonus:
        return 'Milestone Bonus';
    }
  }

  int get basePoints {
    switch (this) {
      case XpActivityType.lessonCompletion:
        return 50;
      case XpActivityType.vocabularyPractice:
        return 20;
      case XpActivityType.vocabularyReview:
        return 15;
      case XpActivityType.examCompletion:
        return 100;
      case XpActivityType.tutorConversation:
        return 30;
      case XpActivityType.milestoneBonus:
        return 150;
    }
  }
}

/// Immutable record of an XP reward transaction.
@immutable
class XpTransaction {
  final String id;
  final XpActivityType activityType;
  final int xpEarned;
  final DateTime timestamp;
  final String? referenceId; // e.g., lesson_id, exam_id

  const XpTransaction({
    required this.id,
    required this.activityType,
    required this.xpEarned,
    required this.timestamp,
    this.referenceId,
  });
}

/// Level tier calculation and title definitions.
@immutable
class LearnerLevel {
  final int level;
  final String titleArabic;
  final String titleEnglish;
  final int minXp;
  final int maxXp;

  const LearnerLevel({
    required this.level,
    required this.titleArabic,
    required this.titleEnglish,
    required this.minXp,
    required this.maxXp,
  });

  /// Deterministically calculates the learner level from cumulative XP.
  static LearnerLevel fromTotalXp(int totalXp) {
    if (totalXp < 100) {
      return const LearnerLevel(
        level: 1,
        titleArabic: 'مستكشف مبتدئ 🧭',
        titleEnglish: 'Novice Explorer',
        minXp: 0,
        maxXp: 100,
      );
    } else if (totalXp < 250) {
      return const LearnerLevel(
        level: 2,
        titleArabic: 'متعلم شغوف 🌱',
        titleEnglish: 'Eager Learner',
        minXp: 100,
        maxXp: 250,
      );
    } else if (totalXp < 500) {
      return const LearnerLevel(
        level: 3,
        titleArabic: 'متحدث واثق 🗣️',
        titleEnglish: 'Confident Speaker',
        minXp: 250,
        maxXp: 500,
      );
    } else if (totalXp < 900) {
      return const LearnerLevel(
        level: 4,
        titleArabic: 'متقن العبارات 📚',
        titleEnglish: 'Phrase Master',
        minXp: 500,
        maxXp: 900,
      );
    } else if (totalXp < 1500) {
      return const LearnerLevel(
        level: 5,
        titleArabic: 'محاور بارع 💬',
        titleEnglish: 'Skilled Conversationalist',
        minXp: 900,
        maxXp: 1500,
      );
    } else if (totalXp < 2300) {
      return const LearnerLevel(
        level: 6,
        titleArabic: 'فصيح اللسان 🌟',
        titleEnglish: 'Eloquent Speaker',
        minXp: 1500,
        maxXp: 2300,
      );
    } else if (totalXp < 3300) {
      return const LearnerLevel(
        level: 7,
        titleArabic: 'سفير اللغات 🌍',
        titleEnglish: 'Language Ambassador',
        minXp: 2300,
        maxXp: 3300,
      );
    } else {
      return const LearnerLevel(
        level: 8,
        titleArabic: 'خبير طليق 👑',
        titleEnglish: 'Fluent Master',
        minXp: 3300,
        maxXp: 5000,
      );
    }
  }

  double progressRatio(int totalXp) {
    if (maxXp <= minXp) return 1.0;
    final currentInLevel = totalXp - minXp;
    final span = maxXp - minXp;
    return (currentInLevel / span).clamp(0.0, 1.0);
  }
}

/// Comprehensive summary of the student's XP status.
@immutable
class XpSummary {
  final int totalXp;
  final int todayXp;
  final int thisWeekXp;
  final LearnerLevel currentLevel;
  final List<XpTransaction> recentTransactions;

  const XpSummary({
    required this.totalXp,
    required this.todayXp,
    required this.thisWeekXp,
    required this.currentLevel,
    this.recentTransactions = const [],
  });

  double get levelProgressRatio => currentLevel.progressRatio(totalXp);
  int get xpToNextLevel => (currentLevel.maxXp - totalXp).clamp(0, 99999);
}
