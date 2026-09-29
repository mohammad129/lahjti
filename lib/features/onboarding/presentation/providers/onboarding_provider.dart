import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../school/domain/models/school_role.dart';
import '../../domain/models/age_group.dart';
import '../../domain/models/experience_level.dart';
import '../../domain/models/learning_goal.dart';
import '../../domain/models/native_language.dart';
import '../../domain/models/onboarding_data.dart';
import '../../domain/models/supported_language.dart';

/// State of the onboarding and placement workflow.
class OnboardingState {
  final int currentStepIndex;
  final OnboardingData data;
  final bool isLoading;

  static const int individualTotalInteractiveSteps = 7; // Steps 0 to 6
  static const int individualPlacementIntroStepIndex = 7;
  static const int individualPlacementAssessmentStepIndex = 8;
  static const int individualPlacementResultStepIndex = 9;
  static const int individualCompletionStepIndex = 10;

  static const int teacherTotalInteractiveSteps = 2; // Steps 0 to 1
  static const int teacherCompletionStepIndex = 2;

  static const int studentTotalInteractiveSteps = 9; // Steps 0 to 8
  static const int studentPlacementIntroStepIndex = 9;
  static const int studentPlacementAssessmentStepIndex = 10;
  static const int studentPlacementResultStepIndex = 11;
  static const int studentCompletionStepIndex = 12;

  const OnboardingState({
    this.currentStepIndex = 0,
    this.data = const OnboardingData(
      accountContext: AccountContext.individual,
      nativeLanguage: NativeLanguage.arabic, // Default native Arabic
    ),
    this.isLoading = false,
  });

  bool get isFirstStep => currentStepIndex == 0;

  int get maxStepIndex {
    if (data.isSchoolTeacher) return teacherCompletionStepIndex;
    if (data.isSchoolStudent) return studentCompletionStepIndex;
    return individualCompletionStepIndex;
  }

  int get totalInteractiveSteps {
    if (data.isSchoolTeacher) return teacherTotalInteractiveSteps;
    if (data.isSchoolStudent) return studentTotalInteractiveSteps;
    return individualTotalInteractiveSteps;
  }

  bool get isCompletionStep {
    if (data.isSchoolTeacher) {
      return currentStepIndex == teacherCompletionStepIndex;
    }
    if (data.isSchoolStudent) {
      return currentStepIndex == studentCompletionStepIndex;
    }
    return currentStepIndex == individualCompletionStepIndex;
  }

  bool get isPlacementStep {
    if (data.isSchoolTeacher) return false;
    if (data.isSchoolStudent) {
      return currentStepIndex >= studentPlacementIntroStepIndex &&
          currentStepIndex <= studentPlacementResultStepIndex;
    }
    return currentStepIndex >= individualPlacementIntroStepIndex &&
        currentStepIndex <= individualPlacementResultStepIndex;
  }

  /// Validates whether the user has fulfilled requirements for the current step.
  bool get canProceed {
    if (data.isSchoolTeacher) {
      switch (currentStepIndex) {
        case 0:
          return data.schoolCode != null && data.schoolCode!.trim().isNotEmpty;
        case 1:
          return data.teacherSubject != null &&
              data.teacherSubject!.trim().isNotEmpty &&
              data.registeredName != null &&
              data.registeredName!.trim().isNotEmpty;
        case 2:
        default:
          return true;
      }
    }

    if (data.isSchoolStudent) {
      switch (currentStepIndex) {
        case 0:
          return data.schoolCode != null && data.schoolCode!.trim().isNotEmpty;
        case 1:
          return data.schoolGrade != null &&
              data.schoolGrade!.trim().isNotEmpty;
        case 2:
          return data.targetLanguage != null;
        case 3:
          return data.ageGroup != null;
        case 4:
          return data.nativeLanguage != null;
        case 5:
          return data.learningGoal != null;
        case 6:
          return data.experienceLevel != null;
        case 7:
          return true; // Registration validated in form
        case 8:
          return data.selectedTutorId != null;
        case 9:
        case 10:
        case 11:
        case 12:
        default:
          return true;
      }
    }

    // Individual Default Flow:
    switch (currentStepIndex) {
      case 0:
        return data.targetLanguage != null;
      case 1:
        return data.ageGroup != null;
      case 2:
        return data.nativeLanguage != null;
      case 3:
        return data.learningGoal != null;
      case 4:
        return data.experienceLevel != null;
      case 5:
        // Registration is validated inside the form step widget
        return true;
      case 6:
        return data.selectedTutorId != null;
      case 7:
      case 8:
      case 9:
      case 10:
        return true;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    int? currentStepIndex,
    OnboardingData? data,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State notifier managing onboarding navigation and selections.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({OnboardingState initialState = const OnboardingState()})
    : super(initialState);

  void selectAccountContext(AccountContext context) {
    state = state.copyWith(data: state.data.copyWith(accountContext: context));
  }

  void selectSchoolRole(SchoolRole role) {
    state = state.copyWith(
      currentStepIndex: 0,
      data: state.data.copyWith(
        accountContext: AccountContext.school,
        schoolRole: role,
      ),
    );
  }

  void setSchoolDetails({
    required String schoolCode,
    required String schoolName,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(schoolCode: schoolCode, schoolName: schoolName),
    );
  }

  void setStudentClassDetails({
    required String grade,
    required String classSection,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        schoolGrade: grade,
        schoolClassSection: classSection,
      ),
    );
  }

  void setTeacherDetails({
    required String fullName,
    required String subject,
    required List<String> gradesTaught,
  }) {
    state = state.copyWith(
      data: state.data.copyWith(
        registeredName: fullName,
        teacherSubject: subject,
        teacherGradesTaught: gradesTaught,
      ),
    );
  }

  void selectTargetLanguage(SupportedLanguage language) {
    state = state.copyWith(data: state.data.copyWith(targetLanguage: language));
  }

  void selectAgeGroup(AgeGroup ageGroup) {
    state = state.copyWith(data: state.data.copyWith(ageGroup: ageGroup));
  }

  void selectNativeLanguage(NativeLanguage nativeLanguage) {
    state = state.copyWith(
      data: state.data.copyWith(nativeLanguage: nativeLanguage),
    );
  }

  void selectLearningGoal(LearningGoal goal) {
    state = state.copyWith(data: state.data.copyWith(learningGoal: goal));
  }

  void selectExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(data: state.data.copyWith(experienceLevel: level));
  }

  void selectTutor(String tutorId) {
    state = state.copyWith(data: state.data.copyWith(selectedTutorId: tutorId));
  }

  void setRegisteredUser(AuthUser user) {
    state = state.copyWith(
      data: state.data.copyWith(
        registeredUserId: user.id,
        registeredEmail: user.email,
        registeredName: user.fullName,
      ),
    );
  }

  bool nextStep() {
    if (state.currentStepIndex < state.maxStepIndex) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
      return true;
    }
    return false;
  }

  bool previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
      return true;
    }
    return false;
  }

  void goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex <= state.maxStepIndex) {
      state = state.copyWith(currentStepIndex: stepIndex);
    }
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier();
    });
