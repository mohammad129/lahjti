import cors from 'cors';
import express, { Express } from 'express';
import { LearningController } from './controllers/learning_controller.js';
import { PlacementController } from './controllers/placement_controller.js';
import { StudentController } from './controllers/student_controller.js';
import { TeacherController } from './controllers/teacher_controller.js';
import { TutorController } from './controllers/tutor_controller.js';
import { SubscriptionController } from './controllers/subscription_controller.js';
import { config } from './config/env.js';
import { errorHandler } from './middleware/error_handler.js';
import { requestMonitoringMiddleware } from './middleware/monitoring_middleware.js';
import { monitoringService } from './services/monitoring_service.js';
import { createLearningRouter } from './routes/learning_routes.js';
import { createPlacementRouter } from './routes/placement_routes.js';
import { createStudentRouter } from './routes/student_routes.js';
import { createSubscriptionRouter } from './routes/subscription_routes.js';
import { createTeacherRouter } from './routes/teacher_routes.js';
import { createTutorRouter } from './routes/tutor_routes.js';
import { createAdminRouter } from './routes/admin_routes.js';
import { createAuthRouter } from './routes/auth_routes.js';

export function createApp(
  placementController?: PlacementController,
  tutorController?: TutorController,
  learningController?: LearningController,
  studentController?: StudentController,
  teacherController?: TeacherController,
  subscriptionController?: SubscriptionController
): Express {
  const app = express();

  // 1. Core Middlewares
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  app.use(requestMonitoringMiddleware);

  // 2. Health & Monitoring Check Endpoints
  const healthCheck = (_req: express.Request, res: express.Response) => {
    res.status(200).json({
      status: 'ok',
      service: 'lahjti-backend',
      environment: config.NODE_ENV,
      timestamp: new Date().toISOString(),
      database: {
        type: config.DATABASE_URL ? 'postgresql' : 'in_memory',
      },
      providers: {
        ai: config.AI_PROVIDER,
        tts: config.TTS_PROVIDER,
      },
      metrics: monitoringService.getMetricsSummary(),
    });
  };
  app.get('/health', healthCheck);
  app.get('/api/v1/health', healthCheck);
  app.get('/api/v1/monitoring/metrics', (_req, res) => {
    res.status(200).json(monitoringService.getMetricsSummary());
  });

  // 3. API Routes
  app.use('/api/v1/placement', createPlacementRouter(placementController));
  app.use('/api/v1/auth', createAuthRouter());
  app.use('/api/v1/tutor', createTutorRouter(tutorController));
  app.use('/api/v1/learning', createLearningRouter(learningController));
  app.use('/api/v1/student', createStudentRouter(studentController));
  app.use('/api/v1/teacher', createTeacherRouter(teacherController));
  app.use('/api/v1/subscription', createSubscriptionRouter(subscriptionController));
  app.use('/api/v1/admin', createAdminRouter());

  // 4. Global Error Handler
  app.use(errorHandler);

  return app;
}
