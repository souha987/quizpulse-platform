import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { z } from 'zod';

dotenv.config();
const candidateEnvPaths = [
  path.resolve(process.cwd(), '.env'),
  path.resolve(process.cwd(), 'backend', '.env'),
  path.resolve(__dirname, '../../.env'),
  path.resolve(__dirname, '../../../backend/.env'),
];
for (const envPath of candidateEnvPaths) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
  }
}

export const INSECURE_DEFAULT_JWT = 'super-secret-jwt-key-change-in-production-min-32-chars-long';

const envSchema = z.object({
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  DIRECT_URL: z.string().optional(),
  PORT: z.string().default('5000').transform((val) => parseInt(val, 10)),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters long'),
  JWT_EXPIRES_IN: z.string().default('7d'),
  CORS_ORIGIN: z.string().default('*'),
  STRIPE_SECRET_KEY: z.string().default('sk_test_mock_secret'),
  STRIPE_WEBHOOK_SECRET: z.string().default('whsec_mock_secret'),
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().optional().default('587'),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  SMTP_FROM: z.string().optional().default('QuizPulse <no-reply@quizpulse.com>'),
  RESEND_API_KEY: z.string().optional(),
  RESEND_FROM: z.string().optional(),
  BREVO_API_KEY: z.string().optional(),
  BREVO_SENDER: z.string().optional(),
}).superRefine((data, ctx) => {
  if (data.NODE_ENV === 'production') {
    if (data.JWT_SECRET === INSECURE_DEFAULT_JWT) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['JWT_SECRET'],
        message: 'Security error: default insecure JWT_SECRET cannot be used in production.',
      });
    }
  }
});

export const env = envSchema.parse(process.env);

if (env.NODE_ENV === 'development') {
  if (env.JWT_SECRET === INSECURE_DEFAULT_JWT) {
    console.warn('[SECURITY WARNING] Running with default insecure JWT_SECRET. Do not deploy to production with this key.');
  }
  if (env.STRIPE_SECRET_KEY.startsWith('sk_test_mock')) {
    console.info('[STRIPE INFO] Mock Stripe keys detected - running in simulated checkout mode.');
  }
}

