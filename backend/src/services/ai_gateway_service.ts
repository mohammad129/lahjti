import { config } from '../config/env.js';
import { AiOutputValidationError, AiTimeoutError, RateLimitError } from '../errors/api_error.js';
import { GeminiLanguageModelProvider } from '../providers/gemini_provider.js';
import {
  EvaluationContext,
  LanguageModelProvider,
} from '../providers/language_model_provider.js';
import { MockLanguageModelProvider } from '../providers/mock_provider.js';
import { OpenAiLanguageModelProvider } from '../providers/openai_provider.js';
import {
  AiEvaluationOutput,
  AiEvaluationOutputSchema,
  EvaluateRequest,
} from '../schemas/evaluation_schemas.js';
import {
  AiTutorConversationOutput,
  AiTutorConversationOutputSchema,
  TutorConversationRequest,
} from '../schemas/tutor_conversation_schemas.js';
import { aiCacheService } from './ai_cache_service.js';
import { jordanianDialectService } from './jordanian_dialect_service.js';
import { monitoringService } from './monitoring_service.js';
import { usageMeteringService } from './usage_metering_service.js';

export class AiGatewayService {
  private static instance: AiGatewayService;
  private fastProvider: LanguageModelProvider;
  private advancedProvider: LanguageModelProvider;
  private readonly timeoutMs: number;

  constructor(
    customFastProvider?: LanguageModelProvider,
    customAdvancedProvider?: LanguageModelProvider,
    timeoutMs?: number
  ) {
    this.timeoutMs = timeoutMs ?? config.AI_TIMEOUT_MS;

    if (customFastProvider && customAdvancedProvider) {
      this.fastProvider = customFastProvider;
      this.advancedProvider = customAdvancedProvider;
    } else if (config.NODE_ENV === 'test' && !process.env.TEST_LIVE_AI) {
      this.fastProvider = new MockLanguageModelProvider();
      this.advancedProvider = new MockLanguageModelProvider();
    } else {
      switch (config.AI_PROVIDER) {
        case 'gemini':
          this.fastProvider = new GeminiLanguageModelProvider(
            config.GEMINI_API_KEY,
            config.AI_FAST_MODEL
          );
          this.advancedProvider = new GeminiLanguageModelProvider(
            config.GEMINI_API_KEY,
            config.AI_ADVANCED_MODEL
          );
          break;
        case 'openai':
          this.fastProvider = new OpenAiLanguageModelProvider(
            config.OPENAI_API_KEY,
            config.AI_FAST_MODEL,
            this.timeoutMs,
            config.OPENAI_BASE_URL
          );
          this.advancedProvider = new OpenAiLanguageModelProvider(
            config.OPENAI_API_KEY,
            config.AI_ADVANCED_MODEL,
            this.timeoutMs,
            config.OPENAI_BASE_URL
          );
          break;
        case 'mock':
        default:
          this.fastProvider = new MockLanguageModelProvider();
          this.advancedProvider = new MockLanguageModelProvider();
          break;
      }
    }
  }

  public static getInstance(): AiGatewayService {
    if (!AiGatewayService.instance) {
      AiGatewayService.instance = new AiGatewayService();
    }
    return AiGatewayService.instance;
  }

  public setProviders(fast: LanguageModelProvider, advanced: LanguageModelProvider): void {
    this.fastProvider = fast;
    this.advancedProvider = advanced;
  }

