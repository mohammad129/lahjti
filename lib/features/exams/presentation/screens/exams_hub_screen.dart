import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../domain/models/exam_models.dart';
import '../providers/exams_providers.dart';

/// The central Exams & Assessment Hub screen.
class ExamsHubScreen extends ConsumerWidget {
  const ExamsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableExams = ref.watch(availableExamsProvider);
    final historyAsync = ref.watch(examHistoryProvider);
    final profile = ref.watch(learningProfileProvider);
    final ageConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isAbbas = (onboardingData.selectedTutorId ?? 'abbas') == 'abbas';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.exams,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20 * ageConfig.textScaleFactor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Assessment Overview Header Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildOverviewHeader(
                  context,
                  profile,
                  isAbbas,
                  ageConfig,
                ),
              ),
            ),

            // 2. Section Title: Milestone Exams
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'اختبارات المعالم الشهرية (Milestones)',
                  style: TextStyle(
                    fontSize: 17 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // 3. Milestone Exams List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exam = availableExams[index];
                  return _buildExamCard(context, ref, exam, isAbbas, ageConfig);
                }, childCount: availableExams.length),
              ),
            ),

            // 4. Past Assessment History Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'سجل نتائج التقييم السابقة',
                  style: TextStyle(
                    fontSize: 17 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // 5. Past History List
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'لم تقم بإجراء أي اختبار بعد. ابدأ اختبارك الأول الآن!',
                          style: TextStyle(
                            fontSize: 13 * ageConfig.textScaleFactor,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final result = history[index];
                      return _buildHistoryCard(context, ref, result, ageConfig);
                    }, childCount: history.length),
                  ),
                );
              },
              loading:
                  () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              error:
                  (err, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error loading history: $err')),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(
    BuildContext context,
    dynamic profile,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isAbbas ? AppColors.primary : AppColors.secondary)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              color: isAbbas ? AppColors.primary : AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز التقييم والاختبارات',
                  style: TextStyle(
                    fontSize: 16 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'قياس دقيق لمهاراتك الست بدون تخمين',
                  style: TextStyle(
                    fontSize: 12 * ageConfig.textScaleFactor,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.estimatedCefrLevel.code,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    WidgetRef ref,
    Exam exam,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exam.titleArabic,
                  style: TextStyle(
                    fontSize: 15 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLightVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exam.estimatedMinutes} دقيقة',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            exam.descriptionArabic,
            style: TextStyle(
              fontSize: 12 * ageConfig.textScaleFactor,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBadge('${exam.sections.length} أقسام', Colors.blue),
                  const SizedBox(width: 6),
                  _buildBadge('${exam.totalQuestions} أسئلة', Colors.purple),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(activeExamAttemptNotifierProvider.notifier)
                      .startExam(exam);
                  context.push(AppRoutes.examsSession);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'بدء الاختبار',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAbbas ? AppColors.primary : AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    ExamResult result,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final isPass = result.isPassing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.examTitleArabic,
                  style: TextStyle(
                    fontSize: 14 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'صحيح ${result.correctCount} من ${result.totalQuestions} • تم الإنجاز',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isPass ? Colors.green : Colors.orange).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.overallScore}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color:
                        isPass ? Colors.green.shade800 : Colors.orange.shade900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: () {
                  ref.read(selectedExamResultProvider.notifier).state = result;
                  context.push(AppRoutes.examsResult);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
