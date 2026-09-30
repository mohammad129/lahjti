import crypto from 'crypto';
import { NextFunction, Request, Response } from 'express';
import { config } from '../config/env.js';
import { UnauthorizedError } from '../errors/api_error.js';
import { AuthService } from '../services/auth_service.js';

export interface AuthenticatedUser {
  userId: string;
  role?: 'admin' | 'teacher' | 'student' | 'individual';
  sessionId?: string;
  isDevUser?: boolean;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

const authService = new AuthService();

export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  const devUserIdHeader = req.headers['x-user-id'];

  // 1. Bearer Token Auth
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7).trim();
    if (config.NODE_ENV === 'production') {
      const identity = verifyProductionJwt(token);
      if (!identity) {
        return next(new UnauthorizedError('Invalid authorization token'));
      }
      if (!identity.sessionId || !(await authService.isSessionActive(identity.sessionId, identity.userId))) {
        return next(new UnauthorizedError('Session is no longer active'));
      }
      req.user = { ...identity, isDevUser: false };
      return next();
    }
    if (token.length > 0 && token !== 'invalid_token') {
      // Development/test only: permit the lightweight test token abstraction.
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

/** Verifies a compact HS256 JWT without accepting unsigned bearer tokens. */
function verifyProductionJwt(token: string): Pick<AuthenticatedUser, 'userId' | 'role' | 'sessionId'> | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;

  const [encodedHeader, encodedPayload, signature] = parts;
  try {
    const header = JSON.parse(Buffer.from(encodedHeader, 'base64url').toString('utf8'));
    const payload = JSON.parse(Buffer.from(encodedPayload, 'base64url').toString('utf8'));
    if (header.alg !== 'HS256' || typeof payload.sub !== 'string' || !payload.sub) return null;
    if (payload.iss !== 'lahjti' || payload.aud !== 'lahjti-mobile' || typeof payload.jti !== 'string' || !payload.jti) return null;
    if (typeof payload.exp !== 'number' || payload.exp <= Math.floor(Date.now() / 1000)) return null;

    const expected = crypto
      .createHmac('sha256', config.JWT_SECRET)
      .update(`${encodedHeader}.${encodedPayload}`)
      .digest('base64url');
    if (signature.length !== expected.length || !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
      return null;
    }
    const allowedRoles = ['admin', 'teacher', 'student', 'individual'];
    const role = allowedRoles.includes(payload.role) ? payload.role as AuthenticatedUser['role'] : undefined;
    return { userId: payload.sub, role, sessionId: payload.jti };
  } catch {
    return null;
  }
}
