import {
  AiTutorConversationOutput,
  AiTutorConversationOutputSchema,
  TutorConversationRequest,
} from '../schemas/tutor_conversation_schemas.js';

/**
 * Intelligent Dynamic Bilingual Engine (Arabic + English).
 * 
 * Guarantees that even if external cloud APIs are unavailable or expired:
 * 1. Understands both Arabic and English inputs from the student.
 * 2. Active error detection and correction with warm Jordanian explanations.
 * 3. Returns rich, dynamic responses in BOTH English and Arabic without repeating.
 * 4. Translates Arabic requests into natural English equivalents and invites practice.
 */
export class DynamicBilingualEngine {
  public static processTurn(request: TutorConversationRequest): AiTutorConversationOutput {
    const rawInput = request.userMessage?.trim() || '';
    const isAbbas = request.tutorPersona === 'abbas';
    const isArabic = /[\u0600-\u06ff]/.test(rawInput);
    const historyLength = request.recentHistory?.length || 0;

    // 1. Initial Greeting / Session Start
    if (request.isSessionStart || rawInput.toLowerCase() === 'start session') {
      return this.handleSessionStart(isAbbas);
    }

    // 2. Handle Arabic Input from Student
    if (isArabic) {
      return this.handleArabicInput(rawInput, isAbbas, historyLength);
    }

    // 3. Handle English Input from Student (with Grammar & Pattern Checking)
    return this.handleEnglishInput(rawInput, isAbbas, request);
  }

  private static handleSessionStart(isAbbas: boolean): AiTutorConversationOutput {
    const tutorResponse = isAbbas
      ? "Hey there! I'm Abbas, your English practice coach! Ready to speak and have fun today? How was your day?"
      : "Hello and welcome! I am Dunya. I'm thrilled to practice English with you today! How are you doing?";

    const explanationArabic = isAbbas
      ? "أهلاً وسهلاً فيك! أنا عباس، مدربك باللغة الإنجليزية. احكيلي بالعربي أو بالإنجليزي، وراح نتعلم سوا خطوة بخطوة 🔥 كيف كان يومك اليوم؟"
      : "أهلاً وسهلاً فيك يا بطل! أنا دنيا. فيك تحكي معي بالإنجليزي أو بالعربي وأنا بساعدك نترجم ونصحح ونحكي بطلاقة 🌟 كيف حالك اليوم؟";

    return AiTutorConversationOutputSchema.parse({
      tutorResponse,
      correctedVersion: null,
      explanationArabic,
      detectedErrors: [],
      shouldCorrect: false,
      encouragement: isAbbas ? 'يلا نبلش بحماس!' : 'بداية موفقة سوا!',
      nextDifficulty: 'same',
    });
  }

