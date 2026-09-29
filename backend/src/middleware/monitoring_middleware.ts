import { NextFunction, Request, Response } from 'express';
import { monitoringService } from '../services/monitoring_service.js';

export function requestMonitoringMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const startTime = Date.now();

  // Attach listener to response finish event
  res.on('finish', () => {
    const durationMs = Date.now() - startTime;
    const statusCode = res.statusCode;
    
    // Check if error code was attached to response or locals
    const errorCode = (res.locals?.errorCode as string) || undefined;

    monitoringService.recordHttpRequest({
      method: req.method,
      path: req.baseUrl ? `${req.baseUrl}${req.path}` : req.path,
      statusCode,
      durationMs,
      errorCode,
      timestamp: Date.now(),
    });
  });

  next();
}
