import { attemptRepository } from '../repositories/attempt.repository';
import { quizRepository } from '../repositories/quiz.repository';
import { classRepository } from '../repositories/class.repository';
import { prisma } from '../config/prisma';
import { AppError } from '../middlewares/error.middleware';
import { StatutQuiz, StatutTentative, TypeQuestion } from '@prisma/client';

export interface UserSubmittedAnswer {
  questionId: string;
  optionId?: string; // Pour QCM_UNIQUE et VRAI_FAUX
  optionIds?: string[]; // Pour QCM_MULTIPLE
  reponseTexte?: string;
}

export class AttemptService {
  /**
   * Lancement sécurisé d'un quiz :
   * 1. Vérifie les droits d'accès (public ou inscrit dans la classe cible)
   * 2. Crée la tentative avec dateDebut = now
   * 3. OMET EXPLICITEMENT estCorrecte et explicationCorrection pour empêcher la triche
   */
  async startQuiz(quizId: string, userId?: string, identifiantSession?: string) {
    if (userId) {
      await this.autoExpireStaleAttempts(userId);
    }
    const quiz = await quizRepository.findById(quizId);
    if (!quiz) {
      throw new AppError('Quiz introuvable', 404);
    }

    if (quiz.statut !== StatutQuiz.PUBLIE) {
      throw new AppError('Ce quiz n\'est pas accessible pour le moment', 403);
    }

    // Vérification des droits d'accès
    if (!quiz.estPublic) {
      if (quiz.classeId) {
        if (!userId) {
          throw new AppError('Vous devez être connecté et inscrit dans la classe pour passer ce quiz', 401);
        }
        const isInClass = await classRepository.isStudentInClass(userId, quiz.classeId);
        const isTeacher = quiz.enseignantId === userId;
        if (!isInClass && !isTeacher) {
          throw new AppError('Vous n\'êtes pas inscrit dans la classe à laquelle ce quiz est assigné', 403);
        }
      } else if (quiz.enseignantId !== userId) {
        throw new AppError('Ce quiz est privé et réservé à son créateur', 403);
      }
    }

    // Vérification s'il existe déjà une tentative en cours pour ne pas créer de doublon au rafraîchissement
    let tentative: any = null;
    if (userId || identifiantSession) {
      const activeAttempt = await attemptRepository.findActiveAttempt(quiz.id, userId, identifiantSession);
      if (activeAttempt) {
        const now = new Date();
        const dateDebut = new Date(activeAttempt.dateDebut);
        const dureeMaxMs = quiz.dureeMinutes * 60 * 1000 + 15000;
        const tempsEcouleMs = now.getTime() - dateDebut.getTime();

        if (tempsEcouleMs > dureeMaxMs) {
          await prisma.tentative.update({
            where: { id: activeAttempt.id },
            data: { statut: StatutTentative.EXPIREE, dateFin: now },
          });
        } else {
          tentative = activeAttempt;
        }
      }
    }

    if (!tentative) {
      // Création de l'enregistrement Tentative
      tentative = await attemptRepository.createAttempt({
        quizId: quiz.id,
        utilisateurId: userId,
        identifiantSession: !userId ? (identifiantSession ?? `anon_${Date.now()}`) : undefined,
      });
    }

    // Récupération sécurisée du contenu du quiz SANS les réponses ni explications
    const safeQuiz = await attemptRepository.getQuizForAttempt(quiz.id);

    const now = new Date();
    const dateDebut = new Date(tentative.dateDebut);
    const dureeTotaleMs = quiz.dureeMinutes * 60 * 1000;
    const tempsEcouleMs = Math.max(0, now.getTime() - dateDebut.getTime());
    const tempsRestantSecondes = Math.max(0, Math.floor((dureeTotaleMs - tempsEcouleMs) / 1000));

    return {
      tentativeId: tentative.id,
      identifiantSession: tentative.identifiantSession,
      dateDebut: tentative.dateDebut,
      dureeMinutes: quiz.dureeMinutes,
      tempsRestantSecondes,
      modeExamenSecurise: quiz.modeExamenSecurise,
      quiz: safeQuiz,
    };
  }

