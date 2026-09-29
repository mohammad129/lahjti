import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../account/presentation/providers/account_providers.dart';
import '../../../learning/domain/models/daily_learning_task.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/domain/models/lesson_models.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../school/presentation/providers/school_providers.dart';

/// Production-ready Student Daily Learning Home Dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final accountContext = ref.watch(currentAccountContextProvider);
    final studentProfile = ref.watch(currentSchoolStudentProfileProvider);

    final selectedTutorId = onboardingData.selectedTutorId ?? 'abbas';
    final tutor = TutorPersona.tutors.firstWhere(
      (t) => t.id == selectedTutorId,
      orElse: () => TutorPersona.tutors.first,
    );
    final isAbbas = tutor.id == 'abbas';

    final profile = ref.watch(learningProfileProvider);
    final progress = ref.watch(learnerProgressProvider);
    final dailyPlan = ref.watch(dailyLearningPlanProvider);
    final modulesAsync = ref.watch(curriculumModulesProvider);

    final studentName =
        onboardingData.registeredName ??
        studentProfile?.fullName ??
        (isArabic ? 'متعلم لهجتي' : 'Learner');

    final isChild = onboardingData.isChild;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          isArabic ? AppConstants.appNameAr : AppConstants.appNameEn,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: false,
        actions: [
          // Language Switcher Toggle
          IconButton(
            icon: const Icon(Icons.language_rounded, color: AppColors.primary),
            tooltip: isArabic ? 'English' : 'العربية',
            onPressed: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
          ),
          // Subscription / Access Pill
          IconButton(
            key: const Key('home_subscription_appbar_btn'),
            icon: const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
            tooltip: l10n.subscriptionTitle,
            onPressed: () => context.push(AppRoutes.subscription),
          ),
          // Profile & Settings
          IconButton(
            key: const Key('home_profile_appbar_btn'),
            icon: const Icon(
              Icons.person_rounded,
              color: AppColors.textPrimaryLight,
            ),
            tooltip: l10n.accountProfileTitle,
            onPressed: () => context.push(AppRoutes.profile),
          ),
          // Logout / Switch Mode
          IconButton(
            key: const Key('home_logout_appbar_btn'),
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
        child: CustomScrollView(
          slivers: [
            // 1. App Bar & Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: (isAbbas
                              ? AppColors.primary
                              : AppColors.secondary)
                          .withValues(alpha: 0.15),
                      child: Text(
                        isAbbas ? '👨‍🏫' : '👩‍🏫',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'مرحباً يا $studentName 👋'
                                : 'Welcome, $studentName 👋',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${isArabic ? "معلمك:" : "Tutor:"} ${tutor.localizedName(l10n)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Gamification Stats & Level Badges
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Streak Pill
                          InkWell(
                            onTap: () => context.push(AppRoutes.progress),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentContainer.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${progress.streakData.currentStreak}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // XP Pill
                          InkWell(
                            onTap: () => context.push(AppRoutes.progress),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '⚡',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${progress.totalXp}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Level Badge
                          InkWell(
                            onTap: () => context.push(AppRoutes.progress),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                profile.estimatedCefrLevel.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Child Mode Banner (when applicable)
            if (isChild)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎈', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'وضع الأطفال التفاعلي نشط: ألعاب تعليمية وتفاعل مرح!'
                                : 'Interactive Child Mode Active: Playful games & fun lessons!',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Primary Hero Card: "Continue Learning"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildContinueLearningHero(
                  context,
                  dailyPlan.recommendedTask,
                  isAbbas,
                  isArabic,
                ),
              ),
            ),

            // 3. Quick Hub Navigation Cards (Vocabulary, Games, Exams, Progress)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: _buildQuickActionCards(context, l10n, accountContext),
              ),
            ),

            // 4. Today's Daily Learning Tasks List Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'مهام اليوم التعليمية'
                                : "Today's Learning Tasks",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isArabic
                                ? '${dailyPlan.completedTasksCount} من ${dailyPlan.totalTasksCount} مكتمل'
                                : '${dailyPlan.completedTasksCount} of ${dailyPlan.totalTasksCount} done',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: dailyPlan.completionRatio,
                        minHeight: 6,
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Daily Tasks List Items
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = dailyPlan.tasks[index];
                  return _buildDailyTaskCard(context, task, isArabic);
                }, childCount: dailyPlan.tasks.length),
              ),
            ),

            // 5. Dedicated Educational Games Hub Discovery Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: _buildGamesHubBanner(context, isArabic),
              ),
            ),

            // 6. Vocabulary Spaced Review Card (When words are due)
            if (dailyPlan.dueVocabularyCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: _buildVocabReviewCard(
                    context,
                    dailyPlan.dueVocabularyCount,
                    isArabic,
                  ),
                ),
              ),
            // 7. Curriculum Modules Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'خطة التعلم — الشهر الأول'
                                : 'Learning Plan — Month 1',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic ? 'رحلة الـ 3 أشهر' : '3-Month Journey',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? '${progress.completedLessonIds.length} مكتمل'
                          : '${progress.completedLessonIds.length} completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Curriculum Modules List
            modulesAsync.when(
              data:
                  (modules) => SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final module = modules[index];
                        return _buildModuleCard(
                          context,
                          ref,
                          module,
                          progress.completedLessonIds,
                          profile.currentLessonId,
                          isArabic,
                        );
                      }, childCount: modules.length),
                    ),
                  ),
              loading:
                  () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              error:
                  (err, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Text('Error loading curriculum: $err'),
                    ),
                  ),
            ),

            // Attribution Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.developerCredit,
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
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // Direct Tutor Call Floating CTA
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_tutor_fab_btn'),
        onPressed: () => context.push(AppRoutes.tutorConversation),
        backgroundColor: isAbbas ? AppColors.primary : AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.record_voice_over_rounded),
        label: Text(
          isAbbas
              ? (isArabic ? 'تحدث مع عباس' : 'Talk with Abbas')
              : (isArabic ? 'تحدث مع دنيا' : 'Talk with Dunya'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildContinueLearningHero(
    BuildContext context,
    DailyLearningTask task,
    bool isAbbas,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            isAbbas
                ? AppColors.primaryGradient
                : const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                ),
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: (isAbbas ? AppColors.primary : AppColors.secondary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
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
                          isArabic ? 'خطوتك التالية الذكية' : 'Smart Next Step',
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
                  '+${task.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            task.localizedTitle(isArabic),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.localizedDescription(isArabic),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            key: const Key('continue_learning_hero_btn'),
            onPressed: () {
              if (task.lessonId != null) {
                context.push('${AppRoutes.learning}?lessonId=${task.lessonId}');
              } else {
                context.push(task.actionRoute);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor:
                  isAbbas ? AppColors.primary : AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'متابعة التعلم ➔' : 'Continue Learning ➔',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabReviewCard(
    BuildContext context,
    int dueCount,
    bool isArabic,
  ) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Text('🗂️', style: TextStyle(fontSize: 20)),
          ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  isArabic
                      ? '$dueCount كلمات تحتاج لتثبيت وتكرار متباعد'
                      : '$dueCount words ready for spaced review',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('home_vocab_review_btn'),
            onPressed: () => context.push(AppRoutes.vocabularyPractice),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isArabic ? 'ابدأ' : 'Start',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTaskCard(
    BuildContext context,
    DailyLearningTask task,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            task.completed ? const Color(0xFFF8FAFC) : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color:
              task.completed ? const Color(0xFFE2E8F0) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Text(task.type.iconEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.localizedTitle(isArabic),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        task.completed
                            ? AppColors.textSecondaryLight
                            : AppColors.textPrimaryLight,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '⏱️ ${task.estimatedMinutes} ${isArabic ? "دقائق" : "mins"} • +${task.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 11,
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
              size: 22,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isArabic ? 'ابدأ' : 'Start',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(
    BuildContext context,
    dynamic l10n,
    AccountContext accountContext,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.menu_book_rounded,
            label: l10n.vocabulary,
            color: AppColors.primary,
            route: AppRoutes.vocabulary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.sports_esports_rounded,
            label: l10n.educationalGames,
            color: const Color(0xFF6366F1),
            route: AppRoutes.games,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.quiz_rounded,
            label: l10n.exams,
            color: const Color(0xFF0D9488),
            route: AppRoutes.exams,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.insights_rounded,
            label: l10n.progressTitle,
            color: const Color(0xFFD97706),
            route: AppRoutes.progress,
          ),
        ),
      ],
    );
  }

  Widget _buildGamesHubBanner(BuildContext context, bool isArabic) {
    return InkWell(
      key: const Key('home_games_hub_banner_btn'),
      onTap: () => context.push(AppRoutes.games),
      borderRadius: AppSpacing.borderRadiusLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎮', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'الألعاب التعليمية التفاعلية 🕹️'
                        : 'Interactive Educational Games 🕹️',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? '5 ألعاب مسلية لتثبيت المفردات وبناء الجمل والمطابقة'
                        : '5 fun mini-games: Word Match, Vocab, & Sentences',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    WidgetRef ref,
    CurriculumModule module,
    List<String> completedIds,
    String activeLessonId,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: module.order == 1,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLightVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(module.iconEmoji, style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            isArabic ? module.themeArabic : module.theme,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          subtitle: Text(
            isArabic
                ? '${module.lessons.length} دروس • شهر ${module.month}'
                : '${module.lessons.length} lessons • Month ${module.month}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          children:
              module.lessons.map((lesson) {
                final isCompleted = completedIds.contains(lesson.id);
                final isActive = lesson.id == activeLessonId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : (isActive
                            ? Icons.play_circle_fill_rounded
                            : Icons.lock_outline_rounded),
                    color:
                        isCompleted
                            ? Colors.green
                            : (isActive
                                ? AppColors.primary
                                : Colors.grey.shade400),
                  ),
                  title: Text(
                    isArabic ? lesson.titleArabic : lesson.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    '${isArabic ? lesson.primarySkill.nameArabic : lesson.primarySkill.nameEnglish} • ${lesson.estimatedMinutes} ${isArabic ? "دقائق" : "mins"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    ref
                        .read(learningProfileProvider.notifier)
                        .updateCurrentLesson(lesson.id);
                    context.push('${AppRoutes.learning}?lessonId=${lesson.id}');
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}
