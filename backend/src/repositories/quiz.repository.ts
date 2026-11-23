import { prisma } from '../config/prisma';
import { Quiz, StatutQuiz, TypeQuestion } from '@prisma/client';

export class QuizRepository {
  async create(data: {
    titre: string;
    description?: string;
    estPublic?: boolean;
    statut?: StatutQuiz;
    dureeMinutes?: number;
    codeAcces: string;
    modeExamenSecurise?: boolean;
    enseignantId: string;
    categorieId?: string;
    classeId?: string;
  }): Promise<Quiz> {
    return prisma.quiz.create({
      data,
    });
  }

  async findById(id: string) {
    return prisma.quiz.findUnique({
      where: { id },
      include: {
        enseignant: {
          select: { id: true, nom: true, prenom: true },
        },
        categorie: {
          include: { matiere: true },
        },
        classe: true,
        questions: {
          orderBy: { ordre: 'asc' },
          include: {
            options: true,
          },
        },
      },
    });
  }

  async findByPin(codeAcces: string) {
    return prisma.quiz.findUnique({
      where: { codeAcces },
      include: {
        enseignant: {
          select: { id: true, nom: true, prenom: true },
        },
        classe: true,
      },
    });
  }

  async listPublic(query?: { search?: string; matiereId?: string; skip?: number; take?: number }) {
    const skip = query?.skip ?? 0;
    const take = query?.take ?? 20;

    const where: any = {
      estPublic: true,
      statut: 'PUBLIE',
    };

    if (query?.search) {
      where.OR = [
        { titre: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query?.matiereId) {
      where.categorie = {
        matiereId: query.matiereId,
      };
    }

    const [total, items] = await Promise.all([
      prisma.quiz.count({ where }),
      prisma.quiz.findMany({
        where,
        skip,
        take,
        include: {
          enseignant: {
            select: { id: true, nom: true, prenom: true },
          },
          categorie: {
            include: { matiere: true },
          },
          _count: {
            select: {
              questions: true,
              tentatives: true,
            },
          },
        },
        orderBy: { dateCreation: 'desc' },
      }),
    ]);

    return { total, items };
  }

  async listByTeacher(enseignantId: string) {
    return prisma.quiz.findMany({
      where: { enseignantId },
      include: {
        categorie: {
          include: { matiere: true },
        },
        classe: true,
        _count: {
          select: {
            questions: true,
            tentatives: true,
          },
        },
      },
      orderBy: { dateCreation: 'desc' },
    });
  }

  async update(id: string, data: Partial<Quiz>) {
    return prisma.quiz.update({
      where: { id },
      data,
    });
  }

  async delete(id: string) {
    return prisma.quiz.delete({
      where: { id },
    });
  }

  async addQuestion(quizId: string, data: {
    enonce: string;
    type: TypeQuestion;
    points: number;
    ordre: number;
    explicationCorrection?: string;
    options: { texte: string; estCorrecte: boolean }[];
  }) {
    return prisma.question.create({
      data: {
        quizId,
        enonce: data.enonce,
        type: data.type,
        points: data.points,
        ordre: data.ordre,
        explicationCorrection: data.explicationCorrection,
        options: {
          create: data.options.map((opt) => ({
            texte: opt.texte,
            estCorrecte: opt.estCorrecte,
          })),
        },
      },
      include: {
        options: true,
      },
    });
  }

  async updateQuestion(questionId: string, data: {
    enonce?: string;
    type?: TypeQuestion;
    points?: number;
    ordre?: number;
    explicationCorrection?: string;
    options?: { id?: string; texte: string; estCorrecte: boolean }[];
  }) {
    // Si options sont fournies, on met à jour la question et ses options
    return prisma.$transaction(async (tx) => {
      const question = await tx.question.update({
        where: { id: questionId },
        data: {
          ...(data.enonce !== undefined && { enonce: data.enonce }),
          ...(data.type !== undefined && { type: data.type }),
          ...(data.points !== undefined && { points: data.points }),
          ...(data.ordre !== undefined && { ordre: data.ordre }),
          ...(data.explicationCorrection !== undefined && { explicationCorrection: data.explicationCorrection }),
        },
      });

      if (data.options) {
        // Supprimer anciennes options et recréer
        await tx.option.deleteMany({ where: { questionId } });
        await tx.option.createMany({
          data: data.options.map((o) => ({
            questionId,
            texte: o.texte,
            estCorrecte: o.estCorrecte,
          })),
        });
      }

      return tx.question.findUnique({
        where: { id: questionId },
        include: { options: true },
      });
    });
  }

  async deleteQuestion(questionId: string) {
    return prisma.question.delete({
      where: { id: questionId },
    });
  }

  async reorderQuestions(quizId: string, orderUpdates: { questionId: string; ordre: number }[]) {
    return prisma.$transaction(
      orderUpdates.map((item) =>
        prisma.question.update({
          where: { id: item.questionId, quizId },
          data: { ordre: item.ordre },
        })
      )
    );
  }
}

export const quizRepository = new QuizRepository();

