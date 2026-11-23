import { Router } from 'express';
import { analyticsController } from '../controllers/analytics.controller';
import { requireAuth, requireRole } from '../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

// Vue d'ensemble du tableau de bord enseignant (vraies métriques)
router.get(
  '/teacher/overview',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => analyticsController.getTeacherOverview(req, res, next)
);

// Tableau d'analyse des résultats d'un quiz
router.get(
  '/quiz/:id',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => analyticsController.getQuizAnalytics(req, res, next)
);

// Export CSV des notes de la classe
router.get(
  '/quiz/:id/export-csv',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => analyticsController.exportCsv(req, res, next)
);

export default router;

