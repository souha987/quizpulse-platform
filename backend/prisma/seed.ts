import { PrismaClient, Role, StatutQuiz, TypeQuestion } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Début du peuplement de la base de données (Seed) ---');

  // 1. Offres d'abonnement
  console.log('Création des offres d\'abonnement...');
  const offreGratuite = await prisma.offreAbonnement.create({
    data: {
      nom: 'Formule Découverte (Gratuit)',
      prix: 0.0,
      dureeJours: 365,
      quotaQuiz: 5,
      quotaClasses: 2,
      modeSecuriseAutorise: false,
      active: true,
    },
  });

  const offrePro = await prisma.offreAbonnement.create({
    data: {
      nom: 'Enseignant Pro (Illimité)',
      prix: 9.99,
      dureeJours: 30,
      quotaQuiz: -1, // -1 = illimité
      quotaClasses: -1,
      modeSecuriseAutorise: true,
      active: true,
    },
  });

  // 2. Utilisateurs
  console.log('Création des utilisateurs de test...');
  const salt = await bcrypt.genSalt(10);
  const hashPass = (pw: string) => bcrypt.hashSync(pw, salt);

  const admin = await prisma.utilisateur.create({
    data: {
      nom: 'System',
      prenom: 'Admin',
      email: 'admin@edutech.com',
      motDePasseHash: hashPass('Admin123!'),
      role: Role.ADMIN,
    },
  });

  const profGratuit = await prisma.utilisateur.create({
    data: {
      nom: 'Dupont',
      prenom: 'Jean',
      email: 'prof.dupont@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  const profPro = await prisma.utilisateur.create({
    data: {
      nom: 'Curie',
      prenom: 'Marie',
      email: 'prof.curie@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  // Abonnement actif pour le prof Pro
  const dateDebut = new Date();
  const dateFin = new Date();
  dateFin.setDate(dateFin.getDate() + 30);

  const subPro = await prisma.abonnement.create({
    data: {
      enseignantId: profPro.id,
      offreId: offrePro.id,
      dateDebut,
      dateFin,
      statut: 'ACTIF',
    },
  });

  await prisma.paiement.create({
    data: {
      abonnementId: subPro.id,
      reference: 'ch_stripe_mock_seed_123',
      montant: 9.99,
      methode: 'carte_bancaire',
      statut: 'VALIDE',
    },
  });

  const etudiantAlice = await prisma.utilisateur.create({
    data: {
      nom: 'Martin',
      prenom: 'Alice',
      email: 'etudiant.alice@edutech.com',
      motDePasseHash: hashPass('Etudiant123!'),
      role: Role.ETUDIANT,
    },
  });

  const etudiantBob = await prisma.utilisateur.create({
    data: {
      nom: 'Bernard',
      prenom: 'Bob',
      email: 'etudiant.bob@edutech.com',
      motDePasseHash: hashPass('Etudiant123!'),
      role: Role.ETUDIANT,
    },
  });

  // 3. Matieres et Catégories
  console.log('Création des matières et catégories...');
  const matiereInfo = await prisma.matiere.create({
    data: {
      nom: 'Informatique & Technologies',
      description: 'Programmation, architectures web et réseaux',
      enseignantId: profPro.id,
      categories: {
        create: [
          { nom: 'Développement Web' },
          { nom: 'Cybersécurité & Réseaux' },
        ],
      },
    },
    include: { categories: true },
  });

  const matiereSciences = await prisma.matiere.create({
    data: {
      nom: 'Sciences Fondamentales',
      description: 'Mathématiques et sciences expérimentales',
      enseignantId: profGratuit.id,
      categories: {
        create: [
          { nom: 'Culture Scientifique' },
          { nom: 'Mathématiques Appliquées' },
        ],
      },
    },
    include: { categories: true },
  });

  // 4. Classes
  console.log('Création des classes...');
  const classeWeb = await prisma.classe.create({
    data: {
      nom: 'Promo Dev Web FullStack 2026',
      codeClasse: 'WEB202',
      enseignantId: profPro.id,
      etudiants: {
        create: [
          { etudiantId: etudiantAlice.id },
          { etudiantId: etudiantBob.id },
        ],
      },
    },
  });

  // 5. Quiz Démo Public (accessible sans compte par code PIN 123456 ou depuis le catalogue)
  console.log('Création du quiz démo public...');
  const quizPublic = await prisma.quiz.create({
    data: {
      titre: 'Quiz Démo : Culture Numérique & Web Moderne',
      description: 'Testez vos connaissances sur les protocoles web, HTTP et les technologies cloud.',
      estPublic: true,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 10,
      codeAcces: '123456',
      modeExamenSecurise: false,
      enseignantId: profPro.id,
      categorieId: matiereInfo.categories[0].id,
      questions: {
        create: [
          {
            enonce: 'Que signifie l\'acronyme HTTP ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            ordre: 1,
            explicationCorrection: 'HTTP signifie HyperText Transfer Protocol, le protocole fondamental du Web.',
            options: {
              create: [
                { texte: 'HyperText Transfer Protocol', estCorrecte: true },
                { texte: 'High Transfer Technical Platform', estCorrecte: false },
                { texte: 'Hyper Tool Typing Program', estCorrecte: false },
                { texte: 'Home Terminal Test Protocol', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Le protocole HTTPS crypte les communications à l\'aide de TLS/SSL.',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            ordre: 2,
            explicationCorrection: 'Vrai : HTTPS utilise le protocole TLS pour chiffrer les échanges entre le client et le serveur.',
            options: {
              create: [
                { texte: 'Vrai', estCorrecte: true },
                { texte: 'Faux', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Quels codes de statut HTTP indiquent un succès (réponse 2xx) ?',
            type: TypeQuestion.QCM_MULTIPLE,
            points: 3.0,
            ordre: 3,
            explicationCorrection: 'Les codes 200 (OK) et 201 (Created) sont des codes de succès 2xx.',
            options: {
              create: [
                { texte: '200 OK', estCorrecte: true },
                { texte: '201 Created', estCorrecte: true },
                { texte: '404 Not Found', estCorrecte: false },
                { texte: '500 Internal Server Error', estCorrecte: false },
              ],
            },
          },
        ],
      },
    },
  });

  // 6. Quiz Examen Sécurisé pour la Classe
  console.log('Création du quiz examen sécurisé...');
  const quizExamen = await prisma.quiz.create({
    data: {
      titre: 'Examen Final : Architecture & Sécurité Web',
      description: 'Évaluation sommative sous surveillance active. Le changement d\'onglet est surveillé et sanctionné.',
      estPublic: false,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 15,
      codeAcces: '654321',
      modeExamenSecurise: true,
      enseignantId: profPro.id,
      classeId: classeWeb.id,
      categorieId: matiereInfo.categories[1].id,
      questions: {
        create: [
          {
            enonce: 'Quelle faille de sécurité consiste à injecter des scripts malveillants exécutés côté navigateur ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            ordre: 1,
            explicationCorrection: 'XSS (Cross-Site Scripting) permet d\'exécuter du JavaScript arbitraire dans le navigateur de la victime.',
            options: {
              create: [
                { texte: 'Cross-Site Scripting (XSS)', estCorrecte: true },
                { texte: 'SQL Injection (SQLi)', estCorrecte: false },
                { texte: 'Denial of Service (DoS)', estCorrecte: false },
                { texte: 'Man In The Middle (MITM)', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Le header HTTP "Content-Security-Policy" (CSP) aide à atténuer les attaques XSS.',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            ordre: 2,
            explicationCorrection: 'Vrai : CSP restreint les sources fiables pour les scripts, images et styles.',
            options: {
              create: [
                { texte: 'Vrai', estCorrecte: true },
                { texte: 'Faux', estCorrecte: false },
              ],
            },
          },
        ],
      },
    },
  });

  console.log('--- Peuplement terminé avec succès ! ---');
  console.log(`Comptes de test :`);
  console.log(`- Admin       : admin@edutech.com / Admin123!`);
  console.log(`- Prof Pro    : prof.curie@edutech.com / Prof123!`);
  console.log(`- Prof Free   : prof.dupont@edutech.com / Prof123!`);
  console.log(`- Étudiant 1  : etudiant.alice@edutech.com / Etudiant123!`);
  console.log(`- Étudiant 2  : etudiant.bob@edutech.com / Etudiant123!`);
  console.log(`Quiz Demo PIN : 123456 (Public)`);
  console.log(`Quiz Exam PIN : 654321 (Sécurisé)`);
}

main()
  .catch((e) => {
    console.error('Erreur lors du seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

