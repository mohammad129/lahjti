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
import { MockLanguageModelProvider } from './mock_provider.js';
import { DynamicBilingualEngine } from '../services/dynamic_bilingual_engine.js';


function extractJson(text: string): unknown {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  const raw = match ? match[1].trim() : text.replace(/```json\n?|```/g, '').trim();
  return JSON.parse(raw);
}

export class OpenAiLanguageModelProvider implements LanguageModelProvider {
  readonly name = 'openai';
  private readonly apiKey: string;
  private readonly model: string;
  private readonly timeoutMs: number;
  private readonly baseUrl: string;

  constructor(
    apiKey: string,
    model: string = 'gpt-4o-mini',
    timeoutMs: number = 10000,
    baseUrl?: string
  ) {
    this.apiKey = apiKey;
    this.model = model.trim();
    this.timeoutMs = timeoutMs;
    const cleanUrl = baseUrl?.trim();
    if (cleanUrl) {
      this.baseUrl = cleanUrl.replace(/\/+$/, '');
    } else if (apiKey.startsWith('sk-ntm-')) {
      this.baseUrl = 'https://api.netmind.ai/inference-api/openai/v1';
    } else {
      this.baseUrl = 'https://api.openai.com/v1';
    }
  }

  /**
   * A provider outage must not make a live conversation silently switch to
   * English. This small, safe reply is deliberately separate from the mock
   * provider and preserves the learner's input language until AI recovers.
   */
  private resilientConversation(request: TutorConversationRequest): AiTutorConversationOutput {
    return DynamicBilingualEngine.processTurn(request);
  }

  async evaluate(
    request: EvaluateRequest,
    _context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    if (!this.apiKey) {
      console.warn('⚠️ OpenAI API key not configured. Delegating to resilient pedagogical engine.');
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    const systemPrompt = buildSystemPrompt(request);
    const userPrompt = buildUserPrompt(request);

    let response: Response;
    try {
      response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: this.model,
          temperature: 0.1,
          response_format: { type: 'json_object' },
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
        }),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (err: any) {
      console.warn(`⚠️ Upstream AI evaluation call to ${this.baseUrl} failed (${err?.message}). Delegating to resilient engine.`);
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    if (!response.ok) {
      console.warn(`⚠️ Upstream AI evaluation to ${this.baseUrl} returned ${response.status}. Delegating to resilient engine.`);
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    const data = (await response.json()) as {
      choices?: Array<{
        message?: { content?: string };
      }>;
    };

    const content = data.choices?.[0]?.message?.content;
    if (!content || content.trim().length === 0) {
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    let parsedJson: unknown;
    try {
      parsedJson = extractJson(content);
    } catch {
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    if (typeof parsedJson === 'object' && parsedJson !== null) {
      (parsedJson as Record<string, unknown>).pronunciationScore = null;
    }

    const validationResult = AiEvaluationOutputSchema.safeParse(parsedJson);
    if (!validationResult.success) {
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    return validationResult.data;
  }

  async conversation(
    request: TutorConversationRequest,
    _context: EvaluationContext
  ): Promise<AiTutorConversationOutput> {
    if (!this.apiKey) {
      console.warn('⚠️ OpenAI API key not configured. Delegating to resilient pedagogical engine.');
      return this.resilientConversation(request);
    }

    const systemPrompt = buildTutorConversationSystemPrompt(request);
    const userPrompt = buildTutorConversationUserPrompt(request);

    let response: Response;
    try {
      const payload = {
        model: this.model,
        temperature: 0.7,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
      };
      console.log('Sending OpenAI payload:', JSON.stringify(payload).substring(0, 200) + '...');
      response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (err: any) {
      console.warn(`⚠️ Upstream AI conversation call to ${this.baseUrl} failed (${err?.message}). Delegating to resilient pedagogical engine.`);
      return this.resilientConversation(request);
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`⚠️ Upstream AI conversation to ${this.baseUrl} returned status ${response.status}. Body: ${errorText}. Delegating to resilient pedagogical engine.`);
      return this.resilientConversation(request);
    }

    const data = (await response.json()) as {
      choices?: Array<{
        message?: { content?: string };
      }>;
    };

    const content = data.choices?.[0]?.message?.content;
    if (!content || content.trim().length === 0) {
      return this.resilientConversation(request);
    }

    let parsedJson: unknown;
    try {
      parsedJson = extractJson(content);
    } catch {
      return this.resilientConversation(request);
    }

    const validationResult = AiTutorConversationOutputSchema.safeParse(parsedJson);
    if (!validationResult.success) {
      return this.resilientConversation(request);
    }

    return validationResult.data;
  }
}
