import '../../../learning/domain/models/learner_progress.dart';
import '../../../learning/domain/models/learning_profile.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../../../learning/domain/models/lesson_models.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../../domain/models/daily_task.dart';
import '../../domain/models/game_models.dart';
import '../../domain/models/student_progress_summary.dart';
import '../../domain/repositories/student_dashboard_repository.dart';
import '../../domain/services/daily_task_generator.dart';

/// In-memory implementation of StudentDashboardRepository for deterministic, zero-cost execution.
class InMemoryStudentDashboardRepository implements StudentDashboardRepository {
  final DailyTaskGenerator _taskGenerator;
  final Map<String, List<DailyTask>> _studentTasks = {};
  final Map<String, StudentProgressSummary> _studentSummaries = {};
  final Map<String, List<GameActivity>> _gamesCatalog = {};
  final Map<String, List<String>> _studentAchievements = {};

  InMemoryStudentDashboardRepository({
    DailyTaskGenerator taskGenerator = const DailyTaskGenerator(),
    bool seedDefaults = true,
  }) : _taskGenerator = taskGenerator {
    if (seedDefaults) {
      _seedDefaultCatalog();
    }
  }

  void _seedDefaultCatalog() {
    // 5 High-Quality Educational Starter Mini-Games
    final games = [
      // Game 1: Word Match
      const GameActivity(
        id: 'game_word_match',
        titleArabic: 'مطابقة الكلمات والمعاني',
        titleEnglish: 'Word & Meaning Match',
        descriptionArabic: 'طابق كل كلمة عربية بالترجمة والمعنى الصحيح لها.',
        descriptionEnglish: 'Match each Arabic word with its correct meaning.',
        gameType: GameType.wordMatch,
        difficulty: 'beginner',
        skill: LearningSkill.vocabulary,
        xpReward: 30,
        iconEmoji: '🧩',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_wm_1',
            promptArabic: 'طابق كلمات المأكولات والمشروبات',
            promptEnglish: 'Match Food & Beverage Words',
            correctAnswer: 'matched',
            matchPairs: {
              'شاي': 'Tea 🍵',
              'قهوة': 'Coffee ☕',
              'ماء': 'Water 💧',
              'طعام': 'Food 🍲',
              'مطعم': 'Restaurant 🍽️',
              'حساب': 'Bill 🧾',
            },
          ),
        ],
      ),

