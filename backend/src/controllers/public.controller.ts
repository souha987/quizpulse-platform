import { Request, Response, NextFunction } from 'express';
import { quizRepository } from '../repositories/quiz.repository';
import { subscriptionRepository } from '../repositories/subscription.repository';
import { prisma } from '../config/prisma';
import { AppError } from '../middlewares/error.middleware';

export class PublicController {
  async getPublicQuizzes(req: Request, res: Response, next: NextFunction) {
    try {
      const search = req.query.search as string | undefined;
      const matiereId = req.query.matiereId as string | undefined;
      const skip = req.query.skip ? parseInt(req.query.skip as string, 10) : 0;
      const take = req.query.take ? parseInt(req.query.take as string, 10) : 20;

      const result = await quizRepository.listPublic({ search, matiereId, skip, take });
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getQuizPreview(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id as string;
      const quiz = await prisma.quiz.findUnique({
        where: { id },
        select: {
          id: true,
          titre: true,
          description: true,
          dureeMinutes: true,
          modeExamenSecurise: true,
          codeAcces: true,
          statut: true,
          estPublic: true,
          dateCreation: true,
          enseignant: {
            select: { id: true, nom: true, prenom: true },
          },
          categorie: {
            include: { matiere: true },
          },
          _count: {
            select: { questions: true, tentatives: true },
          },
        },
      });

      if (!quiz) {
        throw new AppError('Quiz introuvable', 404);
      }

      res.status(200).json(quiz);
    } catch (error) {
      next(error);
    }
  }

  async getPlans(req: Request, res: Response, next: NextFunction) {
    try {
      const plans = await subscriptionRepository.listActivePlans();
      res.status(200).json(plans);
    } catch (error) {
      next(error);
    }
  }

  async getSubjects(req: Request, res: Response, next: NextFunction) {
    try {
      const skip = req.query.skip ? Math.max(0, parseInt(req.query.skip as string, 10)) : 0;
      const take = req.query.take ? Math.min(Math.max(1, parseInt(req.query.take as string, 10)), 100) : 50;
      const search = req.query.search as string | undefined;

      const where: any = {};
      if (search) {
        where.OR = [
          { nom: { contains: search, mode: 'insensitive' } },
          { description: { contains: search, mode: 'insensitive' } },
        ];
      }

      const [total, subjects] = await Promise.all([
        prisma.matiere.count({ where }),
        prisma.matiere.findMany({
          where,
          skip,
          take,
          include: {
            categories: true,
            _count: {
              select: { categories: true },
            },
          },
          orderBy: { nom: 'asc' },
        }),
      ]);

      if (req.query.paginated === 'true') {
        res.status(200).json({ total, skip, take, subjects });
      } else {
        res.status(200).json(subjects);
      }
    } catch (error) {
      next(error);
    }
  }
}

export const publicController = new PublicController();
