import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { TutorController } from '../src/controllers/tutor_controller.js';
import { LanguageModelProvider } from '../src/providers/language_model_provider.js';
import { MockLanguageModelProvider } from '../src/providers/mock_provider.js';
import { TutorConversationService } from '../src/services/tutor_conversation_service.js';

describe('Lahjti Backend AI Gateway - Tutor Conversation Endpoint', () => {
  const defaultPayload = {
    targetLanguage: 'english',
    nativeLanguage: 'arabic',
    ageGroup: 'adult',
    learningGoal: 'conversation',
    difficulty: 'a1',
    tutorPersona: 'abbas',
    userMessage: 'Hello, I want to practice speaking with you.',
    recentHistory: [],
    isSessionStart: false,
  };

  const authHeader = { Authorization: 'Bearer user_mock_123' };

  // 1. Valid conversation request with Abbas persona
  it('1. should successfully generate conversation turn for Abbas persona (200)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tutorResponse');
    expect(res.body).toHaveProperty('explanationArabic');
    expect(res.body).toHaveProperty('detectedErrors');
    expect(res.body).toHaveProperty('shouldCorrect', false);
    expect(res.body).toHaveProperty('nextDifficulty', 'same');
    expect(typeof res.body.tutorResponse).toBe('string');
  });

  // 2. Valid conversation request with Dunya persona
  it('2. should successfully generate conversation turn for Dunya persona (200)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        tutorPersona: 'dunya',
        userMessage: 'I would like to tell you about my morning routine.',
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tutorResponse');
    expect(res.body).toHaveProperty('explanationArabic');
    expect(typeof res.body.tutorResponse).toBe('string');
  });

  // 3. Dynamic Session Start Greeting for Abbas
  it('3. should generate an opening greeting on session start for Abbas', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        tutorPersona: 'abbas',
        isSessionStart: true,
        userMessage: 'Start session',
      });

    expect(res.status).toBe(200);
    expect(res.body.tutorResponse).toContain('Abbas');
    expect(res.body.explanationArabic).toContain('أهلاً');
  });

  // 4. Dynamic Session Start Greeting for Dunya
  it('4. should generate an opening greeting on session start for Dunya', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        tutorPersona: 'dunya',
        isSessionStart: true,
        userMessage: 'Start session',
      });

    expect(res.status).toBe(200);
    expect(res.body.tutorResponse).toContain('Dunya');
    expect(res.body.explanationArabic).toContain('دنيا');
  });

  // 5. Meaningful error correction and Arabic explanation
  it('5. should detect language error, correct it and return Arabic feedback', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        userMessage: 'I go yesterday to the supermarket.',
      });

    expect(res.status).toBe(200);
    expect(res.body.shouldCorrect).toBe(true);
    expect(res.body.correctedVersion).toBe('I went yesterday.');
    expect(res.body.explanationArabic).toContain('الماضي');
    expect(res.body.detectedErrors.length).toBeGreaterThan(0);
  });

  // 6. Humor escalation on repeated mistake
  it('6. should escalate humor playfully when mistake is repeated in history', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        tutorPersona: 'abbas',
        userMessage: 'I go yesterday with my friends.',
        recentHistory: [
          {
            role: 'user',
            text: 'I go yesterday to the market.',
            correctedVersion: 'I went yesterday.',
          },
          {
            role: 'tutor',
            text: 'Oh nice! You mean: I went yesterday.',
            explanationArabic: 'الفعل لازم يكون بالماضي.',
          },
        ],
      });

    expect(res.status).toBe(200);
    expect(res.body.shouldCorrect).toBe(true);
    expect(res.body.explanationArabic).toContain('يا رجل');
  });

  // 7. Unauthenticated request rejection (401)
  it('7. should reject unauthenticated requests with HTTP 401', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .send(defaultPayload);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    expect(res.body.error.arabicMessage).toBe('يرجى تسجيل الدخول للمتابعة.');
  });

  // 8. Missing required userMessage (400)
  it('8. should reject requests missing userMessage with HTTP 400', async () => {
    const app = createApp();
    const invalidPayload = { ...defaultPayload } as Partial<
      typeof defaultPayload
    >;
    delete invalidPayload.userMessage;

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send(invalidPayload);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  // 9. Invalid target language (400)
  it('9. should reject unsupported target language with HTTP 400', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        targetLanguage: 'klingon',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  // 10. Upstream AI provider failure
  it('10. should map AI provider runtime failure to safe HTTP 500 error with Arabic explanation', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        userMessage: 'SIMULATE_AI_ERROR',
      });

    expect(res.status).toBe(500);
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 11. Malformed AI schema recovery (502)
  it('11. should map malformed AI output to HTTP 502 without crashing', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        userMessage: 'SIMULATE_INVALID_JSON',
      });

    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe('AI_SCHEMA_ERROR');
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 12. Timeout protection (504)
  it('12. should time out gracefully when AI provider hangs', async () => {
    const slowProvider: LanguageModelProvider = {
      name: 'slow-mock',
      evaluate: async () => {
        throw new Error('Not used in conversation test');
      },
      conversation: async () => {
        await new Promise((resolve) => setTimeout(resolve, 500));
        return {
          tutorResponse: 'Delayed reply',
          correctedVersion: null,
          explanationArabic: null,
          detectedErrors: [],
          shouldCorrect: false,
          encouragement: null,
          nextDifficulty: 'same',
        };
      },
    };

    const fastTimeoutService = new TutorConversationService(slowProvider, 50);
    const controller = new TutorController(fastTimeoutService);
    const app = createApp(undefined, controller);

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(504);
    expect(res.body.error.code).toBe('AI_TIMEOUT');
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 13. Strict user context from auth middleware
  it('13. should use verified userId from auth context, ignoring any body manipulation', async () => {
    let capturedUserId = '';
    const spyProvider: LanguageModelProvider = {
      name: 'spy-provider',
      evaluate: async () => {
        throw new Error('Not used');
      },
      conversation: async (_req, context) => {
        capturedUserId = context.userId;
        return {
          tutorResponse: 'Verified context response',
          correctedVersion: null,
          explanationArabic: null,
          detectedErrors: [],
          shouldCorrect: false,
          encouragement: null,
          nextDifficulty: 'same',
        };
      },
    };

    const spyService = new TutorConversationService(spyProvider);
    const spyController = new TutorController(spyService);
    const app = createApp(undefined, spyController);

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set({ Authorization: 'Bearer user_mock_123' })
      .send({
        ...defaultPayload,
        userId: 'spoofed_attacker_id', // Must be ignored!
      });

    expect(res.status).toBe(200);
    expect(capturedUserId).toBe('user_mock_123'); // From auth middleware, not spoofed body
  });

  // 14. Pedagogical context injection
  it('14. should accept bounded pedagogical context and pass it to provider', async () => {
    let capturedReq: any = null;
    const spyProvider: LanguageModelProvider = {
      name: 'spy-pedagogical',
      evaluate: async () => {
        throw new Error('Not used');
      },
      conversation: async (req, _context) => {
        capturedReq = req;
        return {
          tutorResponse: 'Pedagogical context response',
          correctedVersion: null,
          explanationArabic: null,
          detectedErrors: [],
          shouldCorrect: false,
          encouragement: null,
          nextDifficulty: 'same',
        };
      },
    };

    const spyService = new TutorConversationService(spyProvider);
    const spyController = new TutorController(spyService);
    const app = createApp(undefined, spyController);

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set(authHeader)
      .send({
        ...defaultPayload,
        currentLessonTitle: 'Ordering in Restaurant',
        currentTopic: 'Food & Dining',
        targetSkill: 'speaking',
        targetVocabulary: ['menu', 'water', 'bill'],
        recentWeaknesses: ['verb_conjugation'],
        recentStrengths: ['polite_expressions'],
      });

    expect(res.status).toBe(200);
    expect(capturedReq).not.toBeNull();
    expect(capturedReq.currentLessonTitle).toBe('Ordering in Restaurant');
    expect(capturedReq.currentTopic).toBe('Food & Dining');
    expect(capturedReq.targetSkill).toBe('speaking');
    expect(capturedReq.targetVocabulary).toContain('menu');
    expect(capturedReq.recentWeaknesses).toContain('verb_conjugation');
    expect(capturedReq.recentStrengths).toContain('polite_expressions');
  });

  // 15. Server-authoritative profile difficulty enrichment
  it('15. should authoritatively use stored database profile CEFR level over client spoofed level', async () => {
    let capturedDifficulty = '';
    const spyProvider: LanguageModelProvider = {
      name: 'spy-cefr',
      evaluate: async () => {
        throw new Error('Not used');
      },
      conversation: async (req) => {
        capturedDifficulty = req.difficulty;
        return {
          tutorResponse: 'CEFR check response',
          correctedVersion: null,
          explanationArabic: null,
          detectedErrors: [],
          shouldCorrect: false,
          encouragement: null,
          nextDifficulty: 'same',
        };
      },
    };

    const { InMemoryLearningDb } = await import('../src/db/index.js');
    const db = new InMemoryLearningDb();
    // Persist authoritative profile at B2
    await db.upsertProfile('user_auth_b2', {
      targetLanguage: 'english',
      estimatedCefrLevel: 'b2',
      weaknesses: ['phrasal_verbs'],
    });

    const spyService = new TutorConversationService(spyProvider);
    const spyController = new TutorController(spyService, db);
    const app = createApp(undefined, spyController);

    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set({ Authorization: 'Bearer user_auth_b2' })
      .send({
        ...defaultPayload,
        difficulty: 'a1', // Client attempts to force A1, server DB has B2
      });

    expect(res.status).toBe(200);
    expect(capturedDifficulty).toBe('b2'); // Enforced from server-authoritative DB
  });

  // 16. Cross-user context isolation
  it('16. should maintain strict cross-user profile isolation for conversations', async () => {
    let capturedWeaknesses: string[] = [];
    const spyProvider: LanguageModelProvider = {
      name: 'spy-isolation',
      evaluate: async () => {
        throw new Error('Not used');
      },
      conversation: async (req) => {
        capturedWeaknesses = req.recentWeaknesses;
        return {
          tutorResponse: 'Isolation response',
          correctedVersion: null,
          explanationArabic: null,
          detectedErrors: [],
          shouldCorrect: false,
          encouragement: null,
          nextDifficulty: 'same',
        };
      },
    };

    const { InMemoryLearningDb } = await import('../src/db/index.js');
    const db = new InMemoryLearningDb();
    // User A has specific weaknesses
    await db.upsertProfile('user_alice', {
      targetLanguage: 'english',
      estimatedCefrLevel: 'a2',
      weaknesses: ['alice_specific_weakness'],
    });
    // User B has distinct weaknesses
    await db.upsertProfile('user_bob', {
      targetLanguage: 'english',
      estimatedCefrLevel: 'b1',
      weaknesses: ['bob_specific_weakness'],
    });

    const spyService = new TutorConversationService(spyProvider);
    const spyController = new TutorController(spyService, db);
    const app = createApp(undefined, spyController);

    // Call as Bob
    const res = await request(app)
      .post('/api/v1/tutor/conversation')
      .set({ Authorization: 'Bearer user_bob' })
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(capturedWeaknesses).toContain('bob_specific_weakness');
    expect(capturedWeaknesses).not.toContain('alice_specific_weakness');
  });
});
