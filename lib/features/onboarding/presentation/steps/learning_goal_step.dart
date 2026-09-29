import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/learning_goal.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step 4: Learning Goal Selection
class LearningGoalStep extends ConsumerWidget {
  const LearningGoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedGoal = ref.watch(
      onboardingProvider.select((s) => s.data.learningGoal),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.learningGoalTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.learningGoalSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView.separated(
            itemCount: LearningGoal.goals.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final goal = LearningGoal.goals[index];
              final isSelected = selectedGoal?.id == goal.id;

              return SelectableOptionCard(
                title: goal.localizedTitle(l10n),
                subtitle: goal.localizedDescription(l10n),
                leading: Text(goal.icon, style: const TextStyle(fontSize: 26)),
                isSelected: isSelected,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectLearningGoal(goal);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
