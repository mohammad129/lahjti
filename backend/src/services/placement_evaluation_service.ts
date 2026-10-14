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
import { aiCacheService } from './ai_cache_service.js';
import { usageMeteringService } from './usage_metering_service.js';

export class PlacementEvaluationService {
  private provider: LanguageModelProvider;
  private customProvider?: LanguageModelProvider;
  private readonly timeoutMs: number;

  constructor(customProvider?: LanguageModelProvider, timeoutMs?: number) {
    this.timeoutMs = timeoutMs ?? config.AI_TIMEOUT_MS;
    this.customProvider = customProvider;

    if (customProvider) {
      this.provider = customProvider;
    } else if (config.NODE_ENV === 'test' && !process.env.TEST_LIVE_AI) {
      this.provider = new MockLanguageModelProvider();
    } else {
      switch (config.AI_PROVIDER) {
        case 'gemini':
          this.provider = new GeminiLanguageModelProvider(
            config.GEMINI_API_KEY,
            config.AI_FAST_MODEL || config.AI_MODEL
          );
          break;
        case 'openai':
          this.provider = new OpenAiLanguageModelProvider(
            config.OPENAI_API_KEY,
            config.AI_FAST_MODEL || config.AI_MODEL,
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
    this.customProvider = newProvider;
  }

  async evaluate(
    request: EvaluateRequest,
    context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    const userId = context.userId || 'anonymous';

    // 1. Quota & Rate Limit Check
    const quotaCheck = await usageMeteringService.canExecuteAiRequest(userId, 150, 0);
    if (!quotaCheck.allowed) {
      throw new RateLimitError(quotaCheck.reason || 'AI evaluation quota exceeded');
    }

    // 2. Cost & Sanity Guard: Truncate response
    if (request.response && request.response.length > config.AI_MAX_INPUT_CHARS) {
      request.response = request.response.substring(0, config.AI_MAX_INPUT_CHARS);
    }

    // 2.5 Deterministic Database / Key Check (0 AI Calls / 0 Credits Used)
    if (request.question.expectedAnswer && !this.customProvider) {
      const cleanExpected = request.question.expectedAnswer.trim().toLowerCase();
      const cleanActual = (request.response || '').trim().toLowerCase();
      const isCorrect = cleanExpected === cleanActual;
      const score = isCorrect ? 100 : (request.skipped ? 0 : 20);

      await usageMeteringService.recordUsage({
        userId,
        feature: 'placement_evaluation',
        modelUsed: 'database_deterministic',
        inputTokens: 0,
        outputTokens: 0,
        cachedResponsesCount: 1,
      });

      return {
        semanticScore: score,
        grammarScore: isCorrect ? 100 : 30,
        vocabularyScore: isCorrect ? 100 : 30,
        comprehensionScore: isCorrect ? 100 : 20,
        fluencyScore: isCorrect ? 100 : 20,
        pronunciationScore: null,
        confidence: 1.0,
        detectedErrors: [],
        correctedAnswer: isCorrect ? null : request.question.expectedAnswer,
        explanationArabic: isCorrect
          ? 'إجابة صحيحة وممتازة تماماً وفق قاعدة البيانات.'
          : `الإجابة الصحيحة هي "${request.question.expectedAnswer}". تم تسجيل ذلك للمراجعة.`,
        wasUnderstandable: isCorrect,
        difficultyRecommendation: isCorrect ? 'increase' : 'decrease',
      };
    }

    // 3. Cache check for deterministic questions (only when using standard provider)
    let cacheKey: string | null = null;
    if (!this.customProvider) {
      cacheKey = aiCacheService.generateKey('placement_eval', {
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
    }

    // 4. Timeout wrapper
    let timeoutHandle: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutHandle = setTimeout(() => {
        reject(
          new AiTimeoutError(
            `Evaluation request timed out after ${this.timeoutMs}ms`
          )
        );
      }, this.timeoutMs);
    });

    try {
      const evaluationPromise = this.provider.evaluate(request, context);
      const rawResult = await Promise.race([evaluationPromise, timeoutPromise]);

      // Strict validation for all providers
      const parsed = AiEvaluationOutputSchema.safeParse(rawResult);
      if (!parsed.success) {
        throw new AiOutputValidationError(
          `AI output validation failed: ${JSON.stringify(parsed.error.format())}`
        );
      }

      // 5. Store in cache if not a custom test spy
      if (cacheKey) {
        aiCacheService.set(cacheKey, parsed.data, 120);
      }

      // 6. Meter usage
      const estimatedInputTokens = Math.ceil(((request.response?.length || 0) + 200) / 4);
      const estimatedOutputTokens = 120;
      await usageMeteringService.recordUsage({
        userId,
        feature: 'placement_evaluation',
        modelUsed: this.provider.name,
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
      });

      return parsed.data;
    } finally {
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
    }
  }
}
