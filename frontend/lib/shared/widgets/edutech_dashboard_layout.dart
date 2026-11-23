import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'quiz_pulse_logo.dart';

class EdutechDashboardLayout extends ConsumerWidget {
  final Widget child;
  final String activeRoute; // 'dashboard', 'classes', 'quiz', 'results', 'pricing', 'admin_dashboard', 'admin_users', 'admin_moderation', 'admin_finance'

  const EdutechDashboardLayout({
    super.key,
    required this.child,
    required this.activeRoute,
  });

  String _getBreadcrumbTitle(String route) {
    switch (route) {
      case 'admin_dashboard':
        return 'Administration / Vue d\'ensemble';
      case 'admin_users':
        return 'Administration / Utilisateurs';
      case 'admin_moderation':
        return 'Administration / Modération Quiz';
      case 'admin_finance':
        return 'Administration / Finances & Plans';
      case 'dashboard':
        return 'Tableau de bord';
      case 'classes':
        return 'Mes classes';
      case 'quiz':
        return 'Gestion des Quiz';
      case 'results':
        return 'Résultats & Évaluations';
      case 'pricing':
      case 'subscription':
        return 'Abonnement';
      default:
        return 'Espace Dédié';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = authState.role == UserRole.admin;
    final isTeacher = authState.role == UserRole.enseignant;
    final isStudent = authState.role == UserRole.etudiant;
    final isDesktop = MediaQuery.of(context).size.width > 950;

    final initials = user != null
        ? '${user.prenom.isNotEmpty ? user.prenom[0] : ""}${user.nom.isNotEmpty ? user.nom[0] : ""}'.toUpperCase()
        : (isAdmin ? 'AD' : (isTeacher ? 'PR' : 'ET'));
    final fullName = user != null
        ? '${user.prenom} ${user.nom}'.trim()
        : (isAdmin ? 'Administrateur' : (isTeacher ? 'Enseignant' : 'Élève'));
    final roleLabel = isAdmin ? 'Administrateur' : (isTeacher ? 'Enseignant' : 'Élève');

    final sidebarContent = Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: QuizPulseLogo(
              size: 30,
              onTap: () => context.go('/'),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Text(
                      isAdmin ? 'ADMINISTRATION' : (isTeacher ? 'ESPACE ENSEIGNANT' : 'ESPACE ÉLÈVE'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  // Menu Navigation
                  if (isAdmin) ...[
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: 'Vue d\'ensemble',
                      isActive: activeRoute == 'admin_dashboard',
                      onTap: () => context.go('/admin'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.people_outline_rounded,
                      label: 'Utilisateurs',
                      isActive: activeRoute == 'admin_users',
                      onTap: () => context.go('/admin/users'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.gavel_outlined,
                      label: 'Modération Quiz',
                      isActive: activeRoute == 'admin_moderation',
                      onTap: () => context.go('/admin/moderation'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.payments_outlined,
                      label: 'Finances & Plans',
                      isActive: activeRoute == 'admin_finance',
                      onTap: () => context.go('/admin/finance'),
                    ),
                  ] else if (isTeacher) ...[
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: 'Tableau de bord',
                      isActive: activeRoute == 'dashboard',
                      onTap: () => context.go('/teacher'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.school_outlined,
                      label: 'Mes classes',
                      isActive: activeRoute == 'classes',
                      onTap: () => context.go('/teacher/classes'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.quiz_outlined,
                      label: 'Mes Quiz',
                      isActive: activeRoute == 'quiz',
                      onTap: () => context.go('/teacher/quizzes'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      label: 'Résultats & Analyses',
                      isActive: activeRoute == 'results',
                      onTap: () => context.go('/teacher/analytics'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.credit_card_outlined,
                      label: 'Abonnement',
                      isActive: activeRoute == 'pricing' || activeRoute == 'subscription',
                      onTap: () => context.go('/teacher/subscription'),
                    ),
                  ] else ...[
                    _buildNavItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: 'Tableau de bord',
                      isActive: activeRoute == 'dashboard',
                      onTap: () => context.go('/student'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.school_outlined,
                      label: 'Mes classes',
                      isActive: activeRoute == 'classes',
                      onTap: () => context.go('/student/classes'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.quiz_outlined,
                      label: 'Quiz assignés',
                      isActive: activeRoute == 'quiz',
                      onTap: () => context.go('/student/quizzes'),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.history_edu_outlined,
                      label: 'Mes résultats',
                      isActive: activeRoute == 'results',
                      onTap: () => context.go('/student/history'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Carte Statut Bas de Sidebar
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Super-Admin',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mode supervision global actif.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.go('/teacher'),
                      child: const Row(
                        children: [
                          Text('Vue enseignant', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isTeacher)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Pass Enseignant Pro',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Quiz illimités & exports notes.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.go('/teacher/subscription'),
                      child: const Row(
                        children: [
                          Text('Gérer l\'offre', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : Drawer(child: sidebarContent),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          if (isDesktop) sidebarContent,

          // Zone Principale
          Expanded(
            child: Column(
              children: [
                // Top Bar Web Épurée
                Container(
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (!isDesktop) ...[
                        Builder(
                          builder: (c) => IconButton(
                            icon: const Icon(Icons.menu, size: 20, color: Color(0xFF334155)),
                            onPressed: () => Scaffold.of(c).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Fil d'Ariane
                      Text(
                        _getBreadcrumbTitle(activeRoute),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const Spacer(),

                      // Bouton Retour Accueil
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home_outlined, size: 16),
                        label: const Text('Accueil public', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                      ),

                      const SizedBox(width: 12),
                      const SizedBox(height: 20, child: VerticalDivider(color: Color(0xFFE2E8F0), width: 1)),
                      const SizedBox(width: 12),

                      // Profil Utilisateur
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  roleLabel,
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Déconnexion',
                            onPressed: () async {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) context.go('/');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenu de la page
                Expanded(
                  child: SingleChildScrollView(
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: isActive ? Border.all(color: const Color(0xFFDBEAFE), width: 1) : null,
      ),
      child: Material(
        color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          leading: Icon(
            icon,
            size: 18,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
