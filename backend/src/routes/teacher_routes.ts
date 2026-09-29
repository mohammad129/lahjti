import { Router } from 'express';
import { TeacherController } from '../controllers/teacher_controller.js';
import { getDatabase } from '../db/index.js';
import { authMiddleware } from '../middleware/auth_middleware.js';
import { SchoolService } from '../services/school_service.js';

export function createTeacherRouter(controller?: TeacherController): Router {
  const router = Router();
  const activeController = controller || new TeacherController(new SchoolService(getDatabase()));

  // 1. Teacher Home / Dashboard Overview
  router.get('/home', authMiddleware, activeController.getHome);

  // 2. Teacher Class Roster & Student Performance
  router.get('/classes/:classId', authMiddleware, activeController.getClassDetail);

  // 3. Teacher Student Educational Metrics (Privacy-Bounded)
  router.get('/students/:studentId', authMiddleware, activeController.getStudentDetail);

  return router;
}
