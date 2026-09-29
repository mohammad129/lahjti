import 'package:flutter/foundation.dart';
import '../../../learning/domain/models/learning_skill.dart';

/// Type of learning daily task assigned to a student.
enum DailyTaskType {
  lesson,
  vocabulary,
  listening,
  speaking,
  pronunciation,
  grammar,
  reading,
  game,
  review,
  conversation;

  String get iconEmoji {
    switch (this) {
      case DailyTaskType.lesson:
        return '📚';
      case DailyTaskType.vocabulary:
        return '🗂️';
      case DailyTaskType.listening:
        return '🎧';
      case DailyTaskType.speaking:
        return '🎙️';
      case DailyTaskType.pronunciation:
        return '🗣️';
      case DailyTaskType.grammar:
        return '📐';
      case DailyTaskType.reading:
        return '📖';
      case DailyTaskType.game:
        return '🎮';
      case DailyTaskType.review:
        return '🔄';
      case DailyTaskType.conversation:
        return '💬';
    }
  }

  static DailyTaskType fromString(String value) {
    return DailyTaskType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => DailyTaskType.lesson,
    );
  }
}

/// Execution lifecycle status of a daily learning task.
enum DailyTaskStatus {
  pending,
  inProgress,
  completed,
  skipped;

  static DailyTaskStatus fromString(String value) {
    return DailyTaskStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => DailyTaskStatus.pending,
    );
  }
}

/// Progress aggregation for a learner's daily task set.
@immutable
class DailyTaskProgress {
  final int totalTasks;
  final int completedTasks;
  final int estimatedTotalMinutes;
  final int earnedXpToday;
  final double completionPercentage;

  const DailyTaskProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.estimatedTotalMinutes,
    required this.earnedXpToday,
    required this.completionPercentage,
  });

  factory DailyTaskProgress.fromTasks(List<DailyTask> tasks) {
    if (tasks.isEmpty) {
      return const DailyTaskProgress(
        totalTasks: 0,
        completedTasks: 0,
        estimatedTotalMinutes: 0,
        earnedXpToday: 0,
        completionPercentage: 0.0,
      );
    }

    final total = tasks.length;
    final completed =
        tasks
            .where((t) => t.completed || t.status == DailyTaskStatus.completed)
            .length;
    final totalMinutes = tasks.fold<int>(
      0,
      (sum, t) => sum + t.estimatedMinutes,
    );
    final earnedXp = tasks
        .where((t) => t.completed || t.status == DailyTaskStatus.completed)
        .fold<int>(0, (sum, t) => sum + t.xpReward);
    final percentage = total > 0 ? (completed / total) * 100.0 : 0.0;

    return DailyTaskProgress(
      totalTasks: total,
      completedTasks: completed,
      estimatedTotalMinutes: totalMinutes,
      earnedXpToday: earnedXp,
      completionPercentage: percentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'estimatedTotalMinutes': estimatedTotalMinutes,
      'earnedXpToday': earnedXpToday,
      'completionPercentage': completionPercentage,
    };
  }
}

/// Immutable domain model representing a deterministic daily learning task for school students.
@immutable
class DailyTask {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final DailyTaskType type;
  final LearningSkill skill;
  final String difficulty; // beginner, intermediate, advanced
  final int estimatedMinutes;
  final int xpReward;
  final bool completed;
  final DailyTaskStatus status;
  final double progress; // 0.0 to 1.0
  final DateTime dueDate;
  final String? lessonId;
  final String? gameId;
  final String actionRoute;
  final bool isForChild;

  const DailyTask({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.type,
    required this.skill,
    this.difficulty = 'beginner',
    required this.estimatedMinutes,
    required this.xpReward,
    this.completed = false,
    this.status = DailyTaskStatus.pending,
    this.progress = 0.0,
    required this.dueDate,
    this.lessonId,
    this.gameId,
    required this.actionRoute,
    this.isForChild = false,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleArabic : titleEnglish;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionArabic : descriptionEnglish;

  DailyTask copyWith({
    String? id,
    String? titleArabic,
    String? titleEnglish,
    String? descriptionArabic,
    String? descriptionEnglish,
    DailyTaskType? type,
    LearningSkill? skill,
    String? difficulty,
    int? estimatedMinutes,
    int? xpReward,
    bool? completed,
    DailyTaskStatus? status,
    double? progress,
    DateTime? dueDate,
    String? lessonId,
    String? gameId,
    String? actionRoute,
    bool? isForChild,
  }) {
    return DailyTask(
      id: id ?? this.id,
      titleArabic: titleArabic ?? this.titleArabic,
      titleEnglish: titleEnglish ?? this.titleEnglish,
      descriptionArabic: descriptionArabic ?? this.descriptionArabic,
      descriptionEnglish: descriptionEnglish ?? this.descriptionEnglish,
      type: type ?? this.type,
      skill: skill ?? this.skill,
      difficulty: difficulty ?? this.difficulty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      lessonId: lessonId ?? this.lessonId,
      gameId: gameId ?? this.gameId,
      actionRoute: actionRoute ?? this.actionRoute,
      isForChild: isForChild ?? this.isForChild,
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
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'completed': completed,
      'status': status.name,
      'progress': progress,
      'dueDate': dueDate.toIso8601String(),
      'lessonId': lessonId,
      'gameId': gameId,
      'actionRoute': actionRoute,
      'isForChild': isForChild,
    };
  }

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    final completedVal = json['completed'] as bool? ?? false;
    final statusVal =
        json['status'] != null
            ? DailyTaskStatus.fromString(json['status'] as String)
            : (completedVal
                ? DailyTaskStatus.completed
                : DailyTaskStatus.pending);

    return DailyTask(
      id: json['id'] as String,
      titleArabic: json['titleArabic'] as String,
      titleEnglish: json['titleEnglish'] as String,
      descriptionArabic: json['descriptionArabic'] as String,
      descriptionEnglish: json['descriptionEnglish'] as String,
      type: DailyTaskType.fromString(json['type'] as String),
      skill: LearningSkill.values.firstWhere(
        (s) => s.name == json['skill'],
        orElse: () => LearningSkill.vocabulary,
      ),
      difficulty: json['difficulty'] as String? ?? 'beginner',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      xpReward: json['xpReward'] as int? ?? 15,
      completed: completedVal || statusVal == DailyTaskStatus.completed,
      status: statusVal,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      dueDate:
          json['dueDate'] != null
              ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
              : DateTime.now(),
      lessonId: json['lessonId'] as String?,
      gameId: json['gameId'] as String?,
      actionRoute: json['actionRoute'] as String? ?? '/learning',
      isForChild: json['isForChild'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          completed == other.completed &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode =>
      id.hashCode ^ completed.hashCode ^ status.hashCode ^ progress.hashCode;
}
