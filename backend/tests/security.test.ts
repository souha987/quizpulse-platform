import { AttemptService } from '../src/services/attempt.service';
import { QuizService } from '../src/services/quiz.service';
import { ClassService } from '../src/services/class.service';
import { quizRepository } from '../src/repositories/quiz.repository';
import { attemptRepository } from '../src/repositories/attempt.repository';
import { classRepository } from '../src/repositories/class.repository';
import { prisma } from '../src/config/prisma';
import { StatutQuiz, TypeQuestion } from '@prisma/client';

describe('QA Tests - Sécurité Critique & Confidentialité des Réponses', () => {
  let attemptService: AttemptService;

  beforeEach(() => {
    attemptService = new AttemptService();
    jest.clearAllMocks();
    jest.spyOn(attemptRepository, 'findActiveAttempt').mockResolvedValue(null);
    jest.spyOn(prisma.tentative, 'findMany').mockResolvedValue([]);
  });

  it('RÈGLE ABSOLUE : GET /api/quiz/:id/start ne doit JAMAIS renvoyer estCorrecte ni explicationCorrection', async () => {
    const mockQuiz = {
      id: 'quiz-secret-1',
      titre: 'Examen de Sécurité',
      dureeMinutes: 20,
      modeExamenSecurise: true,
      statut: StatutQuiz.PUBLIE,
      estPublic: true,
      questions: [
        {
          id: 'q1',
          enonce: 'Quelle est la clé secrète ?',
          type: TypeQuestion.QCM_UNIQUE,
          points: 5.0,
          ordre: 1,
          explicationCorrection: 'ATTENTION CECI NE DOIT PAS FUIR !',
          options: [
            { id: 'opt1', texte: 'Option A', estCorrecte: true },
            { id: 'opt2', texte: 'Option B', estCorrecte: false },
          ],
        },
      ],
    };

    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockQuiz as any);
    jest.spyOn(attemptRepository, 'createAttempt').mockResolvedValue({
      id: 'tentative-sec-1',
      dateDebut: new Date(),
    } as any);

    // Mock du retour de getQuizForAttempt qui applique le select sécurisé
    jest.spyOn(attemptRepository, 'getQuizForAttempt').mockResolvedValue({
      id: 'quiz-secret-1',
      titre: 'Examen de Sécurité',
      description: null,
      dureeMinutes: 20,
      modeExamenSecurise: true,
      questions: [
        {
          id: 'q1',
          enonce: 'Quelle est la clé secrète ?',
          type: TypeQuestion.QCM_UNIQUE,
          points: 5.0,
          ordre: 1,
          options: [
            { id: 'opt1', texte: 'Option A' },
            { id: 'opt2', texte: 'Option B' },
          ],
        },
      ],
    } as any);

    const result = await attemptService.startQuiz('quiz-secret-1', 'etudiant-1');

    expect(result.quiz).toBeDefined();
    const firstQuestion = result.quiz?.questions[0] as any;
    expect(firstQuestion.explicationCorrection).toBeUndefined();

    const firstOption = firstQuestion.options[0] as any;
    expect(firstOption.estCorrecte).toBeUndefined();
    expect(firstOption.texte).toBe('Option A');
  });

  it('doit bloquer l\'accès au quiz privé si l\'étudiant n\'est pas dans la classe', async () => {
    const mockPrivateQuiz = {
      id: 'quiz-private-classe',
      titre: 'Quiz de Classe Restreint',
      statut: StatutQuiz.PUBLIE,
      estPublic: false,
      classeId: 'classe-specifique',
      enseignantId: 'prof-id-different',
    };

    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockPrivateQuiz as any);

    await expect(
      attemptService.startQuiz('quiz-private-classe', undefined) // Visiteur non connecté
    ).rejects.toThrow('Vous devez être connecté et inscrit dans la classe pour passer ce quiz');
  });

  it('en mode visiteur, startQuiz doit générer et retourner un identifiantSession', async () => {
    const mockPublicQuiz = {
      id: 'quiz-public-1',
      titre: 'Quiz Public Démo',
      dureeMinutes: 10,
      modeExamenSecurise: false,
      statut: StatutQuiz.PUBLIE,
      estPublic: true,
      questions: [],
    };

    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockPublicQuiz as any);
    jest.spyOn(attemptRepository, 'createAttempt').mockImplementation(async (data: any) => ({
      id: 'tentative-anon-1',
      dateDebut: new Date(),
      identifiantSession: data.identifiantSession,
    } as any));
    jest.spyOn(attemptRepository, 'getQuizForAttempt').mockResolvedValue({
      id: 'quiz-public-1',
      titre: 'Quiz Public Démo',
      dureeMinutes: 10,
      questions: [],
    } as any);

    const result = await attemptService.startQuiz('quiz-public-1', undefined);

    expect(result.tentativeId).toBe('tentative-anon-1');
    expect(result.identifiantSession).toBeDefined();
    expect(typeof result.identifiantSession).toBe('string');
    expect(result.identifiantSession).toMatch(/^anon_/);
  });

  it('en mode visiteur, submitAttempt doit valider identifiantSession', async () => {
    const mockTentative = {
      id: 'tentative-visiteur-1',
      dateDebut: new Date(),
      statut: 'EN_COURS',
      utilisateurId: null,
      identifiantSession: 'anon_123456',
      quiz: { dureeMinutes: 15, questions: [] },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentative as any);
    jest.spyOn(attemptRepository, 'finishAttempt').mockResolvedValue({
      id: 'tentative-visiteur-1',
      statut: 'TERMINEE',
    } as any);

    // Échec si session absente ou erronée
    await expect(
      attemptService.submitAttempt('tentative-visiteur-1', [], undefined, 'anon_mauvaise_session')
    ).rejects.toThrow('Session de tentative non valide');

    // Succès avec le bon identifiantSession
    const successResult = await attemptService.submitAttempt(
      'tentative-visiteur-1',
      [],
      undefined,
      'anon_123456'
    );
    expect(successResult).toBeDefined();
    expect(successResult.tentativeId).toBe('tentative-visiteur-1');
  });

  it('au rafraîchissement (F5), startQuiz doit réutiliser la tentative EN_COURS et calculer le temps restant sans créer de doublon', async () => {
    const mockQuiz = {
      id: 'quiz-refresh-test',
      titre: 'Quiz Test Rafraîchissement',
      dureeMinutes: 10,
      modeExamenSecurise: false,
      statut: StatutQuiz.PUBLIE,
      estPublic: true,
      questions: [],
    };

    // Tentative commencée il y a 2 minutes (120 secondes)
    const dateDebut = new Date(Date.now() - 120 * 1000);
    const existingActiveAttempt = {
      id: 'tentative-existante-1',
      quizId: 'quiz-refresh-test',
      utilisateurId: 'etudiant-1',
      statut: 'EN_COURS',
      dateDebut,
      reponses: [],
    };

    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockQuiz as any);
    jest.spyOn(attemptRepository, 'findActiveAttempt').mockResolvedValue(existingActiveAttempt as any);
    const createAttemptSpy = jest.spyOn(attemptRepository, 'createAttempt');
    jest.spyOn(attemptRepository, 'getQuizForAttempt').mockResolvedValue({
      id: 'quiz-refresh-test',
      titre: 'Quiz Test Rafraîchissement',
      dureeMinutes: 10,
      questions: [],
    } as any);

    const result = await attemptService.startQuiz('quiz-refresh-test', 'etudiant-1');

    // Doit renvoyer la tentative existante
    expect(result.tentativeId).toBe('tentative-existante-1');
    // Ne doit PAS créer une nouvelle tentative
    expect(createAttemptSpy).not.toHaveBeenCalled();
    // Le temps restant doit être d'environ 8 minutes (environ 480 secondes, marge +/- 5s)
    expect(result.tempsRestantSecondes).toBeGreaterThanOrEqual(475);
    expect(result.tempsRestantSecondes).toBeLessThanOrEqual(485);
  });

  it('GET /api/quiz/:id doit masquer estCorrecte et explicationCorrection pour un étudiant ou visiteur', async () => {
    const quizService = new QuizService();
    const mockQuiz = {
      id: 'quiz-pub-sec',
      titre: 'Quiz Test Public',
      statut: StatutQuiz.PUBLIE,
      enseignantId: 'prof-owner',
      questions: [
        {
          id: 'q1',
          quizId: 'quiz-pub-sec',
          enonce: 'Énoncé secret',
          type: TypeQuestion.QCM_UNIQUE,
          points: 2,
          ordre: 1,
          explicationCorrection: 'Explication secrète ne devant pas fuiter',
          options: [
            { id: 'opt1', questionId: 'q1', texte: 'Bonne réponse', estCorrecte: true },
            { id: 'opt2', questionId: 'q1', texte: 'Mauvaise réponse', estCorrecte: false },
          ],
        },
      ],
    };

    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockQuiz as any);

    // Requête par un étudiant
    const resultEtudiant = await quizService.getQuizById('quiz-pub-sec', 'etudiant-1', 'ETUDIANT');
    const q1 = resultEtudiant.questions[0] as any;
    expect(q1.explicationCorrection).toBeUndefined();
    expect(q1.options[0].estCorrecte).toBeUndefined();
    expect(q1.options[1].estCorrecte).toBeUndefined();
    expect(q1.options[0].texte).toBe('Bonne réponse');

    // Requête par le prof créateur : a accès à tout
    const resultProf = await quizService.getQuizById('quiz-pub-sec', 'prof-owner', 'ENSEIGNANT');
    const qProf = resultProf.questions[0] as any;
    expect(qProf.explicationCorrection).toBe('Explication secrète ne devant pas fuiter');
    expect(qProf.options[0].estCorrecte).toBe(true);
  });

  it('GET /api/attempts/:id doit interdire la consultation du corrigé tant que la tentative est EN_COURS', async () => {
    const mockTentativeEnCours = {
      id: 'tentative-cours-1',
      statut: 'EN_COURS',
      utilisateurId: 'etudiant-1',
      quiz: { enseignantId: 'prof-1' },
    };

    jest.spyOn(attemptRepository, 'findById').mockResolvedValue(mockTentativeEnCours as any);

    await expect(
      attemptService.getAttemptReview('tentative-cours-1', 'etudiant-1', 'ETUDIANT')
    ).rejects.toThrow('Le corrigé n\'est pas disponible tant que la tentative est en cours');
  });

  it('addQuestion doit rejeter une question sans réponse correcte ou avec plusieurs bonnes réponses en QCM_UNIQUE', async () => {
    const quizService = new QuizService();
    const mockQuiz = {
      id: 'quiz-q-val',
      enseignantId: 'prof-1',
      questions: [],
    };
    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockQuiz as any);

    // Aucune réponse correcte
    await expect(
      quizService.addQuestion(
        'quiz-q-val',
        {
          enonce: 'Question sans bonne réponse',
          type: TypeQuestion.QCM_UNIQUE,
          options: [
            { texte: 'A', estCorrecte: false },
            { texte: 'B', estCorrecte: false },
          ],
        },
        'prof-1'
      )
    ).rejects.toThrow('Une question doit comporter au moins une réponse correcte');

    // Deux réponses correctes pour QCM_UNIQUE
    await expect(
      quizService.addQuestion(
        'quiz-q-val',
        {
          enonce: 'Question avec 2 bonnes réponses',
          type: TypeQuestion.QCM_UNIQUE,
          options: [
            { texte: 'A', estCorrecte: true },
            { texte: 'B', estCorrecte: true },
          ],
        },
        'prof-1'
      )
    ).rejects.toThrow('Une question à choix unique ou vrai/faux ne peut avoir qu\'une seule réponse correcte');
  });

  it('duplicateQuiz doit empêcher un enseignant de dupliquer le quiz d\'un autre enseignant', async () => {
    const quizService = new QuizService();
    const mockOriginal = {
      id: 'quiz-autre-prof',
      titre: 'Quiz de Prof A',
      enseignantId: 'prof-A',
      questions: [],
    };
    jest.spyOn(quizRepository, 'findById').mockResolvedValue(mockOriginal as any);

    await expect(
      quizService.duplicateQuiz('quiz-autre-prof', 'prof-B')
    ).rejects.toThrow('Non autorisé à dupliquer un quiz appartenant à un autre enseignant');
  });

  it('getClassDetails doit masquer la liste des étudiants et leurs e-mails pour un étudiant', async () => {
    const classService = new ClassService();
    const mockClasse = {
      id: 'classe-confid',
      nom: 'Classe Terminale S',
      codeClasse: 'TS2026',
      enseignantId: 'prof-1',
      etudiants: [
        { etudiant: { id: 'e1', nom: 'Dupont', prenom: 'Alice', email: 'alice@dupont.fr' } },
        { etudiant: { id: 'e2', nom: 'Martin', prenom: 'Bob', email: 'bob@martin.fr' } },
      ],
      quizAssignes: [],
    };

    jest.spyOn(classRepository, 'findById').mockResolvedValue(mockClasse as any);
    jest.spyOn(classRepository, 'isStudentInClass').mockResolvedValue(true);

    const result = await classService.getClassDetails('classe-confid', 'e1', 'ETUDIANT');

    // La liste brute des étudiants et leurs emails ne doit pas être transmise
    expect((result as any).etudiants).toBeUndefined();
    // Le nombre d'étudiants doit être transmis
    expect((result as any).nbEtudiants).toBe(2);
  });
});

