import { Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { AuthenticatedRequest } from '../types';

export const checkTeacherQuota = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ error: 'Authentification requise' });
      return;
    }

    // 1. Vérifier si l'enseignant a un abonnement actif
    const now = new Date();
    const activeSub = await prisma.abonnement.findFirst({
      where: {
        enseignantId: userId,
        statut: 'ACTIF',
        dateFin: { gte: now },
      },
      include: {
        offre: true,
      },
    });

    // Quota défini par l'offre active ou par le forfait gratuit par défaut (5 quiz/mois)
    const quotaQuiz = activeSub?.offre?.quotaQuiz ?? 5;
    const isUnlimited = quotaQuiz === -1; // -1 représente l'illimité dans les forfaits Pro

    if (isUnlimited) {
      return next();
    }

    // 2. Compter les quiz créés pendant le mois calendaire en cours
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const quizCount = await prisma.quiz.count({
      where: {
        enseignantId: userId,
        dateCreation: {
          gte: startOfMonth,
        },
      },
    });

    if (quizCount >= quotaQuiz) {
      res.status(403).json({
        error: `Quota mensuel atteint (${quizCount}/${quotaQuiz} quiz créés ce mois-ci). Passez à l'abonnement Premium pour créer des quiz illimités.`,
        code: 'QUOTA_EXCEEDED',
        quotaReached: true,
        current: quizCount,
        max: quotaQuiz,
      });
      return;
    }

    next();
  } catch (error) {
    next(error);
  }
};

