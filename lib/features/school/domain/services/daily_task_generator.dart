import '../../../placement/domain/models/cefr_level.dart';
import '../../../learning/domain/models/learner_progress.dart';
import '../../../learning/domain/models/learning_profile.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/domain/models/lesson_models.dart';
import '../../../learning/domain/models/vocabulary_item.dart';
import '../models/daily_task.dart';

/// Deterministic generator for personalized, adaptive school daily learning tasks.
class DailyTaskGenerator {
  const DailyTaskGenerator();

  /// Generates 3 to 5 adaptive daily tasks based on learner progress, weak skills, and age group.
  List<DailyTask> generateDailyTasks({
    required LearningProfile profile,
    required LearnerProgress progress,
    required List<VocabularyItem> vocabularyList,
    required List<Lesson> availableLessons,
    required bool isChild,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final tasks = <DailyTask>[];

    // 1. Task 1: Curriculum Lesson Progression
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
                    title: 'Introduction & Basics',
                    titleArabic: 'التعارف والمفردات الأساسية',
                    description: 'Learn greeting words and introductions',
                    descriptionArabic: 'تعلم كلمات التحية والتعارف الأساسية',
                    cefrLevel: CefrLevel.a1,
                    primarySkill: LearningSkill.speaking,
                    estimatedMinutes: 8,
                    steps: [],
                  ),
    );

    if (isChild) {
      tasks.add(
        DailyTask(
          id: 'task_lesson_${currentLesson.id}',
          titleArabic: 'مغامرة الدرس: ${currentLesson.titleArabic}',
          titleEnglish: 'Lesson Quest: ${currentLesson.title}',
          descriptionArabic: 'استكشف كلمات اليوم واكسب النجوم 🌟',
          descriptionEnglish: 'Discover new words and earn stars!',
          type: DailyTaskType.lesson,
          skill: currentLesson.primarySkill,
          estimatedMinutes: 5,
          xpReward: 30,
          completed: progress.isLessonCompleted(currentLesson.id),
          progress: progress.isLessonCompleted(currentLesson.id) ? 1.0 : 0.0,
          dueDate: now,
          lessonId: currentLesson.id,
          actionRoute: '/learning',
          isForChild: true,
        ),
      );
    } else {
      tasks.add(
        DailyTask(
          id: 'task_lesson_${currentLesson.id}',
          titleArabic: 'درس اليوم: ${currentLesson.titleArabic}',
          titleEnglish: 'Today\'s Lesson: ${currentLesson.title}',
          descriptionArabic: currentLesson.descriptionArabic,
          descriptionEnglish: currentLesson.description,
          type: DailyTaskType.lesson,
          skill: currentLesson.primarySkill,
          estimatedMinutes: 8,
          xpReward: 30,
          completed: progress.isLessonCompleted(currentLesson.id),
          progress: progress.isLessonCompleted(currentLesson.id) ? 1.0 : 0.0,
          dueDate: now,
          lessonId: currentLesson.id,
          actionRoute: '/learning',
          isForChild: false,
        ),
      );
    }

    // 2. Task 2: Vocabulary Spaced Repetition / Practice
    final dueCount = vocabularyList.where((v) => v.isDueForReview(now)).length;
    if (isChild) {
      tasks.add(
        DailyTask(
          id: 'task_vocab_daily',
          titleArabic: 'تحدي الكلمات الذكية 🗂️',
          titleEnglish: 'Word Power Challenge',
          descriptionArabic: 'تدرّب على 5 كلمات جديدة ورسّخ مفرداتك!',
          descriptionEnglish: 'Practice 5 new words and build your vocabulary!',
          type: DailyTaskType.vocabulary,
          skill: LearningSkill.vocabulary,
          estimatedMinutes: 4,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/vocabulary/practice',
          isForChild: true,
        ),
      );
    } else {
      tasks.add(
        DailyTask(
          id: 'task_vocab_daily',
          titleArabic:
              dueCount > 0
                  ? 'مراجعة المفردات المستحقة ($dueCount كلمات)'
                  : 'تدريب المفردات والتعابير اليومية',
          titleEnglish:
              dueCount > 0
                  ? 'Review Due Vocabulary ($dueCount words)'
                  : 'Daily Vocabulary Practice',
          descriptionArabic:
              'تثبيت المفردات عبر التكرار المتباعد لتحسين الحفظ طويل المدى.',
          descriptionEnglish:
              'Reinforce vocabulary using spaced repetition intervals.',
          type: DailyTaskType.vocabulary,
          skill: LearningSkill.vocabulary,
          estimatedMinutes: 5,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/vocabulary/practice',
          isForChild: false,
        ),
      );
    }

