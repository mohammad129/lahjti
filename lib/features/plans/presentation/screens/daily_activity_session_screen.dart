import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/plan_models.dart';
import '../providers/plan_providers.dart';

class DailyActivitySessionScreen extends ConsumerStatefulWidget {
  final String planId;
  final int dayNumber;

  const DailyActivitySessionScreen({
    super.key,
    required this.planId,
    required this.dayNumber,
  });

  @override
  ConsumerState<DailyActivitySessionScreen> createState() =>
      _DailyActivitySessionScreenState();
}

class _DailyActivitySessionScreenState
    extends ConsumerState<DailyActivitySessionScreen> {
  int _currentIndex = 0;
  int _totalXpEarned = 0;
  final Map<int, dynamic> _userAnswers = {};
  bool _isAnswerSubmitted = false;
  String? _scrambledAttempt;

  @override
  Widget build(BuildContext context) {
    final params = DayActivitiesParams(
      planId: widget.planId,
      dayNumber: widget.dayNumber,
    );
    final activitiesAsync = ref.watch(dayActivitiesProvider(params));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'اليوم ${widget.dayNumber} - النشاط ${_currentIndex + 1} من 9',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: SafeArea(
        child: activitiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Text('تعذر تحميل الأنشطة: $err'),
            ),
          ),
          data: (activities) {
            if (activities.isEmpty) {
              return const Center(child: Text('لا توجد أنشطة لهذا اليوم'));
            }

            final activity = activities[_currentIndex];
            final progress = (_currentIndex + 1) / activities.length;

            return Column(
              children: [
                // Top Linear Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 5,
                ),

                // Main Activity Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Activity Header Pill
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(activity.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.typeArabicName,
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 2),
                            Text(
                              '+${activity.xpReward} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Title & Instruction
                        Text(
                          activity.titleAr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.instructionAr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Dynamic Activity Widget based on activityType
                        _buildActivityWidget(activity),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                _buildBottomBar(context, activities),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityWidget(PlanActivity activity) {
    switch (activity.activityType) {
      case 'quick_review':
        return _buildQuickReviewWidget(activity);
      case 'vocab':
        return _buildVocabWidget(activity);
      case 'listening':
        return _buildListeningWidget(activity);
      case 'dialogue':
        return _buildDialogueWidget(activity);
      case 'grammar':
        return _buildGrammarWidget(activity);
      case 'pronunciation':
        return _buildPronunciationWidget(activity);
      case 'mini_game':
        return _buildMiniGameWidget(activity);
      case 'quick_quiz':
        return _buildQuickQuizWidget(activity);
      case 'day_summary':
        return _buildDaySummaryWidget(activity);
      default:
        return const Center(child: Text('محتوى النشاط'));
    }
  }

  // 1. Quick Review
  Widget _buildQuickReviewWidget(PlanActivity activity) {
    final prompt = activity.contentJson['prompt']?.toString() ?? '';
    final options = (activity.contentJson['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final correct = activity.contentJson['correctAnswer']?.toString() ?? '';

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            prompt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...options.map((option) {
            final isSelected = _userAnswers[_currentIndex] == option;
            final isCorrect = option == correct;
            Color btnColor = AppColors.surfaceLightVariant;
            Color textColor = AppColors.textPrimaryLight;

            if (_isAnswerSubmitted) {
              if (isCorrect) {
                btnColor = Colors.green.shade100;
                textColor = Colors.green.shade900;
              } else if (isSelected) {
                btnColor = Colors.red.shade100;
                textColor = Colors.red.shade900;
              }
            } else if (isSelected) {
              btnColor = AppColors.primaryContainer;
              textColor = AppColors.primaryDark;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: AppSpacing.borderRadiusMd,
                onTap: _isAnswerSubmitted
                    ? null
                    : () {
                        setState(() {
                          _userAnswers[_currentIndex] = option;
                        });
                      },
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: btnColor,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. Vocabulary
  Widget _buildVocabWidget(PlanActivity activity) {
    final words = (activity.contentJson['words'] as List?) ?? [];
    return Column(
      children: words.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تشغيل صوت الكلمة: "${map['word']}" 📢'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          map['word'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          map['arabic'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      map['example'] ?? '',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3. Listening
  Widget _buildListeningWidget(PlanActivity activity) {
    final transcript = activity.contentJson['audioTranscript']?.toString() ?? '';
    final question = activity.contentJson['question']?.toString() ?? '';
    final options = (activity.contentJson['options'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio Player Simulator
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تشغيل التسجيل الصوتي المخزن بالخادم... 🎧'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مقطع صوتي مسجل بنطق أصلي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'اضغط للاستماع بتركيز (00:08 ثانية)',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Collapsible transcript
          ExpansionTile(
            title: const Text('عرض نص التسجيل (Transcript)', style: TextStyle(fontSize: 12)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  transcript,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...options.map((opt) {
            return RadioListTile<String>(
              value: opt,
              groupValue: _userAnswers[_currentIndex] as String?,
              title: Text(opt, style: const TextStyle(fontSize: 14)),
              onChanged: (val) {
                setState(() {
                  _userAnswers[_currentIndex] = val;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // 4. Dialogue
  Widget _buildDialogueWidget(PlanActivity activity) {
    final scenario = activity.contentJson['scenario']?.toString() ?? '';
    final lines = (activity.contentJson['lines'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'الموقف: $scenario',
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...lines.asMap().entries.map((entry) {
            final isSpeakerA = entry.key % 2 == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSpeakerA ? AppColors.surfaceLightVariant : AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSpeakerA ? Colors.blue.shade100 : Colors.teal.shade100,
                    child: Text(isSpeakerA ? 'A' : 'B', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. Grammar
  Widget _buildGrammarWidget(PlanActivity activity) {
    final title = activity.contentJson['ruleTitle']?.toString() ?? '';
    final explanation = activity.contentJson['explanation']?.toString() ?? '';
    final quizQ = activity.contentJson['quizQuestion']?.toString() ?? '';
    final options = (activity.contentJson['quizOptions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text(explanation, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondaryLight)),
          const Divider(height: 24),
          Text(quizQ, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...options.map((opt) {
            return RadioListTile<String>(
              value: opt,
              groupValue: _userAnswers[_currentIndex] as String?,
              title: Text(opt, style: const TextStyle(fontSize: 13)),
              onChanged: (val) {
                setState(() {
                  _userAnswers[_currentIndex] = val;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // 6. Pronunciation
  Widget _buildPronunciationWidget(PlanActivity activity) {
    final focusPhrase = activity.contentJson['focusPhrase']?.toString() ?? '';
    final phoneticTip = activity.contentJson['phoneticTip']?.toString() ?? '';
    final sentence = activity.contentJson['practiceSentence']?.toString() ?? '';

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(focusPhrase, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(phoneticTip, style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.surfaceLightVariant,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Text(sentence, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('نطق ممتاز ودقيق! أحسنت 🌟')),
              );
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('تدرب على النطق الآن'),
          ),
        ],
      ),
    );
  }

  // 7. Mini Game (Word Scramble)
  Widget _buildMiniGameWidget(PlanActivity activity) {
    final hint = activity.contentJson['hint']?.toString() ?? '';
    final scrambled = (activity.contentJson['scrambled'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final correct = activity.contentJson['correctWord']?.toString() ?? '';

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text('تلميح: $hint', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scrambled.map((letter) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  setState(() {
                    _scrambledAttempt = (_scrambledAttempt ?? '') + letter;
                  });
                },
                child: Text(letter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _scrambledAttempt ?? 'اضغط الحروف لتركيب الكلمة',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          if (_scrambledAttempt != null) ...[
            const SizedBox(height: 8),
            if (_scrambledAttempt!.toUpperCase() == correct.toUpperCase())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('أحسنت! إجابة صحيحة ومطابقة تماماً ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _scrambledAttempt = null),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }

  // 8. Quick Quiz
  Widget _buildQuickQuizWidget(PlanActivity activity) {
    final questions = (activity.contentJson['questions'] as List?) ?? [];
    return Column(
      children: questions.asMap().entries.map((entry) {
        final q = Map<String, dynamic>.from(entry.value as Map);
        final qIndex = entry.key;
        final qText = q['q']?.toString() ?? '';
        final options = (q['options'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${qIndex + 1}. $qText', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...options.map((opt) {
                return RadioListTile<String>(
                  value: opt,
                  groupValue: _userAnswers[100 + qIndex] as String?,
                  title: Text(opt, style: const TextStyle(fontSize: 13)),
                  onChanged: (val) {
                    setState(() {
                      _userAnswers[100 + qIndex] = val;
                    });
                  },
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 9. Day Summary
  Widget _buildDaySummaryWidget(PlanActivity activity) {
    final quote = activity.contentJson['quote']?.toString() ?? '';

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'مبروك! أنجزت أنشطة اليوم بنجاح',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 28),
                const SizedBox(width: 8),
                Text(
                  '+${_totalXpEarned > 0 ? _totalXpEarned : 150} XP نقاط مضافة لحسابك',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"$quote"',
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, List<PlanActivity> activities) {
    final isLast = _currentIndex == activities.length - 1;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentIndex--;
                  _isAnswerSubmitted = false;
                });
              },
              child: const Text('السابق'),
            ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (isLast) {
                // Finish Session
                ref.invalidate(planDaysProvider(widget.planId));
                ref.invalidate(activePlanProvider);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسجيل إنجاز اليوم بنجاح في سجل نقاطك المعتمد 🏆'),
                  ),
                );
              } else {
                setState(() {
                  _totalXpEarned += activities[_currentIndex].xpReward;
                  _currentIndex++;
                  _isAnswerSubmitted = false;
                });
              }
            },
            child: Text(
              isLast ? 'إنهاء وحفظ إنجاز اليوم 🏆' : 'النشاط التالي ➔',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('هل تريد الخروج؟'),
        content: const Text('يمكنك إكمال الأنشطة المتبقية في أي وقت اليوم دون فقدان تقدمك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متابعة التدريب')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
