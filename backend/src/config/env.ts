import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('3000').transform((val) => parseInt(val, 10)),
  HOST: z.string().default('0.0.0.0'),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  AI_PROVIDER: z.enum(['mock', 'gemini', 'openai']).default('mock'),
  AI_MODEL: z.string().default('gemini-2.5-flash'),
  AI_FAST_MODEL: z.string().default('gemini-2.5-flash-8b'),
  AI_ADVANCED_MODEL: z.string().default('gemini-2.5-flash'),
  GEMINI_API_KEY: z.string().optional().default(''),
  OPENAI_API_KEY: z.string().optional().default(''),
  OPENAI_BASE_URL: z.string().optional().default('https://api.openai.com/v1'),
  RATE_LIMIT_WINDOW_MS: z.string().default('60000').transform((val) => parseInt(val, 10)),
  RATE_LIMIT_MAX_REQUESTS: z.string().default('30').transform((val) => parseInt(val, 10)),
  AI_TIMEOUT_MS: z.string().default('10000').transform((val) => parseInt(val, 10)),
  MAX_RESPONSE_LENGTH: z.string().default('1000').transform((val) => parseInt(val, 10)),
  AI_MAX_CONTEXT_TURNS: z.string().default('6').transform((val) => parseInt(val, 10)),
  AI_MAX_INPUT_CHARS: z.string().default('500').transform((val) => parseInt(val, 10)),
  AI_MAX_OUTPUT_TOKENS: z.string().default('300').transform((val) => parseInt(val, 10)),
  AI_CACHE_TTL_SECONDS: z.string().default('86400').transform((val) => parseInt(val, 10)),
  VOICE_MAX_SECONDS_PER_TURN: z.string().default('30').transform((val) => parseInt(val, 10)),
  DAILY_QUOTA_TRIAL_REQUESTS: z.string().default('30').transform((val) => parseInt(val, 10)),
  DAILY_QUOTA_PAID_REQUESTS: z.string().default('200').transform((val) => parseInt(val, 10)),
  DAILY_QUOTA_SCHOOL_STUDENT_REQUESTS: z.string().default('60').transform((val) => parseInt(val, 10)),
  DAILY_QUOTA_SCHOOL_TEACHER_REQUESTS: z.string().default('500').transform((val) => parseInt(val, 10)),
  JWT_SECRET: z.string().optional().default(''),
  // Comma-separated bootstrap administrator subject IDs. Keep this server-only.
  ADMIN_USER_IDS: z.string().optional().default(''),
  DATABASE_URL: z.string().optional().default(''),
  // Step 28: ElevenLabs Production TTS
  ELEVENLABS_API_KEY: z.string().optional().default(''),
  ELEVENLABS_MODEL_ID: z.string().default('eleven_multilingual_v2'),
  // Voice IDs belong to the account owner and must be configured explicitly.
  ELEVENLABS_VOICE_ID_ABBAS: z.string().optional().default(''),
  ELEVENLABS_VOICE_ID_DUNYA: z.string().optional().default(''),
  TTS_PROVIDER: z.enum(['mock', 'elevenlabs', 'disabled']).default('elevenlabs'),
  TTS_CACHE_MAX_ENTRIES: z.string().default('200').transform((val) => parseInt(val, 10)),
  TTS_MAX_INPUT_CHARS: z.string().default('500').transform((val) => parseInt(val, 10)),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.format());
  throw new Error('Invalid environment configuration');
}

export const config = parsedEnv.data;

if (config.NODE_ENV === 'production' && !config.JWT_SECRET) {
  throw new Error('JWT_SECRET must be configured in production');
}
