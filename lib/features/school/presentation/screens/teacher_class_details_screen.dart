import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/classroom_models.dart';
import '../providers/school_providers.dart';

/// Classroom Details Screen displaying student rosters, individual learning milestones, and activity.
class TeacherClassDetailsScreen extends ConsumerWidget {
  final String classId;

  const TeacherClassDetailsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final classDetailsAsync = ref.watch(teacherClassDetailsProvider(classId));
    final studentsAsync = ref.watch(teacherClassStudentsProvider(classId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: classDetailsAsync.when(
          data:
              (classroom) => Text(
                classroom?.name ?? l10n.classStudentsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
          loading: () => Text(l10n.classStudentsTitle),
          error: (_, __) => Text(l10n.classStudentsTitle),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherClassDetailsProvider(classId));
            ref.invalidate(teacherClassStudentsProvider(classId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Class Overview Header Card
                classDetailsAsync.when(
                  data: (classroom) {
                    if (classroom == null) {
                      return _buildNotFoundCard(context);
                    }
                    return _buildClassHeaderCard(context, classroom);
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error: (_, __) => _buildNotFoundCard(context),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Section Title: Class Students
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.classStudentsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Students List or Empty State
                studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return _buildEmptyStudentsCard(context);
                    }
                    return Column(
                      children:
                          students
                              .map((s) => _buildStudentCard(context, s))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (_, __) => Center(
                        child: Text(
                          l10n.notEnoughDataYet,
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassHeaderCard(BuildContext context, Classroom classroom) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: const Center(
                  child: Text('🏫', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${classroom.grade} • ${classroom.section}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    TeacherStudentSummary student,
  ) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: () {
            context.push(
              '/teacher/students/${student.studentId}?classId=$classId',
            );
          },
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        student.avatarEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.visibleName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLightVariant,
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Text(
                                  student.cefrLevel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Text(
                                '• 🔥 ${student.streakDays}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                '• ⚡ ${student.totalXp} XP',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textTertiaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Today's Status & Overall Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student.completedTasksToday
                            ? l10n.tasksCompletedStatus
                            : l10n.tasksPendingStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              student.completedTasksToday
                                  ? AppColors.success
                                  : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      student.hasSufficientData
                          ? '${student.overallProgressPercentage.toInt()}%'
                          : l10n.notEnoughDataYet,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (student.hasSufficientData) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusFull,
                    child: LinearProgressIndicator(
                      value: student.overallProgressPercentage / 100.0,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLightVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStudentsCard(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🎒', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noStudentsInClass,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundCard(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Center(
        child: Text(
          l10n.notEnoughDataYet,
          style: const TextStyle(color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}
