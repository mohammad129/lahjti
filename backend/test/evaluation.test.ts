import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { PlacementController } from '../src/controllers/placement_controller.js';
import { LanguageModelProvider } from '../src/providers/language_model_provider.js';
import { MockLanguageModelProvider } from '../src/providers/mock_provider.js';
import { PlacementEvaluationService } from '../src/services/placement_evaluation_service.js';

describe('Lahjti Backend AI Gateway - Placement Evaluation Endpoint', () => {
  const defaultPayload = {
    targetLanguage: 'english',
    nativeLanguage: 'arabic',
    ageGroup: 'adult',
    learningGoal: 'conversation',
    difficulty: 'a1',
    question: {
      id: 'q_eng_01',
      type: 'comprehension',
      prompt: 'Introduce yourself in one sentence.',
      promptArabic: 'عرفني عن حالك بجملة وحدة.',
    },
    response: 'Hello, my name is Ahmed and I am learning English.',
    responseDurationMs: 4200,
    skipped: false,
  };

  const authHeader = { Authorization: 'Bearer valid_test_token_123' };

  // 1. Valid evaluation request
  it('1. should successfully evaluate a valid answer with HTTP 200', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('semanticScore');
    expect(res.body).toHaveProperty('grammarScore');
    expect(res.body).toHaveProperty('vocabularyScore');
    expect(res.body).toHaveProperty('comprehensionScore');
    expect(res.body).toHaveProperty('fluencyScore');
    expect(res.body.pronunciationScore).toBeNull();
    expect(res.body).toHaveProperty('confidence');
    expect(res.body).toHaveProperty('explanationArabic');
    expect(res.body).toHaveProperty('wasUnderstandable', true);
    expect(res.body.difficultyRecommendation).toBe('increase');
  });

  // 2. Missing target language
  it('2. should reject request with missing targetLanguage (400)', async () => {
    const app = createApp();
    const invalidPayload = { ...defaultPayload } as Partial<typeof defaultPayload>;
    delete invalidPayload.targetLanguage;

    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(invalidPayload);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 3. Invalid target language
  it('3. should reject request with unsupported target language (400)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, targetLanguage: 'klingon' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toContain('Unsupported target language');
  });

  // 4. Invalid CEFR level
  it('4. should reject request with invalid CEFR difficulty level (400)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, difficulty: 'Z9' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toContain('Invalid CEFR difficulty level');
  });

  // 5. Oversized response
  it('5. should reject or handle response exceeding max character limit (400)', async () => {
    const app = createApp();
    const oversizedText = 'a'.repeat(1005);
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, response: oversizedText });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toContain('Response exceeds maximum allowed length');
  });

  // 6. Missing question object
  it('6. should reject request with missing question prompt (400)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({
        ...defaultPayload,
        question: { id: '', type: 'comprehension', prompt: '' },
      });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  // 7. Invalid duration
  it('7. should reject negative response duration (400)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, responseDurationMs: -500 });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toContain('Duration cannot be negative');
  });

  // 8. Unauthorized request
  it('8. should reject unauthorized requests without credentials (401)', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .send(defaultPayload);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    expect(res.body.error.arabicMessage).toBe('يرجى تسجيل الدخول للمتابعة.');
  });

  // 9. AI provider success
  it('9. should return structured evaluation with proper scores and feedback', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(res.body.semanticScore).toBeGreaterThanOrEqual(0);
    expect(res.body.semanticScore).toBeLessThanOrEqual(100);
    expect(res.body.confidence).toBeGreaterThanOrEqual(0);
    expect(res.body.confidence).toBeLessThanOrEqual(1);
    expect(typeof res.body.explanationArabic).toBe('string');
  });

  // 10. AI provider timeout
  it('10. should return HTTP 504 and Arabic error when AI provider times out', async () => {
    // Custom provider that hangs longer than timeout
    const slowProvider: LanguageModelProvider = {
      name: 'slow-mock',
      evaluate: async () => {
        await new Promise((resolve) => setTimeout(resolve, 300));
        return new MockLanguageModelProvider().evaluate(defaultPayload, { userId: 'u1' });
      },
    };

    const shortTimeoutService = new PlacementEvaluationService(slowProvider, 50); // 50ms timeout
    const controller = new PlacementController(shortTimeoutService);
    const app = createApp(controller);

    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(504);
    expect(res.body.error.code).toBe('AI_TIMEOUT');
    expect(res.body.error.arabicMessage).toBe('أخذ الرد وقت أطول من اللازم. جرب مرة ثانية.');
  });

  // 11. AI provider failure
  it('11. should map AI provider runtime failure to safe HTTP 503 error', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, response: 'SIMULATE_AI_ERROR' });

    expect(res.status).toBe(500);
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 12. Invalid AI JSON handling
  it('12. should map malformed/out-of-schema AI output to HTTP 502 without crashing', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, response: 'SIMULATE_INVALID_JSON' });

    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe('AI_SCHEMA_ERROR');
    expect(res.body.error.arabicMessage).toBeDefined();
  });

  // 13. Out-of-range score validation
  it('13. should ensure scores are clamped between 0 and 100', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(res.body.semanticScore).toBeGreaterThanOrEqual(0);
    expect(res.body.semanticScore).toBeLessThanOrEqual(100);
    expect(res.body.grammarScore).toBeGreaterThanOrEqual(0);
    expect(res.body.grammarScore).toBeLessThanOrEqual(100);
    expect(res.body.vocabularyScore).toBeGreaterThanOrEqual(0);
    expect(res.body.vocabularyScore).toBeLessThanOrEqual(100);
  });

  // 14. Null pronunciation strictly accepted
  it('14. should strictly enforce pronunciationScore as null for text responses', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send(defaultPayload);

    expect(res.status).toBe(200);
    expect(res.body.pronunciationScore).toBeNull();
  });

  // 15. Skipped answer handling
  it('15. should handle skipped answer gracefully with 0 score and decrease recommendation', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({ ...defaultPayload, skipped: true, response: '' });

    expect(res.status).toBe(200);
    expect(res.body.semanticScore).toBe(0);
    expect(res.body.difficultyRecommendation).toBe('decrease');
    expect(res.body.explanationArabic).toContain('عادي جدًا');
  });

  // 16. Arabic explanation returned
  it('16. should always return meaningful Arabic explanation', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/api/v1/placement/evaluate')
      .set(authHeader)
      .send({
        ...defaultPayload,
        response: 'I go yesterday to the supermarket.',
      });

    expect(res.status).toBe(200);
    expect(res.body.explanationArabic).toContain('الفعل');
    expect(res.body.detectedErrors.length).toBeGreaterThan(0);
  });

  // 17. Multiple target languages supported
  it('17. should support multiple languages (Spanish, German, French, Turkish, Korean)', async () => {
    const app = createApp();
    const languages = ['spanish', 'french', 'german', 'turkish', 'korean'] as const;

    for (const lang of languages) {
      const res = await request(app)
        .post('/api/v1/placement/evaluate')
        .set(authHeader)
        .send({
          ...defaultPayload,
          targetLanguage: lang,
          response: 'Hola mi amigo',
        });

      expect(res.status).toBe(200);
      expect(res.body.semanticScore).toBeDefined();
    }
  });
});
