import { ILearningDb, getDatabase } from '../db/index.js';
import { ForbiddenError, NotFoundError } from '../errors/api_error.js';
import {
  IPaymentGatewayProvider,
  PaymentCheckoutSession,
  PaymentWebhookEvent,
  SandboxPaymentProvider,
} from '../providers/payment_provider.js';

export interface SubscriptionDTO {
  userId: string;
  accountContext: 'individual' | 'school';
  role: 'individual' | 'student' | 'teacher';
  status: 'trial' | 'active' | 'expired' | 'cancelled' | 'paymentPending' | 'schoolAccess' | 'pastDue' | 'suspended';
  planId: string;
  priceUsd: number;
  trialStartsAt: string | null;
  trialEndsAt: string | null;
  trialDurationDays: number;
  currentPeriodStart: string | null;
  currentPeriodEnd: string | null;
  subscriptionExpiresAt: string | null;
  cancelledAt: string | null;
  schoolId: string | null;
  schoolCode: string | null;
  isValidAccess: boolean;
  isTrialActive: boolean;
  daysRemaining: number;
}

export interface EntitlementsDTO {
  isValidAccess: boolean;
  isTrialActive: boolean;
  status: string;
  accountContext: string;
  role: string;
  features: {
    aiTutor: boolean;
    voiceConversation: boolean;
    lessons: boolean;
    vocabulary: boolean;
    exams: boolean;
    games: boolean;
    progress: boolean;
    schoolDailyTasks: boolean;
    schoolClassrooms: boolean;
    teacherDashboard: boolean;
  };
  subscription: SubscriptionDTO;
}

export class SubscriptionService {
  private paymentProvider: IPaymentGatewayProvider;

  constructor(
    private db: ILearningDb,
    customPaymentProvider?: IPaymentGatewayProvider
  ) {
    this.paymentProvider = customPaymentProvider ?? new SandboxPaymentProvider();
  }

  public setPaymentProvider(provider: IPaymentGatewayProvider): void {
    this.paymentProvider = provider;
  }