  /**
   * Validation & Calcul de la note d'une tentative :
   * 1. Contrôle du dépassement de temps avec 15s de marge réseau
   * 2. Notation stricte côté serveur avec les vraies réponses en base
   * 3. Renvoi de la note finale avec le corrigé complet et explications
   */
  async submitAttempt(
    tentativeId: string,
    answers: UserSubmittedAnswer[],
    userId?: string,
    identifiantSession?: string,
    clientEstExpiree: boolean = false,
    role?: string
  ) {
    const tentative = await attemptRepository.findById(tentativeId);
    if (!tentative) {
      throw new AppError('Tentative introuvable', 404);
    }

    if (tentative.statut !== StatutTentative.EN_COURS) {
      throw new AppError('Cette tentative a déjà été soumise ou clôturée', 400);
    }

    // Vérifier l'appartenance de la tentative
    if (tentative.utilisateurId && tentative.utilisateurId !== userId) {
      throw new AppError('Non autorisé à soumettre cette tentative', 403);
    }
    if (!tentative.utilisateurId && tentative.identifiantSession && tentative.identifiantSession !== identifiantSession) {
      throw new AppError('Session de tentative non valide', 403);
    }

    const now = new Date();
    const dateDebut = new Date(tentative.dateDebut);
    const dureeMaxMs = tentative.quiz.dureeMinutes * 60 * 1000 + 15000; // 15 secondes de marge réseau
    const tempsEcouleMs = now.getTime() - dateDebut.getTime();

    // Vérification de l'expiration du temps imparti
    const estExpiree = clientEstExpiree || (tempsEcouleMs > dureeMaxMs);
    const statutFinal: StatutTentative = estExpiree ? StatutTentative.EXPIREE : StatutTentative.TERMINEE;

    // Évaluation côté serveur
    let totalScore = 0.0;
    let totalPointsPossible = 0.0;
    const evaluatedResponses: {
      questionId: string;
      optionId?: string;
      reponseTexte?: string;
      estCorrecte: boolean;
      pointsObtenus: number;
    }[] = [];

    // Map des questions réelles avec leurs options et bonnes réponses
    const questionsDb = tentative.quiz.questions;

    for (const q of questionsDb) {
      totalPointsPossible += q.points;
      const userAns = answers.find((a) => a.questionId === q.id);

      if (!userAns) {
        // Pas de réponse fournie pour cette question
        evaluatedResponses.push({
          questionId: q.id,
          estCorrecte: false,
          pointsObtenus: 0.0,
        });
        continue;
      }

      if (q.type === TypeQuestion.QCM_UNIQUE || q.type === TypeQuestion.VRAI_FAUX) {
        const selectedOption = q.options.find((opt) => opt.id === userAns.optionId);
        const estCorrect = selectedOption ? selectedOption.estCorrecte : false;
        const points = estCorrect ? q.points : 0.0;
        totalScore += points;

        evaluatedResponses.push({
          questionId: q.id,
          optionId: userAns.optionId,
          estCorrecte: estCorrect,
          pointsObtenus: points,
        });
      } else if (q.type === TypeQuestion.QCM_MULTIPLE) {
        // Pour choix multiples : déduplication des options soumises avant comparaison
        const rawOptionIds = userAns.optionIds || (userAns.optionId ? [userAns.optionId] : []);
        const submittedOptionIds = Array.from(new Set(rawOptionIds));
        const correctOptions = q.options.filter((opt) => opt.estCorrecte).map((opt) => opt.id);

        const allCorrectSelected =
          submittedOptionIds.length === correctOptions.length &&
          submittedOptionIds.every((id) => correctOptions.includes(id));

        const points = allCorrectSelected ? q.points : 0.0;
        totalScore += points;

        // On enregistre la première option ou le tableau sous forme textuelle
        evaluatedResponses.push({
          questionId: q.id,
          optionId: submittedOptionIds[0],
          reponseTexte: JSON.stringify(submittedOptionIds),
          estCorrecte: allCorrectSelected,
          pointsObtenus: points,
        });
      }
    }

    // Arrondir le score à 2 décimales
    totalScore = Math.round(totalScore * 100) / 100;

    // Enregistrement final en base
    const savedAttempt = await attemptRepository.finishAttempt(tentative.id, {
      score: totalScore,
      statut: statutFinal,
      reponses: evaluatedResponses,
    });

    // Construction du corrigé complet avec explications
    const corrigeComplet = questionsDb.map((q) => {
      const evaluation = evaluatedResponses.find((r) => r.questionId === q.id);
      return {
        questionId: q.id,
        enonce: q.enonce,
        type: q.type,
        pointsPossible: q.points,
        pointsObtenus: evaluation?.pointsObtenus ?? 0,
        estCorrecte: evaluation?.estCorrecte ?? false,
        reponseUtilisateurOptionId: evaluation?.optionId,
        explicationCorrection: q.explicationCorrection,
        options: q.options.map((opt) => ({
          id: opt.id,
          texte: opt.texte,
          estCorrecte: opt.estCorrecte,
        })),
      };
    });

    // Règle pédagogique : Ne jamais envoyer le corrigé ni les bonnes réponses aux étudiants
    const isTeacherOrAdmin = role === 'ENSEIGNANT' || role === 'ADMIN';
    const nbQuestionsTotal = questionsDb.length;
    const nbQuestionsCorrectes = evaluatedResponses.filter((r) => r.estCorrecte).length;

    return {
      tentativeId: savedAttempt.id,
      statut: statutFinal,
      estExpiree,
      score: totalScore,
      totalPointsPossible,
      nbQuestionsCorrectes,
      nbQuestionsTotal,
      pourcentage: totalPointsPossible > 0 ? Math.round((totalScore / totalPointsPossible) * 100) : 0,
      noteSur20: totalPointsPossible > 0 ? Math.round((totalScore / totalPointsPossible) * 20 * 10) / 10 : 0,
      dureeSecondes: Math.round(tempsEcouleMs / 1000),
      nbAvertissementsTriche: savedAttempt.nbAvertissementsTriche,
      corrige: isTeacherOrAdmin ? corrigeComplet : [],
    };
  }

