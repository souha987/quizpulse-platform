import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/quiz_model.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import 'share_modal.dart';

class TeacherQuizzesScreen extends ConsumerStatefulWidget {
  const TeacherQuizzesScreen({super.key});

  @override
  ConsumerState<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends ConsumerState<TeacherQuizzesScreen> {
  List<QuizModel> _quizzes = [];
  Map<String, dynamic>? _subData;
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _searchQuery = '';
  String _statusFilter = 'TOUS'; // TOUS, PUBLIC, PRIVE

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final quizRes = await apiClient.get('/quiz/teacher');
      final subRes = await apiClient.get('/subscriptions/my');

      final list = (quizRes.data as List<dynamic>? ?? [])
          .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _quizzes = list;
          _subData = subRes.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _duplicateQuiz(String quizId) async {
    try {
      await apiClient.post('/quiz/$quizId/duplicate');
      if (mounted) {
        AppAlert.success(context, 'Quiz dupliqué avec succès !');
        _loadData();
      }
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors de la duplication');
      if (mounted) {
        AppAlert.error(context, msg);
      }
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer définitivement ce quiz ? Cette action est irréversible et supprimera également l\'ensemble des résultats, notes et tentatives des étudiants associés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiClient.delete('/quiz/$quizId');
        if (mounted) {
          AppAlert.success(context, 'Quiz supprimé avec succès.');
        }
        _loadData();
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors de la suppression');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  Future<void> _togglePublicQuiz(QuizModel quiz) async {
    final willBePublic = !quiz.estPublic;
    try {
      await apiClient.put('/quiz/${quiz.id}', data: {
        'estPublic': willBePublic,
        if (willBePublic) 'statut': 'PUBLIE',
      });
      if (mounted) {
        if (willBePublic) {
          AppAlert.success(
            context,
            '« ${quiz.titre} » est désormais Public et affiché dans le catalogue public !',
          );
        } else {
          AppAlert.info(
            context,
            '« ${quiz.titre} » est désormais Privé (réservé aux classes ou code PIN).',
          );
        }
        _loadData();
      }
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors du changement de visibilité');
      if (mounted) {
        AppAlert.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlimited = _subData?['quotaQuiz'] == 'Illimité';
    final usedCount = _subData?['quizUtilisesCeMois'] ?? _quizzes.length;
    final maxQuota = isUnlimited ? 'Illimité' : '${_subData?['quotaQuiz'] ?? 5}';

    final filteredQuizzes = _quizzes.where((q) {
      final matchesSearch = _searchQuery.isEmpty ||
          q.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (q.matiereNom?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final bool matchesStatus;
      if (_statusFilter == 'TOUS') {
        matchesStatus = true;
      } else if (_statusFilter == 'PUBLIC') {
        matchesStatus = q.estPublic;
      } else if (_statusFilter == 'PRIVE') {
        matchesStatus = !q.estPublic;
      } else {
        matchesStatus = true;
      }
      return matchesSearch && matchesStatus;
    }).toList();

    return EdutechDashboardLayout(
      activeRoute: 'quiz',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête conforme au dashboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion de mes Quiz',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Créez, modifiez, dupliquez et partagez vos sujets d\'évaluation.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                    ),
                  ],
                ),
                Pulse3DButton(
                  backgroundColor: const Color(0xFF1E40AF),
                  shadowColor: const Color(0xFF1E3A8A),
                  icon: Icons.add_rounded,
                  onPressed: () => context.push('/teacher/quiz/create'),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Text('Créer un Quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Encadré Quota & Statut (Bleu royal #1E40AF pour Pro, Bleu pâle pour Gratuit)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isUnlimited ? const Color(0xFF1E40AF) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isUnlimited ? const Color(0xFF1D4ED8) : const Color(0xFFDBEAFE), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnlimited ? Colors.white.withOpacity(0.18) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUnlimited ? Icons.workspace_premium : Icons.pie_chart_outline_rounded,
                      color: isUnlimited ? Colors.white : const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUnlimited
                              ? 'Formule Enseignant Pro (Quiz Illimités Actifs ⚡)'
                              : 'Quota Mensuel de Création : $usedCount / $maxQuota quiz utilisés',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: isUnlimited ? Colors.white : const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isUnlimited
                              ? 'Vous bénéficiez de quiz illimités, du mode examen sécurisé anti-triche et de l\'export CSV.'
                              : 'Les comptes gratuits sont limités à 5 quiz par mois. Passez à la formule Pro pour débloquer l\'illimité.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isUnlimited ? const Color(0xFFDBEAFE) : const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlimited) ...[
                    const SizedBox(width: 12),
                    Pulse3DButton(
                      backgroundColor: const Color(0xFF2563EB),
                      shadowColor: const Color(0xFF1D4ED8),
                      onPressed: () => context.go('/teacher/subscription'),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      child: const Text('Passer Pro', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Barre de recherche et filtres de statut (Pilule)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre, matière...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
                    ),
                  ),
                ),
                _buildStatusFilterChip('Tous les quiz', 'TOUS'),
                _buildStatusFilterChip('Publics (Catalogue)', 'PUBLIC'),
                _buildStatusFilterChip('Privés (Classe/PIN)', 'PRIVE'),
              ],
            ),

            const SizedBox(height: 24),

            // Liste des Quiz
            if (_isLoading)
              const ShimmerLoading(
                child: Column(
                  children: [
                    QuizCardSkeleton(),
                    QuizCardSkeleton(),
                    QuizCardSkeleton(),
                  ],
                ),
              )
            else if (filteredQuizzes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const EduEmptyState(
                  message: 'Aucun quiz ne correspond à vos critères',
                  subtitle: 'Modifiez vos filtres ou créez une nouvelle évaluation pour enrichir votre catalogue.',
                ),
              )
            else
              Column(
                children: filteredQuizzes.asMap().entries.map((entry) {
                  return FadeSlideIn(
                    index: entry.key,
                    child: _buildTeacherQuizItem(entry.value),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: const Color(0xFF1E40AF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF27272A),
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFFE7E5E4)),
      ),
    );
  }

  Widget _buildTeacherQuizItem(QuizModel quiz) {
    final isMath = quiz.titre.contains('Algèbre') || quiz.matiereNom == 'Mathématiques';
    final isBio = quiz.titre.contains('cellules') || quiz.matiereNom == 'Biologie';
    final accentColor = isMath ? const Color(0xFF2563EB) : (isBio ? const Color(0xFF0284C7) : const Color(0xFF16A34A));

    final isPublished = quiz.statut == 'PUBLIE';
    final statusColor = isPublished ? const Color(0xFF10B981) : const Color(0xFF64748B);
    final statusBg = isPublished ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bordure latérale colorée
            Container(width: 5, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Badges Matière + Statut + PIN
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quiz.matiereNom ?? (isMath ? 'Mathématiques' : (isBio ? 'Biologie' : 'Histoire')),
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: quiz.estPublic ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: quiz.estPublic ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                quiz.estPublic ? Icons.public : Icons.lock_outline,
                                size: 12,
                                color: quiz.estPublic ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                quiz.estPublic ? 'Public' : 'Privé',
                                style: TextStyle(
                                  color: quiz.estPublic ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (quiz.modeExamenSecurise) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 12, color: Color(0xFFDC2626)),
                                SizedBox(width: 4),
                                Text('Anti-triche actif', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                        if (quiz.classeNom != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  quiz.classeNom!,
                                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'PIN : ${quiz.codeAcces}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Titre avec icône/emoji de matière & Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1, right: 6),
                          child: Text(
                            getSubjectEmoji(quiz.matiereNom ?? (isMath ? 'Mathématiques' : (isBio ? 'Biologie' : 'Histoire'))),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            quiz.titre,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
                          ),
                        ),
                      ],
                    ),
                    if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(quiz.description!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 16),

                    // Métadonnées
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.help_outline, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${quiz.nbQuestions ?? 0} questions', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${quiz.dureeMinutes} minutes', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('${quiz.nbTentatives ?? 0} copies rendues', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),

                    // Ligne des actions complètes de PLAN.md :
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // 1. Gérer / Éditer
                        Pulse3DButton(
                          backgroundColor: const Color(0xFF1E40AF),
                          shadowColor: const Color(0xFF1E3A8A),
                          icon: Icons.edit_outlined,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: const Text('Éditer le sujet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          onPressed: () => context.push('/teacher/quiz/${quiz.id}/edit'),
                        ),

                        // 2. Partager QR Code grand format & PIN (ShareModal de PLAN.md)
                        Pulse3DButton(
                          backgroundColor: Colors.white,
                          shadowColor: const Color(0xFFE7E5E4),
                          foregroundColor: const Color(0xFF18181B),
                          icon: Icons.qr_code_2_rounded,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onPressed: () => ShareModal.show(context, quiz),
                          child: const Text('Projeter (QR / PIN)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),

                        // 3. Voir Analytiques & Résultats du quiz
                        Pulse3DButton(
                          backgroundColor: Colors.white,
                          shadowColor: const Color(0xFFE7E5E4),
                          foregroundColor: const Color(0xFF18181B),
                          icon: Icons.bar_chart_rounded,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onPressed: () => context.push('/teacher/quiz/${quiz.id}/analytics'),
                          child: const Text('Résultats & Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),

                        // 4. Prévisualiser (Vue Étudiant)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF71717A),
                            side: const BorderSide(color: Color(0xFFE7E5E4)),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: const Text('Tester (Étudiant)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          onPressed: () => context.push('/student/quiz/${quiz.id}'),
                        ),

                        // 5. Basculer Public / Privé
                        IconButton(
                          tooltip: quiz.estPublic
                              ? 'Rendre Privé (retirer du catalogue public)'
                              : 'Rendre Public (afficher dans le catalogue public)',
                          icon: Icon(
                            quiz.estPublic ? Icons.public : Icons.public_off_outlined,
                            size: 19,
                            color: quiz.estPublic ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                          onPressed: () => _togglePublicQuiz(quiz),
                        ),

                        // 6. Dupliquer en 1 clic
                        IconButton(
                          tooltip: 'Dupliquer le quiz en 1 clic',
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () => _duplicateQuiz(quiz.id),
                        ),

                        // 7. Supprimer
                        IconButton(
                          tooltip: 'Supprimer ce quiz',
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _deleteQuiz(quiz.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
