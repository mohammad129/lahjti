import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../errors/api_error.js';
import { EvaluateRequestSchema } from '../schemas/evaluation_schemas.js';
import { PlacementEvaluationService } from '../services/placement_evaluation_service.js';

export class PlacementController {
  private service: PlacementEvaluationService;

  constructor(service?: PlacementEvaluationService) {
    this.service = service ?? new PlacementEvaluationService();
  }

  evaluateAnswer = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const user = req.user;
      if (!user?.userId) {
        throw new UnauthorizedError('User authentication is required');
      }

      // 1. Strict Request Validation
      const validatedRequest = EvaluateRequestSchema.parse(req.body);

      // 2. Delegate to Service
      const evaluation = await this.service.evaluate(validatedRequest, {
        userId: user.userId,
        requestId: req.headers['x-request-id'] as string | undefined,
      });

      // 3. Return HTTP 200 with strict JSON schema
      res.status(200).json(evaluation);
    } catch (err) {
      next(err);
    }
  };
}
