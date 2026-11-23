import { AttemptService } from '../src/services/attempt.service';
import { attemptRepository } from '../src/repositories/attempt.repository';
import { analyticsService } from '../src/services/analytics.service';
import { prisma } from '../src/config/prisma';
import { TypeQuestion, StatutTentative } from '@prisma/client';

describe('QA Tests - Moteur de Notation et Gestion du Temps', () => {
  let attemptService: AttemptService;

  beforeEach(() => {
    attemptService = new AttemptService();
    jest.clearAllMocks();
  });

  it('doit marquer la tentative comme EXPIREE si le temps dépasse la durée impartie + 15s de marge', async () => {
    const dureeMinutes = 10;
    // Date début il y a 10 minutes et 20 secondes (soit 620 secondes, supérieur à 600s + 15s)
    const dateDebutPasse = new Date(Date.now() - (dureeMinutes * 60 * 1000 + 20000));

    const mockTentative = {
      id: 'tentative-123',
      dateDebut: dateDebutPasse,
      statut: StatutTentative.EN_COURS,
      nbAvertissementsTriche: 0,
      quiz: {
        id: 'quiz-1',
        dureeMinutes,
        questions: [
          {
            id: 'q1',
            enonce: 'Question 1',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            options: [
              { id: 'opt1', texte: 'A', estCorrecte: true },
              { id: 'opt2', texte: 'B', estCorrecte: false },
            ],
          },
        ],
      },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentative as any);
    const finishAttemptSpy = jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-123',
      score: 2.0,
      statut: StatutTentative.EXPIREE,
      nbAvertissementsTriche: 0,
    } as any);

    const result = await attemptService.submitAttempt('tentative-123', [
      { questionId: 'q1', optionId: 'opt1' },
    ]);

    expect(result.estExpiree).toBe(true);
    expect(result.statut).toBe(StatutTentative.EXPIREE);
    expect(finishAttemptSpy).toHaveBeenCalledWith(
      'tentative-123',
      expect.objectContaining({
        statut: StatutTentative.EXPIREE,
      })
    );
  });

  it('doit enregistrer le statut EXPIREE lorsque clientEstExpiree est vrai', async () => {
    const mockTentative = {
      id: 'tentative-client-expiree',
      dateDebut: new Date(), // Tout juste démarrée
      statut: StatutTentative.EN_COURS,
      nbAvertissementsTriche: 0,
      quiz: {
        id: 'quiz-1',
        dureeMinutes: 10,
        questions: [],
      },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentative as any);
    const finishAttemptSpy = jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-client-expiree',
      score: 0,
      statut: StatutTentative.EXPIREE,
      nbAvertissementsTriche: 0,
    } as any);

    const result = await attemptService.submitAttempt(
      'tentative-client-expiree',
      [],
      undefined,
      undefined,
      true // clientEstExpiree = true
    );

    expect(result.estExpiree).toBe(true);
    expect(result.statut).toBe(StatutTentative.EXPIREE);
    expect(finishAttemptSpy).toHaveBeenCalledWith(
      'tentative-client-expiree',
      expect.objectContaining({
        statut: StatutTentative.EXPIREE,
      })
    );
  });

  it('doit valider et attribuer la note correcte pour un QCM_UNIQUE', async () => {
    const mockTentative = {
      id: 'tentative-normal',
      dateDebut: new Date(Date.now() - 60000), // il y a 1 minute
      statut: StatutTentative.EN_COURS,
      nbAvertissementsTriche: 0,
      quiz: {
        id: 'quiz-1',
        dureeMinutes: 15,
        questions: [
          {
            id: 'q1',
            enonce: 'Quel est le protocole web ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.5,
            explicationCorrection: 'Explication HTTP',
            options: [
              { id: 'opt-good', texte: 'HTTP', estCorrecte: true },
              { id: 'opt-bad', texte: 'FTP', estCorrecte: false },
            ],
          },
        ],
      },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentative as any);
    jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-normal',
      score: 2.5,
      statut: StatutTentative.TERMINEE,
      nbAvertissementsTriche: 0,
    } as any);

    const result = await attemptService.submitAttempt('tentative-normal', [
      { questionId: 'q1', optionId: 'opt-good' },
    ]);

    expect(result.estExpiree).toBe(false);
    expect(result.statut).toBe(StatutTentative.TERMINEE);
    expect(result.score).toBe(2.5);
    expect(result.noteSur20).toBe(20);
    expect(result.corrige[0].estCorrecte).toBe(true);
    expect(result.corrige[0].explicationCorrection).toBe('Explication HTTP');
  });

  it('doit valider correctement un QCM_MULTIPLE avec sélection multiple stricte', async () => {
    const mockTentative = {
      id: 'tentative-multiple',
      dateDebut: new Date(Date.now() - 30000),
      statut: StatutTentative.EN_COURS,
      nbAvertissementsTriche: 0,
      quiz: {
        id: 'quiz-2',
        dureeMinutes: 15,
        questions: [
          {
            id: 'qm',
            enonce: 'Sélectionnez les codes succès',
            type: TypeQuestion.QCM_MULTIPLE,
            points: 4.0,
            options: [
              { id: 'opt-200', texte: '200', estCorrecte: true },
              { id: 'opt-201', texte: '201', estCorrecte: true },
              { id: 'opt-404', texte: '404', estCorrecte: false },
            ],
          },
        ],
      },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentative as any);
    jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-multiple',
      score: 4.0,
      statut: StatutTentative.TERMINEE,
      nbAvertissementsTriche: 0,
    } as any);

    // L'étudiant sélectionne les 2 bonnes options
    const resultSuccess = await attemptService.submitAttempt('tentative-multiple', [
      { questionId: 'qm', optionIds: ['opt-200', 'opt-201'] },
    ]);
    expect(resultSuccess.score).toBe(4.0);
    expect(resultSuccess.corrige[0].estCorrecte).toBe(true);

    // L'étudiant sélectionne une bonne option et une fausse
    jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-multiple',
      score: 0.0,
      statut: StatutTentative.TERMINEE,
      nbAvertissementsTriche: 0,
    } as any);

    const resultFail = await attemptService.submitAttempt('tentative-multiple', [
      { questionId: 'qm', optionIds: ['opt-200', 'opt-404'] },
    ]);
    expect(resultFail.score).toBe(0.0);
    expect(resultFail.corrige[0].estCorrecte).toBe(false);

    // Déduplication des options soumises : un doublon de la même option ne doit pas valider la question
    jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-multiple',
      score: 0.0,
      statut: StatutTentative.TERMINEE,
      nbAvertissementsTriche: 0,
    } as any);

    const resultDuplicateFail = await attemptService.submitAttempt('tentative-multiple', [
      { questionId: 'qm', optionIds: ['opt-200', 'opt-200'] }, // 2 fois la même option
    ]);
    expect(resultDuplicateFail.score).toBe(0.0);
    expect(resultDuplicateFail.corrige[0].estCorrecte).toBe(false);
  });

  it('getTeacherOverview ne doit pas limiter totalSubmissions ni la moyenne générale à 10', async () => {
    // Simuler 15 soumissions
    const countSpy = jest.spyOn(prisma.tentative, 'count').mockResolvedValue(15);
    jest.spyOn(prisma.quiz, 'findMany').mockResolvedValue([{ id: 'q1', statut: 'PUBLIE' }] as any);
    jest.spyOn(prisma.classe, 'findMany').mockResolvedValue([] as any);

    // 10 récentes
    const mockRecent = Array.from({ length: 10 }, (_, i) => ({
      id: `att-${i}`,
      quizId: 'q1',
      quiz: { titre: 'Q1', questions: [{ points: 10 }] },
      score: 8,
      dateFin: new Date(),
      statut: 'TERMINEE',
      utilisateur: { nom: 'Nom', prenom: 'Prenom' },
    }));

    // 15 au total pour le calcul de moyenne (ex: 8/10, soit 16/20)
    const mockAll = Array.from({ length: 15 }, (_, i) => ({
      score: 8,
      quiz: { questions: [{ points: 10 }] },
    }));

    jest.spyOn(prisma.tentative, 'findMany')
      .mockResolvedValueOnce(mockRecent as any) // Pour recentAttempts (take: 10)
      .mockResolvedValueOnce(mockAll as any);    // Pour allFinishedAttempts (toutes les 15)

    const overview = await analyticsService.getTeacherOverview('prof-1');

    expect(countSpy).toHaveBeenCalled();
    expect(overview.totalSubmissions).toBe(15); // PAS limité à 10
    expect(overview.recentSubmissions.length).toBe(10);
    expect(overview.generalAverage).toBe(16.0); // 8/10 ramené sur 20 = 16.0
  });
});

