import { prisma } from '../config/prisma';
import { Classe } from '@prisma/client';

export class ClassRepository {
  async create(nom: string, codeClasse: string, enseignantId: string): Promise<Classe> {
    return prisma.classe.create({
      data: {
        nom,
        codeClasse: codeClasse.toUpperCase(),
        enseignantId,
      },
    });
  }

  async findByCode(codeClasse: string) {
    return prisma.classe.findFirst({
      where: {
        codeClasse: codeClasse.toUpperCase(),
        estSupprimee: false,
      },
      include: {
        enseignant: {
          select: { id: true, nom: true, prenom: true },
        },
      },
    });
  }

  async findById(id: string) {
    return prisma.classe.findUnique({
      where: { id },
      include: {
        enseignant: {
          select: { id: true, nom: true, prenom: true, email: true },
        },
        etudiants: {
          include: {
            etudiant: {
              select: { id: true, nom: true, prenom: true, email: true, dateInscription: true },
            },
          },
          orderBy: { dateRejoint: 'desc' },
        },
        quizAssignes: {
          select: {
            id: true,
            titre: true,
            description: true,
            dureeMinutes: true,
            statut: true,
            modeExamenSecurise: true,
            codeAcces: true,
            dateCreation: true,
            _count: {
              select: {
                questions: true,
                tentatives: true,
              },
            },
          },
          orderBy: { dateCreation: 'desc' },
        },
      },
    });
  }

  async listByTeacher(enseignantId: string) {
    return prisma.classe.findMany({
      where: {
        enseignantId,
        estSupprimee: false,
      },
      include: {
        _count: {
          select: {
            etudiants: true,
            quizAssignes: true,
          },
        },
      },
      orderBy: { dateCreation: 'desc' },
    });
  }

  async listByStudent(etudiantId: string) {
    return prisma.etudiantClasse.findMany({
      where: { etudiantId },
      include: {
        classe: {
          include: {
            enseignant: {
              select: { id: true, nom: true, prenom: true },
            },
            quizAssignes: {
              where: { statut: 'PUBLIE' },
              select: {
                id: true,
                titre: true,
                description: true,
                dureeMinutes: true,
                modeExamenSecurise: true,
                codeAcces: true,
              },
            },
            _count: {
              select: { etudiants: true },
            },
          },
        },
      },
      orderBy: { dateRejoint: 'desc' },
    });
  }

  async joinClass(etudiantId: string, classeId: string) {
    return prisma.etudiantClasse.create({
      data: {
        etudiantId,
        classeId,
      },
    });
  }

  async removeStudent(classeId: string, etudiantId: string) {
    return prisma.etudiantClasse.deleteMany({
      where: {
        classeId,
        etudiantId,
      },
    });
  }

  async isStudentInClass(etudiantId: string, classeId: string): Promise<boolean> {
    const record = await prisma.etudiantClasse.findUnique({
      where: {
        etudiantId_classeId: {
          etudiantId,
          classeId,
        },
      },
    });
    return !!record;
  }

  async update(id: string, data: { nom?: string }): Promise<Classe> {
    return prisma.classe.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<Classe> {
    return prisma.classe.update({
      where: { id },
      data: {
        estSupprimee: true,
        dateSuppression: new Date(),
      },
    });
  }
}

export const classRepository = new ClassRepository();

