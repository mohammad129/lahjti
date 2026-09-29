import crypto from 'crypto';
import { config } from '../config/env.js';

export interface TtsSynthesisOptions {
  text: string;
  tutorPersona?: 'abbas' | 'dunya';
  targetLanguage?: string;
  voiceId?: string;
  userId?: string;
}

export interface TtsSynthesisResult {
  audioBase64: string;
  contentType: string;
  format: 'mp3';
  cached: boolean;
  characterCount: number;
  provider: 'elevenlabs' | 'mock';
}

export interface ITtsProvider {
  readonly name: string;
  synthesize(options: TtsSynthesisOptions): Promise<TtsSynthesisResult>;
}

export class MockTtsProvider implements ITtsProvider {
  readonly name = 'mock';

  // Minimal valid 1-frame MP3 base64 (silent/test frame)
  private static readonly DUMMY_MP3_BASE64 =
    '//uQZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWGluZwAAAA8AAAACAAACcQCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA//sQZAAPAAAaQAAAAgAAA0gAAABExBTUUzLjk4LjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  async synthesize(options: TtsSynthesisOptions): Promise<TtsSynthesisResult> {
    const chars = options.text.length;
    return {
      audioBase64: MockTtsProvider.DUMMY_MP3_BASE64,
      contentType: 'audio/mpeg',
      format: 'mp3',
      cached: false,
      characterCount: chars,
      provider: 'mock',
    };
  }
}

export class ElevenLabsTtsProvider implements ITtsProvider {
  readonly name = 'elevenlabs';
  private readonly apiKey: string;
  private readonly modelId: string;
  private readonly abbasVoiceId: string;
  private readonly dunyaVoiceId: string;
  private readonly cache: Map<string, string>;
  private readonly maxCacheSize: number;

  constructor(
    apiKey?: string,
    modelId?: string,
    abbasVoiceId?: string,
    dunyaVoiceId?: string,
    maxCacheSize?: number
  ) {
    this.apiKey = apiKey ?? config.ELEVENLABS_API_KEY;
    this.modelId = modelId ?? config.ELEVENLABS_MODEL_ID;
    this.abbasVoiceId = abbasVoiceId ?? config.ELEVENLABS_VOICE_ID_ABBAS;
    this.dunyaVoiceId = dunyaVoiceId ?? config.ELEVENLABS_VOICE_ID_DUNYA;
    this.maxCacheSize = maxCacheSize ?? config.TTS_CACHE_MAX_ENTRIES;
    this.cache = new Map<string, string>();
  }

  private resolveVoiceId(options: TtsSynthesisOptions): string {
    if (options.voiceId && options.voiceId.trim().length > 0) {
      return options.voiceId;
    }
    const persona = options.tutorPersona?.toLowerCase() || 'abbas';
    return persona === 'dunya' ? this.dunyaVoiceId : this.abbasVoiceId;
  }

  private createCacheKey(text: string, voiceId: string, modelId: string): string {
    return crypto
      .createHash('sha256')
      .update(`${modelId}:${voiceId}:${text.trim()}`)
      .digest('hex');
  }

  async synthesize(options: TtsSynthesisOptions): Promise<TtsSynthesisResult> {
    const rawText = options.text.trim();
    if (!rawText) {
      throw new Error('TTS text cannot be empty');
    }

    const boundedText = rawText.length > config.TTS_MAX_INPUT_CHARS
      ? rawText.substring(0, config.TTS_MAX_INPUT_CHARS)
      : rawText;

    const voiceId = this.resolveVoiceId(options);
    const cacheKey = this.createCacheKey(boundedText, voiceId, this.modelId);

    // 1. Check in-memory hash cache
    if (this.cache.has(cacheKey)) {
      const cachedAudio = this.cache.get(cacheKey)!;
      return {
        audioBase64: cachedAudio,
        contentType: 'audio/mpeg',
        format: 'mp3',
        cached: true,
        characterCount: boundedText.length,
        provider: 'elevenlabs',
      };
    }

    // 2. Validate API Key
    if (!this.apiKey || this.apiKey.trim().length === 0) {
      throw new Error('ELEVENLABS_API_KEY is not configured on the backend server');
    }

    // 3. Make HTTP request to ElevenLabs Text-to-Speech API
    const url = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;
    const payload = {
      text: boundedText,
      model_id: this.modelId,
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.75,
        style: 0.2,
        use_speaker_boost: true,
      },
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': this.apiKey,
        Accept: 'audio/mpeg',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(
        `ElevenLabs TTS API failed with HTTP ${response.status}: ${errorBody}`
      );
    }

    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const base64Audio = buffer.toString('base64');

    // 4. Save to bounded cache
    if (this.cache.size >= this.maxCacheSize) {
      // Evict oldest entry (LRU via Map key iteration)
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey) {
        this.cache.delete(oldestKey);
      }
    }
    this.cache.set(cacheKey, base64Audio);

    return {
      audioBase64: base64Audio,
      contentType: 'audio/mpeg',
      format: 'mp3',
      cached: false,
      characterCount: boundedText.length,
      provider: 'elevenlabs',
    };
  }
}
