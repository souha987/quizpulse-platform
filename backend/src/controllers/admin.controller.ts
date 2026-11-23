import { Response, NextFunction } from 'express';
import { adminService } from '../services/admin.service';
import { AuthenticatedRequest } from '../types';
import { Role, StatutQuiz } from '@prisma/client';

export class AdminController {
  async listUsers(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const skip = req.query.skip ? parseInt(req.query.skip as string, 10) : 0;
      const take = req.query.take ? parseInt(req.query.take as string, 10) : 50;
      const role = req.query.role as Role | undefined;
      const search = req.query.search as string | undefined;

      const result = await adminService.listUsers(skip, take, role, search);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async toggleUserStatus(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.toggleUserStatus(req.params.id as string, req.user!.userId);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async listQuizzes(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const skip = req.query.skip ? parseInt(req.query.skip as string, 10) : 0;
      const take = req.query.take ? parseInt(req.query.take as string, 10) : 50;
      const statut = req.query.statut as StatutQuiz | undefined;
      const search = req.query.search as string | undefined;

      const result = await adminService.listAllQuizzes(skip, take, statut, search);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateQuizStatus(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { statut } = req.body;
      const result = await adminService.updateQuizStatus(req.params.id as string, statut);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getMetrics(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const metrics = await adminService.getPlatformMetrics();
      res.status(200).json(metrics);
    } catch (error) {
      next(error);
    }
  }

  async listPayments(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const skip = req.query.skip ? parseInt(req.query.skip as string, 10) : 0;
      const take = req.query.take ? parseInt(req.query.take as string, 10) : 50;
      const result = await adminService.listPayments(skip, take);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const adminController = new AdminController();
