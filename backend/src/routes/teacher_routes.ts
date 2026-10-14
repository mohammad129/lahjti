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

  // 4. Teacher AI English Tutor Oversight Dashboard (4 Daily Sessions & Fluency)
  router.get('/tutor-oversight', authMiddleware, activeController.getTutorOversight);

  // 5. Teacher Exams Management (8 Question Types, Instant Grading & Analytics)
  router.get('/exams', authMiddleware, activeController.listExams);
  router.post('/exams', authMiddleware, activeController.createExam);
  router.get('/exams/:examId', authMiddleware, activeController.getExamDetails);
  router.get('/exams/:examId/analytics', authMiddleware, activeController.getExamAnalytics);

  // 6. Educational Games Management
  router.get('/games', authMiddleware, activeController.listGames);
  router.post('/games', authMiddleware, activeController.createGame);

  return router;
}

