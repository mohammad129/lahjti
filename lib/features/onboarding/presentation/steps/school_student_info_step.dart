import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/onboarding_provider.dart';

/// Step: School Student Grade & Section Information
class SchoolStudentInfoStep extends ConsumerStatefulWidget {
  const SchoolStudentInfoStep({super.key});

  @override
  ConsumerState<SchoolStudentInfoStep> createState() =>
      _SchoolStudentInfoStepState();
}

class _SchoolStudentInfoStepState extends ConsumerState<SchoolStudentInfoStep> {
  late final TextEditingController _gradeController;
  late final TextEditingController _sectionController;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider).data;
    _gradeController = TextEditingController(text: data.schoolGrade ?? '');
    _sectionController = TextEditingController(
      text: data.schoolClassSection ?? '',
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _updateValues() {
    ref
        .read(onboardingProvider.notifier)
        .setStudentClassDetails(
          grade: _gradeController.text.trim(),
          classSection: _sectionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.studentInfoTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.studentInfoSubtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Grade Input Field
          TextFormField(
            controller: _gradeController,
            decoration: InputDecoration(
              labelText: l10n.studentGradeLabel,
              hintText: l10n.studentGradeHint,
              prefixIcon: const Icon(Icons.class_rounded),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            onChanged: (_) => _updateValues(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section Input Field
          TextFormField(
            controller: _sectionController,
            decoration: InputDecoration(
              labelText: l10n.studentSectionLabel,
              hintText: l10n.studentSectionHint,
              prefixIcon: const Icon(Icons.meeting_room_rounded),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            onChanged: (_) => _updateValues(),
          ),
        ],
      ),
    );
  }
}
