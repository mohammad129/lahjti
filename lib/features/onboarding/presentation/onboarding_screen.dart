import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../placement/presentation/steps/placement_assessment_step.dart';
import '../../placement/presentation/steps/placement_intro_step.dart';
import '../../placement/presentation/steps/placement_result_step.dart';
import 'providers/onboarding_provider.dart';
import 'steps/account_registration_step.dart';
import 'steps/age_group_step.dart';
import 'steps/completion_step.dart';
import 'steps/experience_level_step.dart';
import 'steps/learning_goal_step.dart';
import 'steps/native_language_step.dart';
import 'steps/school_code_verification_step.dart';
import 'steps/school_student_info_step.dart';
import 'steps/target_language_step.dart';
import 'steps/teacher_setup_step.dart';
import 'steps/tutor_selection_step.dart';
import 'widgets/onboarding_progress_bar.dart';

/// Main Onboarding Orchestrator Screen handling stepped navigation,
/// adaptive placement assessment, and state persistence for both
/// Individual learners and School (Student / Teacher) accounts.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final l10n = context.l10n;
    final currentStep = onboardingState.currentStepIndex;
    final isCompletion = onboardingState.isCompletionStep;
    final isPlacementOrCompletion =
        onboardingState.isPlacementStep || isCompletion;
    final isChildMode = onboardingState.data.ageGroup?.isChild ?? false;

    // Determine if the current step handles its own form submission (e.g., account registration)
    final isRegistrationStep =
        (onboardingState.data.isSchoolStudent && currentStep == 7) ||
        (!onboardingState.data.isSchool && currentStep == 5);

    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 0) {
          notifier.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (currentStep > 0) {
                notifier.previousStep();
              } else if (context.canPop()) {
                context.pop();
              }
            },
          ),
          title:
              !isPlacementOrCompletion
                  ? OnboardingProgressBar(
                    currentStep: currentStep,
                    totalSteps: onboardingState.totalInteractiveSteps,
                  )
                  : null,
          centerTitle: true,
          actions: [
            if (isChildMode && !isPlacementOrCompletion)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🎈 أطفال',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: isCompletion ? EdgeInsets.zero : AppSpacing.screenPadding,
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        '${onboardingState.data.accountContext.name}_${onboardingState.data.schoolRole?.name ?? "ind"}_$currentStep',
                      ),
                      child: _buildStep(currentStep, onboardingState),
                    ),
                  ),
                ),

                // Sticky Bottom Continue button for standard selection steps
                if (!isPlacementOrCompletion && !isRegistrationStep) ...[
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: isChildMode ? 56.0 : 48.0,
                    ),
                    child: PrimaryButton(
                      label: l10n.continueText,
                      onPressed:
                          onboardingState.canProceed
                              ? () {
                                notifier.nextStep();
                              }
                              : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int stepIndex, OnboardingState state) {
    if (state.data.isSchoolTeacher) {
      switch (stepIndex) {
        case 0:
          return const SchoolCodeVerificationStep();
        case 1:
          return const TeacherSetupStep();
        case 2:
          return const CompletionStep();
        default:
          return const SchoolCodeVerificationStep();
      }
    }

    if (state.data.isSchoolStudent) {
      switch (stepIndex) {
        case 0:
          return const SchoolCodeVerificationStep();
        case 1:
          return const SchoolStudentInfoStep();
        case 2:
          return const TargetLanguageStep();
        case 3:
          return const AgeGroupStep();
        case 4:
          return const NativeLanguageStep();
        case 5:
          return const LearningGoalStep();
        case 6:
          return const ExperienceLevelStep();
        case 7:
          return const AccountRegistrationStep();
        case 8:
          return const TutorSelectionStep();
        case 9:
          return const PlacementIntroStep();
        case 10:
          return const PlacementAssessmentStep();
        case 11:
          return const PlacementResultStep();
        case 12:
          return const CompletionStep();
        default:
          return const SchoolCodeVerificationStep();
      }
    }

    // Default Individual flow (Maintains exact backward-compatible step indices 0-10)
    switch (stepIndex) {
      case 0:
        return const TargetLanguageStep();
      case 1:
        return const AgeGroupStep();
      case 2:
        return const NativeLanguageStep();
      case 3:
        return const LearningGoalStep();
      case 4:
        return const ExperienceLevelStep();
      case 5:
        return const AccountRegistrationStep();
      case 6:
        return const TutorSelectionStep();
      case 7:
        return const PlacementIntroStep();
      case 8:
        return const PlacementAssessmentStep();
      case 9:
        return const PlacementResultStep();
      case 10:
        return const CompletionStep();
      default:
        return const TargetLanguageStep();
    }
  }
}
