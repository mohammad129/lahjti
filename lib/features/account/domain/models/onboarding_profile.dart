import 'package:flutter/foundation.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/experience_level.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import 'account_context.dart';
import 'school_membership.dart';
import 'subscription_access.dart';
import 'user_role.dart';

/// Immutable domain model encapsulating the complete user onboarding and account profile.
@immutable
class OnboardingProfile {
  final String userId;
  final UserRole userRole;
  final AccountContext accountContext;
  final String name;
  final AgeGroup? ageGroup;
  final NativeLanguage nativeLanguage;
  final SupportedLanguage? targetLanguage;
  final LearningGoal? learningGoal;
  final ExperienceLevel? experienceLevel;
  final String? selectedTutorId;
  final SchoolMembership? schoolMembership;
  final SubscriptionAccess? subscriptionAccess;
  final DateTime createdAt;
  final bool isCompleted;

  const OnboardingProfile({
    required this.userId,
    required this.userRole,
    required this.accountContext,
    required this.name,
    this.ageGroup,
    this.nativeLanguage = NativeLanguage.arabic,
    this.targetLanguage,
    this.learningGoal,
    this.experienceLevel,
    this.selectedTutorId,
    this.schoolMembership,
    this.subscriptionAccess,
    required this.createdAt,
    this.isCompleted = false,
  });

  bool get isChild => ageGroup?.isChild ?? false;
  bool get isTeen => ageGroup?.isTeen ?? false;
  bool get isAdult => ageGroup?.isAdult ?? true;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userRole': userRole.name,
      'accountContext': accountContext.name,
      'name': name,
      'ageGroup': ageGroup?.name,
      'nativeLanguage': nativeLanguage.name,
      'targetLanguage': targetLanguage?.code,
      'learningGoal': learningGoal?.name,
      'experienceLevel': experienceLevel?.name,
      'selectedTutorId': selectedTutorId,
      'schoolMembership': schoolMembership?.toJson(),
      'subscriptionAccess': subscriptionAccess?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      userId: json['userId'] as String? ?? 'user_default',
      userRole: UserRole.fromString(json['userRole'] as String?),
      accountContext: AccountContext.fromString(
        json['accountContext'] as String?,
      ),
      name: json['name'] as String? ?? '',
      ageGroup:
          json['ageGroup'] != null
              ? AgeGroup.values.firstWhere(
                (a) => a.name == json['ageGroup'],
                orElse: () => AgeGroup.age18_25,
              )
              : null,
      nativeLanguage:
          json['nativeLanguage'] != null
              ? NativeLanguage.values.firstWhere(
                (n) => n.name == json['nativeLanguage'],
                orElse: () => NativeLanguage.arabic,
              )
              : NativeLanguage.arabic,
      targetLanguage:
          json['targetLanguage'] != null
              ? SupportedLanguage.fromCode(json['targetLanguage'] as String?)
              : null,
      learningGoal:
          json['learningGoal'] != null
              ? LearningGoal.values.firstWhere(
                (g) => g.name == json['learningGoal'],
                orElse: () => LearningGoal.casualConversation,
              )
              : null,
      experienceLevel:
          json['experienceLevel'] != null
              ? ExperienceLevel.values.firstWhere(
                (e) => e.name == json['experienceLevel'],
                orElse: () => ExperienceLevel.beginner,
              )
              : null,
      selectedTutorId: json['selectedTutorId'] as String?,
      schoolMembership:
          json['schoolMembership'] != null
              ? SchoolMembership.fromJson(
                json['schoolMembership'] as Map<String, dynamic>,
              )
              : null,
      subscriptionAccess:
          json['subscriptionAccess'] != null
              ? SubscriptionAccess.fromJson(
                json['subscriptionAccess'] as Map<String, dynamic>,
              )
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  OnboardingProfile copyWith({
    String? userId,
    UserRole? userRole,
    AccountContext? accountContext,
    String? name,
    AgeGroup? ageGroup,
    NativeLanguage? nativeLanguage,
    SupportedLanguage? targetLanguage,
    LearningGoal? learningGoal,
    ExperienceLevel? experienceLevel,
    String? selectedTutorId,
    SchoolMembership? schoolMembership,
    SubscriptionAccess? subscriptionAccess,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return OnboardingProfile(
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      accountContext: accountContext ?? this.accountContext,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      learningGoal: learningGoal ?? this.learningGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      selectedTutorId: selectedTutorId ?? this.selectedTutorId,
      schoolMembership: schoolMembership ?? this.schoolMembership,
      subscriptionAccess: subscriptionAccess ?? this.subscriptionAccess,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
