import { Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { AuthenticatedRequest } from '../types';

export class AuthController {
  async register(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await authService.register(req.body);
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async login(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { email, motDePasse } = req.body;
      const result = await authService.login(email, motDePasse);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async me(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const user = await authService.getCurrentUser(req.user!.userId);
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  }

  async verifyEmail(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const email = req.body?.email || (req.query?.email as string);
      const code = req.body?.code || (req.query?.code as string);
      const registrationToken = req.body?.registrationToken || (req.query?.registrationToken as string);
      const result = await authService.verifyEmail(email, code, registrationToken);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async resendVerification(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const email = req.body?.email;
      const registrationToken = req.body?.registrationToken;
      const result = await authService.resendVerification(email, registrationToken);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();

