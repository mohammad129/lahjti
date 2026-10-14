import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/plan_models.dart';
import '../providers/plan_providers.dart';

class MistakesReviewScreen extends ConsumerStatefulWidget {
  const MistakesReviewScreen({super.key});

  @override
  ConsumerState<MistakesReviewScreen> createState() => _MistakesReviewScreenState();
}

class _MistakesReviewScreenState extends ConsumerState<MistakesReviewScreen> {
  final Set<String> _reviewedIds = {};

  @override
  Widget build(BuildContext context) {
    final mistakesAsync = ref.watch(dueMistakesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: const Text(
          'بنك أخطائي والمراجعة الذكية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.refresh(dueMistakesProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: mistakesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Text('تعذر تحميل بنك الأخطاء: $err'),
            ),
          ),
          data: (mistakes) {
            final activeMistakes = mistakes.where((m) => !_reviewedIds.contains(m.id)).toList();

            return ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Info Banner explaining Spaced Repetition (SuperMemo-2)
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🧠', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظام التكرار المتباعد (Spaced Repetition)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'نعيد لك الأسئلة التي تعثرت بها سابقاً في أوقات مدروسة علمياً لترسيخ الصواب نهائياً.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                if (activeMistakes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'رائع! لا توجد أخطاء مستحقة للمراجعة الآن',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'لقد أتقنت جميع المفاهيم السابقة بنجاح.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('العودة للرئيسية'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'الأسئلة المستحقة للمراجعة اليوم (${activeMistakes.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...activeMistakes.map((m) => _buildMistakeCard(context, m)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMistakeCard(BuildContext context, StudentMistakeItem mistake) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Source Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mistake.sourceType == 'exam' ? '📝 اختبار مدرسي' : '🎯 نشاط تدريبي',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
              ),
              const Spacer(),
              Text(
                'مراجعة رقم ${mistake.reviewCount + 1}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Question Prompt
          Text(
            mistake.questionPrompt,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Student's previous answer vs correct answer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إجابتك السابقة: ${mistake.studentAnswer}',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الصواب المعتمد: ${mistake.correctAnswer}',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          if (mistake.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 التوضيح: ${mistake.explanation}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Evaluation Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _handleReview(mistake.id, isCorrect: false),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('أحتاج تكرارها', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _handleReview(mistake.id, isCorrect: true),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('أتقنتها تماماً', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleReview(String mistakeId, {required bool isCorrect}) async {
    final repo = ref.read(planRepositoryProvider);
    await repo.reviewMistake(mistakeId, isCorrect: isCorrect, quality: isCorrect ? 5 : 2);
    setState(() {
      _reviewedIds.add(mistakeId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCorrect
                ? 'رائع! تم تباعد السؤال للفترة القادمة بنجاح 🌟'
                : 'تمت جدولة السؤال للمراجعة القريبة لترسيخه 🔁',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
