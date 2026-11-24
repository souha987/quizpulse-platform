import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class TeacherClassesScreen extends ConsumerStatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  ConsumerState<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends ConsumerState<TeacherClassesScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadClasses(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClasses({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/classes/teacher');
      if (mounted) {
        setState(() {
          _classes = res.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateClassDialog() {
    final nomCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Créer une Nouvelle Classe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un code unique à 6 caractères sera généré pour permettre à vos élèves de la rejoindre.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la classe',
                hintText: 'Ex: Mathématiques Spécialité',
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

              if (_classes.any((c) => (c['nom'] ?? '').toString().trim().toLowerCase() == newName.toLowerCase())) {
                AppAlert.warning(context, 'Vous avez déjà une classe portant le nom "$newName".');
                return;
              }

              try {
                await apiClient.post('/classes', data: {'nom': newName});
                if (mounted) {
                  Navigator.pop(ctx);
                  AppAlert.success(context, 'Classe créée avec succès !');
                  _loadClasses();
                }
              } catch (e) {
                final msg = getErrorMessage(e, 'Erreur lors de la création');
                if (mounted) {
                  AppAlert.error(context, msg);
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(Map<String, dynamic> item) {
    final nomCtrl = TextEditingController(text: (item['nom'] ?? '').toString());

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
              'Modifiez l\'intitulé de votre classe pour vous et vos élèves.',
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

              if (_classes.any((c) => c['id'] != item['id'] && (c['nom'] ?? '').toString().trim().toLowerCase() == newName.toLowerCase())) {
                AppAlert.warning(context, 'Vous avez déjà une classe portant le nom "$newName".');
                return;
              }

              try {
                await apiClient.put('/classes/${item['id']}', data: {'nom': newName});
                if (mounted) {
                  Navigator.pop(ctx);
                  AppAlert.success(context, 'Classe mise à jour avec succès !');
                  _loadClasses();
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

  Future<void> _deleteClass(Map<String, dynamic> item) async {
    final nom = (item['nom'] ?? 'cette classe').toString();
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
          'Voulez-vous vraiment supprimer la classe « $nom » ?\n\n'
          '• Les inscriptions des étudiants à cette classe seront révoquées.\n'
          '• Les quiz assignés resteront intacts dans votre bibliothèque de quiz.',
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
        await apiClient.delete('/classes/${item['id']}');
        if (mounted) {
          AppAlert.success(context, 'Classe supprimée avec succès.');
          _loadClasses();
        }
      } catch (e) {
        final msg = getErrorMessage(e, 'Erreur lors de la suppression');
        if (mounted) {
          AppAlert.error(context, msg);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EdutechDashboardLayout(
      activeRoute: 'classes',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête Enseignant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes classes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Votre classe, où que vous soyez. Suivez vos promotions et partagez vos évaluations.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                    ),
                  ],
                ),
                Pulse3DButton(
                  backgroundColor: const Color(0xFF1E40AF),
                  shadowColor: const Color(0xFF1E3A8A),
                  icon: Icons.add,
                  onPressed: _showCreateClassDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Text('Créer une classe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bandeau Pédagogique (Rôle Enseignant : Dégradé Indigo / Violet)
            EdTechHeroBanner(
              tag: 'Espaces de cours • Gestion des groupes',
              title: 'Organisez vos cohortes et facilitez le suivi.',
              description: 'Attribuez des quiz ciblés à chaque classe, analysez leurs résultats individuels ou collectifs.',
              buttonText: 'Nouvelle classe',
              onAction: _showCreateClassDialog,
              secondaryButtonText: 'Voir tous les quiz',
              onSecondaryAction: () => context.go('/teacher/quizzes'),
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            const SizedBox(height: 28),

            // Grille des Cartes de Classes Réelles
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_classes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: EduEmptyState(
                  message: 'Aucune classe créée pour le moment',
                  subtitle: 'Cliquez sur « Nouvelle classe » ci-dessus pour inviter vos élèves et leur assigner des quiz.',
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  final itemWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

                  final colors = [
                    const Color(0xFF2563EB),
                    const Color(0xFF10B981),
                    const Color(0xFFF97316),
                    const Color(0xFF8B5CF6),
                  ];
                  final symbols = ['∑', '🌱', '🏛️', '💻', '🧪'];

                  return Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    children: _classes.asMap().entries.map((entry) {
                      final item = entry.value;
                      final nom = (item['nom'] ?? 'Classe') as String;
                      final code = (item['codeClasse'] ?? item['code'] ?? '') as String;
                      final nb = (item['_count']?['etudiants'] ?? (item['etudiants'] is List ? (item['etudiants'] as List).length : 0)) as int;
                      final user = ref.watch(authProvider).user;
                      final prof = user != null ? 'Prof. ${user.prenom} ${user.nom}'.trim() : 'Enseignant';
                      final symbol = symbols[entry.key % symbols.length];
                      final accent = colors[entry.key % colors.length];

                      final qCount = (item['_count']?['quizAssignes'] ?? 0) as int;

                      return SizedBox(
                        width: itemWidth,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/teacher/classes/${item['id']}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 74,
                                    width: double.infinity,
                                    color: const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              symbol,
                                              style: TextStyle(fontSize: 20, color: accent, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: const Color(0xFFE7E5E4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.people_alt_outlined, size: 13, color: Color(0xFF71717A)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$nb élèves',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF71717A),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 11)),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.assignment_outlined, size: 13, color: Color(0xFF71717A)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$qCount quiz',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF71717A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          tooltip: 'Options de la classe',
                                          icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF71717A)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showEditClassDialog(item);
                                            } else if (val == 'delete') {
                                              _deleteClass(item);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                                  SizedBox(width: 8),
                                                  Text('Modifier la classe'),
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
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nom,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF18181B),
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          prof,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF71717A),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4F4F5),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFE4E4E7)),
                                              ),
                                              child: Text(
                                                'CODE : $code',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF27272A),
                                                ),
                                              ),
                                            ),
                                            Pulse3DButton(
                                              backgroundColor: Colors.white,
                                              shadowColor: const Color(0xFFE7E5E4),
                                              foregroundColor: const Color(0xFF18181B),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              onPressed: () => context.push('/teacher/classes/${item['id']}'),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Voir la classe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward, size: 13),
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
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 48),
            const Center(
              child: Text(
                'Pour les esprits curieux. Un petit progrès chaque jour. ✨',
                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
