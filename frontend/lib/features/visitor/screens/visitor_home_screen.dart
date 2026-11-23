import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/quiz_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/edutech_widgets.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../widgets/hero_interactive_quiz_card.dart';

class VisitorHomeScreen extends ConsumerStatefulWidget {
  const VisitorHomeScreen({super.key});

  @override
  ConsumerState<VisitorHomeScreen> createState() => _VisitorHomeScreenState();
}

class _VisitorHomeScreenState extends ConsumerState<VisitorHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<QuizModel> _quizzes = [];
  List<dynamic> _subjects = [];
  String? _selectedMatiereId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    final isScrolled = _scrollController.hasClients && _scrollController.offset > 20;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjectsRes = await apiClient.get('/public/subjects');
      final queryParams = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (_selectedMatiereId != null) {
        queryParams['matiereId'] = _selectedMatiereId;
      }

      final quizRes = await apiClient.get('/public/quiz', queryParameters: queryParams);

      final items = (quizRes.data['items'] as List<dynamic>? ?? [])
          .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _subjects = subjectsRes.data is List
            ? (subjectsRes.data as List<dynamic>)
            : (subjectsRes.data['subjects'] as List<dynamic>? ?? []);
        _quizzes = items;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger le catalogue. Vérifiez votre connexion.';
      });
    }
  }

  void _scrollToCatalog() {
    _scrollController.animateTo(
      650,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_isScrolled ? 60 : (isMobile ? 68 : 84)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isScrolled ? Colors.white : const Color(0xFFEEF2FF),
            border: _isScrolled
                ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0))
                : null,
            boxShadow: _isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: _isScrolled ? 8 : (isMobile ? 10 : 18),
          ),
          child: Row(
            children: [
              // Logo QuizPulse avec lueur
              QuizPulseLogo(
                size: isMobile ? 32 : 38,
                onTap: () => context.go('/'),
              ),
              if (!isMobile) const SizedBox(width: 24),

              // Liens rapides (Desktop)
              if (screenWidth > 900) ...[
                TextButton.icon(
                  onPressed: _scrollToCatalog,
                  icon: const Icon(Icons.explore_outlined, size: 18, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Explorer les Quiz',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.push('/pricing'),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFFD97706)),
                  label: const Text(
                    'Offres Enseignants',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
              ],

              const Spacer(),

              // Bouton PIN 3D Tactile Rebondi
              Pulse3DButton(
                backgroundColor: const Color(0xFF10B981),
                shadowColor: const Color(0xFF047857),
                icon: Icons.pin,
                onPressed: () => context.push('/student/join'),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Text(isMobile ? 'PIN' : 'Rejoindre par PIN'),
              ),
              SizedBox(width: isMobile ? 8 : 12),

              // Boutons Auth ou Mon Espace
              if (!authState.isAuthenticated) ...[
                if (!isMobile) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => context.push('/login'),
                    child: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                ],
                Pulse3DButton(
                  backgroundColor: const Color(0xFF2563EB),
                  shadowColor: const Color(0xFF1D4ED8),
                  onPressed: () => context.push(isMobile ? '/login' : '/register'),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: Text(isMobile ? 'Connexion' : 'S\'inscrire Gratuit'),
                ),
              ] else ...[
                Pulse3DButton(
                  backgroundColor: const Color(0xFF2563EB),
                  shadowColor: const Color(0xFF1D4ED8),
                  icon: Icons.dashboard,
                  onPressed: () {
                    final roleStr = authState.role.toServerString();
                    if (roleStr == 'ENSEIGNANT') {
                      context.push('/teacher');
                    } else if (roleStr == 'ADMIN') {
                      context.push('/admin');
                    } else {
                      context.push('/student');
                    }
                  },
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: Text(isMobile ? 'Mon Espace' : 'Mon Espace (${authState.user?.prenom ?? ""})'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Se déconnecter',
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      AppAlert.info(context, 'Vous êtes déconnecté.');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // SECTION HERO ULTRA-ATTIRANTE AVEC PHOTO DE CLASSE & OVERLAY BLEU
            Stack(
              children: [
                // Image d'arrière-plan classe
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/classroom_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay bleu identique à la page login (0xFF1E3A8A avec 50% d'opacité)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF1E3A8A).withOpacity(0.50),
                  ),
                ),
                // Gradient subtil pour parfaire la lisibilité du texte
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0F172A).withOpacity(0.35),
                          const Color(0xFF1E3A8A).withOpacity(0.20),
                          const Color(0xFF0F172A).withOpacity(0.50),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, screenHeight - (_isScrolled ? 64 : 84)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 32 : 48,
                  ),
                  alignment: Alignment.center,
                  child: ResponsiveContainer(
                    maxWidth: 1200,
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 880;
                        final showMascot = isDesktop && constraints.maxWidth >= 960;

                        final heroContent = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge d'accroche avec étincelle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.35)),
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  const Icon(Icons.bolt, color: Color(0xFFFBBF24), size: 16),
                                  Text(
                                    'ÉVALUATION GAMIFIÉE & INTELLIGENTE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: isMobile ? 10.5 : 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Titre Accrocheur avec Gradient
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.2,
                                  height: 1.15,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                children: const [
                                  TextSpan(text: 'Apprenez, défiez et évaluez sans '),
                                  TextSpan(
                                    text: 'jamais vous ennuyer.',
                                    style: TextStyle(
                                      color: Color(0xFF93C5FD),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(0, 2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'Entre les QCM trop ennuyeux et les LMS trop rigides : QuizPulse combine notation en temps réel, anti-triche infaillible et plaisir d\'apprendre pour les lycées, universités et écoles supérieures.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFF1F5F9),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Boutons d'Action Tactiles 3D
                            Wrap(
                              spacing: 14,
                              runSpacing: 12,
                              children: [
                                Pulse3DButton(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shadowColor: const Color(0xFF1D4ED8),
                                  icon: Icons.quiz_outlined,
                                  onPressed: _scrollToCatalog,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                  child: const Text('Tester un Quiz Gratuit', style: TextStyle(fontSize: 14)),
                                ),
                                Pulse3DButton(
                                  backgroundColor: Colors.white,
                                  shadowColor: const Color(0xFFCBD5E1),
                                  foregroundColor: const Color(0xFF0F172A),
                                  icon: Icons.school_outlined,
                                  onPressed: () => context.push('/pricing'),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                  child: const Text('Espace Enseignants', style: TextStyle(fontSize: 15)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),

                            // Statistiques Vivantes
                            Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              children: [
                                _buildStatItem('25 000+', 'Quiz complétés', const Color(0xFF93C5FD), isHero: true),
                                _buildStatItem('99.2%', 'Satisfaction profs', const Color(0xFF6EE7B7), isHero: true),
                                _buildStatItem('100%', 'Gratuit étudiants', const Color(0xFFFCD34D), isHero: true),
                              ],
                            ),
                          ],
                        );

                    final interactiveCard = const HeroInteractiveQuizCard();

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 7, child: heroContent),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 5,
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  interactiveCard,
                                  if (showMascot)
                                    const Positioned(
                                      right: -45,
                                      bottom: -35,
                                      child: IgnorePointer(
                                        child: EduMascot(
                                          mood: MascotMood.happy,
                                          size: 200,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          heroContent,
                          const SizedBox(height: 36),
                          Center(child: interactiveCard),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),

            const SizedBox(height: 48),

            // SECTION : COMMENT ÇA MARCHE EN 3 ÉTAPES (3D & Interactive)
            ResponsiveContainer(
              maxWidth: 1100,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF2563EB), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'SIMPLE, FLUIDE ET ULTRA-RAPIDE',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Comment fonctionne EduQuiz ?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Une expérience gamifiée et immersive en 3 étapes sans aucune friction.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 750;
                      final children = [
                        _buildStepCard(
                          step: '1',
                          title: 'Scannez le QR Code',
                          desc: 'L\'enseignant projette le code au tableau. L\'étudiant scanne ou entre le PIN 6 chiffres.',
                          icon: Icons.qr_code_scanner_rounded,
                          accentColor: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEEF2FF),
                        ),
                        _buildStepCard(
                          step: '2',
                          title: 'Répondez au chrono',
                          desc: 'QCM interactifs avec raccourcis clavier, surveillance anti-triche et décompte stimulant.',
                          icon: Icons.timer_outlined,
                          accentColor: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                        _buildStepCard(
                          step: '3',
                          title: 'Montez au classement',
                          desc: 'Résultats instantanés, corrigé détaillé avec explications et certificat de réussite téléchargeable.',
                          icon: Icons.emoji_events_outlined,
                          accentColor: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: c))).toList(),
                        );
                      } else {
                        return Column(
                          children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 56),

            // SECTION CATALOGUE PUBLIC AVEC PILULES COLORÉES
            ResponsiveContainer(
              maxWidth: 1100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isMobile ? screenWidth - 48 : 550),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catalogue des Quiz Publics',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  Text(
                                    'Testez vos connaissances en direct sans inscription préalable',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? math.min(320.0, screenWidth - 48) : 320,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _loadData(),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une matière, un sujet...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Filtres en Pilules Colorées
                  if (_subjects.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSubjectPill(
                            label: 'Toutes les matières',
                            icon: Icons.all_inclusive,
                            isSelected: _selectedMatiereId == null,
                            color: const Color(0xFF2563EB),
                            onTap: () {
                              setState(() => _selectedMatiereId = null);
                              _loadData();
                            },
                          ),
                          const SizedBox(width: 10),
                          ..._subjects.map((sub) {
                            final isSel = _selectedMatiereId == sub['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _buildSubjectPill(
                                label: sub['nom'],
                                icon: _getSubjectIcon(sub['nom']),
                                isSelected: isSel,
                                color: const Color(0xFF2563EB),
                                onTap: () {
                                  setState(() {
                                    _selectedMatiereId = isSel ? null : sub['id'];
                                  });
                                  _loadData();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Grille des Quiz
                  if (_isLoading)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(
                        4,
                        (_) => const SizedBox(
                          width: 350,
                          height: 220,
                          child: LoadingSkeleton(width: 350, height: 220, borderRadius: 20),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(height: 14),
                            Pulse3DButton(
                              onPressed: _loadData,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_quizzes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'Aucun quiz ne correspond à votre recherche.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth > 750
                            ? (constraints.maxWidth - 20) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: _quizzes.map((quiz) {
                            final isMath = quiz.titre.contains('Algèbre') || quiz.matiereNom == 'Mathématiques';
                            final isBio = quiz.titre.contains('cellules') || quiz.matiereNom == 'Biologie';
                            final color = isMath
                                ? const Color(0xFF2563EB)
                                : (isBio ? const Color(0xFF10B981) : const Color(0xFFF43F5E));

                            return SizedBox(
                              width: itemWidth,
                              child: _InteractiveQuizCard(
                                quiz: quiz,
                                accentColor: color,
                                isMath: isMath,
                                isBio: isBio,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                  const SizedBox(height: 56),

                  // SECTION : VOTRE ESPACE D'APPRENTISSAGE
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hub_outlined, color: Color(0xFF475569), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'UN ESPACE POUR CHAQUE ACTEUR',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Votre espace d\'apprentissage dédié',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Que vous soyez apprenant, professeur ou responsable pédagogique, retrouvez votre tableau de bord.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _InteractiveRoleCard(
                            roleTag: 'Élève',
                            roleColor: const Color(0xFF2563EB),
                            roleBgColor: const Color(0xFFEEF2FF),
                            icon: Icons.person_outline_rounded,
                            title: 'Vos classes, vos quiz et vos progrès détaillés.',
                            description: 'Participez aux sessions en direct, révisez en autonomie et téléchargez vos attestations.',
                            onTap: () => context.push('/login'),
                            width: cardWidth,
                          ),
                          _InteractiveRoleCard(
                            roleTag: 'Enseignant',
                            roleColor: const Color(0xFF10B981),
                            roleBgColor: const Color(0xFFECFDF5),
                            icon: Icons.auto_stories_rounded,
                            title: 'Vos cours, vos quiz et l\'analyse de vos classes.',
                            description: 'Générez des QCM assistés par IA, suivez les notes en temps réel et prévenez les fraudes.',
                            onTap: () => context.push('/login'),
                            width: cardWidth,
                          ),
                          _InteractiveRoleCard(
                            roleTag: 'Administrateur',
                            roleColor: const Color(0xFFF43F5E),
                            roleBgColor: const Color(0xFFFFF1F2),
                            icon: Icons.shield_outlined,
                            title: 'Votre établissement et la gouvernance globale.',
                            description: 'Gérez les filières, auditez les sessions, supervisez les licences et la sécurité globale.',
                            onTap: () => context.push('/login'),
                            width: cardWidth,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // BANNIÈRE CTA BAS DE PAGE MODERNE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.28),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, ctaConstraints) {
                        final isCtaWide = ctaConstraints.maxWidth > 700;
                        return Flex(
                          direction: isCtaWide ? Axis.horizontal : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: isCtaWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isCtaWide ? 1 : 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'COMMENCEZ EN 30 SECONDES',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Prêt à dynamiser vos évaluations ?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rejoignez des milliers d\'étudiants et d\'enseignants dès aujourd\'hui. Sans carte bancaire.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCtaWide) const SizedBox(height: 24),
                            Pulse3DButton(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              shadowColor: const Color(0xFFCBD5E1),
                              icon: Icons.rocket_launch_rounded,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              onPressed: () => context.push('/register'),
                              child: const Text(
                                'Créer un compte gratuit',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpaceCard({
    required String roleTag,
    required Color roleColor,
    required Color roleBgColor,
    required String title,
    required VoidCallback onTap,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roleTag,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: roleColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label, Color color, {bool isHero = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
            shadows: isHero
                ? const [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4)]
                : null,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isHero ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            shadows: isHero
                ? const [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4)]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return _InteractiveStepCard(
      step: step,
      title: title,
      desc: desc,
      icon: icon,
      accentColor: accentColor,
      bgColor: bgColor,
    );
  }

  Widget _buildSubjectPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('info') || lower.contains('web') || lower.contains('code')) {
      return Icons.code_rounded;
    }
    if (lower.contains('bio') || lower.contains('chimie') || lower.contains('phys')) {
      return Icons.biotech_rounded;
    }
    if (lower.contains('math')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('lang') || lower.contains('anglais')) {
      return Icons.translate_rounded;
    }
    return Icons.auto_stories_rounded;
  }
}

/// Carte interactive étape avec animation au survol
class _InteractiveStepCard extends StatefulWidget {
  final String step;
  final String title;
  final String desc;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _InteractiveStepCard({
    required this.step,
    required this.title,
    required this.desc,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  State<_InteractiveStepCard> createState() => _InteractiveStepCardState();
}

class _InteractiveStepCardState extends State<_InteractiveStepCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? widget.accentColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 10 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.accentColor : widget.bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHovered ? Colors.white : widget.accentColor,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.bgColor : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.step,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _isHovered ? widget.accentColor : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _isHovered ? widget.accentColor : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.desc,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte interactive de Quiz avec bouton et hover fluide
class _InteractiveQuizCard extends StatefulWidget {
  final QuizModel quiz;
  final Color accentColor;
  final bool isMath;
  final bool isBio;

  const _InteractiveQuizCard({
    required this.quiz,
    required this.accentColor,
    required this.isMath,
    required this.isBio,
  });

  @override
  State<_InteractiveQuizCard> createState() => _InteractiveQuizCardState();
}

class _InteractiveQuizCardState extends State<_InteractiveQuizCard> {
  bool _isHovered = false;

  String _getSubjectEmoji(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('math')) return '📐';
    if (lower.contains('bio') || lower.contains('cellule') || lower.contains('svt')) return '🧬';
    if (lower.contains('hist') || lower.contains('géo') || lower.contains('geo')) return '🏛️';
    if (lower.contains('info') || lower.contains('tech') || lower.contains('code') || lower.contains('prog') || lower.contains('ordi') || lower.contains('cyber')) return '💻';
    return '📚';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final subject = quiz.matiereNom ?? 'Évaluation';
    final teacherName = quiz.enseignantNom ?? 'Enseignant EduQuiz';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.accentColor.withOpacity(0.5) : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.accentColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Liseré animé
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isHovered ? 6 : 4,
                color: widget.accentColor,
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matière + PIN Code
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (quiz.codeAcces != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pin, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    quiz.codeAcces!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Titre avec icône/emoji de matière
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1, right: 8),
                            child: Text(
                              _getSubjectEmoji(subject),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              quiz.titre,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        teacherName,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // Infos / badges
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF10B981)),
                              SizedBox(width: 5),
                              Text(
                                'Entraînement libre',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.flash_on, size: 15, color: Color(0xFFF59E0B)),
                              SizedBox(width: 4),
                              Text(
                                'Notation directe',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bouton d'action
                      Pulse3DButton(
                        backgroundColor: const Color(0xFF2563EB),
                        shadowColor: const Color(0xFF1D4ED8),
                        icon: Icons.play_arrow_rounded,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        borderRadius: 12,
                        onPressed: () => context.push('/student/quiz/${quiz.id}'),
                        child: const Text('Tester le quiz', style: TextStyle(fontWeight: FontWeight.w800)),
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
  }
}

/// Carte interactive Espace avec icones et animations
class _InteractiveRoleCard extends StatefulWidget {
  final String roleTag;
  final Color roleColor;
  final Color roleBgColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final double width;

  const _InteractiveRoleCard({
    required this.roleTag,
    required this.roleColor,
    required this.roleBgColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.width,
  });

  @override
  State<_InteractiveRoleCard> createState() => _InteractiveRoleCardState();
}

class _InteractiveRoleCardState extends State<_InteractiveRoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isHovered ? widget.roleColor.withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.roleColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 22 : 12,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.roleBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.roleColor, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.roleBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.roleTag,
                      style: TextStyle(
                        color: widget.roleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: widget.onTap,
                child: Row(
                  children: [
                    Text(
                      'Se connecter',
                      style: TextStyle(
                        color: widget.roleColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 150),
                      offset: _isHovered ? const Offset(0.25, 0) : Offset.zero,
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: widget.roleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
