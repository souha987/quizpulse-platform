import { Router } from 'express';
import { publicController } from '../controllers/public.controller';

const router = Router();

// Catalogue de quiz publics avec recherche et filtrage par matière
router.get('/quiz', (req, res, next) => publicController.getPublicQuizzes(req, res, next));

// Prévisualisation d'un quiz
router.get('/quiz/:id/preview', (req, res, next) =>
  publicController.getQuizPreview(req, res, next)
);

// Liste des offres tarifaires (Gratuit vs Pro)
router.get('/plans', (req, res, next) => publicController.getPlans(req, res, next));

// Liste des matières et catégories
router.get('/subjects', (req, res, next) => publicController.getSubjects(req, res, next));

export default router;

