import { Router } from 'express';
import { TutorController } from '../controllers/tutor_controller.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { tutorRateLimiter } from '../middleware/rate_limiter.js';

export function createTutorRouter(
  controller: TutorController = new TutorController()
): Router {
  const router = Router();

  router.post(
    '/conversation',
    authMiddleware,
    tutorRateLimiter,
    controller.converse
  );

  router.post(
    '/synthesize',
    authMiddleware,
    tutorRateLimiter,
    controller.synthesize
  );

  return router;
}
