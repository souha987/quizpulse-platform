import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  List<dynamic> _quizzes = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'TOUS'; // 'TOUS', 'PUBLIC', 'PRIVE'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/admin/quiz');
      setState(() {
        _quizzes = res.data['quizzes'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(String quizId, bool currentPublic, String quizTitle) async {
    try {
      final willBePublic = !currentPublic;
      await apiClient.put('/quiz/$quizId', data: {'estPublic': willBePublic, 'statut': 'PUBLIE'});
      if (mounted) {
        if (willBePublic) {
          AppAlert.success(
            context,
            '« $quizTitle » est désormais Public (catalogue)',
          );
        } else {
          AppAlert.info(
            context,
            '« $quizTitle » est désormais Privé (code PIN)',
          );
        }
      }
      _loadQuizzes();
    } catch (e) {
      if (mounted) {
        final msg = getErrorMessage(e, 'Erreur lors du changement de visibilité');
        AppAlert.error(context, msg);
      }
    }
  }

  Future<void> _deleteQuiz(String quizId, String quizTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'évaluation'),
        content: Text('Voulez-vous vraiment supprimer définitivement « $quizTitle » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
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
          AppAlert.success(context, 'Quiz supprimé avec succès');
          _loadQuizzes();
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors de la suppression');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  List<dynamic> get _filteredQuizzes {
    var list = _quizzes;
    if (_selectedStatusFilter == 'PUBLIC') {
      list = list.where((q) => q['estPublic'] == true).toList();
    } else if (_selectedStatusFilter == 'PRIVE') {
      list = list.where((q) => q['estPublic'] != true).toList();
    }
    final qSearch = _searchCtrl.text.trim().toLowerCase();
    if (qSearch.isNotEmpty) {
      list = list.where((q) {
        final title = (q['titre'] ?? '').toString().toLowerCase();
        final subject = (q['matiere'] ?? q['categorie']?['matiere']?['nom'] ?? '').toString().toLowerCase();
        final teacherName = '${q['enseignant']?['prenom'] ?? ''} ${q['enseignant']?['nom'] ?? ''}'.toLowerCase();
        return title.contains(qSearch) || subject.contains(qSearch) || teacherName.contains(qSearch);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredQuizzes;
    final totalCount = _quizzes.length;
    final publicCount = _quizzes.where((q) => q['estPublic'] == true).length;
    final privateCount = _quizzes.where((q) => q['estPublic'] != true).length;

    return EdutechDashboardLayout(
      activeRoute: 'admin_moderation',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & En-tête
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modération des Évaluations & Quiz',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18181B),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Examinez le contenu des quiz, contrôlez les publications et modifiez les statuts en direct.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF71717A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser la liste',
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF71717A)),
                  onPressed: _loadQuizzes,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Barre de Filtres & Recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Champ de recherche
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un quiz par titre, matière ou enseignant...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF2563EB)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            fillColor: const Color(0xFFFAF9F6),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Pastilles de synthèse rapides
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCount au total',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF27272A)),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFFA1A1AA))),
                            Text(
                              '$publicCount publics',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFFA1A1AA))),
                            Text(
                              '$privateCount privés',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Chips de visibilité
                  Row(
                    children: [
                      const Text(
                        'Visibilité :',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF71717A)),
                      ),
                      const SizedBox(width: 10),
                      _buildStatusFilterChip('Tous', 'TOUS'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Publics (Catalogue)', 'PUBLIC'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('Privés (Classe/PIN)', 'PRIVE'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Liste des Quiz
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFA1A1AA)),
                    SizedBox(height: 12),
                    Text(
                      'Aucun quiz ne correspond aux critères sélectionnés',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF27272A)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final q = filtered[index];
                  final quizId = (q['id'] ?? '').toString();
                  final titre = (q['titre'] ?? 'Sans titre').toString();
                  final matiere = (q['matiere'] ?? q['categorie']?['matiere']?['nom'] ?? 'Général').toString();
                  final isPublic = q['estPublic'] == true;
                  final duree = q['dureeMinutes'] ?? 15;
                  final questionsCount = q['_count']?['questions'] ?? 0;
                  final attemptsCount = q['_count']?['tentatives'] ?? 0;
                  final teacher = q['enseignant'];
                  final teacherName = teacher != null
                      ? '${teacher['prenom'] ?? ''} ${teacher['nom'] ?? ''}'.trim()
                      : 'Professeur inconnu';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Matière Icon Container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getSubjectColor(matiere).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getSubjectIcon(matiere),
                            color: _getSubjectColor(matiere),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Titre & Métadonnées
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF18181B),
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getSubjectColor(matiere).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      matiere,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _getSubjectColor(matiere),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPublic ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isPublic ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPublic ? Icons.public : Icons.lock_outline,
                                          size: 11,
                                          color: isPublic ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPublic ? 'Public' : 'Privé',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isPublic ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Auteur : $teacherName',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF52525B)),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$duree min',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$questionsCount questions',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFFA1A1AA)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$attemptsCount copies passées',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Actions Modération
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton Tester le Quiz
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF27272A),
                                side: const BorderSide(color: Color(0xFFE7E5E4)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.push('/student/quiz/$quizId'),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF2563EB)),
                              label: const Text('Tester', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),

                            // Menu Visibilité & Actions
                            PopupMenuButton<String>(
                              tooltip: 'Actions de modération',
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onSelected: (action) {
                                if (action == 'toggle_visibility') {
                                  _toggleVisibility(quizId, isPublic, titre);
                                } else if (action == 'delete') {
                                  _deleteQuiz(quizId, titre);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle_visibility',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isPublic ? Icons.lock_outline : Icons.public,
                                        size: 18,
                                        color: isPublic ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isPublic ? 'Rendre Privé (Code PIN)' : 'Rendre Public (Catalogue)',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                      SizedBox(width: 8),
                                      Text('Supprimer définitivement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFEF4444))),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune_rounded, size: 16, color: Color(0xFF27272A)),
                                    SizedBox(width: 6),
                                    Text('Gérer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF27272A))),
                                    Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF71717A)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String statusValue) {
    final isSelected = _selectedStatusFilter == statusValue;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = statusValue),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF52525B),
          ),
        ),
      ),
    );
  }

  String _formatStatusLabel(String statut) {
    switch (statut) {
      case 'PUBLIE':
        return 'Publié';
      case 'BROUILLON':
        return 'Brouillon';
      case 'ARCHIVE':
        return 'Archivé';
      default:
        return statut;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'PUBLIE':
        return const Color(0xFF047857);
      case 'BROUILLON':
        return const Color(0xFFB45309);
      case 'ARCHIVE':
      default:
        return const Color(0xFF475569);
    }
  }

  Color _getStatusBg(String statut) {
    switch (statut) {
      case 'PUBLIE':
        return const Color(0xFFECFDF5);
      case 'BROUILLON':
        return const Color(0xFFFEF3C7);
      case 'ARCHIVE':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusBorder(String statut) {
    switch (statut) {
      case 'PUBLIE':
        return const Color(0xFFA7F3D0);
      case 'BROUILLON':
        return const Color(0xFFFDE68A);
      case 'ARCHIVE':
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  Color _getSubjectColor(String matiere) {
    final lower = matiere.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF2563EB);
    if (lower.contains('bio') || lower.contains('svt')) return const Color(0xFF10B981);
    if (lower.contains('hist') || lower.contains('geo')) return const Color(0xFF0284C7);
    if (lower.contains('phys') || lower.contains('chim')) return const Color(0xFF0284C7);
    return const Color(0xFF8B5CF6);
  }

  IconData _getSubjectIcon(String matiere) {
    final lower = matiere.toLowerCase();
    if (lower.contains('math')) return Icons.functions_rounded;
    if (lower.contains('bio') || lower.contains('svt')) return Icons.eco_rounded;
    if (lower.contains('hist') || lower.contains('geo')) return Icons.account_balance_rounded;
    if (lower.contains('phys') || lower.contains('chim')) return Icons.science_rounded;
    return Icons.menu_book_rounded;
  }
}
