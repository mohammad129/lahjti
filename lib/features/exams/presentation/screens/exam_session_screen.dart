import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../tutor/presentation/providers/voice_session_provider.dart';
import '../../../vocabulary/presentation/providers/vocabulary_providers.dart';
import '../../domain/models/exam_models.dart';
import '../providers/exams_providers.dart';

/// Interactive Exam Session screen presenting multi-modal assessment questions.
class ExamSessionScreen extends ConsumerStatefulWidget {
  const ExamSessionScreen({super.key});

  @override
  ConsumerState<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends ConsumerState<ExamSessionScreen> {
  bool _isListening = false;
  String _recognizedSpeech = '';

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(activeExamAttemptNotifierProvider);
    final ageConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isAbbas = (onboardingData.selectedTutorId ?? 'abbas') == 'abbas';

    if (attempt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('جلسة الاختبار')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('لا يوجد اختبار نشط حالياً.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('العودة للمركز'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQ = attempt.currentQuestion;
    final currentSec = attempt.currentSection;
    if (currentQ == null || currentSec == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progressRatio =
        attempt.currentGlobalQuestionNumber / attempt.totalQuestions;
    final currentAnswer = attempt.answers[currentQ.id];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'سؤال ${attempt.currentGlobalQuestionNumber} من ${attempt.totalQuestions}',
          style: TextStyle(
            fontSize: 16 * ageConfig.textScaleFactor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _confirmExit(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAbbas ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Section Header & Skill Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isAbbas ? AppColors.primary : AppColors.secondary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentSec.titleArabic,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isAbbas ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                  ),
                  Text(
                    '${currentQ.points} درجات',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Reading Passage (if applicable)
              if (currentQ.passageText != null) ...[
                _buildPassageCard(currentQ.passageText!),
                const SizedBox(height: AppSpacing.md),
              ],

              // 3. Listening Audio Player (if applicable)
              if (currentQ.textToSpeak != null) ...[
                _buildListeningPlayer(ref, currentQ.textToSpeak!, isAbbas),
                const SizedBox(height: AppSpacing.md),
              ],

              // 4. Question Prompt Card
              _buildPromptCard(currentQ, ageConfig),
              const SizedBox(height: AppSpacing.lg),

              // 5. Answer Input: Speaking or Multiple Choice
              if (currentQ.type == ExamQuestionType.speakingProduction)
                _buildSpeakingInput(ref, currentQ, currentAnswer, isAbbas)
              else
                _buildMultipleChoiceOptions(
                  ref,
                  currentQ,
                  currentAnswer,
                  isAbbas,
                  ageConfig,
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(
        context,
        ref,
        attempt,
        isAbbas,
      ),
    );
  }

  Widget _buildPassageCard(String passage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'اقرأ النص التالي:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            passage,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningPlayer(
    WidgetRef ref,
    String textToSpeak,
    bool isAbbas,
  ) {
    final tts = ref.watch(textToSpeechServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isAbbas ? AppColors.primary : AppColors.secondary).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isAbbas ? AppColors.primary : AppColors.secondary).withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () {
              tts.speak(text: textToSpeak, languageCode: 'en');
            },
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor:
                  isAbbas ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استمع للمقطع الصوتي',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  'يمكنك الاستماع أكثر من مرة للإجابة بدقة.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(ExamQuestion q, AgeAdaptiveUiConfig ageConfig) {
    return Container(
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.promptSubtext != null) ...[
            Text(
              q.promptSubtext!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            q.promptText,
            style: TextStyle(
              fontSize: 18 * ageConfig.textScaleFactor,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(
    WidgetRef ref,
    ExamQuestion q,
    ExamAnswer? currentAnswer,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Column(
      children: List.generate(q.options.length, (idx) {
        final option = q.options[idx];
        final isSelected = currentAnswer?.selectedOptionIndex == idx;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              ref
                  .read(activeExamAttemptNotifierProvider.notifier)
                  .selectOption(idx);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: ageConfig.minTouchTargetHeight > 48 ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? (isAbbas ? AppColors.primary : AppColors.secondary)
                            .withValues(alpha: 0.08)
                        : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? (isAbbas ? AppColors.primary : AppColors.secondary)
                          : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (isAbbas
                                  ? AppColors.primary
                                  : AppColors.secondary)
                              : AppColors.surfaceLightVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + idx),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15 * ageConfig.textScaleFactor,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected
                                ? (isAbbas
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpeakingInput(
    WidgetRef ref,
    ExamQuestion q,
    ExamAnswer? currentAnswer,
    bool isAbbas,
  ) {
    final stt = ref.watch(speechToTextServiceProvider);
    final recordedText = currentAnswer?.spokenText ?? _recognizedSpeech;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Text(
            'اضغط للتسجيل وانطق إجابتك بوضوح:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                await stt.stopListening();
                setState(() => _isListening = false);
              } else {
                final available = await stt.initialize();
                if (available) {
                  setState(() {
                    _isListening = true;
                    _recognizedSpeech = 'جاري الاستماع...';
                  });
                  await stt.startListening(
                    languageCode: 'en',
                    onResult: (text, isFinal) {
                      setState(() {
                        _recognizedSpeech = text;
                      });
                      ref
                          .read(activeExamAttemptNotifierProvider.notifier)
                          .recordSpokenAnswer(text);
                    },
                  );
                }
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isListening
                        ? Colors.redAccent
                        : (isAbbas ? AppColors.primary : AppColors.secondary),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : AppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (recordedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLightVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'تم تسجيل: $recordedText',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    WidgetRef ref,
    ExamAttemptState attempt,
    bool isAbbas,
  ) {
    final notifier = ref.read(activeExamAttemptNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous / Skip
          Row(
            children: [
              if (attempt.currentGlobalQuestionNumber > 1)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'السابق',
                  onPressed: () {
                    notifier.previousQuestion();
                    setState(() => _recognizedSpeech = '');
                  },
                ),
              TextButton(
                onPressed: () {
                  notifier.skipQuestion();
                  setState(() => _recognizedSpeech = '');
                },
                child: const Text('تخطي'),
              ),
            ],
          ),

          // Next or Submit
          if (attempt.isLastQuestion)
            ElevatedButton(
              onPressed: () async {
                final result = await notifier.submitExam();
                if (result != null && context.mounted) {
                  context.pushReplacement(AppRoutes.examsResult);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAbbas ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  attempt.isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'إنهاء وتسليم',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                notifier.nextQuestion();
                setState(() => _recognizedSpeech = '');
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                'التالي',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAbbas ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('مغادرة الاختبار؟'),
            content: const Text(
              'هل أنت متأكد من مغادرة جلسة الاختبار الحالية؟ قد تفقد إجاباتك غير المسلمة.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('متابعة الاختبار'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'مغادرة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
