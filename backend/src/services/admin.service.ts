import { userRepository } from '../repositories/user.repository';
import { prisma } from '../config/prisma';
import { Role, StatutQuiz } from '@prisma/client';
import { AppError } from '../middlewares/error.middleware';

export class AdminService {
  async listUsers(skip = 0, take = 50, role?: Role, search?: string) {
    return userRepository.listUsers(skip, take, role, search);
  }

  async toggleUserStatus(userId: string, currentAdminId: string) {
    if (userId === currentAdminId) {
      throw new AppError('Impossible de désactiver votre propre compte administrateur', 400);
    }

    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError('Utilisateur introuvable', 404);
    }

    const updated = await userRepository.setStatus(userId, !user.actif);
    return {
      message: `Statut de l'utilisateur ${updated.email} mis à jour : ${updated.actif ? 'Actif' : 'Suspendu'}`,
      user: {
        id: updated.id,
        email: updated.email,
        actif: updated.actif,
      },
    };
  }

  async listAllQuizzes(skip = 0, take = 50, statut?: StatutQuiz, search?: string) {
    const where: any = {};
    if (statut) where.statut = statut;
    if (search) {
      where.OR = [
        { titre: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [total, quizzes] = await Promise.all([
      prisma.quiz.count({ where }),
      prisma.quiz.findMany({
        where,
        skip,
        take,
        include: {
          enseignant: {
            select: { id: true, nom: true, prenom: true, email: true },
          },
          categorie: {
            include: { matiere: true },
          },
          _count: {
            select: { questions: true, tentatives: true },
          },
        },
        orderBy: { dateCreation: 'desc' },
      }),
    ]);

    const mappedQuizzes = quizzes.map((q) => ({
      ...q,
      matiere: q.categorie?.matiere?.nom || null,
    }));

    return { total, quizzes: mappedQuizzes };
  }

  async updateQuizStatus(quizId: string, statut: StatutQuiz) {
    const quiz = await prisma.quiz.findUnique({ where: { id: quizId } });
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    const updated = await prisma.quiz.update({
      where: { id: quizId },
      data: { statut },
    });

    return {
      message: `Statut du quiz "${updated.titre}" mis à jour en ${statut}`,
      quiz: updated,
    };
  }

  async getPlatformMetrics() {
    const [
      totalUsers,
      totalStudents,
      totalTeachers,
      totalQuizzes,
      totalAttempts,
      totalRevenueData,
    ] = await Promise.all([
      prisma.utilisateur.count(),
      prisma.utilisateur.count({ where: { role: Role.ETUDIANT } }),
      prisma.utilisateur.count({ where: { role: Role.ENSEIGNANT } }),
      prisma.quiz.count(),
      prisma.tentative.count({ where: { statut: 'TERMINEE' } }),
      prisma.paiement.aggregate({
        where: { statut: 'VALIDE' },
        _sum: { montant: true },
      }),
    ]);

    return {
      totalUsers,
      totalStudents,
      totalTeachers,
      totalQuizzes,
      totalAttempts,
      totalRevenue: totalRevenueData._sum.montant ?? 0.0,
    };
  }

  async listPayments(skip = 0, take = 50) {
    const [total, payments] = await Promise.all([
      prisma.paiement.count(),
      prisma.paiement.findMany({
        skip,
        take,
        include: {
          abonnement: {
            include: {
              enseignant: {
                select: { id: true, nom: true, prenom: true, email: true },
              },
              offre: true,
            },
          },
        },
        orderBy: { datePaiement: 'desc' },
      }),
    ]);
    return { total, payments };
  }
}

export const adminService = new AdminService();

