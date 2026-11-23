import { Router } from 'express';
import { attemptController } from '../controllers/attempt.controller';
import { requireAuth, optionalAuth } from '../middlewares/auth.middleware';
import { validateBody } from '../middlewares/validate.middleware';
import { submitAttemptSchema } from '../validations';

const router = Router();

// ENDPOINT CRITIQUE : POST /api/attempts/:id/submit (Validation & Calcul de note)
router.post(
  '/:id/submit',
  optionalAuth,
  validateBody(submitAttemptSchema),
  (req, res, next) => attemptController.submitAttempt(req, res, next)
);

// Enregistrer un avertissement de triche (perte de focus / changement d'onglet)
router.post('/:id/warning', optionalAuth, (req, res, next) =>
  attemptController.recordWarning(req, res, next)
);

// Sauvegarde automatique de la progression en cours
router.post('/:id/save-progress', optionalAuth, (req, res, next) =>
  attemptController.saveProgress(req, res, next)
);

// Historique personnel des tentatives (Étudiant connecté)
router.get('/my', requireAuth, (req, res, next) =>
  attemptController.getMyAttempts(req, res, next)
);

// Consulter le corrigé d'une tentative passée
router.get('/:id', optionalAuth, (req, res, next) =>
  attemptController.getAttemptReview(req, res, next)
);

export default router;

