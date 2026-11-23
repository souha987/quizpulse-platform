import { AuthService } from '../src/services/auth.service';
import { userRepository } from '../src/repositories/user.repository';
import { emailService } from '../src/services/email.service';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../src/config/env';
import { Role } from '@prisma/client';

describe('QA Tests - Authentification & Vérification de l\'adresse e-mail (Point 22)', () => {
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService();
    jest.clearAllMocks();
  });

  it('register NE DOIT RIEN ÉCRIRE dans la base de données avant vérification (zéro écriture)', async () => {
    jest.spyOn(userRepository, 'findByEmail').mockResolvedValue(null);
    jest.spyOn(bcrypt, 'hash').mockResolvedValue('hashed_password' as never);
    const createUserSpy = jest.spyOn(userRepository, 'create');
    const sendEmailSpy = jest.spyOn(emailService, 'sendVerificationEmail').mockResolvedValue(true);

    const result = await authService.register({
      nom: 'Martin',
      prenom: 'Claire',
      email: 'claire@example.com',
      motDePasse: 'Secret123!',
      role: Role.ETUDIANT,
    });

    expect(result.success).toBe(true);
    expect(result.requiresVerification).toBe(true);
    expect(result.registrationToken).toBeDefined();

    // RÈGLE ABSOLUE : Aucune écriture dans la base de données
    expect(createUserSpy).not.toHaveBeenCalled();
    expect(sendEmailSpy).toHaveBeenCalledWith('claire@example.com', 'Claire', expect.stringMatching(/^\d{6}$/));
  });

  it('login doit BLOQUER avec 401 un utilisateur non encore vérifié / non enregistré', async () => {
    jest.spyOn(userRepository, 'findByEmail').mockResolvedValue(null);

    await expect(
      authService.login('inconnu@example.com', 'Secret123!')
    ).rejects.toThrow('Identifiants invalides');
  });

  it('login doit autoriser la connexion si l\'adresse e-mail est vérifiée et le compte créé', async () => {
    const verifiedUser = {
      id: 'user-verified',
      nom: 'Martin',
      prenom: 'Claire',
      email: 'claire@example.com',
      motDePasseHash: await bcrypt.hash('Secret123!', 10),
      role: Role.ETUDIANT,
      actif: true,
      emailVerifie: true,
    };

    jest.spyOn(userRepository, 'findByEmail').mockResolvedValue(verifiedUser as any);
    jest.spyOn(bcrypt, 'compare').mockResolvedValue(true as never);

    const result = await authService.login('claire@example.com', 'Secret123!') as any;

    expect(result.token).toBeDefined();
    expect(result.user.email).toBe('claire@example.com');
    expect(result.user.emailVerifie).toBe(true);
  });

  it('verifyEmail doit rejeter un code erroné', async () => {
    const registrationToken = jwt.sign(
      {
        nom: 'Martin',
        prenom: 'Claire',
        email: 'claire@example.com',
        motDePasseHash: 'hashed_pw',
        role: Role.ETUDIANT,
        codeVerification: '123456',
      },
      env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    await expect(
      authService.verifyEmail('claire@example.com', '999999', registrationToken)
    ).rejects.toThrow('Code de confirmation invalide');
  });

  it('verifyEmail DOIT CRÉER le compte dans Utilisateur UNIQUEMENT après validation du bon code', async () => {
    const registrationToken = jwt.sign(
      {
        nom: 'Martin',
        prenom: 'Claire',
        email: 'claire@example.com',
        motDePasseHash: 'hashed_pw',
        role: Role.ETUDIANT,
        codeVerification: '123456',
      },
      env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    jest.spyOn(userRepository, 'findByEmail').mockResolvedValue(null);
    const createUserSpy = jest.spyOn(userRepository, 'create').mockResolvedValue({
      id: 'new-user-confirmed',
      nom: 'Martin',
      prenom: 'Claire',
      email: 'claire@example.com',
      motDePasseHash: 'hashed_pw',
      role: Role.ETUDIANT,
      emailVerifie: true,
      actif: true,
      dateInscription: new Date(),
    } as any);

    const result = await authService.verifyEmail('claire@example.com', '123456', registrationToken);

    expect(result.success).toBe(true);
    // C'est seulement ici que l'utilisateur est inséré en base
    expect(createUserSpy).toHaveBeenCalledWith({
      nom: 'Martin',
      prenom: 'Claire',
      email: 'claire@example.com',
      motDePasseHash: 'hashed_pw',
      role: Role.ETUDIANT,
      emailVerifie: true,
    });
    expect(result.token).toBeDefined();
    expect(result.user.emailVerifie).toBe(true);
  });

  it('resendVerification doit générer un nouveau code et renvoyer l\'e-mail', async () => {
    const registrationToken = jwt.sign(
      {
        nom: 'Martin',
        prenom: 'Claire',
        email: 'claire@example.com',
        motDePasseHash: 'hashed_pw',
        role: Role.ETUDIANT,
        codeVerification: '123456',
      },
      env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    jest.spyOn(userRepository, 'findByEmail').mockResolvedValue(null);
    const sendEmailSpy = jest.spyOn(emailService, 'sendVerificationEmail').mockResolvedValue(true);

    const result = await authService.resendVerification('claire@example.com', registrationToken);

    expect(result.success).toBe(true);
    expect(result.registrationToken).toBeDefined();
    expect(sendEmailSpy).toHaveBeenCalledWith('claire@example.com', 'Claire', expect.stringMatching(/^\d{6}$/));
  });
});
