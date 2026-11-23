import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import path from 'path';
import fs from 'fs';
import { env } from './config/env';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware';

// Routes
import authRoutes from './routes/auth.routes';
import classRoutes from './routes/class.routes';
import quizRoutes from './routes/quiz.routes';
import attemptRoutes from './routes/attempt.routes';
import analyticsRoutes from './routes/analytics.routes';
import subscriptionRoutes from './routes/subscription.routes';
import adminRoutes from './routes/admin.routes';
import publicRoutes from './routes/public.routes';

const app = express();

// Sécurité : Headers HTTP avec Helmet (adapté pour Flutter Web CanvasKit & WASM)
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  })
);

// Sécurité : CORS
app.use(
  cors({
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
    credentials: true,
  })
);

// Sécurité : Rate Limiting (100 requêtes par minute par IP en prod/dev)
if (env.NODE_ENV !== 'test') {
  const limiter = rateLimit({
    windowMs: 60 * 1000,
    max: 120,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Trop de requêtes effectuées depuis cette IP, veuillez réessayer plus tard.' },
  });
  app.use('/api/', limiter);
}

// Parsing du corps de requête JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Enregistrement des routes API
app.use('/api/auth', authRoutes);
app.use('/api/classes', classRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/attempts', attemptRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/public', publicRoutes);

// Déploiement : Servir l'application Frontend Flutter Web pour accès multi-appareils (Wi-Fi, URL distante)
const possibleWebPaths = [
  path.resolve(__dirname, '../../frontend/build/web'),
  path.resolve(__dirname, '../../../frontend/build/web'),
  path.resolve(process.cwd(), '../frontend/build/web'),
  path.resolve(process.cwd(), 'frontend/build/web'),
];

let webDir: string | null = null;
for (const p of possibleWebPaths) {
  if (fs.existsSync(path.join(p, 'index.html'))) {
    webDir = p;
    break;
  }
}

if (webDir) {
  console.log(`[DÉPLOIEMENT] Application Frontend Flutter Web servie depuis : ${webDir}`);
  app.use(express.static(webDir));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api') || req.path === '/health') {
      return next();
    }
    res.sendFile(path.join(webDir!, 'index.html'));
  });
}

// Gestion 404 et Erreurs Globales
app.use(notFoundHandler);
app.use(errorHandler);

export default app;

