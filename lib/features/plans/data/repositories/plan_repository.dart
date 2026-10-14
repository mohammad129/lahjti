import '../../../../core/network/api_client.dart';
import '../../domain/models/plan_models.dart';

abstract class PlanRepository {
  Future<List<LearningPlan>> getPlans();
  Future<LearningPlan?> getPlanDetails(String planId);
  Future<bool> enrollInPlan(String planId);
  Future<List<PlanDay>> getPlanDays(String planId);
  Future<List<PlanActivity>> getDayActivities(String planId, int dayNumber);
  Future<Map<String, dynamic>> completeActivity(String activityId, Map<String, dynamic> data);
  Future<List<StudentMistakeItem>> getDueMistakes();
  Future<bool> reviewMistake(String mistakeId, {required bool isCorrect, int quality = 4});
}

class RemotePlanRepository implements PlanRepository {
  final ApiClient _apiClient;

  RemotePlanRepository(this._apiClient);

  @override
  Future<List<LearningPlan>> getPlans() async {
    try {
      final response = await _apiClient.get<dynamic>('/plans');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final list = (data['data'] as List)
            .map((item) => LearningPlan.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Fallback to pre-built seed plans
    }
    return _fallbackPlans;
  }

  @override
  Future<LearningPlan?> getPlanDetails(String planId) async {
    try {
      final response = await _apiClient.get<dynamic>('/plans/$planId');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return LearningPlan.fromJson(Map<String, dynamic>.from(data['data'] as Map));
      }
    } catch (_) {
      // Fallback
    }
    return _fallbackPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _fallbackPlans.first,
    );
  }

  @override
  Future<bool> enrollInPlan(String planId) async {
    try {
      final response = await _apiClient.post<dynamic>('/plans/$planId/enroll');
      final data = response.data;
      if (data is Map && data['success'] == true) return true;
    } catch (_) {
      // Fallback in-memory success
    }
    return true;
  }

  @override
  Future<List<PlanDay>> getPlanDays(String planId) async {
    try {
      final response = await _apiClient.get<dynamic>('/plans/$planId');
      final data = response.data;
      if (data is Map && data['data'] is Map && data['data']['days'] is List) {
        return (data['data']['days'] as List)
            .map((item) => PlanDay.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (_) {
      // Fallback
    }

    // Generate 60 days programmatically if not returned from server
    return List.generate(60, (index) {
      final dayNum = index + 1;
      return PlanDay(
        id: 'day-$dayNum',
        planId: planId,
        dayNumber: dayNum,
        titleAr: 'اليوم $dayNum: ${_getDayTitleAr(dayNum)}',
        titleEn: 'Day $dayNum: ${_getDayTitleEn(dayNum)}',
        descriptionAr: 'أنشطة تطبيقية مركزة لتطوير المهارات دون إجهاد',
        descriptionEn: 'Focused micro-activities for steady daily mastery',
        focusSkill: _getDaySkill(dayNum),
        xpReward: 100,
        isUnlocked: dayNum <= 2,
        isCompleted: dayNum == 1,
        activitiesCount: 9,
      );
    });
  }

  @override
  Future<List<PlanActivity>> getDayActivities(String planId, int dayNumber) async {
    try {
      final response = await _apiClient.get<dynamic>('/plans/$planId/days/$dayNumber/activities');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final list = (data['data'] as List)
            .map((item) => PlanActivity.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Fallback
    }
    return _generateDayActivities(dayNumber);
  }

  @override
  Future<Map<String, dynamic>> completeActivity(String activityId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/plans/activities/$activityId/complete',
        data: data,
      );
      if (response.data is Map && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
    } catch (_) {
      // Fallback
    }
    return {
      'pointsAwarded': 25,
      'encouragement': 'رائع جداً! استمر في تقدمك بثقة وخطوات ثابتة 🌟',
    };
  }

  @override
  Future<List<StudentMistakeItem>> getDueMistakes() async {
    try {
      final response = await _apiClient.get<dynamic>('/students/mistakes/due');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => StudentMistakeItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (_) {
      // Fallback
    }
    return _fallbackMistakes;
  }

  @override
  Future<bool> reviewMistake(String mistakeId, {required bool isCorrect, int quality = 4}) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/students/mistakes/$mistakeId/review',
        data: {'isCorrect': isCorrect, 'quality': quality},
      );
      if (response.data is Map && response.data['success'] == true) return true;
    } catch (_) {
      // Fallback
    }
    return true;
  }

  // --- Seed Data & Fallbacks ---

  static final List<LearningPlan> _fallbackPlans = [
    const LearningPlan(
      id: 'plan_60_days_intensive',
      titleAr: 'خطة الـ 60 يوماً المكثفة للطلاقة',
      titleEn: '60-Day Intensive English Fluency Path',
      descriptionAr: 'مسار يومي محكم من 60 يوماً مع 9 أنشطة تفاعلية خفيفة يومياً للوصول للثقة الكاملة في التحدث.',
      descriptionEn: 'Structured 60-day roadmap with 9 bite-sized daily micro-activities for speaking fluency.',
      targetAudience: 'all',
      durationDays: 60,
      level: 'A1-B2',
      icon: '🚀',
      isFeatured: true,
      isActive: true,
      isEnrolled: true,
      currentDay: 2,
      completedDays: 1,
      totalPoints: 120,
      progressPercent: 0.05,
    ),
    const LearningPlan(
      id: 'plan_conversation_mastery',
      titleAr: 'خطة إتقان المحادثة باللغة الإنجليزية',
      titleEn: 'English Conversation Mastery',
      descriptionAr: 'التركيز على لغة الحياة اليومية، ردود الفعل التلقائية، وكسر حاجز الخوف والتردد.',
      descriptionEn: 'Daily spoken dialogues, real-life reactions, and overcoming hesitation.',
      targetAudience: 'adults',
      durationDays: 45,
      level: 'A2-B2',
      icon: '💬',
      isFeatured: true,
      isActive: true,
    ),
    const LearningPlan(
      id: 'plan_job_interview',
      titleAr: 'خطة مقابلات العمل والإنجليزية المهنية',
      titleEn: 'Job Interviews & Workplace English',
      descriptionAr: 'نماذج إجابات الأسئلة الشائعة في المقابلات، مهارات العرض التقديمي، والمراسلات الرسمية.',
      descriptionEn: 'Interview winning phrases, presentation clarity, and professional business emails.',
      targetAudience: 'professionals',
      durationDays: 30,
      level: 'B1-C1',
      icon: '💼',
      isFeatured: false,
      isActive: true,
    ),
    const LearningPlan(
      id: 'plan_travel',
      titleAr: 'خطة السفر والسياحة والمواقف الحية',
      titleEn: 'Travel & Tourism Survival English',
      descriptionAr: 'كل ما تحتاجه في المطار، الفندق، المطاعم، التسوق والمواصلات دون أي تعقيد.',
      descriptionEn: 'Airport navigation, hotel check-ins, dining out, and asking for directions effortlessly.',
      targetAudience: 'travelers',
      durationDays: 20,
      level: 'A1-B1',
      icon: '✈️',
      isFeatured: false,
      isActive: true,
    ),
    const LearningPlan(
      id: 'plan_academic',
      titleAr: 'خطة الإنجليزية للدراسة والجامعة',
      titleEn: 'Academic & College English',
      descriptionAr: 'الكتابة الأكاديمية، قراءة المقالات المعمقة، والاستعداد للاختبارات الدولية.',
      descriptionEn: 'Academic reading, vocabulary for higher education, and test readiness.',
      targetAudience: 'students',
      durationDays: 50,
      level: 'B1-C1',
      icon: '🎓',
      isFeatured: false,
      isActive: true,
    ),
    const LearningPlan(
      id: 'plan_school_support',
      titleAr: 'خطة التقوية لطلاب المدارس',
      titleEn: 'School Curriculum Reinforcement',
      descriptionAr: 'شرح مبسط لقواعد المنهاج، بنك أسئلة تدريبية، ومراجعة ذكية للأخطاء قبل الامتحانات.',
      descriptionEn: 'Simplified grammar rules, exam questions bank, and smart mistake review.',
      targetAudience: 'school',
      durationDays: 40,
      level: 'A1-B1',
      icon: '🎒',
      isFeatured: false,
      isActive: true,
    ),
    const LearningPlan(
      id: 'plan_kids_foundation',
      titleAr: 'خطة التأسيس الممتعة للأطفال',
      titleEn: 'Kids English Fun Foundation',
      descriptionAr: 'أصوات الحروف، الكلمات المصورة، ألعاب تفاعلية شيقة، وأناشيد سهلة ومحببة.',
      descriptionEn: 'Phonics, picture vocabulary, joyful mini-games, and friendly audio clips.',
      targetAudience: 'kids',
      durationDays: 30,
      level: 'Starter',
      icon: '🎈',
      isFeatured: false,
      isActive: true,
    ),
  ];

  static String _getDayTitleAr(int day) {
    switch ((day - 1) % 10) {
      case 0:
        return 'التحيات وكسر الجليد بثقة';
      case 1:
        return 'التعريف بالنفس والاهتمامات';
      case 2:
        return 'السؤال عن الاتجاهات والمواقع';
      case 3:
        return 'طلب الطعام في المطعم والمقهى';
      case 4:
        return 'التسوق والتفاوض بلباقة';
      case 5:
        return 'الحديث عن الروتين اليومي';
      case 6:
        return 'التعبير عن المشاعر والرأي';
      case 7:
        return 'المواقف الطارئة وطلب المساعدة';
      case 8:
        return 'الاتصالات والمكالمات الهاتفية';
      default:
        return 'مراجعة المكتسبات والتطبيق العملي';
    }
  }

  static String _getDayTitleEn(int day) {
    switch ((day - 1) % 10) {
      case 0:
        return 'Greetings & Breaking the Ice';
      case 1:
        return 'Self Introduction & Interests';
      case 2:
        return 'Asking for Directions';
      case 3:
        return 'Ordering at Cafes & Restaurants';
      case 4:
        return 'Shopping & Polite Requests';
      case 5:
        return 'Daily Routines & Schedules';
      case 6:
        return 'Expressing Opinions & Feelings';
      case 7:
        return 'Emergency Help & Questions';
      case 8:
        return 'Phone Calls & Messaging';
      default:
        return 'Milestone Review & Real Practice';
    }
  }

  static String _getDaySkill(int day) {
    final mod = day % 4;
    if (mod == 1) return 'speaking';
    if (mod == 2) return 'listening';
    if (mod == 3) return 'vocab';
    return 'grammar';
  }

  static List<PlanActivity> _generateDayActivities(int dayNumber) {
    return [
      PlanActivity(
        id: 'act_${dayNumber}_1',
        planDayId: 'day_$dayNumber',
        activityType: 'quick_review',
        orderIndex: 1,
        titleAr: '1. مراجعة سريعة لما سبق',
        titleEn: '1. Quick Memory Refresh',
        instructionAr: 'تذكر سريع لأهم عبارة تدربت عليها أمس لترسيخ الذاكرة.',
        instructionEn: 'Quick recall of yesterday’s key phrase.',
        contentJson: {
          'prompt': 'ما معنى جملة: "How are you doing today?"',
          'options': ['كيف حالك اليوم؟', 'أين تذهب اليوم؟', 'كم الساعة الآن؟'],
          'correctAnswer': 'كيف حالك اليوم؟',
          'explanation': 'تستخدم للسؤال الودي عن الحال في بداية الحديث.',
        },
        xpReward: 10,
        estimatedMinutes: 2,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_2',
        planDayId: 'day_$dayNumber',
        activityType: 'vocab',
        orderIndex: 2,
        titleAr: '2. مفردات اليوم الأساسية (5 كلمات)',
        titleEn: '2. Today’s Core 5 Words',
        instructionAr: 'احفظ هذه الكلمات الخمس واستمع لنطقها الواضح.',
        instructionEn: 'Learn these 5 essential words with clear audio.',
        contentJson: {
          'words': [
            {'word': 'Appreciate', 'arabic': 'يقدّر / يشكر', 'example': 'I really appreciate your help.'},
            {'word': 'Available', 'arabic': 'متاح / متفرغ', 'example': 'Are you available tomorrow?'},
            {'word': 'Convenient', 'arabic': 'مناسب / ملائم', 'example': 'Is this time convenient for you?'},
            {'word': 'Recommend', 'arabic': 'يوصي / يقترح', 'example': 'What do you recommend?'},
            {'word': 'Delighted', 'arabic': 'مسرور جداً', 'example': 'I am delighted to meet you.'},
          ],
        },
        xpReward: 15,
        estimatedMinutes: 3,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_3',
        planDayId: 'day_$dayNumber',
        activityType: 'listening',
        orderIndex: 3,
        titleAr: '3. استماع وفهم (مقطع صوتي مسجل)',
        titleEn: '3. Listening Comprehension (Pre-recorded)',
        instructionAr: 'استمع للمحادثة الصوتية بتركيز ثم أجب عن السؤال.',
        instructionEn: 'Listen to the audio clip and select the correct answer.',
        contentJson: {
          'audioTranscript': 'Hello Sarah! Could we reschedule our meeting to 4 PM? That would be much more convenient.',
          'question': 'ما الذي يطلبه المتحدث في التسجيل؟',
          'options': ['تأجيل الاجتماع للساعة 4', 'إلغاء الاجتماع تماماً', 'عقد الاجتماع في الصباح'],
          'correctAnswer': 'تأجيل الاجتماع للساعة 4',
        },
        xpReward: 20,
        estimatedMinutes: 3,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_4',
        planDayId: 'day_$dayNumber',
        activityType: 'dialogue',
        orderIndex: 4,
        titleAr: '4. محادثة وتطبيق جمل حية',
        titleEn: '4. Dialogue & Real-life Sentence Flow',
        instructionAr: 'رتب الجمل لتكوين حوار طبيعي ولبق.',
        instructionEn: 'Arrange the phrases to create a natural conversation.',
        contentJson: {
          'scenario': 'لقاء في مقهى وترتيب موعد',
          'lines': [
            'Hi Omar, it is so good to see you!',
            'Good to see you too! Would you like some coffee?',
            'Yes please, I would love a cappuccino.',
          ],
        },
        xpReward: 15,
        estimatedMinutes: 3,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_5',
        planDayId: 'day_$dayNumber',
        activityType: 'grammar',
        orderIndex: 5,
        titleAr: '5. قاعدة مبسطة وسريعة (كبسولة لغوية)',
        titleEn: '5. Grammar Capsule in a Minute',
        instructionAr: 'قاعدة سهلة في دقيقة واحدة دون مصطلحات معقدة.',
        instructionEn: 'Simple grammar tip without confusing jargon.',
        contentJson: {
          'ruleTitle': 'استخدام Would like بدلاً من Want للمزيد من اللباقة',
          'explanation': 'بدل أن تقول "I want coffee"، الأفضل والألطف في المحادثة أن تقول: "I would like a coffee, please".',
          'quizQuestion': 'أي الجمل التالية أكثر لباقة عند الطلب؟',
          'quizOptions': ['I would like some water, please.', 'Give me water now.'],
          'correctAnswer': 'I would like some water, please.',
        },
        xpReward: 15,
        estimatedMinutes: 2,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_6',
        planDayId: 'day_$dayNumber',
        activityType: 'pronunciation',
        orderIndex: 6,
        titleAr: '6. تمرين نطق ولهجة طبيعية',
        titleEn: '6. Pronunciation & Natural Accent',
        instructionAr: 'لاحظ كيف يتم وصل الكلمات بسلاسة دون تقطيع.',
        instructionEn: 'Notice how native speakers link words naturally.',
        contentJson: {
          'focusPhrase': 'Could you please...?',
          'phoneticTip': 'تُنطق كأنها كلمة واحدة: "Could-you" (كود-يو)',
          'practiceSentence': 'Could you please send me the file?',
        },
        xpReward: 15,
        estimatedMinutes: 2,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_7',
        planDayId: 'day_$dayNumber',
        activityType: 'mini_game',
        orderIndex: 7,
        titleAr: '7. لعبة خفيفة وسريعة (تركيب الكلمات)',
        titleEn: '7. Mini Word Scramble Game',
        instructionAr: 'كون الكلمة الصحيحة من الحروف المبعثرة.',
        instructionEn: 'Unscramble the letters to reveal the target word.',
        contentJson: {
          'hint': 'تعني "مريح أو ملائم في الوقت"',
          'scrambled': ['V', 'E', 'N', 'C', 'O', 'I', 'E', 'N', 'T', 'N'],
          'correctWord': 'CONVENIENT',
        },
        xpReward: 20,
        estimatedMinutes: 3,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_8',
        planDayId: 'day_$dayNumber',
        activityType: 'quick_quiz',
        orderIndex: 8,
        titleAr: '8. اختبار ختامي سريع (3 أسئلة)',
        titleEn: '8. Daily Mastery Quiz (3 Questions)',
        instructionAr: 'أجب عن الأسئلة للتأكد من استيعابك الكامل لليوم.',
        instructionEn: 'Answer these 3 quick questions to lock in today’s gains.',
        contentJson: {
          'questions': [
            {
              'q': 'What is the opposite of "Available"?',
              'options': ['Busy / Unavailable', 'Happy', 'Early'],
              'correct': 'Busy / Unavailable',
            },
            {
              'q': 'Complete: "I really _____ your support."',
              'options': ['appreciate', 'appreciating', 'appreciates'],
              'correct': 'appreciate',
            },
            {
              'q': 'Choose the polite request:',
              'options': ['Could you help me?', 'You help me.'],
              'correct': 'Could you help me?',
            },
          ],
        },
        xpReward: 25,
        estimatedMinutes: 3,
      ),
      PlanActivity(
        id: 'act_${dayNumber}_9',
        planDayId: 'day_$dayNumber',
        activityType: 'day_summary',
        orderIndex: 9,
        titleAr: '9. ملخص الإنجاز والتشجيع اليومي',
        titleEn: '9. Daily Summary & Celebration',
        instructionAr: 'أحسنت صنعاً! إليك ملخص إنجازك اليوم وكلمة تحفيزية.',
        instructionEn: 'Congratulations! Here is your daily achievement summary.',
        contentJson: {
          'xpEarned': 150,
          'streakDays': dayNumber,
          'quote': 'الاستمرار اليومي ولو لـ 15 دقيقة يصنع فارقاً هائلاً في طلاقتك اللغوية. أنت تسير على الطريق الصحيح!',
        },
        xpReward: 30,
        estimatedMinutes: 2,
      ),
    ];
  }

  static final List<StudentMistakeItem> _fallbackMistakes = [
    StudentMistakeItem(
      id: 'mstk_1',
      studentId: 'std_demo',
      sourceType: 'activity',
      questionPrompt: 'What is the correct polite request for water in a restaurant?',
      studentAnswer: 'Give me water now.',
      correctAnswer: 'Could I have some water, please?',
      explanation: 'In English, polite requests usually begin with "Could I have..." or "Would you please...".',
      repetitionInterval: 1,
      easeFactor: 2.5,
      reviewCount: 1,
      nextReviewAt: DateTime.now(),
      isDue: true,
    ),
    StudentMistakeItem(
      id: 'mstk_2',
      studentId: 'std_demo',
      sourceType: 'exam',
      questionPrompt: 'Select the past tense of the irregular verb "teach":',
      studentAnswer: 'teached',
      correctAnswer: 'taught',
      explanation: 'The verb "teach" is irregular. Its past tense is "taught", not "teached".',
      repetitionInterval: 1,
      easeFactor: 2.4,
      reviewCount: 2,
      nextReviewAt: DateTime.now(),
      isDue: true,
    ),
  ];
}
