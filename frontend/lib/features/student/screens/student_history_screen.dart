import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/attempt_model.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/fade_slide_in.dart';

class StudentHistoryScreen extends ConsumerStatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  ConsumerState<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends ConsumerState<StudentHistoryScreen> {
  List<AttemptHistoryItemModel> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/attempts/my');
      final list = (res.data as List<dynamic>? ?? [])
          .map((item) => AttemptHistoryItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _attempts = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _attempts.length;
    final validAttempts = _attempts.where((a) => a.statut == 'TERMINEE' || a.score > 0).toList();
    final passedCount = validAttempts.where((a) {
      final scoreSur20 = a.score > 5.0 ? a.score : (a.score * 4.0);
      return scoreSur20 >= 10.0;
    }).length;
    final passRate = validAttempts.isNotEmpty ? ((passedCount / validAttempts.length) * 100).toInt() : 0;

    double avgScoreSur20 = 0.0;
    if (validAttempts.isNotEmpty) {
      final sum = validAttempts.fold<double>(0.0, (acc, a) {
        final scoreSur20 = a.score > 5.0 ? a.score : (a.score * 4.0);
        return acc + scoreSur20;
      });
      avgScoreSur20 = sum / validAttempts.length;
    }

    return EdutechDashboardLayout(
      activeRoute: 'results',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et sous-titre
            const Row(
              children: [
                Text(
                  'Mes Notes & Résultats',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(width: 8),
                Text('📊', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Retrouvez ici l\'historique complet de vos évaluations, vos scores et vos copies corrigées.',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
            ),
            const SizedBox(height: 24),

            // 3 Cartes de synthèse en haut
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final cardWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: _buildSummaryCard(
                        label: 'Évaluations passées',
                        value: '$totalCount',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEEF2FF),
                        width: cardWidth,
                      ),
                    ),
                    FadeSlideIn(
                      index: 1,
                      child: _buildSummaryCard(
                        label: 'Moyenne générale',
                        value: validAttempts.isNotEmpty ? '${avgScoreSur20.toStringAsFixed(1)}/20' : 'N/A',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                        width: cardWidth,
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: _buildSummaryCard(
                        label: 'Taux de réussite',
                        value: '$passRate%',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                        width: cardWidth,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            if (!_isLoading && _attempts.isNotEmpty)
              _buildScoreProgressionChart(),

            const Text(
              'Historique détaillé des évaluations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_attempts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const EduEmptyState(
                  message: 'Vous n\'avez encore passé aucun quiz',
                  subtitle: 'Vos évaluations terminées et vos résultats corrigés apparaîtront ici.',
                ),
              )
            else
              Column(
                children: _attempts.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isEnCours = item.statut == 'EN_COURS';
                  final isExpiree = item.statut == 'EXPIREE';
                  final isPass = !isEnCours && item.score >= 10.0;
                  final isMath = item.quizTitre.contains('Algèbre');
                  final isBio = item.quizTitre.contains('cellules') || item.quizTitre.contains('Biologie');
                  final subjectName = isMath ? 'Mathématiques' : (isBio ? 'Biologie' : 'Histoire');
                  final subjectColor = isMath
                      ? const Color(0xFF2563EB)
                      : (isBio ? const Color(0xFF10B981) : const Color(0xFFF43F5E));

                  return FadeSlideIn(
                    index: idx,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // Bordure gauche colorée
                            Container(width: 5, color: subjectColor),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    // Icône de validation / statut
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isPass ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPass ? Icons.check_circle_outline : Icons.assignment_turned_in_outlined,
                                        color: isPass ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Titre, date, sujet
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: subjectColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  subjectName,
                                                  style: TextStyle(
                                                    color: subjectColor,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${item.dateDebut.day}/${item.dateDebut.month}/${item.dateDebut.year} à ${item.dateDebut.hour}h${item.dateDebut.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.quizTitre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (item.nbAvertissementsTriche > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '⚠️ ${item.nbAvertissementsTriche} avertissement(s) perte de focus détecté(s)',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Note & Statut
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.score.toStringAsFixed(1)} / 20',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: item.score >= 10.0 ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: const Text(
                                            'Terminé',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
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
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreProgressionChart() {
    if (_attempts.isEmpty) return const SizedBox.shrink();

    // Tri chronologique des évaluations (de la plus ancienne à la plus récente)
    final finishedAttempts = _attempts
        .where((a) => a.statut == 'TERMINEE' || a.score > 0)
        .toList();
    final dataPool = finishedAttempts.isNotEmpty ? finishedAttempts : _attempts;
    // Affiche jusqu'aux 15 dernières évaluations pour couvrir l'historique complet sans surcharger l'axe
    final chartAttempts = dataPool.take(15).toList().reversed.toList();

    List<FlSpot> spots;
    if (chartAttempts.length == 1) {
      spots = [
        FlSpot(0, chartAttempts[0].score.clamp(0.0, 20.0)),
        FlSpot(1, chartAttempts[0].score.clamp(0.0, 20.0)),
      ];
    } else {
      spots = chartAttempts.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.score.clamp(0.0, 20.0));
      }).toList();
    }

    final double maxScore = chartAttempts.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    final double topY = (maxScore > 5 ? 20.0 : 5.0);

    return FadeSlideIn(
      index: 3,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.show_chart_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Courbe d\'évolution des scores',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Progression chronologique de vos dernières évaluations',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${chartAttempts.length} évaluation${chartAttempts.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: topY,
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: topY / 4,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: topY / 2,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}p',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= chartAttempts.length) return const SizedBox.shrink();
                          final att = chartAttempts[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${att.dateDebut.day}/${att.dateDebut.month}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF2563EB),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2563EB).withOpacity(0.18),
                            const Color(0xFF2563EB).withOpacity(0.01),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF0F172A),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final att = (idx >= 0 && idx < chartAttempts.length) ? chartAttempts[idx] : null;
                          return LineTooltipItem(
                            '${att?.quizTitre ?? 'Quiz'}\n${spot.y.toStringAsFixed(1)} pts',
                            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
