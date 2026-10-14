import { Router } from 'express';
import { PlanController } from '../controllers/plan_controller.js';
import { getDatabase } from '../db/index.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { PlanService } from '../services/plan_service.js';

export function createPlanRouter(controller?: PlanController): Router {
  const router = Router();
  const activeController = controller || new PlanController(new PlanService(getDatabase()));

  // 1. List available plans (can be accessed publicly or authenticated)
  router.get('/', activeController.listPlans);

  // 2. Plan details & 60-day roadmap
  router.get('/:planId', activeController.getPlanDetails);

  // 3. Daily path activities
  router.get('/:planId/days/:dayNumber', activeController.getDayActivities);

  // 4. Authenticated plan interactions
  router.use(authMiddleware);
  router.post('/:planId/enroll', activeController.enrollInPlan);
  router.post('/activities/:activityId/complete', activeController.completeActivity);

  return router;
}
