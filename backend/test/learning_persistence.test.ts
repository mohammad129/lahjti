import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { InMemoryLearningDb, setDatabase } from '../src/db/index.js';

describe('Step 12: Real Backend Learning Persistence & Security Tests', () => {
  let app: any;
  let testDb: InMemoryLearningDb;

  beforeEach(() => {
    testDb = new InMemoryLearningDb();
    setDatabase(testDb);
    app = createApp();
  });

  const authUserA = 'user_student_alpha';
  const authUserB = 'user_student_beta';

  // --- 1. AUTHENTICATION TESTS ---
  describe('1. Authentication & Security Gate', () => {
    it('rejects unauthenticated request to /api/v1/learning/profile with 401', async () => {
      const res = await request(app).get('/api/v1/learning/profile');
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(res.body.error.message).toContain('authorization credentials');
    });

    it('rejects invalid bearer token with 401', async () => {
      const res = await request(app)
        .get('/api/v1/learning/profile')
        .set('Authorization', 'Bearer invalid_token');
      expect(res.status).toBe(401);
    });

    it('accepts valid authorization token and derives user identity', async () => {
      const res = await request(app)
        .get('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserA}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.userId).toBe(authUserA);
    });
  });

  // --- 2. USER OWNERSHIP & CROSS-USER ISOLATION TESTS ---
  describe('2. User Ownership & Data Isolation', () => {
    it('isolates User A and User B profiles strictly by token identity', async () => {
      // User A updates profile to Spanish
      await request(app)
        .put('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          targetLanguage: 'spanish',
          estimatedCefrLevel: 'b1',
        });

      // User B updates profile to French
      await request(app)
        .put('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserB}`)
        .send({
          targetLanguage: 'french',
          estimatedCefrLevel: 'a2',
        });

      // Fetch User A profile
      const resA = await request(app)
        .get('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserA}`);
      expect(resA.body.data.targetLanguage).toBe('spanish');
      expect(resA.body.data.estimatedCefrLevel).toBe('b1');

      // Fetch User B profile
      const resB = await request(app)
        .get('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserB}`);
      expect(resB.body.data.targetLanguage).toBe('french');
      expect(resB.body.data.estimatedCefrLevel).toBe('a2');
    });

    it('ignores client-submitted userId in request payload and preserves authenticated identity', async () => {
      // User A tries to spoof User B's profile
      const res = await request(app)
        .put('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          userId: authUserB, // Attempted spoof
          targetLanguage: 'german',
          estimatedCefrLevel: 'c1',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.userId).toBe(authUserA); // Must belong to User A

      // Verify User B profile was NOT touched
      const resB = await request(app)
        .get('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserB}`);
      expect(resB.body.data.targetLanguage).not.toBe('german');
    });
  });

  // --- 3. INPUT VALIDATION & SAFETY TESTS ---
  describe('3. Zod Input Validation', () => {
    it('rejects invalid grammar score outside 0-100 with 400', async () => {
      const res = await request(app)
        .put('/api/v1/learning/profile')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          grammarScore: 150, // Invalid score
        });
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('rejects unknown/impossible activity types in activity recording', async () => {
      const res = await request(app)
        .post('/api/v1/learning/activity')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          activityType: 'give_me_free_xp', // Invalid
        });
      expect(res.status).toBe(400);
    });

    it('rejects invalid exam result payload missing required fields', async () => {
      const res = await request(app)
        .post('/api/v1/learning/exams/results')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          examId: 'ex_1',
          overallScore: -10, // Invalid negative score
        });
      expect(res.status).toBe(400);
    });
  });

  // --- 4. PERSISTENT LEARNER PROGRESS, XP & STREAKS ---
  describe('4. Learner Progress, Anti-Farming XP & Streak Rules', () => {
    it('records valid lesson activity with accuracy bonus and advances total XP', async () => {
      const res = await request(app)
        .post('/api/v1/learning/activity')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          activityType: 'lessonCompletion',
          accuracy: 95, // High performance (+25% bonus -> 63 XP)
          referenceId: 'lesson_1_1',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.xpEarned).toBe(63);
      expect(res.body.data.newTotalXp).toBeGreaterThan(180);
      expect(res.body.data.streak.currentStreak).toBeGreaterThanOrEqual(1);
    });

    it('prevents XP farming on duplicate zero-effort attempts (clamped XP)', async () => {
      const res = await request(app)
        .post('/api/v1/learning/activity')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          activityType: 'lessonCompletion',
          isDuplicateAttempt: true,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.xpEarned).toBeLessThanOrEqual(10);
    });

    it('rejects negative/empty attempts by awarding 0 XP', async () => {
      const res = await request(app)
        .post('/api/v1/learning/activity')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          activityType: 'lessonCompletion',
          accuracy: 0,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.xpEarned).toBe(0);
    });
  });

  // --- 5. VOCABULARY SPACED REPETITION PERSISTENCE ---
  describe('5. Vocabulary Spaced Repetition Persistence', () => {
    it('persists and updates vocabulary progress record', async () => {
      const vocabRes = await request(app)
        .post('/api/v1/learning/vocabulary/progress')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          vocabularyId: 'v_en_hello_01',
          status: 'mastered',
          intervalDays: 4,
          easeFactor: 2.6,
          repetitions: 3,
          accuracyPercentage: 90,
        });

      expect(vocabRes.status).toBe(200);
      expect(vocabRes.body.data.status).toBe('mastered');

      // Fetch user vocabulary list
      const listRes = await request(app)
        .get('/api/v1/learning/vocabulary')
        .set('Authorization', `Bearer ${authUserA}`);

      expect(listRes.status).toBe(200);
      expect(listRes.body.data.length).toBeGreaterThanOrEqual(1);
      expect(listRes.body.data[0].vocabularyId).toBe('v_en_hello_01');
    });
  });

  // --- 6. EXAM RESULTS PERSISTENCE ---
  describe('6. Exam Results Persistence', () => {
    it('saves full exam report and retrieves assessment history', async () => {
      const examRes = await request(app)
        .post('/api/v1/learning/exams/results')
        .set('Authorization', `Bearer ${authUserA}`)
        .send({
          examId: 'exam_month_1_milestone',
          examType: 'monthlyMilestone',
          titleArabic: 'تقييم الشهر الأول',
          overallScore: 88,
          earnedPoints: 88,
          totalPoints: 100,
          isPassed: true,
          projectedCefrLevel: 'a2',
          skillScores: [
            { skill: 'speaking', score: 85 },
            { skill: 'vocabulary', score: 92 },
          ],
          strengths: ['المفردات'],
          improvementAreas: ['الطلاقة'],
          recommendations: [],
        });

      expect(examRes.status).toBe(201);
      expect(examRes.body.data.overallScore).toBe(88);

      // Verify exam appears in user's exam history
      const historyRes = await request(app)
        .get('/api/v1/learning/exams')
        .set('Authorization', `Bearer ${authUserA}`);

      expect(historyRes.status).toBe(200);
      expect(historyRes.body.data.length).toBe(1);
      expect(historyRes.body.data[0].examId).toBe('exam_month_1_milestone');
    });
  });

  // --- 7. DAILY & WEEKLY PROGRESS SUMMARIES ---
  describe('7. Daily & Weekly Summaries', () => {
    it('calculates daily progress summary for today', async () => {
      const res = await request(app)
        .get('/api/v1/learning/daily')
        .set('Authorization', `Bearer ${authUserA}`);

      expect(res.status).toBe(200);
      expect(res.body.data.xpEarned).toBeGreaterThanOrEqual(0);
      expect(res.body.data).toHaveProperty('isGoalMet');
    });

    it('calculates weekly 7-day progress summary', async () => {
      const res = await request(app)
        .get('/api/v1/learning/weekly')
        .set('Authorization', `Bearer ${authUserA}`);

      expect(res.status).toBe(200);
      expect(res.body.data.activeDaysCount).toBeGreaterThanOrEqual(0);
      expect(res.body.data).toHaveProperty('activeDaysMap');
      expect(res.body.data).toHaveProperty('dayXpMap');
    });
  });
});
