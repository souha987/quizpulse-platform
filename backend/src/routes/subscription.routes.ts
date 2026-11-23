import { Router } from 'express';
import { subscriptionController } from '../controllers/subscription.controller';
import { requireAuth, requireRole } from '../middlewares/auth.middleware';
import { Role } from '@prisma/client';

const router = Router();

// Liste des offres d'abonnement disponibles
router.get('/plans', (req, res, next) =>
  subscriptionController.getPlans(req, res, next)
);

// Statut de l'abonnement de l'enseignant connecté et consommation du quota
router.get(
  '/my',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => subscriptionController.getMySubscription(req, res, next)
);

// Initier un paiement / checkout Stripe
router.post(
  '/checkout',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => subscriptionController.checkout(req, res, next)
);

// Webhook Stripe
router.post('/webhook', (req, res, next) =>
  subscriptionController.webhook(req, res, next)
);

export default router;

