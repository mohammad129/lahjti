import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/feature_access_key.dart';
import '../providers/subscription_providers.dart';

/// Reusable widget wrapper guarding premium/institutional features.
/// Renders standard UI when authorized, or a friendly educational paywall card when restricted.
class SubscriptionGuard extends ConsumerWidget {
  final FeatureAccessKey feature;
  final Widget child;
  final Widget? fallback;

  const SubscriptionGuard({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(featureAccessProvider(feature));

    if (permission.isAllowed) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 44)),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic ? 'الميزة مقفلة حالياً' : 'Feature Locked',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                permission.denialReason ??
                    (isArabic
                        ? 'يلزم وجود اشتراك نشط أو رخصة مدرسية صالحة للوصول إلى هذه الميزة.'
                        : 'Active subscription or valid school license required.'),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                key: const Key('subscription_guard_upgrade_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  final route =
                      permission.requiredActionRoute ?? '/subscription/access';
                  context.push(route);
                },
                child: Text(
                  isArabic
                      ? 'عرض خيارات الاشتراك والتراخيص'
                      : 'View Subscription & License Options',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
