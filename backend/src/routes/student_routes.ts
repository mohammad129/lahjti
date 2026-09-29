import { Router } from 'express';
import { StudentController } from '../controllers/student_controller.js';
import { getDatabase } from '../db/index.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { SchoolService } from '../services/school_service.js';

export function createStudentRouter(controller?: StudentController): Router {
  const router = Router();
  const activeController = controller || new StudentController(new SchoolService(getDatabase()));

  // 1. Student Home
  router.get('/home', authMiddleware, activeController.getHome);

  // 2. Daily Tasks
  router.get('/tasks', authMiddleware, activeController.getTasks);
  router.post('/tasks/:taskId/complete', authMiddleware, activeController.completeTask);

  // 3. Mini-Games / Activity Results
  router.post('/games/result', authMiddleware, activeController.submitGameResult);

  // 4. Student Educational Progress
  router.get('/progress', authMiddleware, activeController.getProgress);

  // 5. School Enrollment / Joining
  router.post('/join', authMiddleware, activeController.joinSchool);

  return router;
}
