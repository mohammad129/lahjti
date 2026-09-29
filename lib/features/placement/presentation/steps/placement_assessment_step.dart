import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/feedback/loading_view.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/placement_provider.dart';

/// Step 8: Interactive Conversational Placement Assessment
class PlacementAssessmentStep extends ConsumerStatefulWidget {
  const PlacementAssessmentStep({super.key});

  @override
  ConsumerState<PlacementAssessmentStep> createState() =>
      _PlacementAssessmentStepState();
}

class _PlacementAssessmentStepState
    extends ConsumerState<PlacementAssessmentStep> {
  final _textController = TextEditingController();
  bool _showHint = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit({bool isSkip = false}) {
    final text = _textController.text;
    _textController.clear();
    setState(() => _showHint = false);

    ref
        .read(placementNotifierProvider.notifier)
        .submitAnswer(response: text, isSkipped: isSkip);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final placementState = ref.watch(placementNotifierProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

    // Auto-advance to results when completed
    ref.listen<PlacementState>(placementNotifierProvider, (prev, next) {
      if (next.status == PlacementStatus.completed &&
          prev?.status != PlacementStatus.completed) {
        ref.read(onboardingProvider.notifier).nextStep();
      }
    });

    if (placementState.status == PlacementStatus.initializing) {
      return const LoadingView();
    }

    if (placementState.status == PlacementStatus.error) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.evalErrorRetry,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.tryAgain,
                width: 160,
                height: 44,
                onPressed: () {
                  ref
                      .read(placementNotifierProvider.notifier)
                      .startSession(onboardingData);
                },
              ),
            ],
          ),
        ),
      );
    }

    final question = placementState.currentQuestion;
    if (question == null) {
      return const LoadingView();
    }

    final session = placementState.session;
    final currentIndex = (session?.currentQuestionIndex ?? 0) + 1;
    final tutor = TutorPersona.tutors.firstWhere(
      (t) => t.id == onboardingData.selectedTutorId,
      orElse: () => TutorPersona.tutors.first,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question count & Tutor header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    tutor.id == 'abbas' ? '👨‍🏫' : '👩‍🏫',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    tutor.localizedName(l10n),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLightVariant,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  l10n.questionProgress(currentIndex, 8),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Question Prompt Card
          Container(
            padding: AppSpacing.paddingXl,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    height: 1.35,
                  ),
                ),
                if (question.promptArabic.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    question.promptArabic,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryLight,
                      height: 1.45,
                    ),
                  ),
                ],
                if (question.hintsAllowed && question.hint != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () => setState(() => _showHint = !_showHint),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.answerHint,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showHint) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.accentContainer.withValues(alpha: 0.4),
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Text(
                        question.hint!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Interim Feedback Banner
          if (placementState.feedbackMessage != null &&
              placementState.feedbackMessage!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      placementState.feedbackMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Response Input
          TextField(
            controller: _textController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _handleSubmit(),
            enabled: !placementState.isSubmitting,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: l10n.answerInputHint,
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: AppSpacing.paddingLg,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusLg,
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusLg,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          PrimaryButton(
            label: l10n.answerSubmit,
            isLoading: placementState.isSubmitting,
            onPressed: () => _handleSubmit(),
          ),

          const SizedBox(height: AppSpacing.sm),

          SecondaryButton(
            label: l10n.answerDontKnow,
            onPressed:
                placementState.isSubmitting
                    ? null
                    : () => _handleSubmit(isSkip: true),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
