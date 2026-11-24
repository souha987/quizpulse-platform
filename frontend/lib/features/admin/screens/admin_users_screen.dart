import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedRoleFilter = 'TOUS'; // 'TOUS', 'ENSEIGNANT', 'ETUDIANT', 'ADMIN'
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _searchCtrl.text.trim().isEmpty) {
        _loadUsers(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_searchCtrl.text.trim().isNotEmpty) {
        queryParams['search'] = _searchCtrl.text.trim();
      }

      final res = await apiClient.get('/admin/users', queryParameters: queryParams);
      if (mounted) {
        setState(() {
          _users = res.data['users'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(String userId, String email, bool currentActif) async {
    try {
      await apiClient.patch('/admin/users/$userId/toggle-status');
      if (mounted) {
        if (!currentActif) {
          AppAlert.success(context, 'Compte de $email réactivé avec succès.');
        } else {
          AppAlert.warning(context, 'Compte de $email suspendu.');
        }
      }
      _loadUsers();
    } catch (e) {
      if (mounted) {
        final msg = getErrorMessage(e, 'Erreur lors de la modification du statut');
        AppAlert.error(context, msg);
      }
    }
  }

  List<dynamic> get _filteredUsers {
    if (_selectedRoleFilter == 'TOUS') return _users;
    return _users.where((u) => u['role'] == _selectedRoleFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final totalCount = _users.length;
    final activeCount = _users.where((u) => (u['actif'] ?? u['statutActif']) == true).length;
    final suspendedCount = totalCount - activeCount;

    return EdutechDashboardLayout(
      activeRoute: 'admin_users',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & En-tête
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Annuaire des Utilisateurs',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18181B),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consultez la liste intégrale des comptes, filtrez par rôle et gérez les statuts d\'accès.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF71717A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser la liste',
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF71717A)),
                  onPressed: _loadUsers,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Barre de Filtres & Recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Champ de recherche
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _loadUsers(),
                          decoration: InputDecoration(
                            hintText: 'Rechercher par prénom, nom ou adresse email...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF2563EB)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            fillColor: const Color(0xFFFAF9F6),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Pastilles de synthèse rapides
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalCount inscrits',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF27272A)),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFFA1A1AA))),
                            Text(
                              '$activeCount actifs',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                            ),
                            if (suspendedCount > 0) ...[
                              const Text(' • ', style: TextStyle(color: Color(0xFFA1A1AA))),
                              Text(
                                '$suspendedCount suspendus',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Chips de rôles
                  Row(
                    children: [
                      const Text(
                        'Rôle :',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF71717A)),
                      ),
                      const SizedBox(width: 10),
                      _buildRoleFilterChip('Tous', 'TOUS'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Enseignants', 'ENSEIGNANT'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Élèves', 'ETUDIANT'),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Administrateurs', 'ADMIN'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tableau des Utilisateurs
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFA1A1AA)),
                    SizedBox(height: 12),
                    Text(
                      'Aucun utilisateur ne correspond à votre recherche',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF27272A)),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // En-tête du tableau
                    Container(
                      color: const Color(0xFFFAF9F6),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('UTILISATEUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('RÔLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('STATUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('INSCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          SizedBox(width: 140, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE7E5E4)),

                    // Lignes du tableau
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF4F4F5)),
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        final prenom = (u['prenom'] ?? '').toString();
                        final nom = (u['nom'] ?? '').toString();
                        final email = (u['email'] ?? '').toString();
                        final role = (u['role'] ?? 'ETUDIANT').toString();
                        final isActif = (u['actif'] ?? u['statutActif']) == true;
                        final initials = '${prenom.isNotEmpty ? prenom[0] : ""}${nom.isNotEmpty ? nom[0] : ""}'.toUpperCase();
                        final rawDate = u['dateInscription'] ?? u['dateCreation'];
                        final dateStr = rawDate != null
                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate.toString()))
                            : 'N/A';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // Utilisateur : Avatar + Nom + Email
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 19,
                                      backgroundColor: _getRoleAvatarBg(role),
                                      child: Text(
                                        initials.isNotEmpty ? initials : 'U',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          color: _getRoleColor(role),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$prenom $nom',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              color: Color(0xFF18181B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF71717A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Rôle
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleBadgeBg(role),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _getRoleLabel(role),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _getRoleColor(role),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Statut
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActif ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isActif ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isActif ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isActif ? 'Actif' : 'Suspendu',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isActif ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Inscription
                              Expanded(
                                flex: 2,
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF52525B), fontWeight: FontWeight.w600),
                                ),
                              ),

                              // Action Toggle
                              SizedBox(
                                width: 140,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: isActif
                                      ? OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFEF4444),
                                            side: const BorderSide(color: Color(0xFFFECACA)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _toggleStatus(u['id'], email, isActif),
                                          icon: const Icon(Icons.block_rounded, size: 14),
                                          label: const Text('Suspendre', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                        )
                                      : ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          onPressed: () => _toggleStatus(u['id'], email, isActif),
                                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                          label: const Text('Réactiver', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String roleValue) {
    final isSelected = _selectedRoleFilter == roleValue;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = roleValue),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF52525B),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
      case 'ENSEIGNANT':
        return 'Enseignant';
      case 'ETUDIANT':
      default:
        return 'Élève';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFD97706);
      case 'ENSEIGNANT':
        return const Color(0xFF0284C7);
      case 'ETUDIANT':
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Color _getRoleBadgeBg(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFFEF3C7);
      case 'ENSEIGNANT':
        return const Color(0xFFE0F2FE);
      case 'ETUDIANT':
      default:
        return const Color(0xFFEDE9FE);
    }
  }

  Color _getRoleAvatarBg(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFFFFBEB);
      case 'ENSEIGNANT':
        return const Color(0xFFF0F9FF);
      case 'ETUDIANT':
      default:
        return const Color(0xFFF5F3FF);
    }
  }
}
