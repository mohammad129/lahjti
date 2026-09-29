import { config } from '../config/env.js';
import { AiServiceUnavailableError, ForbiddenError, RateLimitError } from '../errors/api_error.js';
import {
  ElevenLabsTtsProvider,
  ITtsProvider,
  MockTtsProvider,
  TtsSynthesisOptions,
  TtsSynthesisResult,
} from '../providers/tts_provider.js';
import { monitoringService } from './monitoring_service.js';
import { usageMeteringService } from './usage_metering_service.js';

export class TtsService {
  private provider: ITtsProvider;
  private fallbackProvider: ITtsProvider = new MockTtsProvider();

  constructor(customProvider?: ITtsProvider) {
    if (customProvider) {
      this.provider = customProvider;
    } else if (config.NODE_ENV === 'test' && !process.env.TEST_LIVE_TTS) {
      this.provider = new MockTtsProvider();
    } else {
      switch (config.TTS_PROVIDER) {
        case 'elevenlabs':
          this.provider = new ElevenLabsTtsProvider();
          break;
        case 'mock':
        default:
          this.provider = new MockTtsProvider();
          break;
      }
    }
  }

  get providerName(): string {
    return this.provider.name;
  }

  setProvider(provider: ITtsProvider): void {
    this.provider = provider;
  }

  async synthesizeSpeech(
    options: TtsSynthesisOptions
  ): Promise<TtsSynthesisResult> {
    const userId = options.userId || 'anonymous';
    const ttsStartTime = Date.now();

    // 1. Quota Check for Voice synthesis
    if (userId && userId !== 'anonymous') {
      const quotaCheck = await usageMeteringService.canExecuteAiRequest(
        userId,
        50, // token equivalent
        5 // estimated voice seconds
      );
      if (!quotaCheck.allowed) {
        throw new RateLimitError(
          quotaCheck.reason || 'Voice synthesis daily quota exceeded'
        );
      }
    }

    // 2. Synthesize via active provider with resilient fallback
    let result: TtsSynthesisResult;
    try {
      result = await this.provider.synthesize(options);
      
      monitoringService.recordTtsRequest({
        provider: result.provider,
        characterCount: result.characterCount,
        cached: result.cached,
        success: true,
        durationMs: Date.now() - ttsStartTime,
        timestamp: Date.now(),
      });
    } catch (err: any) {
      monitoringService.recordTtsRequest({
        provider: this.provider.name,
        characterCount: options.text.length,
        cached: false,
        success: false,
        durationMs: Date.now() - ttsStartTime,
        errorCode: 'TTS_SYNTHESIS_FAILED',
        timestamp: Date.now(),
      });

      console.warn(`⚠️ Upstream TTS synthesis error: ${err?.message}. Delegating to resilient fallback.`);
      result = await this.fallbackProvider.synthesize(options);
    }

    // 3. Record voice usage if not cached
    if (!result.cached && userId && userId !== 'anonymous') {
      const estimatedSeconds = Math.max(
        1,
        Math.ceil(result.characterCount / 15)
      );
      await usageMeteringService.recordUsage({
        userId,
        feature: 'tutor_conversation',
        modelUsed: `tts-${result.provider}`,
        inputTokens: Math.ceil(result.characterCount / 4),
        outputTokens: 0,
        voiceSeconds: estimatedSeconds,
      });
    }

    return result;
  }
}

export const ttsService = new TtsService();
