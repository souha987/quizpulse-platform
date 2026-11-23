import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class TeacherClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const TeacherClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends ConsumerState<TeacherClassDetailScreen> {
  Map<String, dynamic>? _classe;
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedTab = 0; // 0: Quiz, 1: Élèves
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _loadClassDetails();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClassDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await apiClient.get('/classes/${widget.classId}');
      setState(() {
        _classe = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e, 'Impossible de charger la classe');
      });
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppAlert.success(context, '$label copié dans le presse-papiers !');
    }
  }

  void _showShareClassDialog() {
    if (_classe == null) return;
    final code = (_classe!['codeClasse'] ?? '').toString();
    final nom = (_classe!['nom'] ?? 'Classe').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_2, color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Rejoindre la classe $nom',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les élèves peuvent rejoindre cette classe directement depuis leur espace étudiant en saisissant ce code ou en scannant le QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 190.0,
                  foregroundColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('CODE :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Color(0xFF2563EB)),
                      tooltip: 'Copier le code',
                      onPressed: () => _copyToClipboard(code, 'Code classe'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAssignQuizDialog() async {
    List<dynamic> myQuizzes = [];
    bool loadingQuizzes = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (loadingQuizzes) {
            apiClient.get('/quiz/teacher').then((res) {
              if (ctx.mounted) {
                setModalState(() {
                  final list = (res.data as List<dynamic>? ?? []);
                  // Filtrer les quiz qui ne sont pas déjà dans cette classe
                  myQuizzes = list.where((q) => q['classeId'] != widget.classId).toList();
                  loadingQuizzes = false;
                });
              }
            }).catchError((_) {
              if (ctx.mounted) {
                setModalState(() => loadingQuizzes = false);
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_task, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Assigner un Quiz existant'),
              ],
            ),
            content: SizedBox(
              width: 480,
              height: 380,
              child: loadingQuizzes
                  ? const Center(child: CircularProgressIndicator())
                  : myQuizzes.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun autre quiz disponible à assigner.\nCréez un nouveau quiz depuis l\'éditeur.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: myQuizzes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final q = myQuizzes[i];
                            final titre = (q['titre'] ?? 'Sans titre').toString();
                            final qCount = q['_count']?['questions'] ?? 0;
                            final duree = q['dureeMinutes'] ?? 15;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('$qCount questions • $duree min', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () async {
                                  try {
                                    await apiClient.put('/quiz/${q['id']}', data: {
                                      'classeId': widget.classId,
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      AppAlert.success(context, 'Quiz assigné à la classe avec succès !');
                                      _loadClassDetails();
                                    }
                                  } catch (e) {
                                    final msg = getErrorMessage(e, 'Erreur lors de l\'assignation');
                                    if (mounted) {
                                      AppAlert.error(context, msg);
                                    }
                                  }
                                },
                                child: const Text('Assigner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/teacher/quiz/create?classId=${widget.classId}');
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nouveau quiz pour cette classe'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unassignQuiz(String quizId, String quizTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Détacher le quiz de la classe'),
        content: Text('Voulez-vous retirer le quiz « $quizTitle » de cette classe ? Le quiz restera accessible dans vos quiz personnels.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Détacher'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiClient.put('/quiz/$quizId', data: {'classeId': null});
        if (mounted) {
          AppAlert.success(context, 'Quiz détaché de la classe.');
          _loadClassDetails();
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors du détachement');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  Future<void> _removeStudent(String studentId, String studentName) async {
    if (studentId.isEmpty) {
      AppAlert.error(context, 'Identifiant de l\'élève introuvable.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Retirer l\'élève', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
                children: [
                  const TextSpan(text: 'Voulez-vous vraiment retirer '),
                  TextSpan(
                    text: studentName,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const TextSpan(text: ' de cette classe ?'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'L\'élève n\'aura plus accès aux quiz assignés à cette classe.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.person_remove, size: 16),
            label: const Text('Retirer de la classe', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiClient.delete('/classes/${widget.classId}/students/$studentId');
        if (mounted) {
          AppAlert.success(context, '« $studentName » a été retiré de la classe avec succès.');
          _loadClassDetails();
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors du retrait de l\'élève');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  void _showEditClassDialog() {
    if (_classe == null) return;
    final nomCtrl = TextEditingController(text: (_classe!['nom'] ?? '').toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Modifier la classe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modifiez le nom de votre classe :',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom de la classe',
                hintText: 'Ex: Terminale S2 - Mathématiques',
                prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () async {
              final newName = nomCtrl.text.trim();
              if (newName.isEmpty) return;
              try {
                await apiClient.put('/classes/${widget.classId}', data: {'nom': newName});
                if (mounted) {
                  Navigator.pop(ctx);
                  AppAlert.success(context, 'Nom de la classe mis à jour avec succès !');
                  _loadClassDetails();
                }
              } catch (e) {
                final msg = getErrorMessage(e, 'Erreur lors de la modification');
                if (mounted) {
                  AppAlert.error(context, msg);
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass() async {
    if (_classe == null) return;
    final nom = (_classe!['nom'] ?? 'cette classe').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Supprimer la classe'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement la classe « $nom » ?\n\n'
          '• Tous les élèves seront retirés de cette classe.\n'
          '• Les quiz assignés ne seront pas supprimés et resteront dans votre bibliothèque.',
          style: const TextStyle(height: 1.4, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiClient.delete('/classes/${widget.classId}');
        if (mounted) {
          AppAlert.success(context, 'Classe supprimée avec succès.');
          context.go('/teacher/classes');
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors de la suppression de la classe');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  Future<void> _deleteQuizPermanent(String quizId, String quizTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Supprimer définitivement le quiz'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement le quiz « $quizTitle » ?\n\n'
          'Cette action est irréversible et supprimera le quiz ainsi que l\'historique des tentatives associées.',
          style: const TextStyle(height: 1.4, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          _loadClassDetails();
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors de la suppression du quiz');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
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
                  onPressed: () => context.go('/teacher/classes'),
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
    final etudiants = (_classe!['etudiants'] as List<dynamic>? ?? []);
    final quizzes = (_classe!['quizAssignes'] as List<dynamic>? ?? []);

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

    return EdutechDashboardLayout(
      activeRoute: 'classes',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bouton de retour vers la liste des classes
            InkWell(
              onTap: () => context.go('/teacher/classes'),
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

            // En-tête de la classe avec Titre, Code et Actions rapides
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
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
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

                  final headerButtons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showShareClassDialog,
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Partager le code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Pulse3DButton(
                        backgroundColor: const Color(0xFF2563EB),
                        shadowColor: const Color(0xFF1D4ED8),
                        icon: Icons.add_task,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onPressed: _showAssignQuizDialog,
                        child: const Text('Assigner un quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Options de la classe',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF475569)),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditClassDialog();
                          } else if (val == 'delete') {
                            _deleteClass();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text('Modifier le nom de la classe'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Supprimer la classe', style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: headerInfo),
                        const SizedBox(width: 16),
                        headerButtons,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerInfo,
                        const SizedBox(height: 16),
                        headerButtons,
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
                      title: 'Élèves inscrits',
                      value: '${etudiants.length}',
                      subtitle: 'Membres actifs dans la classe',
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    _buildStatCard(
                      width: cardWidth,
                      title: 'Quiz assignés',
                      value: '${quizzes.length}',
                      subtitle: 'Évaluations disponibles pour ce groupe',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                    _buildStatCard(
                      width: cardWidth,
                      title: 'Code d\'invitation',
                      value: codeClasse,
                      subtitle: 'À partager avec vos élèves',
                      icon: Icons.vpn_key_outlined,
                      color: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF5F3FF),
                      isMonospace: true,
                      onTap: () => _copyToClipboard(codeClasse, 'Code classe'),
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
                        title: 'Élèves inscrits',
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
                        hintText: _selectedTab == 0 ? 'Filtrer les quiz...' : 'Rechercher par nom ou email...',
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
              _buildStudentsSection(filteredStudents, etudiants.length),

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
    bool isMonospace = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      fontFamily: isMonospace ? 'monospace' : null,
                      letterSpacing: isMonospace ? 1.5 : -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
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
          message: 'Aucun quiz assigné à cette classe',
          subtitle: 'Attribuez un de vos quiz existants ou créez une nouvelle évaluation pour ce groupe.',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pulse3DButton(
                backgroundColor: const Color(0xFF2563EB),
                shadowColor: const Color(0xFF1D4ED8),
                icon: Icons.add_task,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                onPressed: _showAssignQuizDialog,
                child: const Text('Assigner un quiz existant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/teacher/quiz/create'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer un nouveau quiz', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
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
            final description = (q['description'] ?? 'Aucune description fournie').toString();
            final statut = (q['statut'] ?? 'BROUILLON').toString();
            final duree = q['dureeMinutes'] ?? 15;
            final codePin = (q['codeAcces'] ?? '').toString();
            final qCount = q['_count']?['questions'] ?? 0;
            final tCount = q['_count']?['tentatives'] ?? 0;
            final isSecurise = q['modeExamenSecurise'] == true;

            Color statusColor;
            Color statusBg;
            String statusText;

            switch (statut) {
              case 'PUBLIE':
                statusColor = const Color(0xFF059669);
                statusBg = const Color(0xFFECFDF5);
                statusText = 'Publié';
                break;
              case 'ARCHIVE':
                statusColor = const Color(0xFF64748B);
                statusBg = const Color(0xFFF1F5F9);
                statusText = 'Archivé';
                break;
              default:
                statusColor = const Color(0xFFD97706);
                statusBg = const Color(0xFFFEF3C7);
                statusText = 'Brouillon';
            }

            return SizedBox(
              width: cardWidth,
              child: Container(
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                    ),
                                  ),
                                  if (isSecurise) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield_outlined, size: 12, color: Color(0xFF2563EB)),
                                          SizedBox(width: 3),
                                          Text('Sécurisé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
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
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val == 'edit') {
                              context.push('/teacher/quiz/$id/edit');
                            } else if (val == 'analytics') {
                              context.push('/teacher/quiz/$id/analytics');
                            } else if (val == 'unassign') {
                              _unassignQuiz(id, titre);
                            } else if (val == 'delete_permanent') {
                              _deleteQuizPermanent(id, titre);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Text('Modifier le quiz'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'analytics',
                              child: Row(
                                children: [
                                  Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF10B981)),
                                  SizedBox(width: 8),
                                  Text('Voir les résultats'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'unassign',
                              child: Row(
                                children: [
                                  Icon(Icons.link_off, size: 18, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 8),
                                  Text('Détacher de la classe', style: TextStyle(color: Color(0xFFD97706))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete_permanent',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                  SizedBox(width: 8),
                                  Text('Supprimer définitivement', style: TextStyle(color: Color(0xFFEF4444))),
                                ],
                              ),
                            ),
                          ],
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
                        const SizedBox(width: 12),
                        _buildQuizBadge(Icons.check_circle_outline, '$tCount copies'),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFDBEAFE)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.push('/teacher/quiz/$id/edit'),
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: const Text('Éditer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF1D4ED8),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.push('/teacher/quiz/$id/analytics'),
                            icon: const Icon(Icons.bar_chart, size: 15),
                            label: const Text('Résultats', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
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

  // Section des Élèves inscrits
  Widget _buildStudentsSection(List<dynamic> studentItems, int totalCount) {
    if (totalCount == 0) {
      final code = (_classe!['codeClasse'] ?? '').toString();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            EduEmptyState(
              message: 'Aucun élève n\'a encore rejoint cette classe',
              subtitle: 'Invitez vos élèves à se connecter avec leur compte Étudiant et à entrer ce code unique :',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('CODE DE LA CLASSE : ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _copyToClipboard(code, 'Code classe'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
          child: Text('Aucun élève ne correspond à votre recherche.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 700;

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studentItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = studentItems[index];
              final etudiant = item['etudiant'] as Map<String, dynamic>? ?? {};
              final studentId = (etudiant['id'] ?? item['etudiantId'] ?? '').toString();
              final nom = (etudiant['nom'] ?? '').toString();
              final prenom = (etudiant['prenom'] ?? '').toString();
              final fullName = '$prenom $nom'.trim().isEmpty ? 'Élève sans nom' : '$prenom $nom'.trim();
              final email = (etudiant['email'] ?? 'Sans email').toString();
              final dateRejointStr = (item['dateRejoint'] ?? item['dateInscription'] ?? '').toString();

              String formattedDate = '';
              if (dateRejointStr.isNotEmpty) {
                try {
                  final dt = DateTime.parse(dateRejointStr);
                  formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                } catch (_) {
                  formattedDate = dateRejointStr;
                }
              }

              String initials = '';
              if (prenom.isNotEmpty) initials += prenom[0].toUpperCase();
              if (nom.isNotEmpty) initials += nom[0].toUpperCase();
              if (initials.isEmpty) initials = 'E';

              final avatarColors = [
                const Color(0xFF2563EB),
                const Color(0xFF059669),
                const Color(0xFFD97706),
                const Color(0xFF7C3AED),
                const Color(0xFF0284C7),
              ];
              final avatarColor = avatarColors[index % avatarColors.length];

              return Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: avatarColor.withOpacity(0.12),
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: avatarColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (formattedDate.isNotEmpty)
                                Text(
                                  'Inscrit le $formattedDate',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline, size: 15, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(email, 'Adresse email'),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _removeStudent(studentId, fullName),
                        icon: const Icon(Icons.person_remove_rounded, size: 16),
                        label: const Text(
                          'Retirer de la classe',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
              // En-tête du tableau d'élèves
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: const Color(0xFFF8FAFC),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                        'DATE D\'INSCRIPTION',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'ACTIONS',
                        textAlign: TextAlign.center,
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
                  final studentId = (etudiant['id'] ?? item['etudiantId'] ?? '').toString();
                  final nom = (etudiant['nom'] ?? '').toString();
                  final prenom = (etudiant['prenom'] ?? '').toString();
                  final fullName = '$prenom $nom'.trim().isEmpty ? 'Élève sans nom' : '$prenom $nom'.trim();
                  final email = (etudiant['email'] ?? 'Sans email').toString();
                  final dateRejointStr = (item['dateRejoint'] ?? item['dateInscription'] ?? '').toString();

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
                  final avatarColor = avatarColors[index % avatarColors.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Nom complet avec Avatar
                        Expanded(
                          flex: 3,
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
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

                        // Actions (Bouton Retirer direct + Menu)
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Retirer de la classe',
                                icon: const Icon(Icons.person_remove_rounded, size: 20, color: Color(0xFFEF4444)),
                                hoverColor: const Color(0xFFFEE2E2),
                                splashRadius: 20,
                                onPressed: () => _removeStudent(studentId, fullName),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (action) {
                                  if (action == 'copy_email') {
                                    _copyToClipboard(email, 'Adresse email');
                                  } else if (action == 'remove') {
                                    _removeStudent(studentId, fullName);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'copy_email',
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy, size: 16, color: Color(0xFF2563EB)),
                                        SizedBox(width: 8),
                                        Text('Copier l\'email', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove_outlined, size: 16, color: Color(0xFFEF4444)),
                                        SizedBox(width: 8),
                                        Text('Retirer de la classe', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      },
    );
  }
}
