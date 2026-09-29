import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { PlacementController } from '../src/controllers/placement_controller.js';
import { TutorController } from '../src/controllers/tutor_controller.js';
import { InMemoryLearningDb, setDatabase } from '../src/db/index.js';
import {
  buildSystemPrompt,
  buildTutorConversationSystemPrompt,
} from '../src/providers/language_model_provider.js';
import { MockLanguageModelProvider } from '../src/providers/mock_provider.js';
import { PlacementEvaluationService } from '../src/services/placement_evaluation_service.js';
import { TutorConversationService } from '../src/services/tutor_conversation_service.js';

describe('STEP 27 — Production Multilingual AI Gateway & Prompt Testing', () => {
  let db: InMemoryLearningDb;
  let app: ReturnType<typeof createApp>;

  beforeEach(() => {
    db = new InMemoryLearningDb();
    setDatabase(db);

    const placementService = new PlacementEvaluationService(new MockLanguageModelProvider());
    const placementController = new PlacementController(placementService);
    const tutorService = new TutorConversationService(new MockLanguageModelProvider());
    const tutorController = new TutorController(tutorService, db);

    app = createApp(placementController, tutorController);
  });

  describe('1. Multilingual Prompt Construction Unit Tests', () => {
    it('generates English target language prompt for English learners', () => {
      const prompt = buildTutorConversationSystemPrompt({
        targetLanguage: 'english',
        nativeLanguage: 'arabic',
        ageGroup: 'adult',
        learningGoal: 'conversation',
        difficulty: 'b1',
        tutorPersona: 'abbas',
        userMessage: 'I want to improve my speaking skills',
        recentHistory: [],
        isSessionStart: false,
        targetVocabulary: ['fluent', 'confident'],
        recentWeaknesses: ['past tense'],
        recentStrengths: ['vocabulary'],
        voiceDurationSeconds: 15,
      });

      expect(prompt).toContain('ENGLISH');
      expect(prompt).toContain('Target Practice Language: ENGLISH');
      expect(prompt).toContain('Target Vocabulary to weave in or elicit: fluent, confident');
      expect(prompt).toContain('Known Student Weaknesses (support gently): past tense');
    });

    it('generates Spanish target language prompt for Spanish learners', () => {
      const prompt = buildTutorConversationSystemPrompt({
        targetLanguage: 'spanish',
        nativeLanguage: 'arabic',
        ageGroup: 'teen',
        learningGoal: 'travel',
        difficulty: 'a2',
        tutorPersona: 'dunya',
        userMessage: 'Quiero aprender español',
        recentHistory: [],
        isSessionStart: false,
        targetVocabulary: ['viajar', 'hotel'],
        recentWeaknesses: [],
        recentStrengths: [],
        voiceDurationSeconds: 10,
      });

      expect(prompt).toContain('SPANISH');
      expect(prompt).toContain('Target Practice Language: SPANISH');
      expect(prompt).toContain('Target Vocabulary to weave in or elicit: viajar, hotel');
    });

    it('generates Arabic target language prompt for Arabic learners', () => {
      const prompt = buildTutorConversationSystemPrompt({
        targetLanguage: 'arabic',
        nativeLanguage: 'english',
        ageGroup: 'adult',
        learningGoal: 'conversation',
        difficulty: 'a1',
        tutorPersona: 'abbas',
        userMessage: 'Marhaban',
        recentHistory: [],
        isSessionStart: false,
        targetVocabulary: [],
        recentWeaknesses: [],
        recentStrengths: [],
        voiceDurationSeconds: 5,
      });

      expect(prompt).toContain('ARABIC');
      expect(prompt).toContain('Target Practice Language: ARABIC');
    });

    it('builds placement evaluation system prompt for French target language', () => {
      const prompt = buildSystemPrompt({
        targetLanguage: 'french',
        nativeLanguage: 'arabic',
        ageGroup: 'adult',
        learningGoal: 'study',
        difficulty: 'b2',
        question: {
          id: 'q_fr_1',
          type: 'grammar',
          prompt: 'Conjuguez le verbe être au présent',
        },
        response: 'Je suis étudiant',
        responseDurationMs: 4500,
        skipped: false,
      });

      expect(prompt).toContain('Target Language to evaluate: FRENCH');
      expect(prompt).toContain('STUDY');
    });
  });

  describe('2. Multilingual Gateway HTTP Endpoints', () => {
    it('handles Spanish tutor conversation session start with Spanish reply', async () => {
      const res = await request(app)
        .post('/api/v1/tutor/conversation')
        .set('Authorization', 'Bearer dev-token')
        .send({
          targetLanguage: 'spanish',
          nativeLanguage: 'arabic',
          tutorPersona: 'abbas',
          isSessionStart: true,
          userMessage: 'Start session',
        });

      expect(res.status).toBe(200);
      expect(res.body.tutorResponse).toContain('español');
    });

    it('handles French tutor conversation session start with French reply', async () => {
      const res = await request(app)
        .post('/api/v1/tutor/conversation')
        .set('Authorization', 'Bearer dev-token')
        .send({
          targetLanguage: 'french',
          nativeLanguage: 'arabic',
          tutorPersona: 'dunya',
          isSessionStart: true,
          userMessage: 'Start session',
        });

      expect(res.status).toBe(200);
      expect(res.body.tutorResponse).toContain('français');
    });

    it('handles Arabic tutor conversation session start with Arabic reply', async () => {
      const res = await request(app)
        .post('/api/v1/tutor/conversation')
        .set('Authorization', 'Bearer dev-token')
        .send({
          targetLanguage: 'arabic',
          nativeLanguage: 'english',
          tutorPersona: 'abbas',
          isSessionStart: true,
          userMessage: 'Start session',
        });

      expect(res.status).toBe(200);
      expect(res.body.tutorResponse).toContain('عربي');
    });

    it('evaluates German placement answer with 200 OK', async () => {
      const res = await request(app)
        .post('/api/v1/placement/evaluate')
        .set('Authorization', 'Bearer dev-token')
        .send({
          targetLanguage: 'german',
          nativeLanguage: 'arabic',
          ageGroup: 'adult',
          learningGoal: 'work',
          difficulty: 'a2',
          question: {
            id: 'q_de_1',
            type: 'translation',
            prompt: 'Translate: Ich lerne Deutsch',
          },
          response: 'Ich lerne Deutsch jeden Tag',
          responseDurationMs: 3200,
          skipped: false,
        });

      expect(res.status).toBe(200);
      expect(res.body.semanticScore).toBeGreaterThanOrEqual(0);
      expect(res.body.pronunciationScore).toBeNull();
    });
  });
});
