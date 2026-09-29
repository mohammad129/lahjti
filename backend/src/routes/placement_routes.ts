import { Router } from 'express';
import { PlacementController } from '../controllers/placement_controller.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { placementRateLimiter } from '../middleware/rate_limiter.js';

export function createPlacementRouter(
  controller: PlacementController = new PlacementController()
): Router {
  const router = Router();

  router.post(
    '/evaluate',
    authMiddleware,
    placementRateLimiter,
    controller.evaluateAnswer
  );

  return router;
}
