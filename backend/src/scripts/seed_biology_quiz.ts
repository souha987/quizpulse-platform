import { PrismaClient, StatutQuiz, TypeQuestion } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Qurio Biology Exam Quiz...');

  const teacher = await prisma.utilisateur.findFirst({
    where: { role: 'ENSEIGNANT' },
  });

  if (!teacher) {
    console.error('Aucun enseignant trouvé');
    return;
  }

  // Créer ou récupérer la matière Biologie
  let matiere = await prisma.matiere.findFirst({
    where: { nom: 'Biologie Cellulaire & Génétique' },
  });

  if (!matiere) {
    matiere = await prisma.matiere.create({
      data: {
        nom: 'Biologie Cellulaire & Génétique',
        description: 'Licence Sciences de la Vie & Santé',
        enseignantId: teacher.id,
      },
    });
  }

  // Créer ou récupérer une catégorie
  let categorie = await prisma.categorie.findFirst({
    where: { matiereId: matiere.id },
  });

  if (!categorie) {
    categorie = await prisma.categorie.create({
      data: {
        nom: 'Biologie Cellulaire',
        matiereId: matiere.id,
      },
    });
  }

  // Supprimer un ancien quiz avec le code 742000 ou 742123 s'il existe
  await prisma.quiz.deleteMany({
    where: {
      codeAcces: { in: ['742000', '742123', '742999'] },
    },
  });

  // Créer le quiz exact de l'Image 3 avec 15 questions
  const quiz = await prisma.quiz.create({
    data: {
      titre: 'Licence Biologie • Session Officielle 2025',
      description: 'Surveillance biométrique & proctoring synchronisée. Détection de changement d\'onglet active.',
      estPublic: true,
      statut: StatutQuiz.PUBLIE,
      dureeMinutes: 30,
      codeAcces: '742000',
      modeExamenSecurise: true,
      enseignantId: teacher.id,
      categorieId: categorie.id,
      questions: {
        create: [
          {
            ordre: 1,
            enonce: 'Quelle est la principale fonction de la membrane plasmique ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 1.0,
            explicationCorrection: 'La membrane plasmique régule les échanges entre le milieu intracellulaire et extracellulaire.',
            options: {
              create: [
                { texte: 'Régulation des échanges cellulaires\nPerméabilité sélective et barrière hydrophobe.', estCorrecte: true },
                { texte: 'Synthèse des ribosomes\nActivité localisée dans le nucléole.', estCorrecte: false },
                { texte: 'Production exclusive de glucose\nActivité réalisée par les chloroplastes végétaux.', estCorrecte: false },
                { texte: 'Stockage principal de l\'ADN\nFonction du noyau eucaryote.', estCorrecte: false },
              ],
            },
          },
          {
            ordre: 2,
            enonce: 'La transcription de l\'ADN en ARN messager a lieu dans le cytosol chez les eucaryotes.',
            type: TypeQuestion.VRAI_FAUX,
            points: 1.0,
            explicationCorrection: 'Faux : chez les eucaryotes, la transcription s\'effectue à l\'intérieur du noyau.',
            options: {
              create: [
                { texte: 'Vrai', estCorrecte: false },
                { texte: 'Faux', estCorrecte: true },
              ],
            },
          },
          {
            ordre: 3,
            enonce: 'Quelles bases azotées composent l\'ARN ?',
            type: TypeQuestion.QCM_MULTIPLE,
            points: 2.0,
            explicationCorrection: 'L\'ARN est composé d\'Adénine, Uracile, Cytosine et Guanine (la Thymine est spécifique à l\'ADN).',
            options: {
              create: [
                { texte: 'Adénine (A)', estCorrecte: true },
                { texte: 'Uracile (U)', estCorrecte: true },
                { texte: 'Cytosine (C)', estCorrecte: true },
                { texte: 'Thymine (T)', estCorrecte: false },
              ],
            },
          },
          {
            ordre: 4,
            enonce: 'Quel organite cellulaire est responsable de la production principale d\'ATP via le mécanisme de phosphorylation oxydative dans les cellules eucaryotes ?',
            type: TypeQuestion.QCM_UNIQUE,
            points: 2.0,
            explicationCorrection: 'La mitochondrie est la centrale énergétique cellulaire où se déroule la phosphorylation oxydative.',
            options: {
              create: [
                { texte: 'L\'appareil de Golgi\nTri, maturation et adressage des protéines et lipides membranaires.', estCorrecte: false },
                { texte: 'La mitochondrie\nCentrale énergétique assurant le cycle de Krebs et la phosphorylation oxydative.', estCorrecte: true },
                { texte: 'Le réticulum endoplasmique granuleux (REG)\nSynthèse peptidique par ribosomes associés et contrôle de conformation.', estCorrecte: false },
                { texte: 'Le peroxysome\nDétoxification du peroxyde d\'hydrogène et bêta-oxydation d\'acides gras spécifiques.', estCorrecte: false },
              ],
            },
          },
          // Questions 5 à 15 pour correspondre aux 15 questions du panneau
          ...Array.from({ length: 11 }, (_, i) => ({
            ordre: 5 + i,
            enonce: `Question ${5 + i} : Propriété structurale et fonctionnelle des macromolécules cellulaires (Partie ${i + 1})`,
            type: TypeQuestion.QCM_UNIQUE,
            points: 1.5,
            explicationCorrection: 'Explication scientifique détaillée de référence.',
            options: {
              create: [
                { texte: 'Hypothèse biologique A\nValidation expérimentale in vitro.', estCorrecte: i % 2 === 0 },
                { texte: 'Hypothèse biologique B\nIncompatibilité thermodynamique.', estCorrecte: i % 2 !== 0 },
                { texte: 'Hypothèse biologique C\nRégulation allostérique négative.', estCorrecte: false },
                { texte: 'Hypothèse biologique D\nCinétique enzymatique michaelienne.', estCorrecte: false },
              ],
            },
          })),
        ],
      },
    },
  });

  console.log(`Quiz créé avec succès ! ID: ${quiz.id}, Code PIN: ${quiz.codeAcces}`);
}

main()
  .catch((e) => console.error(e))
  .finally(() => prisma.$disconnect());

