import '../../../onboarding/domain/models/age_group.dart';
import '../../../placement/domain/models/cefr_level.dart';
import '../../../learning/domain/models/learning_skill.dart';
import '../models/exam_models.dart';

/// Deterministic service for generating structured milestone and checkpoint exams.
class ExamGenerator {
  const ExamGenerator();

  /// Generates the list of available milestone and checkpoint exams for the learner.
  List<Exam> generateAvailableExams({
    required String targetLanguage,
    required CefrLevel cefrLevel,
    required AgeGroup? ageGroup,
  }) {
    return [
      generateMonth1MilestoneExam(
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        ageGroup: ageGroup,
      ),
      generateMonth2MilestoneExam(
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        ageGroup: ageGroup,
      ),
      generateMonth3MilestoneExam(
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        ageGroup: ageGroup,
      ),
      generateSkillCheckpointExam(
        skill: LearningSkill.speaking,
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        ageGroup: ageGroup,
      ),
    ];
  }

  /// Generates Month 1 Milestone Exam (Foundations & Core Skills).
  Exam generateMonth1MilestoneExam({
    required String targetLanguage,
    required CefrLevel cefrLevel,
    required AgeGroup? ageGroup,
  }) {
    final isChild = ageGroup == AgeGroup.age6_10;

    return Exam(
      id: 'exam_month_1',
      titleArabic: 'اختبار الشهر الأول: إتقان الأساسيات',
      titleEnglish: 'Month 1 Milestone: Foundation Mastery',
      descriptionArabic:
          'تقييم شامل لمهاراتك في التحيات، الضمائر، القواعد الأساسية، النطق، والتواصل البسيط.',
      descriptionEnglish:
          'Comprehensive assessment measuring greetings, pronouns, basic grammar, listening, and speaking.',
      targetLanguage: targetLanguage,
      cefrLevel: cefrLevel,
      type: ExamType.monthlyMilestone,
      month: 1,
      estimatedMinutes: isChild ? 8 : 15,
      sections: [
        // Section 1: Vocabulary
        ExamSection(
          id: 'sec_vocab_1',
          titleArabic: 'المفردات والسياق',
          titleEnglish: 'Vocabulary & Context',
          skill: LearningSkill.vocabulary,
          questions: [
            const ExamQuestion(
              id: 'q_v1',
              sectionId: 'sec_vocab_1',
              type: ExamQuestionType.vocabularySelection,
              promptText: 'Nice to meet you',
              promptSubtext: 'اختر المعنى الدقيق للعبارة في سياق التعارف:',
              options: [
                'صباح الخير يا صديقي',
                'فرصة سعيدة بلقائك',
                'مع السلامة، إلى اللقاء',
                'شكرًا جزيلاً على المساعدة',
              ],
              correctOptionIndex: 1,
              points: 10,
            ),
            if (!isChild)
              const ExamQuestion(
                id: 'q_v2',
                sectionId: 'sec_vocab_1',
                type: ExamQuestionType.vocabularySelection,
                promptText: 'I would like to order a bottle of water.',
                promptSubtext: 'ما معنى الكلمة "order" في هذه الجملة؟',
                options: ['يرتب', 'يطلب', 'يبيع', 'يشرب'],
                correctOptionIndex: 1,
                points: 10,
              ),
          ],
        ),

        // Section 2: Grammar & Sentence Structure
        ExamSection(
          id: 'sec_gram_1',
          titleArabic: 'القواعد والتراكيب',
          titleEnglish: 'Grammar & Structure',
          skill: LearningSkill.grammar,
          questions: [
            const ExamQuestion(
              id: 'q_g1',
              sectionId: 'sec_gram_1',
              type: ExamQuestionType.grammarUsage,
              promptText: 'She _______ from Jordan.',
              promptSubtext: 'اختر الفعل المساعد المناسب للفاعل (She):',
              options: ['am', 'is', 'are', 'be'],
              correctOptionIndex: 1,
              points: 10,
            ),
            if (!isChild)
              const ExamQuestion(
                id: 'q_g2',
                sectionId: 'sec_gram_1',
                type: ExamQuestionType.grammarUsage,
                promptText: 'Yesterday, I _______ to the traditional market.',
                promptSubtext: 'اختر الصيغة الماضية الصحيحة للفعل (go):',
                options: ['go', 'goes', 'went', 'gone'],
                correctOptionIndex: 2,
                points: 10,
              ),
          ],
        ),

        // Section 3: Reading Comprehension
        ExamSection(
          id: 'sec_read_1',
          titleArabic: 'فهم المقروء',
          titleEnglish: 'Reading Comprehension',
          skill: LearningSkill.reading,
          questions: [
            const ExamQuestion(
              id: 'q_r1',
              sectionId: 'sec_read_1',
              type: ExamQuestionType.readingComprehension,
              passageText:
                  'Hello! My name is Tareq. I am 22 years old and I live in Amman. I study computer engineering at the university. Every morning, I drink Arabic coffee before classes.',
              promptText: 'Where does Tareq live?',
              promptSubtext: 'بناءً على النص أعلاه، أين يعيش طارق؟',
              options: ['Aqaba', 'Amman', 'London', 'Dubai'],
              correctOptionIndex: 1,
              points: 10,
            ),
            if (!isChild)
              const ExamQuestion(
                id: 'q_r2',
                sectionId: 'sec_read_1',
                type: ExamQuestionType.readingComprehension,
                passageText:
                    'Tareq studies computer engineering and enjoys practicing English with his international friends on weekends.',
                promptText: 'What does Tareq study?',
                promptSubtext: 'ماذا يدرس طارق في الجامعة؟',
                options: [
                  'Medicine',
                  'Computer Engineering',
                  'Law',
                  'Business',
                ],
                correctOptionIndex: 1,
                points: 10,
              ),
          ],
        ),

        // Section 4: Listening Comprehension
        ExamSection(
          id: 'sec_list_1',
          titleArabic: 'الاستماع والفهم',
          titleEnglish: 'Listening Comprehension',
          skill: LearningSkill.listening,
          questions: [
            const ExamQuestion(
              id: 'q_l1',
              sectionId: 'sec_list_1',
              type: ExamQuestionType.listeningComprehension,
              textToSpeak:
                  'The flight to London departs at seven in the morning.',
              promptText: 'استمع للتسجيل الصوتي ثم أجب عن السؤال:',
              promptSubtext: 'What time does the flight depart?',
              options: [
                '7:00 AM (السابعة صباحاً)',
                '7:00 PM (السابعة مساءً)',
                '9:00 AM (التاسعة صباحاً)',
                '11:00 AM (الحادية عشر صباحاً)',
              ],
              correctOptionIndex: 0,
              points: 10,
            ),
          ],
        ),

        // Section 5: Speaking & Pronunciation
        ExamSection(
          id: 'sec_spk_1',
          titleArabic: 'النطق والتحدث',
          titleEnglish: 'Speaking & Pronunciation',
          skill: LearningSkill.speaking,
          questions: [
            const ExamQuestion(
              id: 'q_s1',
              sectionId: 'sec_spk_1',
              type: ExamQuestionType.speakingProduction,
              promptText: 'Good morning, how are you today?',
              promptSubtext: 'اضغط على الميكروفون وانطق الجملة بوضوح:',
              targetSpokenPhrase: 'Good morning how are you today',
              options: [],
              correctOptionIndex: 0,
              points: 15,
            ),
          ],
        ),

        // Section 6: Practical Communication
        ExamSection(
          id: 'sec_comm_1',
          titleArabic: 'التواصل الواقعي',
          titleEnglish: 'Practical Communication',
          skill: LearningSkill.fluency,
          questions: [
            const ExamQuestion(
              id: 'q_c1',
              sectionId: 'sec_comm_1',
              type: ExamQuestionType.practicalCommunication,
              promptText:
                  'A tourist asks you: "Excuse me, where is the nearest pharmacy?"',
              promptSubtext: 'اختر الرد الأنسب والأكثر تهذيباً في هذا الموقف:',
              options: [
                'Go straight and turn right at the bank.',
                'I do not like pharmacies.',
                'No, thank you very much.',
                'Yes, I have two brothers.',
              ],
              correctOptionIndex: 0,
              points: 15,
            ),
          ],
        ),
      ],
    );
  }

