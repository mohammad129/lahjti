import '../../../onboarding/domain/models/age_group.dart';
import '../../../onboarding/domain/models/learning_goal.dart';
import '../../../onboarding/domain/models/native_language.dart';
import '../../../onboarding/domain/models/supported_language.dart';
import '../../domain/models/cefr_level.dart';
import '../../domain/models/placement_question.dart';
import '../../domain/models/question_type.dart';
import '../../domain/providers/placement_content_provider.dart';

/// Mock / Development implementation of [PlacementContentProvider].
///
/// NOTE: This provider exists solely to validate the application architecture and
/// dynamic test suite. It is NOT the production AI curriculum generator.
class MockPlacementContentProvider implements PlacementContentProvider {
  const MockPlacementContentProvider();

  @override
  Future<PlacementQuestion> getNextQuestion({
    required SupportedLanguage targetLanguage,
    required NativeLanguage nativeLanguage,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
    required CefrLevel difficulty,
    required List<String> previousQuestionIds,
  }) async {
    // Generate deterministic question fixtures matching parameters
    final pool = _getQuestionPool(
      targetLanguage: targetLanguage,
      difficulty: difficulty,
      ageGroup: ageGroup,
      learningGoal: learningGoal,
    );

    // Pick first available question not in previous IDs
    final question = pool.firstWhere(
      (q) => !previousQuestionIds.contains(q.id),
      orElse:
          () => _buildFallbackQuestion(
            targetLanguage: targetLanguage,
            difficulty: difficulty,
            index: previousQuestionIds.length + 1,
          ),
    );

    return question;
  }

  List<PlacementQuestion> _getQuestionPool({
    required SupportedLanguage targetLanguage,
    required CefrLevel difficulty,
    required AgeGroup ageGroup,
    required LearningGoal learningGoal,
  }) {
    final langCode = targetLanguage.id;

    switch (difficulty) {
      case CefrLevel.preA1:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_preA1_1',
            type: QuestionType.vocabulary,
            targetLanguage: langCode,
            difficulty: CefrLevel.preA1,
            prompt: _getPreA1Prompt(langCode, 1),
            promptArabic: 'كيف بنحكي "مرحباً" أو "أهلاً" بهي اللغة؟',
            expectedSkills: ['basic_greeting'],
            hintsAllowed: true,
            hint: 'كلمة ترحيبية بسيطة تبدأ بحرف مألوف.',
          ),
          PlacementQuestion(
            id: 'q_${langCode}_preA1_2',
            type: QuestionType.translation,
            targetLanguage: langCode,
            difficulty: CefrLevel.preA1,
            prompt: _getPreA1Prompt(langCode, 2),
            promptArabic: 'كيف بنحكي كلمة "شكراً"؟',
            expectedSkills: ['courtesy_words'],
            hintsAllowed: true,
            hint: 'كلمة الشكر والامتنان المشهورة.',
          ),
          PlacementQuestion(
            id: 'q_${langCode}_preA1_3',
            type: QuestionType.comprehension,
            targetLanguage: langCode,
            difficulty: CefrLevel.preA1,
            prompt: _getPreA1Prompt(langCode, 3),
            promptArabic: 'كيف تحكي "نعم" و "لا"؟',
            expectedSkills: ['affirmation_negation'],
            hintsAllowed: false,
          ),
        ];

