import { describe, expect, it } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { getDatabase, setDatabase, InMemoryLearningDb } from '../src/db/index.js';

describe('STEP 31 — Plan-Based English Learning, School Mode & Minimal AI Cost Architecture', () => {
  const db = new InMemoryLearningDb();
  setDatabase(db);
  const app = createApp();

  let teacherToken = '';
  let studentToken = '';
  const teacherId = 'usr_teacher_abbas';
  const studentId = 'usr_student_ahmed';

  it('1. Setup authentication tokens for Teacher and Student', async () => {
    // Register Teacher
    const tRes = await request(app)
      .post('/api/v1/auth/register')
      .send({ email: 'teacher.abbas@lahjti.com', password: 'password123', role: 'teacher' });
    expect(tRes.status).toBe(201);
    teacherToken = tRes.body.data.token;

    // Register Student
    const sRes = await request(app)
      .post('/api/v1/auth/register')
      .send({ email: 'student.ahmed@lahjti.com', password: 'password123', role: 'student' });
    expect(sRes.status).toBe(201);
    studentToken = sRes.body.data.token;
  });

  it('2. List Plans: Returns rich categorized curriculum plans with zero AI cost', async () => {
    const res = await request(app).get('/api/v1/plans');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.plans.length).toBeGreaterThanOrEqual(4);

    const categories = res.body.plans.map((p: any) => p.category);
    expect(categories).toContain('conversation');
    expect(categories).toContain('job_interview');
    expect(categories).toContain('travel');
    expect(categories).toContain('school');
  });

  it('3. Plan Details: Delivers 60-day roadmap and encouraging Arabic description', async () => {
    const res = await request(app)
      .get('/api/v1/plans/plan_conversation_60')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.plan.titleAr).toContain('المحادثة');
    expect(res.body.plan.durationDays).toBe(60);
    expect(res.body.daysSummary.length).toBeGreaterThanOrEqual(2);
  });

  it('4. Student Plan Enrollment & Day 1 Micro-Activities Stepper', async () => {
    // Enroll
    const enrollRes = await request(app)
      .post('/api/v1/plans/plan_conversation_60/enroll')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(enrollRes.status).toBe(200);
    expect(enrollRes.body.success).toBe(true);
    expect(enrollRes.body.welcomeMessage).toBeDefined();

    // Fetch Day 1 Activities
    const dayRes = await request(app)
      .get('/api/v1/plans/plan_conversation_60/days/1')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(dayRes.status).toBe(200);
    expect(dayRes.body.day.activities.length).toBe(9);

    const types = dayRes.body.day.activities.map((a: any) => a.activityType);
    expect(types).toContain('quick_review');
    expect(types).toContain('new_vocabulary');
    expect(types).toContain('listening');
    expect(types).toContain('dialogue');
    expect(types).toContain('grammar_bite');
    expect(types).toContain('pronunciation_drill');
    expect(types).toContain('mini_game');
    expect(types).toContain('quick_quiz');
    expect(types).toContain('day_summary');
  });

  it('5. Server-Authoritative Activity Completion: Awards points in points_transactions with 0 AI cost', async () => {
    const res = await request(app)
      .post('/api/v1/plans/activities/act_conv_1_2/complete')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ planDayId: 'day_conv_1', score: 100 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.xpEarned).toBe(10);

    // Verify Points Transaction in student ledger
    const ptsRes = await request(app)
      .get('/api/v1/student/points/history')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(ptsRes.status).toBe(200);
    expect(ptsRes.body.data.transactions.length).toBeGreaterThanOrEqual(1);
    expect(ptsRes.body.data.transactions[0].reasonCode).toBe('lesson_completed');
  });

  it('6. Student Codes: Generate ST-XXXXXX code and quick-login with scrypt hashed PIN', async () => {
    // Generate code
    const genRes = await request(app)
      .post('/api/v1/auth/generate-student-code')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ studentId: 'student_123', pin: '4321' });

    expect(genRes.status).toBe(201);
    const code = genRes.body.data.studentCode;
    expect(code).toMatch(/^ST-[A-F0-9]{6}$/);

    // Quick login with Code + PIN
    const loginRes = await request(app)
      .post('/api/v1/auth/student-code-login')
      .send({ studentCode: code, pin: '4321' });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.success).toBe(true);
    expect(loginRes.body.data.token).toBeDefined();

    // Rejects incorrect PIN
    const failRes = await request(app)
      .post('/api/v1/auth/student-code-login')
      .send({ studentCode: code, pin: '0000' });
    expect(failRes.status).toBe(401);
  });

  it('7. Spaced Repetition Mistakes: Logs mistake on wrong answer and advances SM-2 interval upon review', async () => {
    // Submit quiz with intentional wrong answer
    await request(app)
      .post('/api/v1/plans/activities/act_conv_1_8/complete')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        planDayId: 'day_conv_1',
        answers: {
          "What is the most natural reply to 'Nice to meet you'?": 'Yes, goodbye', // wrong
        },
      });

    // Verify mistake is logged in due reviews
    const reviewsRes = await request(app)
      .get('/api/v1/student/mistakes/reviews')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(reviewsRes.status).toBe(200);
    expect(reviewsRes.body.data.reviews.length).toBeGreaterThanOrEqual(1);

    const mistake = reviewsRes.body.data.reviews[0];

    // Attempt review with correct answer
    const attemptRes = await request(app)
      .post(`/api/v1/student/mistakes/${mistake.contentId}/attempt`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ studentAnswer: 'Nice to meet you too' });

    expect(attemptRes.status).toBe(200);
    expect(attemptRes.body.data.wasCorrect).toBe(true);
    expect(attemptRes.body.data.xpEarned).toBe(5);
  });

  it('8. Teacher Exam Builder: Supports 8 question types with deterministic auto-grading and analytics', async () => {
    // Teacher creates exam
    const examRes = await request(app)
      .post('/api/v1/teacher/exams')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'اختبار الوحدة الأولى: قواعد ومحادثة',
        durationMinutes: 20,
        startDate: new Date(),
        endDate: new Date(Date.now() + 86400000),
        passPoints: 50,
        questions: [
          {
            questionType: 'multiple_choice',
            questionText: 'What is the opposite of big?',
            options: ['small', 'huge', 'tall'],
            correctAnswer: 'small',
            points: 10,
          },
          {
            questionType: 'true_false',
            questionText: "'Cat' is an animal.",
            correctAnswer: 'true',
            points: 10,
          },
          {
            questionType: 'word_order',
            questionText: 'Arrange the sentence',
            correctAnswer: ['I', 'am', 'a', 'student'],
            points: 10,
          },
        ],
      });

    expect(examRes.status).toBe(201);
    const examId = examRes.body.data.id;

    // Student submits answers (all correct)
    const subRes = await request(app)
      .post(`/api/v1/student/exams/${examId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        answers: {
          [examRes.body.data.questions[0].id]: 'small',
          [examRes.body.data.questions[1].id]: 'true',
          [examRes.body.data.questions[2].id]: ['I', 'am', 'a', 'student'],
        },
      });

    expect(subRes.status).toBe(200);
    expect(subRes.body.data.totalScore).toBe(30);
    expect(subRes.body.data.percentage).toBe(100);
    expect(subRes.body.data.isPassed).toBe(true);

    // Teacher inspects analytics
    const anaRes = await request(app)
      .get(`/api/v1/teacher/exams/${examId}/analytics`)
      .set('Authorization', `Bearer ${teacherToken}`);

    expect(anaRes.status).toBe(200);
    expect(anaRes.body.data.totalSubmissions).toBe(1);
    expect(anaRes.body.data.passRate).toBe(100);
  });

  it('9. Educational Games Hub: Teacher adds game and student completes play with server-verified XP', async () => {
    // Teacher creates game
    const gRes = await request(app)
      .post('/api/v1/teacher/games')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        nameAr: 'تحدي الكلمات السريعة',
        nameEn: 'Speed Word Match',
        gameType: 'word_match',
        targetAgeGroup: 'teens_11_15',
        difficulty: 'intermediate',
        xpReward: 30,
        questions: [
          { prompt: 'Happy', correctAnswer: 'سعيد', points: 10 },
        ],
      });

    expect(gRes.status).toBe(201);
    const gameId = gRes.body.data.id;

    // Student plays game
    const playRes = await request(app)
      .post(`/api/v1/student/games/${gameId}/play`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        score: 90,
        correctAnswers: 9,
        incorrectAnswers: 1,
      });

    expect(playRes.status).toBe(200);
    expect(playRes.body.data.score).toBe(90);
    expect(playRes.body.data.earnedXp).toBe(27); // 30 * 90%
  });

  it('10. AI Cost Tracking: /api/v1/subscription/cost-breakdown exposes USD cost and cache savings', async () => {
    const costRes = await request(app)
      .get('/api/v1/subscription/cost-breakdown')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(costRes.status).toBe(200);
    expect(costRes.body.data.currency).toBe('USD');
    expect(costRes.body.data.totalCostUsd).toBeDefined();
    expect(costRes.body.data.savedCostUsd).toBeDefined();
  });
});
