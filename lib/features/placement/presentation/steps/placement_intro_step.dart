import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/placement_provider.dart';

/// Step 7: Placement Introduction Screen
class PlacementIntroStep extends ConsumerWidget {
  const PlacementIntroStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

    final tutor = TutorPersona.tutors.firstWhere(
      (t) => t.id == onboardingData.selectedTutorId,
      orElse: () => TutorPersona.tutors.first,
    );

    final isAbbas = tutor.id == 'abbas';
    final tutorMessage =
        isAbbas ? l10n.placementIntroAbbas : l10n.placementIntroDunya;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Title
            Text(
              l10n.placementIntroTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryLight,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Supportive explanation
            Text(
              l10n.placementIntroDesc1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.placementIntroDesc2,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Conversational Tutor Card
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color:
                    isAbbas
                        ? AppColors.primaryContainer.withValues(alpha: 0.4)
                        : AppColors.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: AppSpacing.borderRadiusXl,
                border: Border.all(
                  color: (isAbbas ? AppColors.primary : AppColors.secondary)
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient:
                          isAbbas
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                                colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                              ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isAbbas ? '👨‍🏫' : '👩‍🏫',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutor.localizedName(l10n),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          tutorMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryLight,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Start Assessment CTA
            PrimaryButton(
              label: l10n.placementIntroCta,
              onPressed: () {
                ref
                    .read(placementNotifierProvider.notifier)
                    .startSession(onboardingData);
                ref.read(onboardingProvider.notifier).nextStep();
              },
            ),
          ],
        ),
      ),
    );
  }
}
