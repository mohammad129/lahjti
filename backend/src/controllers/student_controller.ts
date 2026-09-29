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
}
