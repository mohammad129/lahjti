import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError, ValidationError } from '../errors/api_error.js';
import {
  recordActivitySchema,
  saveExamResultSchema,
  updateProfileSchema,
  updateProgressSchema,
  updateVocabularyProgressSchema,
} from '../schemas/learning_schemas.js';
import { LearningService } from '../services/learning_service.js';

export class LearningController {
  constructor(private service: LearningService) {}

  private getAuthUserId(req: Request): string {
    const userId = req.user?.userId;
    if (!userId || userId.trim().length === 0) {
      throw new UnauthorizedError('Authentication required to access learning data');
    }
    return userId.trim();
  }

  getProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const profile = await this.service.getProfile(userId);
      res.status(200).json({ success: true, data: profile });
    } catch (err) {
      next(err);
    }
  };

  updateProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const parsed = updateProfileSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid profile update data: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }
      const updated = await this.service.updateProfile(userId, parsed.data);
      res.status(200).json({ success: true, data: updated });
    } catch (err) {
      next(err);
    }
  };

  getProgress = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const progress = await this.service.getProgress(userId);
      res.status(200).json({ success: true, data: progress });
    } catch (err) {
      next(err);
    }
  };

  updateProgress = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const parsed = updateProgressSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid progress update data');
      }
      const updated = await this.service.updateProgress(userId, parsed.data);
      res.status(200).json({ success: true, data: updated });
    } catch (err) {
      next(err);
    }
  };

  getVocabulary = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const vocab = await this.service.getVocabulary(userId);
      res.status(200).json({ success: true, data: vocab });
    } catch (err) {
      next(err);
    }
  };

  updateVocabularyProgress = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const parsed = updateVocabularyProgressSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid vocabulary progress data: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }
      const updated = await this.service.updateVocabularyProgress(userId, parsed.data);
      res.status(200).json({ success: true, data: updated });
    } catch (err) {
      next(err);
    }
  };

  getExamResults = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const exams = await this.service.getExamResults(userId);
      res.status(200).json({ success: true, data: exams });
    } catch (err) {
      next(err);
    }
  };

  saveExamResult = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const parsed = saveExamResultSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid exam result data: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }
      const saved = await this.service.saveExamResult(userId, parsed.data);
      res.status(201).json({ success: true, data: saved });
    } catch (err) {
      next(err);
    }
  };

  recordActivity = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const parsed = recordActivitySchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError('Invalid activity recording data: ' + parsed.error.issues.map((i) => i.message).join(', '));
      }
      const outcome = await this.service.recordActivity(userId, parsed.data);
      res.status(200).json({ success: true, data: outcome });
    } catch (err) {
      next(err);
    }
  };

  getDailySummary = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const dateStr = typeof req.query.date === 'string' ? req.query.date : new Date().toISOString();
      const date = new Date(dateStr);
      const summary = await this.service.getDailySummary(userId, isNaN(date.getTime()) ? new Date() : date);
      res.status(200).json({ success: true, data: summary });
    } catch (err) {
      next(err);
    }
  };

  getWeeklySummary = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = this.getAuthUserId(req);
      const weekStartStr = typeof req.query.weekStart === 'string' ? req.query.weekStart : new Date().toISOString();
      const weekStart = new Date(weekStartStr);
      const summary = await this.service.getWeeklySummary(userId, isNaN(weekStart.getTime()) ? new Date() : weekStart);
      res.status(200).json({ success: true, data: summary });
    } catch (err) {
      next(err);
    }
  };

  getDialectGuide = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { jordanianDialectService } = await import('../services/jordanian_dialect_service.js');
      res.status(200).json({
        success: true,
        data: {
          commonExpressions: jordanianDialectService.getDialectDictionary(),
          grammarGuidelines: jordanianDialectService.getGrammarGuidelines(),
        },
      });
    } catch (err) {
      next(err);
    }
  };
}
