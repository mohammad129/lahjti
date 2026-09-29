import rateLimit from 'express-rate-limit';
import { config } from '../config/env.js';
import { RateLimitError } from '../errors/api_error.js';

export const placementRateLimiter = rateLimit({
  windowMs: config.RATE_LIMIT_WINDOW_MS,
  max: config.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, _res, next) => {
    next(new RateLimitError());
  },
  keyGenerator: (req) => {
    return req.user?.userId || req.ip || 'anonymous';
  },
});

export const tutorRateLimiter = rateLimit({
  windowMs: config.RATE_LIMIT_WINDOW_MS,
  max: config.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, _res, next) => {
    next(new RateLimitError());
  },
  keyGenerator: (req) => {
    return req.user?.userId || req.ip || 'anonymous';
  },
});
