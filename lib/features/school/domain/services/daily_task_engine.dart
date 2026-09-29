import 'package:flutter/foundation.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../../../learning/domain/models/learner_progress.dart';
import '../../../learning/domain/models/learning_profile.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/domain/models/lesson_models.dart';
import '../../../learning/domain/models/vocabulary_item.dart';
import '../models/daily_task.dart';

/// Aggregated output of the deterministic Daily Task Engine.
@immutable
class DailyTaskPlan {
  final List<DailyTask> tasks;
  final DailyTask recommendedTask;
  final int dueVocabularyCount;
  final DailyTaskProgress progress;

  const DailyTaskPlan({
    required this.tasks,
    required this.recommendedTask,
    required this.dueVocabularyCount,
    required this.progress,
  });
}

/// Pure deterministic domain engine deciding the school student's daily learning tasks.
class DailyTaskEngine {
  const DailyTaskEngine();

  /// Generates 3 to 5 deterministic, pedagogically sequenced daily tasks.
  DailyTaskPlan generatePlan({
    required LearningProfile profile,
    required LearnerProgress progress,
    required List<VocabularyItem> vocabularyList,
    required List<Lesson> availableLessons,
    required bool isChild,
    List<String> completedTaskIds = const [],
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final rawTasks = <DailyTask>[];

    // Find current lesson from curriculum
    final currentLesson = availableLessons.firstWhere(
      (l) => l.id == profile.currentLessonId,
      orElse:
          () =>
              availableLessons.isNotEmpty
                  ? availableLessons.first
                  : const Lesson(
                    id: 'les_default_01',
                    moduleId: 'mod_01',
                    month: 1,
                    order: 1,
                    title: 'Introduction & Greetings',
                    titleArabic: 'التحية والتعريف بالنفس',
                    description: 'Learn greeting words and introductions',
                    descriptionArabic: 'تعلم كلمات التحية والتعارف الأساسية',
                    cefrLevel: CefrLevel.a1,
                    primarySkill: LearningSkill.speaking,
                    estimatedMinutes: 8,
                    steps: [],
                  ),
    );

    final isLessonCompleted = progress.isLessonCompleted(currentLesson.id);
    final dueCount = vocabularyList.where((v) => v.isDueForReview(now)).length;
    final isStrongLearner = profile.overallScore >= 80;
    final isStruggling = profile.overallScore < 60;

    // -------------------------------------------------------------
    // 1. Primary Task: Curriculum Lesson Progression or Review
    // -------------------------------------------------------------
    if (!isLessonCompleted) {
      rawTasks.add(
        DailyTask(
          id: 'task_lesson_${currentLesson.id}',
          titleArabic:
              isChild
                  ? 'مغامرة الدرس: ${currentLesson.titleArabic}'
                  : 'درس اليوم: ${currentLesson.titleArabic}',
          titleEnglish:
              isChild
                  ? 'Lesson Quest: ${currentLesson.title}'
                  : "Today's Lesson: ${currentLesson.title}",
          descriptionArabic: currentLesson.descriptionArabic,
          descriptionEnglish: currentLesson.description,
          type: DailyTaskType.lesson,
          skill: currentLesson.primarySkill,
          difficulty:
              isStruggling
                  ? 'beginner'
                  : (isStrongLearner ? 'intermediate' : 'beginner'),
          estimatedMinutes: isChild ? 5 : (isStruggling ? 6 : 8),
          xpReward: 30,
          completed: false,
          status: DailyTaskStatus.inProgress,
          progress: 0.3,
          dueDate: now,
          lessonId: currentLesson.id,
          actionRoute: '/learning?lessonId=${currentLesson.id}',
          isForChild: isChild,
        ),
      );
    } else {
      rawTasks.add(
        DailyTask(
          id: 'task_lesson_completed_${currentLesson.id}',
          titleArabic:
              isChild
                  ? 'مغامرة الدرس: ${currentLesson.titleArabic}'
                  : 'مراجعة متقدمة: ${currentLesson.titleArabic}',
          titleEnglish:
              isChild
                  ? 'Lesson Quest: ${currentLesson.title}'
                  : 'Advanced Review: ${currentLesson.title}',
          descriptionArabic: 'تثبيت ما تعلمته في الدرس الأخير وتطبيقه.',
          descriptionEnglish:
              'Reinforce what you learned in the latest lesson.',
          type: DailyTaskType.lesson,
          skill: currentLesson.primarySkill,
          difficulty: 'intermediate',
          estimatedMinutes: isChild ? 5 : 7,
          xpReward: 25,
          completed: true,
          status: DailyTaskStatus.completed,
          progress: 1.0,
          dueDate: now,
          lessonId: currentLesson.id,
          actionRoute: '/learning?lessonId=${currentLesson.id}',
          isForChild: isChild,
        ),
      );
    }

    // -------------------------------------------------------------
    // 2. Vocabulary Task: Spaced Repetition or Daily Vocabulary
    // -------------------------------------------------------------
    if (dueCount > 0) {
      rawTasks.add(
        DailyTask(
          id: 'task_vocab_spaced',
          titleArabic:
              isChild
                  ? 'تحدي النجوم للكلمات ($dueCount كلمات مستحقة) ⭐'
                  : 'مراجعة المفردات المستحقة ($dueCount كلمات)',
          titleEnglish:
              isChild
                  ? 'Star Word Quest ($dueCount words due)'
                  : 'Review Due Vocabulary ($dueCount words)',
          descriptionArabic: 'تثبيت الكلمات عبر التكرار المتباعد قبل أن تُنسى.',
          descriptionEnglish:
              'Reinforce words using spaced repetition intervals.',
          type: DailyTaskType.vocabulary,
          skill: LearningSkill.vocabulary,
          difficulty: isStruggling ? 'beginner' : 'intermediate',
          estimatedMinutes: isChild ? 4 : 5,
          xpReward: 20,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/vocabulary/practice',
          isForChild: isChild,
        ),
      );
    } else {
      rawTasks.add(
        DailyTask(
          id: 'task_vocab_daily',
          titleArabic:
              isChild ? 'تحدي الكلمات الذكية 🗂️' : 'تدريب المفردات اليومية',
          titleEnglish:
              isChild
                  ? 'Smart Word Power Challenge'
                  : 'Daily Vocabulary Practice',
          descriptionArabic: 'تدرّب على مفردات جديدة واكتسب طلاقة لغوية.',
          descriptionEnglish: 'Practice vocabulary to build spoken fluency.',
          type: DailyTaskType.vocabulary,
          skill: LearningSkill.vocabulary,
          difficulty: 'beginner',
          estimatedMinutes: isChild ? 4 : 5,
          xpReward: 20,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/vocabulary/practice',
          isForChild: isChild,
        ),
      );
    }

    // -------------------------------------------------------------
    // 3. Adaptive Targeted Practice (Weak Skill vs Strong Fluency)
    // -------------------------------------------------------------
    final isWeakGrammar = profile.grammarScore < 65;
    final isWeakListening = (profile.listeningScore ?? 75) < 65;

    if (isWeakGrammar) {
      rawTasks.add(
        DailyTask(
          id: 'task_adaptive_grammar',
          titleArabic:
              isChild
                  ? 'بناء الجمل السحرية 🧱'
                  : 'تمارين القواعد وتراكيب الجمل',
          titleEnglish:
              isChild
                  ? 'Magic Sentence Builder'
                  : 'Grammar & Sentence Structure',
          descriptionArabic:
              isChild
                  ? 'رتّب الكلمات بشكل صحيح لتكوين جمل ممتازة!'
                  : 'تدريب مركز على التراكيب النحوية وتجنب الأخطاء الشائعة.',
          descriptionEnglish:
              isChild
                  ? 'Arrange words to make awesome sentences!'
                  : 'Targeted practice on sentence structure and rules.',
          type: DailyTaskType.grammar,
          skill: LearningSkill.grammar,
          difficulty: isStruggling ? 'beginner' : 'intermediate',
          estimatedMinutes: isChild ? 5 : 6,
          xpReward: 25,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          gameId: 'game_sentence_builder',
          actionRoute: '/student/games/game_sentence_builder',
          isForChild: isChild,
        ),
      );
    } else if (isWeakListening) {
      rawTasks.add(
        DailyTask(
          id: 'task_adaptive_listening',
          titleArabic:
              isChild
                  ? 'لعبة الاستماع الذكي 🎧'
                  : 'تدريب الاستماع والفهم الصوتي',
          titleEnglish:
              isChild ? 'Listen & Catch Game' : 'Listening Comprehension Drill',
          descriptionArabic:
              isChild
                  ? 'استمع جيداً واختر الكلمة المناسبة 🎯'
                  : 'الاستماع لمقاطع محكية والإجابة على أسئلة الفهم.',
          descriptionEnglish:
              isChild
                  ? 'Listen carefully and tap the right word!'
                  : 'Listen to spoken phrases and verify your comprehension.',
          type: DailyTaskType.listening,
          skill: LearningSkill.listening,
          difficulty: 'beginner',
          estimatedMinutes: isChild ? 4 : 5,
          xpReward: 20,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          gameId: 'game_listen_choose',
          actionRoute: '/student/games/game_listen_choose',
          isForChild: isChild,
        ),
      );
    } else if (isStrongLearner) {
      rawTasks.add(
        DailyTask(
          id: 'task_adaptive_strong_challenge',
          titleArabic:
              isChild
                  ? 'تحدي النجوم: محادثة طليقة 🌟'
                  : 'تحدي الطلاقة: محادثة متقدمة',
          titleEnglish:
              isChild
                  ? 'Star Fluency Quest'
                  : 'Fluency Challenge: Advanced Dialogue',
          descriptionArabic:
              'محادثة سريعة مع المعلم الذكي لاختبار سرعة البديهة والطلاقة.',
          descriptionEnglish:
              'Engage in a live dialogue to boost active spoken fluency.',
          type: DailyTaskType.conversation,
          skill: LearningSkill.speaking,
          difficulty: 'advanced',
          estimatedMinutes: isChild ? 5 : 8,
          xpReward: 35,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/tutor',
          isForChild: isChild,
        ),
      );
    } else {
      rawTasks.add(
        DailyTask(
          id: 'task_adaptive_speaking',
          titleArabic:
              isChild
                  ? 'نطق الكلمات بصوت واضح 🗣️'
                  : 'تدريب النطق والمحادثة التفاعلية',
          titleEnglish:
              isChild
                  ? 'Clear Voice Practice'
                  : 'Pronunciation & Speaking Drill',
          descriptionArabic:
              isChild
                  ? 'تحدث بصوت واثق مع عباس ودنيا واكسب النقاط!'
                  : 'تطبيق التحدث بطلاقة مع التصحيح الصوتي التلقائي.',
          descriptionEnglish:
              isChild
                  ? 'Speak up with Abbas and Dunya to earn points!'
                  : 'Practice spoken fluency with real-time feedback.',
          type: DailyTaskType.speaking,
          skill: LearningSkill.speaking,
          difficulty: 'beginner',
          estimatedMinutes: isChild ? 4 : 5,
          xpReward: 25,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/tutor',
          isForChild: isChild,
        ),
      );
    }

    // -------------------------------------------------------------
    // 4. Interactive Educational Mini-Game
    // -------------------------------------------------------------
    rawTasks.add(
      DailyTask(
        id: 'task_game_word_match',
        titleArabic:
            isChild
                ? 'لعبة مطابقة الكلمات 🧩'
                : 'تحدي اللعبة التعليمية: مطابقة المفردات',
        titleEnglish:
            isChild ? 'Word Match Game' : 'Educational Mini-Game: Word Match',
        descriptionArabic:
            isChild
                ? 'طابق كل كلمة مع معناها بأسرع وقت واجمع النجوم!'
                : 'اربط الكلمات بترجماتها الصحيحة بدقة وسرعة.',
        descriptionEnglish:
            isChild
                ? 'Match words with their meanings to collect stars!'
                : 'Connect terms to their correct meanings accurately.',
        type: DailyTaskType.game,
        skill: LearningSkill.vocabulary,
        difficulty: isStruggling ? 'beginner' : 'intermediate',
        estimatedMinutes: isChild ? 4 : 5,
        xpReward: 25,
        completed: false,
        status: DailyTaskStatus.pending,
        progress: 0.0,
        dueDate: now,
        gameId: 'game_word_match',
        actionRoute: '/student/games/game_word_match',
        isForChild: isChild,
      ),
    );

    // Apply completion overrides from completedTaskIds
    final tasks =
        rawTasks.map((t) {
          if (completedTaskIds.contains(t.id)) {
            return t.copyWith(
              completed: true,
              status: DailyTaskStatus.completed,
              progress: 1.0,
            );
          }
          return t;
        }).toList();

    // -------------------------------------------------------------
    // 5. Enrichment Activity (If all prior tasks completed)
    // -------------------------------------------------------------
    final allDone = tasks.every(
      (t) => t.completed || t.status == DailyTaskStatus.completed,
    );
    if (allDone) {
      tasks.add(
        DailyTask(
          id: 'task_enrichment_convo',
          titleArabic:
              isChild
                  ? 'محادثة حرة ممتعة مع عباس ودنيا 🎈'
                  : 'محادثة تعليمية حرة إثرائية',
          titleEnglish:
              isChild
                  ? 'Fun Free Chat with Abbas & Dunya'
                  : 'Enrichment Educational Free Conversation',
          descriptionArabic:
              'تحدث بحرية في أي موضوع تعليمي تحبه لتطبيق مهاراتك!',
          descriptionEnglish:
              'Engage in open educational conversation on your favorite topic.',
          type: DailyTaskType.conversation,
          skill: LearningSkill.speaking,
          difficulty: 'intermediate',
          estimatedMinutes: 5,
          xpReward: 30,
          completed: false,
          status: DailyTaskStatus.pending,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/tutor',
          isForChild: isChild,
        ),
      );
    }

    // Determine primary recommended task for "Continue Learning" CTA
    final recommended = tasks.firstWhere(
      (t) => !t.completed && t.status != DailyTaskStatus.completed,
      orElse: () => tasks.first,
    );

    return DailyTaskPlan(
      tasks: tasks,
      recommendedTask: recommended,
      dueVocabularyCount: dueCount,
      progress: DailyTaskProgress.fromTasks(tasks),
    );
  }
}
