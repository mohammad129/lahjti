import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/experience_level.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step 5: Experience Level Self-Assessment
class ExperienceLevelStep extends ConsumerWidget {
  const ExperienceLevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedLevel = ref.watch(
      onboardingProvider.select((s) => s.data.experienceLevel),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.experienceTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.experienceSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView.separated(
            itemCount: ExperienceLevel.values.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final level = ExperienceLevel.values[index];
              final isSelected = selectedLevel == level;

              return SelectableOptionCard(
                title: level.localizedTitle(l10n),
                subtitle: level.localizedDescription(l10n),
                isSelected: isSelected,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectExperienceLevel(level);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
