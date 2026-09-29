import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/account_context.dart';
import '../../domain/models/subscription_access.dart';
import '../providers/account_providers.dart';

/// Screen displaying subscription and access status without real payment processing.
///
/// Features:
/// - Real-time Access Decision evaluation (Trial active, Paid active, Expired trial, School access).
/// - Clear transparent pricing: 3-day free trial, then $10/month.
/// - Feature breakdown and plan benefits.
/// - Terms of Service & Privacy Policy placeholders.
/// - Restore Purchases button (with development feedback).
/// - Professional attribution (PTG • Mohammad Abu Abbas • mohammadabuabbas.my).
class SubscriptionAccessScreen extends ConsumerWidget {
  const SubscriptionAccessScreen({super.key});

  void _showRestoreNotice(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) async {
    await ref
        .read(subscriptionAccessRepositoryProvider)
        .checkStatus('current_user');
    ref.invalidate(subscriptionAccessProvider('current_user'));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSandboxCheckoutDialog(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'تأكيد الاشتراك' : 'Confirm Subscription',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'الخطة الشهرية الكاملة — \$10 شهرياً'
                      : 'Full Individual Plan — \$10 / month',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'وصول غير محدود لجميع اللغات، الدروس التفاعلية، محادثات معلم الذكاء الاصطناعي، والألعاب التعليمية.'
                      : 'Unlimited access to all languages, interactive lessons, AI tutor conversations, and educational games.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                key: const Key('sandbox_confirm_payment_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(subscriptionAccessRepositoryProvider)
                      .activatePaidSubscription('current_user');
                  ref.invalidate(subscriptionAccessProvider('current_user'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? '🎉 تم تفعيل الاشتراك بنجاح!'
                              : '🎉 Subscription activated successfully!',
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                child: Text(isArabic ? 'تأكيد' : 'Confirm'),
              ),
            ],
          ),
    );
  }

  void _showTermsDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final accountContext = ref.watch(currentAccountContextProvider);
    final accessAsync = ref.watch(subscriptionAccessProvider('current_user'));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.subscriptionTitle,
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
        child: accessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading access: $err')),
          data: (access) {
            final isSchool =
                accountContext == AccountContext.school ||
                access.status == SubscriptionStatus.schoolAccess;
            final isExpired = access.isTrialExpired;

            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header Badge Card
                  Container(
                    padding: AppSpacing.paddingXl,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isSchool
                                ? [
                                  const Color(0xFF1E3A8A),
                                  const Color(0xFF2563EB),
                                  const Color(0xFF3B82F6),
                                ]
                                : (isExpired
                                    ? [
                                      const Color(0xFFB91C1C),
                                      const Color(0xFFDC2626),
                                      const Color(0xFFEF4444),
                                    ]
                                    : [
                                      const Color(0xFF0F766E),
                                      const Color(0xFF0D9488),
                                      const Color(0xFF14B8A6),
                                    ]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSpacing.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: (isExpired ? Colors.red : AppColors.primary)
                              .withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isSchool ? '🏫' : (isExpired ? '⏳' : '✨'),
                          style: const TextStyle(fontSize: 44),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isSchool
                              ? (access.trialDurationDays == 10
                                  ? l10n.schoolTrialBadge
                                  : l10n.schoolAccessBadge)
                              : (isExpired
                                  ? l10n.trialExpiredBadge
                                  : (access.status == SubscriptionStatus.active
                                      ? l10n.activeSubscriptionBadge
                                      : l10n.trialActiveBadge)),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isSchool
                              ? l10n.schoolAccessDesc(
                                access.schoolName ??
                                    (isArabic ? 'مدرستك' : 'Your School'),
                              )
                              : (isExpired
                                  ? l10n.trialExpiredDesc
                                  : (access.status == SubscriptionStatus.active
                                      ? l10n.activeSubscriptionDesc
                                      : l10n.trialDaysRemainingText(
                                        access.daysRemaining,
                                      ))),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Plan Details Card
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSchool
                                  ? Icons.school_rounded
                                  : Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              isSchool
                                  ? (isArabic
                                      ? 'وصول تعليمي معتمد'
                                      : 'Verified School Access')
                                  : (isArabic
                                      ? 'خطة التعلم الفردي'
                                      : 'Individual Learning Plan'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isSchool
                              ? (isArabic
                                  ? 'تم تفعيل هذا الحساب عبر اشتراك مدرستك. يمكنك الوصول لكافة المناهج والاختبارات والألعاب التعليمية والمحادثات مع المعلم الذكي بدون أي رسوم فردية.'
                                  : 'This account is managed through your school enrollment. Full curriculum, exams, games, and AI Tutor features are accessible without individual fees.')
                              : l10n.subscriptionPriceNote,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Feature List Breakdown
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.subscriptionFeaturesTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildFeatureRow(
                          Icons.record_voice_over_rounded,
                          l10n.subscriptionFeature1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFeatureRow(
                          Icons.sports_esports_rounded,
                          l10n.subscriptionFeature2,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFeatureRow(
                          Icons.analytics_rounded,
                          l10n.subscriptionFeature3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Pricing & Payment Placeholder Section (Individual)
                  if (!isSchool) ...[
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'سعر الاشتراك:' : 'Subscription Price:',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.subscriptionPriceTag,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        key: const Key('subscription_upgrade_cta_btn'),
                        icon: const Icon(Icons.bolt_rounded, size: 20),
                        label: Text(
                          access.status == SubscriptionStatus.active
                              ? (isArabic
                                  ? 'الاشتراك نشط ومفعل ✓'
                                  : 'Subscription Active ✓')
                              : (isArabic
                                  ? 'بدء الاشتراك الآن (\$10/شهرياً) ⚡'
                                  : 'Start Subscription Now (\$10/mo) ⚡'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              access.status == SubscriptionStatus.active
                                  ? const Color(0xFF059669)
                                  : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusLg,
                          ),
                        ),
                        onPressed:
                            access.status == SubscriptionStatus.active
                                ? null
                                : () => _showSandboxCheckoutDialog(
                                  context,
                                  ref,
                                  isArabic,
                                ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Restore Purchases Button
                    Center(
                      child: TextButton.icon(
                        key: const Key('subscription_restore_btn'),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(
                          l10n.restorePurchases,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        onPressed: () {
                          _showRestoreNotice(
                            context,
                            ref,
                            isArabic
                                ? 'خاصية استعادة المشتريات ستكون متاحة مع إطلاق بوابات الدفع الرسمية'
                                : 'Restore purchases will be available with official payment gateways',
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Legal Links (Terms & Privacy placeholders)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        key: const Key('subscription_terms_btn'),
                        onPressed: () {
                          _showTermsDialog(
                            context,
                            l10n.termsOfService,
                            isArabic
                                ? 'شروط استخدام منصة لهجتي: اشتراك شهري يجدد تلقائياً بقيمة 10 دولارات شهرياً بعد انتهاء الفترة التجريبية (3 أيام). يمكن الإلغاء في أي وقت عبر إعدادات الحساب.'
                                : r'Lahjti Terms of Service: Monthly recurring subscription of $10/month after 3-day free trial. Cancel anytime via account settings.',
                          );
                        },
                        child: Text(
                          l10n.termsOfService,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppColors.textTertiaryLight),
                      ),
                      TextButton(
                        key: const Key('subscription_privacy_btn'),
                        onPressed: () {
                          _showTermsDialog(
                            context,
                            l10n.privacyPolicy,
                            isArabic
                                ? 'سياسة خصوصية لهجتي: يتم تشفير وحماية بيانات المستخدمين والطلاب ولا يتم مشاركة أي بيانات صوتية أو معلومات مالية مع أي طرف ثالث.'
                                : 'Lahjti Privacy Policy: User data is encrypted and protected. Voice transcripts and personal information are never shared with third parties.',
                          );
                        },
                        child: Text(
                          l10n.privacyPolicy,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Professional Company Attribution
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n.developerCredit,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
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
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
