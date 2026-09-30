import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/models/tutor_persona.dart';
import '../providers/onboarding_provider.dart';

/// Step 8: Onboarding Completion Screen
class CompletionStep extends ConsumerWidget {
  const CompletionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(onboardingProvider.select((s) => s.data));
    final tutor = TutorPersona.tutors.firstWhere(
      (t) => t.id == data.selectedTutorId,
      orElse: () => TutorPersona.tutors.first,
    );

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Animated Success Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Completion Title
            Text(
              l10n.completionTitle,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Completion Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.completionSubtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Summary Chip of Tutor & Target Language
            if (data.targetLanguage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.targetLanguage!.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      data.targetLanguage!.localizedName(l10n),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      tutor.id == 'abbas' ? '👨‍🏫' : '👩‍🏫',
                      style: const TextStyle(fontSize: 18),
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
              ),

            const Spacer(),

            // CTA Button to Go to Home / Teacher Home
            PrimaryButton(
              label: l10n.letsStart,
              onPressed: () {
                if (data.isSchoolTeacher) {
                  context.go(AppRoutes.teacherHome);
                } else if (data.isSchoolStudent) {
                  context.go(AppRoutes.studentHome);
                } else {
                  // The tutor is the first learning experience for individual
                  // learners; Home remains available from the tutor app bar.
                  context.go(AppRoutes.tutor);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
