import { quizRepository } from '../repositories/quiz.repository';
import { prisma } from '../config/prisma';
import { AppError } from '../middlewares/error.middleware';
import { StatutQuiz, TypeQuestion } from '@prisma/client';

export class QuizService {
  private generatePinCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async createQuiz(
    data: {
      titre: string;
      description?: string;
      estPublic?: boolean;
      statut?: StatutQuiz;
      dureeMinutes?: number;
      modeExamenSecurise?: boolean;
      categorieId?: string;
      classeId?: string;
    },
    enseignantId: string
  ) {
    const trimmedTitre = data.titre.trim();

    // Règle d'unicité : un enseignant ne peut pas avoir deux quiz avec le même titre
    const existingQuiz = await prisma.quiz.findFirst({
      where: {
        enseignantId,
        titre: {
          equals: trimmedTitre,
          mode: 'insensitive',
        },
      },
    });

    if (existingQuiz) {
      throw new AppError(
        `Un quiz avec le titre "${trimmedTitre}" existe déjà. Veuillez choisir un autre titre.`,
        409
      );
    }

    if (data.modeExamenSecurise) {
      const now = new Date();
      const activeSub = await prisma.abonnement.findFirst({
        where: { enseignantId, statut: 'ACTIF', dateFin: { gte: now } },
      });
      if (!activeSub) {
        // Attribution automatique d'un essai Pro gratuit de 30 jours pour tout enseignant
        const proPlan = await prisma.offreAbonnement.findFirst({ where: { active: true } });
        if (proPlan) {
          const expiration = new Date();
          expiration.setDate(expiration.getDate() + 30);
          await prisma.abonnement.create({
            data: {
              enseignantId,
              offreId: proPlan.id,
              dateFin: expiration,
              statut: 'ACTIF',
            },
          });
        }
      }
    }

    let codeAcces = this.generatePinCode();
    let existing = await quizRepository.findByPin(codeAcces);
    let attempts = 0;
    while (existing && attempts < 5) {
      codeAcces = this.generatePinCode();
      existing = await quizRepository.findByPin(codeAcces);
      attempts++;
    }

    const estPublic = data.estPublic ?? false;
    // Un nouveau quiz créé n'a encore aucune question : statut forcé à BROUILLON jusqu'à ajout des questions
    const statut = StatutQuiz.BROUILLON;

    return quizRepository.create({
      titre: trimmedTitre,
      description: data.description,
      estPublic,
      statut,
      dureeMinutes: data.dureeMinutes ?? 15,
      codeAcces,
      modeExamenSecurise: data.modeExamenSecurise ?? false,
      enseignantId,
      categorieId: data.categorieId,
      classeId: data.classeId,
    });
  }

  async getQuizById(id: string, userId?: string, role?: string) {
    const quiz = await quizRepository.findById(id);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    // Si utilisateur est le créateur enseignant ou admin, renvoie tout
    if (quiz.enseignantId === userId || role === 'ADMIN') {
      return quiz;
    }

    // Si le quiz n'est pas publié et que ce n'est pas le créateur
    if (quiz.statut !== StatutQuiz.PUBLIE) {
      throw new AppError('Ce quiz n\'est pas encore disponible', 403);
    }

    // Sécurité critique : masquer les bonnes réponses et explications pour les étudiants et visiteurs
    return {
      ...quiz,
      questions: quiz.questions.map((q) => ({
        id: q.id,
        quizId: q.quizId,
        enonce: q.enonce,
        type: q.type,
        points: q.points,
        ordre: q.ordre,
        options: q.options.map((opt) => ({
          id: opt.id,
          questionId: opt.questionId,
          texte: opt.texte,
        })),
      })),
    };
  }

