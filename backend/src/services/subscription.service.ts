import crypto from 'crypto';
import { subscriptionRepository } from '../repositories/subscription.repository';
import { prisma } from '../config/prisma';
import { AppError } from '../middlewares/error.middleware';
import { env } from '../config/env';

export class SubscriptionService {
  async getAvailablePlans() {
    return subscriptionRepository.listActivePlans();
  }

  async getCurrentSubscription(enseignantId: string) {
    const activeSub = await subscriptionRepository.getActiveSubscription(enseignantId);

    // Compter les quiz créés durant le mois calendaire en cours
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const quizCreatedThisMonth = await prisma.quiz.count({
      where: {
        enseignantId,
        dateCreation: { gte: startOfMonth },
      },
    });

    const quotaQuiz = activeSub?.offre?.quotaQuiz ?? 5;
    const isUnlimited = quotaQuiz === -1;

    return {
      hasActiveSubscription: !!activeSub,
      subscription: activeSub,
      planName: activeSub?.offre?.nom ?? 'Formule Gratuite (Découverte)',
      quotaQuiz: isUnlimited ? 'Illimité' : quotaQuiz,
      quizUtilisesCeMois: quizCreatedThisMonth,
      quotaAtteint: !isUnlimited && quizCreatedThisMonth >= quotaQuiz,
      modeSecuriseAutorise: activeSub?.offre?.modeSecuriseAutorise ?? false,
    };
  }

  async createCheckoutSession(
    enseignantId: string,
    offreId: string,
    options?: { successUrl?: string; cancelUrl?: string }
  ) {
    const plan = await subscriptionRepository.findPlanById(offreId);
    if (!plan || !plan.active) {
      throw new AppError('Offre d\'abonnement introuvable ou inactive', 404);
    }

    const isMock = env.STRIPE_SECRET_KEY.startsWith('sk_test_mock');

    if (isMock) {
      // Mock/Stub de session Stripe Checkout pour développement / démo
      const fakeSessionId = `cs_test_${Date.now()}_${Math.random().toString(36).substring(7)}`;
      const fakeReference = `pay_${Date.now()}_${Math.random().toString(36).substring(7)}`;

      // Pour l'intégration directe ou mode développement, validation immédiate
      const result = await subscriptionRepository.createSubscription({
        enseignantId,
        offreId: plan.id,
        dureeJours: plan.dureeJours,
        referencePaiement: fakeReference,
        montant: plan.prix,
        methode: 'stripe_mock',
      });

      return {
        sessionId: fakeSessionId,
        checkoutUrl: `https://checkout.stripe.com/c/pay/${fakeSessionId}`,
        isMock: true,
        success: true,
        message: 'Abonnement activé avec succès (Mode Simulation)',
        subscription: result.subscription,
      };
    }

    // Intégration Stripe API réelle
    try {
      const params = new URLSearchParams();
      params.append('payment_method_types[]', 'card');
      params.append('mode', 'payment');
      params.append('line_items[0][price_data][currency]', 'tnd');
      params.append('line_items[0][price_data][unit_amount]', Math.round(plan.prix * 100).toString());
      params.append('line_items[0][price_data][product_data][name]', `Abonnement QuizPulse - ${plan.nom}`);
      params.append('line_items[0][quantity]', '1');
      params.append('client_reference_id', enseignantId);
      params.append('metadata[enseignantId]', enseignantId);
      params.append('metadata[offreId]', plan.id);
      params.append('success_url', options?.successUrl || 'http://localhost:3000/teacher/subscription?status=success');
      params.append('cancel_url', options?.cancelUrl || 'http://localhost:3000/teacher/subscription?status=cancelled');

      const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });

      const session: any = await response.json();
      if (!response.ok) {
        throw new AppError(`Erreur Stripe Checkout: ${session.error?.message || 'Échec d\'initialisation'}`, 400);
      }

      return {
        sessionId: session.id,
        checkoutUrl: session.url,
        isMock: false,
        success: true,
        message: 'Session Stripe Checkout créée avec succès',
      };
    } catch (error: any) {
      if (error instanceof AppError) throw error;
      throw new AppError(`Erreur de connexion avec le service de paiement: ${error.message}`, 502);
    }
  }

  verifyWebhookSignature(payload: string, signatureHeader?: string): boolean {
    const isMock = env.STRIPE_WEBHOOK_SECRET.startsWith('whsec_mock');
    if (isMock) {
      return true;
    }

    if (!signatureHeader) {
      return false;
    }

    try {
      const parts = signatureHeader.split(',').reduce((acc: Record<string, string>, item) => {
        const [k, v] = item.split('=');
        if (k && v) acc[k.trim()] = v.trim();
        return acc;
      }, {});

      const timestamp = parts['t'];
      const signature = parts['v1'];
      if (!timestamp || !signature) return false;

      const expectedSignature = crypto
        .createHmac('sha256', env.STRIPE_WEBHOOK_SECRET)
        .update(`${timestamp}.${payload}`)
        .digest('hex');

      return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
    } catch {
      return false;
    }
  }

  async handleWebhookEvent(event: any) {
    if (!event || !event.type) {
      return { received: true, processed: false, reason: 'Invalid event structure' };
    }

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data?.object;
        const enseignantId = session?.client_reference_id || session?.metadata?.enseignantId;
        const offreId = session?.metadata?.offreId;

        if (enseignantId && offreId) {
          const plan = await subscriptionRepository.findPlanById(offreId);
          if (plan) {
            await subscriptionRepository.createSubscription({
              enseignantId,
              offreId: plan.id,
              dureeJours: plan.dureeJours,
              referencePaiement: session.payment_intent || session.id,
              montant: plan.prix,
              methode: 'stripe_webhook',
            });
          }
        }
        return { received: true, processed: true, event: event.type };
      }

      default:
        return { received: true, processed: true, event: event.type };
    }
  }
}

export const subscriptionService = new SubscriptionService();

