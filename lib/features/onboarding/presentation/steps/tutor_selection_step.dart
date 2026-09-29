import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/tutor_persona.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/tutor_card.dart';

/// Step 7: AI Tutor Persona Selection
class TutorSelectionStep extends ConsumerWidget {
  const TutorSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedTutorId = ref.watch(
      onboardingProvider.select((s) => s.data.selectedTutorId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tutorSelectionTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.tutorSelectionSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView.separated(
            itemCount: TutorPersona.tutors.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final tutor = TutorPersona.tutors[index];
              final isSelected = selectedTutorId == tutor.id;

              return TutorCard(
                tutor: tutor,
                isSelected: isSelected,
                onSelect: () {
                  ref.read(onboardingProvider.notifier).selectTutor(tutor.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
