import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/context_extensions.dart';

/// Reusable full-page or contained loading spinner with optional text.
class LoadingView extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingView({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveText = message ?? context.l10n.loading;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
              strokeWidth: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              effectiveText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