  /**
   * Evaluates a placement or learning exercise response.
   * Uses fast/cheaper model routing and deterministic caching.
   */
  public async evaluate(
    request: EvaluateRequest,
    context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    const userId = context.userId || 'anonymous';

    // 1. Quota & Rate Limit Check
    const quotaCheck = await usageMeteringService.canExecuteAiRequest(userId, 150, 0);
    if (!quotaCheck.allowed) {
      throw new RateLimitError(quotaCheck.reason || 'AI request quota exceeded');
    }

    // 2. Input Length & Context Bounds
    if (request.response && request.response.length > config.AI_MAX_INPUT_CHARS) {
      request.response = request.response.substring(0, config.AI_MAX_INPUT_CHARS);
    }

    // 3. Cache Check for deterministic / static placement evaluations
    const cacheKey = aiCacheService.generateKey('eval', {
      qId: request.question.id,
      resp: (request.response || '').trim().toLowerCase(),
      diff: request.difficulty,
      lang: request.targetLanguage,
      skipped: request.skipped,
    });

    const cached = aiCacheService.get<AiEvaluationOutput>(cacheKey);
    if (cached) {
      await usageMeteringService.recordUsage({
        userId,
        feature: 'placement_evaluation',
        modelUsed: 'cache',
        inputTokens: 0,
        outputTokens: 0,
        cachedResponsesCount: 1,
      });
      return cached;
    }

    // 4. Model Routing: Use Fast Model for discrete evaluation
    const provider = this.fastProvider;

    // 5. Execute with Timeout
    const evalStartTime = Date.now();
    let timeoutHandle: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutHandle = setTimeout(() => {
        reject(new AiTimeoutError(`Evaluation request timed out after ${this.timeoutMs}ms`));
      }, this.timeoutMs);
    });

    try {
      const evaluationPromise = provider.evaluate(request, context);
      const rawResult = await Promise.race([evaluationPromise, timeoutPromise]);

      const parsed = AiEvaluationOutputSchema.safeParse(rawResult);
      if (!parsed.success) {
        throw new AiOutputValidationError(
          `Evaluation validation failed: ${JSON.stringify(parsed.error.format())}`
        );
      }

      // 6. Cache the successful result
      aiCacheService.set(cacheKey, parsed.data, 120);

      // 7. Meter usage in database
      const estimatedInputTokens = Math.ceil(((request.response?.length || 0) + 200) / 4);
      const estimatedOutputTokens = 120;
      await usageMeteringService.recordUsage({
        userId,
        feature: 'placement_evaluation',
        modelUsed: provider.name,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
      });

      // 8. Record telemetry in monitoring
      monitoringService.recordAiRequest({
        feature: 'placement_evaluation',
        provider: provider.name,
        model: config.AI_FAST_MODEL,
        success: true,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        durationMs: Date.now() - evalStartTime,
        timestamp: Date.now(),
      });

      return parsed.data;
    } catch (err: any) {
      monitoringService.recordAiRequest({
        feature: 'placement_evaluation',
        provider: provider.name,
        model: config.AI_FAST_MODEL,
        success: false,
        inputTokens: 0,
        outputTokens: 0,
        durationMs: Date.now() - evalStartTime,
        errorCode: err?.code || 'AI_ERROR',
        timestamp: Date.now(),
      });
      throw err;
    } finally {
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
    }
  }

  /**
   * Handles conversational tutor turns with context sliding window and advanced model routing.
   */
  public async converse(
    request: TutorConversationRequest,
    context: EvaluationContext,
    voiceDurationSeconds: number = 0
  ): Promise<AiTutorConversationOutput> {
    const userId = context.userId || 'anonymous';

    // 1. Quota & Rate Limit Check (including voice cost protection)
    const quotaCheck = await usageMeteringService.canExecuteAiRequest(
      userId,
      250,
      voiceDurationSeconds
    );
    if (!quotaCheck.allowed) {
      throw new RateLimitError(quotaCheck.reason || 'AI conversation quota exceeded');
    }

    // 2. Token & Context Limits: Bound input characters
    if (request.userMessage && request.userMessage.length > config.AI_MAX_INPUT_CHARS) {
      request.userMessage = request.userMessage.substring(0, config.AI_MAX_INPUT_CHARS);
    }

    // 3. Sliding Window History: limit turns to strictly configured maximum
    const maxTurns = config.AI_MAX_CONTEXT_TURNS;
    if (request.recentHistory && request.recentHistory.length > maxTurns) {
      request.recentHistory = request.recentHistory.slice(-maxTurns);
    }

    // 4. Cache Check for exact repeated starter phrases
    const isStarter = request.isSessionStart || (!request.recentHistory || request.recentHistory.length === 0);
    const cacheKey = isStarter
      ? aiCacheService.generateKey('tutor_starter', {
          persona: request.tutorPersona,
          lang: request.targetLanguage,
          diff: request.difficulty,
          topic: request.currentTopic || '',
        })
      : null;

    if (cacheKey) {
      const cached = aiCacheService.get<AiTutorConversationOutput>(cacheKey);
      if (cached) {
        await usageMeteringService.recordUsage({
          userId,
          feature: 'tutor_conversation',
          modelUsed: 'cache',
          inputTokens: 0,
          outputTokens: 0,
          voiceSeconds: voiceDurationSeconds,
          cachedResponsesCount: 1,
        });
        return cached;
      }
    }

    // 5. Model Routing: Use Advanced Model for multi-turn conversational tutor
    const provider = this.advancedProvider;

    // 6. Execute with Timeout
    const convStartTime = Date.now();
    let timeoutHandle: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutHandle = setTimeout(() => {
        reject(new AiTimeoutError(`Tutor conversation request timed out after ${this.timeoutMs}ms`));
      }, this.timeoutMs);
    });

    try {
      const conversationPromise = provider.conversation(request, context);
      const rawResult = await Promise.race([conversationPromise, timeoutPromise]);

      const parsed = AiTutorConversationOutputSchema.safeParse(rawResult);
      if (!parsed.success) {
        throw new AiOutputValidationError(
          `Tutor conversation validation failed: ${JSON.stringify(parsed.error.format())}`
        );
      }

      // If this was a starter turn, cache for subsequent users
      if (cacheKey) {
        aiCacheService.set(cacheKey, parsed.data, 180);
      }

      // 7. Meter usage in database
      const estimatedInputTokens = Math.ceil(
        ((request.userMessage?.length || 0) + (request.recentHistory?.length || 0) * 80 + 300) / 4
      );
      const estimatedOutputTokens = 150;
      await usageMeteringService.recordUsage({
        userId,
        feature: 'tutor_conversation',
        modelUsed: provider.name,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        voiceSeconds: voiceDurationSeconds,
      });

      // 8. Record telemetry in monitoring
      monitoringService.recordAiRequest({
        feature: 'tutor_conversation',
        provider: provider.name,
        model: config.AI_ADVANCED_MODEL,
        success: true,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        durationMs: Date.now() - convStartTime,
        timestamp: Date.now(),
      });

      return parsed.data;
    } catch (err: any) {
      monitoringService.recordAiRequest({
        feature: 'tutor_conversation',
        provider: provider.name,
        model: config.AI_ADVANCED_MODEL,
        success: false,
        inputTokens: 0,
        outputTokens: 0,
        durationMs: Date.now() - convStartTime,
        errorCode: err?.code || 'AI_ERROR',
        timestamp: Date.now(),
      });
      throw err;
    } finally {
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
    }
  }
}

export const aiGatewayService = AiGatewayService.getInstance();
