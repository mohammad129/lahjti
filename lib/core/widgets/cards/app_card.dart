import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable Card container for content modules and list items.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingLg,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppSpacing.radiusLg,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surfaceLight;
    final effectiveBorder = borderColor ?? AppColors.borderLight;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: effectiveBorder, width: 1),
    );

    if (onTap != null) {
      return Material(
        color: effectiveBg,
        shape: shape,
        elevation: elevation,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return Container(
      decoration: ShapeDecoration(
        color: effectiveBg,
        shape: shape,
        shadows:
            elevation > 0
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: elevation * 4,
                    offset: Offset(0, elevation),
                  ),
                ]
                : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
