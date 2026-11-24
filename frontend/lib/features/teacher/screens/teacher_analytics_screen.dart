import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/quiz_model.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/edu_mascot.dart';

class TeacherAnalyticsScreen extends ConsumerStatefulWidget {
  final String? quizId;

  const TeacherAnalyticsScreen({super.key, this.quizId});

  @override
  ConsumerState<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends ConsumerState<TeacherAnalyticsScreen> {
  List<QuizModel> _myQuizzes = [];
  String? _selectedQuizId;
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedQuizId = widget.quizId;
    _initializeData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _selectedQuizId != null) {
        _loadAnalyticsForQuiz(_selectedQuizId!, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final quizRes = await apiClient.get('/quiz/teacher');
      final list = (quizRes.data as List<dynamic>? ?? [])
          .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _myQuizzes = list;
        if (_selectedQuizId == null && list.isNotEmpty) {
          _selectedQuizId = list.first.id;
        }
      });

      if (_selectedQuizId != null) {
        await _loadAnalyticsForQuiz(_selectedQuizId!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e, 'Impossible de charger la liste des quiz');
      });
    }
  }

  Future<void> _loadAnalyticsForQuiz(String qId, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await apiClient.get('/analytics/quiz/$qId');
      if (mounted) {
        setState(() {
          _analytics = res.data as Map<String, dynamic>;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = getErrorMessage(e, 'Impossible de charger les analytiques de ce quiz');
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_selectedQuizId == null) return;
    try {
      final res = await apiClient.get('/analytics/quiz/$_selectedQuizId/export-csv');
      final csvString = res.data.toString();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.file_download_done_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Export CSV des Notes Généré'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voici le fichier CSV prêt pour l\'administration et les bulletins :'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: SelectableText(
                        csvString,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppAlert.error(context, 'Erreur lors de l\'export CSV');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _analytics?['titre'] ?? 'Sélectionnez un quiz';
    final totalTentatives = (_analytics?['totalTentatives'] as num?)?.toInt() ?? 0;
    final scoreMoyen = (_analytics?['scoreMoyen'] as num?)?.toDouble() ?? 0.0;
    final tauxReussite = (_analytics?['tauxReussiteGlobal'] as num?)?.toInt() ?? 0;
    final questionStats = (_analytics?['tauxEchecParQuestion'] as List<dynamic>? ?? []);
    final studentAttempts = (_analytics?['tentativesEtudiants'] as List<dynamic>? ?? []);

    return EdutechDashboardLayout(
      activeRoute: 'results',
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
                      'Résultats & Analytiques',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Suivi des performances des promotions, distribution des notes et export CSV.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                    ),
                  ],
                ),
                if (_selectedQuizId != null && totalTentatives > 0)
                  Pulse3DButton(
                    backgroundColor: const Color(0xFF1E40AF),
                    shadowColor: const Color(0xFF1E3A8A),
                    icon: Icons.download_rounded,
                    onPressed: _exportCsv,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Text('Exporter CSV', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Sélecteur de Quiz Interactif
            if (_myQuizzes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 12),
                    const Text('Sujet analysé :', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF334155))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedQuizId,
                          isExpanded: true,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 14),
                          items: _myQuizzes.map((q) {
                            return DropdownMenuItem<String>(
                              value: q.id,
                              child: Text('${q.titre} (${q.matiereNom ?? "Général"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedQuizId = val);
                              _loadAnalyticsForQuiz(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              )
            else if (_myQuizzes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const EduEmptyState(
                  message: 'Aucune évaluation à analyser',
                  subtitle: 'Créez votre premier quiz pour visualiser les statistiques de vos élèves.',
                ),
              )
            else ...[
              // 4 Indicateurs Métriques Propres (EdTechStatCard)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;
                  final cards = [
                    EdTechStatCard(
                      title: 'Taux de réussite',
                      value: '$tauxReussite%',
                      subtitle: 'Moyenne générale',
                      icon: Icons.trending_up,
                      variationText: '+3.5%',
                      isVariationPositive: true,
                    ),
                    EdTechStatCard(
                      title: 'Score moyen',
                      value: '${(scoreMoyen * 4).toStringAsFixed(1)}/20',
                      subtitle: 'Note officielle promo',
                      icon: Icons.emoji_events_outlined,
                      variationText: 'Standard',
                      isVariationPositive: true,
                    ),
                    EdTechStatCard(
                      title: 'Copies rendues',
                      value: '$totalTentatives',
                      subtitle: 'Évaluations soumises',
                      icon: Icons.assignment_turned_in_outlined,
                      variationText: 'Total',
                      isVariationPositive: true,
                    ),
                    Builder(
                      builder: (context) {
                        final cheatCount = studentAttempts.where((att) =>
                            att['statut'] == 'ANNULEE_TRICHE' ||
                            att['tricheDetectee'] == true ||
                            ((att['nbAvertissementsTriche'] as num?)?.toInt() ?? 0) > 0).length;
                        return EdTechStatCard(
                          title: 'Alertes anti-triche',
                          value: '$cheatCount',
                          subtitle: cheatCount > 0 ? '$cheatCount cas de triche détecté(s)' : 'Intégrité respectée',
                          icon: cheatCount > 0 ? Icons.gavel_rounded : Icons.verified_user_outlined,
                          variationText: cheatCount > 0 ? 'Fraude' : 'Conforme',
                          isVariationPositive: cheatCount == 0,
                        );
                      },
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: cards.asMap().entries.map((entry) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: FadeSlideIn(
                            index: entry.key,
                            child: entry.value,
                          ),
                        ),
                      )).toList(),
                    );
                  } else {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cards.asMap().entries.map((entry) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: FadeSlideIn(
                          index: entry.key,
                          child: entry.value,
                        ),
                      )).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // Graphique en Barres du Taux d'Échec par Question (FL_CHART exigé dans PLAN.md)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Taux d\'Échec par Question',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 22),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Identifiez en un clin d\'œil les notions les plus difficiles et les erreurs fréquentes.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    if (totalTentatives == 0 || questionStats.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: const EduEmptyState(
                          message: 'Aucune copie rendue pour l\'instant',
                          subtitle: 'Le graphique apparaîtra dès que vos premiers élèves auront validé ce quiz.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final q = questionStats[groupIndex];
                                  return BarTooltipItem(
                                    '${q['enonce']}\nÉchec : ${rod.toY.toInt()}%',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < questionStats.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Q${index + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: questionStats.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final q = entry.value;
                              final rate = ((q['tauxEchecPourcent'] as num?)?.toDouble()) ?? 0.0;
                              final color = rate > 50 ? const Color(0xFFEF4444) : (rate > 25 ? const Color(0xFF1E40AF) : const Color(0xFF2563EB));

                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: rate > 0 ? rate : 5, // minimum visuel
                                    color: color,
                                    width: 22,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tableau des Copies Rendues (PLAN.md)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Copies Rendues par les Étudiants',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Notes officielles sur 20',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (studentAttempts.isEmpty)
                      const EduEmptyState(
                        message: 'Aucune copie rendue pour l\'instant',
                        subtitle: 'Aucun élève n\'a encore complété cette évaluation.',
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 28,
                          columns: const [
                            DataColumn(label: Text('Étudiant', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Note sur 20', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Score brut', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Intégrité Anti-Triche', style: TextStyle(fontWeight: FontWeight.w800))),
                          ],
                          rows: studentAttempts.map((att) {
                            final isCheated = att['statut'] == 'ANNULEE_TRICHE' ||
                                (att['tricheDetectee'] == true) ||
                                ((att['nbAvertissementsTriche'] as num?)?.toInt() ?? 0) > 0;
                            final note = isCheated ? 0.0 : ((att['noteSur20'] as num?)?.toDouble() ?? 0.0);
                            final isPass = !isCheated && note >= 10.0;
                            final studentDisplayName = att['etudiantNom'] ??
                                '${att['prenom'] ?? ""} ${att['nom'] ?? ""}'.trim();
                            final initial = (att['prenom'] as String?)?.isNotEmpty == true
                                ? att['prenom'][0]
                                : (studentDisplayName.isNotEmpty ? studentDisplayName[0] : "E");

                            return DataRow(
                              color: isCheated ? MaterialStateProperty.all(const Color(0xFFFEF2F2)) : null,
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isCheated ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                                        child: Text(
                                          '$initial',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isCheated ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(studentDisplayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          if (isCheated)
                                            const Text(
                                              'A quitté l\'épreuve',
                                              style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(att['email'] ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCheated
                                          ? const Color(0xFFFEE2E2)
                                          : (isPass ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: isCheated ? Border.all(color: const Color(0xFFFCA5A5)) : null,
                                    ),
                                    child: Text(
                                      isCheated ? '0.0 / 20' : '$note / 20',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isCheated
                                            ? const Color(0xFFDC2626)
                                            : (isPass ? const Color(0xFF10B981) : const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(isCheated ? '0 pts (Annulé)' : '${att['score']} pts')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCheated ? const Color(0xFFDC2626) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCheated ? Icons.gavel_rounded : Icons.check_circle_outline,
                                          color: isCheated ? Colors.white : const Color(0xFF10B981),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCheated ? 'TRICHE DÉTECTÉE' : 'Conforme (Intégrité OK)',
                                          style: TextStyle(
                                            color: isCheated ? Colors.white : const Color(0xFF047857),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color cardBg,
    required Color borderColor,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF71717A)),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF18181B), letterSpacing: -0.8),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
