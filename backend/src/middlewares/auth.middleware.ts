import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { AuthenticatedRequest, TokenPayload } from '../types';
import { Role } from '@prisma/client';

export const requireAuth = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Accès non autorisé : Token JWT manquant' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as TokenPayload;
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token invalide ou expiré' });
    return;
  }
};

export const optionalAuth = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, env.JWT_SECRET) as TokenPayload;
      req.user = decoded;
    } catch {
      // Ignorer l'erreur pour les visiteurs anonymes
    }
  }

  next();
};

export const requireRole = (allowedRoles: Role[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Authentification requise' });
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({ error: 'Accès interdit : Privilèges insuffisants' });
      return;
    }

    next();
  };
};

