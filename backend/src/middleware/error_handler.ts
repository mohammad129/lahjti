import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../errors/api_error.js';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // 1. Known Custom ApiError
  if (err instanceof ApiError) {
    res.locals.errorCode = err.code;
    res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        arabicMessage: err.arabicMessage,
      },
    });
    return;
  }

  // 2. Zod Validation Error
  if (err instanceof ZodError) {
    res.locals.errorCode = 'VALIDATION_ERROR';
    const errorDetails = err.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', ');
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: `Validation failed: ${errorDetails}`,
        arabicMessage: 'البيانات المدخلة غير صحيحة. يرجى التأكد والمحاولة مرة أخرى.',
      },
    });
    return;
  }

  // 3. Fallback Internal Server Error (Never leak stack trace or internal secrets)
  res.locals.errorCode = 'INTERNAL_SERVER_ERROR';
  console.error('Unhandled server error:', err);
  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected internal server error occurred',
      arabicMessage: 'صار معنا خلل غير متوقع. يرجى المحاولة مرة أخرى لاحقًا.',
    },
  });
}
