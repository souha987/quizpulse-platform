import { prisma } from '../config/prisma';
import { Role, Utilisateur } from '@prisma/client';

export class UserRepository {
  async findByEmail(email: string): Promise<Utilisateur | null> {
    return prisma.utilisateur.findUnique({
      where: { email: email.toLowerCase() },
    });
  }

  async findById(id: string): Promise<Utilisateur | null> {
    return prisma.utilisateur.findUnique({
      where: { id },
    });
  }

  async create(data: {
    nom: string;
    prenom: string;
    email: string;
    motDePasseHash: string;
    role: Role;
    emailVerifie?: boolean;
    codeVerification?: string | null;
    dateExpirationVerification?: Date | null;
  }): Promise<Utilisateur> {
    return prisma.utilisateur.create({
      data: {
        nom: data.nom,
        prenom: data.prenom,
        email: data.email.toLowerCase(),
        motDePasseHash: data.motDePasseHash,
        role: data.role,
        emailVerifie: data.emailVerifie ?? false,
        codeVerification: data.codeVerification,
        dateExpirationVerification: data.dateExpirationVerification,
      },
    });
  }

  async updateVerificationCode(userId: string, code: string, expiresAt: Date): Promise<Utilisateur> {
    return prisma.utilisateur.update({
      where: { id: userId },
      data: {
        codeVerification: code,
        dateExpirationVerification: expiresAt,
      },
    });
  }

  async verifyEmail(userId: string): Promise<Utilisateur> {
    return prisma.utilisateur.update({
      where: { id: userId },
      data: {
        emailVerifie: true,
        codeVerification: null,
        dateExpirationVerification: null,
      },
    });
  }

  async listUsers(skip = 0, take = 50, role?: Role, search?: string) {
    const where: any = {};
    if (role) where.role = role;
    if (search) {
      where.OR = [
        { nom: { contains: search, mode: 'insensitive' } },
        { prenom: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [total, users] = await Promise.all([
      prisma.utilisateur.count({ where }),
      prisma.utilisateur.findMany({
        where,
        skip,
        take,
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          role: true,
          actif: true,
          dateInscription: true,
          _count: {
            select: {
              tentatives: true,
              quizCrees: true,
              classesEnseignees: true,
            },
          },
        },
        orderBy: { dateInscription: 'desc' },
      }),
    ]);

    return { total, users };
  }

  async setStatus(userId: string, actif: boolean): Promise<Utilisateur> {
    return prisma.utilisateur.update({
      where: { id: userId },
      data: { actif },
    });
  }
}

export const userRepository = new UserRepository();

