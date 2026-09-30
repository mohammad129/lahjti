import { Router } from 'express';
import { AdminController } from '../controllers/admin_controller.js';
import { adminRateLimiter } from '../middleware/rate_limiter.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { requireAdmin } from '../middleware/admin_middleware.js';

export function createAdminRouter(controller: AdminController = new AdminController()): Router {
  const router = Router();
  router.use(authMiddleware, requireAdmin, adminRateLimiter);
  router.get('/overview', controller.overview);
  for (const kind of ['lessons', 'vocabulary'] as const) {
    router.get(`/${kind}`, controller.listContent(kind));
    router.post(`/${kind}`, controller.createContent(kind));
    router.put(`/${kind}/:id`, controller.updateContent(kind));
    router.delete(`/${kind}/:id`, controller.deleteContent(kind));
  }
  return router;
}
