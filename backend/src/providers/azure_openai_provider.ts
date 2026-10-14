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

export class AzureOpenAiLanguageModelProvider implements LanguageModelProvider {
  readonly name = 'azure_openai';
  private readonly apiKey: string;
  private readonly endpoint: string;
  private readonly deployment: string;
  private readonly timeoutMs: number;
  private readonly apiVersion: string;

  constructor(
    apiKey: string,
    endpoint: string,
    deployment: string,
    timeoutMs: number = 10000,
    apiVersion: string = '2024-02-15-preview'
  ) {
    this.apiKey = apiKey;
    this.endpoint = endpoint.replace(/\/+$/, '');
    this.deployment = deployment;
    this.timeoutMs = timeoutMs;
    this.apiVersion = apiVersion;
  }

  private resilientConversation(request: TutorConversationRequest): AiTutorConversationOutput {
    return DynamicBilingualEngine.processTurn(request);
  }

  async evaluate(
    request: EvaluateRequest,
    _context: EvaluationContext
  ): Promise<AiEvaluationOutput> {
    if (!this.apiKey || !this.endpoint) {
      console.warn('⚠️ Azure OpenAI config missing. Delegating to resilient engine.');
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    const systemPrompt = buildSystemPrompt(request);
    const userPrompt = buildUserPrompt(request);

    const url = `${this.endpoint}/openai/deployments/${this.deployment}/chat/completions?api-version=${this.apiVersion}`;

    let response: Response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': this.apiKey,
        },
        body: JSON.stringify({
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
      console.warn(`⚠️ Azure OpenAI evaluation call to ${url} failed (${err?.message}).`);
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    if (!response.ok) {
      console.warn(`⚠️ Azure OpenAI returned ${response.status}. Delegating to resilient engine.`);
      const fallback = new MockLanguageModelProvider();
      return fallback.evaluate(request, _context);
    }

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
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
    if (!this.apiKey || !this.endpoint) {
      console.warn('⚠️ Azure OpenAI config missing. Delegating to resilient engine.');
      return this.resilientConversation(request);
    }

    const systemPrompt = buildTutorConversationSystemPrompt(request);
    const userPrompt = buildTutorConversationUserPrompt(request);

    const url = `${this.endpoint}/openai/deployments/${this.deployment}/chat/completions?api-version=${this.apiVersion}`;

    let response: Response;
    try {
      const payload = {
        temperature: 0.7,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
      };
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': this.apiKey,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (err: any) {
      console.warn(`⚠️ Azure OpenAI conversation call to ${url} failed (${err?.message}).`);
      return this.resilientConversation(request);
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`⚠️ Azure OpenAI returned status ${response.status}. Body: ${errorText}.`);
      return this.resilientConversation(request);
    }

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
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
