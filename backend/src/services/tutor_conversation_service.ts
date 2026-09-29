import { config } from '../config/env.js';
import { getDatabase } from '../db/index.js';
import { AiOutputValidationError, AiTimeoutError, ForbiddenError, RateLimitError } from '../errors/api_error.js';
import { GeminiLanguageModelProvider } from '../providers/gemini_provider.js';
import {
  EvaluationContext,
  LanguageModelProvider,
} from '../providers/language_model_provider.js';
import { MockLanguageModelProvider } from '../providers/mock_provider.js';
import { OpenAiLanguageModelProvider } from '../providers/openai_provider.js';
import {
  AiTutorConversationOutput,
  AiTutorConversationOutputSchema,
  TutorConversationRequest,
} from '../schemas/tutor_conversation_schemas.js';
import { ttsService } from './tts_service.js';
import { usageMeteringService } from './usage_metering_service.js';

export class TutorConversationService {
  private provider: LanguageModelProvider;
  private readonly timeoutMs: number;

  constructor(customProvider?: LanguageModelProvider, timeoutMs?: number) {
    this.timeoutMs = timeoutMs ?? config.AI_TIMEOUT_MS;

    if (customProvider) {
      this.provider = customProvider;
    } else if (config.NODE_ENV === 'test' && !process.env.TEST_LIVE_AI) {
      this.provider = new MockLanguageModelProvider();
    } else {
      switch (config.AI_PROVIDER) {
        case 'gemini':
          this.provider = new GeminiLanguageModelProvider(
            config.GEMINI_API_KEY,
            config.AI_ADVANCED_MODEL || config.AI_MODEL
          );
          break;
        case 'openai':
          this.provider = new OpenAiLanguageModelProvider(
            config.OPENAI_API_KEY,
            config.AI_ADVANCED_MODEL || config.AI_MODEL,
            this.timeoutMs,
            config.OPENAI_BASE_URL
          );
          break;
        case 'mock':
        default:
          this.provider = new MockLanguageModelProvider();
          break;
      }
    }
  }

  get providerName(): string {
    return this.provider.name;
  }

  setProvider(newProvider: LanguageModelProvider): void {
    this.provider = newProvider;
  }

  async converse(
    request: TutorConversationRequest,
    context: EvaluationContext,
    voiceDurationSeconds: number = 0
  ): Promise<AiTutorConversationOutput> {
    const userId = context.userId || 'anonymous';

    // 1. Subscription & Entitlement Server-Authoritative Check
    if (userId && userId !== 'anonymous') {
      try {
        const db = getDatabase();
        const sub = await db.getSubscription(userId);
        if (sub) {
          const now = new Date();
          const isTrialExpired =
            sub.status === 'trial' && sub.trialEndsAt && now.getTime() > new Date(sub.trialEndsAt).getTime();
          const isPastDueOrExpired =
            sub.status === 'expired' || sub.status === 'pastDue' || sub.status === 'suspended';
          if (isTrialExpired || isPastDueOrExpired) {
            throw new ForbiddenError(
              'Active trial or subscription required to use AI tutor',
              'انتهت الفترة التجريبية للاشتراك. يرجى الاشتراك للمتابعة.'
            );
          }
        }
      } catch (err) {
        if (err instanceof ForbiddenError) throw err;
        // Non-fatal db check error fallback
      }
    }

    // 2. Quota & Voice Protection Check
    const quotaCheck = await usageMeteringService.canExecuteAiRequest(
      userId,
      250,
      voiceDurationSeconds
    );
    if (!quotaCheck.allowed) {
      throw new RateLimitError(quotaCheck.reason || 'AI conversation quota exceeded');
    }

    // 3. Cost & Sanity Guard: Truncate user message
    if (
      request.userMessage &&
      request.userMessage.length > config.AI_MAX_INPUT_CHARS
    ) {
      request.userMessage = request.userMessage.substring(
        0,
        config.AI_MAX_INPUT_CHARS
      );
    }

    // 4. Bound history context to max turns
    const maxTurns = config.AI_MAX_CONTEXT_TURNS || 6;
    if (request.recentHistory && request.recentHistory.length > maxTurns) {
      request.recentHistory = request.recentHistory.slice(-maxTurns);
    }

    // 5. Timeout wrapper
    let timeoutHandle: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutHandle = setTimeout(() => {
        reject(
          new AiTimeoutError(
            `Tutor conversation request timed out after ${this.timeoutMs}ms`
          )
        );
      }, this.timeoutMs);
    });

    try {
      const conversationPromise = this.provider.conversation(request, context);
      const rawResult = await Promise.race([
        conversationPromise,
        timeoutPromise,
      ]);

      // Strict output validation
      const parsed = AiTutorConversationOutputSchema.safeParse(rawResult);
      if (!parsed.success) {
        throw new AiOutputValidationError(
          `Tutor conversation output validation failed: ${JSON.stringify(
            parsed.error.format()
          )}`
        );
      }

      const outputData = parsed.data;

      // Optional ElevenLabs Voice Synthesis
      if (request.synthesizeVoice && outputData.tutorResponse) {
        try {
          const ttsResult = await ttsService.synthesizeSpeech({
            text: outputData.tutorResponse,
            tutorPersona: request.tutorPersona,
            targetLanguage: request.targetLanguage,
            userId,
          });
          outputData.audioBase64 = ttsResult.audioBase64;
          outputData.voiceProvider = ttsResult.provider;
        } catch {
          // Graceful fallback to client device TTS
          outputData.audioBase64 = null;
          outputData.voiceProvider = 'device_fallback';
        }
      }

      // 6. Meter usage
      const estimatedInputTokens = Math.ceil(
        ((request.userMessage?.length || 0) + (request.recentHistory?.length || 0) * 80 + 300) / 4
      );
      const estimatedOutputTokens = 150;
      await usageMeteringService.recordUsage({
        userId,
        feature: 'tutor_conversation',
        modelUsed: this.provider.name,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        voiceSeconds: voiceDurationSeconds,
      });

      return outputData;
    } finally {
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
    }
  }
}
