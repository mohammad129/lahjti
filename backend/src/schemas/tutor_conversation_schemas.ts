import { z } from 'zod';

export const SupportedTargetLanguages = [
  'english',
  'arabic',
  'jordanian',
  'spanish',
  'french',
  'german',
  'italian',
  'turkish',
  'japanese',
  'chinese',
  'korean',
  'en',
  'ar',
  'jo',
  'es',
  'fr',
  'de',
  'it',
  'tr',
  'ja',
  'zh',
  'ko',
] as const;

export const TutorPersonaEnum = z.enum(['abbas', 'dunya']);
export const AgeGroupEnum = z.enum(['child', 'teen', 'adult', 'senior']);
export const LearningGoalEnum = z.enum([
  'conversation',
  'travel',
  'work',
  'study',
  'general',
]);
export const CefrDifficultyEnum = z.enum(['a1', 'a2', 'b1', 'b2', 'c1', 'c2']);

export const ConversationTurnSchema = z.object({
  role: z.enum(['user', 'tutor']),
  text: z.string().min(1).max(500),
  explanationArabic: z.string().nullable().optional(),
  correctedVersion: z.string().nullable().optional(),
});

export const TutorConversationRequestSchema = z.object({
  targetLanguage: z.enum(SupportedTargetLanguages),
  nativeLanguage: z.string().min(2).max(30).default('arabic'),
  ageGroup: AgeGroupEnum.default('adult'),
  learningGoal: LearningGoalEnum.default('conversation'),
  difficulty: CefrDifficultyEnum.default('a1'),
  tutorPersona: TutorPersonaEnum.default('abbas'),
  userMessage: z.string().min(1).max(1000),
  recentHistory: z.array(ConversationTurnSchema).max(6).default([]),
  isSessionStart: z.boolean().default(false),
  // Step 14 Pedagogical Context (bounded & validated)
  currentLessonTitle: z.string().max(200).optional(),
  currentTopic: z.string().max(200).optional(),
  targetSkill: z.string().max(50).optional(),
  targetVocabulary: z.array(z.string().max(50)).max(10).default([]),
  recentWeaknesses: z.array(z.string().max(200)).max(5).default([]),
  recentStrengths: z.array(z.string().max(200)).max(5).default([]),
  // Step 25.5 Voice Cost Protection
  voiceDurationSeconds: z.number().min(0).max(300).default(0),
  // Step 28 ElevenLabs Voice Synthesis Option
  synthesizeVoice: z.boolean().default(false),
});

export const AiTutorConversationOutputSchema = z.object({
  tutorResponse: z.string().min(1).max(2000),
  correctedVersion: z.string().max(1000).nullable().default(null),
  explanationArabic: z.string().max(1000).nullable().default(null),
  detectedErrors: z.array(z.string().max(300)).max(10).default([]),
  shouldCorrect: z.boolean().default(false),
  encouragement: z.string().max(300).nullable().default(null),
  nextDifficulty: z.enum(['easier', 'same', 'harder']).default('same'),
  // Step 28 TTS Audio Payload
  audioBase64: z.string().nullable().optional(),
  voiceProvider: z.string().nullable().optional(),
  conversationLanguage: z.string().min(2).max(30).optional(),
});

export const TtsSynthesizeRequestSchema = z.object({
  text: z.string().min(1).max(1000),
  tutorPersona: TutorPersonaEnum.default('abbas'),
  targetLanguage: z.enum(SupportedTargetLanguages).default('english'),
  voiceId: z.string().max(100).optional(),
});

export const TtsSynthesizeResponseSchema = z.object({
  audioBase64: z.string(),
  contentType: z.string(),
  format: z.literal('mp3'),
  cached: z.boolean(),
  characterCount: z.number(),
  provider: z.string(),
});

export type ConversationTurn = z.infer<typeof ConversationTurnSchema>;
export type TutorConversationRequest = z.infer<
  typeof TutorConversationRequestSchema
>;
export type AiTutorConversationOutput = z.infer<
  typeof AiTutorConversationOutputSchema
>;
export type TtsSynthesizeRequest = z.infer<typeof TtsSynthesizeRequestSchema>;
export type TtsSynthesizeResponse = z.infer<typeof TtsSynthesizeResponseSchema>;
