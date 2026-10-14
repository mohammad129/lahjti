import { NextFunction, Request, Response } from 'express';
import { ForbiddenError, NotFoundError, UnauthorizedError, ValidationError } from '../errors/api_error.js';
import { joinSchoolSchema, submitGameResultSchema } from '../schemas/school_schemas.js';
import { SchoolService } from '../services/school_service.js';

export class StudentController {
  constructor(private service: SchoolService) {}

  private getAuthStudentId(req: Request): string {
    const userId = req.user?.userId;
    if (!userId || userId.trim().length === 0) {
      throw new UnauthorizedError('Authentication required to access student learning');
    }
    return userId.trim();
  }

  getHome = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const data = await this.service.getStudentHome(studentId);
      res.status(200).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  getTasks = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const date = (req.query.date as string) || new Date().toISOString().split('T')[0];
      const tasks = await this.service.getOrCreateDailyTasks(studentId, date);
      res.status(200).json({ success: true, data: tasks });
    } catch (err) {
      next(err);
    }
  };

  completeTask = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const taskId = req.params.taskId;
      if (!taskId || taskId.trim().length === 0) {
        throw new ValidationError('Task ID is required');
      }

      const result = await this.service.completeDailyTask(studentId, taskId.trim());
      res.status(200).json({ success: true, data: result });
    } catch (err: any) {
      if (err.message?.startsWith('NOT_FOUND:')) {
        return next(new NotFoundError(err.message.replace('NOT_FOUND: ', '')));
      }
      if (err.message?.startsWith('FORBIDDEN:')) {
        return next(new ForbiddenError(err.message.replace('FORBIDDEN: ', '')));
      }
      next(err);
    }
  };

  submitGameResult = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const parsed = submitGameResultSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid game result payload: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }

      const result = await this.service.submitGameResult(studentId, parsed.data);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };

  getProgress = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const progress = await this.service.getStudentProgress(studentId);
      res.status(200).json({ success: true, data: progress });
    } catch (err) {
      next(err);
    }
  };

  joinSchool = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const parsed = joinSchoolSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid school join payload: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }

      const result = await this.service.joinSchool(studentId, parsed.data);
      res.status(200).json({ success: true, data: result });
    } catch (err: any) {
      if (err.message?.startsWith('NOT_FOUND:')) {
        return next(new NotFoundError(err.message.replace('NOT_FOUND: ', '')));
      }
      next(err);
    }
  };

  submitExam = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const { examId } = req.params;
      const { answers } = req.body;
      const { getDatabase } = await import('../db/index.js');
      const { ExamManagementService } = await import('../services/exam_management_service.js');
      const examService = new ExamManagementService(getDatabase());
      const result = await examService.submitExam(examId, studentId, answers || {});
      res.status(200).json({ success: true, data: result });
    } catch (err) { next(err); }
  };

  getMistakeReviews = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const { getDatabase } = await import('../db/index.js');
      const { SpacedRepetitionMistakeService } = await import('../services/mistake_service.js');
      const mistakeService = new SpacedRepetitionMistakeService(getDatabase());
      const reviews = await mistakeService.getDueReviews(studentId);
      res.status(200).json({ success: true, data: reviews });
    } catch (err) { next(err); }
  };

  attemptMistakeReview = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const { contentId } = req.params;
      const { studentAnswer } = req.body;
      const { getDatabase } = await import('../db/index.js');
      const { SpacedRepetitionMistakeService } = await import('../services/mistake_service.js');
      const mistakeService = new SpacedRepetitionMistakeService(getDatabase());
      const result = await mistakeService.submitReviewAttempt(studentId, contentId, String(studentAnswer || ''));
      res.status(200).json({ success: true, data: result });
    } catch (err) { next(err); }
  };

  getPointsHistory = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const { getDatabase } = await import('../db/index.js');
      const db = getDatabase();
      const transactions = await db.getPointsTransactions(studentId);
      const progress = await db.getProgress(studentId);
      res.status(200).json({
        success: true,
        data: {
          totalPoints: progress?.totalXp || 0,
          transactions,
        },
      });
    } catch (err) { next(err); }
  };

  playGame = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = this.getAuthStudentId(req);
      const { gameId } = req.params;
      const { getDatabase } = await import('../db/index.js');
      const { GameManagementService } = await import('../services/game_management_service.js');
      const gameService = new GameManagementService(getDatabase());
      const result = await gameService.submitGamePlay(gameId, studentId, req.body);
      res.status(200).json({ success: true, data: result });
    } catch (err) { next(err); }
  };
}

