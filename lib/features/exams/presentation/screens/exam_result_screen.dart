import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../domain/models/exam_models.dart';
import '../providers/exams_providers.dart';

/// Screen presenting the transparent score evaluation, 6-skill breakdown, and actionable recommendations.
class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(selectedExamResultProvider);
    final ageConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isAbbas = (onboardingData.selectedTutorId ?? 'abbas') == 'abbas';

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('نتيجة الاختبار')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('لا توجد نتيجة اختبار للعرض.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.exams),
                child: const Text('العودة للمركز'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('تقرير النتيجة والتقييم'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.exams),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Score Hero Card
              _buildScoreHeroCard(result, isAbbas, ageConfig),
              const SizedBox(height: AppSpacing.lg),

              // 2. 6-Skill Performance Breakdown
              Text(
                'تحليل المهارات الست',
                style: TextStyle(
                  fontSize: 17 * ageConfig.textScaleFactor,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSkillBreakdownCard(result, ageConfig),
              const SizedBox(height: AppSpacing.lg),

              // 3. Strengths Card
              _buildStrengthsCard(result, ageConfig),
              const SizedBox(height: AppSpacing.md),

              // 4. Areas for Improvement (if any)
              if (result.areasForImprovementArabic.isNotEmpty) ...[
                _buildImprovementCard(result, ageConfig),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 5. Actionable Recommendations
              Text(
                'التوصيات التعليمية الذكية',
                style: TextStyle(
                  fontSize: 17 * ageConfig.textScaleFactor,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...result.recommendations.map(
                (rec) =>
                    _buildRecommendationTile(context, rec, isAbbas, ageConfig),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6. Primary Action: Practice Weak Areas with Abbas / Dunya
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.tutorConversation),
                icon: const Icon(Icons.record_voice_over_rounded),
                label: Text(
                  isAbbas
                      ? 'تطبيق نقاط الضعف مع عباس'
                      : 'تطبيق نقاط الضعف مع دنيا',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAbbas ? AppColors.primary : AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Secondary Action: Return to Hub
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.exams),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'العودة لمركز الاختبارات',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeroCard(
    ExamResult result,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final score = result.overallScore;
    final isPass = result.isPassing;

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.examTitleArabic,
                  style: TextStyle(
                    fontSize: 15 * ageConfig.textScaleFactor,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'المستوى: ${result.estimatedCefrLevel.code}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isPass ? Colors.green : Colors.orange).withValues(
                alpha: 0.1,
              ),
              border: Border.all(
                color: isPass ? Colors.green : Colors.orange,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '$score%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color:
                      isPass ? Colors.green.shade800 : Colors.orange.shade900,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isPass
                ? 'أداء رائع وناجح! 🎉'
                : 'محاولة جيدة، تحتاج لمزيد من الممارسة 💡',
            style: TextStyle(
              fontSize: 16 * ageConfig.textScaleFactor,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أجبت بشكل صحيح على ${result.correctCount} من إجمالي ${result.totalQuestions} سؤال.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBreakdownCard(
    ExamResult result,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children:
            result.skillScores.map((score) {
              final isHigh = score.scorePercentage >= 75;
              final color =
                  isHigh
                      ? Colors.green
                      : (score.scorePercentage >= 50
                          ? Colors.blue
                          : Colors.orange);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          score.skill.nameArabic,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${score.scorePercentage}% (${score.pointsEarned}/${score.pointsPossible})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score.scorePercentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildStrengthsCard(ExamResult result, AgeAdaptiveUiConfig ageConfig) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نقاط القوة والإتقان:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...result.strengthsArabic.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $s',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard(
    ExamResult result,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: Colors.orange.shade800,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مجالات تحتاج لمزيد من الممارسة:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...result.areasForImprovementArabic.map(
            (area) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $area',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(
    BuildContext context,
    ExamRecommendation rec,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isAbbas ? AppColors.primary : AppColors.secondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: isAbbas ? AppColors.primary : AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.titleArabic,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.rationaleArabic,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            onPressed: () {
              if (rec.targetRoute == '/tutor') {
                context.push(AppRoutes.tutorConversation);
              } else if (rec.targetRoute == '/vocabulary') {
                context.push(AppRoutes.vocabulary);
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ],
      ),
    );
  }
}
