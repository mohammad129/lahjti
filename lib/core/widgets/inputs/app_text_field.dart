import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable form text input field with error and prefix/suffix support.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          maxLines: maxLines,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                enabled
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLightVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.error, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
