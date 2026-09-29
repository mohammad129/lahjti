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
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';

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
                      (_, __) => _buildOverviewGrid(
                        context,
                        TeacherOverviewData.empty(),
                      ),
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
                          classes
                              .map((c) => _buildClassCard(context, c))
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
                          l10n.notEnoughDataYet,
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                          ),
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

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
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
}
