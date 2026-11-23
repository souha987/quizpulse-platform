import { prisma } from '../config/prisma';

export class SubscriptionRepository {
  async listActivePlans() {
    return prisma.offreAbonnement.findMany({
      where: { active: true },
      orderBy: { prix: 'asc' },
    });
  }

  async findPlanById(id: string) {
    return prisma.offreAbonnement.findUnique({
      where: { id },
    });
  }

  async getActiveSubscription(enseignantId: string) {
    const now = new Date();
    return prisma.abonnement.findFirst({
      where: {
        enseignantId,
        statut: 'ACTIF',
        dateFin: { gte: now },
      },
      include: {
        offre: true,
        paiements: {
          orderBy: { datePaiement: 'desc' },
          take: 5,
        },
      },
    });
  }

  async createSubscription(data: {
    enseignantId: string;
    offreId: string;
    dureeJours: number;
    referencePaiement: string;
    montant: number;
    methode: string;
  }) {
    const dateDebut = new Date();
    const dateFin = new Date();
    dateFin.setDate(dateFin.getDate() + data.dureeJours);

    return prisma.$transaction(async (tx) => {
      // Désactiver tout abonnement précédent encore actif
      await tx.abonnement.updateMany({
        where: { enseignantId: data.enseignantId, statut: 'ACTIF' },
        data: { statut: 'ANNULE' },
      });

      // Créer nouvel abonnement
      const sub = await tx.abonnement.create({
        data: {
          enseignantId: data.enseignantId,
          offreId: data.offreId,
          dateDebut,
          dateFin,
          statut: 'ACTIF',
        },
      });

      // Créer enregistrement du paiement
      const payment = await tx.paiement.create({
        data: {
          abonnementId: sub.id,
          reference: data.referencePaiement,
          montant: data.montant,
          methode: data.methode,
          statut: 'VALIDE',
        },
      });

      return { subscription: sub, payment };
    });
  }
}

export const subscriptionRepository = new SubscriptionRepository();

