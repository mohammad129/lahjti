/**
 * Jordanian Dialect Knowledge & System Prompt Layer
 * Provides authentic colloquial Jordanian vocabulary, grammar nuances, cultural expressions,
 * and conversational dynamics for AI interactions without relying on vague prompts.
 */

export interface JordanianDialectContext {
  commonExpressions: Record<string, string>;
  grammarRules: string[];
  culturalNotes: string[];
  levelAdaptations: Record<string, string>;
}

export class JordanianDialectService {
  private static instance: JordanianDialectService;

  public static getInstance(): JordanianDialectService {
    if (!JordanianDialectService.instance) {
      JordanianDialectService.instance = new JordanianDialectService();
    }
    return JordanianDialectService.instance;
  }

  /**
   * Core dictionary of everyday Jordanian Arabic expressions and conversational markers
   */
  private readonly dialectData: JordanianDialectContext = {
    commonExpressions: {
      'شو الأخبار': 'What is up / How are things?',
      'يعطيك العافية': 'May God give you health/energy (universal polite greeting)',
      'يسعد مساك / صباحك': 'Good evening / morning',
      'تمام التمام': 'Everything is great / top-notch',
      'مش مشكلة / ولا يهمك': 'No problem / Don\'t worry at all',
      'على راسي / من عيوني': 'With pleasure / You have my utmost respect',
      'يسلمو ايديك': 'Thank you (bless your hands)',
      'هسا / هلأ': 'Now / Right now',
      'بدّي / بدّك': 'I want / You want',
      'عم + فعل': 'Continuous present tense marker (e.g., عم بحكي = I am speaking)',
      'رح + فعل': 'Future tense marker (e.g., رح نروح = We will go)',
      'كتير / واجد': 'A lot / Very',
      'شو رأيك': 'What do you think?',
      'يلا': 'Come on / Let\'s go',
      'بسيطة': 'It is simple / No worries',
      'ع راسي والله': 'Most welcome / Highly appreciated',
    },
    grammarRules: [
      'Use the negation particle "ما" + "ش" suffix or just "ما" (e.g., ما بعرف / ما بعرفش).',
      'Use "بدّي" for desire/need instead of MSA "أريد".',
      'Use "عم" prefix for continuous actions (e.g., عم بدرس = studying).',
      'Use "رح" prefix for future actions instead of MSA "سوف / سـ".',
      'Pronouns and demonstratives: "هاد / هادا" (this m.), "هاي / هادي" (this f.), "هذول" (these).',
      'Possessive particle "تبع" (e.g., الكتاب تبعي = my book).',
    ],
    culturalNotes: [
      'Keep the tone exceptionally hospitable, warm, encouraging, and authentically Jordanian (نشامى).',
      'Use natural feedback tokens like "عفكرة", "والله", "تمام", "يا سيدي", "صديقي / عزيزي".',
      'Encourage the student gently and correct errors naturally within conversation context.',
    ],
    levelAdaptations: {
      beginner: 'Use simple, short sentences (1-2 lines), everyday basic Jordanian words, and clear Arabic script with minimal complex slang.',
      intermediate: 'Use rich conversational Jordanian, common idioms, natural speed phrases, and gentle corrections.',
      advanced: 'Use full colloquial depth, local humor, cultural idioms, proverbs, and nuanced dialect differences (Ammani urban vs regional expressions).',
    },
  };

  /**
   * Generates a concise, token-optimized system instruction for AI prompts
   */
  public getSystemPrompt(level: 'beginner' | 'intermediate' | 'advanced' = 'intermediate'): string {
    const levelGuidance = this.dialectData.levelAdaptations[level] || this.dialectData.levelAdaptations.intermediate;
    
    return [
      'Role: You are a friendly, encouraging AI conversational tutor specializing in spoken Jordanian Arabic (اللهجة الأردنية).',
      `Target Level: ${level.toUpperCase()}. ${levelGuidance}`,
      'Dialect Rules:',
      '- Always converse in authentic Jordanian colloquial Arabic (use بدّي, عم, رح, هسا, كيفك, شو الأخبار, تمام).',
      '- Do NOT revert to stiff Modern Standard Arabic (الفصحى المعقدة) unless explaining formal grammar.',
      '- Keep responses concise (1 to 3 short sentences maximum) to keep dialogue engaging and fast.',
      '- If the user makes a dialect or grammar mistake, provide a quick, polite correction, then continue the dialogue with an engaging question.',
    ].join('\n');
  }

  /**
   * Returns dictionary of common terms for client-side caching & instant lookups
   */
  public getDialectDictionary(): Record<string, string> {
    return { ...this.dialectData.commonExpressions };
  }

  /**
   * Returns grammar tips for quick reference
   */
  public getGrammarGuidelines(): string[] {
    return [...this.dialectData.grammarRules];
  }
}

export const jordanianDialectService = JordanianDialectService.getInstance();
