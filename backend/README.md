# Lahjti (لهجتي) — Backend AI Gateway

Secure backend proxy and AI evaluation gateway for the Lahjti language learning platform.

## Architecture

```
Flutter Mobile App (Dio ApiClient)
   │
   ▼ (HTTPS with Auth Token)
Express Gateway (/api/v1/placement/evaluate)
   │
   ├─► Auth Middleware (JWT / Dev Token)
   ├─► Rate Limiter (Sliding Window per IP/User)
   ├─► Request Validation (Zod Schema)
   │
   ▼
PlacementEvaluationService
   │
   ├─► Timeout Guard & Response Truncation
   ▼
LanguageModelProvider (Pluggable: Gemini | OpenAI | Mock)
   │
   ▼
Strict AI Output Schema Validation (Zod)
   │
   ▼
HTTP 200 (Structured JSON Evaluation) ──► Flutter PlacementEngine
```

## Security & Privacy Principles

1. **Zero Client Secrets**: No AI API keys or upstream vendor credentials exist in the Flutter application.
2. **Strict Request Validation**: Every field (target language, native language, age group, learning goal, CEFR level, question ID, response text) is validated server-side.
3. **Structured AI Outputs**: The AI is instructed via rigid system prompts and enforced via JSON Schema mode. Output is validated against `AiEvaluationOutputSchema` prior to returning to the client.
4. **No-Fake Pronunciation Rule**: For typed placement questions, `pronunciationScore` is strictly `null`.
5. **Cost & Abuse Protection**:
   - Rate limiting per user/IP.
   - Max input response length enforced (`1000` chars).
   - Timeouts (`10,000ms`).
   - No unnecessary historical context passed to AI.

## Supported Languages

- English (`english`)
- Spanish (`spanish`)
- French (`french`)
- German (`german`)
- Italian (`italian`)
- Turkish (`turkish`)
- Japanese (`japanese`)
- Chinese (`chinese`)
- Korean (`korean`)

## Environment Variables

Copy `.env.example` to `.env`:

```env
PORT=3000
NODE_ENV=development
AI_PROVIDER=mock # 'mock' | 'gemini' | 'openai'
AI_MODEL=gemini-2.5-flash
GEMINI_API_KEY=
OPENAI_API_KEY=
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=30
AI_TIMEOUT_MS=10000
MAX_RESPONSE_LENGTH=1000
JWT_SECRET=dev_secret_key_lahjti_2026
```

## Running the Backend

```bash
# Install dependencies
npm install

# Run in development mode (hot reload)
npm run dev

# Run automated tests
npm test

# Build for production
npm run build
```
