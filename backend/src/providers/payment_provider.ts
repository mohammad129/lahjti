import crypto from 'crypto';

export interface PaymentCheckoutSession {
  sessionId: string;
  checkoutUrl: string;
  planId: string;
  priceUsd: number;
  userId: string;
  expiresAt: Date;
}

export type WebhookEventType =
  | 'checkout.completed'
  | 'invoice.payment_succeeded'
  | 'invoice.payment_failed'
  | 'customer.subscription.deleted'
  | 'customer.subscription.updated';

export interface PaymentWebhookEvent {
  id: string;
  type: WebhookEventType;
  userId: string;
  planId: string;
  periodDays: number;
  status: string;
  timestamp: Date;
  rawPayload?: any;
}

export interface IPaymentGatewayProvider {
  readonly name: string;
  createCheckoutSession(
    userId: string,
    planId: string,
    options?: { successUrl?: string; cancelUrl?: string }
  ): Promise<PaymentCheckoutSession>;
  verifyWebhook(payload: any, signature?: string): Promise<PaymentWebhookEvent>;
  restorePurchases(
    userId: string,
    platformReceipt?: string
  ): Promise<{ restored: boolean; planId?: string; expiresAt?: Date }>;
}

/**
 * Sandbox & Test Payment Provider
 * Provides PCI-DSS compliant sandbox checkout session generation, deterministic webhook parsing,
 * and receipt reconciliation without storing raw credit card details or charging real cards.
 */
export class SandboxPaymentProvider implements IPaymentGatewayProvider {
  readonly name = 'sandbox_gateway';

  async createCheckoutSession(
    userId: string,
    planId: string = 'individual_monthly',
    options?: { successUrl?: string; cancelUrl?: string }
  ): Promise<PaymentCheckoutSession> {
    const sessionId = `cs_test_${crypto.randomBytes(12).toString('hex')}`;
    const priceUsd = planId === 'individual_monthly' ? 10.0 : (planId === 'individual_yearly' ? 99.0 : 10.0);
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes validity

    const success = options?.successUrl || 'https://lahjti.com/billing/success';
    const checkoutUrl = `https://checkout.lahjti.com/pay/${sessionId}?user=${userId}&plan=${planId}&return=${encodeURIComponent(
      success
    )}`;

    return {
      sessionId,
      checkoutUrl,
      planId,
      priceUsd,
      userId,
      expiresAt,
    };
  }

  async verifyWebhook(payload: any, _signature?: string): Promise<PaymentWebhookEvent> {
    if (!payload || !payload.type || !payload.userId) {
      throw new Error('Invalid payment webhook payload: missing type or userId');
    }

    return {
      id: payload.id || `evt_${crypto.randomBytes(8).toString('hex')}`,
      type: payload.type as WebhookEventType,
      userId: payload.userId,
      planId: payload.planId || 'individual_monthly',
      periodDays: payload.periodDays || 30,
      status: payload.status || 'active',
      timestamp: payload.timestamp ? new Date(payload.timestamp) : new Date(),
      rawPayload: payload,
    };
  }

  async restorePurchases(
    userId: string,
    platformReceipt?: string
  ): Promise<{ restored: boolean; planId?: string; expiresAt?: Date }> {
    if (platformReceipt && platformReceipt.includes('expired')) {
      return { restored: false };
    }

    // Default sandbox restore grants valid monthly access
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    return {
      restored: true,
      planId: 'individual_monthly',
      expiresAt,
    };
  }
}
