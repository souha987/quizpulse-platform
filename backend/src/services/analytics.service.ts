import { attemptRepository } from '../repositories/attempt.repository';
import { quizRepository } from '../repositories/quiz.repository';
import { AppError } from '../middlewares/error.middleware';
import { prisma } from '../config/prisma';

export class AnalyticsService {
  async getQuizAnalytics(quizId: string, enseignantId: string, role?: string) {
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    if (quiz.enseignantId !== enseignantId && role !== 'ADMIN') {
      throw new AppError('Accès non autorisé aux analytiques de ce quiz', 403);
    }

    const attempts = await attemptRepository.getAttemptsForQuiz(quizId);

    const totalTentatives = attempts.length;
    if (totalTentatives === 0) {
      return {
        quizId: quiz.id,
        titre: quiz.titre,
        totalTentatives: 0,
        scoreMoyen: 0,
        tauxReussiteGlobal: 0,
        tauxEchecParQuestion: quiz.questions.map((q) => ({
          questionId: q.id,
          enonce: q.enonce,
          points: q.points,
          totalReponses: 0,
          nbEchecs: 0,
          tauxEchecPourcent: 0,
        })),
        tentativesEtudiants: [],
      };
    }

    // Calcul score moyen et max possible
    const totalPossiblePoints = quiz.questions.reduce((sum, q) => sum + q.points, 0);
    const sumScores = attempts.reduce((sum, a) => sum + a.score, 0);
    const scoreMoyen = Math.round((sumScores / totalTentatives) * 100) / 100;
    const tauxReussiteGlobal =
      totalPossiblePoints > 0 ? Math.round((scoreMoyen / totalPossiblePoints) * 100) : 0;

    // Calcul du taux d'échec par question
    const questionStats = quiz.questions.map((question) => {
      let countReponses = 0;
      let countEchecs = 0;

      for (const attempt of attempts) {
        const userResp = attempt.reponses.find((r) => r.questionId === question.id);
        if (userResp) {
          countReponses++;
          if (!userResp.estCorrecte) {
            countEchecs++;
          }
        } else {
          // Non répondu = échec
          countEchecs++;
          countReponses++;
        }
      }

      const tauxEchecPourcent =
        countReponses > 0 ? Math.round((countEchecs / countReponses) * 100) : 0;

      return {
        questionId: question.id,
        enonce: question.enonce,
        points: question.points,
        totalReponses: countReponses,
        nbEchecs: countEchecs,
        tauxEchecPourcent,
      };
    });

    // Liste des étudiants et notes
    const tentativesEtudiants = attempts.map((a) => {
      const noteSur20 =
        totalPossiblePoints > 0 ? Math.round((a.score / totalPossiblePoints) * 20 * 10) / 10 : 0;
      const nomComplet = a.utilisateur
        ? `${a.utilisateur.nom} ${a.utilisateur.prenom}`
        : `Visiteur Anonyme (${a.identifiantSession || 'N/A'})`;

      return {
        tentativeId: a.id,
        etudiantNom: nomComplet,
        email: a.utilisateur?.email ?? 'N/A',
        datePassage: a.dateDebut,
        score: a.score,
        noteSur20,
        statut: a.statut,
        nbAvertissementsTriche: a.nbAvertissementsTriche,
      };
    });

    return {
      quizId: quiz.id,
      titre: quiz.titre,
      dureeMinutes: quiz.dureeMinutes,
      modeExamenSecurise: quiz.modeExamenSecurise,
      totalTentatives,
      scoreMoyen,
      totalPossiblePoints,
      tauxReussiteGlobal,
      tauxEchecParQuestion: questionStats,
      tentativesEtudiants,
    };
  }

