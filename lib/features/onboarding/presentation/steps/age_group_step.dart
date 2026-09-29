import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/age_group.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step 2: Age Group Selection with adaptive category indications.
class AgeGroupStep extends ConsumerWidget {
  const AgeGroupStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final selectedAge = ref.watch(
      onboardingProvider.select((s) => s.data.ageGroup),
    );

    final displayedGroups = AgeGroup.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ageGroupTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.ageGroupSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView.separated(
            itemCount: displayedGroups.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final age = displayedGroups[index];
              final isSelected = selectedAge == age;

              String? subtitle;
              String emoji = '👤';
              if (age.isChild) {
                emoji = '🎈';
                subtitle =
                    isArabic
                        ? 'تجربة مرحة وسهلة مع ألعاب تعليمية مبسطة'
                        : 'Playful experience with simplified learning games';
              } else if (age.isTeen) {
                emoji = '⚡';
                subtitle =
                    isArabic
                        ? 'تحديات لغوية، نقاط وتقدم سريع وتفاعل ممتع'
                        : 'Gamified challenges, fast progress & interactive speech';
              } else if (age == AgeGroup.age18_25 || age == AgeGroup.age19_25) {
                emoji = '🎓';
                subtitle =
                    isArabic
                        ? 'محادثات واقعية للدراسة والسفر والتواصل اليومي'
                        : 'Real-world conversations for study, travel & daily life';
              } else if (age == AgeGroup.age26_40 || age == AgeGroup.age26_35) {
                emoji = '💼';
                subtitle =
                    isArabic
                        ? 'لهجات عملية وسياقات مهنية واجتماعية متقدمة'
                        : 'Practical dialects for professional & social fluency';
              } else {
                emoji = '🌟';
                subtitle =
                    isArabic
                        ? 'تعلم مريح ومرن يركز على الفهم والتواصل الطبيعي'
                        : 'Comfortable, flexible learning focused on natural fluency';
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56.0),
                child: SelectableOptionCard(
                  key: Key('age_option_${age.name}'),
                  title: age.localizedLabel(l10n),
                  subtitle: subtitle,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLightVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  isSelected: isSelected,
                  onSelect: () {
                    ref.read(onboardingProvider.notifier).selectAgeGroup(age);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