  /// Generates Month 2 Milestone Exam (Real-Life Scenarios).
  Exam generateMonth2MilestoneExam({
    required String targetLanguage,
    required CefrLevel cefrLevel,
    required AgeGroup? ageGroup,
  }) {
    return Exam(
      id: 'exam_month_2',
      titleArabic: 'اختبار الشهر الثاني: مواقف الحياة الواقعية',
      titleEnglish: 'Month 2 Milestone: Real-Life Scenarios',
      descriptionArabic:
          'تقييم قدرتك على التعامل في المطاعم، الفنادق، طلب المساعدة، وتوجيه الاتجاهات.',
      descriptionEnglish:
          'Evaluate conversational fluency in dining, hotels, navigation, and professional interactions.',
      targetLanguage: targetLanguage,
      cefrLevel: cefrLevel,
      type: ExamType.monthlyMilestone,
      month: 2,
      estimatedMinutes: 18,
      sections: [
        ExamSection(
          id: 'sec_m2_vocab',
          titleArabic: 'مفردات المواقف',
          titleEnglish: 'Situational Vocabulary',
          skill: LearningSkill.vocabulary,
          questions: [
            const ExamQuestion(
              id: 'q_m2_v1',
              sectionId: 'sec_m2_vocab',
              type: ExamQuestionType.vocabularySelection,
              promptText: 'Could I have the bill, please?',
              promptSubtext: 'أين ومتى تستخدم هذه العبارة؟',
              options: [
                'في المطعم عند الانتهاء من تناول الوجبة',
                'في المطار عند تسجيل الحقائب',
                'في الجامعة عند بدء المحاضرة',
                'في الفندق عند تسجيل الدخول',
              ],
              correctOptionIndex: 0,
              points: 10,
            ),
          ],
        ),
        ExamSection(
          id: 'sec_m2_comm',
          titleArabic: 'التواصل وسرعة الاستجابة',
          titleEnglish: 'Communication & Response',
          skill: LearningSkill.fluency,
          questions: [
            const ExamQuestion(
              id: 'q_m2_c1',
              sectionId: 'sec_m2_comm',
              type: ExamQuestionType.practicalCommunication,
              promptText:
                  'The hotel receptionist asks: "Would you prefer a room with a city view or sea view?"',
              promptSubtext: 'اختر الإجابة المناسبة:',
              options: [
                'I would prefer a room with a city view, please.',
                'I arrived yesterday at the airport.',
                'The food was very delicious.',
                'Yes, I can play football.',
              ],
              correctOptionIndex: 0,
              points: 15,
            ),
          ],
        ),
      ],
    );
  }

