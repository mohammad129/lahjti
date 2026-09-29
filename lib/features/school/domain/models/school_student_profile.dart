import 'package:flutter/foundation.dart';
import '../../../onboarding/domain/models/age_group.dart';

/// Immutable model representing a school student's profile.
@immutable
class SchoolStudentProfile {
  final String studentId;
  final String fullName;
  final String schoolId;
  final String schoolCode;
  final String schoolName;
  final String grade;
  final String classSection;
  final AgeGroup? ageGroup;
  final String? nativeLanguage;
  final String? targetLanguageCode;
  final String? learningGoal;
  final String? experienceLevel;
  final String? selectedTutorId;
  final DateTime enrolledAt;

  const SchoolStudentProfile({
    required this.studentId,
    required this.fullName,
    required this.schoolId,
    required this.schoolCode,
    required this.schoolName,
    required this.grade,
    required this.classSection,
    this.ageGroup,
    this.nativeLanguage,
    this.targetLanguageCode,
    this.learningGoal,
    this.experienceLevel,
    this.selectedTutorId,
    required this.enrolledAt,
  });

  SchoolStudentProfile copyWith({
    String? studentId,
    String? fullName,
    String? schoolId,
    String? schoolCode,
    String? schoolName,
    String? grade,
    String? classSection,
    AgeGroup? ageGroup,
    String? nativeLanguage,
    String? targetLanguageCode,
    String? learningGoal,
    String? experienceLevel,
    String? selectedTutorId,
    DateTime? enrolledAt,
  }) {
    return SchoolStudentProfile(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      classSection: classSection ?? this.classSection,
      ageGroup: ageGroup ?? this.ageGroup,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      learningGoal: learningGoal ?? this.learningGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      selectedTutorId: selectedTutorId ?? this.selectedTutorId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
      'grade': grade,
      'classSection': classSection,
      'ageGroup': ageGroup?.name,
      'nativeLanguage': nativeLanguage,
      'targetLanguageCode': targetLanguageCode,
      'learningGoal': learningGoal,
      'experienceLevel': experienceLevel,
      'selectedTutorId': selectedTutorId,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }

  factory SchoolStudentProfile.fromJson(Map<String, dynamic> json) {
    return SchoolStudentProfile(
      studentId: json['studentId'] as String,
      fullName: json['fullName'] as String,
      schoolId: json['schoolId'] as String,
      schoolCode: json['schoolCode'] as String,
      schoolName: json['schoolName'] as String,
      grade: json['grade'] as String,
      classSection: json['classSection'] as String,
      ageGroup:
          json['ageGroup'] != null
              ? AgeGroup.values.firstWhere(
                (a) => a.name == json['ageGroup'],
                orElse: () => AgeGroup.age6_10,
              )
              : null,
      nativeLanguage: json['nativeLanguage'] as String?,
      targetLanguageCode: json['targetLanguageCode'] as String?,
      learningGoal: json['learningGoal'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      selectedTutorId: json['selectedTutorId'] as String?,
      enrolledAt:
          json['enrolledAt'] != null
              ? DateTime.tryParse(json['enrolledAt'] as String) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolStudentProfile &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          schoolCode == other.schoolCode;

  @override
  int get hashCode => studentId.hashCode ^ schoolCode.hashCode;
}
