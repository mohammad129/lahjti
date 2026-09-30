import { NextFunction, Request, Response } from 'express';
import { config } from '../config/env.js';
import { ForbiddenError, UnauthorizedError } from '../errors/api_error.js';

/** Server-side admin gate. Flutter route visibility is never an authority. */
export function requireAdmin(req: Request, _res: Response, next: NextFunction): void {
  const user = req.user;
  if (!user) return next(new UnauthorizedError('Authentication required for administration'));

  const bootstrapAdmins = new Set(
    config.ADMIN_USER_IDS.split(',').map((id) => id.trim()).filter(Boolean),
  );
  if (user.role === 'admin' || bootstrapAdmins.has(user.userId)) return next();
  return next(new ForbiddenError('Administrator privileges are required'));
}