      // Game 2: Listen & Choose
      const GameActivity(
        id: 'game_listen_choose',
        titleArabic: 'استمع واختر',
        titleEnglish: 'Listen & Choose',
        descriptionArabic: 'استمع للتعبير الصوتي واختر المعنى والرد الملائم.',
        descriptionEnglish:
            'Listen to the audio prompt and choose the correct answer.',
        gameType: GameType.listenAndChoose,
        difficulty: 'beginner',
        skill: LearningSkill.listening,
        xpReward: 25,
        iconEmoji: '🎧',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_lc_1',
            promptArabic: '« أهلاً وسهلاً »',
            promptEnglish: 'Ahlan wa Sahlan',
            options: [
              'Hello & Welcome',
              'Goodbye',
              'Good morning',
              'Thank you',
            ],
            correctOptionIndex: 0,
            correctAnswer: 'Hello & Welcome',
            explanationArabic:
                '«أهلاً وسهلاً» هي عبارة ترحيبية شهيرة في اللغة العربية.',
          ),
          GameQuestion(
            id: 'q_lc_2',
            promptArabic: '« شكراً جزيلاً »',
            promptEnglish: 'Shukran Jazeelan',
            options: [
              'Please',
              'Thank you very much',
              'You are welcome',
              'Sorry',
            ],
            correctOptionIndex: 1,
            correctAnswer: 'Thank you very much',
            explanationArabic: 'تُقال لشكر شخص بامتنان وتقدير.',
          ),
          GameQuestion(
            id: 'q_lc_3',
            promptArabic: '« كم الحساب لو سمحت؟ »',
            promptEnglish: 'Kam al-hisab law samaht?',
            options: [
              'Where is the restaurant?',
              'How much is the bill, please?',
              'What time is it?',
              'Can I help you?',
            ],
            correctOptionIndex: 1,
            correctAnswer: 'How much is the bill, please?',
            explanationArabic:
                'تُستخدم لطلب فاتورة الحساب في المطعم أو المتجر.',
          ),
          GameQuestion(
            id: 'q_lc_4',
            promptArabic: '« صباح الخير والورد »',
            promptEnglish: 'Sabah al-khair wal-ward',
            options: [
              'Good morning with roses',
              'Good evening',
              'See you tomorrow',
              'Have a nice day',
            ],
            correctOptionIndex: 0,
            correctAnswer: 'Good morning with roses',
            explanationArabic: 'تحية صباحية رقيقة ومحببة.',
          ),
        ],
      ),

      // Game 3: Sentence Builder
      const GameActivity(
        id: 'game_sentence_builder',
        titleArabic: 'بناء الجمل السليمة',
        titleEnglish: 'Sentence Builder',
        descriptionArabic: 'رتّب الكلمات المبعثرة بالترتيب النحوي الصحيح.',
        descriptionEnglish:
            'Arrange scrambled words to construct a proper sentence.',
        gameType: GameType.sentenceBuilder,
        difficulty: 'intermediate',
        skill: LearningSkill.grammar,
        xpReward: 30,
        iconEmoji: '🧱',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_sb_1',
            promptArabic: 'رتّب الجملة لطلب مشروب:',
            promptEnglish: 'Arrange the sentence to order a drink:',
            correctAnswer: 'أريد كوب قهوة مع حليب',
            scrambledWords: ['مع', 'كوب', 'أريد', 'حليب', 'قهوة'],
            explanationArabic:
                'الترتيب: الفعل (أريد) ثم المفعول (كوب قهوة) ثم الوصف (مع حليب).',
          ),
          GameQuestion(
            id: 'q_sb_2',
            promptArabic: 'رتّب جملة السؤال عن المكان:',
            promptEnglish: 'Arrange the sentence to ask for a place:',
            correctAnswer: 'أين يقع أقرب مطعم',
            scrambledWords: ['أقرب', 'أين', 'مطعم', 'يقع'],
            explanationArabic:
                'تبدأ الجملة بأداة الاستفهام (أين) ثم الفعل (يقع).',
          ),
          GameQuestion(
            id: 'q_sb_3',
            promptArabic: 'رتّب جملة التحية للصديق:',
            promptEnglish: 'Arrange the greeting sentence:',
            correctAnswer: 'سعيد بلقائك اليوم يا صديقي',
            scrambledWords: ['بلقائك', 'سعيد', 'يا', 'اليوم', 'صديقي'],
            explanationArabic: 'تعبير ودود يعبر عن الفرح برؤية الصديق.',
          ),
        ],
      ),

      // Game 4: Memory Vocabulary
      const GameActivity(
        id: 'game_memory_vocab',
        titleArabic: 'ذاكرة البطاقات الذكية',
        titleEnglish: 'Memory Flashcard Pairs',
        descriptionArabic:
            'اقلب البطاقات واعثر على الأزواج المتطابقة من الكلمات.',
        descriptionEnglish: 'Flip cards and find matching pairs of vocabulary.',
        gameType: GameType.memoryVocab,
        difficulty: 'beginner',
        skill: LearningSkill.vocabulary,
        xpReward: 25,
        iconEmoji: '🃏',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_mv_1',
            promptArabic: 'بطاقات المدرسة والتعلم',
            promptEnglish: 'School & Learning Cards',
            correctAnswer: 'matched',
            matchPairs: {
              'كتاب': 'Book 📖',
              'مدرسة': 'School 🏫',
              'طالب': 'Student 🎒',
              'معلم': 'Teacher 👩‍🏫',
            },
          ),
        ],
      ),

      // Game 5: Quick Quiz
      const GameActivity(
        id: 'game_quick_quiz',
        titleArabic: 'تحدي الاختبار السريع',
        titleEnglish: 'Quick 5-Question Quiz',
        descriptionArabic: 'اختبر حصيلتك اللغوية في 5 أسئلة سريعة وممتعة.',
        descriptionEnglish:
            'Test your language recall with a fast 5-question quiz.',
        gameType: GameType.quickQuiz,
        difficulty: 'beginner',
        skill: LearningSkill.comprehension,
        xpReward: 35,
        iconEmoji: '⚡',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_qq_1',
            promptArabic: 'ما الرد المناسب على «صباح الخير»؟',
            promptEnglish: 'What is the proper reply to "Good morning"?',
            options: ['صباح النور', 'مساء الخير', 'تصبح على خير', 'مع السلامة'],
            correctOptionIndex: 0,
            correctAnswer: 'صباح النور',
          ),
          GameQuestion(
            id: 'q_qq_2',
            promptArabic: 'ما معنى كلمة «كتاب» بالإنجليزية؟',
            promptEnglish: 'What does "Kitab" mean in English?',
            options: ['Pen', 'Book', 'Bag', 'Desk'],
            correctOptionIndex: 1,
            correctAnswer: 'Book',
          ),
          GameQuestion(
            id: 'q_qq_3',
            promptArabic: 'أي من الكلمات التالية تدل على مكان؟',
            promptEnglish: 'Which of the following is a location?',
            options: ['مطعم', 'تفاحة', 'سريع', 'يقرأ'],
            correctOptionIndex: 0,
            correctAnswer: 'مطعم',
          ),
          GameQuestion(
            id: 'q_qq_4',
            promptArabic: 'الفعل «ذهبَ» يدل على الزمن:',
            promptEnglish: 'The verb "Dhahaba" indicates which tense?',
            options: ['الماضي', 'المضارع', 'المستقبل', 'الأمر'],
            correctOptionIndex: 0,
            correctAnswer: 'الماضي',
          ),
          GameQuestion(
            id: 'q_qq_5',
            promptArabic: 'ما مرادف كلمة «جميل»؟',
            promptEnglish: 'What is a synonym for "Jameel"?',
            options: ['حلو / رائع', 'صعب', 'قديم', 'قصير'],
            correctOptionIndex: 0,
            correctAnswer: 'حلو / رائع',
          ),
        ],
      ),

      // Game 6: Picture / Word Select
      const GameActivity(
        id: 'game_picture_select',
        titleArabic: 'مطابقة الصور والكلمات',
        titleEnglish: 'Picture & Word Selection',
        descriptionArabic: 'اختر الصورة أو الكلمة المطابقة للمثال الموضح.',
        descriptionEnglish:
            'Select the matching picture or word for the prompt.',
        gameType: GameType.pictureWordSelect,
        difficulty: 'beginner',
        skill: LearningSkill.vocabulary,
        xpReward: 25,
        iconEmoji: '🖼️',
        isChildFriendly: true,
        questions: [
          GameQuestion(
            id: 'q_pws_1',
            promptArabic: 'اختر الرمز المعبر عن «تفاحة» (Apple):',
            promptEnglish: 'Select the symbol for Apple:',
            options: ['تفاحة 🍎', 'سيارة 🚗', 'كتاب 📖', 'بيت 🏠'],
            correctOptionIndex: 0,
            correctAnswer: 'تفاحة 🍎',
          ),
          GameQuestion(
            id: 'q_pws_2',
            promptArabic: 'ما هو الشيء المستخدم للقراءة والتعلم؟',
            promptEnglish: 'What is used for reading and learning?',
            options: ['كرة ⚽', 'كتاب 📚', 'ماء 💧', 'قبعة 🎩'],
            correctOptionIndex: 1,
            correctAnswer: 'كتاب 📚',
          ),
          GameQuestion(
            id: 'q_pws_3',
            promptArabic: 'اختر وسيلة النقل المناسبة للسفر جواً:',
            promptEnglish: 'Select the vehicle for air travel:',
            options: ['سفينة 🚢', 'طائرة ✈️', 'دراجة 🚲', 'قطار 🚆'],
            correctOptionIndex: 1,
            correctAnswer: 'طائرة ✈️',
          ),
        ],
      ),
    ];

    _gamesCatalog['default'] = games;
  }

  @override
  Future<List<DailyTask>> getDailyTasks({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  }) async {
    final key = '${schoolCode}_$studentId';
    if (_studentTasks.containsKey(key) && _studentTasks[key]!.isNotEmpty) {
      return _studentTasks[key]!;
    }

    // Generate fresh tasks deterministically using the task generator
    final defaultProfile = LearningProfile(
      userId: 'stu_sami_01',
      targetLanguage: 'ar_levantine',
      estimatedCefrLevel: CefrLevel.a2,
      overallScore: 75,
      comprehensionScore: 80,
      vocabularyScore: 78,
      grammarScore: 70,
      listeningScore: 82,
      speakingScore: 78,
      currentLessonId: 'les_01',
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 9, 21),
    );

    final defaultProgress = LearnerProgress(
      completedLessonIds: const ['les_intro_00'],
      lastSessionDate: DateTime(2026, 9, 21),
      totalXp: 450,
      dailyStreak: 5,
    );

    final generated = _taskGenerator.generateDailyTasks(
      profile: defaultProfile,
      progress: defaultProgress,
      vocabularyList: const [],
      availableLessons: const [
        Lesson(
          id: 'les_01',
          moduleId: 'mod_01',
          month: 1,
          order: 1,
          title: 'At the Cafe & Restaurant',
          titleArabic: 'في المقهى والمطعم',
          description: 'Ordering food, drinks, and asking for the bill',
          descriptionArabic: 'طلب المأكولات والمشروبات ودفع الحساب بطلاقة',
          cefrLevel: CefrLevel.a2,
          primarySkill: LearningSkill.speaking,
          estimatedMinutes: 8,
          steps: [],
        ),
      ],
      isChild: isChild,
    );

    _studentTasks[key] = generated;

    // Initialize summary if absent
    if (!_studentSummaries.containsKey(key)) {
      _studentSummaries[key] = StudentProgressSummary(
        studentId: studentId,
        totalXp: 450,
        streakDays: 5,
        completedTasksTodayCount: 0,
        totalTasksTodayCount: generated.length,
        todayProgressRatio: 0.0,
        currentLevel: 'A2 - مبتدئ متقدم',
        hasCompletedDailyGoal: false,
        dailyGoalTarget: 3,
      );
    }

    return generated;
  }

  @override
  Future<DailyTask> completeDailyTask({
    required String studentId,
    required String taskId,
    required String schoolCode,
  }) async {
    final key = '${schoolCode}_$studentId';
    final tasks = await getDailyTasks(
      studentId: studentId,
      schoolCode: schoolCode,
    );

    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw ArgumentError('Task with ID $taskId not found');
    }

    final task = tasks[index];
    if (task.completed) {
      return task; // already completed
    }

    final updatedTask = task.copyWith(
      completed: true,
      status: DailyTaskStatus.completed,
      progress: 1.0,
    );

    tasks[index] = updatedTask;
    _studentTasks[key] = tasks;

    // Update Student Summary & XP
    final currentSummary =
        _studentSummaries[key] ?? StudentProgressSummary.initial(studentId);
    final completedCount = tasks.where((t) => t.completed).length;
    final totalTasks = tasks.length;
    final newRatio = (completedCount / (totalTasks > 0 ? totalTasks : 1)).clamp(
      0.0,
      1.0,
    );
    final hasGoal = completedCount >= currentSummary.dailyGoalTarget;

    _studentSummaries[key] = StudentProgressSummary(
      studentId: studentId,
      totalXp: currentSummary.totalXp + task.xpReward,
      streakDays: currentSummary.streakDays,
      completedTasksTodayCount: completedCount,
      totalTasksTodayCount: totalTasks,
      todayProgressRatio: newRatio,
      currentLevel: currentSummary.currentLevel,
      hasCompletedDailyGoal: hasGoal,
      dailyGoalTarget: currentSummary.dailyGoalTarget,
    );

    return updatedTask;
  }

  @override
  Future<List<GameActivity>> getAvailableGames({
    required String studentId,
    required String schoolCode,
    bool isChild = false,
  }) async {
    final list = _gamesCatalog['default'] ?? [];
    if (isChild) {
      return list.where((g) => g.isChildFriendly).toList();
    }
    return list;
  }

  @override
  Future<GameActivity?> getGameById({
    required String gameId,
    required String studentId,
    required String schoolCode,
  }) async {
    final games = await getAvailableGames(
      studentId: studentId,
      schoolCode: schoolCode,
    );
    try {
      return games.firstWhere((g) => g.id == gameId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GameResult> submitGameResult({
    required String studentId,
    required String schoolCode,
    required GameResult result,
  }) async {
    final key = '${schoolCode}_$studentId';

    // Auto complete matching daily game task if applicable
    final tasks = await getDailyTasks(
      studentId: studentId,
      schoolCode: schoolCode,
    );
    final matchingTask =
        tasks
            .where(
              (t) => t.gameId == result.gameId || t.type == DailyTaskType.game,
            )
            .firstOrNull;

    if (matchingTask != null && !matchingTask.completed && result.passed) {
      await completeDailyTask(
        studentId: studentId,
        taskId: matchingTask.id,
        schoolCode: schoolCode,
      );
    } else {
      // Award XP directly if not tied to task
      final currentSummary =
          _studentSummaries[key] ?? StudentProgressSummary.initial(studentId);
      _studentSummaries[key] = StudentProgressSummary(
        studentId: studentId,
        totalXp: currentSummary.totalXp + result.earnedXp,
        streakDays: currentSummary.streakDays,
        completedTasksTodayCount: currentSummary.completedTasksTodayCount,
        totalTasksTodayCount: currentSummary.totalTasksTodayCount,
        todayProgressRatio: currentSummary.todayProgressRatio,
        currentLevel: currentSummary.currentLevel,
        hasCompletedDailyGoal: currentSummary.hasCompletedDailyGoal,
        dailyGoalTarget: currentSummary.dailyGoalTarget,
      );
    }

    return result;
  }

  @override
  Future<StudentProgressSummary> getStudentProgressSummary({
    required String studentId,
    required String schoolCode,
  }) async {
    final key = '${schoolCode}_$studentId';
    if (_studentSummaries.containsKey(key)) {
      return _studentSummaries[key]!;
    }
    // Initialize tasks and summary
    await getDailyTasks(studentId: studentId, schoolCode: schoolCode);
    return _studentSummaries[key] ?? StudentProgressSummary.initial(studentId);
  }

  @override
  Future<List<String>> getStudentAchievements({
    required String studentId,
    required String schoolCode,
  }) async {
    final key = '${schoolCode}_$studentId';
    if (_studentAchievements.containsKey(key)) {
      return _studentAchievements[key]!;
    }

    final summary = await getStudentProgressSummary(
      studentId: studentId,
      schoolCode: schoolCode,
    );

    final list = <String>[];
    if (summary.streakDays >= 3) {
      list.add('🔥 شعلة الالتزام: 3 أيام متتالية');
    }
    if (summary.totalXp >= 100) {
      list.add('⭐ مستكشف المفردات: تخطي 100 نقطة XP');
    }
    if (summary.completedTasksTodayCount >= 1) {
      list.add('🎯 الانطلاقة اليومية: إتمام أول نشاط اليوم');
    }

    _studentAchievements[key] = list;
    return list;
  }
}
