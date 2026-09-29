import 'package:flutter/foundation.dart';
import '../../../learning/domain/models/learning_skill.dart';

/// Immutable model representing an academic classroom assigned to a teacher.
@immutable
class Classroom {
  final String id;
  final String schoolCode;
  final String name;
  final String grade;
  final String section;
  final String teacherId;
  final bool active;
  final DateTime createdAt;

  const Classroom({
    required this.id,
    required this.schoolCode,
    required this.name,
    required this.grade,
    required this.section,
    required this.teacherId,
    this.active = true,
    required this.createdAt,
  });

  String get displayName => '$grade - $section';

  Classroom copyWith({
    String? id,
    String? schoolCode,
    String? name,
    String? grade,
    String? section,
    String? teacherId,
    bool? active,
    DateTime? createdAt,
  }) {
    return Classroom(
      id: id ?? this.id,
      schoolCode: schoolCode ?? this.schoolCode,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      teacherId: teacherId ?? this.teacherId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolCode': schoolCode,
      'name': name,
      'grade': grade,
      'section': section,
      'teacherId': teacherId,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] as String,
      schoolCode: json['schoolCode'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      section: json['section'] as String,
      teacherId: json['teacherId'] as String,
      active: json['active'] as bool? ?? true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Classroom && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents an enrolled student in a specific classroom.
@immutable
class ClassroomStudent {
  final String studentId;
  final String classId;
  final String schoolCode;
  final String fullName;
  final String avatarEmoji;
  final DateTime joinedAt;

  const ClassroomStudent({
    required this.studentId,
    required this.classId,
    required this.schoolCode,
    required this.fullName,
    this.avatarEmoji = '🎒',
    required this.joinedAt,
  });

  /// Privacy-safe visible name for minor students (e.g. "سامي ع." / "Sami A.")
  String get visibleName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    final first = parts.first;
    final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first $lastInitial.';
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'classId': classId,
      'schoolCode': schoolCode,
      'fullName': fullName,
      'avatarEmoji': avatarEmoji,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory ClassroomStudent.fromJson(Map<String, dynamic> json) {
    return ClassroomStudent(
      studentId: json['studentId'] as String,
      classId: json['classId'] as String,
      schoolCode: json['schoolCode'] as String,
      fullName: json['fullName'] as String,
      avatarEmoji: json['avatarEmoji'] as String? ?? '🎒',
      joinedAt:
          json['joinedAt'] != null
              ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

/// Overview metric aggregates for the main Teacher Dashboard.
@immutable
class TeacherOverviewData {
  final int totalStudents;
  final int activeTodayCount;
  final int completedTasksTodayCount;
  final double averageProgressPercentage;
  final bool hasSufficientData;

  const TeacherOverviewData({
    required this.totalStudents,
    required this.activeTodayCount,
    required this.completedTasksTodayCount,
    required this.averageProgressPercentage,
    required this.hasSufficientData,
  });

  factory TeacherOverviewData.empty() {
    return const TeacherOverviewData(
      totalStudents: 0,
      activeTodayCount: 0,
      completedTasksTodayCount: 0,
      averageProgressPercentage: 0.0,
      hasSufficientData: false,
    );
  }
}

/// Summary card representation of a teacher's classroom on the dashboard.
@immutable
class TeacherClassSummary {
  final String classId;
  final String className;
  final String grade;
  final String section;
  final int studentCount;
  final int activeTodayCount;
  final int completedTasksTodayCount;
  final double averageProgressPercentage;
  final bool hasSufficientData;

  const TeacherClassSummary({
    required this.classId,
    required this.className,
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.activeTodayCount,
    required this.completedTasksTodayCount,
    required this.averageProgressPercentage,
    required this.hasSufficientData,
  });

  String get displayName => '$grade - $section';
}

/// Student performance summary for classroom student lists.
@immutable
class TeacherStudentSummary {
  final String studentId;
  final String classId;
  final String visibleName;
  final String avatarEmoji;
  final String cefrLevel;
  final int totalXp;
  final int streakDays;
  final bool completedTasksToday;
  final double overallProgressPercentage;
  final bool hasSufficientData;
  final DateTime lastActiveDate;

  const TeacherStudentSummary({
    required this.studentId,
    required this.classId,
    required this.visibleName,
    this.avatarEmoji = '🎒',
    required this.cefrLevel,
    required this.totalXp,
    required this.streakDays,
    required this.completedTasksToday,
    required this.overallProgressPercentage,
    required this.hasSufficientData,
    required this.lastActiveDate,
  });
}

/// Detailed educational learning overview for a student.
@immutable
class StudentLearningOverview {
  final String studentId;
  final String visibleName;
  final String cefrLevel;
  final int totalXp;
  final int streakDays;
  final int lessonsCompletedCount;
  final int vocabularyMasteredCount;
  final int examsCompletedCount;
  final int totalLearningMinutes;
  final bool hasSufficientData;
  final DateTime lastActiveDate;

  const StudentLearningOverview({
    required this.studentId,
    required this.visibleName,
    required this.cefrLevel,
    required this.totalXp,
    required this.streakDays,
    required this.lessonsCompletedCount,
    required this.vocabularyMasteredCount,
    required this.examsCompletedCount,
    required this.totalLearningMinutes,
    required this.hasSufficientData,
    required this.lastActiveDate,
  });
}

/// Educational skill progress summary for a student.
@immutable
class StudentSkillSummary {
  final LearningSkill skill;
  final int score; // 0 - 100
  final int assessedAttempts;
  final bool hasSufficientEvidence;

  const StudentSkillSummary({
    required this.skill,
    required this.score,
    required this.assessedAttempts,
    required this.hasSufficientEvidence,
  });
}

/// Educational activity log item for a student.
@immutable
class StudentActivitySummary {
  final String id;
  final String title;
  final String type; // 'lesson', 'vocabulary', 'exam', 'tutor'
  final DateTime timestamp;
  final String details;

  const StudentActivitySummary({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    required this.details,
  });
}
