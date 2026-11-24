import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/quiz_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/edu_mascot.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  List<QuizModel> _quizzes = [];
  List<dynamic> _classes = [];
  Map<String, dynamic>? _subData;
  Map<String, dynamic>? _overview;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadTeacherData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeacherData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      List<QuizModel> quizzesList = [];
      try {
        final quizRes = await apiClient.get('/quiz/teacher');
        quizzesList = (quizRes.data as List<dynamic>? ?? [])
            .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}

      Map<String, dynamic>? sub;
      try {
        final subRes = await apiClient.get('/subscriptions/my');
        sub = subRes.data as Map<String, dynamic>?;
      } catch (_) {}

      List<dynamic> classesList = [];
      try {
        final classesRes = await apiClient.get('/classes/teacher');
        classesList = classesRes.data as List<dynamic>? ?? [];
      } catch (_) {}

      Map<String, dynamic>? overview;
      try {
        final overviewRes = await apiClient.get('/analytics/teacher/overview');
        overview = overviewRes.data as Map<String, dynamic>?;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _quizzes = quizzesList;
          _subData = sub;
          _classes = classesList;
          _overview = overview;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profName = user != null ? '${user.prenom} ${user.nom}'.trim() : 'Enseignant';

    return EdutechDashboardLayout(
      activeRoute: 'dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête Enseignant
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Bonjour, Prof. $profName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('👋', style: TextStyle(fontSize: 26)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE7E5E4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF71717A)),
                      SizedBox(width: 6),
                      Text(
                        'Semestre d\'Automne 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Votre prochain cours commence ici. Pilotez vos évaluations et analysez vos promotions.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF71717A)),
            ),
            const SizedBox(height: 24),

            // 1. Bandeau d'accueil Enseignant (Dégradé Indigo / Violet)
            EdTechHeroBanner(
              tag: 'Espace Pédagogique • Vue d\'ensemble',
              title: 'Éveillez la curiosité. Évaluez avec sérénité.',
              description: 'Pilotez vos évaluations, gérez vos classes et analysez les copies de vos élèves en temps réel.',
              buttonText: 'Créer un quiz',
              onAction: () => context.push('/teacher/quiz/create'),
              secondaryButtonText: 'Gérer mes classes',
              onSecondaryAction: () => context.push('/teacher/classes'),
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            const SizedBox(height: 24),

            // 2. Grille de cartes Bento (Données réelles issues de la base)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final activeClasses = _overview?['activeClassesCount'] ?? _classes.length;
                final totalStudents = _overview?['totalStudents'] ?? 0;
                final publishedCount = _overview?['publishedQuizzesCount'] ?? _quizzes.where((q) => q.statut == 'PUBLIE').length;
                final totalQuizzes = _overview?['totalQuizzesCount'] ?? _quizzes.length;
                final avgScore = _overview?['generalAverage'];
                final totalSubmissions = _overview?['totalSubmissions'] ?? 0;

                final cards = [
                  EdTechStatCard(
                    title: 'Classes actives',
                    value: '$activeClasses',
                    subtitle: '$totalStudents élèves inscrits',
                    icon: Icons.school_outlined,
                    variationText: activeClasses > 0 ? '$activeClasses créées' : '0',
                    isVariationPositive: activeClasses > 0,
                  ),
                  EdTechStatCard(
                    title: 'Quiz publiés',
                    value: '$publishedCount',
                    subtitle: 'Sur $totalQuizzes au total',
                    icon: Icons.quiz_outlined,
                    variationText: publishedCount > 0 ? '$publishedCount en ligne' : '0',
                    isVariationPositive: publishedCount > 0,
                  ),
                  EdTechStatCard(
                    title: 'Moyenne générale',
                    value: (avgScore != null && avgScore > 0) ? '${avgScore.toStringAsFixed(1)}/20' : 'N/A',
                    subtitle: 'Moyenne des évaluations',
                    icon: Icons.trending_up,
                    variationText: (avgScore != null && avgScore >= 10) ? 'Conforme' : 'Standard',
                    isVariationPositive: avgScore != null && avgScore >= 10,
                  ),
                  EdTechStatCard(
                    title: 'Copies rendues',
                    value: '$totalSubmissions',
                    subtitle: 'Total copies enregistrées',
                    icon: Icons.pending_actions_outlined,
                    variationText: totalSubmissions > 0 ? 'Traitées' : '0',
                    isVariationPositive: totalSubmissions > 0,
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

            // 3. Bento Grid : Tableau de quiz réels à gauche & Quotas / Classes à droite
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 920;

                final mainContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête "Vos quiz"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Vos quiz récents',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_quizzes.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => context.go('/teacher/quizzes'),
                          child: const Row(
                            children: [
                              Text(
                                'Tout voir',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tableau / Cartes des vrais quiz de l'enseignant
                    if (_quizzes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: EduEmptyState(
                          message: 'Aucun quiz créé pour le moment',
                          subtitle: 'Cliquez sur « Créer un quiz » ci-dessus pour lancer votre première évaluation.',
                        ),
                      )
                    else
                      Column(
                        children: _quizzes.take(3).toList().asMap().entries.map((entry) {
                          final idx = entry.key;
                          final quiz = entry.value;
                          final tag = quiz.matiereNom?.isNotEmpty == true ? quiz.matiereNom![0].toUpperCase() : 'Q';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FadeSlideIn(
                              index: idx,
                              child: _buildModernQuizRow(
                                context,
                                intentTag: tag,
                                intentColor: const Color(0xFF2563EB),
                                intentBg: const Color(0xFFEFF6FF),
                                subject: quiz.matiereNom ?? 'Général',
                                title: quiz.titre,
                                teacher: profName.isNotEmpty ? 'Prof. $profName' : 'Enseignant',
                                duration: '${quiz.dureeMinutes} min',
                                questions: '${quiz.nbQuestions ?? quiz.questions?.length ?? 0} questions',
                                pinCode: quiz.codeAcces ?? 'N/A',
                                status: quiz.statut == 'PUBLIE' ? 'Publié' : (quiz.statut == 'BROUILLON' ? 'Brouillon' : 'Archivé'),
                                onManage: () => context.push('/teacher/quiz/${quiz.id}/edit'),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),

                    // Section "Derniers travaux rendus" (Données réelles de la BD)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Derniers travaux rendus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/teacher/analytics'),
                          child: const Row(
                            children: [
                              Text(
                                'Tout voir',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Builder(
                      builder: (context) {
                        final recentSubmissions = (_overview?['recentSubmissions'] as List<dynamic>? ?? []);
                        if (recentSubmissions.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: EduEmptyState(
                              message: 'Aucune copie rendue pour l\'instant',
                              subtitle: 'Les copies et notes de vos élèves s\'afficheront ici dès qu\'ils termineront un quiz.',
                            ),
                          );
                        }
                        return Column(
                          children: recentSubmissions.map((sub) {
                            final student = (sub['studentName'] ?? 'Élève').toString();
                            final quizTitle = (sub['quizTitle'] ?? 'Évaluation').toString();
                            final isCheated = sub['statut'] == 'ANNULEE_TRICHE' ||
                                (sub['tricheDetectee'] == true) ||
                                ((sub['nbAvertissementsTriche'] as num?)?.toInt() ?? 0) > 0;
                            final scoreSur20 = isCheated ? 0.0 : ((sub['noteSur20'] as num?)?.toDouble() ?? 0.0);
                            final dateFin = sub['dateFin'] != null ? DateTime.tryParse(sub['dateFin'].toString()) : null;
                            final timeAgo = dateFin != null ? _formatTimeAgo(dateFin) : 'Récemment';
                            final isExcellent = !isCheated && scoreSur20 >= 14.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildSubmittedRow(
                                studentName: student,
                                quizTitle: quizTitle,
                                timeAgo: timeAgo,
                                score: isCheated ? '0.0/20 (TRICHE)' : '${scoreSur20.toStringAsFixed(1)}/20 (${((scoreSur20 / 20.0) * 100).round()}%)',
                                isExcellent: isExcellent,
                                isCheated: isCheated,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );

                final usedQuizzes = _subData?['quizUtilisesCeMois'] ?? 0;
                final rawQuota = _subData?['quotaQuiz'];
                final isUnlimited = rawQuota == 'Illimité' || rawQuota == -1;
                final quotaMax = isUnlimited ? 999 : (rawQuota is num ? rawQuota.toInt() : 5);
                final planName = _subData?['planName'] ?? 'Formule Gratuite (Découverte)';
                final quotaRatio = isUnlimited ? 0.2 : (usedQuizzes / (quotaMax > 0 ? quotaMax : 5)).clamp(0.0, 1.0);

                final sideWidgets = Column(
                  children: [
                    // Carte Quota & Abonnement Réel
                    Container(
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
                            children: [
                              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              const Text(
                                'Formule & Quotas Actifs',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUnlimited ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isUnlimited ? 'PRO' : 'GRATUIT',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isUnlimited ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            planName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Consommation ce mois-ci', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(
                                isUnlimited ? '$usedQuizzes créés (Illimité)' : '$usedQuizzes / $quotaMax quiz',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: quotaRatio,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(quotaRatio >= 0.8 ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => context.go('/teacher/subscription'),
                              child: const Text('Gérer mon offre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Carte Classes Actives Réelles
                    Container(
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
                              const Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 18, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mes Classes',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              Text(
                                '${_classes.length}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_classes.isEmpty)
                            const Text(
                              'Aucune classe créée pour l\'instant.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            )
                          else
                            ..._classes.take(3).map((cl) {
                              final name = (cl['nom'] ?? 'Classe').toString();
                              final code = (cl['codeClasse'] ?? cl['code'] ?? '').toString();
                              final count = cl['_count']?['etudiants'] ?? cl['etudiants']?.length ?? 0;
                              final classId = (cl['id'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: classId.isNotEmpty ? () => context.push('/teacher/classes/$classId') : null,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '$count élève${count > 1 ? "s" : ""} • $code',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => context.go('/teacher/classes'),
                              child: const Text('Accéder aux classes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    JoinClassCardWidget(
                      isTeacher: true,
                      onAction: () => context.go('/teacher/classes'),
                    ),
                  ],
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: mainContent),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: sideWidgets),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      mainContent,
                      const SizedBox(height: 32),
                      sideWidgets,
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 36),

            // 4. Bento Graphique du bas : Données réelles issues de la base
            Builder(
              builder: (context) {
                final recentSubmissions = (_overview?['recentSubmissions'] as List<dynamic>? ?? []);
                if (recentSubmissions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                    ),
                    child: EduEmptyState(
                      message: 'Aucune copie rendue pour l\'instant',
                      subtitle: 'Le comparatif des scores s\'affichera dès que vos élèves auront soumis des évaluations.',
                    ),
                  );
                }

                // Regroupement par titre de quiz
                final Map<String, List<double>> quizScores = {};
                for (final sub in recentSubmissions) {
                  final title = (sub['quizTitle'] ?? 'Quiz').toString();
                  final score = (sub['noteSur20'] as num?)?.toDouble() ?? 0.0;
                  quizScores.putIfAbsent(title, () => []).add(score);
                }

                final titles = quizScores.keys.take(5).toList();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Moyenne des Dernières Évaluations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF18181B),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Notes moyennes obtenues par vos élèves sur leurs copies récentes.',
                                style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${recentSubmissions.length} copie${recentSubmissions.length > 1 ? "s" : ""}',
                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 20,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final quizName = titles[groupIndex];
                                  return BarTooltipItem(
                                    '$quizName\nMoyenne : ${rod.toY.toStringAsFixed(1)} / 20',
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
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < titles.length) {
                                      final raw = titles[idx];
                                      final label = raw.length > 15 ? '${raw.substring(0, 13)}...' : raw;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          label,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF71717A)),
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
                                  reservedSize: 28,
                                  getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA))),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: titles.asMap().entries.map((e) {
                              final scores = quizScores[e.value]!;
                              final avg = scores.reduce((a, b) => a + b) / scores.length;
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: avg.clamp(0.0, 20.0),
                                    color: const Color(0xFF2563EB),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuizRow(
    BuildContext context, {
    required String intentTag,
    required Color intentColor,
    required Color intentBg,
    required String subject,
    required String title,
    required String teacher,
    required String duration,
    required String questions,
    required String pinCode,
    required String status,
    required VoidCallback onManage,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: intentBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                intentTag,
                style: TextStyle(color: intentColor, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Titre & Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE7E5E4)),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF71717A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PIN : $pinCode',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF18181B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$teacher • $questions • $duration',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Bouton Gérer
          Pulse3DButton(
            backgroundColor: const Color(0xFF2563EB),
            shadowColor: const Color(0xFF1D4ED8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onPressed: onManage,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gérer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedRow({
    required String studentName,
    required String quizTitle,
    required String timeAgo,
    required String score,
    required bool isExcellent,
    bool isCheated = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isCheated ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCheated ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: isCheated ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCheated
                  ? const Color(0xFFFEE2E2)
                  : (isExcellent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheated
                  ? Icons.gavel_rounded
                  : (isExcellent ? Icons.check_circle_outline_rounded : Icons.star_outline_rounded),
              color: isCheated
                  ? const Color(0xFFDC2626)
                  : (isExcellent ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    if (isCheated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TRICHE DÉTECTÉE',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  quizTitle,
                  style: TextStyle(fontSize: 12, color: isCheated ? const Color(0xFFB91C1C) : const Color(0xFF71717A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCheated ? const Color(0xFFDC2626) : (isExcellent ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
