import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError, ValidationError } from '../errors/api_error.js';
import { AuthService } from '../services/auth_service.js';

export class AuthController {
  constructor(private readonly service = new AuthService()) {}
  register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { email, password, role } = req.body ?? {};
      // Public registration never grants administrator access.
      const safeRole = role === 'teacher' ? 'teacher' : 'student';
      res.status(201).json({ success: true, data: await this.service.register(String(email ?? ''), String(password ?? ''), safeRole) });
    } catch (error) { next(error); }
  };
  login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { email, password } = req.body ?? {};
      res.status(200).json({ success: true, data: await this.service.login(String(email ?? ''), String(password ?? '')) });
    } catch (error) { next(error); }
  };
  session = (req: Request, res: Response, next: NextFunction): void => {
    try {
      if (!req.user) throw new UnauthorizedError();
      res.status(200).json({ success: true, data: { user: { id: req.user.userId, role: req.user.role } } });
    } catch (error) { next(error); }
  };
  logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user?.sessionId) throw new ValidationError('A production session is required');
      await this.service.logout(req.user.sessionId);
      res.status(204).send();
    } catch (error) { next(error); }
  };
}