  /// Generates Month 3 Milestone Exam (Spontaneous Fluency & Storytelling).
  Exam generateMonth3MilestoneExam({
    required String targetLanguage,
    required CefrLevel cefrLevel,
    required AgeGroup? ageGroup,
  }) {
    return Exam(
      id: 'exam_month_3',
      titleArabic: 'اختبار الشهر الثالث: الطلاقة وسرد القصص',
      titleEnglish: 'Month 3 Milestone: Natural Fluency',
      descriptionArabic:
          'تقييم التعبير عن الرأي، مناقشة الأفكار، والتحدث العفوي والتلقائي.',
      descriptionEnglish:
          'Evaluate spontaneous discussions, opinion sharing, and natural speech rhythm.',
      targetLanguage: targetLanguage,
      cefrLevel: cefrLevel,
      type: ExamType.monthlyMilestone,
      month: 3,
      estimatedMinutes: 20,
      sections: [
        ExamSection(
          id: 'sec_m3_read',
          titleArabic: 'فهم الأفكار المعقدة',
          titleEnglish: 'Complex Comprehension',
          skill: LearningSkill.reading,
          questions: [
            const ExamQuestion(
              id: 'q_m3_r1',
              sectionId: 'sec_m3_read',
              type: ExamQuestionType.readingComprehension,
              passageText:
                  'Remote work has transformed modern professional life, offering flexibility and eliminating daily commuting stress.',
              promptText: 'What is the main benefit discussed?',
              promptSubtext: 'ما هي الفائدة الأساسية المذكورة في النص؟',
              options: [
                'Flexibility and reduced commute stress',
                'Working in a crowded office',
                'Traveling only by airplane',
                'Having less free time',
              ],
              correctOptionIndex: 0,
              points: 15,
            ),
          ],
        ),
      ],
    );
  }

  /// Generates a focused Checkpoint exam for a single skill.
  Exam generateSkillCheckpointExam({
    required LearningSkill skill,
    required String targetLanguage,
    required CefrLevel cefrLevel,
    required AgeGroup? ageGroup,
  }) {
    return Exam(
      id: 'exam_checkpoint_${skill.name}',
      titleArabic: 'اختبار تقييم مهارة: ${skill.nameArabic}',
      titleEnglish: 'Checkpoint: ${skill.nameEnglish}',
      descriptionArabic:
          'اختبار مركز لقياس مستواك الحالي في مهارة ${skill.nameArabic} وتحديد نقاط التطوير.',
      descriptionEnglish:
          'Focused evaluation measuring your current proficiency in ${skill.nameEnglish}.',
      targetLanguage: targetLanguage,
      cefrLevel: cefrLevel,
      type: ExamType.skillCheckpoint,
      estimatedMinutes: 10,
      sections: [
        ExamSection(
          id: 'sec_chk_${skill.name}',
          titleArabic: skill.nameArabic,
          titleEnglish: skill.nameEnglish,
          skill: skill,
          questions: [
            const ExamQuestion(
              id: 'q_chk_1',
              sectionId: 'sec_chk_1',
              type: ExamQuestionType.speakingProduction,
              promptText: 'Tell me about your favorite hobby.',
              promptSubtext: 'تحدث باختصار عن هوايتك المفضلة:',
              targetSpokenPhrase: 'favorite hobby',
              options: [],
              correctOptionIndex: 0,
              points: 20,
            ),
          ],
        ),
      ],
    );
  }
}
