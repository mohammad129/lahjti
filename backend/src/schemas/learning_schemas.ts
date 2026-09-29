import { z } from 'zod';

export const updateProfileSchema = z.object({
  targetLanguage: z.string().min(1).max(64).default('english'),
  ageGroup: z.string().min(1).max(32).default('age19_25'),
  nativeLanguage: z.string().min(1).max(32).default('arabic'),
  learningGoal: z.string().min(1).max(64).default('generalFluency'),
  experienceLevel: z.string().min(1).max(64).default('beginnerWithBasics'),
  estimatedCefrLevel: z.string().min(1).max(16).default('a1'),
  currentLessonId: z.string().min(1).max(64).default('lesson_1_1'),
  selectedTutorId: z.string().min(1).max(32).default('abbas'),
  grammarScore: z.number().int().min(0).max(100).default(50),
  vocabularyScore: z.number().int().min(0).max(100).default(50),
  comprehensionScore: z.number().int().min(0).max(100).default(50),
  communicationScore: z.number().int().min(0).max(100).default(50),
  pronunciationScore: z.number().int().min(0).max(100).nullable().optional(),
  strengths: z.array(z.string()).default([]),
  weaknesses: z.array(z.string()).default([]),
  recommendedFocusAreas: z.array(z.string()).default([]),
});

export const updateProgressSchema = z.object({
  completedLessonIds: z.array(z.string()).default([]),
  inProgressLessonId: z.string().min(1).max(64).optional(),
  totalMinutesLearned: z.number().int().min(0).optional(),
});

export const updateVocabularyProgressSchema = z.object({
  vocabularyId: z.string().min(1).max(64),
  status: z.enum(['learning', 'reviewing', 'mastered']).default('learning'),
  intervalDays: z.number().int().min(1).default(1),
  easeFactor: z.number().min(1.0).max(5.0).default(2.5),
  repetitions: z.number().int().min(0).default(0),
  accuracyPercentage: z.number().int().min(0).max(100).default(0),
  lastReviewedDate: z.string().datetime({ offset: true }).optional().nullable(),
  nextReviewDate: z.string().datetime({ offset: true }).optional(),
});

export const saveExamResultSchema = z.object({
  id: z.string().optional(),
  examId: z.string().min(1).max(64),
  examType: z.string().min(1).max(32),
  titleArabic: z.string().min(1).max(255),
  overallScore: z.number().int().min(0).max(100),
  earnedPoints: z.number().int().min(0),
  totalPoints: z.number().int().min(1),
  isPassed: z.boolean(),
  projectedCefrLevel: z.string().min(1).max(16),
  skillScores: z.array(z.any()).default([]),
  strengths: z.array(z.string()).default([]),
  improvementAreas: z.array(z.string()).default([]),
  recommendations: z.array(z.any()).default([]),
  completedAt: z.string().datetime({ offset: true }).optional(),
});

export const recordActivitySchema = z.object({
  activityType: z.enum([
    'lessonCompletion',
    'vocabularyPractice',
    'vocabularyReview',
    'examCompletion',
    'tutorConversation',
    'milestoneBonus',
  ]),
  accuracy: z.number().int().min(0).max(100).optional(),
  count: z.number().int().min(1).max(100).optional(),
  referenceId: z.string().max(128).optional(),
  isDuplicateAttempt: z.boolean().optional().default(false),
});
