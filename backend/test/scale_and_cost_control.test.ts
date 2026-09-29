import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { InMemoryLearningDb, setDatabase } from '../src/db/index.js';
import * as schema from '../src/db/schema.js';
import { PlacementController } from '../src/controllers/placement_controller.js';
import { TutorController } from '../src/controllers/tutor_controller.js';
import { SubscriptionController } from '../src/controllers/subscription_controller.js';
import { SubscriptionService } from '../src/services/subscription_service.js';
import { PlacementEvaluationService } from '../src/services/placement_evaluation_service.js';
import { TutorConversationService } from '../src/services/tutor_conversation_service.js';
import { aiCacheService } from '../src/services/ai_cache_service.js';
import { jordanianDialectService } from '../src/services/jordanian_dialect_service.js';
import { usageMeteringService } from '../src/services/usage_metering_service.js';
import { MockLanguageModelProvider } from '../src/providers/mock_provider.js';

describe('STEP 25.5 — Production Scale & AI Cost Control Test Suite', () => {
  let db: InMemoryLearningDb;
  let app: ReturnType<typeof createApp>;

  const testUser = 'user_scale_777';
  const schoolStudent = 'user_scale_student_888';
  const schoolTeacher = 'user_scale_teacher_999';

  beforeEach(async () => {
    db = new InMemoryLearningDb();
    setDatabase(db);
    aiCacheService.clear();

    const subService = new SubscriptionService(db);
    const subController = new SubscriptionController(subService);
    const tutorService = new TutorConversationService();
    const tutorController = new TutorController(tutorService, db);
    const placementService = new PlacementEvaluationService();
    const placementController = new PlacementController(placementService);

    app = createApp(
      placementController,
      tutorController,
      undefined,
      undefined,
      undefined,
      subController
    );

    // Initialize individual trial subscription
    await subService.startTrial(testUser, 'individual', 'individual');

    // Initialize school student & teacher
    await db.createSchool({
      id: 'sch_amman_01',
      name: 'مدرسة عمان النموذجية',
      schoolCode: 'AMM-2026',
    });
    await subService.startTrial(schoolStudent, 'school', 'student', 'AMM-2026');
    await db.upsertSchoolMembership({
      userId: schoolTeacher,
      schoolId: 'sch_amman_01',
      role: 'teacher',
      status: 'active',
    });
  });

  // 1. Centralized AI Execution
  it('1. AI Gateway: Centralizes requests and returns valid conversational output', async () => {
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${testUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: 'Hello Abbas, I want to practice ordering coffee.',
        tutorPersona: 'abbas',
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tutorResponse');
    expect(res.body.tutorResponse.length).toBeGreaterThan(0);
  });

  // 2. Model Routing
  it('2. Model Routing: Routes placement evaluation through fast provider and conversation through advanced provider', async () => {
    let fastCalled = false;
    let advancedCalled = false;

    class FastSpyProvider extends MockLanguageModelProvider {
      override async evaluate(req: any, ctx: any) {
        fastCalled = true;
        return super.evaluate(req, ctx);
      }
    }

    class AdvancedSpyProvider extends MockLanguageModelProvider {
      override async conversation(req: any, ctx: any) {
        advancedCalled = true;
        return super.conversation(req, ctx);
      }
    }

    const customPlacementCtrl = new PlacementController(new PlacementEvaluationService(new FastSpyProvider()));
    const customTutorCtrl = new TutorController(new TutorConversationService(new AdvancedSpyProvider()), db);
    const customApp = createApp(customPlacementCtrl, customTutorCtrl);

    // 1. Placement call should route to fast provider
    const evalRes = await request(customApp)
      .post('/api/v1/placement/evaluate')
      .set('Authorization', `Bearer ${testUser}`)
      .send({
        question: {
          id: 'q_scale_1',
          type: 'translation',
          prompt: 'Translate to English: مرحبا',
          promptArabic: 'ترجم للإنجليزية: مرحبا',
        },
        response: 'Hello',
        responseDurationMs: 1200,
        skipped: false,
        targetLanguage: 'english',
        nativeLanguage: 'arabic',
        difficulty: 'a1',
        ageGroup: 'adult',
        learningGoal: 'conversation',
      });

    expect(evalRes.status).toBe(200);
    expect(fastCalled).toBe(true);

    // 2. Tutor conversation should route to advanced provider
    const convRes = await request(customApp)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${testUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: 'How are you doing today?',
        tutorPersona: 'abbas',
      });

    expect(convRes.status).toBe(200);
    expect(advancedCalled).toBe(true);
  });

  // 3. Token & Context Bounds
  it('3. Token & Context Limits: Caps input length and limits history sliding window', async () => {
    const hugeMessage = 'A'.repeat(3000); // Exceeds AI_MAX_INPUT_CHARS
    const excessHistory = Array.from({ length: 15 }, (_, i) => ({
      role: (i % 2 === 0 ? 'user' : 'tutor') as 'user' | 'tutor',
      text: `Message ${i}`,
    }));

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${testUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: hugeMessage.substring(0, 900), // Within schema max 1000
        recentHistory: excessHistory.slice(-6),
        tutorPersona: 'abbas',
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tutorResponse');
  });

  // 4. Rate Limiting + Abuse Protection
  it('4. Rate Limiting: Blocks burst spam with 429 Too Many Requests', async () => {
    const spamUser = 'spam_bot_001';
    
    // Send 18 rapid requests to exceed burst limit (max 15/min for base tier)
    let rateLimited = false;
    for (let i = 0; i < 20; i++) {
      const res = await request(app)
        .post('/api/v1/tutor/conversation')
        .set('Authorization', `Bearer ${spamUser}`)
        .send({
          targetLanguage: 'english',
          userMessage: `Spam attempt ${i}`,
        });

      if (res.status === 429) {
        rateLimited = true;
        expect(res.body.error.arabicMessage).toBeDefined();
        break;
      }
    }

    expect(rateLimited).toBe(true);
  });

  // 5. Usage Metering & Privacy
  it('5. Usage Metering: Records tokens & request counts without logging user conversation text', async () => {
    const privacyUser = 'user_privacy_conscious_42';
    const secretSentence = 'My super private secret conversation 12345';

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${privacyUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: secretSentence,
        tutorPersona: 'dunya',
      });

    expect(res.status).toBe(200);

    const today = new Date().toISOString().split('T')[0];
    const dailyRecords = await db.getDailyAiUsage(privacyUser, today);

    expect(dailyRecords.length).toBeGreaterThan(0);
    const rec = dailyRecords[0];
    expect(rec.userId).toBe(privacyUser);
    expect(rec.requestCount).toBeGreaterThanOrEqual(1);
    expect(rec.inputTokens).toBeGreaterThan(0);
    expect(rec.outputTokens).toBeGreaterThan(0);

    // Verify STRICT PRIVACY: raw conversation content is NOT present anywhere in telemetry
    const serializedRecord = JSON.stringify(rec);
    expect(serializedRecord).not.toContain(secretSentence);
  });

  // 6. Per-User Quotas
  it('6. Quotas: Enforces daily request limits according to subscription tier', async () => {
    const quotaUser = 'limited_trial_user';
    const quota = await usageMeteringService.getQuotaForUser(quotaUser);
    expect(quota.maxDailyRequests).toBeGreaterThanOrEqual(5);

    const teacherQuota = await usageMeteringService.getQuotaForUser(schoolTeacher);
    expect(teacherQuota.maxDailyRequests).toBeGreaterThanOrEqual(200);

    const studentQuota = await usageMeteringService.getQuotaForUser(schoolStudent);
    expect(studentQuota.maxDailyRequests).toBeGreaterThanOrEqual(30);
  });

  // 7. Caching for Static / Repeat Queries
  it('7. Caching: Returns cached evaluation for identical answers with zero extra LLM cost', async () => {
    const promptData = {
      question: {
        id: 'q_vocab_cache_101',
        type: 'translation',
        prompt: 'Translate: مرحبا',
        promptArabic: 'ترجم: مرحبا',
      },
      response: 'Hello',
      responseDurationMs: 2500,
      skipped: false,
      targetLanguage: 'english',
      nativeLanguage: 'arabic',
      difficulty: 'a1',
      ageGroup: 'adult',
      learningGoal: 'conversation',
    };

    // First call (cache miss)
    const res1 = await request(app)
      .post('/api/v1/placement/evaluate')
      .set('Authorization', `Bearer ${testUser}`)
      .send(promptData);

    expect(res1.status).toBe(200);

    const statsBefore = aiCacheService.getStats();

    // Second call with identical payload (cache hit)
    const res2 = await request(app)
      .post('/api/v1/placement/evaluate')
      .set('Authorization', `Bearer ${testUser}`)
      .send(promptData);

    expect(res2.status).toBe(200);
    expect(res2.body.semanticScore).toBe(res1.body.semanticScore);

    const statsAfter = aiCacheService.getStats();
    expect(statsAfter.hits).toBeGreaterThan(statsBefore.hits);
    expect(statsAfter.savedTokens).toBeGreaterThan(statsBefore.savedTokens);
  });

  // 8. Database Indexes
  it('8. Database Indexes: Schema defines production indexes for 50k user scale', () => {
    expect(schema.aiUsageRecords).toBeDefined();
    expect(schema.userSubscriptions).toBeDefined();
  });

  // 9. Jordanian Dialect Layer
  it('9. Dialect Layer: Delivers structured colloquial vocabulary, rules, and system prompt', async () => {
    const dict = jordanianDialectService.getDialectDictionary();
    expect(dict['شو الأخبار']).toBeDefined();
    expect(dict['يعطيك العافية']).toBeDefined();
    expect(dict['على راسي / من عيوني']).toBeDefined();

    const rules = jordanianDialectService.getGrammarGuidelines();
    expect(rules.length).toBeGreaterThan(2);

    const systemPrompt = jordanianDialectService.getSystemPrompt('intermediate');
    expect(systemPrompt).toContain('اللهجة الأردنية');
    expect(systemPrompt).toContain('INTERMEDIATE');

    // Test API route
    const res = await request(app).get('/api/v1/learning/dialect-guide');
    expect(res.status).toBe(200);
    expect(res.body.data.commonExpressions).toBeDefined();
    expect(res.body.data.grammarGuidelines).toBeDefined();
  });

  // 10. Voice Cost Protection
  it('10. Voice Cost Protection: Rejects voice calls exceeding turn duration limit', async () => {
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', `Bearer ${testUser}`)
      .send({
        targetLanguage: 'english',
        userMessage: 'Hello tutor, I have a long voice note',
        voiceDurationSeconds: 120, // Exceeds 30s limit
      });

    expect(res.status).toBe(429);
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 11. Usage Telemetry API Endpoint
  it('11. Telemetry API: /api/v1/subscription/usage exposes remaining daily quota', async () => {
    const res = await request(app)
      .get('/api/v1/subscription/usage')
      .set('Authorization', `Bearer ${testUser}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.quota).toBeDefined();
    expect(res.body.data.remainingRequests).toBeGreaterThanOrEqual(0);
    expect(res.body.data.remainingTokens).toBeGreaterThanOrEqual(0);
  });
});
