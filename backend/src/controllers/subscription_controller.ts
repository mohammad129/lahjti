import { NextFunction, Request, Response } from 'express';
import {
  checkAccessSchema,
  createCheckoutSessionSchema,
  restorePurchasesSchema,
  simulateCheckoutSchema,
  startTrialSchema,
  webhookPayloadSchema,
} from '../schemas/subscription_schemas.js';
import { SubscriptionService } from '../services/subscription_service.js';
import { usageMeteringService } from '../services/usage_metering_service.js';

export class SubscriptionController {
  constructor(private subscriptionService: SubscriptionService) {}

  getStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const context = (req.query.context as any) || 'individual';
      const role = (req.query.role as any) || 'individual';
      const schoolCode = req.query.schoolCode as string | undefined;

      const result = await this.subscriptionService.getSubscriptionStatus(
        userId,
        context,
        role,
        schoolCode
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  startTrial = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const parsed = startTrialSchema.parse(req.body);

      const result = await this.subscriptionService.startTrial(
        userId,
        parsed.accountContext,
        parsed.role as 'student' | 'individual' | 'teacher' | undefined,
        parsed.schoolCode
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  createCheckoutSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const parsed = createCheckoutSessionSchema.parse(req.body || {});

      const session = await this.subscriptionService.createCheckoutSession(
        userId,
        parsed.planId,
        {
          successUrl: parsed.successUrl,
          cancelUrl: parsed.cancelUrl,
        }
      );

      res.status(200).json({
        success: true,
        data: session,
      });
    } catch (err) {
      next(err);
    }
  };

  handleWebhook = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = webhookPayloadSchema.parse(req.body);
      const signature = req.headers['stripe-signature'] as string | undefined;

      const result = await this.subscriptionService.handleWebhook(parsed, signature);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  restorePurchases = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const parsed = restorePurchasesSchema.parse(req.body || {});

      const result = await this.subscriptionService.restorePurchases(
        userId,
        parsed.platformReceipt
      );

      res.status(200).json({
        success: true,
        data: result,
        message: 'Purchases synchronized and restored successfully',
      });
    } catch (err) {
      next(err);
    }
  };

  getEntitlements = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const entitlements = await this.subscriptionService.getEntitlements(userId);

      res.status(200).json({
        success: true,
        data: entitlements,
      });
    } catch (err) {
      next(err);
    }
  };

  simulateCheckout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const parsed = simulateCheckoutSchema.parse(req.body);

      const result = await this.subscriptionService.simulateCheckout(
        userId,
        parsed.planId,
        parsed.periodDays,
        parsed.simulatePending
      );

      res.status(200).json({
        success: true,
        data: result,
        message: 'Mock subscription upgrade successful (Demo mode - no card charged)',
      });
    } catch (err) {
      next(err);
    }
  };

  cancelSubscription = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const result = await this.subscriptionService.cancelSubscription(userId);

      res.status(200).json({
        success: true,
        data: result,
        message: 'Subscription cancelled. Access remains valid until current period end.',
      });
    } catch (err) {
      next(err);
    }
  };

  checkAccess = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const feature = (req.query.feature as any) || req.body?.feature;
      const parsed = checkAccessSchema.parse({ feature });

      const result = await this.subscriptionService.checkFeatureAccess(
        userId,
        parsed.feature
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  getUsageTelemetry = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.userId || 'usr_anonymous';
      const summary = await usageMeteringService.getDailyUsageSummary(userId);
      res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (err) {
      next(err);
    }
  };
}
