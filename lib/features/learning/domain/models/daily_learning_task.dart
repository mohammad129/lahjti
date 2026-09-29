import 'package:flutter/foundation.dart';
import 'learning_skill.dart';

/// Supported types of daily learning tasks.
enum DailyLearningTaskType {
  lesson,
  vocabularyReview,
  listening,
  speaking,
  pronunciation,
  grammar,
  reading,
  conversation,
  quiz,
  educationalGame;

  String get iconEmoji {
    switch (this) {
      case DailyLearningTaskType.lesson:
        return '📚';
      case DailyLearningTaskType.vocabularyReview:
        return '🗂️';
      case DailyLearningTaskType.listening:
        return '🎧';
      case DailyLearningTaskType.speaking:
        return '🎙️';
      case DailyLearningTaskType.pronunciation:
        return '🗣️';
      case DailyLearningTaskType.grammar:
        return '📐';
      case DailyLearningTaskType.reading:
        return '📖';
      case DailyLearningTaskType.conversation:
        return '💬';
      case DailyLearningTaskType.quiz:
        return '📝';
      case DailyLearningTaskType.educationalGame:
        return '🎮';
    }
  }

  static DailyLearningTaskType fromString(String value) {
    switch (value) {
      case 'lesson':
        return DailyLearningTaskType.lesson;
      case 'vocabularyReview':
      case 'vocabulary_review':
      case 'vocabulary':
        return DailyLearningTaskType.vocabularyReview;
      case 'listening':
        return DailyLearningTaskType.listening;
      case 'speaking':
        return DailyLearningTaskType.speaking;
      case 'pronunciation':
        return DailyLearningTaskType.pronunciation;
      case 'grammar':
        return DailyLearningTaskType.grammar;
      case 'reading':
        return DailyLearningTaskType.reading;
      case 'conversation':
        return DailyLearningTaskType.conversation;
      case 'quiz':
        return DailyLearningTaskType.quiz;
      case 'educationalGame':
      case 'educational_game':
      case 'game':
        return DailyLearningTaskType.educationalGame;
      default:
        return DailyLearningTaskType.lesson;
    }
  }
}

/// Immutable domain model representing a deterministic daily learning task for all student learners.
@immutable
class DailyLearningTask {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final DailyLearningTaskType type;
  final LearningSkill skill;
  final int estimatedMinutes;
  final int xpReward;
  final bool completed;
  final double progress; // 0.0 to 1.0
  final DateTime createdDate;
  final DateTime? completedDate;
  final String? lessonId;
  final String? gameId;
  final String actionRoute;
  final bool isForChild;
  final bool isSchoolTask;
  final String? schoolCode;

  const DailyLearningTask({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.type,
    required this.skill,
    required this.estimatedMinutes,
    required this.xpReward,
    this.completed = false,
    this.progress = 0.0,
    required this.createdDate,
    this.completedDate,
    this.lessonId,
    this.gameId,
    required this.actionRoute,
    this.isForChild = false,
    this.isSchoolTask = false,
    this.schoolCode,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleArabic : titleEnglish;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionArabic : descriptionEnglish;

  DailyLearningTask copyWith({
    String? id,
    String? titleArabic,
    String? titleEnglish,
    String? descriptionArabic,
    String? descriptionEnglish,
    DailyLearningTaskType? type,
    LearningSkill? skill,
    int? estimatedMinutes,
    int? xpReward,
    bool? completed,
    double? progress,
    DateTime? createdDate,
    DateTime? completedDate,
    String? lessonId,
    String? gameId,
    String? actionRoute,
    bool? isForChild,
    bool? isSchoolTask,
    String? schoolCode,
  }) {
    return DailyLearningTask(
      id: id ?? this.id,
      titleArabic: titleArabic ?? this.titleArabic,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      descriptionArabic: descriptionArabic ?? this.descriptionArabic,
      descriptionEnglish: descriptionEnglish ?? this.descriptionEnglish,
      type: type ?? this.type,
      skill: skill ?? this.skill,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
      createdDate: createdDate ?? this.createdDate,
      completedDate: completedDate ?? this.completedDate,
      lessonId: lessonId ?? this.lessonId,
      gameId: gameId ?? this.gameId,
      actionRoute: actionRoute ?? this.actionRoute,
      isForChild: isForChild ?? this.isForChild,
      isSchoolTask: isSchoolTask ?? this.isSchoolTask,
      schoolCode: schoolCode ?? this.schoolCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleArabic': titleArabic,
      'titleEnglish': titleEnglish,
      'descriptionArabic': descriptionArabic,
      'descriptionEnglish': descriptionEnglish,
      'type': type.name,
      'skill': skill.name,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'completed': completed,
      'progress': progress,
      'createdDate': createdDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'lessonId': lessonId,
      'gameId': gameId,
      'actionRoute': actionRoute,
      'isForChild': isForChild,
      'isSchoolTask': isSchoolTask,
      'schoolCode': schoolCode,
    };
  }

  factory DailyLearningTask.fromJson(Map<String, dynamic> json) {
    return DailyLearningTask(
      id: json['id'] as String,
      titleArabic: json['titleArabic'] as String? ?? '',
      titleEnglish: json['titleEnglish'] as String? ?? '',
      descriptionArabic: json['descriptionArabic'] as String? ?? '',
      descriptionEnglish: json['descriptionEnglish'] as String? ?? '',
      type: DailyLearningTaskType.fromString(
        json['type'] as String? ?? 'lesson',
      ),
      skill: LearningSkill.values.firstWhere(
        (s) => s.name == json['skill'],
        orElse: () => LearningSkill.vocabulary,
      ),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      xpReward: json['xpReward'] as int? ?? 15,
      completed: json['completed'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdDate:
          json['createdDate'] != null
              ? DateTime.tryParse(json['createdDate'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      completedDate:
          json['completedDate'] != null
              ? DateTime.tryParse(json['completedDate'] as String)
              : null,
      lessonId: json['lessonId'] as String?,
      gameId: json['gameId'] as String?,
      actionRoute: json['actionRoute'] as String? ?? '/learning',
      isForChild: json['isForChild'] as bool? ?? false,
      isSchoolTask: json['isSchoolTask'] as bool? ?? false,
      schoolCode: json['schoolCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLearningTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          completed == other.completed &&
          progress == other.progress;

  @override
  int get hashCode => id.hashCode ^ completed.hashCode ^ progress.hashCode;
}