      case CefrLevel.a1:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_a1_1',
            type: QuestionType.sentenceConstruction,
            targetLanguage: langCode,
            difficulty: CefrLevel.a1,
            prompt: _getA1Prompt(langCode, 1),
            promptArabic: 'عرفني عن اسمك بجملة بسيطة.',
            expectedSkills: ['self_introduction'],
            hintsAllowed: true,
            hint: 'My name is... أو ما يعادلها.',
          ),
          PlacementQuestion(
            id: 'q_${langCode}_a1_2',
            type: QuestionType.vocabulary,
            targetLanguage: langCode,
            difficulty: CefrLevel.a1,
            prompt: _getA1Prompt(langCode, 2),
            promptArabic: 'كيف تسأل شخص "كيف حالك اليوم؟"',
            expectedSkills: ['inquiries'],
            hintsAllowed: false,
          ),
        ];

      case CefrLevel.a2:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_a2_1',
            type: QuestionType.freeResponse,
            targetLanguage: langCode,
            difficulty: CefrLevel.a2,
            prompt: _getA2Prompt(langCode, 1, learningGoal),
            promptArabic: 'احكيلي شو بتحب تعمل بأوقات فراغك؟',
            expectedSkills: ['daily_routine', 'likes_dislikes'],
            hintsAllowed: false,
          ),
          PlacementQuestion(
            id: 'q_${langCode}_a2_2',
            type: QuestionType.grammar,
            targetLanguage: langCode,
            difficulty: CefrLevel.a2,
            prompt: _getA2Prompt(langCode, 2, learningGoal),
            promptArabic: 'احكيلي شو عملت مبارح بجملة قصيرة في الماضي.',
            expectedSkills: ['past_tense'],
            hintsAllowed: true,
            hint: 'استخدم صيغة الماضي البسيط.',
          ),
        ];

      case CefrLevel.b1:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_b1_1',
            type: QuestionType.freeResponse,
            targetLanguage: langCode,
            difficulty: CefrLevel.b1,
            prompt: _getB1Prompt(langCode, 1, learningGoal),
            promptArabic: 'اوصف مكان زرته وحبيته وليش عجبك؟',
            expectedSkills: ['narrative', 'descriptive_language'],
            hintsAllowed: false,
          ),
        ];

      case CefrLevel.b2:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_b2_1',
            type: QuestionType.freeResponse,
            targetLanguage: langCode,
            difficulty: CefrLevel.b2,
            prompt: _getB2Prompt(langCode, 1),
            promptArabic: 'شو رأيك بالعمل عن بعد مقارنة بالعمل من المكتب؟',
            expectedSkills: ['opinion', 'argumentation'],
            hintsAllowed: false,
          ),
        ];

      case CefrLevel.c1:
      case CefrLevel.c2:
        return [
          PlacementQuestion(
            id: 'q_${langCode}_c1_1',
            type: QuestionType.freeResponse,
            targetLanguage: langCode,
            difficulty: difficulty,
            prompt: _getC1Prompt(langCode, 1),
            promptArabic:
                'ناقش أثر التكنولوجيا والذكاء الاصطناعي على مستقبل الوظائف.',
            expectedSkills: ['complex_discourse', 'nuance'],
            hintsAllowed: false,
          ),
        ];
    }
  }

  String _getPreA1Prompt(String lang, int variant) {
    if (variant == 1) {
      return lang == 'en' ? 'Say "Hello" or "Hi"' : 'Type the basic greeting.';
    } else if (variant == 2) {
      return lang == 'en' ? 'Say "Thank you"' : 'Type how to say thanks.';
    }
    return lang == 'en' ? 'Say "Yes" and "No"' : 'Type yes / no words.';
  }

  String _getA1Prompt(String lang, int variant) {
    if (variant == 1) {
      return lang == 'en'
          ? 'Introduce yourself: "My name is..."'
          : 'State your name in a short sentence.';
    }
    return lang == 'en'
        ? 'Ask someone: "How are you?"'
        : 'Ask a friend how they are doing.';
  }

  String _getA2Prompt(String lang, int variant, LearningGoal goal) {
    if (variant == 1) {
      return lang == 'en'
          ? 'What do you like to do on weekends?'
          : 'Describe your favorite hobby or free time activity.';
    }
    return lang == 'en'
        ? 'Tell me what you did yesterday.'
        : 'Describe one thing you did yesterday in the past.';
  }

  String _getB1Prompt(String lang, int variant, LearningGoal goal) {
    return lang == 'en'
        ? 'Describe a memorable trip you took and why you enjoyed it.'
        : 'Describe a memorable experience or journey.';
  }

  String _getB2Prompt(String lang, int variant) {
    return lang == 'en'
        ? 'Compare the advantages and disadvantages of remote work.'
        : 'Share your perspective on modern work flexibility.';
  }

  String _getC1Prompt(String lang, int variant) {
    return lang == 'en'
        ? 'Discuss how artificial intelligence will transform global education.'
        : 'Analyze the cultural and societal impact of emerging technologies.';
  }

  PlacementQuestion _buildFallbackQuestion({
    required SupportedLanguage targetLanguage,
    required CefrLevel difficulty,
    required int index,
  }) {
    return PlacementQuestion(
      id: 'q_${targetLanguage.id}_${difficulty.code}_$index',
      type: QuestionType.freeResponse,
      targetLanguage: targetLanguage.id,
      difficulty: difficulty,
      prompt: 'Share a thought about your day in ${targetLanguage.nameEn}.',
      promptArabic: 'شاركني فكرة أو جملة بسيطة باللغة المستهدفة.',
      expectedSkills: ['general_expression'],
    );
  }
}
