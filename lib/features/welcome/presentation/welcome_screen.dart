import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../account/domain/models/account_context.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/context_extensions.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../school/domain/models/school_role.dart';

/// Polished Initial Welcome Screen for Lahjti (لهجتي).
///
/// Provides a clear two-path entry model:
/// - A) شخص (Individual Person) -> Personal onboarding & 3-day trial.
/// - B) مدرسة (School) -> "هل أنت؟" Student or Teacher selection with 10-day institutional access.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _showSchoolRoleModal(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.schoolRoleTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.schoolRoleSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ListTile(
                  key: const Key('modal_select_student'),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Text('🎒', style: TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    l10n.roleStudent,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(l10n.roleStudentDesc),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .selectSchoolRole(SchoolRole.student);
                    Navigator.pop(modalContext);
                    context.push(AppRoutes.onboarding);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  key: const Key('modal_select_teacher'),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Text('👩‍🏫', style: TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    l10n.roleTeacher,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(l10n.roleTeacherDesc),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .selectSchoolRole(SchoolRole.teacher);
                    Navigator.pop(modalContext);
                    context.push(AppRoutes.onboarding);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.hasBoundedHeight
                      ? (constraints.maxHeight - (AppSpacing.lg * 2))
                          .clamp(0.0, double.infinity)
                      : 0.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: App Icon & Language Switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // App brand badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AppSpacing.borderRadiusFull,
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  isArabic ? 'مدرب ذكي' : 'AI Powered',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Language Toggle Button
                          TextButton.icon(
                            onPressed: () {
                              ref.read(localeProvider.notifier).toggleLocale();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              backgroundColor: AppColors.surfaceLightVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.borderRadiusFull,
                              ),
                            ),
                            icon: const Icon(Icons.language_rounded, size: 18),
                            label: Text(
                              isArabic ? 'English' : 'العربية',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Center Hero Visual & Illustration Card
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F766E),
                                Color(0xFF0D9488),
                                Color(0xFF14B8A6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.record_voice_over_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // App Name Title
                      Text(
                        isArabic
                            ? AppConstants.appNameAr
                            : AppConstants.appNameEn,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Main Hero Tagline
                      Text(
                        isArabic
                            ? AppConstants.welcomeTaglineAr
                            : context.l10n.welcomeTagline,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Supporting Description
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          isArabic
                              ? AppConstants.welcomeSubtitleAr
                              : context.l10n.welcomeSubtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryLight,
                            height: 1.55,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Spacer(),

                      // Primary Call to Action Button: A) شخص (Individual Person)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56.0),
                        child: PrimaryButton(
                          label:
                              isArabic
                                  ? AppConstants.welcomeCtaAr
                                  : context.l10n.welcomeButtonCta,
                          onPressed: () {
                            ref.read(onboardingProvider.notifier).reset();
                            ref
                                .read(onboardingProvider.notifier)
                                .selectAccountContext(
                                  AccountContext.individual,
                                );
                            context.push(AppRoutes.onboarding);
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Secondary Call to Action Button: B) مدرسة (School Entry)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56.0),
                        child: OutlinedButton.icon(
                          key: const Key('welcome_school_portal_btn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                              horizontal: AppSpacing.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusLg,
                            ),
                          ),
                          icon: const Icon(Icons.school_rounded, size: 22),
                          label: Text(
                            context.l10n.welcomeSchoolButton,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => _showSchoolRoleModal(context, ref),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Professional Company & Developer Reference Footer
                      Column(
                        children: [
                          Text(
                            isArabic
                                ? 'تعلم اللهجة بكل ثقة وطبيعية'
                                : 'Learn spoken dialects naturally and with confidence',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Phoenix Technical Group (PTG) • Mohammad Abu Abbas • mohammadabuabbas.my',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiaryLight,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
