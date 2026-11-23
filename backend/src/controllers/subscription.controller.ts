import { Response, NextFunction } from 'express';
import { subscriptionService } from '../services/subscription.service';
import { AuthenticatedRequest } from '../types';

export class SubscriptionController {
  async getPlans(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const plans = await subscriptionService.getAvailablePlans();
      res.status(200).json(plans);
    } catch (error) {
      next(error);
    }
  }

  async getMySubscription(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const sub = await subscriptionService.getCurrentSubscription(req.user!.userId);
      res.status(200).json(sub);
    } catch (error) {
      next(error);
    }
  }

  async checkout(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { offreId } = req.body;
      const result = await subscriptionService.createCheckoutSession(req.user!.userId, offreId);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async webhook(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const signature = req.headers['stripe-signature'] as string | undefined;
      const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);

      const isValid = subscriptionService.verifyWebhookSignature(rawBody, signature);
      if (!isValid) {
        return res.status(400).json({ error: 'Signature de webhook Stripe invalide' });
      }

      const event = typeof req.body === 'object' ? req.body : JSON.parse(req.body);
      const result = await subscriptionService.handleWebhookEvent(event);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

export const subscriptionController = new SubscriptionController();

