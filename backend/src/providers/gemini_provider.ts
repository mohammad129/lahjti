import {
  AiOutputValidationError,
  AiServiceUnavailableError,
  AiTimeoutError,
} from '../errors/api_error.js';
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
import {
  buildSystemPrompt,
  buildTutorConversationSystemPrompt,
  buildTutorConversationUserPrompt,
  buildUserPrompt,
  EvaluationContext,
  LanguageModelProvider,
} from './language_model_provider.js';

function extractJson(text: string): unknown {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  const raw = match ? match[1].trim() : text.replace(/```json\n?|```/g, '').trim();
  return JSON.parse(raw);
}

export class GeminiLanguageModelProvider implements LanguageModelProvider {
  readonly name = 'gemini';
  private readonly apiKey: string;
  private readonly model: string;
  private readonly timeoutMs: number;

  constructor(apiKey: string, model: string = 'gemini-2.5-flash', timeoutMs: number = 10000) {
    this.apiKey = apiKey;
    this.model = model;
    this.timeoutMs = timeoutMs;
  }

  async evaluate(
    request: EvaluateRequest,
    _context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    if (!this.apiKey) {
      throw new AiServiceUnavailableError(
        'Gemini API key is not configured on the backend',
        'خدمة التقييم الذكي غير مهيئة حاليًا. يرجى مراجعة إعدادات الخادم.'
      );
    }

    const systemPrompt = buildSystemPrompt(request);
    const userPrompt = buildUserPrompt(request);
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`;

    const requestBody = {
      systemInstruction: {
        parts: [{ text: systemPrompt }],
      },
      contents: [
        {
          role: 'user',
          parts: [{ text: userPrompt }],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: 'application/json',
      },
    };

    let response: Response;
    try {
      response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (err: any) {
      if (err?.name === 'TimeoutError' || err?.name === 'AbortError') {
        throw new AiTimeoutError(`Gemini evaluation timed out after ${this.timeoutMs}ms`);
      }
      throw new AiServiceUnavailableError(
        `Gemini network call failed: ${err instanceof Error ? err.message : 'Network error'}`
      );
    }

    if (!response.ok) {
      throw new AiServiceUnavailableError(
        `Gemini API returned status ${response.status}`,
        'تعذر الاتصال بمزود الذكاء الاصطناعي. يرجى المحاولة مرة أخرى لاحقًا.'
      );
    }

    const data = (await response.json()) as {
      candidates?: Array<{
        content?: {
          parts?: Array<{ text?: string }>;
        };
      }>;
    };

    const textPart = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!textPart || textPart.trim().length === 0) {
      throw new AiOutputValidationError('Gemini returned empty candidate response');
    }

    let parsedJson: unknown;
    try {
      parsedJson = extractJson(textPart);
    } catch {
      throw new AiOutputValidationError('Failed to parse Gemini output as JSON');
    }

    if (typeof parsedJson === 'object' && parsedJson !== null) {
      (parsedJson as Record<string, unknown>).pronunciationScore = null;
    }

    const validationResult = AiEvaluationOutputSchema.safeParse(parsedJson);
    if (!validationResult.success) {
      throw new AiOutputValidationError(
        `Gemini output failed schema validation: ${JSON.stringify(validationResult.error.format())}`
      );
    }

    return validationResult.data;
  }

  async conversation(
    request: TutorConversationRequest,
    _context: EvaluationContext
  ): Promise<AiTutorConversationOutput> {
    if (!this.apiKey) {
      throw new AiServiceUnavailableError(
        'Gemini API key is not configured on the backend',
        'خدمة المحادثة الذكية غير مهيئة حاليًا. يرجى مراجعة إعدادات الخادم.'
      );
    }

    const systemPrompt = buildTutorConversationSystemPrompt(request);
    const userPrompt = buildTutorConversationUserPrompt(request);
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`;

    const requestBody = {
      systemInstruction: {
        parts: [{ text: systemPrompt }],
      },
      contents: [
        {
          role: 'user',
          parts: [{ text: userPrompt }],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        responseMimeType: 'application/json',
      },
    };

    let response: Response;
    try {
      response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (err: any) {
      if (err?.name === 'TimeoutError' || err?.name === 'AbortError') {
        throw new AiTimeoutError(`Gemini conversation timed out after ${this.timeoutMs}ms`);
      }
      throw new AiServiceUnavailableError(
        `Gemini conversation network call failed: ${err instanceof Error ? err.message : 'Network error'}`
      );
    }

    if (!response.ok) {
      throw new AiServiceUnavailableError(
        `Gemini conversation returned status ${response.status}`,
        'تعذر إتمام المحادثة مع المعلم الذكي حالياً. يرجى المحاولة مرة أخرى.'
      );
    }

    const data = (await response.json()) as {
      candidates?: Array<{
        content?: {
          parts?: Array<{ text?: string }>;
        };
      }>;
    };

    const textPart = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!textPart || textPart.trim().length === 0) {
      throw new AiOutputValidationError('Gemini returned empty conversation candidate response');
    }

    let parsedJson: unknown;
    try {
      parsedJson = extractJson(textPart);
    } catch {
      throw new AiOutputValidationError('Failed to parse Gemini conversation output as JSON');
    }

    const validationResult = AiTutorConversationOutputSchema.safeParse(parsedJson);
    if (!validationResult.success) {
      throw new AiOutputValidationError(
        `Gemini conversation output failed schema validation: ${JSON.stringify(validationResult.error.format())}`
      );
    }

    return validationResult.data;
  }
}
