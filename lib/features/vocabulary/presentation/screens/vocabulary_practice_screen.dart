import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lahjti/core/routing/app_routes.dart';
import 'package:lahjti/core/theme/app_colors.dart';
import 'package:lahjti/core/theme/app_spacing.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/tutor/presentation/providers/voice_session_provider.dart';
import 'package:lahjti/features/vocabulary/domain/models/vocabulary_practice_models.dart';
import 'package:lahjti/features/vocabulary/presentation/providers/vocabulary_providers.dart';

/// The interactive quiz and spaced-review practice session screen.
class VocabularyPracticeScreen extends ConsumerStatefulWidget {
  const VocabularyPracticeScreen({super.key});

  @override
  ConsumerState<VocabularyPracticeScreen> createState() =>
      _VocabularyPracticeScreenState();
}

class _VocabularyPracticeScreenState
    extends ConsumerState<VocabularyPracticeScreen> {
  bool _isListening = false;
  String _recognizedSpeech = '';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vocabularyPracticeNotifierProvider);
    final ageConfig = ref.watch(ageAdaptiveUiConfigProvider);
    final onboardingData = ref.watch(onboardingProvider.select((s) => s.data));
    final isAbbas = (onboardingData.selectedTutorId ?? 'abbas') == 'abbas';

    if (session.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('التدريب الذكي'), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'لا توجد أسئلة تدريب حالياً!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('العودة للمفردات'),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isCompleted) {
      return _buildCompletionScreen(context, session, isAbbas, ageConfig);
    }

    final currentQ = session.currentQuestion!;
    final progressVal = (session.currentIndex + 1) / session.totalQuestions;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'سؤال ${session.currentIndex + 1} من ${session.totalQuestions}',
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
            value: progressVal,
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
              // 1. Practice Mode Badge
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isAbbas ? AppColors.primary : AppColors.secondary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getModeIcon(currentQ.mode),
                        size: 16,
                        color:
                            isAbbas ? AppColors.primary : AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentQ.mode.nameArabic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isAbbas ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Question Prompt Card
              _buildPromptCard(context, ref, currentQ, isAbbas, ageConfig),
              const SizedBox(height: AppSpacing.lg),

              // 3. Mode-specific Options / Speaking area
              if (currentQ.mode == PracticeMode.speakingProduction)
                _buildSpeakingArea(
                  context,
                  ref,
                  currentQ,
                  session,
                  isAbbas,
                  ageConfig,
                )
              else
                _buildMultipleChoiceOptions(
                  ref,
                  currentQ,
                  session,
                  isAbbas,
                  ageConfig,
                ),

              const SizedBox(height: AppSpacing.lg),

              // 4. Explanation box if answered
              if (session.isAnswerSubmitted == true) ...[
                _buildExplanationCard(currentQ, session.results.last.isCorrect),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child:
            session.isAnswerSubmitted == true
                ? ElevatedButton(
                  onPressed: () {
                    ref
                        .read(vocabularyPracticeNotifierProvider.notifier)
                        .nextQuestion();
                    setState(() {
                      _recognizedSpeech = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAbbas ? AppColors.primary : AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.currentIndex + 1 < session.totalQuestions
                            ? 'السؤال التالي'
                            : 'عرض النتيجة 🎉',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                )
                : ElevatedButton(
                  onPressed:
                      session.selectedOptionIndex != null
                          ? () {
                            ref
                                .read(
                                  vocabularyPracticeNotifierProvider.notifier,
                                )
                                .submitAnswer();
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAbbas ? AppColors.primary : AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تأكيد الإجابة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
      ),
    );
  }

  Widget _buildPromptCard(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion q,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final tts = ref.watch(textToSpeechServiceProvider);

    return Container(
      padding: EdgeInsets.all(ageConfig.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(ageConfig.borderRadius),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                q.promptSubtext ?? 'اختر الإجابة الصحيحة:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (q.mode != PracticeMode.wordSelection)
                IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: 'استمع للنطق',
                  onPressed: () {
                    tts.speak(text: q.targetItem.term, languageCode: 'en');
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.promptText,
            style: TextStyle(
              fontSize: 22 * ageConfig.textScaleFactor,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (q.targetItem.phonetic != null &&
              q.mode == PracticeMode.speakingProduction) ...[
            const SizedBox(height: 4),
            Text(
              q.targetItem.phonetic!,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(
    WidgetRef ref,
    PracticeQuestion q,
    PracticeSessionState session,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    return Column(
      children: List.generate(q.options.length, (idx) {
        final option = q.options[idx];
        final isSelected = session.selectedOptionIndex == idx;
        final isSubmitted = session.isAnswerSubmitted == true;
        final isCorrectOption = idx == q.correctOptionIndex;

        Color borderColor = AppColors.borderLight;
        Color bgColor = AppColors.surfaceLight;
        Color textColor = AppColors.textPrimaryLight;

        if (isSubmitted) {
          if (isCorrectOption) {
            borderColor = Colors.green;
            bgColor = Colors.green.withValues(alpha: 0.1);
            textColor = Colors.green.shade800;
          } else if (isSelected && !isCorrectOption) {
            borderColor = Colors.red;
            bgColor = Colors.red.withValues(alpha: 0.1);
            textColor = Colors.red.shade800;
          }
        } else if (isSelected) {
          borderColor = isAbbas ? AppColors.primary : AppColors.secondary;
          bgColor = (isAbbas ? AppColors.primary : AppColors.secondary)
              .withValues(alpha: 0.08);
          textColor = isAbbas ? AppColors.primary : AppColors.secondary;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap:
                isSubmitted
                    ? null
                    : () {
                      ref
                          .read(vocabularyPracticeNotifierProvider.notifier)
                          .selectOption(idx);
                    },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: ageConfig.minTouchTargetHeight > 48 ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
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
                              ? borderColor
                              : AppColors.surfaceLightVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + idx), // A, B, C, D
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
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isSubmitted && isCorrectOption)
                    const Icon(Icons.check_circle_rounded, color: Colors.green)
                  else if (isSubmitted && isSelected && !isCorrectOption)
                    const Icon(Icons.cancel_rounded, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpeakingArea(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion q,
    PracticeSessionState session,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final stt = ref.watch(speechToTextServiceProvider);
    final isSubmitted = session.isAnswerSubmitted == true;

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
            'اضغط على الميكروفون وتحدث بالإنجليزية:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap:
                isSubmitted
                    ? null
                    : () async {
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
                            },
                          );
                        }
                      }
                    },
            child: Container(
              width: 80,
              height: 80,
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
                    spreadRadius: _isListening ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_recognizedSpeech.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLightVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ما تم سماعه: $_recognizedSpeech',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (!isSubmitted)
            ElevatedButton.icon(
              onPressed:
                  _recognizedSpeech.isNotEmpty &&
                          _recognizedSpeech != 'جاري الاستماع...'
                      ? () {
                        ref
                            .read(vocabularyPracticeNotifierProvider.notifier)
                            .evaluateSpokenText(_recognizedSpeech);
                      }
                      : null,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تقييم النطق'),
            ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(PracticeQuestion q, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isCorrect
                ? Colors.green.withValues(alpha: 0.08)
                : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCorrect
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isCorrect ? Colors.green : Colors.orange.shade800,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'إجابة ممتازة! 👏' : 'توضيح تربوي 💡',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color:
                      isCorrect
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.explanationArabic,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(
    BuildContext context,
    PracticeSessionState session,
    bool isAbbas,
    AgeAdaptiveUiConfig ageConfig,
  ) {
    final score = session.scorePercentage.round();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'اكتمل التدريب بنجاح! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'تم تحديث جدول التكرار المتباعد لكلماتك تلقائياً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14 * ageConfig.textScaleFactor,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Score Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('النتيجة', '$score%', AppColors.primary),
                    _buildStatCol(
                      'صحيح',
                      '${session.correctCount}',
                      Colors.green,
                    ),
                    _buildStatCol(
                      'يحتاج تدريب',
                      '${session.incorrectCount}',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.tutorConversation),
                icon: const Icon(Icons.record_voice_over_rounded),
                label: Text(
                  isAbbas ? 'تطبيق الكلمات مع عباس' : 'تطبيق الكلمات مع دنيا',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'العودة للمفردات',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  IconData _getModeIcon(PracticeMode mode) {
    switch (mode) {
      case PracticeMode.recognizeMeaning:
        return Icons.translate_rounded;
      case PracticeMode.wordSelection:
        return Icons.checklist_rounded;
      case PracticeMode.sentenceCompletion:
        return Icons.short_text_rounded;
      case PracticeMode.speakingProduction:
        return Icons.mic_rounded;
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('مغادرة التدريب؟'),
            content: const Text('هل أنت متأكد من مغادرة جلسة التدريب الحالية؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('متابعة'),
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
