import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../school/domain/models/school_role.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step: School Role Selection (Student vs Teacher)
class SchoolRoleStep extends ConsumerWidget {
  const SchoolRoleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedRole = ref.watch(
      onboardingProvider.select((s) => s.data.schoolRole),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolRoleTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.schoolRoleSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView(
            children: [
              SelectableOptionCard(
                title: l10n.roleStudent,
                subtitle: l10n.roleStudentDesc,
                leading: const Text('🎒', style: TextStyle(fontSize: 28)),
                isSelected: selectedRole == SchoolRole.student,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectSchoolRole(SchoolRole.student);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableOptionCard(
                title: l10n.roleTeacher,
                subtitle: l10n.roleTeacherDesc,
                leading: const Text('👩‍🏫', style: TextStyle(fontSize: 28)),
                isSelected: selectedRole == SchoolRole.teacher,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectSchoolRole(SchoolRole.teacher);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
