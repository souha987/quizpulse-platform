import { prisma } from '../config/prisma';
import { StatutTentative, Tentative } from '@prisma/client';

export class AttemptRepository {
  async createAttempt(data: {
    quizId: string;
    utilisateurId?: string;
    identifiantSession?: string;
  }): Promise<Tentative> {
    return prisma.tentative.create({
      data: {
        quizId: data.quizId,
        utilisateurId: data.utilisateurId,
        identifiantSession: data.identifiantSession,
        dateDebut: new Date(),
        statut: 'EN_COURS',
        score: 0.0,
      },
    });
  }

  async findActiveAttempt(quizId: string, userId?: string, identifiantSession?: string) {
    const where: any = {
      quizId,
      statut: 'EN_COURS',
    };
    if (userId) {
      where.utilisateurId = userId;
    } else if (identifiantSession) {
      where.identifiantSession = identifiantSession;
    } else {
      return null;
    }

    return prisma.tentative.findFirst({
      where,
      orderBy: { dateDebut: 'desc' },
      include: {
        reponses: true,
      },
    });
  }

  async findById(id: string) {
    return prisma.tentative.findUnique({
      where: { id },
      include: {
        quiz: {
          include: {
            questions: {
              orderBy: { ordre: 'asc' },
              include: {
                options: true,
              },
            },
          },
        },
        reponses: {
          include: {
            option: true,
          },
        },
        utilisateur: {
          select: {
            id: true,
            nom: true,
            prenom: true,
            email: true,
          },
        },
      },
    });
  }

  // RÈGLE ABSOLUE POUR LE START DU QUIZ :
  // Omettre explicitement 'estCorrecte' et 'explicationCorrection'
  async getQuizForAttempt(quizId: string) {
    return prisma.quiz.findUnique({
      where: { id: quizId },
      select: {
        id: true,
        titre: true,
        description: true,
        dureeMinutes: true,
        modeExamenSecurise: true,
        questions: {
          orderBy: { ordre: 'asc' },
          select: {
            id: true,
            enonce: true,
            type: true,
            points: true,
            ordre: true,
            // ATTENTION : 'explicationCorrection' n'est PAS sélectionné ici pour éviter toute triche !
            options: {
              select: {
                id: true,
                texte: true,
                // ATTENTION : 'estCorrecte' n'est PAS sélectionné ici pour empêcher toute triche inspecteur !
              },
            },
          },
        },
      },
    });
  }

  async recordWarning(tentativeId: string) {
    return prisma.tentative.update({
      where: { id: tentativeId },
      data: {
        nbAvertissementsTriche: {
          increment: 1,
        },
      },
    });
  }

  async saveProgress(tentativeId: string, answers: { questionId: string; optionId?: string; reponseTexte?: string }[]) {
    return prisma.$transaction(async (tx) => {
      for (const ans of answers) {
        // Upsert de la réponse temporaire
        const existing = await tx.reponseDonnee.findFirst({
          where: { tentativeId, questionId: ans.questionId },
        });

        if (existing) {
          await tx.reponseDonnee.update({
            where: { id: existing.id },
            data: {
              optionId: ans.optionId,
              reponseTexte: ans.reponseTexte,
            },
          });
        } else {
          await tx.reponseDonnee.create({
            data: {
              tentativeId,
              questionId: ans.questionId,
              optionId: ans.optionId,
              reponseTexte: ans.reponseTexte,
            },
          });
        }
      }
    });
  }

  async finishAttempt(
    tentativeId: string,
    data: {
      score: number;
      statut: StatutTentative;
      reponses: {
        questionId: string;
        optionId?: string;
        reponseTexte?: string;
        estCorrecte: boolean;
        pointsObtenus: number;
      }[];
    }
  ) {
    return prisma.$transaction(async (tx) => {
      // 1. Supprimer les réponses temporaires pour réécrire la validation finale
      await tx.reponseDonnee.deleteMany({
        where: { tentativeId },
      });

      // 2. Insérer les réponses évaluées
      if (data.reponses.length > 0) {
        await tx.reponseDonnee.createMany({
          data: data.reponses.map((r) => ({
            tentativeId,
            questionId: r.questionId,
            optionId: r.optionId,
            reponseTexte: r.reponseTexte,
            estCorrecte: r.estCorrecte,
            pointsObtenus: r.pointsObtenus,
          })),
        });
      }

      // 3. Mettre à jour la tentative
      return tx.tentative.update({
        where: { id: tentativeId },
        data: {
          score: data.score,
          statut: data.statut,
          dateFin: new Date(),
        },
        include: {
          reponses: {
            include: {
              question: {
                select: {
                  id: true,
                  enonce: true,
                  points: true,
                  explicationCorrection: true,
                  options: true,
                },
              },
            },
          },
        },
      });
    });
  }

  async listByUser(userId: string) {
    return prisma.tentative.findMany({
      where: { utilisateurId: userId },
      include: {
        quiz: {
          select: {
            id: true,
            titre: true,
            description: true,
            dureeMinutes: true,
            modeExamenSecurise: true,
          },
        },
      },
      orderBy: { dateDebut: 'desc' },
    });
  }

  async getAttemptsForQuiz(quizId: string) {
    return prisma.tentative.findMany({
      where: { quizId, statut: { in: ['TERMINEE', 'EXPIREE'] } },
      include: {
        utilisateur: {
          select: { id: true, nom: true, prenom: true, email: true },
        },
        reponses: {
          include: {
            question: true,
            option: true,
          },
        },
      },
      orderBy: { score: 'desc' },
    });
  }
}

export const attemptRepository = new AttemptRepository();

