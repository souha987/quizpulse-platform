# Plan d'Exécution - Edutech Quiz Platform (Web & Mobile)

- [x] **Étape 1 : Initialisation de l'arborescence et architecture du projet**
  - [x] Structure des répertoires `backend/` et `frontend/`
  - [x] Configuration globale de l'environnement (.env.example, README)

- [x] **Étape 2 : Backend Setup & Base de Données (Prisma + PostgreSQL)**
  - [x] Initialisation de `backend/package.json` et `tsconfig.json`
  - [x] Installation des dépendances (Express, Prisma, TypeScript, Zod, JWT, bcryptjs, cors, helmet, etc.)
  - [x] Écriture du schéma complet `schema.prisma` selon la spécification
  - [x] Génération du client Prisma et script de seed de données de test

- [x] **Étape 3 : Core Services Backend (Architecture Modulaire)**
  - [x] Configuration Express, middlewares globaux (helmet, cors, rate-limit, errorHandler)
  - [x] Authentification & Rôles (JWT, bcryptjs, middleware `requireAuth`, `requireRole`)
  - [x] Middleware critique `checkTeacherQuota` (Freemium vs Premium)
  - [x] Module Classes & Inscriptions (Codes PIN 6 caractères, assignations)
  - [x] Module Quiz & Questions (CRUD, Catégories, Matières, Mode Examen)
  - [x] Module Tentatives & Moteur de notation sécurisé (`/start` sans correction, `/submit` avec contrôle temps + marge 15s)
  - [x] Module Analytics Enseignant (taux d'échec par question, export CSV des notes)
  - [x] Module Abonnements & Paiements (Plans Freemium / Pro, Stripe webhook mock/stub)
  - [x] Module Admin (Modération des quiz, bannissement / statut utilisateurs, métriques)
  - [x] Tests unitaires et d'intégration Jest (Auth, Quotas, Calcul de note, Sécurité du corrigé)

- [x] **Étape 4 : Frontend Flutter Setup**
  - [x] Structure Flutter (`lib/core/`, `lib/features/`, `lib/shared/`)
  - [x] Configuration `pubspec.yaml` (riverpod, go_router, dio, qr_flutter, mobile_scanner, shared_preferences, fl_chart, etc.)
  - [x] Configuration HTTP Dio avec intercepteurs JWT & gestion d'erreurs
  - [x] Système de routage GoRouter avec Role Guards (Visiteur, Étudiant, Enseignant, Admin)
  - [x] Gestion d'état et cache local (Riverpod, persistence locale des réponses)

- [x] **Étape 5 : Vues Flutter Complètes**
  - [x] Espace Visiteur (Catalogue de quiz publics, recherche temps réel, filtres matières, quiz démo sans compte, pricing)
  - [x] Espace Étudiant (Rejoindre par PIN 6 chiffres / QR Code, session de quiz interactive avec compte à rebours & alerte 60s, mode examen sécurisé anti-triche, historique & révision)
  - [x] Espace Enseignant (Éditeur de quiz avec réorganisation, modale de partage QR & PIN, tableau de bord analytique avec graphiques de taux d'échec & export CSV)
  - [x] Espace Admin (Gestion des utilisateurs, modération des quiz signalés, métriques)

- [x] **Étape 6 : Revue QA, Robustesse & Documentation**
  - [x] Vérification de la gestion des erreurs réseau et mode hors-ligne
  - [x] Tests bout en bout des endpoints critiques
  - [x] Documentation d'installation et d'exécution
