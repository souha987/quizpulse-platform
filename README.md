# EDUTECH QUIZ PLATFORM (WEB & MOBILE)

Plateforme web et mobile complète, professionnelle, sécurisée et modulaire pour la création, la gestion et le passage d'évaluations et de quiz éducatifs.

---

## 🎯 Vision du Produit & Profils

1. **Visiteur (Sans Inscription)** :
   - Accès immédiat au catalogue des quiz publics avec recherche en temps réel et filtres par matière.
   - Passage de quiz démo sans inscription préalable (`identifiantSession`).
   - Grille comparative des offres (Gratuit Découverte vs Enseignant Pro).
2. **Étudiant (100% Gratuit & Illimité)** :
   - Inscription immédiate, rejoindre une classe via code PIN (6 caractères).
   - Accès aux quiz assignés ou via code PIN 6 chiffres / scan QR Code.
   - Passage en Mode Normal ou Mode Examen Sécurisé (surveillance anti-triche des pertes de focus / changement d'onglet).
   - Compte à rebours avec alerte visuelle aux 60 dernières secondes et sauvegarde locale automatique en temps réel.
   - Corrigé complet post-soumission avec explications pédagogiques détaillées et historique personnel des notes.
3. **Enseignant (Freemium vs Pro)** :
   - Gestion de ses matières, catégories et classes virtuelles avec codes de classe uniques (6 car.).
   - Éditeur intuitif avec réorganisation des questions par glisser-déposer (`ReorderableListView`).
   - Modale de partage avec affichage grand format du QR Code vectoriel (`qr_flutter`) et du code PIN 6 chiffres.
   - Contrôle strict des quotas mensuels (`checkTeacherQuota`) : Gratuit limité à 5 quiz/mois vs Pro Illimité.
   - Tableau de bord analytique complet : taux de réussite, liste des étudiants, note sur 20, export CSV, et graphique en barres (`fl_chart`) identifiant le taux d'échec par question.
4. **Admin** :
   - Modération et prévisualisation des quiz de la plateforme (Publié, Brouillon, Archivé).
   - Datatable des utilisateurs avec suspension / réactivation en 1 clic.
   - Métriques globales (utilisateurs, étudiants, enseignants, quiz créés, copies rendues, revenus Stripe).

---

## 🏗️ Stack Technique

- **Frontend Flutter (Web, Android, iOS)** :
  - State Management : `flutter_riverpod` (v2)
  - Routing : `go_router` avec gardes d'authentification et de rôle
  - HTTP & Cache : `dio` avec intercepteurs JWT automatiques
  - Vector QR & Camera Scanner : `qr_flutter` & `mobile_scanner`
  - Offline & Autosave : `shared_preferences` pour sauvegarde automatique des réponses en cours
  - Visual Data & Charts : `fl_chart` pour le taux d'échec par question
- **Backend Node.js & TypeScript** :
  - Framework : `Express.js` en architecture modulaire (Controllers, Services, Repositories)
  - ORM & Base : `Prisma` + PostgreSQL (Supabase ready)
  - Sécurité : `helmet`, `cors`, `express-rate-limit`, `bcryptjs`, `jsonwebtoken`
  - Validation : `zod` pour validation stricte des DTOs
  - Tests : `jest`, `ts-jest` (100% de réussite sur les tests unitaires QA)

---

## 🔐 Sécurité Critique & Moteur de Notation (Backend)

1. **Lancement Sécurisé (`GET /api/quiz/:id/start`)** :
   - Vérifie les droits d'accès (public ou inscrit dans la classe cible).
   - Crée une entrée `Tentative` avec `dateDebut = new Date()`.
   - **Règle absolue appliquée** : Sélection des questions et options **en omettant explicitement `estCorrecte` et `explicationCorrection`** :
     ```ts
     options: {
       select: { id: true, texte: true } // 'estCorrecte' omis côté serveur
     }
     ```
2. **Validation & Calcul de Note (`POST /api/attempts/:id/submit`)** :
   - Calcule le temps écoulé `dateSoumission - dateDebut`. Si `tempsEcoule > dureeMinutes * 60 * 1000 + 15000` (15s de marge réseau), marque la tentative comme `EXPIREE`.
   - Évaluation côté serveur en interrogeant la vraie valeur `estCorrecte` en base de données.
   - Retourne la note finale sur 20 et le corrigé complet avec les explications pédagogiques.
3. **Contrôle des Quotas Enseignant (`checkTeacherQuota`)** :
   - Compte les quiz créés durant le mois calendaire en cours.
   - Bloque avec une erreur 403 dès que l'enseignant gratuit atteint son quota de 5 quiz et l'invite à passer en Pro.

---

## 🧪 Données de Test & Comptes Démo (Seed)

| Rôle | Email | Mot de passe | Description |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@edutech.com` | `Admin123!` | Accès au panel admin, métriques et modération |
| **Prof Pro** | `prof.curie@edutech.com` | `Prof123!` | Enseignant avec abonnement Pro illimité actif |
| **Prof Gratuit** | `prof.dupont@edutech.com` | `Prof123!` | Enseignant Freemium soumis au quota mensuel |
| **Étudiant 1** | `etudiant.alice@edutech.com` | `Etudiant123!` | Étudiante inscrite dans la classe `WEB202` |
| **Étudiant 2** | `etudiant.bob@edutech.com` | `Etudiant123!` | Étudiant inscrit dans la classe `WEB202` |

- **Quiz Démo Public** : Code PIN **`123456`** (accessible sans compte depuis la vitrine)
- **Quiz Examen Sécurisé** : Code PIN **`654321`** (surveillance anti-triche active)
- **Classe Démo** : Code **`WEB202`**

---

## 🚀 Guide d'Exécution

### 1. Backend (Node.js & TypeScript)

```bash
cd backend

# Installation des dépendances
npm install

# Génération du client Prisma
npm run prisma:generate

# Lancer la suite complète de tests QA Jest
npm test

# Compiler en production
npm run build

# Démarrer le serveur API (port 5000)
npm start
# Ou en mode dev rechargement à chaud :
npm run dev
```

### 2. Frontend (Flutter Web & Mobile)

```bash
cd frontend

# Récupérer les dépendances Flutter
flutter pub get

# Lancer les tests unitaires et widget tests
flutter test test/widget_test.dart

# Compiler la version Web de production
flutter build web --no-tree-shake-icons

# Lancer en mode développement sur Chrome :
flutter run -d chrome
```

---

## 📋 Plan de Développement

Le suivi des étapes est documenté et coché dans le fichier [PLAN.md](file:///c:/Users/barou/OneDrive/Desktop/quiz-platform/PLAN.md).
