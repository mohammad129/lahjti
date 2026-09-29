import {
  AiEvaluationOutput,
  AiEvaluationOutputSchema,
  EvaluateRequest,
} from '../schemas/evaluation_schemas.js';
import {
  AiTutorConversationOutput,
  AiTutorConversationOutputSchema,
  TutorConversationRequest,
} from '../schemas/tutor_conversation_schemas.js';
import {
  EvaluationContext,
  LanguageModelProvider,
} from './language_model_provider.js';

export class MockLanguageModelProvider implements LanguageModelProvider {
  readonly name = 'mock';

  async evaluate(
    request: EvaluateRequest,
    _context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    // 1. Handle skipped or empty responses
    if (
      request.skipped ||
      !request.response ||
      request.response.trim().length === 0
    ) {
      return AiEvaluationOutputSchema.parse({
        semanticScore: 0,
        grammarScore: 0,
        vocabularyScore: 0,
        comprehensionScore: 0,
        fluencyScore: 0,
        pronunciationScore: null,
        confidence: 1.0,
        detectedErrors: [],
        correctedAnswer: null,
        explanationArabic: 'عادي جدًا. هاي الخطوة بتساعدنا نعرف من وين نبدأ.',
        wasUnderstandable: false,
        difficultyRecommendation: 'decrease',
      });
    }

    const trimmed = request.response.trim();

    // 2. Simulate error trigger for test suites
    if (trimmed === 'SIMULATE_AI_ERROR') {
      throw new Error('Simulated upstream AI provider service failure');
    }

    if (trimmed === 'SIMULATE_INVALID_JSON') {
      // Return invalid data that will fail schema validation
      return {
        semanticScore: 999, // out of range!
        grammarScore: 100,
        vocabularyScore: 100,
        comprehensionScore: 100,
        fluencyScore: 100,
        pronunciationScore: null,
        confidence: 0.9,
        detectedErrors: [],
        explanationArabic: 'خطأ',
        wasUnderstandable: true,
        difficultyRecommendation: 'increase',
      } as unknown as AiEvaluationOutput;
    }

    // 3. Meaning correct but imperfect grammar (e.g. "I go yesterday" or similar)
    if (
      trimmed.toLowerCase().includes('go yesterday') ||
      trimmed.toLowerCase().includes('ayer')
    ) {
      return AiEvaluationOutputSchema.parse({
        semanticScore: 85,
        grammarScore: 60,
        vocabularyScore: 75,
        comprehensionScore: 90,
        fluencyScore: 70,
        pronunciationScore: null,
        confidence: 0.92,
        detectedErrors: [
          {
            type: 'grammar',
            original: 'go yesterday',
            correction: 'went yesterday',
            explanationArabic:
              'الفعل لازم يكون بصيغة الماضي لأن الجملة تحتوي على كلمة أمس.',
          },
        ],
        correctedAnswer: 'I went yesterday.',
        explanationArabic:
          'جوابك مفهوم وممتاز 👍 بس الفعل لازم يكون بالماضي لأنك بتحكي عن أمس.',
        wasUnderstandable: true,
        difficultyRecommendation: 'same',
      });
    }

    // 4. Short / weak answers (< 6 characters)
    if (trimmed.length < 6) {
      return AiEvaluationOutputSchema.parse({
        semanticScore: 40,
        grammarScore: 50,
        vocabularyScore: 40,
        comprehensionScore: 45,
        fluencyScore: 35,
        pronunciationScore: null,
        confidence: 0.85,
        detectedErrors: [
          {
            type: 'comprehension',
            original: trimmed,
            correction: 'Complete sentence',
            explanationArabic: 'الإجابة قصيرة جدًا، حاول إعطاء جملة كاملة.',
          },
        ],
        correctedAnswer: null,
        explanationArabic: 'ولا يهمك، خلينا نجرب إشي أبسط خطوة بخطوة.',
        wasUnderstandable: false,
        difficultyRecommendation: 'decrease',
      });
    }

    // 5. Normal / strong answers
    return AiEvaluationOutputSchema.parse({
      semanticScore: 90,
      grammarScore: 85,
      vocabularyScore: 88,
      comprehensionScore: 95,
      fluencyScore: 85,
      pronunciationScore: null,
      confidence: 0.95,
      detectedErrors: [],
      correctedAnswer: trimmed,
      explanationArabic: 'ممتاز جدًا 👏 صياغة صحيحة ومفهومة.',
      wasUnderstandable: true,
      difficultyRecommendation: 'increase',
    });
  }

