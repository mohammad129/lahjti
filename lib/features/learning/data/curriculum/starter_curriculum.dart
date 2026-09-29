import '../../../placement/domain/models/cefr_level.dart';
import '../../domain/models/learning_skill.dart';
import '../../domain/models/lesson_models.dart';
import '../../domain/models/vocabulary_item.dart';

/// Comprehensive starter curriculum for the 3-Month English Learning Journey.
class StarterCurriculum {
  StarterCurriculum._();

  static final List<CurriculumModule> modules = [
    // ==========================================
    // MONTH 1: FOUNDATION (الأساس المتين)
    // ==========================================
    CurriculumModule(
      id: 'mod_1',
      month: 1,
      theme: 'Greetings & Introductions',
      themeArabic: 'التحيات والتعريف بالنفس',
      description:
          'Master first impressions, greetings, and basic introductions.',
      descriptionArabic: 'تعلم كيف تُلقي التحية وتُعرف عن نفسك بثقة وسهولة.',
      iconEmoji: '👋',
      order: 1,
      lessons: [
        Lesson(
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
          targetSkills: const [
            LearningSkill.speaking,
            LearningSkill.vocabulary,
            LearningSkill.listening,
          ],
          targetVocabulary: const [
            'hello',
            'name',
            'nice',
            'meet',
            'good morning',
          ],
          grammarFocus: 'Verb to be (am / is / are) with personal pronouns',
          estimatedMinutes: 8,
          order: 1,
          steps: const [
            LessonStep(
              id: 'step_1_1_1',
              type: LessonStepType.introduction,
              title: 'Welcome to your first lesson!',
              titleArabic: 'أهلاً بك في أول درس!',
              content:
                  'In this lesson, we will learn how to greet someone and introduce yourself smoothly.',
              contentArabic:
                  'في هذا الدرس، رح نتعلم كيف نلقي التحية ونعرف عن أنفسنا بطريقة طبيعية وواثقة.',
            ),
            LessonStep(
              id: 'step_1_1_2',
              type: LessonStepType.examples,
              title: 'Key Phrases',
              titleArabic: 'أهم العبارات',
              content:
                  '• Hello, my name is...\n• Nice to meet you!\n• How are you today?',
              contentArabic:
                  '• مرحبًا، اسمي هو...\n• فرصة سعيدة بلقائك!\n• كيف حالك اليوم؟',
              targetPhrases: [
                'Hello, my name is...',
                'Nice to meet you!',
                'How are you?',
              ],
            ),
            LessonStep(
              id: 'step_1_1_3',
              type: LessonStepType.speakingActivity,
              title: 'Speak with your Tutor',
              titleArabic: 'تحدث مع معلمك الذكي',
              content: 'Say hello to your tutor and tell them your name.',
              contentArabic: 'ألقِ التحية على عباس أو دنيا وأخبرهم باسمك.',
              interactivePrompt: 'Say: "Hello! My name is..."',
            ),
          ],
        ),
        Lesson(
          id: 'lesson_1_2',
          moduleId: 'mod_1',
          month: 1,
          title: 'Where Are You From?',
          titleArabic: 'من أين أنت؟ (البلدان والجنسيات)',
          description:
              'Express your country, city of origin, and where you live.',
          descriptionArabic: 'تعلم كيف تتحدث عن بلدك ومدينتك ومكان إقامتك.',
          cefrLevel: CefrLevel.a1,
          primarySkill: LearningSkill.speaking,
          targetSkills: const [
            LearningSkill.vocabulary,
            LearningSkill.speaking,
          ],
          targetVocabulary: const ['country', 'city', 'from', 'live', 'Jordan'],
          grammarFocus: 'Prepositions of place (from, in)',
          estimatedMinutes: 8,
          order: 2,
          steps: const [
            LessonStep(
              id: 'step_1_2_1',
              type: LessonStepType.introduction,
              title: 'Talking about Origins',
              titleArabic: 'الحديث عن الأصول والبلدان',
              content:
                  'Learn how to answer "Where are you from?" and describe your hometown.',
              contentArabic:
                  'رح نتعلم نجاوب على سؤال "من أين أنت؟" ونحكي عن بلدنا.',
            ),
            LessonStep(
              id: 'step_1_2_2',
              type: LessonStepType.examples,
              title: 'Common Expressions',
              titleArabic: 'عبارات شائعة',
              content:
                  '• I am from Jordan.\n• I live in Amman.\n• Where do you live?',
              contentArabic: '• أنا من الأردن.\n• أعيش في عمّان.\n• أين تعيش؟',
              targetPhrases: [
                'I am from...',
                'I live in...',
                'Where do you live?',
              ],
            ),
          ],
        ),
        Lesson(
          id: 'lesson_1_3',
          moduleId: 'mod_1',
          month: 1,
          title: 'Numbers & Contact Info',
          titleArabic: 'الأرقام ومعلومات التواصل',
          description:
              'Exchange phone numbers, emails, and basic numbers 1 to 100.',
          descriptionArabic:
              'تعلم نطق الأرقام وتبادل أرقام الهواتف والبريد الإلكتروني.',
          cefrLevel: CefrLevel.a1,
          primarySkill: LearningSkill.listening,
          targetSkills: const [
            LearningSkill.listening,
            LearningSkill.vocabulary,
          ],
          targetVocabulary: const [
            'number',
            'phone',
            'email',
            'one',
            'two',
            'hundred',
          ],
          estimatedMinutes: 7,
          order: 3,
          steps: const [
            LessonStep(
              id: 'step_1_3_1',
              type: LessonStepType.introduction,
              title: 'Numbers in Everyday Life',
              titleArabic: 'الأرقام في الحياة اليومية',
              content:
                  'Master counting and spelling contact information accurately.',
              contentArabic:
                  'تعلم نطق الأرقام وكتابة الإيميل ورقم الهاتف بسهولة.',
            ),
          ],
        ),
      ],
    ),

    CurriculumModule(
      id: 'mod_2',
      month: 1,
      theme: 'Daily Life & Family',
      themeArabic: 'الحياة اليومية والعائلة',
      description:
          'Describe family members, daily habits, and household routines.',
      descriptionArabic:
          'تعلم الحديث عن أفراد العائلة والعادات والروتين اليومي.',
      iconEmoji: '🏡',
      order: 2,
      lessons: [
        Lesson(
          id: 'lesson_2_1',
          moduleId: 'mod_2',
          month: 1,
          title: 'My Family & Home',
          titleArabic: 'عائلتي ومنزلي',
          description: 'Talk about parents, siblings, and relationships.',
          descriptionArabic: 'تعلم أسماء أفراد الأسرة وكيفية وصفهم.',
          cefrLevel: CefrLevel.a1,
          primarySkill: LearningSkill.vocabulary,
          targetSkills: const [
            LearningSkill.vocabulary,
            LearningSkill.speaking,
          ],
          targetVocabulary: const [
            'father',
            'mother',
            'brother',
            'sister',
            'family',
            'house',
          ],
          estimatedMinutes: 8,
          order: 1,
          steps: const [
            LessonStep(
              id: 'step_2_1_1',
              type: LessonStepType.introduction,
              title: 'Family Members',
              titleArabic: 'أفراد الأسرة',
              content:
                  'Learn vocabulary for family members and describe your household.',
              contentArabic: 'مفردات العائلة وطرق وصف بيتك وعلاقاتك الأسرية.',
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // MONTH 2: REAL LIFE (الحياة الواقعية)
    // ==========================================
    CurriculumModule(
      id: 'mod_3',
      month: 2,
      theme: 'Food & Restaurants',
      themeArabic: 'المطاعم وطلب الطعام',
      description: 'Order meals, ask about menus, and pay the bill.',
      descriptionArabic:
          'تعلم طلب الوجبات وقراءة قائمة الطعام والحساب في المطعم.',
      iconEmoji: '🍽️',
      order: 3,
      lessons: [
        Lesson(
          id: 'lesson_3_1',
          moduleId: 'mod_3',
          month: 2,
          title: 'Ordering at a Restaurant',
          titleArabic: 'الطلب في المطعم',
          description:
              'Polite requests like "I would like...", questions about ingredients.',
          descriptionArabic: 'استخدام صيغ الطلب المؤدب والسؤال عن الأطباق.',
          cefrLevel: CefrLevel.a2,
          primarySkill: LearningSkill.speaking,
          targetSkills: const [LearningSkill.speaking, LearningSkill.listening],
          targetVocabulary: const [
            'menu',
            'water',
            'order',
            'bill',
            'delicious',
            'table',
          ],
          grammarFocus: 'Modal verbs for politeness (would like, could I have)',
          estimatedMinutes: 9,
          order: 1,
          steps: const [
            LessonStep(
              id: 'step_3_1_1',
              type: LessonStepType.introduction,
              title: 'At the Table',
              titleArabic: 'على طاولة المطعم',
              content:
                  'Learn how to order food politely and ask for the check.',
              contentArabic: 'تعلم عبارات الطلب الراقية وطلب الحساب من النادل.',
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // MONTH 3: NATURAL COMMUNICATION (الطلاقة والتواصل)
    // ==========================================
    CurriculumModule(
      id: 'mod_4',
      month: 3,
      theme: 'Expressing Opinions & Stories',
      themeArabic: 'التعبير عن الرأي وسرد القصص',
      description:
          'Engage in lively discussions, share past experiences, and defend ideas.',
      descriptionArabic:
          'المشاركة في نقاشات حية وسرد أحداث الماضي والتعبير عن الرأي.',
      iconEmoji: '💬',
      order: 4,
      lessons: [
        Lesson(
          id: 'lesson_4_1',
          moduleId: 'mod_4',
          month: 3,
          title: 'Sharing Past Experiences',
          titleArabic: 'سرد أحداث وتجارب الماضي',
          description:
              'Narrate what happened on your last vacation or weekend.',
          descriptionArabic:
              'سرد قصة عطلتك أو نهاية الأسبوع باستخدام الماضي البسيط.',
          cefrLevel: CefrLevel.b1,
          primarySkill: LearningSkill.fluency,
          targetSkills: const [
            LearningSkill.speaking,
            LearningSkill.grammar,
            LearningSkill.fluency,
          ],
          targetVocabulary: const [
            'yesterday',
            'travel',
            'experience',
            'interesting',
            'enjoyed',
          ],
          grammarFocus: 'Past Simple vs Past Continuous',
          estimatedMinutes: 10,
          order: 1,
          steps: const [
            LessonStep(
              id: 'step_4_1_1',
              type: LessonStepType.introduction,
              title: 'Storytelling in English',
              titleArabic: 'سرد القصص بالإنجليزية',
              content: 'Connect past events smoothly using transition words.',
              contentArabic:
                  'ربط الأحداث الماضية بطلاقة باستخدام أدوات الربط الزمنية.',
            ),
          ],
        ),
      ],
    ),
  ];

  static final List<VocabularyItem> starterVocabulary = [
    const VocabularyItem(
      id: 'v_hello',
      term: 'Hello',
      translationArabic: 'مرحبًا',
      phonetic: '/həˈloʊ/',
      exampleSentence: 'Hello, my name is Abbas.',
      exampleTranslationArabic: 'مرحبًا، اسمي عباس.',
      difficulty: CefrLevel.a1,
      category: 'Greetings',
    ),
    const VocabularyItem(
      id: 'v_meet',
      term: 'Nice to meet you',
      translationArabic: 'فرصة سعيدة بلقائك',
      phonetic: '/naɪs tuː miːt juː/',
      exampleSentence: 'It is very nice to meet you today.',
      exampleTranslationArabic: 'من دواعي سروري لقاؤك اليوم.',
      difficulty: CefrLevel.a1,
      category: 'Greetings',
    ),
    const VocabularyItem(
      id: 'v_thanks',
      term: 'Thank you',
      translationArabic: 'شكرًا لك',
      phonetic: '/θæŋk juː/',
      exampleSentence: 'Thank you for your valuable help.',
      exampleTranslationArabic: 'شكرًا لك على مساعدتك القيمة.',
      difficulty: CefrLevel.a1,
      category: 'Greetings',
    ),
    const VocabularyItem(
      id: 'v_went',
      term: 'Went',
      translationArabic: 'ذهب (ماضي)',
      phonetic: '/wɛnt/',
      exampleSentence: 'I went to the market yesterday.',
      exampleTranslationArabic: 'ذهبت إلى السوق بالأمس.',
      difficulty: CefrLevel.a1,
      category: 'Verbs',
    ),
    const VocabularyItem(
      id: 'v_order',
      term: 'Would like to order',
      translationArabic: 'أود أن أطلب',
      phonetic: '/wʊd laɪk tuː ˈɔːrdər/',
      exampleSentence: 'I would like to order a cup of coffee, please.',
      exampleTranslationArabic: 'أود طلب فنجان قهوة من فضلك.',
      difficulty: CefrLevel.a2,
      category: 'Restaurant',
    ),
    const VocabularyItem(
      id: 'v_water',
      term: 'Water',
      translationArabic: 'ماء',
      phonetic: '/ˈwɔːtər/',
      exampleSentence: 'Can I have a bottle of cold water?',
      exampleTranslationArabic: 'هل يمكنني الحصول على زجاجة ماء بارد؟',
      difficulty: CefrLevel.a1,
      category: 'Food',
    ),
    const VocabularyItem(
      id: 'v_family',
      term: 'Family',
      translationArabic: 'عائلة',
      phonetic: '/ˈfæməli/',
      exampleSentence: 'I love spending time with my family.',
      exampleTranslationArabic: 'أحب قضاء الوقت مع عائلتي.',
      difficulty: CefrLevel.a1,
      category: 'Family',
    ),
    const VocabularyItem(
      id: 'v_airport',
      term: 'Airport',
      translationArabic: 'مطار',
      phonetic: '/ˈerpɔːrt/',
      exampleSentence: 'We arrived at Queen Alia Airport early.',
      exampleTranslationArabic: 'وصلنا إلى مطار الملكة علياء مبكرًا.',
      difficulty: CefrLevel.a2,
      category: 'Travel',
    ),
    const VocabularyItem(
      id: 'v_work',
      term: 'Office',
      translationArabic: 'مكتب / عمل',
      phonetic: '/ˈɔːfɪs/',
      exampleSentence: 'I start working in the office at 9 AM.',
      exampleTranslationArabic: 'أبدأ العمل في المكتب عند التاسعة صباحًا.',
      difficulty: CefrLevel.a2,
      category: 'Work',
    ),
    const VocabularyItem(
      id: 'v_morning',
      term: 'Good morning',
      translationArabic: 'صباح الخير',
      phonetic: '/ɡʊd ˈmɔːrnɪŋ/',
      exampleSentence: 'Good morning everyone, have a great day.',
      exampleTranslationArabic: 'صباح الخير للجميع، أتمنى لكم يومًا رائعًا.',
      difficulty: CefrLevel.a1,
      category: 'Daily Life',
    ),
  ];
}
