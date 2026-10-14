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

  router.get(
    '/student-session/status',
    authMiddleware,
    controller.getStudentSessionStatus
  );

  router.post(
    '/student-session/start',
    authMiddleware,
    tutorRateLimiter,
    controller.startStudentSession
  );

  router.post(
    '/student-session/end',
    authMiddleware,
    tutorRateLimiter,
    controller.endStudentSession
  );

  return router;
}
