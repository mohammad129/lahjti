import 'package:flutter/foundation.dart';

/// Immutable model representing a school teacher's profile.
@immutable
class TeacherProfile {
  final String teacherId;
  final String fullName;
  final String email;
  final String schoolId;
  final String schoolCode;
  final String schoolName;
  final String subjectTaught;
  final List<String> gradesTaught;
  final DateTime createdAt;

  const TeacherProfile({
    required this.teacherId,
    required this.fullName,
    required this.email,
    required this.schoolId,
    required this.schoolCode,
    required this.schoolName,
    required this.subjectTaught,
    this.gradesTaught = const [],
    required this.createdAt,
  });

  TeacherProfile copyWith({
    String? teacherId,
    String? fullName,
    String? email,
    String? schoolId,
    String? schoolCode,
    String? schoolName,
    String? subjectTaught,
    List<String>? gradesTaught,
    DateTime? createdAt,
  }) {
    return TeacherProfile(
      teacherId: teacherId ?? this.teacherId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
      subjectTaught: subjectTaught ?? this.subjectTaught,
      gradesTaught: gradesTaught ?? this.gradesTaught,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'fullName': fullName,
      'email': email,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
      'subjectTaught': subjectTaught,
      'gradesTaught': gradesTaught,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      teacherId: json['teacherId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String? ?? '',
      schoolId: json['schoolId'] as String,
      schoolCode: json['schoolCode'] as String,
      schoolName: json['schoolName'] as String,
      subjectTaught: json['subjectTaught'] as String,
      gradesTaught:
          (json['gradesTaught'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherProfile &&
          runtimeType == other.runtimeType &&
          teacherId == other.teacherId &&
          schoolCode == other.schoolCode;

  @override
  int get hashCode => teacherId.hashCode ^ schoolCode.hashCode;
}
