import { NextFunction, Request, Response } from 'express';
import { ForbiddenError, NotFoundError, UnauthorizedError, ValidationError } from '../errors/api_error.js';
import { createClassroomSchema, enrollStudentSchema } from '../schemas/school_schemas.js';
import { SchoolService } from '../services/school_service.js';

export class TeacherController {
  constructor(private service: SchoolService) {}

  private getAuthTeacherId(req: Request): string {
    const userId = req.user?.userId;
    if (!userId || userId.trim().length === 0) {
      throw new UnauthorizedError('Authentication required to access teacher portal');
    }
    return userId.trim();
  }

  getHome = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const teacherId = this.getAuthTeacherId(req);
      const data = await this.service.getTeacherHome(teacherId);
      res.status(200).json({ success: true, data });
    } catch (err: any) {
      if (err.message?.startsWith('FORBIDDEN:')) {
        return next(new ForbiddenError(err.message.replace('FORBIDDEN: ', '')));
      }
      next(err);
    }
  };

  getClassDetail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const teacherId = this.getAuthTeacherId(req);
      const classId = req.params.classId;
      if (!classId) {
        throw new ValidationError('classId is required');
      }

      const data = await this.service.getTeacherClassDetail(teacherId, classId);
      res.status(200).json({ success: true, data });
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

  getStudentDetail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const teacherId = this.getAuthTeacherId(req);
      const studentId = req.params.studentId;
      if (!studentId) {
        throw new ValidationError('studentId is required');
      }

      const data = await this.service.getTeacherStudentDetail(teacherId, studentId);
      res.status(200).json({ success: true, data });
    } catch (err: any) {
      if (err.message?.startsWith('FORBIDDEN:')) {
        return next(new ForbiddenError(err.message.replace('FORBIDDEN: ', '')));
      }
      next(err);
    }
  };
}
