import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/models/classroom_models.dart';
import '../providers/school_providers.dart';

/// Real interactive Teacher Dashboard Screen for educators in the school context.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(localeProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final teacherProfile = ref.watch(currentTeacherProfileProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));

    final teacherName =
        teacherProfile?.fullName ??
        onboardingData.registeredName ??
        (isArabic ? 'الأستاذ' : 'Teacher');
    final schoolName =
        teacherProfile?.schoolName ??
        onboardingData.schoolName ??
        (isArabic ? 'المدرسة النموذجية' : 'School Academy');
    final subject =
        teacherProfile?.subjectTaught ??
        onboardingData.teacherSubject ??
        (isArabic ? 'اللغة الإنجليزية والمحادثة' : 'English & Conversation');

    final overviewAsync = ref.watch(teacherOverviewProvider);
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          l10n.teacherDashboardTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: false,
        actions: [
          // Language Switcher
          IconButton(
            icon: const Icon(Icons.language_rounded, color: AppColors.primary),
            tooltip: isArabic ? 'English' : 'العربية',
            onPressed: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
          ),
          // Logout / Exit to Welcome
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondaryLight,
            ),
            onPressed: () {
              context.go(AppRoutes.welcome);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherOverviewProvider);
            ref.invalidate(teacherClassesProvider);
            ref.invalidate(teacherTutorOversightProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Teacher Header Card
                Container(
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
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '👩‍🏫',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.teacherHomeSubtitle(teacherName),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  schoolName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          '📚 $subject',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tab Switcher: Overview & Classes vs AI English Tutor Oversight (4 Sessions)
                _buildTabSelector(
                  context,
                  ref,
                  ref.watch(teacherActiveTabProvider),
                  isArabic,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Active Tab Content
                if (ref.watch(teacherActiveTabProvider) == 0)
                  _buildOverviewTabContent(
                    context,
                    overviewAsync,
                    classesAsync,
                    l10n,
                  )
                else
                  _buildTutorOversightTabContent(
                    context,
                    ref,
                    isArabic,
                    classesAsync,
                  ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(
    BuildContext context,
    WidgetRef ref,
    int activeTab,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightVariant,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(teacherActiveTabProvider.notifier).state = 0;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      activeTab == 0
                          ? AppColors.surfaceLight
                          : Colors.transparent,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow:
                      activeTab == 0
                          ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: Text(
                    isArabic ? '📊 نظرة عامة والصفوف' : '📊 Overview & Classes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                      color:
                          activeTab == 0
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(teacherActiveTabProvider.notifier).state = 1;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      activeTab == 1
                          ? AppColors.surfaceLight
                          : Colors.transparent,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow:
                      activeTab == 1
                          ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: Text(
                    isArabic
                        ? '🤖 تدريب الذكاء الاصطناعي (4 جلسات)'
                        : '🤖 AI Tutor (4 Sessions)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                      color:
                          activeTab == 1
                              ? const Color(0xFF4F46E5)
                              : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTabContent(
    BuildContext context,
    AsyncValue<TeacherOverviewData> overviewAsync,
    AsyncValue<List<TeacherClassSummary>> classesAsync,
    dynamic l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Teacher Tools Banner: Exam Builder & Games Hub
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('teacher_create_exam_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push(AppRoutes.teacherExamBuilder),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('منشئ الاختبارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('teacher_manage_games_btn'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF818CF8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push(AppRoutes.games),
                icon: const Icon(Icons.sports_esports_rounded, size: 18),
                label: const Text('الألعاب المدرسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Real Metric Overview Cards Grid (2x2)
        overviewAsync.when(
          data: (data) => _buildOverviewGrid(context, data),
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, __) =>
                  _buildOverviewGrid(context, TeacherOverviewData.empty()),
        ),

        const SizedBox(height: AppSpacing.xl),

        // My Classes Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myClassesTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Classes List
        classesAsync.when(
          data: (classes) {
            if (classes.isEmpty) {
              return _buildEmptyClassesCard(context);
            }
            return Column(
              children:
                  classes.map((c) => _buildClassCard(context, c)).toList(),
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
              (err, _) => Center(
                child: Text(
                  l10n.notEnoughDataYet,
                  style: const TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Privacy Protection Notice Badge
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceLightVariant,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.privacy_tip_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.privacyProtectionNotice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(BuildContext context, TeacherOverviewData data) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: l10n.totalStudentsLabel,
                value: '${data.totalStudents}',
                icon: Icons.people_alt_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                title: l10n.activeTodayLabel,
                value: '${data.activeTodayCount}',
                icon: Icons.bolt_rounded,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: l10n.tasksCompletedTodayLabel,
                value: '${data.completedTasksTodayCount}',
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                title: l10n.averageProgressLabel,
                value:
                    data.hasSufficientData
                        ? '${data.averageProgressPercentage.toInt()}%'
                        : l10n.notEnoughDataYet,
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF6366F1),
                isSmallText: !data.hasSufficientData,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
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
            style: TextStyle(
              fontSize: isSmallText ? 12 : 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, TeacherClassSummary classItem) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: () {
            context.push('/teacher/classes/${classItem.classId}');
          },
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text('🏫', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              classItem.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        l10n.studentCountLabel(classItem.studentCount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.activeTodayLabel}: ${classItem.activeTodayCount}/${classItem.studentCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      classItem.hasSufficientData
                          ? '${l10n.averageProgressLabel}: ${classItem.averageProgressPercentage.toInt()}%'
                          : l10n.notEnoughDataYet,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.viewDetailsBtn,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyClassesCard(BuildContext context) {
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
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noClassesAssigned,
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

  // =========================================================================
  // AI English Tutor Oversight View (4 Daily Sessions & Fluency Tracking)
  // =========================================================================

  Widget _buildTutorOversightTabContent(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
    AsyncValue<List<TeacherClassSummary>> classesAsync,
  ) {
    final oversightAsync = ref.watch(teacherTutorOversightProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Educational Banner for Tutor Tracking
        _buildTutorHeroBanner(context, isArabic),

        const SizedBox(height: AppSpacing.lg),

        // 2. Class Filter Chips
        _buildClassFilterChips(context, ref, classesAsync, isArabic),

        const SizedBox(height: AppSpacing.lg),

        // 3. KPI Metric Cards Grid (4 metrics)
        oversightAsync.when(
          data: (data) => _buildTutorMetricGrid(context, data, isArabic),
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, __) => _buildTutorMetricGrid(
                context,
                TeacherTutorOversightData.empty(),
                isArabic,
              ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 4. Common Grammar Error Alerts (Pedagogical Actionable Insights)
        oversightAsync.when(
          data: (data) {
            if (data.commonGrammarPoints.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildGrammarAlertCard(
              context,
              data.commonGrammarPoints,
              isArabic,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 5. Section Header for Students List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isArabic
                    ? 'متابعة الطلاب والجلسات الأربع اليومية'
                    : 'Daily 4-Session Student Tracking',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            oversightAsync.maybeWhen(
              data:
                  (data) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Text(
                      isArabic
                          ? '${data.students.length} طلاب'
                          : '${data.students.length} students',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 6. Student Session Progress Cards List
        oversightAsync.when(
          data: (data) {
            if (data.students.isEmpty) {
              return _buildEmptyTutorStudentsCard(context, isArabic);
            }
            return Column(
              children:
                  data.students
                      .map((s) => _buildTutorStudentCard(context, s, isArabic))
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
              (err, _) => Center(
                child: Text(
                  isArabic
                      ? 'تعذر تحميل بيانات المتابعة حالياً'
                      : 'Unable to load tutor oversight data',
                  style: const TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 7. Privacy Disclaimer Badge
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 22,
                color: Color(0xFF0F766E),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isArabic
                      ? 'ملاحظة خصوصية: نصوص وتسجيلات المحادثات الصوتية مشفرة وخاصة بالطالب؛ تظهر للمعلم مؤشرات التقدم والملاحظات التربوية التوجيهية فقط.'
                      : 'Privacy Notice: Audio recordings and direct transcripts are private to the student; only educational indicators and guidance notes are shared with teachers.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTutorHeroBanner(BuildContext context, bool isArabic) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎙️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'متابعة المحادثة الإنجليزية اليومية'
                          : 'Daily English AI Tutor Tracking',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'المدرب الذكي: عباس ودنيا'
                          : 'AI Tutors: Abbas & Dunya',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'الحد اليومي: 4 جلسات مرنة وساعة كاملة (60 دقيقة) لكل طالب'
                        : 'Daily limit: 4 sessions & 1 hour (60 min) per student',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildClassFilterChips(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TeacherClassSummary>> classesAsync,
    bool isArabic,
  ) {
    final selectedClassId = ref.watch(selectedTutorClassFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // "All Classes" Chip
          FilterChip(
            label: Text(
              isArabic ? '🏫 كل الصفوف' : '🏫 All Classes',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selectedClassId == null
                        ? FontWeight.w800
                        : FontWeight.w600,
                color:
                    selectedClassId == null
                        ? Colors.white
                        : AppColors.textPrimaryLight,
              ),
            ),
            selected: selectedClassId == null,
            selectedColor: const Color(0xFF4F46E5),
            backgroundColor: AppColors.surfaceLight,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color:
                  selectedClassId == null
                      ? const Color(0xFF4F46E5)
                      : AppColors.borderLight,
            ),
            onSelected: (_) {
              ref.read(selectedTutorClassFilterProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: AppSpacing.sm),

          // Individual Class Chips
          ...classesAsync.maybeWhen(
            data:
                (classes) => classes.map((c) {
                  final isSelected = selectedClassId == c.classId;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(
                        c.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF4F46E5),
                      backgroundColor: AppColors.surfaceLight,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color:
                            isSelected
                                ? const Color(0xFF4F46E5)
                                : AppColors.borderLight,
                      ),
                      onSelected: (_) {
                        ref
                            .read(selectedTutorClassFilterProvider.notifier)
                            .state = isSelected ? null : c.classId;
                      },
                    ),
                  );
                }),
            orElse: () => const [],
          ),
        ],
      ),
    );
  }

  Widget _buildTutorMetricGrid(
    BuildContext context,
    TeacherTutorOversightData data,
    bool isArabic,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: isArabic ? 'المتدربون اليوم' : 'Practiced Today',
                value: '${data.practicedTodayCount} / ${data.totalStudents}',
                icon: Icons.record_voice_over_rounded,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                title: isArabic ? 'إجمالي وقت المحادثة' : 'Total Spoken Time',
                value:
                    isArabic
                        ? '${data.totalSpokenHours} ساعة'
                        : '${data.totalSpokenHours} hrs',
                icon: Icons.timer_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: isArabic ? 'أتموا الحصص (4/4)' : 'Completed 4/4 Sessions',
                value:
                    isArabic
                        ? '${data.completedQuotaCount} طلاب'
                        : '${data.completedQuotaCount} students',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                title: isArabic ? 'متوسط طلاقة الإنجليزية' : 'Avg Fluency Score',
                value:
                    data.averageFluencyScore > 0
                        ? '${data.averageFluencyScore}%'
                        : (isArabic ? 'قيد التقييم' : 'Assessing'),
                icon: Icons.insights_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrammarAlertCard(
    BuildContext context,
    List<TeacherGrammarPoint> points,
    bool isArabic,
  ) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isArabic
                      ? 'نقاط لغوية تحتاج تعزيزاً في الحصة القادمة'
                      : 'Common Language Points for Classroom Reinforcement',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                        ),
                        children: [
                          TextSpan(
                            text: '${p.topic}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: p.recommendedAction),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorStudentCard(
    BuildContext context,
    TeacherStudentTutorSummary student,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color:
              student.hasActiveSession
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.4)
                  : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                student.hasActiveSession
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: () {
            _showStudentTutorDetailsModal(context, student, isArabic);
          },
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, CEFR Level, Spoken Time Badge
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLightVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          student.avatarEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  student.displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4F46E5,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Text(
                                  student.cefrLevel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.className,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Spoken time badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            student.isGoalCompleted
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : student.hasActiveSession
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                                : AppColors.surfaceLightVariant,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        student.spokenTimeFormatted(isArabic),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color:
                              student.isGoalCompleted
                                  ? const Color(0xFF047857)
                                  : student.hasActiveSession
                                  ? const Color(0xFFB45309)
                                  : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Spoken time progress bar (Container + FractionallySizedBox, layout safe)
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLightVariant,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: ClipRRect(
                    borderRadius: AppSpacing.borderRadiusFull,
                    child: Align(
                      alignment:
                          isArabic
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: student.progressFraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  student.isGoalCompleted
                                      ? [
                                        const Color(0xFF10B981),
                                        const Color(0xFF059669),
                                      ]
                                      : [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF4F46E5),
                                      ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // The 4 Session Visual Slots Pills
                Row(
                  children:
                      student.sessions.map((slot) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildSessionSlotPill(context, slot, isArabic),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Status text and action link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student.sessionProgressText(isArabic),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              student.isGoalCompleted
                                  ? const Color(0xFF047857)
                                  : student.hasActiveSession
                                  ? const Color(0xFFB45309)
                                  : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isArabic ? 'تفاصيل الجلسات' : 'Session details',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSlotPill(
    BuildContext context,
    TeacherTutorSessionSlot slot,
    bool isArabic,
  ) {
    Color bg;
    Color border;
    Color textColor;
    String label;
    IconData icon;

    if (slot.isCompleted) {
      bg = const Color(0xFFD1FAE5);
      border = const Color(0xFF10B981);
      textColor = const Color(0xFF065F46);
      icon = Icons.check_circle_rounded;
      label = isArabic ? '${slot.sessionNumber}: ${slot.durationMinutes}د' : '#${slot.sessionNumber}: ${slot.durationMinutes}m';
    } else if (slot.isActive) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFF59E0B);
      textColor = const Color(0xFF92400E);
      icon = Icons.mic_rounded;
      label = isArabic ? '${slot.sessionNumber}: نشطة' : '#${slot.sessionNumber}: Active';
    } else {
      bg = AppColors.surfaceLightVariant;
      border = AppColors.borderLight;
      textColor = AppColors.textSecondaryLight;
      icon = Icons.radio_button_unchecked_rounded;
      label = isArabic ? '${slot.sessionNumber}: متبقية' : '#${slot.sessionNumber}: Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTutorStudentsCard(BuildContext context, bool isArabic) {
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
            const Text('🎓', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isArabic
                  ? 'لا يوجد طلاب مسجلون في هذا الصف حالياً'
                  : 'No students enrolled in this class currently',
              style: const TextStyle(
                fontSize: 14,
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

  // =========================================================================
  // Student Session Detail Modal / Bottom Sheet
  // =========================================================================

  void _showStudentTutorDetailsModal(
    BuildContext context,
    TeacherStudentTutorSummary student,
    bool isArabic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header with Student Avatar, Name, and Status
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            student.avatarEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${student.className} • ${student.cefrLevel}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Quota Overview Box
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightVariant,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildModalStatColumn(
                            isArabic ? 'وقت المحادثة' : 'Spoken Time',
                            student.spokenTimeFormatted(isArabic),
                            const Color(0xFF4F46E5),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.borderLight,
                        ),
                        Expanded(
                          child: _buildModalStatColumn(
                            isArabic
                                ? 'الجلسات المكتملة'
                                : 'Completed Sessions',
                            '${student.completedSessionsCount} / ${student.maxDailySessions}',
                            const Color(0xFF0F766E),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.borderLight,
                        ),
                        Expanded(
                          child: _buildModalStatColumn(
                            isArabic ? 'حالة الهدف' : 'Goal Status',
                            student.isGoalCompleted
                                ? (isArabic ? 'مكتمل 🎯' : 'Done 🎯')
                                : (isArabic ? 'قيد الإنجاز' : 'In Progress'),
                            student.isGoalCompleted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // The 4 Daily Sessions Breakdown
                  Text(
                    isArabic
                        ? 'تفاصيل الحصص الأربع لليوم'
                        : 'Today\'s 4 Sessions Breakdown',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ...student.sessions.map((slot) {
                    return _buildSessionDetailCard(slot, isArabic);
                  }),

                  const SizedBox(height: AppSpacing.md),

                  // Teacher Pedagogical Recommendation Box
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              isArabic
                                  ? 'توصية المدرب الذكي للمعلم'
                                  : 'AI Tutor Teacher Recommendation',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3730A3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          student.teacherNotesSuggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF312E81),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Privacy Notice
                  Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightVariant,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            isArabic
                                ? 'التسجيلات الصوتية ومحادثات الذكاء الاصطناعي مشفرة ومحمية لحفظ خصوصية الطالب.'
                                : 'Audio recordings and AI chats are encrypted to preserve student privacy.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDetailCard(
    TeacherTutorSessionSlot slot,
    bool isArabic,
  ) {
    Color indicatorColor;
    String statusLabel;

    if (slot.isCompleted) {
      indicatorColor = const Color(0xFF10B981);
      statusLabel = isArabic ? 'مكتملة' : 'Completed';
    } else if (slot.isActive) {
      indicatorColor = const Color(0xFFF59E0B);
      statusLabel = isArabic ? 'نشطة الآن 🎙️' : 'Active Now 🎙️';
    } else {
      indicatorColor = AppColors.borderLight;
      statusLabel = isArabic ? 'متبقية' : 'Pending';
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
            width: 8,
            height: 38,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic
                          ? 'الجلسة ${slot.sessionNumber} من 4'
                          : 'Session ${slot.sessionNumber} of 4',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: indicatorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (slot.topic != null)
                  Text(
                    slot.topic!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      slot.durationText(isArabic),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    if (slot.tutorName != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        isArabic
                            ? 'المدرب: ${slot.tutorName == 'Abbas' ? 'عباس' : 'دنيا'}'
                            : 'Tutor: ${slot.tutorName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                    if (slot.turnsCount > 0) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        isArabic
                            ? '${slot.turnsCount} ردود'
                            : '${slot.turnsCount} turns',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
