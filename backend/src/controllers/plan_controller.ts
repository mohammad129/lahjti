import { NextFunction, Request, Response } from 'express';
import { PlanService } from '../services/plan_service.js';

export class PlanController {
  constructor(private planService: PlanService) {}

  listPlans = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { category, targetAgeGroup, targetLevel } = req.query;
      const plans = await this.planService.listPlans({
        category: category as string,
        targetAgeGroup: targetAgeGroup as string,
        targetLevel: targetLevel as string,
      });
      res.json({ success: true, count: plans.length, plans });
    } catch (error) {
      next(error);
    }
  };

  getPlanDetails = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { planId } = req.params;
      const studentId = req.user?.userId || (req as any).user?.id;
      const details = await this.planService.getPlanDetails(planId, studentId);
      res.json({ success: true, ...details });
    } catch (error) {
      next(error);
    }
  };

  enrollInPlan = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { planId } = req.params;
      const studentId = req.user?.userId || (req as any).user?.id || req.body.studentId;
      const result = await this.planService.enrollStudent(studentId, planId);
      res.json({ success: true, ...result });
    } catch (error) {
      next(error);
    }
  };

  getDayActivities = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { planId, dayNumber } = req.params;
      const studentId = req.user?.userId || (req as any).user?.id || 'anonymous';
      const day = await this.planService.getDayActivities(
        studentId,
        planId,
        parseInt(dayNumber, 10) || 1
      );
      res.json({ success: true, day });
    } catch (error) {
      next(error);
    }
  };

  completeActivity = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { activityId } = req.params;
      const { planDayId, score, answers } = req.body;
      const studentId = req.user?.userId || (req as any).user?.id;

      const result = await this.planService.completeActivity(
        studentId,
        planDayId,
        activityId,
        { score, answers }
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  };
}
