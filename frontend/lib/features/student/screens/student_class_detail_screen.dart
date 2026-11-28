import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class StudentClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const StudentClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends ConsumerState<StudentClassDetailScreen> {
  Map<String, dynamic>? _classe;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  int _selectedTab = 0; // 0: Quiz, 1: Membres / Camarades
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadClassDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClassDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final res = await apiClient.get('/classes/${widget.classId}');
      if (mounted) {
        setState(() {
          _classe = res.data as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = getErrorMessage(e, 'Impossible de charger la classe');
        });
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppAlert.success(context, '$label copié dans le presse-papiers !');
    }
  }

  void _confirmLeaveClass() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Quitter cette classe ?'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous désinscrire de la classe "${_classe?['nom'] ?? 'cette classe'}" ? Vous ne recevrez plus les nouveaux quiz assignés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiClient.delete('/classes/${widget.classId}/leave');
                if (mounted) {
                  AppAlert.success(context, 'Vous avez quitté la classe avec succès.');
                  context.go('/student/classes');
                }
              } catch (e) {
                if (mounted) {
                  AppAlert.error(context, getErrorMessage(e, 'Impossible de quitter la classe'));
                }
              }
            },
            child: const Text('Confirmer et quitter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const EdutechDashboardLayout(
        activeRoute: 'classes',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(60.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null || _classe == null) {
      return EdutechDashboardLayout(
        activeRoute: 'classes',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Classe introuvable',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.go('/student/classes'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour à mes classes'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final nomClasse = (_classe!['nom'] ?? 'Classe').toString();
    final codeClasse = (_classe!['codeClasse'] ?? '').toString();
    final enseignant = _classe!['enseignant'] as Map<String, dynamic>?;
    final profName = enseignant != null
        ? 'Prof. ${enseignant['prenom'] ?? ''} ${enseignant['nom'] ?? ''}'.trim()
        : 'Enseignant';
    final profEmail = enseignant != null ? (enseignant['email'] ?? '').toString() : '';

    final etudiants = (_classe!['etudiants'] as List<dynamic>? ?? []);
    final quizzes = (_classe!['quizAssignes'] as List<dynamic>? ?? []);

    // Compteur de quiz complétés par l'étudiant
    int completedQuizzesCount = 0;
    for (final q in quizzes) {
      final attempt = q['derniereTentative'];
      if (attempt != null && (attempt['statut'] == 'TERMINEE' || attempt['statut'] == 'EXPIREE')) {
        completedQuizzesCount++;
      }
    }

    // Filtrage pour la recherche
    final filteredQuizzes = quizzes.where((q) {
      if (_searchFilter.isEmpty) return true;
      final titre = (q['titre'] ?? '').toString().toLowerCase();
      final desc = (q['description'] ?? '').toString().toLowerCase();
      final qCode = (q['codeAcces'] ?? '').toString().toLowerCase();
      return titre.contains(_searchFilter) || desc.contains(_searchFilter) || qCode.contains(_searchFilter);
    }).toList();

    final filteredStudents = etudiants.where((item) {
      if (_searchFilter.isEmpty) return true;
      final etudiant = item['etudiant'] as Map<String, dynamic>? ?? {};
      final nom = (etudiant['nom'] ?? '').toString().toLowerCase();
      final prenom = (etudiant['prenom'] ?? '').toString().toLowerCase();
      final email = (etudiant['email'] ?? '').toString().toLowerCase();
      final full1 = '$prenom $nom'.toLowerCase();
      final full2 = '$nom $prenom'.toLowerCase();
      return nom.contains(_searchFilter) ||
          prenom.contains(_searchFilter) ||
          email.contains(_searchFilter) ||
          full1.contains(_searchFilter) ||
          full2.contains(_searchFilter);
    }).toList();

    final currentUser = ref.watch(authProvider).user;

    return EdutechDashboardLayout(
      activeRoute: 'classes',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bouton de retour vers mes classes
            InkWell(
              onTap: () => context.go('/student/classes'),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text(
                      'Toutes mes classes',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bandeau d'information si la classe a été supprimée par l'enseignant
            if (_classe!['estSupprimee'] == true) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cette classe a été supprimée par l\'enseignant',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Cette fiche reste affichée dans votre espace pour assurer la traçabilité de votre parcours. Les nouvelles inscriptions et sessions sont désormais closes.',
                            style: TextStyle(fontSize: 12.5, color: const Color(0xFFB91C1C).withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // En-tête de la classe de l'élève
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  final headerInfo = Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Center(
                          child: Icon(Icons.school, color: Color(0xFF2563EB), size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    nomClasse,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Text(
                                    'Inscrit',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profName,
                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.key, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CODE : $codeClasse',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _copyToClipboard(codeClasse, 'Code classe'),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.copy, size: 15, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final teacherQuickCard = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin, size: 24, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Enseignant référent', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Text(profName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          ],
                        ),
                        if (profEmail.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF2563EB)),
                            tooltip: 'Copier l\'email de l\'enseignant',
                            onPressed: () => _copyToClipboard(profEmail, 'Email de l\'enseignant'),
                          ),
                        ],
                      ],
                    ),
                  );

                  final leaveButton = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Quitter la classe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: _confirmLeaveClass,
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: headerInfo),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            teacherQuickCard,
                            const SizedBox(width: 12),
                            leaveButton,
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerInfo,
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: teacherQuickCard),
                            const SizedBox(width: 10),
                            leaveButton,
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // Cartes Bento Statistiques
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final cardWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      width: cardWidth,
                      title: 'Quiz disponibles',
                      value: '${quizzes.length}',
                      subtitle: 'Évaluations publiées par votre prof',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    _buildStatCard(
                      width: cardWidth,
                      title: 'Mes quiz complétés',
                      value: '$completedQuizzesCount / ${quizzes.length}',
                      subtitle: completedQuizzesCount == quizzes.length && quizzes.isNotEmpty
                          ? 'Tous les quiz sont terminés ! 🎉'
                          : 'Progressez à votre rythme',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                    _buildStatCard(
                      width: cardWidth,
                      title: 'Camarades de classe',
                      value: '${etudiants.length}',
                      subtitle: 'Élèves inscrits dans ce groupe',
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF5F3FF),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Barre de Navigation des Onglets & Recherche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 650;

                  final tabButtons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(
                        index: 0,
                        title: 'Quiz de la classe',
                        count: quizzes.length,
                        icon: Icons.quiz_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        index: 1,
                        title: 'Camarades & Enseignant',
                        count: etudiants.length,
                        icon: Icons.people_alt_outlined,
                      ),
                    ],
                  );

                  final searchField = SizedBox(
                    width: isWide ? 260 : double.infinity,
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchFilter = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: _selectedTab == 0 ? 'Filtrer les quiz...' : 'Rechercher un camarade...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        suffixIcon: _searchFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchFilter = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tabButtons,
                        searchField,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(scrollDirection: Axis.horizontal, child: tabButtons),
                        const SizedBox(height: 12),
                        searchField,
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // Contenu de l'onglet actif
            if (_selectedTab == 0)
              _buildQuizzesSection(filteredQuizzes, quizzes.length)
            else
              _buildStudentsSection(filteredStudents, etudiants.length, currentUser?.id),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _searchCtrl.clear();
          _searchFilter = '';
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section des Quiz assignés
  Widget _buildQuizzesSection(List<dynamic> quizzes, int totalCount) {
    if (totalCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: EduEmptyState(
          message: 'Aucun quiz disponible dans cette classe',
          subtitle: 'Votre enseignant publiera prochainement des devoirs et évaluations pour ce groupe.',
        ),
      );
    }

    if (quizzes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('Aucun quiz ne correspond à votre recherche.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: quizzes.map((q) {
            final id = q['id'].toString();
            final titre = (q['titre'] ?? 'Sans titre').toString();
            final description = (q['description'] ?? 'Aucune description').toString();
            final duree = q['dureeMinutes'] ?? 15;
            final codePin = (q['codeAcces'] ?? '').toString();
            final qCount = q['_count']?['questions'] ?? 0;
            final isSecurise = q['modeExamenSecurise'] == true;

            final attempt = q['derniereTentative'];
            final attStatut = attempt?['statut'];
            final isCheated = attStatut == 'ANNULEE_TRICHE';
            final isCompleted = attempt != null && (attStatut == 'TERMINEE' || attStatut == 'EXPIREE' || isCheated);
            final score = attempt != null ? (attempt['score'] as num?)?.toDouble() : null;
            final isClassDeleted = _classe?['estSupprimee'] == true;

            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCheated
                        ? const Color(0xFFFECACA)
                        : (isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                    width: (isCompleted || isCheated) ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isCheated) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.cancel, size: 12, color: Color(0xFFDC2626)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Fraude détectée • 0.0/20',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (isCompleted) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                                          const SizedBox(width: 4),
                                          Text(
                                            score != null ? 'Terminé • Note: ${score.toStringAsFixed(1)}/20' : 'Terminé',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: const Text(
                                        'À faire',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ],
                                  if (isSecurise) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield_outlined, size: 12, color: Color(0xFFEA580C)),
                                          SizedBox(width: 3),
                                          Text('Examen sécurisé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                titre,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildQuizBadge(Icons.timer_outlined, '$duree min'),
                        const SizedBox(width: 12),
                        _buildQuizBadge(Icons.help_outline, '$qCount questions'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'PIN: $codePin',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Pulse3DButton(
                        backgroundColor: isClassDeleted
                            ? const Color(0xFF94A3B8)
                            : (isCheated
                                ? const Color(0xFFDC2626)
                                : (isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB))),
                        shadowColor: isClassDeleted
                            ? const Color(0xFF64748B)
                            : (isCheated
                                ? const Color(0xFFB91C1C)
                                : (isCompleted ? const Color(0xFF047857) : const Color(0xFF1D4ED8))),
                        icon: isClassDeleted
                            ? Icons.block
                            : (isCompleted ? Icons.visibility : Icons.play_arrow),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        onPressed: isClassDeleted
                            ? () {
                                AppAlert.warning(context, 'Cette classe a été supprimée par l\'enseignant. Les quiz ne sont plus accessibles.');
                              }
                            : (isCompleted
                                ? () {
                                    final attId = attempt?['id'];
                                    if (attId != null) {
                                      context.push('/student/result?attemptId=$attId');
                                    } else {
                                      AppAlert.info(context, 'Vous avez déjà passé cette évaluation.');
                                    }
                                  }
                                : () => context.push('/student/quiz/$id')),
                        child: Text(
                          isClassDeleted
                              ? 'Classe supprimée'
                              : (isCheated
                                  ? 'Voir sanction (0/20)'
                                  : (isCompleted ? 'Voir mon résultat' : 'Commencer le quiz')),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuizBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  // Section des Camarades & Enseignant (avec badge « MOI » pour l'utilisateur connecté)
  Widget _buildStudentsSection(List<dynamic> studentItems, int totalCount, String? currentUserId) {
    if (studentItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('Aucun camarade ne correspond à votre recherche.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du tableau des camarades
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'NOM & PRÉNOM',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ADRESSE EMAIL',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'MEMBRE DEPUIS LE',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Liste des étudiants
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studentItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = studentItems[index];
              final etudiant = item['etudiant'] as Map<String, dynamic>? ?? {};
              final sId = (etudiant['id'] ?? '').toString();
              final nom = (etudiant['nom'] ?? '').toString();
              final prenom = (etudiant['prenom'] ?? '').toString();
              final fullName = '$prenom $nom'.trim().isEmpty ? 'Élève' : '$prenom $nom'.trim();
              final email = (etudiant['email'] ?? 'Sans email').toString();
              final dateRejointStr = (item['dateRejoint'] ?? item['dateInscription'] ?? '').toString();

              final isMe = currentUserId != null && sId == currentUserId;

              String formattedDate = '';
              if (dateRejointStr.isNotEmpty) {
                try {
                  final dt = DateTime.parse(dateRejointStr);
                  formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                } catch (_) {
                  formattedDate = dateRejointStr;
                }
              }

              // Initiales pour l'avatar
              String initials = '';
              if (prenom.isNotEmpty) initials += prenom[0].toUpperCase();
              if (nom.isNotEmpty) initials += nom[0].toUpperCase();
              if (initials.isEmpty) initials = 'E';

              // Couleurs d'avatar alternées
              final avatarColors = [
                const Color(0xFF2563EB),
                const Color(0xFF059669),
                const Color(0xFFD97706),
                const Color(0xFF7C3AED),
                const Color(0xFF0284C7),
              ];
              final avatarColor = isMe ? const Color(0xFF2563EB) : avatarColors[index % avatarColors.length];

              return Container(
                color: isMe ? const Color(0xFFF0FDF4) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Nom complet avec Avatar et badge « MOI »
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: avatarColor.withOpacity(0.12),
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: avatarColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                                      color: isMe ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'MOI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Email avec bouton de copie rapide
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline, size: 15, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(email, 'Adresse email'),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Date d'adhésion
                    Expanded(
                      flex: 2,
                      child: Text(
                        formattedDate.isNotEmpty ? formattedDate : '-',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
