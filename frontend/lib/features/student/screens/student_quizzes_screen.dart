import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/quiz_model.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class StudentQuizzesScreen extends ConsumerStatefulWidget {
  const StudentQuizzesScreen({super.key});

  @override
  ConsumerState<StudentQuizzesScreen> createState() => _StudentQuizzesScreenState();
}

class _StudentQuizzesScreenState extends ConsumerState<StudentQuizzesScreen> {
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  String? _selectedClassId; // null = toutes les classes
  String _selectedStatusFilter = 'TOUS'; // TOUS, A_FAIRE, TERMINE
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadQuizzes(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizzes({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/quiz/student/assigned');
      final list = (res.data as List<dynamic>? ?? [])
          .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _quizzes = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showJoinClassDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.school_outlined, color: Color(0xFF1E40AF), size: 22),
            SizedBox(width: 8),
            Text(
              'Rejoindre une classe',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saisissez le code à 6 caractères fourni par votre enseignant pour rejoindre sa classe.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 2),
              decoration: InputDecoration(
                labelText: 'Code de la classe',
                hintText: 'Ex: ABC123',
                prefixIcon: const Icon(Icons.key, color: Color(0xFF1E40AF), size: 20),
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              try {
                await apiClient.post('/classes/join', data: {'codeClasse': code});
                if (mounted) {
                  Navigator.pop(ctx);
                  AppAlert.success(context, 'Classe rejointe avec succès ! 🎉');
                  _loadQuizzes();
                }
              } catch (e) {
                if (mounted) {
                  AppAlert.error(context, getErrorMessage(e, 'Impossible de rejoindre la classe'));
                }
              }
            },
            child: const Text('Valider le code', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraire les classes uniques parmi les quiz assignés
    final Map<String, String> classesMap = {};
    for (final q in _quizzes) {
      if (q.classeId != null && q.classeNom != null) {
        classesMap[q.classeId!] = q.classeNom!;
      }
    }

    final filtered = _quizzes.where((q) {
      // Filtrer par classe
      if (_selectedClassId != null && q.classeId != _selectedClassId) {
        return false;
      }

      // Filtrer par statut (À faire vs Terminé)
      final statut = q.derniereTentative?['statut'];
      final isDone = q.derniereTentative != null && (statut == 'TERMINEE' || statut == 'EXPIREE' || statut == 'ANNULEE_TRICHE');
      if (_selectedStatusFilter == 'A_FAIRE' && isDone) {
        return false;
      }
      if (_selectedStatusFilter == 'TERMINE' && !isDone) {
        return false;
      }

      // Recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = q.titre.toLowerCase().contains(query);
        final matchSubject = q.matiereNom?.toLowerCase().contains(query) ?? false;
        final matchTeacher = q.enseignantNom?.toLowerCase().contains(query) ?? false;
        final matchClass = q.classeNom?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchSubject && !matchTeacher && !matchClass) {
          return false;
        }
      }

      return true;
    }).toList();

    return EdutechDashboardLayout(
      activeRoute: 'quiz',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz assignés',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Les évaluations assignées par vos professeurs dans les classes dont vous êtes membre.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                    ),
                  ],
                ),
                Pulse3DButton(
                  backgroundColor: const Color(0xFF1E40AF),
                  shadowColor: const Color(0xFF1E3A8A),
                  icon: Icons.add_rounded,
                  onPressed: _showJoinClassDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  child: const Text('Rejoindre une classe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Barre de recherche et filtres de statut
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un quiz, matière...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
                    ),
                  ),
                ),
                _buildStatusFilterChip('Tous (${_quizzes.length})', 'TOUS'),
                _buildStatusFilterChip(
                  'À compléter (${_quizzes.where((q) => q.derniereTentative == null || (q.derniereTentative!['statut'] != 'TERMINEE' && q.derniereTentative!['statut'] != 'EXPIREE' && q.derniereTentative!['statut'] != 'ANNULEE_TRICHE')).length})',
                  'A_FAIRE',
                ),
                _buildStatusFilterChip(
                  'Terminés (${_quizzes.where((q) => q.derniereTentative != null && (q.derniereTentative!['statut'] == 'TERMINEE' || q.derniereTentative!['statut'] == 'EXPIREE' || q.derniereTentative!['statut'] == 'ANNULEE_TRICHE')).length})',
                  'TERMINE',
                ),
              ],
            ),

            // Filtres par classe (si plus d'une classe)
            if (classesMap.length > 1) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes mes classes'),
                    selected: _selectedClassId == null,
                    onSelected: (_) => setState(() => _selectedClassId = null),
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: _selectedClassId == null ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: _selectedClassId == null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  ...classesMap.entries.map((entry) {
                    final isSel = _selectedClassId == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedClassId = entry.key),
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                      ),
                    );
                  }),
                ],
              ),
            ],

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_quizzes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EduMascot(mood: MascotMood.thinking, size: 85),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun quiz assigné pour le moment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vous n\'avez aucune évaluation en attente dans vos classes.\nRejoignez une classe avec le code d\'accès fourni par votre enseignant pour recevoir vos sujets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Pulse3DButton(
                      backgroundColor: const Color(0xFF1E40AF),
                      shadowColor: const Color(0xFF1E3A8A),
                      icon: Icons.add,
                      onPressed: _showJoinClassDialog,
                      child: const Text('Rejoindre une classe', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const EduEmptyState(
                  message: 'Aucun quiz assigné ne correspond à ces critères',
                  subtitle: 'Modifiez vos filtres ou effectuez une autre recherche.',
                ),
              )
            else
              Column(
                children: filtered.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final quiz = entry.value;
                  final attStatut = quiz.derniereTentative?['statut'];
                  final isCheated = attStatut == 'ANNULEE_TRICHE';
                  final isDone = quiz.derniereTentative != null && (attStatut == 'TERMINEE' || attStatut == 'EXPIREE' || isCheated);
                  final score = quiz.derniereTentative?['score'];
                  final attemptId = quiz.derniereTentative?['id'];

                  final isMath = quiz.titre.contains('Algèbre') || quiz.matiereNom == 'Mathématiques';
                  final isBio = quiz.titre.contains('cellules') || quiz.matiereNom == 'Biologie';
                  final color = isCheated
                      ? const Color(0xFFDC2626)
                      : (isMath
                          ? const Color(0xFF2563EB)
                          : (isBio ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)));

                  final statusLabel = isCheated
                      ? '⚠️ Fraude détectée • 0.0/20'
                      : (isDone
                          ? 'Complété • Note : ${score != null ? "${score}/20" : "Rendue"}'
                          : 'Classe : ${quiz.classeNom ?? "Assigné"}');

                  final buttonLabel = isCheated
                      ? 'Voir sanction (0/20)'
                      : (isDone ? 'Voir le résultat' : 'Commencer l\'évaluation');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FadeSlideIn(
                      index: idx,
                      child: EdTechQuizCard(
                        title: quiz.titre,
                        teacherName: quiz.enseignantNom != null ? 'Prof. ${quiz.enseignantNom}' : 'Enseignant',
                        subject: quiz.classeNom != null ? '${quiz.classeNom!} • ${quiz.matiereNom ?? "Évaluation"}' : (quiz.matiereNom ?? 'Évaluation'),
                        accentColor: color,
                        questionCount: quiz.nbQuestions ?? 0,
                        durationMinutes: quiz.dureeMinutes,
                        status: statusLabel,
                        pinCode: quiz.codeAcces,
                        buttonText: buttonLabel,
                        onAction: () {
                          if (isDone && attemptId != null) {
                            context.push('/student/result?attemptId=$attemptId');
                          } else {
                            _startQuizWithInstructions(
                              context: context,
                              quizId: quiz.id,
                              quizTitle: quiz.titre,
                              durationMinutes: quiz.dureeMinutes,
                              isSecurise: quiz.modeExamenSecurise,
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _startQuizWithInstructions({
    required BuildContext context,
    required String quizId,
    required String quizTitle,
    required int durationMinutes,
    required bool isSecurise,
  }) {
    if (!isSecurise) {
      context.push('/student/quiz/$quizId');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Consignes d\'Examen Sécurisé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de débuter : "$quizTitle"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Règle stricte anti-triche :\nNe quittez pas la page du quiz, ne changez pas d\'onglet et ne réduisez pas votre fenêtre. Toute sortie annulera immédiatement votre tentative avec la note définitive de 0.0/20 pour triche.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Durée allouée : $durationMinutes minute(s)',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/student/quiz/$quizId');
            },
            child: const Text('J\'ai compris, débuter', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = value),
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
}