  async conversation(
    request: TutorConversationRequest,
    _context: EvaluationContext
  ): Promise<AiTutorConversationOutput> {
    const trimmed = request.userMessage.trim();
    const isAbbas = request.tutorPersona === 'abbas';

    // 1. Simulation triggers for tests
    if (trimmed === 'SIMULATE_AI_ERROR') {
      throw new Error('Simulated upstream AI provider service failure');
    }

    if (trimmed === 'SIMULATE_INVALID_JSON') {
      return {
        tutorResponse: '',
        nextDifficulty: 'invalid_difficulty' as unknown,
      } as unknown as AiTutorConversationOutput;
    }

    // 2. Session start / greeting
    if (request.isSessionStart) {
      const lang = request.targetLanguage.toLowerCase();
      let responseText = '';

      if (lang === 'spanish' || lang === 'es') {
        responseText = isAbbas
          ? "¡Hola! Soy Abbas, tu compañero de aprendizaje. ¿Listo para practicar español hoy? Cuéntame, ¿cómo estuvo tu mañana?"
          : "¡Hola! Soy Dunya y estoy muy feliz de practicar español contigo hoy. ¿Cómo va tu día?";
      } else if (lang === 'french' || lang === 'fr') {
        responseText = isAbbas
          ? "Salut! Je suis Abbas. Prêt à pratiquer le français aujourd'hui? Raconte-moi, comment s'est passée ta matinée?"
          : "Bonjour! Je suis Dunya. Très heureuse de pratiquer le français avec toi. Comment se passe ta journée?";
      } else if (lang === 'german' || lang === 'de') {
        responseText = isAbbas
          ? "Hallo! Ich bin Abbas. Bereit für Deutsch heute? Wie war dein Morgen?"
          : "Guten Tag! Ich bin Dunya. Ich freue mich darauf, Deutsch mit dir zu üben. Wie geht es dir?";
      } else if (lang === 'arabic' || lang === 'ar' || lang === 'jordanian' || lang === 'jo') {
        responseText = isAbbas
          ? "يا هلا والله! أنا عباس، جاهز نتدرب ونحكي عربي سوا اليوم؟ كيف كان يومك؟"
          : "أهلاً وسهلاً فيك! أنا دنيا ورح نتدرب على العربي بكل هدوء. كيف ماشي يومك؟";
      } else {
        responseText = isAbbas
          ? "Hey there! I'm Abbas, your practice partner. Ready to speak some English today? Tell me, how was your morning?"
          : "Hello! I'm Dunya, and I'm very excited to practice with you today. How is your day going so far?";
      }

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: responseText,
        correctedVersion: null,
        explanationArabic: isAbbas
          ? 'أهلاً وسهلاً يا بطل! جاهزين لنتدرب ونحكي مع بعض براحتنا 🔥'
          : 'أهلاً وسهلاً فيك! أنا دنيا ورح نتدرب سوا خطوة بخطوة بكل هدوء 🌟',
        detectedErrors: [],
        shouldCorrect: false,
        encouragement: 'يلا نبدأ!',
        nextDifficulty: 'same',
      });
    }

    // 3. Repeated mistake humor escalation
    const hadPastTenseMistakeInHistory = request.recentHistory.some(
      (turn) =>
        turn.text.toLowerCase().includes('go yesterday') ||
        (turn.correctedVersion && turn.correctedVersion.includes('went'))
    );

    if (
      hadPastTenseMistakeInHistory &&
      (trimmed.toLowerCase().includes('go yesterday') ||
        trimmed.toLowerCase().includes('goed'))
    ) {
      if (isAbbas) {
        return AiTutorConversationOutputSchema.parse({
          tutorResponse:
            "Haha, I see you're still determined with 'go'! Remember: 'I went yesterday.' Now tell me, what did you see there?",
          correctedVersion: 'I went yesterday.',
          explanationArabic:
            'يا رجل 😂 لسه بنحاول مع نفس الجملة! الماضي من go هو went، ما في هروب منها 😉',
          detectedErrors: ['Repeated past tense mistake: use "went"'],
          shouldCorrect: true,
          encouragement: 'قربنا نتقنها 100%',
          nextDifficulty: 'same',
        });
      } else {
        return AiTutorConversationOutputSchema.parse({
          tutorResponse:
            "We are almost there! Remember to use 'I went yesterday.' Let's try saying it together!",
          correctedVersion: 'I went yesterday.',
          explanationArabic:
            'ولا يهمك، التكرار هو سر التعلم! تذكر دائمًا (went) للماضي 🌟',
          detectedErrors: ['Past tense: use "went" instead of "go"'],
          shouldCorrect: true,
          encouragement: 'خطوة بخطوة عم نتقدم!',
          nextDifficulty: 'same',
        });
      }
    }

    // 4. Single mistake (Grammar error)
    if (
      trimmed.toLowerCase().includes('go yesterday') ||
      trimmed.toLowerCase().includes('goed')
    ) {
      if (isAbbas) {
        return AiTutorConversationOutputSchema.parse({
          tutorResponse:
            "Oh nice! You mean: 'I went yesterday.' Where did you go exactly?",
          correctedVersion: 'I went yesterday.',
          explanationArabic:
            'استنى استنى 😂 الفعل لازم يكون بالماضي (went) لأنك حكيت عن أمس 👍',
          detectedErrors: ['Past tense: use "went" instead of "go"'],
          shouldCorrect: true,
          encouragement: 'محاولة حلوة ومعنى واضح!',
          nextDifficulty: 'same',
        });
      } else {
        return AiTutorConversationOutputSchema.parse({
          tutorResponse:
            "Great effort! Just remember: 'I went yesterday.' Where did you go?",
          correctedVersion: 'I went yesterday.',
          explanationArabic:
            'محاولة ممتازة! بس تذكر إن الفعل بالماضي بصير (went) لما تحكي عن أمس 🌟',
          detectedErrors: ['Past tense: use "went" instead of "go"'],
          shouldCorrect: true,
          encouragement: 'رائع، استمر!',
          nextDifficulty: 'same',
        });
      }
    }

    // 5. Name introduction handling (e.g. "Hello, my name is Ali." / "My name is...")
    const nameMatch = trimmed.match(/(?:my name is|i am|i'm|me llamo|soy|je m'appelle|ich heiße|اسمي|أنا)\s+([A-Za-z\u0600-\u06FF]+)/i);
    if (nameMatch) {
      const studentName = nameMatch[1];
      const lang = request.targetLanguage.toLowerCase();
      let tutorText = '';
      let arabicNote = '';

      if (lang === 'spanish' || lang === 'es') {
        tutorText = isAbbas
          ? `¡Hola ${studentName}! ¡Qué gran gusto conocerte! Soy Abbas, tu profesor de idiomas. ¿De qué te gustaría hablar hoy?`
          : `¡Hola ${studentName}! Es un placer conocerte. Soy Dunya. ¿Qué te gustaría practicar hoy?`;
        arabicNote = `أهلاً وسهلاً يا ${studentName}! بداية ممتازة لتعريف نفسك باللغة الإسبانية 👍`;
      } else if (lang === 'french' || lang === 'fr') {
        tutorText = isAbbas
          ? `Salut ${studentName}! Ravi de te rencontrer! Je suis Abbas. De quoi aimerais-tu parler aujourd'hui?`
          : `Bonjour ${studentName}! Enchantée de faire ta connaissance. Je suis Dunya. Que souhaites-tu pratiquer aujourd'hui?`;
        arabicNote = `أهلاً وسهلاً يا ${studentName}! تعبير ممتاز لتعريف نفسك بالفرنسية 🌟`;
      } else if (lang === 'german' || lang === 'de') {
        tutorText = isAbbas
          ? `Hallo ${studentName}! Schön dich kennenzulernen! Ich bin Abbas. Worüber möchtest du heute sprechen?`
          : `Guten Tag ${studentName}! Es freut mich, dich kennenzulernen. Ich bin Dunya. Was möchtest du heute üben?`;
        arabicNote = `أهلاً بك يا ${studentName}! تقديم رائع لنفسك بالألمانية 👌`;
      } else if (lang === 'arabic' || lang === 'ar' || lang === 'jordanian' || lang === 'jo') {
        tutorText = isAbbas
          ? `يا هلا والله يا ${studentName}! نورت، أنا عباس ومتحمس نحكي ونتدرب سوا! شو حابب نمارس اليوم؟`
          : `أهلاً وسهلاً فيك يا ${studentName}! تشرفت بمعرفتك، أنا دنيا. عن شو بتحب نحكي اليوم؟`;
        arabicNote = `تشرفنا يا ${studentName}! بداية محادثة لطيفة وودودة 🌟`;
      } else {
        tutorText = isAbbas
          ? `Hello ${studentName}! Awesome to meet you! I'm Abbas, your language tutor. What would you like to practice speaking about today?`
          : `Hello ${studentName}! It is a real pleasure to meet you. I am Dunya, and I am excited to help you learn. What would you like to practice today?`;
        arabicNote = `أهلاً وسهلاً بك يا ${studentName}! تعريف ممتاز عن النفس وجملة صحيحة 100% 🌟`;
      }

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: tutorText,
        correctedVersion: null,
        explanationArabic: arabicNote,
        detectedErrors: [],
        shouldCorrect: false,
        encouragement: `أهلاً بك يا ${studentName}!`,
        nextDifficulty: 'same',
      });
    }

    // 6. Short greeting (Hello / Hi / How are you)
    if (
      trimmed.toLowerCase().includes('hello') ||
      trimmed.toLowerCase().includes('hi') ||
      trimmed.toLowerCase().includes('hey') ||
      trimmed.toLowerCase().includes('how are you')
    ) {
      const isHowAreYou = trimmed.toLowerCase().includes('how are you') || trimmed.toLowerCase().includes('how do you do');
      let reply = '';
      if (isHowAreYou) {
        reply = isAbbas
          ? "I'm doing fantastic and full of energy! How are you doing today?"
          : "I am doing very well, thank you! How are you feeling today?";
      } else {
        reply = isAbbas
          ? "Hey there! Awesome greeting! Tell me, what did you do today?"
          : "Hello there! Wonderful to talk with you. How is your day going?";
      }

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: reply,
        correctedVersion: null,
        explanationArabic: isAbbas
          ? 'تحية ممتازة وبداية حلوة! حاول تجاوب بجملة كاملة 👌'
          : 'تحية لطيفة ومتقنة! خلينا نكمل ونتدرب 🌟',
        detectedErrors: [],
        shouldCorrect: false,
        encouragement: 'أحسنت!',
        nextDifficulty: 'same',
      });
    }

    // 7. Default natural response
    return AiTutorConversationOutputSchema.parse({
      tutorResponse: isAbbas
        ? "That sounds really interesting! Tell me more about why you like that."
        : "That's lovely! You are expressing your thoughts very clearly. What else happened?",
      correctedVersion: null,
      explanationArabic: isAbbas
        ? 'كلامك مفهوم وممتاز! كمل واحكيلي تفاصيل أكتر 🔥'
        : 'ممتاز جدًا! طلاقتك عم تتحسن مع كل جملة 👏',
      detectedErrors: [],
      shouldCorrect: false,
      encouragement: 'استمر، أداء رائع!',
      nextDifficulty: 'same',
    });
  }
}
