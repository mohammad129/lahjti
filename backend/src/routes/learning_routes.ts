import { Router } from 'express';
import { LearningController } from '../controllers/learning_controller.js';
import { getDatabase } from '../db/index.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { LearningService } from '../services/learning_service.js';

export function createLearningRouter(
  controller?: LearningController
): Router {
  const router = Router();
  const activeController =
    controller || new LearningController(new LearningService(getDatabase()));

  // 1. Profile Endpoints
  router.get('/profile', authMiddleware, activeController.getProfile);
  router.put('/profile', authMiddleware, activeController.updateProfile);

  // 2. Progress Endpoints
  router.get('/progress', authMiddleware, activeController.getProgress);
  router.put('/progress', authMiddleware, activeController.updateProgress);

  // 3. Vocabulary Endpoints
  router.get('/vocabulary', authMiddleware, activeController.getVocabulary);
  router.post('/vocabulary/progress', authMiddleware, activeController.updateVocabularyProgress);

  // 4. Exams Endpoints
  router.get('/exams', authMiddleware, activeController.getExamResults);
  router.post('/exams/results', authMiddleware, activeController.saveExamResult);

  // 5. Activity & Summary Endpoints
  router.post('/activity', authMiddleware, activeController.recordActivity);
  router.get('/daily', authMiddleware, activeController.getDailySummary);
  router.get('/weekly', authMiddleware, activeController.getWeeklySummary);

  // 6. Production Dialect Reference & Client Cache
  router.get('/dialect-guide', activeController.getDialectGuide);

  return router;
}
