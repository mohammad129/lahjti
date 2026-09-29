import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/tutor_persona.dart';

/// Rich Persona Card component for AI Tutor selection (Ahmed / Layan).
class TutorCard extends StatelessWidget {
  final TutorPersona tutor;
  final bool isSelected;
  final VoidCallback onSelect;

  const TutorCard({
    super.key,
    required this.tutor,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAbbas = tutor.id == 'abbas';
    final traits = tutor.localizedTraits(l10n);

    final avatarGradient =
        isAbbas
            ? const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            : const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.35)
                : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          width: isSelected ? 2.5 : 1.0,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: AppSpacing.borderRadiusXl,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name + Checkbox
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: avatarGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isAbbas
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isAbbas ? '👨‍🏫' : '👩‍🏫',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.localizedName(l10n),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            tutor.localizedRole(l10n),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
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
                                size: 16,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Description
                Text(
                  tutor.localizedDescription(l10n),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Personality traits chips
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs,
                  children:
                      traits.map((trait) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surfaceLightVariant,
                            borderRadius: AppSpacing.borderRadiusFull,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary.withValues(
                                        alpha: 0.25,
                                      )
                                      : AppColors.borderLight,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            trait,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondaryLight,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
