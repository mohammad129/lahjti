import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../account/domain/models/account_context.dart';
import '../../../account/domain/models/subscription_access.dart';
import '../../../account/presentation/providers/account_providers.dart';
import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/experience_level.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../school/presentation/providers/school_providers.dart';

/// Clean Account & Profile Screen displaying user identity, learning preferences
/// (Target Language, CEFR Level, Goal, Age, Tutor Persona), and live subscription/access tier status.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final accountContext = ref.watch(currentAccountContextProvider);
    final accessAsync = ref.watch(subscriptionAccessProvider('current_user'));

    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final studentProfile = ref.watch(currentSchoolStudentProfileProvider);
    final teacherProfile = ref.watch(currentTeacherProfileProvider);

    final displayName =
        onboardingData.registeredName ??
        (accountContext.isSchool
            ? (studentProfile?.fullName ??
                teacherProfile?.fullName ??
                (isArabic ? 'المستخدم' : 'User'))
            : (isArabic ? 'متعلم لهجتي' : 'Lahjti Learner'));

    final email = onboardingData.registeredEmail ?? 'user@lahjti.com';
    final currentTargetLang =
        onboardingData.targetLanguage ?? SupportedLanguage.english;
    final currentAgeGroup = onboardingData.ageGroup ?? AgeGroup.age18_25;
    final currentGoal =
        onboardingData.learningGoal ?? LearningGoal.casualConversation;
    final currentLevel = onboardingData.experienceLevel ?? ExperienceLevel.zero;
    final selectedTutorId = onboardingData.selectedTutorId ?? 'abbas';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.accountProfileTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Avatar & Identity Card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          accountContext.isSchool
                              ? (onboardingData.isSchoolTeacher
                                  ? '👩‍🏫'
                                  : '🎒')
                              : (selectedTutorId == 'abbas'
                                  ? '👨‍🎓'
                                  : '👩‍🎓'),
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 2. Learning Preferences Section Header
              Text(
                isArabic
                    ? 'تفضيلات ومسار التعلم'
                    : 'Learning Path & Preferences',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Target Language Tile
              _buildPreferenceTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.primary,
                title: isArabic ? 'اللغة المستهدفة للتعلم' : 'Target Language',
                subtitle:
                    '${currentTargetLang.flagEmoji} ${currentTargetLang.localizedName(l10n)}',
                onTap: () => _showTargetLanguagePicker(context, ref),
              ),
              const SizedBox(height: 8),

              // Proficiency Level Tile
              _buildPreferenceTile(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF0D9488),
                title: isArabic ? 'المستوى التعليمي' : 'Proficiency Level',
                subtitle: currentLevel.localizedTitle(l10n),
                onTap: () => _showLevelPicker(context, ref),
              ),
              const SizedBox(height: 8),

              // Learning Goal Tile
              _buildPreferenceTile(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: isArabic ? 'هدف التعلم' : 'Learning Goal',
                subtitle: currentGoal.localizedTitle(l10n),
                onTap: () => _showGoalPicker(context, ref),
              ),
              const SizedBox(height: 8),

              // Age Group Tile
              _buildPreferenceTile(
                icon: Icons.cake_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: isArabic ? 'الفئة العمرية' : 'Age Group',
                subtitle: currentAgeGroup.localizedLabel(l10n),
                onTap: () => _showAgeGroupPicker(context, ref),
              ),
              const SizedBox(height: 8),

              // AI Tutor Persona Tile
              _buildPreferenceTile(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFFEC4899),
                title: isArabic ? 'المدرب التعليمي الذكي' : 'AI Learning Coach',
                subtitle:
                    selectedTutorId == 'abbas'
                        ? (isArabic
                            ? 'عباس (مدرب محفّز)'
                            : 'Abbas (Motivational)')
                        : (isArabic
                            ? 'دنيا (مدربة مرحة)'
                            : 'Dunya (Playful & Gentle)'),
                onTap: () => _showTutorPicker(context, ref),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 3. Subscription & Access Status Header
              Text(
                l10n.accountAccessStatusLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Dynamic Subscription / Access Status Card
              accessAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (access) {
                  return _buildAccessStatusCard(
                    context,
                    accountContext: accountContext,
                    access: access,
                    isArabic: isArabic,
                    onboardingSchoolName: onboardingData.schoolName,
                  );
                },
              ),

              const SizedBox(height: 8),

              // Subscription Screen Navigation Tile
              ListTile(
                key: const Key('profile_subscription_tile'),
                leading: const Icon(
                  Icons.stars_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  l10n.subscriptionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isArabic
                      ? 'إدارة الخطة، والتجربة المجانية، والاشتراك'
                      : 'Manage plan, free trial & subscription',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                onTap: () {
                  context.push(AppRoutes.subscription);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // 4. App Settings Header
              Text(
                isArabic ? 'إعدادات التطبيق' : 'App Settings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // UI Language Toggle Tile
              ListTile(
                leading: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  isArabic ? 'لغة الواجهة' : 'App Interface Language',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isArabic ? 'العربية (RTL)' : 'English (LTR)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () {
                    ref.read(localeProvider.notifier).toggleLocale();
                  },
                  child: Text(
                    isArabic ? 'تغيير إلى English' : 'Switch to العربية',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  side: const BorderSide(color: AppColors.borderLight),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Professional Attribution Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      l10n.developerCredit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'mohammadabuabbas.my',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: const BorderSide(color: AppColors.borderLight),
      ),
      onTap: onTap,
    );
  }

  void _showTargetLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'اختر اللغة المستهدفة' : 'Select Target Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: SupportedLanguage.initialLanguages.length,
                    itemBuilder: (ctx, index) {
                      final lang = SupportedLanguage.initialLanguages[index];
                      return ListTile(
                        leading: Text(
                          lang.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          lang.localizedName(l10n),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(lang.nativeName),
                        onTap: () {
                          ref
                              .read(onboardingProvider.notifier)
                              .selectTargetLanguage(lang);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelPicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تحديد المستوى' : 'Select Proficiency Level',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...ExperienceLevel.values.map(
                  (lvl) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.signal_cellular_alt_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      lvl.localizedTitle(l10n),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(lvl.localizedDescription(l10n)),
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .selectExperienceLevel(lvl);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'هدف التعلم' : 'Select Learning Goal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...LearningGoal.values.map(
                  (goal) => ListTile(
                    leading: Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      goal.localizedTitle(l10n),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(goal.localizedDescription(l10n)),
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .selectLearningGoal(goal);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAgeGroupPicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الفئة العمرية' : 'Select Age Group',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...AgeGroup.primaryGroups.map(
                  (age) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      age.localizedLabel(l10n),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      ref.read(onboardingProvider.notifier).selectAgeGroup(age);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTutorPicker(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'اختر مدربك الذكي' : 'Select AI Coach',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...TutorPersona.tutors.map(
                  (tutor) => ListTile(
                    leading: Text(
                      tutor.avatarEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      tutor.localizedName(l10n),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isArabic ? tutor.descriptionAr : tutor.descriptionEn,
                    ),
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .selectTutor(tutor.id);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessStatusCard(
    BuildContext context, {
    required AccountContext accountContext,
    required SubscriptionAccess access,
    required bool isArabic,
    String? onboardingSchoolName,
  }) {
    final l10n = context.l10n;

    // School Context
    if (accountContext.isSchool ||
        access.status == SubscriptionStatus.schoolAccess) {
      final schoolName =
          access.schoolName ??
          onboardingSchoolName ??
          (isArabic ? 'المدرسة النموذجية' : 'Academy');
      return Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF1D4ED8)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isArabic ? 'وصول مدرسي' : 'School Access',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isArabic ? 'نشط' : 'Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              schoolName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isArabic
                  ? 'وصول تعليمي معتمد عبر ترخيص المدرسة'
                  : 'Access active via institutional license',
              style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
            ),
          ],
        ),
      );
    }

    // Individual Active Paid Subscription
    if (access.status == SubscriptionStatus.active) {
      return Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF059669)),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Lahjti Individual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isArabic ? 'نشط' : 'Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isArabic ? '10 دولارات / شهرياً' : '\$10 / month',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
      );
    }

    // Individual Expired Trial
    if (access.isTrialExpired) {
      return Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_off_rounded, color: Color(0xFFDC2626)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isArabic ? 'انتهت التجربة' : 'Trial Ended',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.trialEndedSubscriptionRequired,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      );
    }

    // Individual Active Trial
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.trialActiveBadge,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${access.daysRemaining} ${isArabic ? "أيام" : "days"}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.trialActiveDaysRemaining(access.daysRemaining),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
