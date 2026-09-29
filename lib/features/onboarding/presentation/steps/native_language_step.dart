import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/native_language.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step 3: Native Language Selection
class NativeLanguageStep extends ConsumerWidget {
  const NativeLanguageStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedNative = ref.watch(
      onboardingProvider.select((s) => s.data.nativeLanguage),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.nativeLanguageTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.nativeLanguageSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView.separated(
            itemCount: NativeLanguage.values.length,
            separatorBuilder:
                (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final lang = NativeLanguage.values[index];
              final isSelected = selectedNative == lang;

              return SelectableOptionCard(
                title: lang.localizedName(l10n),
                subtitle:
                    lang.nativeName != lang.localizedName(l10n)
                        ? lang.nativeName
                        : null,
                leading: Text(
                  lang.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                isSelected: isSelected,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectNativeLanguage(lang);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
