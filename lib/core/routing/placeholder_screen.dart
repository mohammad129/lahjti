import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/context_extensions.dart';
import '../widgets/buttons/secondary_button.dart';

/// Clean placeholder page displayed for routes that will be developed in later steps.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.icon = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading:
            context.canPop()
                ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                )
                : null,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentContainer,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    context.l10n.comingSoon,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.comingSoonDesc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (context.canPop()) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  SecondaryButton(
                    label: context.l10n.back,
                    width: 140,
                    height: 44,
                    onPressed: () => context.pop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
