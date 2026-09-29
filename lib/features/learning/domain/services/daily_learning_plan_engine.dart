import '../../../account/domain/models/account_context.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../models/daily_learning_task.dart';
import '../models/learner_progress.dart';
import '../models/learning_profile.dart';
import '../models/learning_skill.dart';
import '../models/lesson_models.dart';
import '../models/vocabulary_item.dart';

/// Result container bundling the generated daily tasks and top recommended action.
class DailyPlanResult {
  final List<DailyLearningTask> tasks;
  final DailyLearningTask recommendedTask;
  final Lesson? currentLesson;
  final int dueVocabularyCount;
  final int completedTasksCount;
  final int totalTasksCount;
  final double completionRatio;
  final bool isDailyGoalCompleted;
  final int totalXpAvailable;

  const DailyPlanResult({
    required this.tasks,
    required this.recommendedTask,
    this.currentLesson,
    required this.dueVocabularyCount,
    required this.completedTasksCount,
    required this.totalTasksCount,
    required this.completionRatio,
    required this.isDailyGoalCompleted,
    required this.totalXpAvailable,
  });
}

/// Pure deterministic decision engine creating personalized daily learning plans.
class DailyLearningPlanEngine {
  const DailyLearningPlanEngine();

  /// Evaluates learner state, curriculum, and context to generate a deterministic daily plan.
  DailyPlanResult generatePlan({
    required LearningProfile profile,
    required LearnerProgress progress,
    required List<VocabularyItem> vocabularyItems,
    required List<Lesson> availableLessons,
    List<DailyLearningTask>? schoolAssignedTasks,
    bool isChild = false,
    AccountContext accountContext = AccountContext.individual,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final List<DailyLearningTask> generatedTasks = [];

    // 1. SCHOOL CONTEXT TASKS (If applicable)
    if (accountContext.isSchool &&
        schoolAssignedTasks != null &&
        schoolAssignedTasks.isNotEmpty) {
      generatedTasks.addAll(schoolAssignedTasks);
    }

    // 2. CURRENT / INCOMPLETE LESSON EVALUATION
    final currentLesson = availableLessons.firstWhere(
      (l) => l.id == profile.currentLessonId,
      orElse:
          () =>
              availableLessons.isNotEmpty
                  ? availableLessons.first
                  : _fallbackLesson,
    );

    final isCurrentLessonCompleted = progress.isLessonCompleted(
      currentLesson.id,
    );

    final lessonTask = DailyLearningTask(
      id: 'task_lesson_${currentLesson.id}',
      titleArabic:
          isCurrentLessonCompleted
              ? 'مراجعة درس: ${currentLesson.titleArabic}'
              : 'متابعة درس: ${currentLesson.titleArabic}',
      titleEnglish:
          isCurrentLessonCompleted
              ? 'Review: ${currentLesson.title}'
              : 'Continue: ${currentLesson.title}',
      descriptionArabic: currentLesson.descriptionArabic,
      descriptionEnglish: currentLesson.description,
      type: DailyLearningTaskType.lesson,
      skill: currentLesson.primarySkill,
      estimatedMinutes: isChild ? 4 : currentLesson.estimatedMinutes,
      xpReward: 30,
      completed: isCurrentLessonCompleted,
      progress: isCurrentLessonCompleted ? 1.0 : 0.0,
      createdDate: now,
      lessonId: currentLesson.id,
      actionRoute: '/learning',
      isForChild: isChild,
      isSchoolTask: accountContext.isSchool,
    );
    generatedTasks.add(lessonTask);

    // 3. VOCABULARY DUE QUEUE
    final dueVocab =
        vocabularyItems.where((v) => v.isDueForReview(now)).toList();
    final dueCount = dueVocab.length;

    if (dueCount > 0) {
      final vocabMinutes = isChild ? 3 : ((dueCount * 0.5).ceil()).clamp(3, 10);
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_vocab_review_${now.year}_${now.month}_${now.day}',
          titleArabic: 'تثبيت المفردات المستحقة ($dueCount كلمات)',
          titleEnglish: 'Review Due Vocabulary ($dueCount words)',
          descriptionArabic:
              'مراجعة سريعة بالتكرار المتباعد لتثبيت الكلمات في الذاكرة الدائمة.',
          descriptionEnglish:
              'Spaced repetition review to lock new terms into long-term memory.',
          type: DailyLearningTaskType.vocabularyReview,
          skill: LearningSkill.vocabulary,
          estimatedMinutes: vocabMinutes,
          xpReward: (dueCount * 4).clamp(15, 40),
          completed: false,
          progress: 0.0,
          createdDate: now,
          actionRoute: '/vocabulary/practice',
          isForChild: isChild,
        ),
      );
    }

