import { config } from '../config/env.js';
import { getDatabase } from '../db/index.js';

export interface UserQuotaConfig {
  maxDailyRequests: number;
  maxDailyTokens: number;
  maxDailyVoiceSeconds: number;
  maxBurstPerMinute: number;
}

export class UsageMeteringService {
  private static instance: UsageMeteringService;
  
  // In-memory sliding window rate limiter: userId -> array of timestamps
  private burstRateLimiter: Map<string, number[]> = new Map();

  public static getInstance(): UsageMeteringService {
    if (!UsageMeteringService.instance) {
      UsageMeteringService.instance = new UsageMeteringService();
    }
    return UsageMeteringService.instance;
  }

  /**
   * Determine user tier and return corresponding quota limits
   */
  public async getQuotaForUser(userId: string): Promise<UserQuotaConfig> {
    const db = getDatabase();

    // Check School Membership first
    const membership = await db.getSchoolMembership(userId);
    if (membership && membership.status === 'active') {
      if (membership.role === 'teacher') {
        return {
          maxDailyRequests: config.DAILY_QUOTA_SCHOOL_TEACHER_REQUESTS,
          maxDailyTokens: 350000,
          maxDailyVoiceSeconds: 7200, // 2 hours
          maxBurstPerMinute: 60,
        };
      } else if (membership.role === 'student') {
        return {
          maxDailyRequests: config.DAILY_QUOTA_SCHOOL_STUDENT_REQUESTS,
          maxDailyTokens: 60000,
          maxDailyVoiceSeconds: 1200, // 20 minutes
          maxBurstPerMinute: 20,
        };
      }
    }

    const sub = await db.getSubscription(userId);

    // Default base tier (if no subscription or inactive)
    let maxRequests = config.DAILY_QUOTA_TRIAL_REQUESTS;
    let maxTokens = 30000;
    let maxVoiceSeconds = 600; // 10 minutes
    let maxBurst = 15;

    if (sub) {
      if (sub.accountContext === 'school') {
        if (sub.role === 'teacher') {
          maxRequests = config.DAILY_QUOTA_SCHOOL_TEACHER_REQUESTS;
          maxTokens = 350000;
          maxVoiceSeconds = 7200;
          maxBurst = 60;
        } else {
          maxRequests = config.DAILY_QUOTA_SCHOOL_STUDENT_REQUESTS;
          maxTokens = 60000;
          maxVoiceSeconds = 1200;
          maxBurst = 20;
        }
      } else {
        // Individual
        if (sub.status === 'active') {
          maxRequests = config.DAILY_QUOTA_PAID_REQUESTS;
          maxTokens = 200000;
          maxVoiceSeconds = 3600; // 1 hour
          maxBurst = 30;
        } else if (sub.status === 'trial') {
          maxRequests = config.DAILY_QUOTA_TRIAL_REQUESTS;
          maxTokens = 30000;
          maxVoiceSeconds = 600;
          maxBurst = 15;
        } else {
          // Expired / cancelled / suspended
          maxRequests = 5;
          maxTokens = 5000;
          maxVoiceSeconds = 0;
          maxBurst = 5;
        }
      }
    }

    return {
      maxDailyRequests: maxRequests,
      maxDailyTokens: maxTokens,
      maxDailyVoiceSeconds: maxVoiceSeconds,
      maxBurstPerMinute: maxBurst,
    };
  }

  /**
   * Check if a user has exceeded rate limit burst (per minute)
   */
  public checkBurstRateLimit(userId: string, maxBurstPerMinute: number = 15): boolean {
    const now = Date.now();
    const windowStart = now - 60000; // 1 minute window

    let timestamps = this.burstRateLimiter.get(userId) || [];
    timestamps = timestamps.filter((t) => t > windowStart);

    if (timestamps.length >= maxBurstPerMinute) {
      this.burstRateLimiter.set(userId, timestamps);
      return false; // Exceeded limit
    }

    timestamps.push(now);
    this.burstRateLimiter.set(userId, timestamps);
    return true; // Allowed
  }

  /**
   * Verify if user can execute an AI request according to quotas
   */
  public async canExecuteAiRequest(
    userId: string,
    estimatedTokens: number = 100,
    voiceSeconds: number = 0
  ): Promise<{ allowed: boolean; reason?: string; currentRequests?: number; maxRequests?: number }> {
    const quota = await this.getQuotaForUser(userId);

    // 1. Check Burst Rate Limit
    if (!this.checkBurstRateLimit(userId, quota.maxBurstPerMinute)) {
      return {
        allowed: false,
        reason: 'Rate limit exceeded: Please wait a moment before sending more requests.',
      };
    }

    // 2. Check Voice duration per turn
    if (voiceSeconds > config.VOICE_MAX_SECONDS_PER_TURN) {
      return {
        allowed: false,
        reason: `Voice input exceeds maximum limit of ${config.VOICE_MAX_SECONDS_PER_TURN} seconds per turn.`,
      };
    }

    // 3. Check Daily DB Totals
    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const dailyUsage = await db.getTotalDailyAiTokens(userId, today);

    if (dailyUsage.totalRequests >= quota.maxDailyRequests) {
      return {
        allowed: false,
        reason: `Daily AI request quota reached (${dailyUsage.totalRequests}/${quota.maxDailyRequests}). Please upgrade or try again tomorrow.`,
        currentRequests: dailyUsage.totalRequests,
        maxRequests: quota.maxDailyRequests,
      };
    }

    if (dailyUsage.totalTokens + estimatedTokens > quota.maxDailyTokens) {
      return {
        allowed: false,
        reason: `Daily AI token limit reached (${dailyUsage.totalTokens}/${quota.maxDailyTokens}).`,
      };
    }

    if (dailyUsage.totalVoiceSeconds + voiceSeconds > quota.maxDailyVoiceSeconds) {
      return {
        allowed: false,
        reason: `Daily voice audio duration limit reached (${Math.round(dailyUsage.totalVoiceSeconds)}s/${quota.maxDailyVoiceSeconds}s).`,
      };
    }

    return { allowed: true, currentRequests: dailyUsage.totalRequests, maxRequests: quota.maxDailyRequests };
  }

  /**
   * Meter and record AI consumption without storing private user text
   */
  public async recordUsage(data: {
    userId: string;
    feature: string;
    modelUsed: string;
    inputTokens: number;
    outputTokens: number;
    voiceSeconds?: number;
    cachedResponsesCount?: number;
  }): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();

    await db.recordAiUsage({
      userId: data.userId,
      usageDate: today,
      feature: data.feature,
      modelUsed: data.modelUsed,
      inputTokens: data.inputTokens,
      outputTokens: data.outputTokens,
      voiceSeconds: data.voiceSeconds || 0,
      cachedResponsesCount: data.cachedResponsesCount || 0,
    });
  }

  /**
   * Get telemetry summary for current user
   */
  public async getDailyUsageSummary(userId: string): Promise<any> {
    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const totals = await db.getTotalDailyAiTokens(userId, today);
    const quota = await this.getQuotaForUser(userId);

    return {
      date: today,
      usage: totals,
      quota,
      remainingRequests: Math.max(0, quota.maxDailyRequests - totals.totalRequests),
      remainingTokens: Math.max(0, quota.maxDailyTokens - totals.totalTokens),
      remainingVoiceSeconds: Math.max(0, quota.maxDailyVoiceSeconds - totals.totalVoiceSeconds),
    };
  }
}

export const usageMeteringService = UsageMeteringService.getInstance();
