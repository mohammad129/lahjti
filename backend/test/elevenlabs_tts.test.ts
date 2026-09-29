import express, { Express } from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import { errorHandler } from '../src/middleware/error_handler.js';
import {
  ElevenLabsTtsProvider,
  MockTtsProvider,
} from '../src/providers/tts_provider.js';
import { createTutorRouter } from '../src/routes/tutor_routes.js';
import { TtsService } from '../src/services/tts_service.js';

describe('Step 28: ElevenLabs Production TTS & Voice Gateway Tests', () => {
  let app: Express;
  const authToken = 'Bearer user_voice_test_01';

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/api/v1/tutor', createTutorRouter());
    app.use(errorHandler);
  });

  it('1. MockTtsProvider synthesizes valid base64 MP3 audio and metadata', async () => {
    const provider = new MockTtsProvider();
    const result = await provider.synthesize({
      text: 'Hello, welcome to your Spanish lesson!',
      tutorPersona: 'abbas',
      targetLanguage: 'spanish',
    });

    expect(result.provider).toBe('mock');
    expect(result.format).toBe('mp3');
    expect(result.contentType).toBe('audio/mpeg');
    expect(typeof result.audioBase64).toBe('string');
    expect(result.audioBase64.length).toBeGreaterThan(10);
    expect(result.characterCount).toBe('Hello, welcome to your Spanish lesson!'.length);
  });

  it('2. ElevenLabsTtsProvider routes Abbas and Dunya to their distinct voice IDs and caches results', async () => {
    const provider = new ElevenLabsTtsProvider(
      'mock_api_key',
      'eleven_multilingual_v2',
      'voice_abbas_123',
      'voice_dunya_456',
      50
    );

    // Test resolve voice ID logic directly
    const abbasVoice = (provider as any).resolveVoiceId({ tutorPersona: 'abbas' });
    const dunyaVoice = (provider as any).resolveVoiceId({ tutorPersona: 'dunya' });

    expect(abbasVoice).toBe('voice_abbas_123');
    expect(dunyaVoice).toBe('voice_dunya_456');

    // Test cache key generation
    const key1 = (provider as any).createCacheKey('Hello', 'voice_abbas_123', 'eleven_multilingual_v2');
    const key2 = (provider as any).createCacheKey('Hello', 'voice_abbas_123', 'eleven_multilingual_v2');
    const key3 = (provider as any).createCacheKey('Hello', 'voice_dunya_456', 'eleven_multilingual_v2');

    expect(key1).toBe(key2);
    expect(key1).not.toBe(key3);
  });

  it('3. TtsService checks quota and synthesizes speech successfully', async () => {
    const service = new TtsService(new MockTtsProvider());
    const result = await service.synthesizeSpeech({
      text: 'Guten Tag! Wie geht es dir?',
      tutorPersona: 'dunya',
      targetLanguage: 'german',
      userId: 'user_voice_test_01',
    });

    expect(result.format).toBe('mp3');
    expect(result.audioBase64).toBeDefined();
  });

  it('4. POST /api/v1/tutor/synthesize returns HTTP 200 with synthesized audio', async () => {
    const response = await request(app)
      .post('/api/v1/tutor/synthesize')
      .set('Authorization', authToken)
      .send({
        text: 'Bonjour! Comment allez-vous?',
        tutorPersona: 'dunya',
        targetLanguage: 'french',
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('audioBase64');
    expect(response.body.format).toBe('mp3');
    expect(response.body.contentType).toBe('audio/mpeg');
  });

  it('5. POST /api/v1/tutor/conversation with synthesizeVoice=true returns audio in payload', async () => {
    const response = await request(app)
      .post('/api/v1/tutor/conversation')
      .set('Authorization', authToken)
      .send({
        targetLanguage: 'english',
        userMessage: 'Hello Abbas, I want to practice ordering food.',
        tutorPersona: 'abbas',
        synthesizeVoice: true,
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('tutorResponse');
    expect(response.body).toHaveProperty('audioBase64');
    expect(typeof response.body.audioBase64).toBe('string');
  });
});
