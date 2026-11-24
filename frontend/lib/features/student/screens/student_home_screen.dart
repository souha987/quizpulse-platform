import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/attempt_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/count_up_text.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  List<dynamic> _myClasses = [];
  List<AttemptHistoryItemModel> _recentAttempts = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadDashboardData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final classesRes = await apiClient.get('/classes/student');
      final attemptsRes = await apiClient.get('/attempts/my');
      final attemptsList = (attemptsRes.data as List<dynamic>? ?? [])
          .map((a) => AttemptHistoryItemModel.fromJson(a as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _myClasses = classesRes.data as List<dynamic>;
          _recentAttempts = attemptsList;
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
                  _loadDashboardData();
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
    final user = ref.watch(authProvider).user;
    final firstName = user?.prenom ?? 'Élève';

    // Calcul du score moyen
    double avgScore = 0.0;
    if (_recentAttempts.isNotEmpty) {
      final valid = _recentAttempts.where((a) => a.score != null).toList();
      if (valid.isNotEmpty) {
        final sum = valid.fold<double>(0.0, (acc, item) => acc + item.score!);
        avgScore = (sum / valid.length);
      }
    }

    final completedAttempts = _recentAttempts.where((a) => a.statut == 'TERMINEE' || a.statut == 'EXPIREE').length;
    final participationRate = _recentAttempts.isNotEmpty
        ? '${((completedAttempts / _recentAttempts.length) * 100).round()}%'
        : '0%';

    return EdutechDashboardLayout(
      activeRoute: 'dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau d'Accueil Bleu & Blanc (Rôle Étudiant : Dégradé Bleu)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ESPACE ÉLÈVE • TABLEAU DE BORD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bonjour, $firstName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Suivez vos classes, vos quiz en attente et l\'historique complet de vos résultats d\'évaluation.',
                          style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E40AF),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              onPressed: _showJoinClassDialog,
                              icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF1E40AF)),
                              label: const Text(
                                'Rejoindre une classe',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E40AF),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              onPressed: () => context.go('/student/quizzes'),
                              icon: const Icon(Icons.quiz_outlined, size: 16, color: Color(0xFF1E40AF)),
                              label: const Text(
                                'Accéder à mes quiz',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.of(context).size.width > 500) ...[
                    const SizedBox(width: 20),
                    const EduMascot(
                      mood: MascotMood.happy,
                      size: 110,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Cartes Métriques Professionnelles (Blanches avec icônes bleues)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: _buildMetricCard(
                        width: cardWidth.clamp(160.0, 360.0),
                        icon: Icons.school_outlined,
                        title: 'Classes Rejointes',
                        value: '${_myClasses.length}',
                        subtitle: 'Groupes de cours actifs',
                      ),
                    ),
                    FadeSlideIn(
                      index: 1,
                      child: _buildMetricCard(
                        width: cardWidth.clamp(160.0, 360.0),
                        icon: Icons.task_alt_outlined,
                        title: 'Quiz Complétés',
                        value: '${_recentAttempts.length}',
                        subtitle: 'Copies enregistrées',
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: _buildMetricCard(
                        width: cardWidth.clamp(160.0, 360.0),
                        icon: Icons.analytics_outlined,
                        title: 'Score Moyen',
                        value: avgScore > 0 ? '${avgScore.toStringAsFixed(1)}/20' : 'N/A',
                        subtitle: 'Sur l\'ensemble des quiz',
                      ),
                    ),
                    FadeSlideIn(
                      index: 3,
                      child: _buildMetricCard(
                        width: cardWidth.clamp(160.0, 360.0),
                        icon: Icons.verified_outlined,
                        title: 'Participation',
                        value: participationRate,
                        subtitle: 'Assiduité aux épreuves',
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Section 2 Colonnes Web : Classes & Dernières Évaluations
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRecentAttemptsSection()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildMyClassesSection()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildRecentAttemptsSection(),
                      const SizedBox(height: 16),
                      _buildMyClassesSection(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CountUpText(
            value: value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttemptsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Derniers Quiz Rendus',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/student/history'),
                child: const Text('Voir tout l\'historique', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_recentAttempts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const EduEmptyState(
                message: 'Aucune tentative enregistrée',
                subtitle: 'Vos dernières évaluations et vos résultats apparaîtront ici.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentAttempts.length > 5 ? 5 : _recentAttempts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final att = _recentAttempts[index];
                final quizTitle = att.quizTitre ?? 'Évaluation';
                final score = att.score;
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(att.dateDebut);
                final isEnCours = att.statut == 'EN_COURS';
                final isExpiree = att.statut == 'EXPIREE';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF2563EB), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quizTitle,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(dateStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: score >= 10 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: score >= 10 ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(1)} / 20',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: score >= 10 ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
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

  Widget _buildMyClassesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes Classes',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 20),
                tooltip: 'Rejoindre une classe',
                onPressed: _showJoinClassDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_myClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: EduEmptyState(
                message: 'Vous n\'avez rejoint aucune classe',
                subtitle: 'Rejoignez votre première classe à l\'aide d\'un code fourni par votre enseignant.',
                action: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _showJoinClassDialog,
                  child: const Text('Rejoindre avec un code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myClasses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = _myClasses[index];
                final cls = (item is Map && item['classe'] != null)
                    ? item['classe'] as Map<String, dynamic>
                    : item as Map<String, dynamic>;
                final classId = (cls['id'] ?? '').toString();
                final nom = (cls['nom'] ?? 'Classe').toString();
                final code = (cls['codeClasse'] ?? '').toString();
                final enseignant = cls['enseignant'];
                final profName = enseignant != null
                    ? '${enseignant['prenom'] ?? ''} ${enseignant['nom'] ?? ''}'.trim()
                    : 'Enseignant';

                return InkWell(
                  onTap: classId.isNotEmpty ? () => context.push('/student/classes/$classId') : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.school_outlined, color: Color(0xFF2563EB), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nom,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              Text(profName, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
