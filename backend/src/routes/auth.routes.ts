import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { requireAuth } from '../middlewares/auth.middleware';
import { validateBody } from '../middlewares/validate.middleware';
import { loginSchema, registerSchema, verifyEmailSchema, resendVerificationSchema } from '../validations';

const router = Router();

router.post('/register', validateBody(registerSchema), (req, res, next) =>
  authController.register(req, res, next)
);

router.post('/login', validateBody(loginSchema), (req, res, next) =>
  authController.login(req, res, next)
);

router.post('/verify-email', validateBody(verifyEmailSchema), (req, res, next) =>
  authController.verifyEmail(req, res, next)
);

router.get('/verify-email', (req, res, next) =>
  authController.verifyEmail(req, res, next)
);

router.post('/resend-verification', validateBody(resendVerificationSchema), (req, res, next) =>
  authController.resendVerification(req, res, next)
);

router.get('/me', requireAuth, (req, res, next) =>
  authController.me(req, res, next)
);

export default router;

