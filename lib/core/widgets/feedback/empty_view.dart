import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/context_extensions.dart';

/// Reusable empty state view.
class EmptyView extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? context.l10n.emptyStateTitle;
    final effectiveMessage = message ?? context.l10n.emptyStateMessage;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLightVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.textTertiaryLight),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              effectiveTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              effectiveMessage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
