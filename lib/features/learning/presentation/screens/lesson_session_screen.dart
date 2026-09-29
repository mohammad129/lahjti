import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../onboarding/domain/models/tutor_persona.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../data/curriculum/starter_curriculum.dart';
import '../../domain/models/lesson_models.dart';
import '../providers/learning_providers.dart';

/// Interactive Step-by-Step Lesson Session Screen for Lahjti.
class LessonSessionScreen extends ConsumerStatefulWidget {
  final String? lessonId;

  const LessonSessionScreen({super.key, this.lessonId});

  @override
  ConsumerState<LessonSessionScreen> createState() =>
      _LessonSessionScreenState();
}

class _LessonSessionScreenState extends ConsumerState<LessonSessionScreen> {
  int _currentStepIndex = 0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final profile = ref.watch(learningProfileProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final tutorId = onboardingData.selectedTutorId ?? 'abbas';
    final tutor = TutorPersona.tutors.firstWhere(
      (t) => t.id == tutorId,
      orElse: () => TutorPersona.tutors.first,
    );

    // Resolve Lesson
    final targetId = widget.lessonId ?? profile.currentLessonId;
    final allLessons =
        StarterCurriculum.modules.expand((m) => m.lessons).toList();
    final lesson = allLessons.firstWhere(
      (l) => l.id == targetId,
      orElse: () => allLessons.first,
    );

    final steps =
        lesson.steps.isNotEmpty
            ? lesson.steps
            : [
              LessonStep(
                id: 'step_intro',
                type: LessonStepType.introduction,
                title: lesson.title,
                titleArabic: lesson.titleArabic,
                content: lesson.description,
                contentArabic: lesson.descriptionArabic,
                targetPhrases: lesson.targetVocabulary,
              ),
              LessonStep(
                id: 'step_practice',
                type: LessonStepType.speakingActivity,
                title: 'Practical Application',
                titleArabic: 'التطبيق العملي',
                content:
                    'Practice speaking the target phrases with your AI tutor.',
                contentArabic:
                    'تدرّب على نطق واستخدام العبارات مع معلمك الذكي.',
                interactivePrompt:
                    'Say: "${lesson.targetVocabulary.isNotEmpty ? lesson.targetVocabulary.first : "Hello"}"',
              ),
            ];

    final totalSteps = steps.length;
    final stepProgress = (_currentStepIndex + 1) / totalSteps;

    if (_isCompleted) {
      return _buildCompletionView(context, lesson, tutor, isArabic);
    }

    final activeStep = steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              isArabic ? lesson.titleArabic : lesson.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isArabic
                  ? 'الخطوة ${_currentStepIndex + 1} من $totalSteps'
                  : 'Step ${_currentStepIndex + 1} of $totalSteps',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: stepProgress,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tutor Speech Bubble Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.borderRadiusLg,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: (tutor.id == 'abbas'
                              ? AppColors.primary
                              : AppColors.secondary)
                          .withValues(alpha: 0.15),
                      child: Text(
                        tutor.id == 'abbas' ? '👨‍🏫' : '👩‍🏫',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.localizedName(l10n),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? activeStep.titleArabic
                                : activeStep.title,
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

              const SizedBox(height: AppSpacing.lg),

              // Step Content Card
              Container(
                padding: AppSpacing.paddingXl,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? activeStep.contentArabic : activeStep.content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),

                    if (activeStep.targetPhrases.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        isArabic ? 'العبارات المستهدفة:' : 'Target Phrases:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...activeStep.targetPhrases.map(
                        (phrase) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                phrase,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (activeStep.interactivePrompt != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '💡',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic
                                      ? 'تحدي تفاعلي سريع:'
                                      : 'Quick Interactive Task:',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activeStep.interactivePrompt!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Bottom Action Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('lesson_session_next_btn'),
                  onPressed: () {
                    if (_currentStepIndex < totalSteps - 1) {
                      setState(() {
                        _currentStepIndex++;
                      });
                    } else {
                      // Final Step Completed!
                      ref
                          .read(learnerProgressProvider.notifier)
                          .markLessonCompleted(lesson.id);
                      setState(() {
                        _isCompleted = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStepIndex < totalSteps - 1
                        ? (isArabic ? 'التالي ➔' : 'Next ➔')
                        : (isArabic
                            ? 'إنهاء الدرس والحصول على 30 XP 🎉'
                            : 'Complete Lesson (+30 XP) 🎉'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView(
    BuildContext context,
    Lesson lesson,
    TutorPersona tutor,
    bool isArabic,
  ) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Text('🏆', style: TextStyle(fontSize: 64))),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isArabic
                    ? 'أحسنت! أكملت الدرس بنجاح'
                    : 'Great Job! Lesson Completed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isArabic ? lesson.titleArabic : lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Reward Summary Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '⚡',
                      '+30 XP',
                      isArabic ? 'النقاط المكتسبة' : 'XP Earned',
                    ),
                    _buildStatItem(
                      '⏱️',
                      '8 دقائق',
                      isArabic ? 'وقت التعلم' : 'Learning Time',
                    ),
                    _buildStatItem(
                      '🌟',
                      '100%',
                      isArabic ? 'معدل الإنجاز' : 'Accuracy',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Return Home Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('lesson_session_return_home_btn'),
                  onPressed: () {
                    context.go(AppRoutes.home);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                  ),
                  child: Text(
                    isArabic ? 'العودة للرئيسية' : 'Return to Home',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
