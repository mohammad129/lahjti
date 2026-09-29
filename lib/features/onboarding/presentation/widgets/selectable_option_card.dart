import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Reusable selectable card with animated selection border, checkmark, and custom leading icon/emoji.
class SelectableOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onSelect;
  final EdgeInsetsGeometry? padding;

  const SelectableOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.isSelected,
    required this.onSelect,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.35)
                : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md + 2,
                ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs - 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color:
                                isSelected
                                    ? AppColors.primaryDark.withValues(
                                      alpha: 0.8,
                                    )
                                    : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
