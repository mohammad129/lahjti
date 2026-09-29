import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../account/domain/models/account_context.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/selectable_option_card.dart';

/// Step: Account Type Selection (Individual vs School)
class AccountTypeStep extends ConsumerWidget {
  const AccountTypeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentContext = ref.watch(
      onboardingProvider.select((s) => s.data.accountContext),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountTypeTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.accountTypeSubtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: ListView(
            children: [
              SelectableOptionCard(
                title: l10n.accountIndividual,
                subtitle: l10n.accountIndividualDesc,
                leading: const Text('👤', style: TextStyle(fontSize: 28)),
                isSelected: currentContext == AccountContext.individual,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectAccountContext(AccountContext.individual);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableOptionCard(
                title: l10n.accountSchool,
                subtitle: l10n.accountSchoolDesc,
                leading: const Text('🏫', style: TextStyle(fontSize: 28)),
                isSelected: currentContext == AccountContext.school,
                onSelect: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectAccountContext(AccountContext.school);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
