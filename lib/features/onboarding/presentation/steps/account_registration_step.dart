import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Step 6: Account Registration Screen
class AccountRegistrationStep extends ConsumerStatefulWidget {
  const AccountRegistrationStep({super.key});

  @override
  ConsumerState<AccountRegistrationStep> createState() =>
      _AccountRegistrationStepState();
}

class _AccountRegistrationStepState
    extends ConsumerState<AccountRegistrationStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider).data;
    if (data.registeredName != null) {
      _nameController.text = data.registeredName!;
    }
    if (data.registeredEmail != null) {
      _emailController.text = data.registeredEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.valNameRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.valEmailInvalid;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return context.l10n.valEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 12) {
      return context.l10n.valPasswordWeak;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != _passwordController.text) {
      return context.l10n.valPasswordsDoNotMatch;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final user = await ref
        .read(authNotifierProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (user != null) {
        ref.read(onboardingProvider.notifier).setRegisteredUser(user);
        ref.read(onboardingProvider.notifier).nextStep();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.registerTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.registerSubtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Full Name
            AppTextField(
              label: l10n.fullName,
              hintText: l10n.fullNameHint,
              controller: _nameController,
              validator: _validateName,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Email
            AppTextField(
              label: l10n.email,
              hintText: l10n.emailHint,
              controller: _emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Password
            AppTextField(
              label: l10n.password,
              hintText: l10n.passwordHint,
              controller: _passwordController,
              validator: _validatePassword,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirm Password
            AppTextField(
              label: l10n.confirmPassword,
              hintText: l10n.confirmPasswordHint,
              controller: _confirmPasswordController,
              validator: _validateConfirmPassword,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Form Submit Button
            PrimaryButton(
              label: l10n.continueText,
              isLoading: _isSubmitting,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
