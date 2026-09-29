import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../school/presentation/providers/school_providers.dart';
import '../providers/onboarding_provider.dart';

/// Step: School Code Entry & Verification
class SchoolCodeVerificationStep extends ConsumerStatefulWidget {
  const SchoolCodeVerificationStep({super.key});

  @override
  ConsumerState<SchoolCodeVerificationStep> createState() =>
      _SchoolCodeVerificationStepState();
}

class _SchoolCodeVerificationStepState
    extends ConsumerState<SchoolCodeVerificationStep> {
  late final TextEditingController _codeController;
  bool _isChecking = false;
  String? _verificationError;
  String? _verifiedSchoolName;

  @override
  void initState() {
    super.initState();
    final currentCode = ref.read(onboardingProvider).data.schoolCode ?? '';
    final currentName = ref.read(onboardingProvider).data.schoolName;
    _codeController = TextEditingController(text: currentCode);
    _verifiedSchoolName = currentName;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isChecking = true;
      _verificationError = null;
    });

    final repo = ref.read(schoolRepositoryProvider);
    final school = await repo.findSchoolByCode(code);

    if (!mounted) return;

    setState(() {
      _isChecking = false;
      if (school != null && school.isActive) {
        _verifiedSchoolName = school.name;
        _verificationError = null;
        ref
            .read(onboardingProvider.notifier)
            .setSchoolDetails(schoolCode: school.code, schoolName: school.name);
      } else {
        _verifiedSchoolName = null;
        _verificationError = context.l10n.schoolCodeInvalid;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.schoolCodeLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.schoolCodeHint,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Code Input Field
          TextFormField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.schoolCodeLabel,
              hintText: 'SCH-1001',
              prefixIcon: const Icon(Icons.school_rounded),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              suffixIcon:
                  _verifiedSchoolName != null
                      ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      )
                      : null,
            ),
            onChanged: (val) {
              if (_verifiedSchoolName != null) {
                setState(() {
                  _verifiedSchoolName = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Verify Code Button
          PrimaryButton(
            label: l10n.schoolCodeVerifyBtn,
            isLoading: _isChecking,
            onPressed: _verifyCode,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Verification Status Banner
          if (_verifiedSchoolName != null) ...[
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🏫', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.schoolCodeValid,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _verifiedSchoolName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_verificationError != null) ...[
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _verificationError!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
