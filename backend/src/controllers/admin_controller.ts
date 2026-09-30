import { NextFunction, Request, Response } from 'express';
import { config } from '../config/env.js';
import { monitoringService } from '../services/monitoring_service.js';
import { ContentManagementService } from '../services/content_management_service.js';

/** Safe operational overview. It intentionally excludes secrets and user content. */
export class AdminController {
  private readonly content = new ContentManagementService();
  overview = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      res.status(200).json({
        success: true,
        data: {
          metrics: monitoringService.getMetricsSummary(),
          services: {
            databaseConfigured: Boolean(config.DATABASE_URL),
            aiProvider: config.AI_PROVIDER,
            ttsProvider: config.TTS_PROVIDER,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  };
  listContent = (kind: 'lessons' | 'vocabulary') => async (_req: Request, res: Response, next: NextFunction): Promise<void> => { try { res.json({ success: true, data: await this.content.list(kind) }); } catch (error) { next(error); } };
  createContent = (kind: 'lessons' | 'vocabulary') => async (req: Request, res: Response, next: NextFunction): Promise<void> => { try { res.status(201).json({ success: true, data: await this.content.create(kind, req.body ?? {}) }); } catch (error) { next(error); } };
  updateContent = (kind: 'lessons' | 'vocabulary') => async (req: Request, res: Response, next: NextFunction): Promise<void> => { try { res.json({ success: true, data: await this.content.update(kind, req.params.id, req.body ?? {}) }); } catch (error) { next(error); } };
  deleteContent = (kind: 'lessons' | 'vocabulary') => async (req: Request, res: Response, next: NextFunction): Promise<void> => { try { await this.content.remove(kind, req.params.id); res.status(204).send(); } catch (error) { next(error); } };
}
