import '../../../placement/domain/models/cefr_level.dart';
import '../models/learner_progress.dart';
import '../models/learning_profile.dart';
import '../models/learning_recommendation.dart';
import '../models/learning_skill.dart';
import '../models/lesson_models.dart';
import '../models/vocabulary_item.dart';

/// Result of evaluating a student's practice exercise or lesson performance.
class AdaptationDecision {
  final String action; // 'advance', 'reinforce', 'review'
  final String feedbackArabic;
  final String feedbackEnglish;
  final bool shouldAdvanceDifficulty;
  final LearningSkill? focusSkill;

  const AdaptationDecision({
    required this.action,
    required this.feedbackArabic,
    required this.feedbackEnglish,
    this.shouldAdvanceDifficulty = false,
    this.focusSkill,
  });
}

/// Deterministic, testable core engine for adaptive difficulty and learning recommendations.
class AdaptiveLearningEngine {
  const AdaptiveLearningEngine();

  /// Evaluates learner performance on an exercise or session and outputs deterministic adaptation decisions.
  AdaptationDecision evaluatePerformance({
    required double accuracy, // 0.0 to 1.0
    required List<String> detectedErrors,
    required CefrLevel currentLevel,
    LearningSkill primarySkill = LearningSkill.comprehension,
  }) {
    if (accuracy >= 0.80) {
      return AdaptationDecision(
        action: 'advance',
        feedbackArabic: 'أداء متميز ورائع! جاهز للانتقال للخطوة التالية 🚀',
        feedbackEnglish:
            'Outstanding performance! Ready for the next challenge.',
        shouldAdvanceDifficulty: true,
      );
    } else if (accuracy >= 0.50) {
      return AdaptationDecision(
        action: 'reinforce',
        feedbackArabic: 'محاولة جيدة! خلينا نعزز هذا المفهوم كمان شوي 👍',
        feedbackEnglish:
            'Good effort! Let us reinforce this concept a bit more.',
        shouldAdvanceDifficulty: false,
        focusSkill: primarySkill,
      );
    } else {
      return AdaptationDecision(
        action: 'review',
        feedbackArabic: 'ولا يهمك، خلينا نراجع الأساسيات خطوة بخطوة 🌟',
        feedbackEnglish:
            'No worries, let us review the fundamentals step by step.',
        shouldAdvanceDifficulty: false,
        focusSkill: primarySkill,
      );
    }
  }

  /// Calculates the next spaced repetition interval and updated mastery status for a vocabulary item.
  VocabularyItem computeNextReview({
    required VocabularyItem item,
    required bool wasCorrect,
    required DateTime now,
  }) {
    if (!wasCorrect) {
      return item.copyWith(
        correctStreak: 0,
        totalAttempts: item.totalAttempts + 1,
        incorrectAttempts: item.incorrectAttempts + 1,
        status: MasteryStatus.learning,
        lastReviewed: now,
        nextReview: now.add(const Duration(hours: 4)),
      );
    }

    final newStreak = item.correctStreak + 1;
    Duration interval;
    MasteryStatus newStatus;

    switch (newStreak) {
      case 1:
        interval = const Duration(days: 1);
        newStatus = MasteryStatus.learning;
        break;
      case 2:
        interval = const Duration(days: 3);
        newStatus = MasteryStatus.reviewing;
        break;
      case 3:
        interval = const Duration(days: 7);
        newStatus = MasteryStatus.reviewing;
        break;
      case 4:
        interval = const Duration(days: 14);
        newStatus = MasteryStatus.mastered;
        break;
      default:
        final days = (14 * (newStreak - 3)).clamp(14, 60);
        interval = Duration(days: days);
        newStatus = MasteryStatus.mastered;
        break;
    }

    return item.copyWith(
      correctStreak: newStreak,
      totalAttempts: item.totalAttempts + 1,
      status: newStatus,
      lastReviewed: now,
      nextReview: now.add(interval),
    );
  }

  /// Deterministically decides the top pedagogical recommendation for the learner's next action.
  LearningRecommendation generateDailyRecommendation({
    required LearningProfile profile,
    required LearnerProgress progress,
    required List<VocabularyItem> vocabularyItems,
    required List<Lesson> availableLessons,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // 1. Spaced Repetition Queue check (Highest urgency if items are due)
    final dueVocab =
        vocabularyItems.where((v) => v.isDueForReview(now)).toList();
    if (dueVocab.isNotEmpty) {
      return LearningRecommendation(
        type: RecommendationType.reviewVocabulary,
        titleArabic: 'مراجعة المفردات المستحقة',
        titleEnglish: 'Review Due Vocabulary',
        subtitleArabic:
            'لديك ${dueVocab.length} كلمات تحتاج لتثبيت وتكرار متباعد.',
        subtitleEnglish:
            'You have ${dueVocab.length} words due for spaced review.',
        actionRoute: '/vocabulary',
        urgencyScore: 90,
      );
    }

    // 2. Active In-Progress Lesson
    if (availableLessons.isNotEmpty) {
      final currentLesson = availableLessons.firstWhere(
        (l) => l.id == profile.currentLessonId,
        orElse: () => availableLessons.first,
      );

      if (!progress.isLessonCompleted(currentLesson.id)) {
        return LearningRecommendation(
          type: RecommendationType.continueLesson,
          titleArabic: 'متابعة درس: ${currentLesson.titleArabic}',
          titleEnglish: 'Continue: ${currentLesson.title}',
          subtitleArabic: currentLesson.descriptionArabic,
          subtitleEnglish: currentLesson.description,
          targetLessonId: currentLesson.id,
          targetSkill: currentLesson.primarySkill,
          actionRoute: '/learning',
          urgencyScore: 80,
        );
      }
    }

    // 3. Weak Skill Targeted Practice
    if (profile.grammarScore < 60) {
      return const LearningRecommendation(
        type: RecommendationType.practiceWeakSkill,
        titleArabic: 'تقوية مهارة القواعد',
        titleEnglish: 'Grammar Reinforcement',
        subtitleArabic: 'تدريب مخصص لتقوية التراكيب وأزمنة الأفعال.',
        subtitleEnglish:
            'Targeted practice for sentence structures and tenses.',
        targetSkill: LearningSkill.grammar,
        actionRoute: '/tutor',
        urgencyScore: 70,
      );
    }

    // 4. Default: Conversational Practice with AI Tutor
    return const LearningRecommendation(
      type: RecommendationType.startConversation,
      titleArabic: 'محادثة حرة مع معلمك الذكي',
      titleEnglish: 'Conversation Practice',
      subtitleArabic: 'تطبيق ما تعلمته في محادثة واقعية ممتعة ومحفزة.',
      subtitleEnglish: 'Apply what you learned in a natural friendly chat.',
      actionRoute: '/tutor',
      urgencyScore: 50,
    );
  }
}
