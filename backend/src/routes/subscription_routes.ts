import { Router } from 'express';
import { SubscriptionController } from '../controllers/subscription_controller.js';
import { getDatabase } from '../db/index.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { SubscriptionService } from '../services/subscription_service.js';

export function createSubscriptionRouter(controller?: SubscriptionController): Router {
  const router = Router();

  const ctrl =
    controller ||
    new SubscriptionController(new SubscriptionService(getDatabase()));

  // 1. Unauthenticated Webhook Callback Endpoint
  router.post('/webhook', ctrl.handleWebhook);

  // 2. Authenticated Endpoints
  router.use(authMiddleware);

  // Status, Entitlements and AI Usage Telemetry
  router.get('/status', ctrl.getStatus);
  router.get('/entitlements', ctrl.getEntitlements);
  router.post('/check-access', ctrl.checkAccess);
  router.get('/usage', ctrl.getUsageTelemetry);
  router.post('/trial/start', ctrl.startTrial);

  // Payment Gateway & Billing
  router.post('/checkout-session', ctrl.createCheckoutSession);
  router.post('/restore', ctrl.restorePurchases);
  router.post('/cancel', ctrl.cancelSubscription);
  router.post('/simulate-checkout', ctrl.simulateCheckout);

  return router;
}
