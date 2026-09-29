import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/models/cefr_level.dart';
import '../providers/placement_provider.dart';

/// Step 9: Placement Assessment Results Screen
class PlacementResultStep extends ConsumerWidget {
  const PlacementResultStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final placementState = ref.watch(placementNotifierProvider);
    final result = placementState.result;

    final cefr = result?.estimatedCefrLevel ?? CefrLevel.a1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Title
          Text(
            l10n.placementResultTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.placementResultSubtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Estimated CEFR Level Hero Card
          Container(
            padding: AppSpacing.paddingXl,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusXl,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  cefr.code,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  cefr.localizedTitle(l10n),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.placementResultDisclaimer,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Skill Scores Breakdown
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkillMeter(
                  label: l10n.placementSkillComprehension,
                  score: result?.comprehensionScore ?? 75,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSkillMeter(
                  label: l10n.placementSkillVocabulary,
                  score: result?.vocabularyScore ?? 65,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSkillMeter(
                  label: l10n.placementSkillGrammar,
                  score: result?.grammarScore ?? 70,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSkillMeter(
                  label: l10n.placementSkillCommunication,
                  score: result?.fluencyScore ?? 60,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Pronunciation Notice (Strictly no fake score)
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.surfaceLightVariant,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.pronunciationNotice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Strengths & Focus Areas
          if (result != null && result.strengths.isNotEmpty) ...[
            _buildHighlightsCard(
              title: l10n.strengthsTitle,
              icon: Icons.star_rounded,
              iconColor: AppColors.accent,
              items: result.strengths,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (result != null && result.recommendedFocusAreas.isNotEmpty) ...[
            _buildHighlightsCard(
              title: l10n.weaknessesTitle,
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.primary,
              items: result.recommendedFocusAreas,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // CTA to Completion
          PrimaryButton(
            label: l10n.continueJourney,
            onPressed: () {
              ref.read(onboardingProvider.notifier).nextStep();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSkillMeter({required String label, required int score}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              '$score%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusFull,
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLightVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