  async recordCheatWarning(tentativeId: string) {
    const tentative = await attemptRepository.findById(tentativeId);
    if (!tentative) {
      throw new AppError('Tentative introuvable', 404);
    }
    return attemptRepository.recordWarning(tentativeId);
  }

  async saveProgress(
    tentativeId: string,
    answers: { questionId: string; optionId?: string; reponseTexte?: string }[]
  ) {
    const tentative = await attemptRepository.findById(tentativeId);
    if (!tentative) {
      throw new AppError('Tentative introuvable', 404);
    }
    if (tentative.statut !== StatutTentative.EN_COURS) {
      throw new AppError('Impossible de sauvegarder la progression d\'une tentative terminée', 400);
    }
    return attemptRepository.saveProgress(tentativeId, answers);
  }

  async autoExpireStaleAttempts(userId?: string) {
    try {
      const now = new Date();
      const whereClause: any = { statut: StatutTentative.EN_COURS };
      if (userId) {
        whereClause.utilisateurId = userId;
      }

      const staleAttempts = await prisma.tentative.findMany({
        where: whereClause,
        include: {
          quiz: {
            include: {
              questions: {
                include: { options: true },
              },
            },
          },
          reponses: true,
        },
      });

      for (const att of staleAttempts) {
        const dureeMinutes = att.quiz?.dureeMinutes || 15;
        const dureeMaxMs = dureeMinutes * 60 * 1000 + 30000; // 30s marge réseau
        const tempsEcouleMs = now.getTime() - new Date(att.dateDebut).getTime();

        if (tempsEcouleMs > dureeMaxMs) {
          let totalScore = 0.0;
          let totalPointsPossible = 0.0;

          if (att.quiz?.questions) {
            for (const q of att.quiz.questions) {
              totalPointsPossible += q.points;
              const userAns = att.reponses.find((r) => r.questionId === q.id);
              if (userAns && userAns.optionId) {
                const selectedOpt = q.options.find((opt) => opt.id === userAns.optionId);
                if (selectedOpt && selectedOpt.estCorrecte) {
                  totalScore += q.points;
                  await prisma.reponseDonnee.update({
                    where: { id: userAns.id },
                    data: { estCorrecte: true, pointsObtenus: q.points },
                  });
                }
              }
            }
          }

          const noteSur20 = totalPointsPossible > 0
            ? Math.round((totalScore / totalPointsPossible) * 20 * 10) / 10
            : 0.0;

          await prisma.tentative.update({
            where: { id: att.id },
            data: {
              statut: StatutTentative.EXPIREE,
              score: totalScore,
              dateFin: new Date(new Date(att.dateDebut).getTime() + dureeMinutes * 60 * 1000),
            },
          });
        }
      }
    } catch (err) {
      console.error('Erreur autoExpireStaleAttempts:', err);
    }
  }

  async getUserHistory(userId: string) {
    await this.autoExpireStaleAttempts(userId);
    return attemptRepository.listByUser(userId);
  }

  async getAttemptReview(tentativeId: string, userId?: string, role?: string) {
    const tentative = await attemptRepository.findById(tentativeId);
    if (!tentative) {
      throw new AppError('Tentative introuvable', 404);
    }

    if (role !== 'ADMIN' && tentative.utilisateurId && tentative.utilisateurId !== userId) {
      throw new AppError('Accès non autorisé aux résultats de cette tentative', 403);
    }

    // Sécurité critique : masquer les bonnes réponses et explications tant que la tentative est en cours
    if (tentative.statut === StatutTentative.EN_COURS && role !== 'ADMIN' && tentative.quiz?.enseignantId !== userId) {
      throw new AppError('Le corrigé n\'est pas disponible tant que la tentative est en cours', 403);
    }

    // Pour les étudiants : masquer systématiquement les bonnes réponses et explications
    if (role === 'ETUDIANT' || (!role && role !== 'ADMIN' && tentative.quiz?.enseignantId !== userId)) {
      return {
        ...tentative,
        quiz: tentative.quiz
          ? {
              ...tentative.quiz,
              questions: tentative.quiz.questions?.map((q: any) => ({
                id: q.id,
                enonce: q.enonce,
                type: q.type,
                points: q.points,
                ordre: q.ordre,
                options: q.options?.map((opt: any) => ({
                  id: opt.id,
                  texte: opt.texte,
                })),
              })),
            }
          : undefined,
      };
    }

    return tentative;
  }
}

export const attemptService = new AttemptService();