  async updateQuiz(
    quizId: string,
    data: {
      titre?: string;
      description?: string;
      estPublic?: boolean;
      statut?: StatutQuiz;
      dureeMinutes?: number;
      modeExamenSecurise?: boolean;
      categorieId?: string;
      classeId?: string;
    },
    enseignantId: string,
    role?: string
  ) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à modifier ce quiz', 403);
    }

    let trimmedTitre: string | undefined = undefined;
    if (data.titre) {
      trimmedTitre = data.titre.trim();
      // Règle d'unicité : un enseignant ne peut pas avoir deux quiz avec le même titre
      const duplicate = await prisma.quiz.findFirst({
        where: {
          enseignantId: quiz.enseignantId,
          id: { not: quizId },
          titre: {
            equals: trimmedTitre,
            mode: 'insensitive',
          },
        },
      });

      if (duplicate) {
        throw new AppError(
          `Un autre quiz avec le titre "${trimmedTitre}" existe déjà. Veuillez choisir un autre titre.`,
          409
        );
      }
    }

    if (data.modeExamenSecurise) {
      const now = new Date();
      const activeSub = await prisma.abonnement.findFirst({
        where: { enseignantId, statut: 'ACTIF', dateFin: { gte: now } },
      });
      if (!activeSub) {
        // Attribution automatique d'un essai Pro gratuit de 30 jours pour tout enseignant
        const proPlan = await prisma.offreAbonnement.findFirst({ where: { active: true } });
        if (proPlan) {
          const expiration = new Date();
          expiration.setDate(expiration.getDate() + 30);
          await prisma.abonnement.create({
            data: {
              enseignantId,
              offreId: proPlan.id,
              dateFin: expiration,
              statut: 'ACTIF',
            },
          });
        }
      }
    }

    const targetStatut = data.statut ?? quiz.statut;
    if (targetStatut === StatutQuiz.PUBLIE && (!quiz.questions || quiz.questions.length === 0)) {
      throw new AppError('Impossible de publier un quiz qui ne contient aucune question', 400);
    }

    return quizRepository.update(quizId, {
      ...data,
      ...(trimmedTitre !== undefined && { titre: trimmedTitre }),
      statut: targetStatut,
    });
  }

  async deleteQuiz(quizId: string, enseignantId: string, role?: string) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à supprimer ce quiz', 403);
    }

    return quizRepository.delete(quizId);
  }

  async duplicateQuiz(quizId: string, enseignantId: string, role?: string) {
    const original = await quizRepository.findById(quizId);
    if (!original) {
      throw new AppError('Quiz introuvable', 404);
    }

    if (original.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à dupliquer un quiz appartenant à un autre enseignant', 403);
    }

    let copyTitle = `${original.titre} (Copie)`;
    let copyIndex = 2;
    while (
      await prisma.quiz.findFirst({
        where: {
          enseignantId,
          titre: { equals: copyTitle, mode: 'insensitive' },
        },
      })
    ) {
      copyTitle = `${original.titre} (Copie ${copyIndex})`;
      copyIndex++;
    }

    const newQuiz = await this.createQuiz(
      {
        titre: copyTitle,
        description: original.description || undefined,
        estPublic: original.estPublic,
        dureeMinutes: original.dureeMinutes,
        modeExamenSecurise: original.modeExamenSecurise,
        categorieId: original.categorieId || undefined,
      },
      enseignantId
    );

    if (original.questions && original.questions.length > 0) {
      for (const q of original.questions) {
        await this.addQuestion(
          newQuiz.id,
          {
            enonce: q.enonce,
            type: q.type,
            points: q.points,
            explicationCorrection: q.explicationCorrection || undefined,
            options: q.options.map((opt) => ({
              texte: opt.texte,
              estCorrecte: opt.estCorrecte,
            })),
          },
          enseignantId
        );
      }
    }

    return quizRepository.findById(newQuiz.id);
  }

  async addQuestion(
    quizId: string,
    data: {
      enonce: string;
      type: TypeQuestion;
      points?: number;
      ordre?: number;
      explicationCorrection?: string;
      options: { texte: string; estCorrecte: boolean }[];
    },
    enseignantId: string,
    role?: string
  ) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }
    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à modifier ce quiz', 403);
    }

    // Validation des réponses correctes
    const correctCount = data.options.filter((o) => o.estCorrecte).length;
    if (correctCount === 0) {
      throw new AppError('Une question doit comporter au moins une réponse correcte', 400);
    }
    if ((data.type === TypeQuestion.QCM_UNIQUE || data.type === TypeQuestion.VRAI_FAUX) && correctCount > 1) {
      throw new AppError('Une question à choix unique ou vrai/faux ne peut avoir qu\'une seule réponse correcte', 400);
    }

    const currentQuestionsCount = quiz.questions?.length ?? 0;
    const ordre = data.ordre ?? currentQuestionsCount + 1;

    return quizRepository.addQuestion(quizId, {
      enonce: data.enonce,
      type: data.type,
      points: data.points ?? 1.0,
      ordre,
      explicationCorrection: data.explicationCorrection,
      options: data.options,
    });
  }

  async updateQuestion(
    quizId: string,
    questionId: string,
    data: {
      enonce?: string;
      type?: TypeQuestion;
      points?: number;
      ordre?: number;
      explicationCorrection?: string;
      options?: { id?: string; texte: string; estCorrecte: boolean }[];
    },
    enseignantId: string,
    role?: string
  ) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) throw new AppError('Quiz introuvable', 404);
    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à modifier les questions de ce quiz', 403);
    }

    const question = quiz.questions?.find((q) => q.id === questionId);
    if (!question) {
      throw new AppError('Question introuvable dans ce quiz', 404);
    }

    if (data.options) {
      const qType = data.type || question.type;
      const correctCount = data.options.filter((o) => o.estCorrecte).length;
      if (correctCount === 0) {
        throw new AppError('Une question doit comporter au moins une réponse correcte', 400);
      }
      if ((qType === TypeQuestion.QCM_UNIQUE || qType === TypeQuestion.VRAI_FAUX) && correctCount > 1) {
        throw new AppError('Une question à choix unique ou vrai/faux ne peut avoir qu\'une seule réponse correcte', 400);
      }
    }

    return quizRepository.updateQuestion(questionId, data);
  }

  async deleteQuestion(quizId: string, questionId: string, enseignantId: string, role?: string) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) throw new AppError('Quiz introuvable', 404);
    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à supprimer les questions de ce quiz', 403);
    }

    const question = quiz.questions?.find((q) => q.id === questionId);
    if (!question) {
      throw new AppError('Question introuvable dans ce quiz', 404);
    }

    return quizRepository.deleteQuestion(questionId);
  }

  async reorderQuestions(quizId: string, orderUpdates: { questionId: string; ordre: number }[], enseignantId: string, role?: string) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) throw new AppError('Quiz introuvable', 404);
    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Non autorisé à réorganiser ce quiz', 403);
    }

    return quizRepository.reorderQuestions(quizId, orderUpdates);
  }

  async getPublicQuizzes(query?: { search?: string; matiereId?: string; skip?: number; take?: number }) {
    return quizRepository.listPublic(query);
  }

  async getTeacherQuizzes(enseignantId: string) {
    return quizRepository.listByTeacher(enseignantId);
  }

  async findByPin(pin: string) {
    const quiz = await quizRepository.findByPin(pin.trim());
    if (!quiz) {
      throw new AppError('Code PIN invalide. Aucun quiz correspondant.', 404);
    }
    return quiz;
  }

  async getStudentAssignedQuizzes(userId: string) {
    const studentClasses = await prisma.etudiantClasse.findMany({
      where: { etudiantId: userId },
      select: { classeId: true },
    });

    const classIds = studentClasses.map((sc) => sc.classeId);
    if (classIds.length === 0) {
      return [];
    }

    const quizzes = await prisma.quiz.findMany({
      where: {
        classeId: { in: classIds },
        statut: StatutQuiz.PUBLIE,
        classe: {
          estSupprimee: false,
        },
      },
      include: {
        enseignant: {
          select: { id: true, nom: true, prenom: true },
        },
        classe: {
          select: { id: true, nom: true, codeClasse: true },
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
    });

    const quizIds = quizzes.map((q) => q.id);
    const userAttempts = await prisma.tentative.findMany({
      where: {
        utilisateurId: userId,
        quizId: { in: quizIds },
      },
      orderBy: { dateDebut: 'desc' },
    });

    return quizzes.map((q) => {
      const myAttempts = userAttempts.filter((a) => a.quizId === q.id);
      const lastAttempt = myAttempts[0] || null;
      return {
        ...q,
        derniereTentative: lastAttempt
          ? {
              id: lastAttempt.id,
              score: lastAttempt.score,
              statut: lastAttempt.statut,
              dateDebut: lastAttempt.dateDebut,
              dateFin: lastAttempt.dateFin,
            }
          : null,
      };
    });
  }
}

export const quizService = new QuizService();

