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

  // 6. Student Exams (Submit answers & auto-grade)
  router.post('/exams/:examId/submit', authMiddleware, activeController.submitExam);

  // 7. Student Spaced Repetition Mistakes Review
  router.get('/mistakes/reviews', authMiddleware, activeController.getMistakeReviews);
  router.post('/mistakes/:contentId/attempt', authMiddleware, activeController.attemptMistakeReview);

  // 8. Points Transactions Audit Ledger
  router.get('/points/history', authMiddleware, activeController.getPointsHistory);

  // 9. Educational Game Play
  router.post('/games/:gameId/play', authMiddleware, activeController.playGame);

  return router;
}
