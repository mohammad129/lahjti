import 'package:flutter/foundation.dart';
import '../../../school/domain/models/school_role.dart';

/// Immutable model representing a verified connection to an educational institution.
@immutable
class SchoolMembership {
  final String schoolId;
  final String schoolCode;
  final String schoolName;
  final SchoolRole role;
  final String? grade;
  final String? classSection;
  final DateTime joinedAt;
  final bool isVerified;
  final int trialDaysRemaining;

  const SchoolMembership({
    required this.schoolId,
    required this.schoolCode,
    required this.schoolName,
    required this.role,
    this.grade,
    this.classSection,
    required this.joinedAt,
    this.isVerified = true,
    this.trialDaysRemaining = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
      'role': role.name,
      'grade': grade,
      'classSection': classSection,
      'joinedAt': joinedAt.toIso8601String(),
      'isVerified': isVerified,
      'trialDaysRemaining': trialDaysRemaining,
    };
  }

  factory SchoolMembership.fromJson(Map<String, dynamic> json) {
    return SchoolMembership(
      schoolId: json['schoolId'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      role:
          SchoolRole.fromString(json['role'] as String?) ?? SchoolRole.student,
      grade: json['grade'] as String?,
      classSection: json['classSection'] as String?,
      joinedAt:
          json['joinedAt'] != null
              ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? true,
      trialDaysRemaining: json['trialDaysRemaining'] as int? ?? 10,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolMembership &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId &&
          schoolCode == other.schoolCode &&
          schoolName == other.schoolName &&
          role == other.role &&
          grade == other.grade &&
          classSection == other.classSection &&
          isVerified == other.isVerified;

  @override
  int get hashCode =>
      schoolId.hashCode ^
      schoolCode.hashCode ^
      schoolName.hashCode ^
      role.hashCode ^
      grade.hashCode ^
      classSection.hashCode ^
      isVerified.hashCode;
}
