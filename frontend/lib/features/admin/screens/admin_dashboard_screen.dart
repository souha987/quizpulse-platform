import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/admin/metrics');
      setState(() {
        _metrics = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EdutechDashboardLayout(
      activeRoute: 'admin_dashboard',
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bandeau d'Accueil Bleu Royal & Blanc
                  _buildAdminHeroBanner(context),

                  const SizedBox(height: 24),

                  // Titre de section KPI
                  const Row(
                    children: [
                      Text(
                        'Indicateurs Clés de Performance',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Mise à jour en direct',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Grille de KPI Professionnels (Blanc & Bleu)
                  _buildBentoMetricsGrid(),

                  const SizedBox(height: 28),

                  // Modules de Gouvernance
                  const Text(
                    'Modules de Supervision',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cartes d'action rapide vers les pages d'administration
                  _buildQuickActionCards(context),

                  const SizedBox(height: 28),

                  // Section État du Système & Sécurité
                  _buildSystemHealthCard(),

                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'CONTRÔLE ADMINISTRATEUR',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                tooltip: 'Actualiser les métriques',
                onPressed: _loadMetrics,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tableau de Bord Administrateur',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Text(
              'Supervisez les opérations de la plateforme EduQuiz : annuaire des utilisateurs, modération des contenus et transactions d\'abonnements Stripe.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFFDBEAFE),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: () => context.go('/admin/users'),
                icon: const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF0F172A)),
                label: const Text(
                  'Utilisateurs',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: () => context.go('/admin/moderation'),
                icon: const Icon(Icons.gavel_outlined, size: 16, color: Color(0xFF0F172A)),
                label: const Text(
                  'Modération Quiz',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: () => context.go('/admin/finance'),
                icon: const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF0F172A)),
                label: const Text(
                  'Finances & Plans',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetricsGrid() {
    final totalUsers = _metrics?['totalUsers'] ?? 0;
    final totalStudents = _metrics?['totalStudents'] ?? 0;
    final totalTeachers = _metrics?['totalTeachers'] ?? 0;
    final totalQuizzes = _metrics?['totalQuizzes'] ?? 0;
    final totalAttempts = _metrics?['totalAttempts'] ?? 0;
    final totalRevenue = _metrics?['totalRevenue'] ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;
        final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              width: cardWidth.clamp(160.0, 360.0),
              icon: Icons.people_alt_outlined,
              title: 'Utilisateurs',
              value: '$totalUsers',
              subtitle: '$totalStudents élèves • $totalTeachers profs',
            ),
            _buildStatCard(
              width: cardWidth.clamp(160.0, 360.0),
              icon: Icons.quiz_outlined,
              title: 'Quiz Créés',
              value: '$totalQuizzes',
              subtitle: 'Catalogues d\'évaluations',
            ),
            _buildStatCard(
              width: cardWidth.clamp(160.0, 360.0),
              icon: Icons.assignment_turned_in_outlined,
              title: 'Copies Rendues',
              value: '$totalAttempts',
              subtitle: 'Tentatives enregistrées',
            ),
            _buildStatCard(
              width: cardWidth.clamp(160.0, 360.0),
              icon: Icons.account_balance_wallet_rounded,
              title: 'Revenus Stripe',
              value: '$totalRevenue DT',
              subtitle: 'Abonnements enseignants',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
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
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final cardWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionCard(
              width: cardWidth,
              title: 'Annuaire Utilisateurs',
              subtitle: 'Consultez, filtrez et gérez les comptes élèves et enseignants.',
              icon: Icons.manage_accounts_outlined,
              actionLabel: 'Ouvrir l\'annuaire',
              onTap: () => context.go('/admin/users'),
            ),
            _buildActionCard(
              width: cardWidth,
              title: 'Modération des Quiz',
              subtitle: 'Contrôlez les questions et modérez les évaluations.',
              icon: Icons.fact_check_outlined,
              actionLabel: 'Examiner les quiz',
              onTap: () => context.go('/admin/moderation'),
            ),
            _buildActionCard(
              width: cardWidth,
              title: 'Finances & Plans',
              subtitle: 'Historique des paiements Stripe et suivi des souscriptions Pro.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Voir les transactions',
              onTap: () => context.go('/admin/finance'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthCard() {
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
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text(
                'État des Services',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Spacer(),
              Text(
                'Systèmes opérationnels',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildHealthItem('Serveur Backend Node/Express', 'En ligne (Port 5000)'),
              _buildHealthItem('Base PostgreSQL Supabase', 'Connectée (Prisma)'),
              _buildHealthItem('Surveillance Anti-Triche', 'Active'),
              _buildHealthItem('Passerelle Stripe', 'Opérationnelle'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String title, String status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            Text(
              status,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }
}
