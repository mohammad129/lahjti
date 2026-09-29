import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/supported_language.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step 1: Target Language Selection
class TargetLanguageStep extends ConsumerWidget {
  const TargetLanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedLang = ref.watch(
      onboardingProvider.select((s) => s.data.targetLanguage),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.targetLanguageTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.targetLanguageSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView.separated(
            itemCount: SupportedLanguage.initialLanguages.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final language = SupportedLanguage.initialLanguages[index];
              final isSelected = selectedLang?.id == language.id;

              return SelectableOptionCard(
                title: language.localizedName(l10n),
                subtitle:
                    language.nameEn != language.localizedName(l10n)
                        ? language.nameEn
                        : null,
                leading: Text(
                  language.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                isSelected: isSelected,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectTargetLanguage(language);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
