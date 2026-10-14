import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class StudentCodeLoginDialog extends ConsumerStatefulWidget {
  const StudentCodeLoginDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const StudentCodeLoginDialog(),
    );
  }

  @override
  ConsumerState<StudentCodeLoginDialog> createState() => _StudentCodeLoginDialogState();
}

class _StudentCodeLoginDialogState extends ConsumerState<StudentCodeLoginDialog> {
  final _codeController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithStudentCode(
        studentCode: _codeController.text.trim(),
        pin: _pinController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pop(context); // Close dialog
        context.go(AppRoutes.studentHome);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أهلاً بك يا ${user.fullName}! تم تسجيل الدخول بنجاح 🎒'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = ref.read(authNotifierProvider).errorMessage ?? 'رمز الطالب أو PIN غير صحيح';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تسجيل الدخول: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
      backgroundColor: AppColors.surfaceLight,
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🎒', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              const Text(
                'الدخول السريع بكود الطالب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              const Text(
                'أدخل رمز الطالب (ST-XXXXXX) والرمز السري المسلم لك من مدرستك',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Student Code Field
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'رمز الطالب (Student Code)',
                  hintText: 'مثال: ST-8F4K29',
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال رمز الطالب';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // PIN Field
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'الرمز السري (PIN)',
                  hintText: '4 أو 6 أرقام',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 4) {
                    return 'الرمز السري يجب أن لا يقل عن 4 أرقام';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'دخول إلى صفي',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: AppSpacing.xs),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