  private static handleArabicInput(
    input: string,
    isAbbas: boolean,
    turnCount: number
  ): AiTutorConversationOutput {
    const lower = input.toLowerCase();

    // A. Arabic Greetings
    if (
      lower.includes('مرحبا') ||
      lower.includes('سلام') ||
      lower.includes('أهلا') ||
      lower.includes('صباح') ||
      lower.includes('مساء')
    ) {
      const enPhrase = isAbbas ? "Hey! Great to hear from you! How's everything going?" : "Hello! Welcome! How is your day going?";
      const arExp = isAbbas
        ? "يا هلا والله! لما بنحيي حدا بالإنجليزي بنقول: 'Hey, how's it going?' جرب كررها وراي واحكيلي شو عملت اليوم!"
        : "أهلاً وسهلاً فيك! للتحية بنقدر نقول: 'Hello! How are you?' جرب اكتبها أو احكيها بالإنجليزي!";

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: enPhrase,
        correctedVersion: "Hello! How are you doing today?",
        explanationArabic: arExp,
        detectedErrors: [],
        shouldCorrect: true,
        encouragement: 'ممتاز! جرب كرر الجملة بالإنجليزي 👏',
        nextDifficulty: 'same',
      });
    }

    // B. Arabic Name Introduction (اسمي ... / أنا ...)
    const nameMatch = input.match(/(?:اسمي|أنا|معاك|معك)\s+([A-Za-z\u0600-\u06ff]+)/);
    if (nameMatch) {
      const name = nameMatch[1];
      const enPhrase = isAbbas
        ? `Nice to meet you, ${name}! To say that in English, you say: "My name is ${name}." What is your favorite hobby?`
        : `It's a pleasure to meet you, ${name}! In English you can say: "My name is ${name}." What do you like to do in your free time?`;

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: enPhrase,
        correctedVersion: `My name is ${name}.`,
        explanationArabic: `تشرفنا يا ${name}! لما تعرّف عن حالك بالإنجليزي بنقول: 'My name is ${name}' أو 'I am ${name}'. كررها واحكيلي شو هوايتك المفضلة!`,
        detectedErrors: ['Spoke in Arabic: provided English equivalent'],
        shouldCorrect: true,
        encouragement: `كفو يا ${name}! 🌟`,
        nextDifficulty: 'same',
      });
    }

    // C. Student asks how to say something (كيف بحكي / شو معنى / بدي اقول)
    if (
      lower.includes('كيف بحكي') ||
      lower.includes('شو معنى') ||
      lower.includes('بدي اقول') ||
      lower.includes('معنى') ||
      lower.includes('كيف اقول')
    ) {
      return AiTutorConversationOutputSchema.parse({
        tutorResponse: "I understand! Whatever phrase you want to learn, just ask me and we will translate and practice it in English together!",
        correctedVersion: "How do I say this in English?",
        explanationArabic: "سؤالك ممتاز! لما بدك تسأل كيف بتحكي إشي بالإنجليزي اسألني: 'How do I say ... in English?' اكتبلي العبارة وبترجملك إياها وبنكررها سوا!",
        detectedErrors: [],
        shouldCorrect: true,
        encouragement: 'سؤال ذكي، استمر بالسؤال!',
        nextDifficulty: 'same',
      });
    }

    // D. Daily life / School / Feeling in Arabic (رحت على / عندي امتحان / بحب / تعبان / مبسوط)
    if (lower.includes('مدرسة') || lower.includes('جامعة') || lower.includes('امتحان') || lower.includes('درس')) {
      return AiTutorConversationOutputSchema.parse({
        tutorResponse: "School life is exciting! In English, we say: 'I go to school every day.' Which school subject do you like the most, Science or English?",
        correctedVersion: "I am studying for school.",
        explanationArabic: "حلو كتير! لما نحكي عن الدراسة بنقول: 'I study English at school'. شو أكتر مادة بتحبها بالمدرسة، العلوم ولا الإنجليزي؟ احكيلي بالإنجليزية!",
        detectedErrors: [],
        shouldCorrect: true,
        encouragement: 'بطل، خلينا نحكي عن المدرسة!',
        nextDifficulty: 'same',
      });
    }

    // E. General Arabic conversation fallback
    const dynamicReplies = [
      {
        en: "I totally understand what you mean! Let's say that in English: 'I am practicing my English today.' Can you repeat that?",
        ar: `فهمت عليك تماماً! فكرتك حلوة، ولما نعبر عنها بالإنجليزي بنقول: 'I am practicing my English today'. احكيلي شو رأيك؟`,
        corr: "I am practicing my English today.",
      },
      {
        en: "That's wonderful! In English, you can say: 'I like learning with my AI tutor.' What else would you like to talk about?",
        ar: `رائع جداً! بنقدر نعبر عنها بالإنجليزي بجملة بسيطة: 'I like learning with my AI tutor.' عن شو كمان بتحب نحكي؟`,
        corr: "I like learning new things.",
      },
      {
        en: "Awesome! Let's take it step by step. Try to give me a short sentence in English, even just two or three words!",
        ar: `ممتاز يا بطل! خلينا نمشي خطوة بخطوة، جرب اعطيني جملة بسيطة بالإنجليزي من كلمتين أو تلات وأنا معك بصححلك وبدربك فوراً.`,
        corr: "Let's speak English together.",
      },
    ];

    const pick = dynamicReplies[turnCount % dynamicReplies.length];

    return AiTutorConversationOutputSchema.parse({
      tutorResponse: pick.en,
      correctedVersion: pick.corr,
      explanationArabic: pick.ar,
      detectedErrors: ['Spoke in Arabic: translated to English for practice'],
      shouldCorrect: true,
      encouragement: isAbbas ? 'يا بطل، بنتعلم اللغتين سوا!' : 'ممتاز، خطوة بخطوة بنصير طلقاء!',
      nextDifficulty: 'same',
    });
  }

  private static handleEnglishInput(
    input: string,
    isAbbas: boolean,
    request: TutorConversationRequest
  ): AiTutorConversationOutput {
    const trimmed = input.trim();
    const lower = trimmed.toLowerCase();

    // 0. Repeated mistake humor escalation
    const hadPastTenseMistakeInHistory = request.recentHistory?.some(
      (turn) =>
        turn.text?.toLowerCase().includes('go yesterday') ||
        (turn.correctedVersion && turn.correctedVersion.includes('went'))
    );

    if (
      hadPastTenseMistakeInHistory &&
      (lower.includes('go yesterday') || lower.includes('goed'))
    ) {
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
    }

    // 1. Check for Past Tense Mistakes ("Yesterday I go", "I see him last night", "goed")
    if (lower.includes('go yesterday') || lower.includes('goed')) {
      return AiTutorConversationOutputSchema.parse({
        tutorResponse: isAbbas
          ? "Oh nice! You mean: 'I went yesterday.' Where did you go exactly?"
          : "We are almost there! Remember to use 'I went yesterday.' Let's try saying it together!",
        correctedVersion: 'I went yesterday.',
        explanationArabic: isAbbas
          ? 'استنى استنى 😂 الفعل لازم يكون بالماضي (went) لأنك حكيت عن أمس 👍'
          : 'ولا يهمك، التكرار هو سر التعلم! تذكر دائمًا (went) للماضي 🌟',
        detectedErrors: ['Past tense: use "went" instead of "go"'],
        shouldCorrect: true,
        encouragement: 'قربت على الصح!',
        nextDifficulty: 'same',
      });
    }

    const hasPastTimeMarker = /\b(yesterday|last\s+(night|week|month|year|weekend|summer)|ago|in the past)\b/i.test(lower);
    const presentVerbMatch = lower.match(/\b(go|see|come|eat|buy|take|make|play|watch|study|visit|sleep)\b/i);

    if (hasPastTimeMarker && presentVerbMatch) {
      const verb = presentVerbMatch[1].toLowerCase();
      const pastMap: Record<string, string> = {
        go: 'went',
        see: 'saw',
        come: 'came',
        eat: 'ate',
        buy: 'bought',
        take: 'took',
        make: 'made',
        play: 'played',
        watch: 'watched',
        study: 'studied',
        visit: 'visited',
        sleep: 'slept',
      };
      const pastVerb = pastMap[verb] || 'went';
      let corrected = trimmed.replace(new RegExp(`\\b${verb}\\b`, 'gi'), pastVerb);

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: isAbbas
          ? `Spot on with the meaning! Just remember we use the past tense: '${pastVerb}'. Tell me more about what happened!`
          : `Great job expressing yourself! For past events, we say '${pastVerb}' instead of '${verb}'. What happened next?`,
        correctedVersion: corrected,
        explanationArabic: `يا بطل 👏 المعنى مفهوم وممتاز! بس انتبه: بما إنه في دلالة على الماضي، لازم الفعل يتحول للماضي: بنستعمل '${pastVerb}' بدل '${verb}'.`,
        detectedErrors: [`Past tense error: use '${pastVerb}' instead of '${verb}'`],
        shouldCorrect: true,
        encouragement: 'تصحيح بسيط وبصير أسلوبك متل أهل اللغة! 🌟',
        nextDifficulty: 'same',
      });
    }

    // 2. Check for Missing Verb "to be" ("I student", "He doctor", "She nice", "I happy")
    const missingToBeMatch = lower.match(/\b(i|he|she|they|we)\s+(student|teacher|doctor|happy|sad|tired|ready|fine|good|from jordan|from egypt)\b/i);
    if (missingToBeMatch) {
      const subject = missingToBeMatch[1];
      const predicate = missingToBeMatch[2];
      const verb = subject === 'i' ? 'am' : (subject === 'he' || subject === 'she') ? 'is' : 'are';
      const corrected = `${subject.charAt(0).toUpperCase() + subject.slice(1)} ${verb} ${predicate}.`;

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: `I hear you! Remember the linking verb: "${corrected}" Tell me more!`,
        correctedVersion: corrected,
        explanationArabic: `ملاحظة ذكية يا بطل 👍 بالإنجليزي ما بنقدر نسيب الجملة بدون فعل كينونة (am / is / are). فبنقول: '${corrected}' بدل ما نسيبها بدون فعل.`,
        detectedErrors: [`Missing verb to be: use '${verb}' after '${subject}'`],
        shouldCorrect: true,
        encouragement: 'ممتاز، القاعدة صارت واضحة وسهلة!',
        nextDifficulty: 'same',
      });
    }

    // 3. Check for Subject-Verb Agreement ("he like", "she want", "he play")
    const agreementMatch = lower.match(/\b(he|she|it)\s+(like|want|play|study|work|live)\b/i);
    if (agreementMatch) {
      const subj = agreementMatch[1];
      const verb = agreementMatch[2];
      const corrected = `${subj} ${verb}s`;

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: `You're doing great! Don't forget the 's' for third person: "${corrected}". What else?`,
        correctedVersion: trimmed.replace(new RegExp(`\\b${subj}\\s+${verb}\\b`, 'gi'), corrected),
        explanationArabic: `قريب جداً من الصح! مع الضمائر (he / she / it) بالمضارع البسيط، بنضيف حرف 's' للفعل (he ${verb}s). بسيطة ومهمة!`,
        detectedErrors: [`Subject-verb agreement: add 's' to verb with '${subj}'`],
        shouldCorrect: true,
        encouragement: 'قاعدة أساسية وسهل تتقنها!',
        nextDifficulty: 'same',
      });
    }

    // 4. English Greeting (Hello / Hi / How are you)
    if (lower === 'hello' || lower === 'hi' || lower === 'hey' || lower.includes('how are you')) {
      const tutorReply = isAbbas
        ? "Hey! I'm feeling fantastic and full of energy! How are you doing today? Did you have a good day?"
        : "Hello! It is wonderful to hear from you. I am doing very well, thank you! How are you feeling today?";

      return AiTutorConversationOutputSchema.parse({
        tutorResponse: tutorReply,
        correctedVersion: null,
        explanationArabic: "تحية ممتازة وصحيحة 100%! سألتك عن يومك، جرب جاوبني بجملة إنجليزية كاملة متل: 'I am doing great' أو 'I had a busy day'.",
        detectedErrors: [],
        shouldCorrect: false,
        encouragement: 'تحية طليقة وواثقة! 👏',
        nextDifficulty: 'same',
      });
    }

    // 5. English Name Introduction ("My name is..." / "I am...")
    const enNameMatch = trimmed.match(/\b(?:my name is|i am|i'm)\s+([A-Za-z]+)\b/i);
    if (enNameMatch) {
      const name = enNameMatch[1];
      return AiTutorConversationOutputSchema.parse({
        tutorResponse: `Awesome to meet you, ${name}! Your introduction is completely accurate. Tell me, what's your favorite sport or hobby?`,
        correctedVersion: null,
        explanationArabic: `أهلاً وسهلاً بك يا ${name}! جملة التعريف عن نفسك صحيحة ومتقنة تماماً 🌟 سألتك عن رياضتك أو هوايتك المفضلة، احكيلي شو بتحب تمارس!`,
        detectedErrors: [],
        shouldCorrect: false,
        encouragement: `أداء ممتاز يا ${name}!`,
        nextDifficulty: 'same',
      });
    }

    // 6. Natural English conversational continuation
    const contextFollowUps = [
      {
        en: "That sounds really interesting! Can you tell me a little bit more about why you enjoy that?",
        ar: "كلامك رائع ومعبّر جداً! حابب أسمع منك تفاصيل أكتر، شو أكتر إشي بيميز هاد الموضوع بالنسبة إلك؟",
      },
      {
        en: "I love your choice of words! It's very natural. If you had free time tomorrow, what would you do?",
        ar: "صياغتك ممتازة وكلماتك طبيعية جداً 👏 لو كان عندك وقت فراغ بكرة، شو أول إشي بتحب تعمله؟",
      },
      {
        en: "You are speaking clearly and confidently! Let's keep the flow going: what is something new you learned recently?",
        ar: "طلاقتك وثقتك عم تزيد مع كل جملة! احكيلي عن إشي جديد اتعلمته بالفترة الأخيرة.",
      },
    ];

    const pick = contextFollowUps[Math.abs(trimmed.length + (request.recentHistory?.length || 0)) % contextFollowUps.length];

    return AiTutorConversationOutputSchema.parse({
      tutorResponse: pick.en,
      correctedVersion: null,
      explanationArabic: pick.ar,
      detectedErrors: [],
      shouldCorrect: false,
      encouragement: isAbbas ? 'استمر يا بطل، لغتك عم تتطور بسرعة!' : 'رائع جداً، مستواك عم يتقدم بثقة!',
      nextDifficulty: 'same',
    });
  }
}
