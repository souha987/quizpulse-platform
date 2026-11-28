import { Router } from 'express';
import { classController } from '../controllers/class.controller';
import { requireAuth, requireRole } from '../middlewares/auth.middleware';
import { validateBody } from '../middlewares/validate.middleware';
import { createClassSchema, updateClassSchema, joinClassSchema } from '../validations';
import { Role } from '@prisma/client';

const router = Router();

// Créer une classe (Enseignant uniquement)
router.post(
  '/',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  validateBody(createClassSchema),
  (req, res, next) => classController.createClass(req, res, next)
);

// Obtenir ses classes créées (Enseignant)
router.get(
  '/teacher',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => classController.getMyTeacherClasses(req, res, next)
);

// Rejoindre une classe avec le code PIN 6 caractères (Étudiant)
router.post(
  '/join',
  requireAuth,
  validateBody(joinClassSchema),
  (req, res, next) => classController.joinClass(req, res, next)
);

// Quitter une classe (Étudiant)
router.delete(
  '/:id/leave',
  requireAuth,
  requireRole([Role.ETUDIANT, Role.ADMIN]),
  (req, res, next) => classController.leaveClass(req, res, next)
);

// Obtenir ses classes rejointes (Étudiant)
router.get(
  '/student',
  requireAuth,
  (req, res, next) => classController.getMyStudentClasses(req, res, next)
);

// Détails d'une classe
router.get(
  '/:id',
  requireAuth,
  (req, res, next) => classController.getClassDetails(req, res, next)
);

// Retirer un étudiant d'une classe (Enseignant propriétaire ou Admin)
router.delete(
  '/:id/students/:studentId',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => classController.removeStudentFromClass(req, res, next)
);

// Modifier une classe (Enseignant propriétaire ou Admin)
router.put(
  '/:id',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  validateBody(updateClassSchema),
  (req, res, next) => classController.updateClass(req, res, next)
);

// Supprimer une classe (Enseignant propriétaire ou Admin)
router.delete(
  '/:id',
  requireAuth,
  requireRole([Role.ENSEIGNANT, Role.ADMIN]),
  (req, res, next) => classController.deleteClass(req, res, next)
);

export default router;