  async getTeacherOverview(enseignantId: string) {
    const [quizzes, classes, recentAttempts, totalSubmissions, allFinishedAttempts] = await Promise.all([
      prisma.quiz.findMany({
        where: { enseignantId },
        include: {
          categorie: { include: { matiere: true } },
          questions: { select: { points: true } },
          _count: { select: { questions: true, tentatives: true } },
        },
        orderBy: { dateCreation: 'desc' },
      }),
      prisma.classe.findMany({
        where: { enseignantId },
        include: {
          _count: { select: { etudiants: true } },
        },
      }),
      prisma.tentative.findMany({
        where: {
          quiz: { enseignantId },
          statut: { in: ['TERMINEE', 'EXPIREE'] },
        },
        include: {
          quiz: {
            select: {
              id: true,
              titre: true,
              questions: { select: { points: true } },
            },
          },
          utilisateur: {
            select: { id: true, nom: true, prenom: true, email: true },
          },
        },
        orderBy: { dateFin: 'desc' },
        take: 10,
      }),
      prisma.tentative.count({
        where: {
          quiz: { enseignantId },
          statut: { in: ['TERMINEE', 'EXPIREE'] },
        },
      }),
      prisma.tentative.findMany({
        where: {
          quiz: { enseignantId },
          statut: { in: ['TERMINEE', 'EXPIREE'] },
        },
        select: {
          score: true,
          quiz: {
            select: {
              questions: { select: { points: true } },
            },
          },
        },
      }),
    ]);

    const activeClassesCount = classes.length;
    const totalStudents = classes.reduce((sum, c) => sum + c._count.etudiants, 0);
    const publishedQuizzesCount = quizzes.filter((q) => q.statut === 'PUBLIE').length;

    let generalAverage = 0;
    if (totalSubmissions > 0 && allFinishedAttempts.length > 0) {
      let sumNotesSur20 = 0;
      let countNotes = 0;
      for (const a of allFinishedAttempts) {
        const totalPoints = a.quiz.questions.reduce((sum, q) => sum + q.points, 0);
        if (totalPoints > 0) {
          sumNotesSur20 += (a.score / totalPoints) * 20;
          countNotes++;
        }
      }
      if (countNotes > 0) {
        generalAverage = Math.round((sumNotesSur20 / countNotes) * 10) / 10;
      }
    }

    return {
      activeClassesCount,
      totalStudents,
      publishedQuizzesCount,
      totalQuizzesCount: quizzes.length,
      generalAverage,
      totalSubmissions,
      recentSubmissions: recentAttempts.map((a) => {
        const totalPoints = a.quiz.questions.reduce((sum, q) => sum + q.points, 0);
        const noteSur20 = totalPoints > 0 ? Math.round((a.score / totalPoints) * 20 * 10) / 10 : 0;
        const studentName = a.utilisateur
          ? `${a.utilisateur.prenom} ${a.utilisateur.nom}`.trim()
          : (a.identifiantSession || 'Anonyme');

        return {
          id: a.id,
          quizId: a.quizId,
          quizTitle: a.quiz.titre,
          studentName,
          score: a.score,
          noteSur20,
          dateFin: a.dateFin,
          statut: a.statut,
        };
      }),
    };
  }

  async generateCsvExport(quizId: string, enseignantId: string, role?: string): Promise<string> {
    const now = new Date();
    const activeSub = await prisma.abonnement.findFirst({
      where: { enseignantId, statut: 'ACTIF', dateFin: { gte: now } },
    });
    if (!activeSub && role !== 'ADMIN') {
      throw new AppError('L\'export CSV des notes est réservé aux abonnés de l\'offre Pro', 403);
    }

    const analytics = await this.getQuizAnalytics(quizId, enseignantId, role);

    const headers = ['Nom Complet', 'Email', 'Date Passage', 'Score Brut', 'Note /20', 'Statut', 'Avertissements Triche'];
    const rows = analytics.tentativesEtudiants.map((t) => [
      `"${t.etudiantNom.replace(/"/g, '""')}"`,
      `"${t.email}"`,
      `"${new Date(t.datePassage).toISOString()}"`,
      t.score,
      t.noteSur20,
      t.statut,
      t.nbAvertissementsTriche,
    ]);

    return [headers.join(';'), ...rows.map((r) => r.join(';'))].join('\n');
  }
}

export const analyticsService = new AnalyticsService();

