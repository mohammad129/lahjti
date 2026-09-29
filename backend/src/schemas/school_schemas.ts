import { z } from 'zod';

export const completeTaskSchema = z.object({
  progress: z.number().min(0).max(1).optional().default(1.0),
});

export const submitGameResultSchema = z.object({
  gameId: z.string().min(1, 'gameId is required'),
  taskId: z.string().optional(),
  score: z.number().int().min(0).max(100),
  correctAnswers: z.number().int().min(0),
  incorrectAnswers: z.number().int().min(0),
  skill: z.string().min(1, 'skill is required'),
  vocabularyIds: z.array(z.string()).optional().default([]),
});

export const createSchoolSchema = z.object({
  name: z.string().min(2, 'School name must be at least 2 characters'),
  schoolCode: z.string().min(3, 'School code must be at least 3 characters'),
});

export const joinSchoolSchema = z.object({
  schoolCode: z.string().min(1, 'schoolCode is required'),
  role: z.enum(['student', 'teacher']).default('student'),
  displayName: z.string().min(1).optional(),
  grade: z.string().optional(),
  section: z.string().optional(),
});

export const createClassroomSchema = z.object({
  grade: z.string().min(1, 'Grade is required'),
  section: z.string().min(1).default('A'),
  name: z.string().min(2, 'Classroom name is required'),
});

export const enrollStudentSchema = z.object({
  studentId: z.string().min(1, 'studentId is required'),
});
