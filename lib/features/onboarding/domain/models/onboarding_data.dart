import 'package:flutter/foundation.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../school/domain/models/school_role.dart';
import 'age_group.dart';
import 'experience_level.dart';
import 'learning_goal.dart';
import 'native_language.dart';
import 'supported_language.dart';

/// Immutable model representing the user's choices accumulated during Onboarding.
@immutable
class OnboardingData {
  final AccountContext accountContext;
  final SchoolRole? schoolRole;
  final String? schoolCode;
  final String? schoolName;
  final String? schoolGrade;
  final String? schoolClassSection;
  final String? teacherSubject;
  final List<String>? teacherGradesTaught;

  final SupportedLanguage? targetLanguage;
  final AgeGroup? ageGroup;
  final NativeLanguage? nativeLanguage;
  final LearningGoal? learningGoal;
  final ExperienceLevel? experienceLevel;
  final String? selectedTutorId;
  final String? registeredUserId;
  final String? registeredEmail;
  final String? registeredName;

  const OnboardingData({
    this.accountContext = AccountContext.individual,
    this.schoolRole,
    this.schoolCode,
    this.schoolName,
    this.schoolGrade,
    this.schoolClassSection,
    this.teacherSubject,
    this.teacherGradesTaught,
    this.targetLanguage,
    this.ageGroup,
    this.nativeLanguage,
    this.learningGoal,
    this.experienceLevel,
    this.selectedTutorId,
    this.registeredUserId,
    this.registeredEmail,
    this.registeredName,
  });

  bool get isIndividual => accountContext == AccountContext.individual;
  bool get isSchool => accountContext == AccountContext.school;
  bool get isSchoolStudent => isSchool && schoolRole == SchoolRole.student;
  bool get isSchoolTeacher => isSchool && schoolRole == SchoolRole.teacher;
  bool get isChild => ageGroup?.isChild ?? false;

  OnboardingData copyWith({
    AccountContext? accountContext,
    SchoolRole? schoolRole,
    String? schoolCode,
    String? schoolName,
    String? schoolGrade,
    String? schoolClassSection,
    String? teacherSubject,
    List<String>? teacherGradesTaught,
    SupportedLanguage? targetLanguage,
    AgeGroup? ageGroup,
    NativeLanguage? nativeLanguage,
    LearningGoal? learningGoal,
    ExperienceLevel? experienceLevel,
    String? selectedTutorId,
    String? registeredUserId,
    String? registeredEmail,
    String? registeredName,
  }) {
    return OnboardingData(
      accountContext: accountContext ?? this.accountContext,
      schoolRole: schoolRole ?? this.schoolRole,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
      schoolGrade: schoolGrade ?? this.schoolGrade,
      schoolClassSection: schoolClassSection ?? this.schoolClassSection,
      teacherSubject: teacherSubject ?? this.teacherSubject,
      teacherGradesTaught: teacherGradesTaught ?? this.teacherGradesTaught,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      ageGroup: ageGroup ?? this.ageGroup,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningGoal: learningGoal ?? this.learningGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      selectedTutorId: selectedTutorId ?? this.selectedTutorId,
      registeredUserId: registeredUserId ?? this.registeredUserId,
      registeredEmail: registeredEmail ?? this.registeredEmail,
      registeredName: registeredName ?? this.registeredName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingData &&
          runtimeType == other.runtimeType &&
          accountContext == other.accountContext &&
          schoolRole == other.schoolRole &&
          schoolCode == other.schoolCode &&
          schoolName == other.schoolName &&
          schoolGrade == other.schoolGrade &&
          schoolClassSection == other.schoolClassSection &&
          teacherSubject == other.teacherSubject &&
          listEquals(teacherGradesTaught, other.teacherGradesTaught) &&
          targetLanguage == other.targetLanguage &&
          ageGroup == other.ageGroup &&
          nativeLanguage == other.nativeLanguage &&
          learningGoal == other.learningGoal &&
          experienceLevel == other.experienceLevel &&
          selectedTutorId == other.selectedTutorId &&
          registeredUserId == other.registeredUserId &&
          registeredEmail == other.registeredEmail &&
          registeredName == other.registeredName;

  @override
  int get hashCode =>
      accountContext.hashCode ^
      schoolRole.hashCode ^
      schoolCode.hashCode ^
      schoolName.hashCode ^
      schoolGrade.hashCode ^
      schoolClassSection.hashCode ^
      teacherSubject.hashCode ^
      Object.hashAll(teacherGradesTaught ?? []) ^
      targetLanguage.hashCode ^
      ageGroup.hashCode ^
      nativeLanguage.hashCode ^
      learningGoal.hashCode ^
      experienceLevel.hashCode ^
      selectedTutorId.hashCode ^
      registeredUserId.hashCode ^
      registeredEmail.hashCode ^
      registeredName.hashCode;

  @override
  String toString() =>
      'OnboardingData(context: ${accountContext.name}, role: ${schoolRole?.name}, school: $schoolCode, target: ${targetLanguage?.nameEn}, tutor: $selectedTutorId)';
}
