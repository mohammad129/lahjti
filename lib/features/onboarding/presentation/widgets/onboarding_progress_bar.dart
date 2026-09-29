import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';

/// Clean animated linear progress indicator for the onboarding flow.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 7,
  });

  @override
  Widget build(BuildContext context) {
    // Current step is 1-indexed for display (1 to 7)
    final displayStep = (currentStep + 1).clamp(1, totalSteps);
    final progressValue = (displayStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.stepProgress(displayStep, totalSteps),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              '${(progressValue * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusFull,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: progressValue),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLightVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
