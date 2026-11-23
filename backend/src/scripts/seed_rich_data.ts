import { PrismaClient, Role, StatutQuiz, TypeQuestion, StatutTentative } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('=== SEEDING RICH REAL-WORLD DATA (QuizPulse) ===');

  const salt = await bcrypt.genSalt(10);
  const hashPass = (pw: string) => bcrypt.hashSync(pw, salt);

  // 1. UTILISATEURS
  console.log('1. Création des utilisateurs...');
  
  // Élève : Alex Martin (AM)
  const alex = await prisma.utilisateur.upsert({
    where: { email: 'etudiant.alice@edutech.com' },
    update: {
      nom: 'Martin',
      prenom: 'Alex',
      role: Role.ETUDIANT,
    },
    create: {
      nom: 'Martin',
      prenom: 'Alex',
      email: 'etudiant.alice@edutech.com',
      motDePasseHash: hashPass('Etudiant123!'),
      role: Role.ETUDIANT,
    },
  });

  // Enseignant : Claire Dubois (PC)
  const claire = await prisma.utilisateur.upsert({
    where: { email: 'prof.curie@edutech.com' },
    update: {
      nom: 'Dubois',
      prenom: 'Claire',
      role: Role.ENSEIGNANT,
    },
    create: {
      nom: 'Dubois',
      prenom: 'Claire',
      email: 'prof.curie@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  // Enseignant : Prof. David Miller (Maths)
  const miller = await prisma.utilisateur.upsert({
    where: { email: 'prof.miller@edutech.com' },
    update: {},
    create: {
      nom: 'Miller',
      prenom: 'David',
      email: 'prof.miller@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  // Enseignant : Mme Sarah Wilson (Bio)
  const wilson = await prisma.utilisateur.upsert({
    where: { email: 'prof.wilson@edutech.com' },
    update: {},
    create: {
      nom: 'Wilson',
      prenom: 'Sarah',
      email: 'prof.wilson@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  // Enseignant : M. James Carter (Histoire)
  const carter = await prisma.utilisateur.upsert({
    where: { email: 'prof.carter@edutech.com' },
    update: {},
    create: {
      nom: 'Carter',
      prenom: 'James',
      email: 'prof.carter@edutech.com',
      motDePasseHash: hashPass('Prof123!'),
      role: Role.ENSEIGNANT,
    },
  });

  // 2. MATIÈRES & CATÉGORIES
  console.log('2. Création des matières...');
  
  const matMath = await prisma.matiere.upsert({
    where: { id: 'matiere-math-01' },
    update: {},
    create: {
      id: 'matiere-math-01',
      nom: 'Mathématiques',
      description: 'Algèbre, géométrie, analyse et probabilités',
      enseignantId: miller.id,
      categories: {
        create: [{ nom: 'Algèbre & Équations' }, { nom: 'Géométrie' }],
      },
    },
    include: { categories: true },
  });

  const matBio = await prisma.matiere.upsert({
    where: { id: 'matiere-bio-01' },
    update: {},
    create: {
      id: 'matiere-bio-01',
      nom: 'Biologie',
      description: 'Sciences de la vie, cellules et génétique',
      enseignantId: wilson.id,
      categories: {
        create: [{ nom: 'Biologie Cellulaire' }, { nom: 'Génétique' }],
      },
    },
    include: { categories: true },
  });

  const matHist = await prisma.matiere.upsert({
    where: { id: 'matiere-hist-01' },
    update: {},
    create: {
      id: 'matiere-hist-01',
      nom: 'Histoire',
      description: 'Histoire médiévale, moderne et contemporaine',
      enseignantId: carter.id,
      categories: {
        create: [{ nom: 'Renaissance' }, { nom: 'Temps Modernes' }],
      },
    },
    include: { categories: true },
  });

  // 3. CLASSES
  console.log('3. Création des classes...');
  
  const classeMath = await prisma.classe.upsert({
    where: { codeClasse: 'MATH24' },
    update: {},
    create: {
      nom: 'Mathématiques',
      codeClasse: 'MATH24',
      enseignantId: miller.id,
    },
  });

  const classeBio = await prisma.classe.upsert({
    where: { codeClasse: 'BIO24' },
    update: {},
    create: {
      nom: 'Biologie',
      codeClasse: 'BIO24',
      enseignantId: wilson.id,
    },
  });

  const classeHist = await prisma.classe.upsert({
    where: { codeClasse: 'HIST24' },
    update: {},
    create: {
      nom: 'Histoire',
      codeClasse: 'HIST24',
      enseignantId: carter.id,
    },
  });

  // Inscrire Alex Martin dans les 3 classes
  for (const c of [classeMath, classeBio, classeHist]) {
    await prisma.etudiantClasse.upsert({
      where: {
        etudiantId_classeId: {
          etudiantId: alex.id,
          classeId: c.id,
        },
      },
      update: {},
      create: {
        etudiantId: alex.id,
        classeId: c.id,
      },
    });
  }

  // 4. QUIZ
  console.log('4. Création des quiz...');

  // Quiz 1 : Algèbre
  const quizAlgebre = await prisma.quiz.upsert({
    where: { codeAcces: 'MATH01' },
    update: {},
    create: {
      titre: 'Algèbre : équations et expressions',
      description: 'Développements, factorisations et résolution d\'équations du premier et second degré.',
      estPublic: true,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 25,
      codeAcces: 'MATH01',
      modeExamenSecurise: false,
      enseignantId: miller.id,
      classeId: classeMath.id,
      categorieId: matMath.categories[0].id,
      questions: {
        create: [
          {
            enonce: 'Quelle est la solution de l\'équation 2x + 6 = 14 ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            ordre: 1,
            explicationCorrection: '2x = 14 - 6 = 8, donc x = 4.',
            options: {
              create: [
                { texte: 'x = 4', estCorrecte: true },
                { texte: 'x = 3', estCorrecte: false },
                { texte: 'x = 5', estCorrecte: false },
                { texte: 'x = 8', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'L\'expression (a + b)² est égale à a² + 2ab + b².',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            ordre: 2,
            explicationCorrection: 'Vrai : C\'est la première identité remarquable.',
            options: {
              create: [
                { texte: 'Vrai', estCorrecte: true },
                { texte: 'Faux', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Quelles sont les solutions de l\'équation x² - 9 = 0 ?',
            type: TypeQuestion.QCM_MULTIPLE,
            points: 2.0,
            ordre: 3,
            explicationCorrection: 'x² = 9 donne x = 3 ou x = -3.',
            options: {
              create: [
                { texte: 'x = 3', estCorrecte: true },
                { texte: 'x = -3', estCorrecte: true },
                { texte: 'x = 0', estCorrecte: false },
                { texte: 'x = 9', estCorrecte: false },
              ],
            },
          },
        ],
      },
    },
    include: { questions: { include: { options: true } } },
  });

  // Quiz 2 : Biologie
  const quizBio = await prisma.quiz.upsert({
    where: { codeAcces: 'BIO001' },
    update: {},
    create: {
      titre: 'Le monde des cellules vivantes',
      description: 'Structure cellulaire, organites, membranes et respiration cellulaire.',
      estPublic: true,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 30,
      codeAcces: 'BIO001',
      modeExamenSecurise: false,
      enseignantId: wilson.id,
      classeId: classeBio.id,
      categorieId: matBio.categories[0].id,
      questions: {
        create: [
          {
            enonce: 'Quel organite est souvent qualifié de "centrale énergétique" de la cellule ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            ordre: 1,
            explicationCorrection: 'La mitochondrie produit l\'ATP par respiration cellulaire.',
            options: {
              create: [
                { texte: 'La mitochondrie', estCorrecte: true },
                { texte: 'Le noyau', estCorrecte: false },
                { texte: 'L\'appareil de Golgi', estCorrecte: false },
                { texte: 'Le ribosome', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Les cellules végétales possèdent une paroi cellulosique et des chloroplastes.',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            ordre: 2,
            explicationCorrection: 'Vrai : ce sont des caractéristiques distinctives des cellules végétales.',
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
    include: { questions: { include: { options: true } } },
  });

  // Quiz 3 : Renaissance
  const quizHist = await prisma.quiz.upsert({
    where: { codeAcces: 'HIST01' },
    update: {},
    create: {
      titre: 'Voyage à travers la Renaissance',
      description: 'L\'essor artistique, scientifique et philosophique du XVe et XVIe siècle en Europe.',
      estPublic: true,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 20,
      codeAcces: 'HIST01',
      modeExamenSecurise: false,
      enseignantId: carter.id,
      classeId: classeHist.id,
      categorieId: matHist.categories[0].id,
      questions: {
        create: [
          {
            enonce: 'Dans quelle ville italienne la Renaissance a-t-elle principalement pris son essor ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            ordre: 1,
            explicationCorrection: 'Florence a été le foyer culturel et financier majeur de la Renaissance.',
            options: {
              create: [
                { texte: 'Florence', estCorrecte: true },
                { texte: 'Rome', estCorrecte: false },
                { texte: 'Venise', estCorrecte: false },
                { texte: 'Milan', estCorrecte: false },
              ],
            },
          },
          {
            enonce: 'Léonard de Vinci a peint La Joconde.',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            ordre: 2,
            explicationCorrection: 'Vrai : Chef-d\'œuvre exposé au musée du Louvre.',
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
    include: { questions: { include: { options: true } } },
  });

  // 5. TENTATIVES POUR ALEX MARTIN (Historique & Résultats réels)
  console.log('5. Création des tentatives pour Alex Martin...');

  // Tentative 1 : Algèbre 100% (score: 5/5)
  await prisma.tentative.create({
    data: {
      utilisateurId: alex.id,
      quizId: quizAlgebre.id,
      dateDebut: new Date(Date.now() - 3600 * 1000 * 24 * 2),
      dateFin: new Date(Date.now() - 3600 * 1000 * 24 * 2 + 12 * 60 * 1000),
      score: 5.0,
      statut: StatutTentative.TERMINEE,
      reponses: {
        create: quizAlgebre.questions.map(q => {
          const correctOpt = q.options.find(o => o.estCorrecte);
          return {
            questionId: q.id,
            optionId: correctOpt?.id,
            estCorrecte: true,
            pointsObtenus: q.points,
          };
        }),
      },
    },
  });

  // Tentative 2 : Algèbre 33% (score: 1.65/5)
  await prisma.tentative.create({
    data: {
      utilisateurId: alex.id,
      quizId: quizAlgebre.id,
      dateDebut: new Date(Date.now() - 3600 * 1000 * 24 * 5),
      dateFin: new Date(Date.now() - 3600 * 1000 * 24 * 5 + 8 * 60 * 1000),
      score: 1.65,
      statut: StatutTentative.TERMINEE,
      reponses: {
        create: quizAlgebre.questions.map((q, idx) => {
          const opt = idx === 0 ? q.options.find(o => o.estCorrecte) : q.options.find(o => !o.estCorrecte);
          return {
            questionId: q.id,
            optionId: opt?.id,
            estCorrecte: idx === 0,
            pointsObtenus: idx === 0 ? q.points : 0,
          };
        }),
      },
    },
  });

  // Tentative 3 : Biologie 85% (score: 2.55/3)
  await prisma.tentative.create({
    data: {
      utilisateurId: alex.id,
      quizId: quizBio.id,
      dateDebut: new Date(Date.now() - 3600 * 1000 * 24 * 1),
      dateFin: new Date(Date.now() - 3600 * 1000 * 24 * 1 + 15 * 60 * 1000),
      score: 2.55,
      statut: StatutTentative.TERMINEE,
      reponses: {
        create: quizBio.questions.map(q => {
          const correctOpt = q.options.find(o => o.estCorrecte);
          return {
            questionId: q.id,
            optionId: correctOpt?.id,
            estCorrecte: true,
            pointsObtenus: q.points,
          };
        }),
      },
    },
  });

  // Tentative 4 : Renaissance 72%
  await prisma.tentative.create({
    data: {
      utilisateurId: alex.id,
      quizId: quizHist.id,
      dateDebut: new Date(Date.now() - 3600 * 1000 * 4),
      dateFin: new Date(Date.now() - 3600 * 1000 * 4 + 11 * 60 * 1000),
      score: 2.16,
      statut: StatutTentative.TERMINEE,
      reponses: {
        create: quizHist.questions.map(q => {
          const correctOpt = q.options.find(o => o.estCorrecte);
          return {
            questionId: q.id,
            optionId: correctOpt?.id,
            estCorrecte: true,
            pointsObtenus: q.points,
          };
        }),
      },
    },
  });

  console.log('=== SEED TERMINÉ AVEC SUCCÈS ! ===');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
