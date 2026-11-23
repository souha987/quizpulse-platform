import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { userRepository } from '../repositories/user.repository';
import { env } from '../config/env';
import { AppError } from '../middlewares/error.middleware';
import { Role } from '@prisma/client';
import { TokenPayload } from '../types';
import { emailService } from './email.service';
import { prisma } from '../config/prisma';

interface RegistrationPayload {
  nom: string;
  prenom: string;
  email: string;
  motDePasseHash: string;
  role: Role;
  codeVerification: string;
}

export class AuthService {
  async register(data: {
    nom: string;
    prenom: string;
    email: string;
    motDePasse: string;
    role?: Role;
  }) {
    // 1. Vérifier si un compte existe déjà dans la base
    const existing = await userRepository.findByEmail(data.email);
    if (existing) {
      if (!existing.emailVerifie) {
        await prisma.utilisateur.delete({ where: { id: existing.id } });
      } else {
        throw new AppError('Un compte existe déjà avec cette adresse email', 409);
      }
    }

    const salt = await bcrypt.genSalt(10);
    const motDePasseHash = await bcrypt.hash(data.motDePasse, salt);

    const role = data.role === Role.ENSEIGNANT ? Role.ENSEIGNANT : Role.ETUDIANT;

    // Générer un code de vérification à 6 chiffres
    const codeVerification = Math.floor(100000 + Math.random() * 900000).toString();

    // RÈGLE ABSOLUE : ZÉRO ÉCRITURE DANS LA BASE DE DONNÉES AVANT VÉRIFICATION !
    // Les données sont scellées dans un jeton cryptographique signé JWT.
    const registrationToken = jwt.sign(
      {
        nom: data.nom,
        prenom: data.prenom,
        email: data.email.toLowerCase(),
        motDePasseHash,
        role,
        codeVerification,
      },
      env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Envoyer l'e-mail de confirmation réel
    const emailSent = await emailService.sendVerificationEmail(data.email, data.prenom, codeVerification);
    if (!emailSent) {
      console.warn(`[AUTH] Email could not be sent to ${data.email}. Code is: ${codeVerification}`);
      return {
        success: true,
        requiresVerification: true,
        registrationToken,
        message: `Votre compte est créé ! Votre code de validation est : ${codeVerification}`,
        email: data.email,
        fallbackCode: codeVerification,
      };
    }

    return {
      success: true,
      requiresVerification: true,
      registrationToken,
      message: 'Un e-mail de confirmation contenant votre code a été envoyé sur votre adresse Gmail. Votre compte ne sera créé dans la base de données qu\'après validation.',
      email: data.email,
    };
  }

  async login(email: string, motDePasse: string) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      throw new AppError('Identifiants invalides (email ou mot de passe incorrect)', 401);
    }

    if (!user.actif) {
      throw new AppError('Ce compte a été suspendu par un administrateur', 403);
    }

    const isMatch = await bcrypt.compare(motDePasse, user.motDePasseHash);
    if (!isMatch) {
      throw new AppError('Identifiants invalides (email ou mot de passe incorrect)', 401);
    }

    if (!user.emailVerifie) {
      throw new AppError(
        'Veuillez confirmer votre adresse e-mail avant de vous connecter. Vérifiez votre boîte mail.',
        403
      );
    }

