import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { getDatabase } from '../src/db/index.js';

describe('School Student AI Tutor - 4 Sessions & 1 Hour Daily Cap Suite', () => {
  const studentUserId = 'user_student_english_test';
  const authHeader = { Authorization: `Bearer ${studentUserId}` };

  beforeEach(async () => {
    const db = getDatabase();
    // Register as school student
    await db.upsertSchoolMembership({
      userId: studentUserId,
      schoolId: 'school_alpha',
      role: 'student',
      status: 'active',
    });
    await db.upsertProfile(studentUserId, {
      targetLanguage: 'english',
      ageGroup: 'teen',
      nativeLanguage: 'arabic',
      accountContext: 'school',
      role: 'student',
      estimatedCefrLevel: 'a2',
    });
  });

  it('1. GET /api/v1/tutor/student-session/status returns 4 sessions and 3600s total', async () => {
    const app = createApp();
    const res = await request(app)
      .get('/api/v1/tutor/student-session/status')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.isSchoolStudent).toBe(true);
    expect(res.body.maxDailySessions).toBe(4);
    expect(res.body.maxDailySeconds).toBe(3600);
    expect(res.body.remainingSessions).toBe(4);
    expect(res.body.completedSessionsCount).toBe(0);
    expect(res.body.currentSessionNumber).toBe(1);
    expect(res.body.canStartOrContinueSession).toBe(true);
  });

  it('2. POST /api/v1/tutor/student-session/start initializes session 1 of 4', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/student-session/start')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.session).toBeDefined();
    expect(res.body.session.sessionNumber).toBe(1);
    expect(res.body.session.status).toBe('active');
    expect(res.body.status.currentSessionNumber).toBe(1);
  });

  it('3. POST /api/v1/tutor/conversation attaches studentSession and accumulates duration', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        targetLanguage: 'english',
        nativeLanguage: 'arabic',
        ageGroup: 'teen',
        learningGoal: 'conversation',
        difficulty: 'a2',
        tutorPersona: 'abbas',
        userMessage: 'Hello Abbas! We learned about science in school today.',
        recentHistory: [],
        isSessionStart: false,
        voiceDurationSeconds: 20,
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tutorResponse');
    expect(res.body).toHaveProperty('studentSession');
    expect(res.body.studentSession.isSchoolStudent).toBe(true);
    expect(res.body.studentSession.currentSessionNumber).toBe(1);
    expect(res.body.studentSession.totalSecondsUsedToday).toBeGreaterThanOrEqual(20);
    expect(res.body.studentSession.remainingSecondsToday).toBeLessThan(3600);
  });

  it('4. POST /api/v1/tutor/student-session/end completes session 1 and advances to session 2', async () => {
    const app = createApp();
    const endRes = await request(app)
      .post('/api/v1/tutor/student-session/end')
      .set(authHeader);

    expect(endRes.status).toBe(200);
    expect(endRes.body.status.completedSessionsCount).toBe(1);
    expect(endRes.body.status.remainingSessions).toBe(3);
    expect(endRes.body.status.currentSessionNumber).toBe(2);

    // Start session 2
    const start2Res = await request(app)
      .post('/api/v1/tutor/student-session/start')
      .set(authHeader);

    expect(start2Res.status).toBe(200);
    expect(start2Res.body.session.sessionNumber).toBe(2);
  });

  it('5. Capping: Completing all 4 sessions blocks a 5th session with friendly Arabic rate limit message', async () => {
    const app = createApp();
    const db = getDatabase();
    const today = new Date().toISOString().split('T')[0];

    // Seed 4 completed sessions
    for (let i = 1; i <= 4; i++) {
      await db.saveStudentTutorSession({
        id: `sess_${studentUserId}_${today}_${i}`,
        studentId: studentUserId,
        sessionDate: today,
        sessionNumber: i,
        durationSeconds: 300,
        turnsCount: 10,
        status: 'completed',
        startedAt: new Date(),
        endedAt: new Date(),
      });
    }

    const statusRes = await request(app)
      .get('/api/v1/tutor/student-session/status')
      .set(authHeader);

    expect(statusRes.body.completedSessionsCount).toBe(4);
    expect(statusRes.body.remainingSessions).toBe(0);
    expect(statusRes.body.canStartOrContinueSession).toBe(false);
    expect(statusRes.body.limitReason).toContain('أنهيت جلساتك الـ 4 لهذا اليوم');

    // Attempting a 5th conversation should be rejected with 429 RateLimitError
    const convRes = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        targetLanguage: 'english',
        nativeLanguage: 'arabic',
        ageGroup: 'teen',
        learningGoal: 'conversation',
        difficulty: 'a2',
        tutorPersona: 'abbas',
        userMessage: 'Can I start session 5 please?',
        recentHistory: [],
        isSessionStart: false,
      });

    expect(convRes.status).toBe(429);
    expect(convRes.body.error.message).toContain('جلساتك الـ 4');
  });

  it('6. Capping: Exceeding 3600 seconds cumulative limit blocks conversation with 429', async () => {
    const app = createApp();
    const db = getDatabase();
    const cappedUserId = 'user_student_time_capped';
    const cappedAuthHeader = { Authorization: `Bearer ${cappedUserId}` };
    const today = new Date().toISOString().split('T')[0];

    await db.upsertSchoolMembership({
      userId: cappedUserId,
      schoolId: 'school_alpha',
      role: 'student',
      status: 'active',
    });

    // Seed a session reaching full 3600 seconds
    await db.saveStudentTutorSession({
      id: `sess_${cappedUserId}_${today}_1`,
      studentId: cappedUserId,
      sessionDate: today,
      sessionNumber: 1,
      durationSeconds: 3600,
      turnsCount: 40,
      status: 'completed',
      startedAt: new Date(),
      endedAt: new Date(),
    });

    const statusRes = await request(app)
      .get('/api/v1/tutor/student-session/status')
      .set(cappedAuthHeader);

    expect(statusRes.body.totalSecondsUsedToday).toBe(3600);
    expect(statusRes.body.remainingSecondsToday).toBe(0);
    expect(statusRes.body.canStartOrContinueSession).toBe(false);
    expect(statusRes.body.limitReason).toContain('ساعة كاملة');

    const convRes = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(cappedAuthHeader)
      .send({
        targetLanguage: 'english',
        nativeLanguage: 'arabic',
        ageGroup: 'teen',
        learningGoal: 'conversation',
        difficulty: 'a2',
        tutorPersona: 'abbas',
        userMessage: 'Testing over time limit',
        recentHistory: [],
        isSessionStart: false,
      });

    expect(convRes.status).toBe(429);
    expect(convRes.body.error.message).toContain('ساعة كاملة');
  });
});
