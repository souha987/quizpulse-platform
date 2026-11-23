import { Response, NextFunction } from 'express';
import { attemptService } from '../services/attempt.service';
import { AuthenticatedRequest } from '../types';

export class AttemptController {
  /**
   * Endpoint GET /api/quiz/:id/start (Lancement sécurisé)
   * - Vérifie les droits d'accès
   * - Crée la tentative
   * - Omet explicitement 'estCorrecte' et 'explicationCorrection'
   */
  async startQuiz(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const quizId = req.params.id as string;
      const userId = req.user?.userId;
      const identifiantSession = (req.headers['x-session-id'] as string) || (req.query.sessionId as string);

      const result = await attemptService.startQuiz(quizId, userId, identifiantSession);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Endpoint POST /api/attempts/:id/submit (Validation & Calcul de note)
   * - Calcule le temps écoulé (dureeMinutes + 15s marge réseau)
   * - Note côté serveur avec la vraie valeur estCorrecte
   * - Renvoie la note et le corrigé complet
   */
  async submitAttempt(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const tentativeId = req.params.id as string;
      const { reponses, identifiantSession, estExpiree, isAutoExpired } = req.body;
      const headerSessionId = req.headers['x-session-id'] as string;
      const session = identifiantSession || headerSessionId;
      const userId = req.user?.userId;
      const hasExpired = Boolean(estExpiree || isAutoExpired);

      const result = await attemptService.submitAttempt(
        tentativeId,
        reponses,
        userId,
        session,
        hasExpired
      );
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async recordWarning(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const tentativeId = req.params.id as string;
      await attemptService.recordCheatWarning(tentativeId);
      res.status(200).json({ message: 'Avertissement de sortie d\'écran enregistré' });
    } catch (error) {
      next(error);
    }
  }

  async saveProgress(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const tentativeId = req.params.id as string;
      const { reponses } = req.body;
      await attemptService.saveProgress(tentativeId, reponses);
      res.status(200).json({ message: 'Progression sauvegardée' });
    } catch (error) {
      next(error);
    }
  }

  async getMyAttempts(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const history = await attemptService.getUserHistory(req.user!.userId);
      res.status(200).json(history);
    } catch (error) {
      next(error);
    }
  }

  async getAttemptReview(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const review = await attemptService.getAttemptReview(
        req.params.id as string,
        req.user?.userId,
        req.user?.role
      );
      res.status(200).json(review);
    } catch (error) {
      next(error);
    }
  }
}

export const attemptController = new AttemptController();
