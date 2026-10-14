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
          maxDailyVoiceSeconds: config.DAILY_QUOTA_SCHOOL_STUDENT_VOICE_SECONDS, // 1 hour per day (3600 seconds)
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
          maxVoiceSeconds = config.DAILY_QUOTA_SCHOOL_STUDENT_VOICE_SECONDS; // 1 hour per day (3600 seconds)
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
   * Check if a given user is an active school student
   */
  public async isSchoolStudent(userId: string): Promise<boolean> {
    if (!userId || userId === 'anonymous') return false;
    const db = getDatabase();
    try {
      const membership = await db.getSchoolMembership(userId);
      if (membership && membership.role === 'student' && membership.status === 'active') {
        return true;
      }
      const sub = await db.getSubscription(userId);
      if (sub && sub.accountContext === 'school' && sub.role === 'student') {
        return true;
      }
      const profile = await db.getProfile(userId);
      if (profile && (profile.accountContext === 'school' || profile.role === 'student')) {
        return true;
      }
    } catch {
      // Non-fatal fallback
    }
    return false;
  }

  /**
   * Get real-time student tutor session status for today (4 sessions, 1 hour total)
   */
  public async getStudentSessionStatus(userId: string): Promise<{
    isSchoolStudent: boolean;
    maxDailySessions: number;
    completedSessionsCount: number;
    currentSessionNumber: number;
    remainingSessions: number;
    maxDailySeconds: number;
    totalSecondsUsedToday: number;
    remainingSecondsToday: number;
    activeSessionId: string | null;
    activeSessionDurationSeconds: number;
    canStartOrContinueSession: boolean;
    limitReason?: string;
  }> {
    const isStudent = await this.isSchoolStudent(userId);
    const maxDailySessions = config.DAILY_QUOTA_SCHOOL_STUDENT_MAX_SESSIONS || 4;
    const maxDailySeconds = config.DAILY_QUOTA_SCHOOL_STUDENT_VOICE_SECONDS || 3600;

    if (!isStudent) {
      return {
        isSchoolStudent: false,
        maxDailySessions,
        completedSessionsCount: 0,
        currentSessionNumber: 1,
        remainingSessions: maxDailySessions,
        maxDailySeconds,
        totalSecondsUsedToday: 0,
        remainingSecondsToday: maxDailySeconds,
        activeSessionId: null,
        activeSessionDurationSeconds: 0,
        canStartOrContinueSession: true,
      };
    }

    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const sessions = await db.getStudentDailyTutorSessions(userId, today);

    const completedSessions = sessions.filter((s) => s.status === 'completed');
    const activeSession = sessions.find((s) => s.status === 'active');

    const totalSecondsUsedToday = Math.round(
      sessions.reduce((sum, s) => sum + (Number(s.durationSeconds) || 0), 0)
    );
    const remainingSecondsToday = Math.max(0, maxDailySeconds - totalSecondsUsedToday);
    const completedSessionsCount = completedSessions.length;

    let currentSessionNumber = activeSession
      ? activeSession.sessionNumber
      : Math.min(maxDailySessions, completedSessionsCount + 1);

    const remainingSessions = Math.max(0, maxDailySessions - completedSessionsCount);

    let canStartOrContinueSession = true;
    let limitReason: string | undefined;

    if (remainingSecondsToday <= 0) {
      canStartOrContinueSession = false;
      limitReason =
        'أحسنت يا بطل! لقد استنفدت وقت المحادثة اليومي المخصص لك (ساعة كاملة). نراك غداً لمتابعة التعلّم!';
    } else if (completedSessionsCount >= maxDailySessions && !activeSession) {
      canStartOrContinueSession = false;
      limitReason =
        'أحسنت يا بطل! أنهيت جلساتك الـ 4 لهذا اليوم. خذ استراحة ممتعة ونلتقي غداً في جلسات جديدة!';
    }

    return {
      isSchoolStudent: true,
      maxDailySessions,
      completedSessionsCount,
      currentSessionNumber,
      remainingSessions,
      maxDailySeconds,
      totalSecondsUsedToday,
      remainingSecondsToday,
      activeSessionId: activeSession?.id ?? null,
      activeSessionDurationSeconds: Math.round(activeSession?.durationSeconds || 0),
      canStartOrContinueSession,
      limitReason,
    };
  }

  /**
   * Explicitly starts a new session for a school student (within the 4 daily sessions limit)
   */
  public async startStudentSession(userId: string): Promise<any> {
    const isStudent = await this.isSchoolStudent(userId);
    if (!isStudent) {
      return { isSchoolStudent: false };
    }

    const status = await this.getStudentSessionStatus(userId);
    if (!status.canStartOrContinueSession) {
      throw new Error(status.limitReason || 'Daily AI session limit reached.');
    }

    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const sessions = await db.getStudentDailyTutorSessions(userId, today);
    const activeSession = sessions.find((s) => s.status === 'active');

    if (activeSession) {
      return {
        session: activeSession,
        status,
      };
    }

    const nextSessionNumber = status.completedSessionsCount + 1;
    const newSession = await db.saveStudentTutorSession({
      id: `sess_${userId}_${today}_${nextSessionNumber}`,
      studentId: userId,
      sessionDate: today,
      sessionNumber: nextSessionNumber,
      durationSeconds: 0,
      turnsCount: 0,
      status: 'active',
      startedAt: new Date(),
    });

    const updatedStatus = await this.getStudentSessionStatus(userId);
    return {
      session: newSession,
      status: updatedStatus,
    };
  }

  /**
   * Records elapsed turn duration into the student's active daily session
   */
  public async recordStudentTurn(
    userId: string,
    durationSeconds: number = 10,
    sessionId?: string
  ): Promise<void> {
    const isStudent = await this.isSchoolStudent(userId);
    if (!isStudent) return;

    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const sessions = await db.getStudentDailyTutorSessions(userId, today);

    let targetSession = sessionId
      ? sessions.find((s) => s.id === sessionId)
      : sessions.find((s) => s.status === 'active');

    if (!targetSession) {
      const completedCount = sessions.filter((s) => s.status === 'completed').length;
      if (completedCount >= (config.DAILY_QUOTA_SCHOOL_STUDENT_MAX_SESSIONS || 4)) {
        return; // Already capped
      }
      const nextNum = completedCount + 1;
      targetSession = await db.saveStudentTutorSession({
        id: `sess_${userId}_${today}_${nextNum}`,
        studentId: userId,
        sessionDate: today,
        sessionNumber: nextNum,
        durationSeconds: 0,
        turnsCount: 0,
        status: 'active',
        startedAt: new Date(),
      });
    }

    const newDuration = Math.round(
      (Number(targetSession.durationSeconds) || 0) + Math.max(durationSeconds, 5)
    );
    const newTurns = (targetSession.turnsCount || 0) + 1;

    // Check if total daily voice seconds reached max limit (1 hour = 3600 seconds)
    const otherSessionsTotal = sessions
      .filter((s) => s.id !== targetSession.id)
      .reduce((sum, s) => sum + (Number(s.durationSeconds) || 0), 0);
    const isCumulativeDailyHourExceeded =
      otherSessionsTotal + newDuration >= (config.DAILY_QUOTA_SCHOOL_STUDENT_VOICE_SECONDS || 3600);

    await db.updateStudentTutorSession(targetSession.id, {
      durationSeconds: newDuration,
      turnsCount: newTurns,
      status: isCumulativeDailyHourExceeded ? 'completed' : targetSession.status,
      endedAt: isCumulativeDailyHourExceeded ? new Date() : targetSession.endedAt,
    });
  }

  /**
   * Explicitly concludes an active session for a student, advancing to next session slot
   */
  public async endStudentSession(
    userId: string,
    sessionId?: string
  ): Promise<{ session: any; status: any }> {
    const isStudent = await this.isSchoolStudent(userId);
    if (!isStudent) {
      return { session: null, status: await this.getStudentSessionStatus(userId) };
    }

    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const sessions = await db.getStudentDailyTutorSessions(userId, today);

    const targetSession = sessionId
      ? sessions.find((s) => s.id === sessionId)
      : sessions.find((s) => s.status === 'active');

    if (targetSession && targetSession.status === 'active') {
      await db.updateStudentTutorSession(targetSession.id, {
        status: 'completed',
        endedAt: new Date(),
      });
    }

    const updatedStatus = await this.getStudentSessionStatus(userId);
    return {
      session: targetSession,
      status: updatedStatus,
    };
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

  /**
   * Detailed AI Cost Breakdown in USD according to Requirement 16
   */
  public async getCostBreakdown(userId: string): Promise<any> {
    const today = new Date().toISOString().split('T')[0];
    const db = getDatabase();
    const records = await db.getDailyAiUsage(userId, today);

    // Pricing rates per unit in USD
    const INPUT_TOKEN_COST = 0.0000005; // $0.50 per 1M
    const OUTPUT_TOKEN_COST = 0.0000015; // $1.50 per 1M
    const VOICE_SECOND_COST = 0.00002; // $0.02 per 1000s

    let totalCostUsd = 0;
    let savedCostUsd = 0;

    const featureBreakdown = records.map((r) => {
      const inputCost = (r.inputTokens || 0) * INPUT_TOKEN_COST;
      const outputCost = (r.outputTokens || 0) * OUTPUT_TOKEN_COST;
      const voiceCost = (r.voiceSeconds || 0) * VOICE_SECOND_COST;
      const featureCost = inputCost + outputCost + voiceCost;

      totalCostUsd += featureCost;

      // Calculate cost saved by cached / deterministic database hits
      const saved = (r.cachedResponsesCount || 0) * (200 * INPUT_TOKEN_COST + 120 * OUTPUT_TOKEN_COST);
      savedCostUsd += saved;

      return {
        feature: r.feature,
        modelUsed: r.modelUsed,
        requestsCount: r.requestCount,
        inputTokens: r.inputTokens,
        outputTokens: r.outputTokens,
        voiceSeconds: r.voiceSeconds,
        cachedResponsesCount: r.cachedResponsesCount,
        costUsd: Math.round(featureCost * 10000) / 10000,
      };
    });

    return {
      userId,
      date: today,
      totalCostUsd: Math.round(totalCostUsd * 10000) / 10000,
      savedCostUsd: Math.round(savedCostUsd * 10000) / 10000,
      currency: 'USD',
      features: featureBreakdown,
      projectedMonthlyCostUsd: Math.round(totalCostUsd * 30 * 100) / 100,
    };
  }
}

export const usageMeteringService = UsageMeteringService.getInstance();
