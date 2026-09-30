import { Router } from 'express';
import { AuthController } from '../controllers/auth_controller.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { placementRateLimiter } from '../middleware/rate_limiter.js';

export function createAuthRouter(controller = new AuthController()): Router {
  const router = Router();
  router.post('/register', placementRateLimiter, controller.register);
  router.post('/login', placementRateLimiter, controller.login);
  router.get('/session', authMiddleware, controller.session);
  router.post('/logout', authMiddleware, controller.logout);
  return router;
}
