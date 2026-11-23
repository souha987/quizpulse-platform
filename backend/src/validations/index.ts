import { z } from 'zod';
import { Role, StatutQuiz, TypeQuestion } from '@prisma/client';

export const registerSchema = z.object({
  nom: z.string().min(2, 'Le nom doit contenir au moins 2 caractères'),
  prenom: z.string().min(2, 'Le prénom doit contenir au moins 2 caractères'),
  email: z.string().email('Format d\'email invalide'),
  motDePasse: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
  role: z.nativeEnum(Role).optional(),
});

export const loginSchema = z.object({
  email: z.string().email('Format d\'email invalide'),
  motDePasse: z.string().min(1, 'Le mot de passe est requis'),
});

export const verifyEmailSchema = z.object({
  email: z.string().email('Format d\'email invalide'),
  code: z.string().min(4, 'Le code de vérification est requis'),
  registrationToken: z.string().optional(),
});

export const resendVerificationSchema = z.object({
  email: z.string().email('Format d\'email invalide'),
  registrationToken: z.string().optional(),
});

export const createClassSchema = z.object({
  nom: z.string().min(3, 'Le nom de la classe doit comporter au moins 3 caractères'),
});

export const updateClassSchema = z.object({
  nom: z.string().min(3, 'Le nom de la classe doit comporter au moins 3 caractères'),
});

export const joinClassSchema = z.object({
  codeClasse: z.string().min(4, 'Code de classe invalide').max(10),
});

export const createQuizSchema = z.object({
  titre: z.string().min(3, 'Le titre doit comporter au moins 3 caractères'),
  description: z.string().optional(),
  estPublic: z.boolean().default(false),
  statut: z.nativeEnum(StatutQuiz).optional(),
  dureeMinutes: z.number().int().min(1).max(180).default(15),
  modeExamenSecurise: z.boolean().default(false),
  categorieId: z.string().uuid().optional(),
  classeId: z.string().uuid().optional(),
});

export const updateQuizSchema = z.object({
  titre: z.string().min(3).optional(),
  description: z.string().optional(),
  estPublic: z.boolean().optional(),
  statut: z.nativeEnum(StatutQuiz).optional(),
  dureeMinutes: z.number().int().min(1).max(180).optional(),
  modeExamenSecurise: z.boolean().optional(),
  categorieId: z.string().uuid().nullable().optional(),
  classeId: z.string().uuid().nullable().optional(),
});

export const createQuestionSchema = z.object({
  enonce: z.string().min(3, 'L\'énoncé doit comporter au moins 3 caractères'),
  type: z.nativeEnum(TypeQuestion).default(TypeQuestion.QCM_UNIQUE),
  points: z.number().min(0.5).default(1.0),
  ordre: z.number().int().optional(),
  explicationCorrection: z.string().optional(),
  options: z.array(
    z.object({
      texte: z.string().min(1, 'Le texte de l\'option est requis'),
      estCorrecte: z.boolean().default(false),
    })
  ).min(2, 'Une question doit comporter au moins 2 options'),
});

export const submitAttemptSchema = z.object({
  identifiantSession: z.string().optional(),
  reponses: z.array(
    z.object({
      questionId: z.string(),
      optionId: z.string().optional(),
      optionIds: z.array(z.string()).optional(),
      reponseTexte: z.string().optional(),
    })
  ),
});

export const reorderQuestionsSchema = z.object({
  questions: z.array(
    z.object({
      questionId: z.string(),
      ordre: z.number().int(),
    })
  ).min(1),
});