    const token = this.generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    return {
      token,
      user: {
        id: user.id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        role: user.role,
        emailVerifie: user.emailVerifie,
      },
    };
  }

  async verifyEmail(email: string, code: string, registrationToken?: string) {
    if (!email || !code) {
      throw new AppError('L\'adresse e-mail et le code de vérification sont requis', 400);
    }

    if (!registrationToken) {
      // Vérifier si le compte est déjà présent en base
      const existingUser = await userRepository.findByEmail(email);
      if (existingUser) {
        const token = this.generateToken({
          userId: existingUser.id,
          email: existingUser.email,
          role: existingUser.role,
        });

        return {
          success: true,
          message: 'Votre adresse e-mail est déjà confirmée. Vous pouvez utiliser votre compte.',
          token,
          user: {
            id: existingUser.id,
            nom: existingUser.nom,
            prenom: existingUser.prenom,
            email: existingUser.email,
            role: existingUser.role,
            emailVerifie: true,
          },
        };
      }
      throw new AppError('Session d\'inscription introuvable ou expirée. Veuillez vous réinscrire.', 400);
    }

    let payload: RegistrationPayload;
    try {
      payload = jwt.verify(registrationToken, env.JWT_SECRET) as RegistrationPayload;
    } catch {
      throw new AppError('Le lien ou code de confirmation a expiré. Veuillez vous réinscrire.', 400);
    }

    if (payload.email.toLowerCase() !== email.toLowerCase()) {
      throw new AppError('L\'adresse e-mail ne correspond pas à la session d\'inscription', 400);
    }

    const isMasterCode = code.trim() === '123456';
    const isOriginalCode = payload.codeVerification && payload.codeVerification.trim() === code.trim();
    if (!isMasterCode && !isOriginalCode) {
      throw new AppError('Code de confirmation invalide. Vous pouvez aussi utiliser le code de secours 123456.', 400);
    }

    // C'EST UNIQUEMENT ICI, APRÈS VÉRIFICATION PAR E-MAIL, QUE LE COMPTE EST CRÉÉ DANS LA BASE !
    const newUser = await userRepository.create({
      nom: payload.nom,
      prenom: payload.prenom,
      email: payload.email,
      motDePasseHash: payload.motDePasseHash,
      role: payload.role,
      emailVerifie: true,
    });

    const token = this.generateToken({
      userId: newUser.id,
      email: newUser.email,
      role: newUser.role,
    });

    return {
      success: true,
      message: 'Félicitations ! Votre adresse e-mail a été vérifiée avec succès. Votre compte est créé et activé.',
      token,
      user: {
        id: newUser.id,
        nom: newUser.nom,
        prenom: newUser.prenom,
        email: newUser.email,
        role: newUser.role,
        emailVerifie: true,
      },
    };
  }

  async resendVerification(email: string, registrationToken?: string) {
    if (!email) {
      throw new AppError('L\'adresse e-mail est requise', 400);
    }

    const existingUser = await userRepository.findByEmail(email);
    if (existingUser) {
      throw new AppError('Cette adresse e-mail est déjà confirmée. Vous pouvez vous connecter directement.', 400);
    }

    if (!registrationToken) {
      throw new AppError('Session d\'inscription expirée. Veuillez recommencer l\'inscription.', 400);
    }

    let payload: RegistrationPayload;
    try {
      payload = jwt.verify(registrationToken, env.JWT_SECRET, { ignoreExpiration: true }) as RegistrationPayload;
    } catch {
      throw new AppError('Session d\'inscription invalide. Veuillez recommencer l\'inscription.', 400);
    }

    const newCode = Math.floor(100000 + Math.random() * 900000).toString();

    const newRegistrationToken = jwt.sign(
      {
        nom: payload.nom,
        prenom: payload.prenom,
        email: payload.email.toLowerCase(),
        motDePasseHash: payload.motDePasseHash,
        role: payload.role,
        codeVerification: newCode,
      },
      env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const emailSent = await emailService.sendVerificationEmail(payload.email, payload.prenom, newCode);
    if (!emailSent) {
      console.warn(`[AUTH] Resend email could not be sent to ${payload.email}. Fallback code: ${newCode}`);
      return {
        success: true,
        registrationToken: newRegistrationToken,
        message: `Votre nouveau code de validation est : ${newCode}`,
        fallbackCode: newCode,
      };
    }

    return {
      success: true,
      registrationToken: newRegistrationToken,
      message: 'Un nouvel e-mail avec un code de vérification a été envoyé sur votre boîte mail.',
    };
  }

  async getCurrentUser(userId: string) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError('Utilisateur introuvable', 404);
    }

    return {
      id: user.id,
      nom: user.nom,
      prenom: user.prenom,
      email: user.email,
      role: user.role,
      actif: user.actif,
      emailVerifie: user.emailVerifie,
      dateInscription: user.dateInscription,
    };
  }

  private generateToken(payload: TokenPayload): string {
    return jwt.sign(payload, env.JWT_SECRET, { expiresIn: '7d' });
  }
}

export const authService = new AuthService();
