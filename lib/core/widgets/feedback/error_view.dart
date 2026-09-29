import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/context_extensions.dart';
import '../buttons/primary_button.dart';

/// Reusable friendly error display with retry button.
class ErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData icon;

  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMessage = message ?? context.l10n.somethingWentWrong;
    final effectiveRetry = retryLabel ?? context.l10n.tryAgain;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              effectiveMessage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: effectiveRetry,
                onPressed: onRetry,
                width: 180,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
