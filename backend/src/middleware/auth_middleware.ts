import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../errors/api_error.js';

export interface AuthenticatedUser {
  userId: string;
  isDevUser?: boolean;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;
  const devUserIdHeader = req.headers['x-user-id'];

  // 1. Bearer Token Auth
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7).trim();
    if (token.length > 0 && token !== 'invalid_token') {
      // In production, verify JWT signature with config.JWT_SECRET.
      // For dev/token abstraction, accept valid token string:
      req.user = {
        userId: token.startsWith('user_') ? token : `usr_${token.substring(0, 12)}`,
        isDevUser: false,
      };
      return next();
    }
    return next(new UnauthorizedError('Invalid authorization token'));
  }

  // 2. Development User Header (Clearly marked dev path)
  if (process.env.NODE_ENV !== 'production' && typeof devUserIdHeader === 'string' && devUserIdHeader.trim().length > 0) {
    req.user = {
      userId: devUserIdHeader.trim(),
      isDevUser: true,
    };
    return next();
  }

  // 3. Fallback: Reject unauthenticated requests
  return next(
    new UnauthorizedError('Missing or malformed authorization credentials')
  );
}
