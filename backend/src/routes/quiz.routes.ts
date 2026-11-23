import { Router } from 'express';
import { quizController } from '../controllers/quiz.controller';
import { attemptController } from '../controllers/attempt.controller';
import { requireAuth, requireRole, optionalAuth } from '../middlewares/auth.middleware';
import { checkTeacherQuota } from '../middlewares/quota.middleware';
import { validateBody } from '../middlewares/validate.middleware';
import {
  createQuizSchema,
  updateQuizSchema,
  createQuestionSchema,
  reorderQuestionsSchema,
} from '../validations';
import { Role } from '@prisma/client';

const router = Router();

// Créer un quiz (Enseignant uniquement, soumis au quota mensuel)
router.post(
  '/',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  checkTeacherQuota,
  validateBody(createQuizSchema),
  (req, res, next) => quizController.createQuiz(req, res, next)
);

// Liste des quiz de l'enseignant connecté
router.get(
  '/teacher',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => quizController.getMyTeacherQuizzes(req, res, next)
);

// Quiz assignés aux classes de l'étudiant connecté
router.get(
  '/student/assigned',
  requireAuth,
  (req, res, next) => quizController.getMyAssignedQuizzes(req, res, next)
);

// Recherche par code PIN 6 chiffres (Étudiant ou Visiteur)
router.get('/pin/:pin', optionalAuth, (req, res, next) =>
  quizController.findByPin(req, res, next)
);

// ENDPOINT CRITIQUE : GET /api/quiz/:id/start (Lancement sécurisé)
router.get('/:id/start', optionalAuth, (req, res, next) =>
  attemptController.startQuiz(req, res, next)
);

// Détails d'un quiz
router.get('/:id', optionalAuth, (req, res, next) =>
  quizController.getQuizById(req, res, next)
);

// Mise à jour d'un quiz
router.put(
  '/:id',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  validateBody(updateQuizSchema),
  (req, res, next) => quizController.updateQuiz(req, res, next)
);

// Suppression d'un quiz
router.delete(
  '/:id',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => quizController.deleteQuiz(req, res, next)
);

// Duplication d'un quiz en 1 clic
router.post(
  '/:id/duplicate',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  checkTeacherQuota,
  (req, res, next) => quizController.duplicateQuiz(req, res, next)
);

// Questions : Ajout
router.post(
  '/:id/questions',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  validateBody(createQuestionSchema),
  (req, res, next) => quizController.addQuestion(req, res, next)
);

// Questions : Modification
router.put(
  '/:id/questions/:questionId',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => quizController.updateQuestion(req, res, next)
);

// Questions : Suppression
router.delete(
  '/:id/questions/:questionId',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => quizController.deleteQuestion(req, res, next)
);

// Questions : Réorganisation drag-and-drop
router.post(
  '/:id/reorder',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  validateBody(reorderQuestionsSchema),
  (req, res, next) => quizController.reorderQuestions(req, res, next)
);

export default router;