  /**
   * Evaluates if current subscription record has valid access rights.
   */
  private evaluateAccess(sub: any): { isValidAccess: boolean; isTrialActive: boolean; daysRemaining: number } {
    const now = new Date();
    const status = sub.status;

    if (status === 'suspended' || status === 'expired' || status === 'pastDue') {
      return { isValidAccess: false, isTrialActive: false, daysRemaining: 0 };
    }

    if (status === 'schoolAccess') {
      return { isValidAccess: true, isTrialActive: false, daysRemaining: 365 };
    }

    if (status === 'active') {
      const expiry = sub.currentPeriodEnd ? new Date(sub.currentPeriodEnd) : (sub.subscriptionExpiresAt ? new Date(sub.subscriptionExpiresAt) : null);
      if (expiry) {
        const isValid = now.getTime() < expiry.getTime();
        const diffDays = Math.max(0, Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
        return { isValidAccess: isValid, isTrialActive: false, daysRemaining: diffDays };
      }
      return { isValidAccess: true, isTrialActive: false, daysRemaining: 30 };
    }

    if (status === 'cancelled') {
      const expiry = sub.currentPeriodEnd ? new Date(sub.currentPeriodEnd) : (sub.subscriptionExpiresAt ? new Date(sub.subscriptionExpiresAt) : null);
      if (expiry) {
        const isValid = now.getTime() < expiry.getTime();
        const diffDays = Math.max(0, Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
        return { isValidAccess: isValid, isTrialActive: false, daysRemaining: diffDays };
      }
      return { isValidAccess: false, isTrialActive: false, daysRemaining: 0 };
    }

    if (status === 'trial') {
      const trialEnds = sub.trialEndsAt ? new Date(sub.trialEndsAt) : null;
      if (trialEnds) {
        const isValid = now.getTime() < trialEnds.getTime();
        const diffDays = Math.max(0, Math.ceil((trialEnds.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
        return { isValidAccess: isValid, isTrialActive: isValid, daysRemaining: diffDays };
      }
      return { isValidAccess: true, isTrialActive: true, daysRemaining: sub.trialDurationDays || 3 };
    }

    return { isValidAccess: false, isTrialActive: false, daysRemaining: 0 };
  }

  private mapToDTO(sub: any): SubscriptionDTO {
    const { isValidAccess, isTrialActive, daysRemaining } = this.evaluateAccess(sub);

    return {
      userId: sub.userId,
      accountContext: sub.accountContext || 'individual',
      role: sub.role || 'individual',
      status: sub.status,
      planId: sub.planId || (sub.accountContext === 'school' ? 'school_license' : 'individual_monthly'),
      priceUsd: sub.priceUsd !== undefined ? sub.priceUsd : (sub.accountContext === 'school' ? 0.0 : 10.0),
      trialStartsAt: sub.trialStartsAt ? new Date(sub.trialStartsAt).toISOString() : null,
      trialEndsAt: sub.trialEndsAt ? new Date(sub.trialEndsAt).toISOString() : null,
      trialDurationDays: sub.trialDurationDays || (sub.accountContext === 'school' ? 10 : 3),
      currentPeriodStart: sub.currentPeriodStart ? new Date(sub.currentPeriodStart).toISOString() : null,
      currentPeriodEnd: sub.currentPeriodEnd ? new Date(sub.currentPeriodEnd).toISOString() : null,
      subscriptionExpiresAt: sub.subscriptionExpiresAt ? new Date(sub.subscriptionExpiresAt).toISOString() : null,
      cancelledAt: sub.cancelledAt ? new Date(sub.cancelledAt).toISOString() : null,
      schoolId: sub.schoolId || null,
      schoolCode: sub.schoolCode || null,
      isValidAccess,
      isTrialActive,
      daysRemaining,
    };
  }

  /**
   * Retrieves or initializes authoritative subscription for user.
   */
  async getSubscriptionStatus(
    userId: string,
    accountContext: 'individual' | 'school' = 'individual',
    role: 'individual' | 'student' | 'teacher' = 'individual',
    schoolCode?: string
  ): Promise<SubscriptionDTO> {
    let sub = await this.db.getSubscription(userId);

    // Check school membership for teachers
    const membership = await this.db.getSchoolMembership(userId);
    if (membership && membership.role === 'teacher' && membership.status === 'active') {
      const school = await this.db.getSchool(membership.schoolId);
      const record = {
        userId,
        accountContext: 'school',
        role: 'teacher',
        status: 'schoolAccess',
        planId: 'school_license',
        priceUsd: 0.0,
        trialDurationDays: 0,
        schoolId: membership.schoolId,
        schoolCode: school?.schoolCode || schoolCode || null,
      };
      const saved = await this.db.upsertSubscription(record);
      return this.mapToDTO(saved);
    }

    if (!sub) {
      // Auto-start default trial on first query
      return this.startTrial(userId, accountContext, role, schoolCode);
    }

    // Check if trial has elapsed and update status to expired if needed
    const { isValidAccess } = this.evaluateAccess(sub);
    if (!isValidAccess && sub.status === 'trial') {
      const updated = await this.db.upsertSubscription({
        ...sub,
        status: 'expired',
      });
      return this.mapToDTO(updated);
    }

    return this.mapToDTO(sub);
  }

  /**
   * Starts trial explicitly (3 days for Individual, 10 days for School Student).
   * Persisted server-side: Existing trial will NOT be reset.
   */
  async startTrial(
    userId: string,
    accountContext: 'individual' | 'school' = 'individual',
    role: 'individual' | 'student' | 'teacher' = 'individual',
    schoolCode?: string
  ): Promise<SubscriptionDTO> {
    const existing = await this.db.getSubscription(userId);
    if (existing) {
      return this.mapToDTO(existing);
    }

    const now = new Date();
    const trialDays = accountContext === 'school' && role === 'student' ? 10 : 3;
    const trialEnds = new Date(now.getTime() + trialDays * 24 * 60 * 60 * 1000);

    let schoolId: string | null = null;
    if (schoolCode) {
      const school = await this.db.getSchoolByCode(schoolCode);
      if (school) schoolId = school.id;
    }

    const record = {
      userId,
      accountContext,
      role,
      status: 'trial',
      planId: accountContext === 'school' ? 'school_student_trial' : 'individual_monthly',
      priceUsd: accountContext === 'school' ? 0.0 : 10.0,
      trialStartsAt: now,
      trialEndsAt: trialEnds,
      trialDurationDays: trialDays,
      schoolId,
      schoolCode: schoolCode || null,
    };

    const saved = await this.db.upsertSubscription(record);
    return this.mapToDTO(saved);
  }

  /**
   * Creates a tokenized checkout session through the decoupled payment provider.
   */
  async createCheckoutSession(
    userId: string,
    planId: string = 'individual_monthly',
    options?: { successUrl?: string; cancelUrl?: string }
  ): Promise<PaymentCheckoutSession> {
    return await this.paymentProvider.createCheckoutSession(userId, planId, options);
  }

  /**
   * Processes server-to-server webhook events from payment gateway.
   */
  async handleWebhook(payload: any, signature?: string): Promise<{ processed: boolean; event: PaymentWebhookEvent; subscription: SubscriptionDTO }> {
    const event = await this.paymentProvider.verifyWebhook(payload, signature);
    const existing = await this.db.getSubscription(event.userId);
    const now = new Date();

    let newStatus = existing?.status || 'trial';
    let currentPeriodStart = existing?.currentPeriodStart || now;
    let currentPeriodEnd = existing?.currentPeriodEnd || new Date(now.getTime() + event.periodDays * 24 * 60 * 60 * 1000);
    let subscriptionExpiresAt = currentPeriodEnd;

    switch (event.type) {
      case 'checkout.completed':
      case 'invoice.payment_succeeded':
        newStatus = 'active';
        currentPeriodStart = now;
        currentPeriodEnd = new Date(now.getTime() + event.periodDays * 24 * 60 * 60 * 1000);
        subscriptionExpiresAt = currentPeriodEnd;
        break;
      case 'invoice.payment_failed':
        newStatus = 'pastDue';
        break;
      case 'customer.subscription.deleted':
        newStatus = 'expired';
        break;
    }

    const record = {
      ...(existing || {}),
      userId: event.userId,
      accountContext: 'individual',
      role: 'individual',
      status: newStatus,
      planId: event.planId,
      priceUsd: 10.0,
      currentPeriodStart,
      currentPeriodEnd,
      subscriptionExpiresAt,
      cancelledAt: event.type === 'customer.subscription.deleted' ? now : existing?.cancelledAt || null,
    };

    const saved = await this.db.upsertSubscription(record);
    return {
      processed: true,
      event,
      subscription: this.mapToDTO(saved),
    };
  }

  /**
   * Simulates checkout / subscription upgrade to $10/month plan without real credit card processing.
   */
  async simulateCheckout(
    userId: string,
    planId: string = 'individual_monthly',
    periodDays: number = 30,
    simulatePending: boolean = false
  ): Promise<SubscriptionDTO> {
    const existing = await this.db.getSubscription(userId);
    const now = new Date();
    const periodEnd = new Date(now.getTime() + periodDays * 24 * 60 * 60 * 1000);

    const status = simulatePending ? 'paymentPending' : 'active';

    const record = {
      ...(existing || {}),
      userId,
      accountContext: 'individual',
      role: 'individual',
      status,
      planId,
      priceUsd: 10.0,
      currentPeriodStart: now,
      currentPeriodEnd: periodEnd,
      subscriptionExpiresAt: periodEnd,
      cancelledAt: null,
    };

    const saved = await this.db.upsertSubscription(record);
    return this.mapToDTO(saved);
  }

  /**
   * Cancels active subscription. Remains valid until current period end.
   */
  async cancelSubscription(userId: string): Promise<SubscriptionDTO> {
    const existing = await this.db.getSubscription(userId);
    if (!existing) {
      throw new NotFoundError('Subscription record not found');
    }

    const now = new Date();
    const record = {
      ...existing,
      status: 'cancelled',
      cancelledAt: now,
    };

    const saved = await this.db.upsertSubscription(record);
    return this.mapToDTO(saved);
  }

  /**
   * Restores purchases / authoritative subscription from server & store receipt verification.
   */
  async restorePurchases(userId: string, platformReceipt?: string): Promise<SubscriptionDTO> {
    const providerResult = await this.paymentProvider.restorePurchases(userId, platformReceipt);

    if (providerResult.restored && providerResult.expiresAt) {
      const existing = await this.db.getSubscription(userId);
      const now = new Date();
      const record = {
        ...(existing || {}),
        userId,
        accountContext: 'individual',
        role: 'individual',
        status: 'active',
        planId: providerResult.planId || 'individual_monthly',
        priceUsd: 10.0,
        currentPeriodStart: now,
        currentPeriodEnd: providerResult.expiresAt,
        subscriptionExpiresAt: providerResult.expiresAt,
      };
      const saved = await this.db.upsertSubscription(record);
      return this.mapToDTO(saved);
    }

    const sub = await this.db.getSubscription(userId);
    if (!sub) {
      return this.startTrial(userId, 'individual', 'individual');
    }
    return this.mapToDTO(sub);
  }

  /**
   * Computes complete, granular feature entitlements for user.
   */
  async getEntitlements(userId: string): Promise<EntitlementsDTO> {
    const subDTO = await this.getSubscriptionStatus(userId);
    const isValid = subDTO.isValidAccess;
    const isTeacher = subDTO.role === 'teacher' && subDTO.status === 'schoolAccess';
    const isSchoolStudent = subDTO.accountContext === 'school' && subDTO.role === 'student' && isValid;

    return {
      isValidAccess: isValid,
      isTrialActive: subDTO.isTrialActive,
      status: subDTO.status,
      accountContext: subDTO.accountContext,
      role: subDTO.role,
      features: {
        aiTutor: isValid,
        voiceConversation: isValid,
        lessons: isValid,
        vocabulary: isValid,
        exams: isValid,
        games: isValid,
        progress: isValid,
        schoolDailyTasks: isSchoolStudent,
        schoolClassrooms: isTeacher,
        teacherDashboard: isTeacher,
      },
      subscription: subDTO,
    };
  }

  /**
   * Evaluates feature access according to strict multi-tenant access policy.
   */
  async checkFeatureAccess(
    userId: string,
    feature: string
  ): Promise<{ isAllowed: boolean; reason?: string; requiredAction?: string; subscription: SubscriptionDTO }> {
    const entitlements = await this.getEntitlements(userId);
    const subDTO = entitlements.subscription;

    // 1. Teacher Dashboard & Classroom Oversight
    if (feature === 'teacherDashboard' || feature === 'schoolClassrooms') {
      if (entitlements.features.teacherDashboard) {
        return { isAllowed: true, subscription: subDTO };
      }
      return {
        isAllowed: false,
        reason: 'Teacher role and valid school membership required',
        requiredAction: '/welcome',
        subscription: subDTO,
      };
    }

    // 2. School Daily Tasks
    if (feature === 'schoolDailyTasks') {
      if (entitlements.features.schoolDailyTasks) {
        return { isAllowed: true, subscription: subDTO };
      }
      return {
        isAllowed: false,
        reason: subDTO.accountContext === 'school'
          ? 'School student trial expired or license inactive'
          : 'Feature available for school student accounts only',
        requiredAction: subDTO.accountContext === 'school' ? '/school/verify-code' : '/welcome',
        subscription: subDTO,
      };
    }

    // 3. Core Learning Features (aiTutor, voiceConversation, lessons, vocabulary, exams, games, progress)
    if (subDTO.isValidAccess) {
      return { isAllowed: true, subscription: subDTO };
    }

    // Restricted due to expired trial or pending payment
    if (subDTO.accountContext === 'school') {
      return {
        isAllowed: false,
        reason: 'School student 10-day trial elapsed. Valid school license required.',
        requiredAction: '/school/verify-code',
        subscription: subDTO,
      };
    }

    return {
      isAllowed: false,
      reason: 'Individual 3-day trial elapsed. $10 / month active subscription required.',
      requiredAction: '/subscription/access',
      subscription: subDTO,
    };
  }
}
