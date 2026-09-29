import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/models/daily_task.dart';
import '../providers/student_providers.dart';

/// Production-ready School Student Learning Home Screen for Lahjti.
/// Clearly separated from teacher dashboard, personalized for school learners,
/// with age adaptation for children 6-10 and older students.
class StudentSchoolHomeScreen extends ConsumerWidget {
  const StudentSchoolHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    final studentProfile = ref.watch(currentSchoolStudentProfileProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isChild = ref.watch(isChildModeProvider);

    final learningProfile = ref.watch(learningProfileProvider);
    final learnerProgress = ref.watch(learnerProgressProvider);
    final dailyPlan = ref.watch(studentDailyPlanProvider);
    final tasksAsync = ref.watch(studentDailyTasksProvider);

    final effectiveTasks = tasksAsync.value ?? dailyPlan.tasks;
    final effectiveProgress = DailyTaskProgress.fromTasks(effectiveTasks);
    final effectiveRecommendedTask = effectiveTasks.firstWhere(
      (t) => !t.completed,
      orElse:
          () =>
              effectiveTasks.isNotEmpty
                  ? effectiveTasks.first
                  : dailyPlan.recommendedTask,
    );

    final defaultName = isArabic ? 'سامي' : 'Sami';
    final studentName =
        studentProfile?.fullName.split(' ').first ??
        onboardingData.registeredName?.split(' ').first ??
        defaultName;
    final schoolName =
        studentProfile?.schoolName ??
        onboardingData.schoolName ??
        (isArabic ? 'مدرسة النور الأهلية' : 'Al-Noor School');
    final gradeSection =
        (studentProfile != null)
            ? '${studentProfile.grade} - ${studentProfile.classSection}'
            : (onboardingData.schoolGrade != null)
            ? '${onboardingData.schoolGrade} - ${onboardingData.schoolClassSection ?? (isArabic ? "أ" : "A")}'
            : (isArabic ? 'الصف السادس - أ' : 'Grade 6 - A');

    return Scaffold(
      backgroundColor:
          isChild ? const Color(0xFFF4F9F9) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isChild ? const Color(0xFFE6F4F1) : AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          l10n.studentSchoolHomeTitle,
          style: TextStyle(
            fontSize: isChild ? 20 : 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          // Language Switcher
          IconButton(
            icon: const Icon(Icons.language_rounded, color: AppColors.primary),
            tooltip: isArabic ? 'English' : 'العربية',
            onPressed: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
          ),
          // School Access / Subscription
          IconButton(
            key: const Key('student_subscription_appbar_btn'),
            icon: const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
            tooltip: l10n.subscriptionTitle,
            onPressed: () => context.push(AppRoutes.subscription),
          ),
          // Profile & Student Info
          IconButton(
            key: const Key('student_profile_appbar_btn'),
            icon: const Icon(
              Icons.person_rounded,
              color: AppColors.textPrimaryLight,
            ),
            tooltip: l10n.accountProfileTitle,
            onPressed: () => context.push(AppRoutes.profile),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(studentDailyTasksProvider);
              ref.invalidate(studentProgressSummaryProvider);
            },
          ),
          // Logout / Switch Role
          IconButton(
            key: const Key('student_logout_appbar_btn'),
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondaryLight,
            ),
            tooltip: isArabic ? 'تسجيل الخروج' : 'Logout',
            onPressed: () => context.go(AppRoutes.welcome),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentDailyTasksProvider);
            ref.invalidate(studentProgressSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Personalized Header
                _buildHeader(
                  context,
                  studentName: studentName,
                  schoolName: schoolName,
                  gradeSection: gradeSection,
                  cefrLevel: learningProfile.estimatedCefrLevel.code,
                  totalXp: learnerProgress.totalXp,
                  streakDays: learnerProgress.streakData.currentStreak,
                  isChild: isChild,
                  isArabic: isArabic,
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Child Mode Fun Banner (if applicable)
                if (isChild) ...[
                  _buildChildBanner(context, isArabic),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 3. Primary Hero Card: "Continue Learning"
                _buildContinueLearningHero(
                  context,
                  recommendedTask: effectiveRecommendedTask,
                  isChild: isChild,
                  isArabic: isArabic,
                ),

                const SizedBox(height: AppSpacing.md),

                // 4. Vocabulary Spaced Review Card (When words are due)
                if (dailyPlan.dueVocabularyCount > 0) ...[
                  _buildVocabReviewCard(
                    context,
                    dueCount: dailyPlan.dueVocabularyCount,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 5. Daily Tasks List Section
                _buildDailyTasksSection(
                  context,
                  ref: ref,
                  tasks: effectiveTasks,
                  progress: effectiveProgress,
                  isChild: isChild,
                  isArabic: isArabic,
                ),

                const SizedBox(height: AppSpacing.md),

                // 6. Current Lesson Progression Card
                _buildCurrentLessonCard(
                  context,
                  lessonId: learningProfile.currentLessonId,
                  isArabic: isArabic,
                ),

                const SizedBox(height: AppSpacing.md),

                // 7. Quick Action Hub Section (Games, Progress, AI Assistant)
                _buildQuickHubSection(
                  context,
                  isChild: isChild,
                  isArabic: isArabic,
                ),

                const SizedBox(height: AppSpacing.md),

                // 8. Recent Achievements Section
                ref
                    .watch(studentAchievementsProvider)
                    .when(
                      data:
                          (achievements) => _buildAchievementsCard(
                            context,
                            achievements: achievements,
                            isChild: isChild,
                            isArabic: isArabic,
                          ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                const SizedBox(height: AppSpacing.md),

                // 9. Privacy & Safe AI Assistant Notice
                _buildSafeAiNotice(context, l10n.safeAiNotice),

                const SizedBox(height: AppSpacing.lg),

                // 10. Developer Attribution Footer
                _buildAttributionFooter(l10n.developerCredit),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String studentName,
    required String schoolName,
    required String gradeSection,
    required String cefrLevel,
    required int totalXp,
    required int streakDays,
    required bool isChild,
    required bool isArabic,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:
            isChild ? BorderRadius.circular(20) : AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isChild ? const Color(0xFFBBE5DE) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isChild
                        ? const Color(0xFFFFE082)
                        : AppColors.primaryContainer,
                child: Text(
                  isChild ? '🎒' : '👨‍🎓',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studentGreeting(studentName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$schoolName • $gradeSection',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // CEFR Level Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  cefrLevel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildHeaderPill(
                  '⚡ $totalXp XP',
                  isArabic ? 'مجموع النقاط' : 'Total XP',
                ),
              ),
              Expanded(
                child: _buildHeaderPill(
                  '🔥 $streakDays ${isArabic ? "أيام" : "days"}',
                  isArabic ? 'أيام الاستمرار' : 'Streak',
                ),
              ),
              Expanded(
                child: _buildHeaderPill(
                  '🏫 ${isArabic ? "طالب مدرسي" : "School Student"}',
                  isArabic ? 'الحساب' : 'Account',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChildBanner(BuildContext context, bool isArabic) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Text('🎈', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.childModeBanner,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueLearningHero(
    BuildContext context, {
    required DailyTask recommendedTask,
    required bool isChild,
    required bool isArabic,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            isChild
                ? const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.todayTaskMission,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${recommendedTask.xpReward} XP ⭐',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.todayTaskMissionSub(3, 50),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? (isChild
                    ? 'مغامرة اليوم: استكشف واكسب النجوم 🌟'
                    : 'خطوتك التالية في التعلم 🎯')
                : (isChild
                    ? 'Today\'s Quest: Explore & Learn 🌟'
                    : 'Your Next Learning Step 🎯'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendedTask.localizedDescription(isArabic),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '⏱️ ${recommendedTask.estimatedMinutes} ${isArabic ? "دقائق" : "mins"}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('student_home_continue_cta_btn'),
                onPressed: () {
                  if (recommendedTask.lessonId != null) {
                    context.push(
                      '${AppRoutes.learning}?lessonId=${recommendedTask.lessonId}',
                    );
                  } else {
                    context.push(recommendedTask.actionRoute);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  isArabic ? 'متابعة التعلم' : 'Continue Learning',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabReviewCard(
    BuildContext context, {
    required int dueCount,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'مراجعة المفردات المستحقة'
                      : 'Due Vocabulary Review',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  isArabic
                      ? '$dueCount كلمات تحتاج لتكرار متباعد'
                      : '$dueCount words due for spaced repetition',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.vocabularyPractice),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isArabic ? 'راجع الآن' : 'Review',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasksSection(
    BuildContext context, {
    required WidgetRef ref,
    required List<DailyTask> tasks,
    required DailyTaskProgress progress,
    required bool isChild,
    required bool isArabic,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayTasksTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.whatToDoToday,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic
                      ? '${progress.completedTasks} من ${progress.totalTasks} مكتمل'
                      : '${progress.completedTasks} of ${progress.totalTasks} done',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.completionPercentage / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...tasks.map(
            (task) => _buildTaskItem(
              context,
              ref: ref,
              task: task,
              isArabic: isArabic,
              isChild: isChild,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context, {
    required WidgetRef ref,
    required DailyTask task,
    required bool isArabic,
    required bool isChild,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            task.completed ? const Color(0xFFF8FAFC) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              task.completed ? const Color(0xFFE2E8F0) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Text(task.type.iconEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.localizedTitle(isArabic),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        task.completed
                            ? AppColors.textSecondaryLight
                            : AppColors.textPrimaryLight,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '⏱️ ${task.estimatedMinutes} ${isArabic ? "دقائق" : "mins"} • +${task.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (task.completed)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            )
          else
            OutlinedButton(
              onPressed: () {
                if (task.lessonId != null) {
                  context.push(
                    '${AppRoutes.learning}?lessonId=${task.lessonId}',
                  );
                } else {
                  context.push(task.actionRoute);
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                isArabic ? 'ابدأ' : 'Start',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentLessonCard(
    BuildContext context, {
    required String lessonId,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Text('📖', style: TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'الدرس الحالي في المنهج'
                      : 'Current Curriculum Lesson',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  isArabic
                      ? 'الوحدة الأولى: في المقهى والمطعم'
                      : 'Unit 1: At the Cafe & Restaurant',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed:
                () => context.push('${AppRoutes.learning}?lessonId=$lessonId'),
            child: Text(
              isArabic ? 'عرض' : 'View',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHubSection(
    BuildContext context, {
    required bool isChild,
    required bool isArabic,
  }) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHubCard(
                context,
                emoji: '📚',
                title: l10n.continueLesson,
                subtitle: isArabic ? 'متابعة المنهج' : 'Next Lesson',
                color: const Color(0xFF3B82F6),
                route: AppRoutes.learning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildHubCard(
                context,
                emoji: '🗂️',
                title: l10n.vocabularyReview,
                subtitle: isArabic ? 'تكرار متباعد' : 'Spaced Repetition',
                color: const Color(0xFF8B5CF6),
                route: AppRoutes.vocabularyPractice,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildHubCard(
                context,
                emoji: '🎮',
                title: l10n.educationalGames,
                subtitle: isArabic ? '5 ألعاب تفاعلية' : '5 Mini-Games',
                color: const Color(0xFF6366F1),
                route: AppRoutes.studentGames,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildHubCard(
                context,
                emoji: '🤖',
                title: l10n.talkToTutors,
                subtitle: isArabic ? 'محادثة آمنة' : 'Safe Dialogue',
                color: const Color(0xFFF59E0B),
                route: AppRoutes.tutorConversation,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildProgressHubBanner(context, isArabic),
      ],
    );
  }

  Widget _buildProgressHubBanner(BuildContext context, bool isArabic) {
    return InkWell(
      onTap: () => context.push(AppRoutes.studentProgress),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'لوحة التقدم' : 'Progress Hub',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    isArabic
                        ? 'عرض تفاصيل المستوى، المفردات المتقنة والأوسمة'
                        : 'View level details, mastered words & earned badges',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
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
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(
    BuildContext context, {
    required List<String> achievements,
    required bool isChild,
    required bool isArabic,
  }) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'الإنجازات المكتسبة مؤخراً 🏆'
                : 'Recent Achievements 🏆',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                achievements.map((ach) {
                  return Chip(
                    avatar: const Text('⭐', style: TextStyle(fontSize: 14)),
                    label: Text(
                      ach,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: const Color(0xFFFEF3C7),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeAiNotice(BuildContext context, String noticeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              noticeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionFooter(String creditText) {
    return Center(
      child: Column(
        children: [
          Text(
            creditText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            'mohammadabuabbas.my',
            style: TextStyle(fontSize: 10, color: AppColors.textTertiaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
