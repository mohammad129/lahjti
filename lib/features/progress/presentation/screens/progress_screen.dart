import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../domain/models/achievement_models.dart';
import '../../domain/models/progress_summary_models.dart';
import '../../domain/models/streak_models.dart';
import '../../domain/models/xp_models.dart';
import '../providers/progress_providers.dart';

/// Comprehensive, age-adaptive, and gamified progress dashboard.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uiConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final profile = ref.watch(learningProfileProvider);
    final progress = ref.watch(learnerProgressProvider);
    final currentLevel = ref.watch(learnerLevelProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final streak = ref.watch(streakDataProvider);
    final achievements = ref.watch(achievementsListProvider);
    final skillsMap = ref.watch(skillsProgressProvider);
    final weeklySummaryAsync = ref.watch(weeklyProgressSummaryProvider);
    final recommendation = ref.watch(dailyRecommendationProvider);

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.progressTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimaryLight,
                  ),
                  onPressed: () => context.pop(),
                )
                : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: uiConfig.cardPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Profile & Level Banner
              _buildLevelHeaderCard(
                context,
                profileName: 'المتعلم',
                cefrCode: profile.estimatedCefrLevel.code,
                currentLevel: currentLevel,
                totalXp: progress.totalXp,
                isArabic: isArabic,
                uiConfig: uiConfig,
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. Key Metrics Row (Streak, Total XP, Longest Streak, Active Days)
              _buildMetricsCapsules(
                context,
                streak: streak,
                totalXp: progress.totalXp,
                l10n: l10n,
                isArabic: isArabic,
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Today's Learning Goal Card
              _buildDailyGoalCard(
                context,
                goal: dailyGoal,
                l10n: l10n,
                onStartRecommended: () {
                  if (recommendation.type.name.contains('vocabulary')) {
                    context.push(AppRoutes.vocabulary);
                  } else if (recommendation.type.name.contains('exam')) {
                    context.push(AppRoutes.exams);
                  } else {
                    context.push(AppRoutes.tutorConversation);
                  }
                },
                uiConfig: uiConfig,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 4. Skills Breakdown (6 Skills)
              _buildSkillsSection(
                context,
                skillsMap: skillsMap,
                l10n: l10n,
                isArabic: isArabic,
                uiConfig: uiConfig,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 5. 3-Month Learning Roadmap
              _buildRoadmapSection(
                context,
                completedLessons: progress.completedLessonIds.length,
                l10n: l10n,
                uiConfig: uiConfig,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 6. Weekly Summary Strip
              weeklySummaryAsync.when(
                data:
                    (weekly) => _buildWeeklySummaryCard(
                      context,
                      summary: weekly,
                      l10n: l10n,
                      isArabic: isArabic,
                      uiConfig: uiConfig,
                    ),
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 7. Achievements & Badges Catalog
              _buildAchievementsSection(
                context,
                achievements: achievements,
                l10n: l10n,
                isArabic: isArabic,
                uiConfig: uiConfig,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelHeaderCard(
    BuildContext context, {
    required String profileName,
    required String cefrCode,
    required LearnerLevel currentLevel,
    required int totalXp,
    required bool isArabic,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    final levelTitle =
        isArabic ? currentLevel.titleArabic : currentLevel.titleEnglish;
    final progressRatio = currentLevel.progressRatio(totalXp);

    return Container(
      padding: EdgeInsets.all(uiConfig.cardPadding),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(uiConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎓', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'المستوى ${currentLevel.level}'
                                : 'Level ${currentLevel.level}',
                            style: TextStyle(
                              fontSize: 12 * uiConfig.textScaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          Text(
                            levelTitle,
                            style: TextStyle(
                              fontSize: 16 * uiConfig.textScaleFactor,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // CEFR Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cefrCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // XP Progress in Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalXp XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${currentLevel.maxXp} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCapsules(
    BuildContext context, {
    required StreakData streak,
    required int totalXp,
    required dynamic l10n,
    required bool isArabic,
  }) {
    return Row(
      children: [
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? '${streak.currentStreak} أيام'
                            : '${streak.currentStreak} Days',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        l10n.currentStreak,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Total XP Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalXp XP',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        l10n.totalXp,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard(
    BuildContext context, {
    required DailyLearningGoal goal,
    required dynamic l10n,
    required VoidCallback onStartRecommended,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    return Container(
      padding: EdgeInsets.all(uiConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(uiConfig.borderRadius),
        border: Border.all(
          color:
              goal.isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (goal.isCompleted
                                ? AppColors.success
                                : AppColors.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        goal.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.flag_rounded,
                        color:
                            goal.isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.dailyGoal,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16 * uiConfig.textScaleFactor,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLightVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${goal.earnedXp} / ${goal.targetXp} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            goal.isCompleted
                ? l10n.dailyGoalMet
                : l10n.dailyGoalRemaining(goal.remainingXp),
            style: TextStyle(
              fontSize: 13 * uiConfig.textScaleFactor,
              fontWeight: FontWeight.w600,
              color:
                  goal.isCompleted
                      ? AppColors.success
                      : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: uiConfig.minTouchTargetHeight,
            child: ElevatedButton.icon(
              onPressed: onStartRecommended,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                l10n.startRecommendedAction,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
    BuildContext context, {
    required Map<LearningSkill, dynamic> skillsMap,
    required dynamic l10n,
    required bool isArabic,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    final allSkills = LearningSkill.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.skillsBreakdown,
          style: TextStyle(
            fontSize: 17 * uiConfig.textScaleFactor,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(uiConfig.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(uiConfig.borderRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children:
                allSkills.map((skill) {
                  final progress = skillsMap[skill];
                  final score = progress?.levelScore ?? 45;
                  final hasEvidence = progress?.hasSufficientEvidence ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getSkillEmoji(skill),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic ? skill.nameArabic : skill.nameEnglish,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (hasEvidence)
                              Text(
                                '$score%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLightVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.insufficientEvidence,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                hasEvidence
                                    ? (score / 100).clamp(0.0, 1.0)
                                    : 0.35,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              hasEvidence
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapSection(
    BuildContext context, {
    required int completedLessons,
    required dynamic l10n,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.learningRoadmap,
          style: TextStyle(
            fontSize: 17 * uiConfig.textScaleFactor,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(uiConfig.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(uiConfig.borderRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildRoadmapMonthRow(
                monthNumber: 1,
                title: l10n.month1Title,
                subtitle: '$completedLessons دروس مكتملة',
                isCurrent: true,
                isCompleted: completedLessons >= 10,
                progress: (completedLessons / 10).clamp(0.1, 1.0),
              ),
              const Divider(height: 24),
              _buildRoadmapMonthRow(
                monthNumber: 2,
                title: l10n.month2Title,
                subtitle: 'مواقف الحياة اليومية والحوارات',
                isCurrent: false,
                isCompleted: false,
                progress: 0.0,
              ),
              const Divider(height: 24),
              _buildRoadmapMonthRow(
                monthNumber: 3,
                title: l10n.month3Title,
                subtitle: 'الطلاقة والمناقشات المتقدمة',
                isCurrent: false,
                isCompleted: false,
                progress: 0.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapMonthRow({
    required int monthNumber,
    required String title,
    required String subtitle,
    required bool isCurrent,
    required bool isCompleted,
    required double progress,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? AppColors.successContainer
                    : (isCurrent
                        ? AppColors.primaryContainer
                        : AppColors.surfaceLightVariant),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isCompleted
                  ? Icons.check_rounded
                  : (isCurrent
                      ? Icons.play_arrow_rounded
                      : Icons.lock_outline_rounded),
              color:
                  isCompleted
                      ? AppColors.success
                      : (isCurrent ? AppColors.primary : Colors.grey.shade400),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(
    BuildContext context, {
    required WeeklyProgressSummary summary,
    required dynamic l10n,
    required bool isArabic,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    final days =
        isArabic
            ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
            : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklySummary,
          style: TextStyle(
            fontSize: 17 * uiConfig.textScaleFactor,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(uiConfig.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(uiConfig.borderRadius),
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
                      l10n.activeDaysThisWeek(summary.activeDaysCount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+${summary.totalXpEarned} XP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isActive = summary.activeDaysMap[dayIndex] ?? false;

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? AppColors.primary
                                    : AppColors.surfaceLightVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              isActive
                                  ? Icons.local_fire_department_rounded
                                  : Icons.circle_outlined,
                              color:
                                  isActive
                                      ? Colors.white
                                      : Colors.grey.shade400,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context, {
    required List<Achievement> achievements,
    required dynamic l10n,
    required bool isArabic,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.achievementsTitle,
                style: TextStyle(
                  fontSize: 17 * uiConfig.textScaleFactor,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.unlockedAchievements(unlockedCount, achievements.length),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final item = achievements[index];
            return _buildAchievementCard(
              context,
              achievement: item,
              isArabic: isArabic,
              l10n: l10n,
              uiConfig: uiConfig,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required Achievement achievement,
    required bool isArabic,
    required dynamic l10n,
    required AgeAdaptiveUiConfig uiConfig,
  }) {
    final title = isArabic ? achievement.titleArabic : achievement.titleEnglish;
    final description =
        isArabic
            ? achievement.descriptionArabic
            : achievement.descriptionEnglish;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder:
              (ctx) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievement.iconEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (achievement.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🏆 ${l10n.unlockedOn(achievement.unlockedAt?.toString().substring(0, 10) ?? '')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Text(
                            '${achievement.currentValue} / ${achievement.targetValue}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievement.progressRatio,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
        );
      },
      borderRadius: BorderRadius.circular(uiConfig.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              achievement.isUnlocked
                  ? AppColors.surfaceLight
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(uiConfig.borderRadius),
          border: Border.all(
            color:
                achievement.isUnlocked
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.iconEmoji,
              style: TextStyle(
                fontSize: 28,
                color: achievement.isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    achievement.isUnlocked
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            if (achievement.isUnlocked)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 16,
              )
            else
              Text(
                '${achievement.currentValue}/${achievement.targetValue}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSkillEmoji(LearningSkill skill) {
    switch (skill) {
      case LearningSkill.speaking:
        return '🎙️';
      case LearningSkill.listening:
        return '🎧';
      case LearningSkill.reading:
        return '📖';
      case LearningSkill.vocabulary:
        return '📚';
      case LearningSkill.grammar:
        return '📐';
      case LearningSkill.pronunciation:
        return '🗣️';
      case LearningSkill.fluency:
        return '⚡';
      case LearningSkill.comprehension:
        return '💬';
    }
  }
}