    // 4. WEAK SKILL TARGETED PRACTICE
    if (profile.grammarScore < 65) {
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_grammar_reinforce_${now.year}_${now.month}_${now.day}',
          titleArabic:
              isChild
                  ? 'لعبة القواعد والتراكيب 🧩'
                  : 'تقوية مهارة القواعد والتراكيب',
          titleEnglish:
              isChild
                  ? 'Grammar Puzzle Game 🧩'
                  : 'Grammar Reinforcement Practice',
          descriptionArabic:
              'تدريب مخصص لتقوية تصريف الأفعال وصياغة الجمل بدقة.',
          descriptionEnglish:
              'Targeted drill focusing on tenses and sentence structures.',
          type:
              isChild
                  ? DailyLearningTaskType.educationalGame
                  : DailyLearningTaskType.grammar,
          skill: LearningSkill.grammar,
          estimatedMinutes: isChild ? 4 : 6,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          createdDate: now,
          gameId: isChild ? 'sentence_builder' : null,
          actionRoute:
              isChild
                  ? '/student/games/sentence_builder'
                  : '/tutor/conversation',
          isForChild: isChild,
        ),
      );
    } else if (profile.vocabularyScore < 65 && dueCount == 0) {
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_vocab_reinforce_${now.year}_${now.month}_${now.day}',
          titleArabic:
              isChild ? 'لعبة مطابقة الكلمات 🗂️' : 'توسيع الثروة اللغوية',
          titleEnglish:
              isChild
                  ? 'Word Matching Game 🗂️'
                  : 'Vocabulary Expansion Practice',
          descriptionArabic: 'تعلم واستخدام 5 مصطلحات جديدة في سياقات يومية.',
          descriptionEnglish:
              'Learn and apply 5 new terms in everyday contexts.',
          type:
              isChild
                  ? DailyLearningTaskType.educationalGame
                  : DailyLearningTaskType.vocabularyReview,
          skill: LearningSkill.vocabulary,
          estimatedMinutes: isChild ? 3 : 5,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          createdDate: now,
          gameId: isChild ? 'word_match' : null,
          actionRoute:
              isChild ? '/student/games/word_match' : '/vocabulary/practice',
          isForChild: isChild,
        ),
      );
    } else if (profile.speakingScore != null && profile.speakingScore! < 65) {
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_speaking_pronounce_${now.year}_${now.month}_${now.day}',
          titleArabic:
              isChild ? 'تحدث مع عباس ودنيا 🗣️' : 'تدريب النطق ومخارج الحروف',
          titleEnglish:
              isChild
                  ? 'Talk with AI Tutor 🗣️'
                  : 'Pronunciation & Speaking Drill',
          descriptionArabic:
              'تدريب صوتي قصير لضبط مخارج الحروف والنبرة الواثقة.',
          descriptionEnglish:
              'Short vocal exercise to improve accent clarity and confidence.',
          type: DailyLearningTaskType.pronunciation,
          skill: LearningSkill.speaking,
          estimatedMinutes: isChild ? 3 : 5,
          xpReward: 25,
          completed: false,
          progress: 0.0,
          createdDate: now,
          actionRoute: '/tutor/conversation',
          isForChild: isChild,
        ),
      );
    }

    // 5. LEARNER PACE ADJUSTMENT (Strong vs Struggling vs Child)
    if (profile.overallScore >= 80 && !isChild) {
      // Strong learner challenge
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_fluency_challenge_${now.year}_${now.month}_${now.day}',
          titleArabic: 'تحدي الطلاقة والمحادثة الحرة',
          titleEnglish: 'Fluency & Conversational Challenge',
          descriptionArabic:
              'محادثة متقدمة مع معلمك الذكي لتوسيع المفردات والطلاقة.',
          descriptionEnglish:
              'Advanced conversation with AI tutor to build spontaneous fluency.',
          type: DailyLearningTaskType.conversation,
          skill: LearningSkill.speaking,
          estimatedMinutes: 8,
          xpReward: 35,
          completed: false,
          progress: 0.0,
          createdDate: now,
          actionRoute: '/tutor/conversation',
          isForChild: false,
        ),
      );
    } else if (isChild) {
      // Child Mode playful activity
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_kid_game_${now.year}_${now.month}_${now.day}',
          titleArabic: 'لعبة استمع واختر 🎧',
          titleEnglish: 'Listen & Choose Game 🎧',
          descriptionArabic: 'استمع للصوت واختر الصورة الصحيحة لكسب النجوم!',
          descriptionEnglish:
              'Listen to the audio and choose the right picture to earn stars!',
          type: DailyLearningTaskType.educationalGame,
          skill: LearningSkill.listening,
          estimatedMinutes: 3,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          createdDate: now,
          gameId: 'listen_and_choose',
          actionRoute: '/student/games/listen_and_choose',
          isForChild: true,
        ),
      );
    }

    // 6. ENRICHMENT WHEN ALL TASKS COMPLETED
    final completedCount = generatedTasks.where((t) => t.completed).length;
    final allCompleted = completedCount == generatedTasks.length;

    if (allCompleted) {
      generatedTasks.add(
        DailyLearningTask(
          id: 'task_enrichment_${now.year}_${now.month}_${now.day}',
          titleArabic: 'محادثة إثرائية إضافية 🌟',
          titleEnglish: 'Bonus Enrichment Conversation 🌟',
          descriptionArabic:
              'أنجزت جميع مهام اليوم! استمتع بمحادثة حرة مع معلمك الذكي.',
          descriptionEnglish:
              'You completed today\'s goals! Enjoy a casual chat with your AI tutor.',
          type: DailyLearningTaskType.conversation,
          skill: LearningSkill.speaking,
          estimatedMinutes: 5,
          xpReward: 25,
          completed: false,
          progress: 0.0,
          createdDate: now,
          actionRoute: '/tutor/conversation',
          isForChild: isChild,
        ),
      );
    }

    // 7. DETERMINISTIC "CONTINUE LEARNING" RECOMMENDED TASK SELECTION
    // Priority:
    // 1. Resume incomplete lesson
    // 2. Review due vocabulary
    // 3. Practice weakest skill
    // 4. Start next lesson / game
    // 5. AI Tutor conversation
    DailyLearningTask recommended;

    if (!isCurrentLessonCompleted) {
      recommended = lessonTask;
    } else if (dueCount > 0) {
      recommended = generatedTasks.firstWhere(
        (t) => t.type == DailyLearningTaskType.vocabularyReview,
        orElse: () => lessonTask,
      );
    } else {
      final incompleteTask = generatedTasks.firstWhere(
        (t) => !t.completed,
        orElse: () => generatedTasks.first,
      );
      recommended = incompleteTask;
    }

    final totalTasks = generatedTasks.length;
    final finalCompleted = generatedTasks.where((t) => t.completed).length;
    final ratio = totalTasks > 0 ? finalCompleted / totalTasks : 0.0;
    final totalXp = generatedTasks.fold(0, (sum, t) => sum + t.xpReward);

    return DailyPlanResult(
      tasks: generatedTasks,
      recommendedTask: recommended,
      currentLesson: currentLesson,
      dueVocabularyCount: dueCount,
      completedTasksCount: finalCompleted,
      totalTasksCount: totalTasks,
      completionRatio: ratio,
      isDailyGoalCompleted: finalCompleted >= 2 || allCompleted,
      totalXpAvailable: totalXp,
    );
  }

  static const Lesson _fallbackLesson = Lesson(
    id: 'lesson_1_1',
    moduleId: 'mod_1',
    month: 1,
    title: 'Hello & Nice to Meet You',
    titleArabic: 'التحية والتعريف بالاسم',
    description:
        'Learn common greetings, saying your name, and polite pleasantries.',
    descriptionArabic:
        'تعلم أهم عبارات التحية وكيفية ذكر اسمك والترحيب بالآخرين.',
    cefrLevel: CefrLevel.a1,
    primarySkill: LearningSkill.speaking,
    targetSkills: [LearningSkill.speaking, LearningSkill.vocabulary],
    steps: [],
    order: 1,
  );
}
