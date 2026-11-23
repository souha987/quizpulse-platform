import { Response, NextFunction } from 'express';
import { analyticsService } from '../services/analytics.service';
import { AuthenticatedRequest } from '../types';

export class AnalyticsController {
  async getQuizAnalytics(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const analytics = await analyticsService.getQuizAnalytics(
        req.params.id as string,
        req.user!.userId,
        req.user?.role
      );
      res.status(200).json(analytics);
    } catch (error) {
      next(error);
    }
  }

  async exportCsv(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const csvData = await analyticsService.generateCsvExport(
        req.params.id as string,
        req.user!.userId,
        req.user?.role
      );

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="notes-quiz-${req.params.id}.csv"`);
      res.status(200).send(csvData);
    } catch (error) {
      next(error);
    }
  }

  async getTeacherOverview(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const overview = await analyticsService.getTeacherOverview(req.user!.userId);
      res.status(200).json(overview);
    } catch (error) {
      next(error);
    }
  }
}

export const analyticsController = new AnalyticsController();
