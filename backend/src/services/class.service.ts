import { classRepository } from '../repositories/class.repository';
import { prisma } from '../config/prisma';
import { AppError } from '../middlewares/error.middleware';

export class ClassService {
  private generateClassCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  async createClass(nom: string, enseignantId: string) {
    const trimmedNom = nom.trim();

    // Règle d'unicité : un enseignant ne peut pas avoir deux classes actives avec le même nom
    const existingClass = await prisma.classe.findFirst({
      where: {
        enseignantId,
        nom: {
          equals: trimmedNom,
          mode: 'insensitive',
        },
        estSupprimee: false,
      },
    });

    if (existingClass) {
      throw new AppError(
        `Une classe avec le nom "${trimmedNom}" existe déjà. Veuillez choisir un autre nom.`,
        409
      );
    }

    const now = new Date();
    const activeSub = await prisma.abonnement.findFirst({
      where: {
        enseignantId,
        statut: 'ACTIF',
        dateFin: { gte: now },
      },
      include: { offre: true },
    });

    const maxClasses = activeSub?.offre?.quotaClasses ?? 2;
    if (maxClasses !== -1) {
      const currentClassCount = await prisma.classe.count({ where: { enseignantId, estSupprimee: false } });
      if (currentClassCount >= maxClasses) {
        throw new AppError(
          `Limite atteinte (${currentClassCount}/${maxClasses} classes). Passez à l'abonnement Pro pour créer des classes virtuelles illimitées.`,
          403
        );
      }
    }

    let codeClasse = this.generateClassCode();
    // Assurer l'unicité
    let existing = await classRepository.findByCode(codeClasse);
    let attempts = 0;
    while (existing && attempts < 5) {
      codeClasse = this.generateClassCode();
      existing = await classRepository.findByCode(codeClasse);
      attempts++;
    }

    return classRepository.create(nom, codeClasse, enseignantId);
  }

  async getTeacherClasses(enseignantId: string) {
    return classRepository.listByTeacher(enseignantId);
  }

  async getClassDetails(classeId: string, userId: string, role: string) {
    const classe = await classRepository.findById(classeId);
    if (!classe) {
      throw new AppError('Classe introuvable', 404);
    }

    if (role === 'ENSEIGNANT' && (classe.enseignantId !== userId || classe.estSupprimee)) {
      throw new AppError('Accès non autorisé ou classe supprimée', 404);
    }

    if (role === 'ETUDIANT') {
      const isMember = await classRepository.isStudentInClass(userId, classeId);
      if (!isMember) {
        throw new AppError('Vous n\'êtes pas inscrit dans cette classe', 403);
      }

      const publishedQuizzes = classe.quizAssignes.filter((q) => q.statut === 'PUBLIE');
      const quizIds = publishedQuizzes.map((q) => q.id);

      const userAttempts = await prisma.tentative.findMany({
        where: {
          utilisateurId: userId,
          quizId: { in: quizIds },
        },
        orderBy: { dateDebut: 'desc' },
      });

      const quizzesWithAttempts = publishedQuizzes.map((q) => {
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

      // Confidentialité des étudiants : suppression de la liste des étudiants et de leurs emails
      const { etudiants, ...classeWithoutStudents } = classe as any;
      return {
        ...classeWithoutStudents,
        nbEtudiants: classe.etudiants?.length ?? 0,
        quizAssignes: quizzesWithAttempts,
      };
    }

    return classe;
  }

  async joinClass(codeClasse: string, etudiantId: string) {
    const classe = await classRepository.findByCode(codeClasse.trim().toUpperCase());
    if (!classe || (classe as any).estSupprimee) {
      throw new AppError('Code classe invalide ou classe clôturée par l\'enseignant', 404);
    }

    const alreadyInClass = await classRepository.isStudentInClass(etudiantId, classe.id);
    if (alreadyInClass) {
      throw new AppError('Vous êtes déjà inscrit dans cette classe', 409);
    }

    await classRepository.joinClass(etudiantId, classe.id);

    return {
      message: 'Inscription réussie à la classe',
      classe: {
        id: classe.id,
        nom: classe.nom,
        codeClasse: classe.codeClasse,
        enseignant: classe.enseignant,
      },
    };
  }

  async leaveClass(classeId: string, etudiantId: string) {
    const isEnrolled = await classRepository.isStudentInClass(etudiantId, classeId);
    if (!isEnrolled) {
      throw new AppError('Vous n\'êtes pas inscrit dans cette classe', 400);
    }
    await classRepository.removeStudent(classeId, etudiantId);
    return { message: 'Vous avez quitté la classe avec succès' };
  }

  async getStudentClasses(etudiantId: string) {
    return classRepository.listByStudent(etudiantId);
  }

  async removeStudentFromClass(classeId: string, etudiantId: string, teacherId: string, role?: string) {
    const classe = await classRepository.findById(classeId);
    if (!classe) {
      throw new AppError('Classe introuvable', 404);
    }

    if (role === 'ENSEIGNANT' && classe.enseignantId !== teacherId) {
      throw new AppError('Non autorisé à modifier cette classe', 403);
    }

    await classRepository.removeStudent(classeId, etudiantId);
    return { message: 'Étudiant retiré de la classe avec succès' };
  }

  async updateClass(classeId: string, nom: string, teacherId: string, role?: string) {
    const classe = await classRepository.findById(classeId);
    if (!classe || classe.estSupprimee) {
      throw new AppError('Classe introuvable ou supprimée', 404);
    }

    if (role === 'ENSEIGNANT' && classe.enseignantId !== teacherId) {
      throw new AppError('Non autorisé à modifier cette classe', 403);
    }

    const trimmedNom = nom.trim();
    // Règle d'unicité : un enseignant ne peut pas avoir deux classes actives avec le même nom
    const duplicate = await prisma.classe.findFirst({
      where: {
        enseignantId: classe.enseignantId,
        id: { not: classeId },
        nom: {
          equals: trimmedNom,
          mode: 'insensitive',
        },
        estSupprimee: false,
      },
    });

    if (duplicate) {
      throw new AppError(
        `Une autre classe avec le nom "${trimmedNom}" existe déjà. Veuillez choisir un autre nom.`,
        409
      );
    }

    return classRepository.update(classeId, { nom: trimmedNom });
  }

  async deleteClass(classeId: string, teacherId: string, role?: string) {
    const classe = await classRepository.findById(classeId);
    if (!classe || classe.estSupprimee) {
      throw new AppError('Classe introuvable ou déjà supprimée', 404);
    }

    if (role === 'ENSEIGNANT' && classe.enseignantId !== teacherId) {
      throw new AppError('Non autorisé à supprimer cette classe', 403);
    }

    await classRepository.delete(classeId);
    return { message: 'Classe supprimée avec succès' };
  }
}

export const classService = new ClassService();

