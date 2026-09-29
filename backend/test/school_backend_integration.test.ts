import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { InMemoryLearningDb, setDatabase } from '../src/db/index.js';

describe('Step 24: Real School Backend Integration & Security Tests', () => {
  let app: any;
  let testDb: InMemoryLearningDb;

  const studentA = 'user_student_alpha';
  const studentB = 'user_student_beta';
  const teacherA = 'user_teacher_alpha';
  const teacherB = 'user_teacher_beta';

  beforeEach(async () => {
    testDb = new InMemoryLearningDb();
    setDatabase(testDb);
    app = createApp();

    // Seed School A
    await testDb.createSchool({
      id: 'school_alpha_id',
      name: 'Alpha International School',
      schoolCode: 'ALPHA101',
    });

    // Seed School B
    await testDb.createSchool({
      id: 'school_beta_id',
      name: 'Beta Academy',
      schoolCode: 'BETA202',
    });

    // Seed Memberships
    await testDb.upsertSchoolMembership({
      schoolId: 'school_alpha_id',
      userId: teacherA,
      role: 'teacher',
      displayName: 'الأستاذ أحمد',
    });

    await testDb.upsertSchoolMembership({
      schoolId: 'school_alpha_id',
      userId: studentA,
      role: 'student',
      displayName: 'سارة خالد',
    });

    await testDb.upsertSchoolMembership({
      schoolId: 'school_beta_id',
      userId: teacherB,
      role: 'teacher',
      displayName: 'الأستاذ محمود',
    });

    await testDb.upsertSchoolMembership({
      schoolId: 'school_beta_id',
      userId: studentB,
      role: 'student',
      displayName: 'طارق علي',
    });

    // Seed Classrooms
    await testDb.createClassroom({
      id: 'class_alpha_grade7',
      schoolId: 'school_alpha_id',
      teacherId: teacherA,
      grade: 'Grade 7',
      section: 'A',
      name: 'اللغة الإنجليزية - الصف السابع',
    });

    await testDb.createClassroom({
      id: 'class_beta_grade8',
      schoolId: 'school_beta_id',
      teacherId: teacherB,
      grade: 'Grade 8',
      section: 'B',
      name: 'اللغة الإنجليزية - الصف الثامن',
    });

    // Enroll students in classrooms
    await testDb.addStudentToClassroom({
      classroomId: 'class_alpha_grade7',
      studentId: studentA,
      status: 'active',
    });

    await testDb.addStudentToClassroom({
      classroomId: 'class_beta_grade8',
      studentId: studentB,
      status: 'active',
    });
  });

  // 1. Student Home Authorization & Data Isolation
  describe('1. Student School Home Authorization', () => {
    it('rejects unauthenticated request to /api/v1/student/home with 401', async () => {
      const res = await request(app).get('/api/v1/student/home');
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('returns server-authoritative student home context for authenticated student', async () => {
      const res = await request(app)
        .get('/api/v1/student/home')
        .set('Authorization', `Bearer ${studentA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.student.displayName).toBe('سارة خالد');
      expect(res.body.data.student.schoolName).toBe('Alpha International School');
      expect(res.body.data.student.grade).toBe('Grade 7');
      expect(res.body.data.dailyTasks).toBeDefined();
      expect(res.body.data.dailyTasks.length).toBeGreaterThan(0);
      expect(res.body.data.vocabularyReview.dueCount).toBeGreaterThanOrEqual(0);
    });

    it('does not leak private passwords or teacher internal notes', async () => {
      const res = await request(app)
        .get('/api/v1/student/home')
        .set('Authorization', `Bearer ${studentA}`);

      expect(res.body.data.password).toBeUndefined();
      expect(res.body.data.teacherNotes).toBeUndefined();
      expect(res.body.data.systemPrompts).toBeUndefined();
    });
  });

  // 2. Deterministic Daily Task Persistence & Retrieval
  describe('2. Deterministic Daily Tasks', () => {
    it('generates consistent, deterministic daily tasks for same student and date', async () => {
      const res1 = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentA}`);

      const res2 = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentA}`);

      expect(res1.status).toBe(200);
      expect(res2.status).toBe(200);
      expect(res1.body.data.length).toBe(res2.body.data.length);
      expect(res1.body.data[0].id).toBe(res2.body.data[0].id);
    });
  });

  // 3. Task Ownership & Cross-Student Security
  describe('3. Task Ownership & Security', () => {
    it('prevents Student A from completing Student B task with 403 Forbidden', async () => {
      // Generate tasks for Student B
      const tasksBRes = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentB}`);

      const taskBId = tasksBRes.body.data[0].id;

      // Student A attempts to complete Student B's task
      const completeRes = await request(app)
        .post(`/api/v1/student/tasks/${taskBId}/complete`)
        .set('Authorization', `Bearer ${studentA}`)
        .send({});

      expect(completeRes.status).toBe(403);
      expect(completeRes.body.error.code).toBe('FORBIDDEN');
    });

    it('returns 404 for non-existent taskId', async () => {
      const completeRes = await request(app)
        .post('/api/v1/student/tasks/non_existent_task/complete')
        .set('Authorization', `Bearer ${studentA}`)
        .send({});

      expect(completeRes.status).toBe(404);
    });
  });

  // 4. Task Completion & Server-Calculated XP
  describe('4. Task Completion & Anti-Farming XP', () => {
    it('completes task and awards server-calculated XP', async () => {
      const tasksRes = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentA}`);

      const task = tasksRes.body.data[0];

      const res = await request(app)
        .post(`/api/v1/student/tasks/${task.id}/complete`)
        .set('Authorization', `Bearer ${studentA}`)
        .send({});

      expect(res.status).toBe(200);
      expect(res.body.data.success).toBe(true);
      expect(res.body.data.earnedXp).toBe(task.xpReward || 25);
      expect(res.body.data.task.status).toBe('completed');
    });

    it('prevents XP farming: repeated completion returns 0 earned XP', async () => {
      const tasksRes = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentA}`);

      const task = tasksRes.body.data[0];

      // First completion
      await request(app)
        .post(`/api/v1/student/tasks/${task.id}/complete`)
        .set('Authorization', `Bearer ${studentA}`)
        .send({});

      // Duplicate completion attempt
      const dupRes = await request(app)
        .post(`/api/v1/student/tasks/${task.id}/complete`)
        .set('Authorization', `Bearer ${studentA}`)
        .send({});

      expect(dupRes.status).toBe(200);
      expect(dupRes.body.data.earnedXp).toBe(0);
      expect(dupRes.body.data.message).toContain('already completed');
    });

    it('ignores client-sent arbitrary XP payloads', async () => {
      const tasksRes = await request(app)
        .get('/api/v1/student/tasks?date=2026-09-22')
        .set('Authorization', `Bearer ${studentA}`);

      const task = tasksRes.body.data[1];

      const res = await request(app)
        .post(`/api/v1/student/tasks/${task.id}/complete`)
        .set('Authorization', `Bearer ${studentA}`)
        .send({ xp: 999999 });

      expect(res.status).toBe(200);
      // XP must be server-calculated, NOT 999999
      expect(res.body.data.earnedXp).toBe(task.xpReward || 15);
    });
  });

  // 5. Game Result Persistence & Calculation
  describe('5. Game Result Persistence', () => {
    it('records valid game result with server-calculated XP', async () => {
      const res = await request(app)
        .post('/api/v1/student/games/result')
        .set('Authorization', `Bearer ${studentA}`)
        .send({
          gameId: 'word_match',
          score: 85,
          correctAnswers: 17,
          incorrectAnswers: 3,
          skill: 'vocabulary',
          vocabularyIds: ['vocab_1', 'vocab_2'],
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.earnedXp).toBeGreaterThan(0);
      expect(res.body.data.gameResult.studentId).toBe(studentA);
    });

    it('rejects invalid game result payload with 400 Validation Error', async () => {
      const res = await request(app)
        .post('/api/v1/student/games/result')
        .set('Authorization', `Bearer ${studentA}`)
        .send({
          gameId: '', // Invalid empty string
          score: 150, // Invalid score > 100
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  // 6. Teacher Dashboard Integration & Isolation
  describe('6. Teacher Dashboard & Privacy Boundaries', () => {
    it('allows Teacher A to access assigned classes in School A', async () => {
      const res = await request(app)
        .get('/api/v1/teacher/home')
        .set('Authorization', `Bearer ${teacherA}`);

      expect(res.status).toBe(200);
      expect(res.body.data.teacher.displayName).toBe('الأستاذ أحمد');
      expect(res.body.data.metrics.totalClasses).toBe(1);
      expect(res.body.data.classes[0].id).toBe('class_alpha_grade7');
    });

    it('prevents Student A from accessing Teacher Dashboard with 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/teacher/home')
        .set('Authorization', `Bearer ${studentA}`);

      expect(res.status).toBe(403);
    });

    it('prevents Teacher A from viewing classes of Teacher B in School B', async () => {
      const res = await request(app)
        .get('/api/v1/teacher/classes/class_beta_grade8')
        .set('Authorization', `Bearer ${teacherA}`);

      expect(res.status).toBe(403);
    });

    it('prevents Teacher A from viewing Student B who is in another school/class', async () => {
      const res = await request(app)
        .get(`/api/v1/teacher/students/${studentB}`)
        .set('Authorization', `Bearer ${teacherA}`);

      expect(res.status).toBe(403);
    });

    it('allows Teacher A to view educational progress of Student A in their class without leaking AI chats', async () => {
      const res = await request(app)
        .get(`/api/v1/teacher/students/${studentA}`)
        .set('Authorization', `Bearer ${teacherA}`);

      expect(res.status).toBe(200);
      expect(res.body.data.student.id).toBe(studentA);
      expect(res.body.data.student.cefrLevel).toBeDefined();
      expect(res.body.data.student.totalXp).toBeDefined();
      // Ensure strict absence of private AI transcripts or audio recordings
      expect(res.body.data.student.privateAiConversations).toBeUndefined();
      expect(res.body.data.student.voiceRecordings).toBeUndefined();
      expect(res.body.data.student.systemPrompts).toBeUndefined();
    });
  });
});
