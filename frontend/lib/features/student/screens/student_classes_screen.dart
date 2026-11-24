import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class StudentClassesScreen extends ConsumerStatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  ConsumerState<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends ConsumerState<StudentClassesScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/classes/student');
      setState(() {
        _classes = res.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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
              'Scannez le QR Code de votre classe ou saisissez le code d\'accès fourni par votre enseignant.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 16),

            // Option 1 : Scanner QR Code
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
                side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
                backgroundColor: const Color(0xFFEFF6FF),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/student/scan?mode=class');
              },
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text(
                'Scanner le QR Code de la classe',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),

            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OU PAR CODE MANUEL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 14),

            // Option 2 : Code manuel
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ex: MATH24',
                hintStyle: const TextStyle(letterSpacing: 0, fontSize: 13, color: Color(0xFFA1A1AA)),
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF1E40AF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              if (codeCtrl.text.trim().length < 4) return;
              try {
                await apiClient.post('/classes/join', data: {
                  'codeClasse': codeCtrl.text.trim().toUpperCase(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  AppAlert.success(context, 'Classe rejointe avec succès ! 🎉');
                  _loadClasses();
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
    return EdutechDashboardLayout(
      activeRoute: 'classes',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête Enseignant / Élève unifié
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
                      'Votre classe, où que vous soyez. Accédez aux cours et devoirs.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                    ),
                  ],
                ),
                Pulse3DButton(
                  backgroundColor: const Color(0xFF1E40AF),
                  shadowColor: const Color(0xFF1E3A8A),
                  icon: Icons.add,
                  onPressed: _showJoinClassDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Text('Rejoindre une classe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bandeau Pédagogique
            EdTechHeroBanner(
              tag: 'Espace Élève • Mes cours',
              title: 'Apprenez avec méthode. Révisez à votre rythme.',
              description: 'Rejoignez vos promotions et retrouvez en direct les quiz préparés par vos enseignants.',
              buttonText: 'Rejoindre une classe',
              onAction: _showJoinClassDialog,
              secondaryButtonText: 'Voir mes quiz',
              onSecondaryAction: () => context.go('/student/quizzes'),
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
                  message: 'Vous n\'avez rejoint aucune classe pour le moment',
                  subtitle: 'Rejoignez une classe avec le code fourni par votre enseignant ou en scannant le QR Code.',
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  final itemWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    children: _classes.asMap().entries.map((entry) {
                      final item = entry.value;
                      final classe = (item is Map && item['classe'] != null)
                          ? (item['classe'] as Map<String, dynamic>)
                          : (item as Map<String, dynamic>);

                      final title = (classe['nom'] ?? 'Classe').toString();
                      final classCode = (classe['codeClasse'] ?? classe['code'] ?? '').toString();
                      final teacher = classe['enseignant'] != null
                          ? 'Prof. ${classe['enseignant']['prenom'] ?? ''} ${classe['enseignant']['nom'] ?? ''}'.trim()
                          : 'Enseignant';
                      final studentCount = (classe['_count']?['etudiants'] as num?)?.toInt() ?? 0;

                      final colors = [
                        const Color(0xFF2563EB),
                        const Color(0xFF10B981),
                        const Color(0xFFF97316),
                        const Color(0xFF8B5CF6),
                      ];
                      final bgColors = [
                        const Color(0xFFEDE9FE),
                        const Color(0xFFD1FAE5),
                        const Color(0xFFFFEDD5),
                        const Color(0xFFE0E7FF),
                      ];
                      final symbols = ['∑', '🌱', '🏛️', '💻'];

                      final color = colors[entry.key % colors.length];
                      final bg = bgColors[entry.key % bgColors.length];
                      final sym = symbols[entry.key % symbols.length];

                      final classId = (classe['id'] ?? '').toString();
                      final isDeleted = (classe['estSupprimee'] == true);
                      String? deletedDateStr;
                      if (classe['dateSuppression'] != null) {
                        final d = DateTime.tryParse(classe['dateSuppression'].toString());
                        if (d != null) {
                          deletedDateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                        }
                      }

                      return SizedBox(
                        width: itemWidth,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: classId.isNotEmpty ? () => context.push('/student/classes/$classId') : null,
                            borderRadius: BorderRadius.circular(10),
                            child: EdTechClassCard(
                              title: title,
                              teacherName: teacher,
                              classCode: classCode,
                              studentCount: studentCount,
                              iconSymbol: sym,
                              headerBgColor: bg,
                              symbolColor: color,
                              isDeleted: isDeleted,
                              deletedDateStr: deletedDateStr,
                              onViewClass: () {
                                if (classId.isNotEmpty) {
                                  context.push('/student/classes/$classId');
                                } else {
                                  context.go('/student/quizzes');
                                }
                              },
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
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
