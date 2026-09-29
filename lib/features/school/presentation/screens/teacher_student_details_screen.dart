import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../domain/models/classroom_models.dart';
import '../providers/school_providers.dart';

/// Detailed Student Educational Progress Screen for teachers.
class TeacherStudentDetailsScreen extends ConsumerWidget {
  final String studentId;
  final String classId;

  const TeacherStudentDetailsScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final params = StudentQueryParams(studentId: studentId, classId: classId);

    final overviewAsync = ref.watch(teacherStudentOverviewProvider(params));
    final skillsAsync = ref.watch(teacherStudentSkillsProvider(params));
    final activitiesAsync = ref.watch(teacherStudentActivitiesProvider(params));
    final attentionAsync = ref.watch(teacherStudentAttentionProvider(params));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: overviewAsync.when(
          data:
              (overview) => Text(
                overview?.visibleName ?? l10n.studentProgressTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
          loading: () => Text(l10n.studentProgressTitle),
          error: (_, __) => Text(l10n.studentProgressTitle),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherStudentOverviewProvider(params));
            ref.invalidate(teacherStudentSkillsProvider(params));
            ref.invalidate(teacherStudentActivitiesProvider(params));
            ref.invalidate(teacherStudentAttentionProvider(params));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Student Header Card
                overviewAsync.when(
                  data: (overview) {
                    if (overview == null) {
                      return _buildNotFoundCard(context);
                    }
                    return _buildHeaderCard(context, overview);
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

                // 2. Learning Overview Cards
                Text(
                  l10n.learningOverviewTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                overviewAsync.when(
                  data: (overview) {
                    if (overview == null) return const SizedBox.shrink();
                    return _buildLearningMetrics(context, overview);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 3. Skill Progress Section
                Text(
                  l10n.skillProgressTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                skillsAsync.when(
                  data: (skills) {
                    if (skills.isEmpty) {
                      return _buildEmptySectionCard(
                        context,
                        l10n.notEnoughDataYet,
                      );
                    }
                    return Column(
                      children:
                          skills
                              .map((skill) => _buildSkillRow(context, skill))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (_, __) => _buildEmptySectionCard(
                        context,
                        l10n.notEnoughDataYet,
                      ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 4. Needs Attention Section
                Text(
                  l10n.needsAttentionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                attentionAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return _buildPositiveAttentionCard(context);
                    }
                    return Column(
                      children:
                          items
                              .map((item) => _buildWarningCard(context, item))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 5. Recent Activity Section
                Text(
                  l10n.recentActivityTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return _buildEmptySectionCard(
                        context,
                        l10n.notEnoughDataYet,
                      );
                    }
                    return Column(
                      children:
                          activities
                              .map((act) => _buildActivityItem(context, act))
                              .toList(),
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (_, __) => _buildEmptySectionCard(
                        context,
                        l10n.notEnoughDataYet,
                      ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    StudentLearningOverview overview,
  ) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎒', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.visibleName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    overview.cefrLevel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningMetrics(
    BuildContext context,
    StudentLearningOverview overview,
  ) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: l10n.lessonsCompletedLabel,
                value: '${overview.lessonsCompletedCount}',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: l10n.vocabularyMasteredLabel,
                value: '${overview.vocabularyMasteredCount}',
                icon: Icons.menu_book_rounded,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: l10n.examsCompletedLabel,
                value: '${overview.examsCompletedCount}',
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: l10n.totalMinutesLearnedLabel,
                value: '${overview.totalLearningMinutes}',
                icon: Icons.timer_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(BuildContext context, StudentSkillSummary skill) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final skillName =
        isArabic ? skill.skill.nameArabic : skill.skill.nameEnglish;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(skill.skill.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    skillName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          skill.hasSufficientEvidence
                              ? AppColors.primaryContainer
                              : AppColors.surfaceLightVariant,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Text(
                      skill.hasSufficientEvidence
                          ? l10n.evidenceSufficientBadge
                          : l10n.evidenceInsufficientBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            skill.hasSufficientEvidence
                                ? AppColors.primaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${skill.score}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusFull,
            child: LinearProgressIndicator(
              value: skill.score / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLightVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                skill.score >= 80
                    ? AppColors.success
                    : (skill.score >= 60
                        ? AppColors.primary
                        : AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositiveAttentionCard(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.noAttentionNeeded,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, String warningText) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              warningText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    StudentActivitySummary activity,
  ) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'lesson':
        icon = Icons.menu_book_rounded;
        color = AppColors.primary;
        break;
      case 'vocabulary':
        icon = Icons.style_rounded;
        color = AppColors.accent;
        break;
      case 'exam':
        icon = Icons.assignment_turned_in_rounded;
        color = AppColors.success;
        break;
      case 'tutor':
      default:
        icon = Icons.record_voice_over_rounded;
        color = const Color(0xFF6366F1);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.details,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard(BuildContext context, String message) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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
