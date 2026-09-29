import { z } from 'zod';

export const SupportedLanguages = [
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

export const AgeGroups = ['child', 'teen', 'adult', 'senior'] as const;

export const LearningGoals = [
  'conversation',
  'travel',
  'work',
  'study',
  'brainWorkout',
] as const;

export const CefrLevels = [
  'preA1',
  'a1',
  'a2',
  'b1',
  'b2',
  'c1',
  'c2',
] as const;

export const QuestionTypes = [
  'comprehension',
  'translation',
  'sentenceConstruction',
  'vocabulary',
  'grammar',
  'speaking',
  'listening',
  'freeResponse',
] as const;

export const QuestionSchema = z.object({
  id: z.string().min(1, 'Question ID is required').max(100),
  type: z.enum(QuestionTypes, {
    errorMap: () => ({ message: 'Invalid question type' }),
  }),
  prompt: z.string().min(1, 'Question prompt is required').max(500),
  promptArabic: z.string().max(500).optional(),
});

export const EvaluateRequestSchema = z.object({
  targetLanguage: z.enum(SupportedLanguages, {
    errorMap: () => ({ message: 'Unsupported target language' }),
  }),
  nativeLanguage: z.string().min(1, 'Native language is required').max(50),
  ageGroup: z.enum(AgeGroups, {
    errorMap: () => ({ message: 'Invalid age group' }),
  }),
  learningGoal: z.enum(LearningGoals, {
    errorMap: () => ({ message: 'Invalid learning goal' }),
  }),
  difficulty: z.enum(CefrLevels, {
    errorMap: () => ({ message: 'Invalid CEFR difficulty level' }),
  }),
  question: QuestionSchema,
  response: z.string().max(1000, 'Response exceeds maximum allowed length of 1000 characters'),
  responseDurationMs: z
    .number()
    .int('Duration must be an integer')
    .min(0, 'Duration cannot be negative')
    .max(600000, 'Duration cannot exceed 10 minutes'),
  skipped: z.boolean().default(false),
});

export type EvaluateRequest = z.infer<typeof EvaluateRequestSchema>;

export const DetectedErrorSchema = z.object({
  type: z.string().default('grammar'),
  original: z.string().default(''),
  correction: z.string().default(''),
  explanationArabic: z.string().default(''),
});

export const AiEvaluationOutputSchema = z.object({
  semanticScore: z
    .number()
    .int()
    .min(0, 'Score must be at least 0')
    .max(100, 'Score cannot exceed 100'),
  grammarScore: z
    .number()
    .int()
    .min(0, 'Score must be at least 0')
    .max(100, 'Score cannot exceed 100'),
  vocabularyScore: z
    .number()
    .int()
    .min(0, 'Score must be at least 0')
    .max(100, 'Score cannot exceed 100'),
  comprehensionScore: z
    .number()
    .int()
    .min(0, 'Score must be at least 0')
    .max(100, 'Score cannot exceed 100'),
  fluencyScore: z
    .number()
    .int()
    .min(0, 'Score must be at least 0')
    .max(100, 'Score cannot exceed 100'),
  pronunciationScore: z.null({
    invalid_type_error: 'Pronunciation score must be null for text placement',
  }),
  confidence: z
    .number()
    .min(0, 'Confidence must be at least 0.0')
    .max(1, 'Confidence cannot exceed 1.0'),
  detectedErrors: z.array(DetectedErrorSchema).default([]),
  correctedAnswer: z.string().nullable().optional(),
  explanationArabic: z.string().min(1, 'Arabic explanation is required'),
  wasUnderstandable: z.boolean(),
  difficultyRecommendation: z.enum(['increase', 'same', 'decrease']),
});

export type AiEvaluationOutput = z.infer<typeof AiEvaluationOutputSchema>;
