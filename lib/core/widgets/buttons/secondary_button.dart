import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable secondary / outlined button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = textColor ?? AppColors.primary;
    final effectiveBorder = borderColor ?? AppColors.borderLight;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