    // 3. Task 3: Adaptive Targeted Skill Exercise (Weakest Skill or Listening/Speaking)
    final isWeakGrammar = profile.grammarScore < 65;
    final isWeakListening = (profile.listeningScore ?? 75) < 65;

    if (isWeakGrammar) {
      tasks.add(
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
                  : 'تدريب مركز على التراكيب النحوية لتجنب الأخطاء الشائعة.',
          descriptionEnglish:
              isChild
                  ? 'Arrange words to make awesome sentences!'
                  : 'Targeted practice on sentence structure and tenses.',
          type: DailyTaskType.grammar,
          skill: LearningSkill.grammar,
          estimatedMinutes: 6,
          xpReward: 25,
          completed: false,
          progress: 0.0,
          dueDate: now,
          gameId: 'game_sentence_builder',
          actionRoute: '/student/games/game_sentence_builder',
          isForChild: isChild,
        ),
      );
    } else if (isWeakListening) {
      tasks.add(
        DailyTask(
          id: 'task_adaptive_listening',
          titleArabic:
              isChild
                  ? 'لعبة الاستماع الذكي 🎧'
                  : 'تدريب الاستماع والفهم الصوتي',
          titleEnglish:
              isChild ? 'Listen & Catch Game' : 'Listening Comprehension',
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
          estimatedMinutes: 5,
          xpReward: 20,
          completed: false,
          progress: 0.0,
          dueDate: now,
          gameId: 'game_listen_choose',
          actionRoute: '/student/games/game_listen_choose',
          isForChild: isChild,
        ),
      );
    } else {
      tasks.add(
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
          estimatedMinutes: 5,
          xpReward: 25,
          completed: false,
          progress: 0.0,
          dueDate: now,
          actionRoute: '/tutor',
          isForChild: isChild,
        ),
      );
    }

    // 4. Task 4: Educational Mini-Game
    tasks.add(
      DailyTask(
        id: 'task_game_daily',
        titleArabic:
            isChild
                ? 'لعبة مطابقة الكلمات 🧩'
                : 'تحدي اللعبة التعليمية: مطابقة المفردات',
        titleEnglish:
            isChild ? 'Word Match Game' : 'Educational Mini-Game Challenge',
        descriptionArabic:
            isChild
                ? 'اربط الكلمة بصورتها ومعناها الصحيح!'
                : 'لعبة تفاعلية لترسيخ المفردات واختبار سرعة البديهة.',
        descriptionEnglish:
            isChild
                ? 'Match the words with their meanings!'
                : 'Interactive mini-game to sharpen vocabulary recall.',
        type: DailyTaskType.game,
        skill: LearningSkill.vocabulary,
        estimatedMinutes: 4,
        xpReward: 25,
        completed: false,
        progress: 0.0,
        dueDate: now,
        gameId: 'game_word_match',
        actionRoute: '/student/games/game_word_match',
        isForChild: isChild,
      ),
    );

    // 5. Task 5: Safe Educational AI Conversation with Abbas or Dunya
    tasks.add(
      DailyTask(
        id: 'task_tutor_conversation',
        titleArabic:
            isChild
                ? 'محادثة ودية مع عباس ودنيا 💬'
                : 'محادثة تطبيقية مع المدرب الذكي',
        titleEnglish:
            isChild
                ? 'Friendly Chat with Abbas & Dunya'
                : 'AI Tutor Conversation',
        descriptionArabic:
            isChild
                ? 'اسأل عباس ودنيا أي سؤال عن الكلمات واللغة بأمان تام 🛡️'
                : 'تحدث في مواضيع يومية لتطوير الطلاقة والتعبير اللغوي.',
        descriptionEnglish:
            isChild
                ? 'Safe, educational chat with friendly AI tutors.'
                : 'Practice free conversation on everyday topics.',
        type: DailyTaskType.conversation,
        skill: LearningSkill.speaking,
        estimatedMinutes: 5,
        xpReward: 25,
        completed: false,
        progress: 0.0,
        dueDate: now,
        actionRoute: '/tutor',
        isForChild: isChild,
      ),
    );

    return tasks;
  }
}
