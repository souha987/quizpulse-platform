import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../shared/widgets/confetti_celebration.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/count_up_text.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  // 0: Tout, 1: Erreurs uniquement, 2: Bonnes réponses uniquement
  int _selectedFilter = 0;

  void _showCertificateDialog(BuildContext context, String studentName, double noteSur20, String mention, int nbAvertissementsTriche) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF7), // Ton parchemin élégant
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Bordure dorée
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sceau académique
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, size: 54, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 16),
              const Text(
                'ATTESTATION OFFICIELLE DE RÉUSSITE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF92400E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Plateforme d\'Évaluation Sécurisée EduQuiz',
                style: TextStyle(fontSize: 13, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cette attestation certifie avec succès que :',
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563), fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'a validé l\'évaluation avec la note remarquable de $noteSur20 / 20 ($mention).',
                style: const TextStyle(fontSize: 15, color: Color(0xFF374151), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (nbAvertissementsTriche == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Épreuve horodatée et contrôlée sans fraude',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppAlert.success(context, 'Attestation prête à être imprimée ou sauvegardée en PDF.');
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimer l\'attestation (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attemptState = ref.watch(quizAttemptProvider);
    final authState = ref.watch(authProvider);
    final result = attemptState.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Résultats')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Aucun résultat disponible.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/student'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }

    final isCheated = result.statut == 'ANNULEE_TRICHE' || result.nbAvertissementsTriche > 0;
    final isSuccess = !isCheated && result.noteSur20 >= 10.0;
    final isStudent = authState.role == UserRole.etudiant || authState.role == UserRole.visiteur;
    final studentName = authState.user?.nomComplet ?? 'Candidat Évaluateur';

    String mention = 'Passable';
    if (isCheated) {
      mention = 'Fraude (Annulé)';
    } else if (result.noteSur20 >= 16.0) {
      mention = 'Très Bien';
    } else if (result.noteSur20 >= 14.0) {
      mention = 'Bien';
    } else if (result.noteSur20 >= 12.0) {
      mention = 'Assez Bien';
    }

    final totalCount = result.nbQuestionsTotal > 0 ? result.nbQuestionsTotal : result.corrige.length;
    final successCount = result.nbQuestionsTotal > 0 ? result.nbQuestionsCorrectes : result.corrige.where((q) => q.estCorrecte).length;
    final errorsCount = totalCount >= successCount ? totalCount - successCount : 0;
    final minutes = result.dureeSecondes ~/ 60;
    final seconds = result.dureeSecondes % 60;
    final timeSpentStr = minutes > 0
        ? '$minutes min ${seconds.toString().padLeft(2, '0')} s'
        : '$seconds s';

    final filteredQuestions = result.corrige.where((q) {
      if (_selectedFilter == 1) return !q.estCorrecte;
      if (_selectedFilter == 2) return q.estCorrecte;
      return true;
    }).toList();

    return ConfettiCelebration(
      isPlaying: isSuccess,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const QuizPulseLogo(size: 32),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded, size: 18, color: Color(0xFF2563EB)),
            label: const Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/student'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          maxWidth: 820,
          child: Column(
            children: [
              // Bloc Synthèse Supérieur (Score compté sur 1s, Temps passé, Bonnes réponses)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Score animé de 0 à la note en 1 seconde
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Color(0xFF2563EB), size: 24),
                              const SizedBox(width: 8),
                              CountUpText(
                                value: '${result.noteSur20.toStringAsFixed(1)}/20',
                                duration: const Duration(milliseconds: 1000),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Score (${result.pourcentage}%)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 46, color: const Color(0xFFE2E8F0)),
                    // Temps passé
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_outlined, color: Color(0xFF0284C7), size: 22),
                              const SizedBox(width: 6),
                              Text(
                                timeSpentStr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Temps passé',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 46, color: const Color(0xFFE2E8F0)),
                    // X bonnes réponses sur Y
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 22),
                              const SizedBox(width: 6),
                              Text(
                                '$successCount / $totalCount',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$successCount bonne${successCount > 1 ? "s" : ""} sur $totalCount',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Carte Synthèse du Résultat
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    EduMascot(
                      mood: isCheated ? MascotMood.encourage : (isSuccess ? MascotMood.celebrate : MascotMood.encourage),
                      size: 130,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCheated
                          ? 'Tentative Annulée (Triche)'
                          : (isSuccess ? 'Bravo !' : 'Continue, tu y es presque !'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isCheated ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCheated
                          ? '⚠️ Fraude / Sortie d\'écran détectée'
                          : (isSuccess ? 'Félicitations ! Évaluation Validée 🎉' : 'Évaluation Non Validée'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isCheated
                            ? const Color(0xFFDC2626)
                            : (isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCheated
                          ? 'Vous avez quitté la page du quiz pendant l\'épreuve. Votre tentative a été invalidée avec la note de 0/20 et transmise à votre enseignant.'
                          : (result.estExpiree
                              ? 'Tentative terminée (temps imparti expiré)'
                              : 'Copie corrigée et enregistrée sur les serveurs EduQuiz'),
                      style: TextStyle(
                        color: isCheated ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Métriques Clés
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isCheated ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isCheated ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetricItem(
                            'Note finale',
                            isCheated ? '0.0 / 20' : '${result.noteSur20} / 20',
                            isCheated
                                ? const Color(0xFFDC2626)
                                : (isSuccess ? const Color(0xFF65A30D) : const Color(0xFFDC2626)),
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                          _buildMetricItem(
                            'Score brut',
                            isCheated ? '0.0 / ${result.totalPointsPossible}' : '${result.score} / ${result.totalPointsPossible}',
                            isCheated ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                          _buildMetricItem(
                            'Taux Réussite',
                            isCheated ? '0 %' : '${result.pourcentage} %',
                            isCheated ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                          if (result.nbAvertissementsTriche > 0) ...[
                            Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                            _buildMetricItem(
                              'Avertissements',
                              '${result.nbAvertissementsTriche}',
                              const Color(0xFFDC2626),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (isSuccess) ...[
                      const SizedBox(height: 20),
                      Pulse3DButton(
                        backgroundColor: const Color(0xFFD97706),
                        shadowColor: const Color(0xFFB45309),
                        icon: Icons.workspace_premium,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        onPressed: () => _showCertificateDialog(
                            context,
                            studentName,
                            result.noteSur20,
                            mention,
                            result.nbAvertissementsTriche),
                        child: const Text(
                          '📜 Voir mon Attestation de Réussite',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (isStudent || result.corrige.isEmpty) ...[
                // Message pédagogique confidentiel pour les étudiants
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          size: 42,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Corrigé & Réponses Confidentiels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Votre copie a été enregistrée avec succès et votre note a été transmise à votre enseignant.\n\nConformément aux règles d\'évaluation académique, le corrigé détaillé des questions n\'est pas affiché aux étudiants.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Corrigé Détaillé et Explications (Réservé aux Enseignants / Admins)
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Corrigé & Explications Pédagogiques (Vue Enseignant)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${result.corrige.length} questions',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Puces de filtrage interactif
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Tout (${result.corrige.length})'),
                      selected: _selectedFilter == 0,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 0 ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) => setState(() => _selectedFilter = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Mes Erreurs ($errorsCount) ❌'),
                      selected: _selectedFilter == 1,
                      selectedColor: const Color(0xFFDC2626),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 1 ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) => setState(() => _selectedFilter = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Réussies ($successCount) ✅'),
                      selected: _selectedFilter == 2,
                      selectedColor: const Color(0xFF10B981),
                      labelStyle: TextStyle(
                        color: _selectedFilter == 2 ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) => setState(() => _selectedFilter = 2),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (filteredQuestions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune question ne correspond à ce filtre.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...filteredQuestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: q.estCorrecte ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: q.estCorrecte
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Question ${idx + 1}',
                                    style: TextStyle(
                                      color: q.estCorrecte ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${q.pointsObtenus} / ${q.pointsPossible} pt${q.pointsPossible > 1 ? "s" : ""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: q.estCorrecte ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              q.enonce,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 14),

                            ...q.options.map((opt) {
                              final isUserChoice = q.reponseUtilisateurOptionId == opt.id;
                              final isCorrect = opt.estCorrecte;

                              Color itemColor = Colors.grey.shade50;
                              Color borderColor = Colors.grey.shade200;
                              IconData? icon;
                              Color iconColor = Colors.grey;

                              if (isCorrect) {
                                itemColor = const Color(0xFFECFDF5);
                                borderColor = const Color(0xFF10B981);
                                icon = Icons.check_circle;
                                iconColor = const Color(0xFF10B981);
                              } else if (isUserChoice && !isCorrect) {
                                itemColor = const Color(0xFFFEF2F2);
                                borderColor = const Color(0xFFEF4444);
                                icon = Icons.cancel;
                                iconColor = const Color(0xFFEF4444);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    if (icon != null) ...[
                                      Icon(icon, color: iconColor, size: 20),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: Text(
                                        opt.texte,
                                        style: TextStyle(
                                          color: isCorrect
                                              ? const Color(0xFF047857)
                                              : (isUserChoice ? const Color(0xFFB91C1C) : Colors.black87),
                                          fontWeight: (isCorrect || isUserChoice)
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isUserChoice)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCorrect ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Votre réponse',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),

                            if (q.explicationCorrection != null &&
                                q.explicationCorrection!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb, color: Color(0xFF2563EB), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Explication : ${q.explicationCorrection}',
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],

              const SizedBox(height: 24),

              Pulse3DButton(
                width: double.infinity,
                backgroundColor: const Color(0xFF2563EB),
                shadowColor: const Color(0xFF1D4ED8),
                icon: Icons.home,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => context.go('/student'),
                child: const Text('Retour à mon espace étudiant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
