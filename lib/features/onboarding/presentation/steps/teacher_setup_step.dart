import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/onboarding_provider.dart';

/// Step: School Teacher Subject & Grades Setup
class TeacherSetupStep extends ConsumerStatefulWidget {
  const TeacherSetupStep({super.key});

  @override
  ConsumerState<TeacherSetupStep> createState() => _TeacherSetupStepState();
}

class _TeacherSetupStepState extends ConsumerState<TeacherSetupStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _gradesController;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider).data;
    _nameController = TextEditingController(text: data.registeredName ?? '');
    _subjectController = TextEditingController(text: data.teacherSubject ?? '');
    _gradesController = TextEditingController(
      text: data.teacherGradesTaught?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _gradesController.dispose();
    super.dispose();
  }

  void _updateValues() {
    final rawGrades =
        _gradesController.text
            .split(',')
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty)
            .toList();

    ref
        .read(onboardingProvider.notifier)
        .setTeacherDetails(
          fullName: _nameController.text.trim(),
          subject: _subjectController.text.trim(),
          gradesTaught: rawGrades,
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
            l10n.teacherSetupTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.teacherSetupSubtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Teacher Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.fullName,
              hintText: 'أحمد محمود / Ahmad Mahmoud',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            onChanged: (_) => _updateValues(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Subject Taught
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: l10n.teacherSubjectLabel,
              hintText: l10n.teacherSubjectHint,
              prefixIcon: const Icon(Icons.menu_book_rounded),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            onChanged: (_) => _updateValues(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Grades Taught
          TextFormField(
            controller: _gradesController,
            decoration: InputDecoration(
              labelText: l10n.teacherGradesLabel,
              hintText: l10n.teacherGradesHint,
              prefixIcon: const Icon(Icons.grade_rounded),
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
