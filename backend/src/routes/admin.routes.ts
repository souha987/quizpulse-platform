import { Router } from 'express';
import { adminController } from '../controllers/admin.controller';
import { requireAuth, requireRole } from '../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

// Toutes les routes admin nécessitent le rôle ADMIN
router.use(requireAuth, requireRole([Role.ADMIN]));

// Gestion des utilisateurs
router.get('/users', (req, res, next) => adminController.listUsers(req, res, next));
router.patch('/users/:id/toggle-status', (req, res, next) =>
  adminController.toggleUserStatus(req, res, next)
);

// Modération des quiz
router.get('/quiz', (req, res, next) => adminController.listQuizzes(req, res, next));
router.patch('/quiz/:id/status', (req, res, next) =>
  adminController.updateQuizStatus(req, res, next)
);

// Métriques globales de la plateforme
router.get('/metrics', (req, res, next) => adminController.getMetrics(req, res, next));

// Liste des paiements et transactions
router.get('/payments', (req, res, next) => adminController.listPayments(req, res, next));

export default router;

