import 'package:flutter/foundation.dart';

/// Represents an organized, goal-focused English learning track.
@immutable
class LearningPlan {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String targetAudience;
  final int durationDays;
  final String level;
  final String icon;
  final bool isFeatured;
  final bool isActive;
  final bool isEnrolled;
  final int currentDay;
  final int completedDays;
  final int totalPoints;
  final double progressPercent;

  const LearningPlan({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.targetAudience,
    this.durationDays = 60,
    required this.level,
    this.icon = '🎯',
    this.isFeatured = false,
    this.isActive = true,
    this.isEnrolled = false,
    this.currentDay = 1,
    this.completedDays = 0,
    this.totalPoints = 0,
    this.progressPercent = 0.0,
  });

  factory LearningPlan.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    final duration = json['durationDays'] as int? ?? 60;
    final completed = progress?['completedDays'] as int? ?? 0;
    final current = progress?['currentDay'] as int? ?? 1;
    final points = progress?['totalPoints'] as int? ?? 0;
    final calculatedPercent = duration > 0 ? (completed / duration).clamp(0.0, 1.0) : 0.0;

    return LearningPlan(
      id: json['id']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      descriptionAr: json['descriptionAr']?.toString() ?? '',
      descriptionEn: json['descriptionEn']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? 'all',
      durationDays: duration,
      level: json['level']?.toString() ?? 'A1-B2',
      icon: json['icon']?.toString() ?? '🎯',
      isFeatured: json['isFeatured'] == true || json['is_featured'] == true,
      isActive: json['isActive'] != false,
      isEnrolled: progress != null,
      currentDay: current,
      completedDays: completed,
      totalPoints: points,
      progressPercent: calculatedPercent,
    );
  }

  LearningPlan copyWith({
    bool? isEnrolled,
    int? currentDay,
    int? completedDays,
    int? totalPoints,
    double? progressPercent,
  }) {
    return LearningPlan(
      id: id,
      titleAr: titleAr,
      titleEn: titleEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      targetAudience: targetAudience,
      durationDays: durationDays,
      level: level,
      icon: icon,
      isFeatured: isFeatured,
      isActive: isActive,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      totalPoints: totalPoints ?? this.totalPoints,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}

/// A specific day in the 60-day roadmap.
@immutable
class PlanDay {
  final String id;
  final String planId;
  final int dayNumber;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String focusSkill;
  final int xpReward;
  final bool isUnlocked;
  final bool isCompleted;
  final int activitiesCount;

  const PlanDay({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.focusSkill = 'general',
    this.xpReward = 100,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.activitiesCount = 9,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      id: json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? json['plan_id']?.toString() ?? '',
      dayNumber: json['dayNumber'] as int? ?? json['day_number'] as int? ?? 1,
      titleAr: json['titleAr']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      descriptionAr: json['descriptionAr']?.toString() ?? '',
      descriptionEn: json['descriptionEn']?.toString() ?? '',
      focusSkill: json['focusSkill']?.toString() ?? json['focus_skill']?.toString() ?? 'general',
      xpReward: json['xpReward'] as int? ?? json['xp_reward'] as int? ?? 100,
      isUnlocked: json['isUnlocked'] == true,
      isCompleted: json['isCompleted'] == true,
      activitiesCount: json['activitiesCount'] as int? ?? 9,
    );
  }
}

/// An individual micro-activity among the 9 daily components.
@immutable
class PlanActivity {
  final String id;
  final String planDayId;
  final String activityType;
  final int orderIndex;
  final String titleAr;
  final String titleEn;
  final String instructionAr;
  final String instructionEn;
  final Map<String, dynamic> contentJson;
  final int xpReward;
  final int estimatedMinutes;
  final bool isCompleted;
  final int? userScore;
  final String? feedback;

  const PlanActivity({
    required this.id,
    required this.planDayId,
    required this.activityType,
    required this.orderIndex,
    required this.titleAr,
    required this.titleEn,
    required this.instructionAr,
    required this.instructionEn,
    required this.contentJson,
    this.xpReward = 15,
    this.estimatedMinutes = 3,
    this.isCompleted = false,
    this.userScore,
    this.feedback,
  });

  factory PlanActivity.fromJson(Map<String, dynamic> json) {
    final rawContent = json['contentJson'] ?? json['content_json'];
    final Map<String, dynamic> parsedContent;
    if (rawContent is Map) {
      parsedContent = Map<String, dynamic>.from(rawContent);
    } else {
      parsedContent = const {};
    }

    return PlanActivity(
      id: json['id']?.toString() ?? '',
      planDayId: json['planDayId']?.toString() ?? json['plan_day_id']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? json['activity_type']?.toString() ?? 'vocab',
      orderIndex: json['orderIndex'] as int? ?? json['order_index'] as int? ?? 1,
      titleAr: json['titleAr']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      instructionAr: json['instructionAr']?.toString() ?? '',
      instructionEn: json['instructionEn']?.toString() ?? '',
      contentJson: parsedContent,
      xpReward: json['xpReward'] as int? ?? json['xp_reward'] as int? ?? 15,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? json['estimated_minutes'] as int? ?? 3,
      isCompleted: json['isCompleted'] == true,
      userScore: json['userScore'] as int?,
      feedback: json['feedback']?.toString(),
    );
  }

  PlanActivity copyWith({
    String? activityType,
    bool? isCompleted,
    int? userScore,
    String? feedback,
  }) {
    return PlanActivity(
      id: id,
      planDayId: planDayId,
      activityType: activityType ?? this.activityType,
      orderIndex: orderIndex,
      titleAr: titleAr,
      titleEn: titleEn,
      instructionAr: instructionAr,
      instructionEn: instructionEn,
      contentJson: contentJson,
      xpReward: xpReward,
      estimatedMinutes: estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      userScore: userScore ?? this.userScore,
      feedback: feedback ?? this.feedback,
    );
  }

  /// Activity type display badge and icon
  String get icon {
    switch (activityType) {
      case 'quick_review':
        return '🔄';
      case 'vocab':
        return '📚';
      case 'listening':
        return '🎧';
      case 'dialogue':
        return '💬';
      case 'grammar':
        return '🧩';
      case 'pronunciation':
        return '🎙️';
      case 'mini_game':
        return '🎮';
      case 'quick_quiz':
        return '📝';
      case 'day_summary':
        return '🏆';
      default:
        return '✨';
    }
  }

  String get typeArabicName {
    switch (activityType) {
      case 'quick_review':
        return 'مراجعة سريعة';
      case 'vocab':
        return 'مفردات اليوم';
      case 'listening':
        return 'استماع وفهم';
      case 'dialogue':
        return 'محادثة وتطبيق جمل';
      case 'grammar':
        return 'قاعدة مبسطة وسريعة';
      case 'pronunciation':
        return 'نطق ولهجة';
      case 'mini_game':
        return 'لعبة خفيفة';
      case 'quick_quiz':
        return 'اختبار ختامي سريع';
      case 'day_summary':
        return 'ملخص اليوم والتشجيع';
      default:
        return 'نشاط تفاعلي';
    }
  }
}

/// Spaced Repetition Student Mistake entry
@immutable
class StudentMistakeItem {
  final String id;
  final String studentId;
  final String sourceType;
  final String questionPrompt;
  final String studentAnswer;
  final String correctAnswer;
  final String explanation;
  final int repetitionInterval;
  final double easeFactor;
  final int reviewCount;
  final DateTime nextReviewAt;
  final bool isDue;

  const StudentMistakeItem({
    required this.id,
    required this.studentId,
    required this.sourceType,
    required this.questionPrompt,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.repetitionInterval,
    required this.easeFactor,
    required this.reviewCount,
    required this.nextReviewAt,
    required this.isDue,
  });

  factory StudentMistakeItem.fromJson(Map<String, dynamic> json) {
    final nextRev = json['nextReviewAt'] != null
        ? DateTime.tryParse(json['nextReviewAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    return StudentMistakeItem(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'exam',
      questionPrompt: json['questionPrompt']?.toString() ?? '',
      studentAnswer: json['studentAnswer']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      repetitionInterval: json['repetitionInterval'] as int? ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: json['reviewCount'] as int? ?? 0,
      nextReviewAt: nextRev,
      isDue: nextRev.isBefore(DateTime.now().add(const Duration(minutes: 5))),
    );
  }
}
