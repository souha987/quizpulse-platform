import { checkTeacherQuota } from '../src/middlewares/quota.middleware';
import { prisma } from '../src/config/prisma';
import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../src/types';
import { Role } from '@prisma/client';

describe('QA Tests - Contrôle des Quotas Enseignant (checkTeacherQuota)', () => {
  let mockReq: Partial<AuthenticatedRequest>;
  let mockRes: Partial<Response>;
  let next: NextFunction;

  beforeEach(() => {
    mockReq = {
      user: {
        userId: 'prof-free-1',
        email: 'prof@test.com',
        role: Role.ENSEIGNANT,
      },
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  it('doit autoriser la création de quiz si l\'enseignant gratuit a créé moins de 5 quiz ce mois-ci', async () => {
    // Pas d'abonnement actif (offre gratuite par défaut = 5)
    jest.spyOn(prisma.abonnement, 'findFirst').mockResolvedValue(null);
    // 3 quiz créés ce mois
    jest.spyOn(prisma.quiz, 'count').mockResolvedValue(3);

    await checkTeacherQuota(mockReq as AuthenticatedRequest, mockRes as Response, next);

    expect(next).toHaveBeenCalled();
    expect(mockRes.status).not.toHaveBeenCalled();
  });

  it('doit bloquer avec erreur 403 si l\'enseignant gratuit a atteint son quota de 5 quiz', async () => {
    jest.spyOn(prisma.abonnement, 'findFirst').mockResolvedValue(null);
    // 5 quiz déjà créés
    jest.spyOn(prisma.quiz, 'count').mockResolvedValue(5);

    await checkTeacherQuota(mockReq as AuthenticatedRequest, mockRes as Response, next);

    expect(next).not.toHaveBeenCalled();
    expect(mockRes.status).toHaveBeenCalledWith(403);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'QUOTA_EXCEEDED',
        quotaReached: true,
        current: 5,
        max: 5,
      })
    );
  });

  it('doit autoriser la création illimitée si l\'enseignant a un abonnement Pro actif', async () => {
    const mockProSub = {
      id: 'sub-pro-1',
      offre: {
        quotaQuiz: -1, // Illimité
      },
    };
    jest.spyOn(prisma.abonnement, 'findFirst').mockResolvedValue(mockProSub as any);

    await checkTeacherQuota(mockReq as AuthenticatedRequest, mockRes as Response, next);

    expect(next).toHaveBeenCalled();
    expect(mockRes.status).not.toHaveBeenCalled();
  });
});

