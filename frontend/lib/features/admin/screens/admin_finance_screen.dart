import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  List<dynamic> _payments = [];
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final paymentsFuture = apiClient.get('/admin/payments');
      final metricsFuture = apiClient.get('/admin/metrics');

      final results = await Future.wait([paymentsFuture, metricsFuture]);
      final paymentsRes = results[0];
      final metricsRes = results[1];

      setState(() {
        _payments = paymentsRes.data['payments'] as List<dynamic>? ?? [];
        _metrics = metricsRes.data as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredPayments {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _payments;
    return _payments.where((p) {
      final ref = (p['reference'] ?? '').toString().toLowerCase();
      final enseignant = p['abonnement']?['enseignant'];
      final name = '${enseignant?['prenom'] ?? ''} ${enseignant?['nom'] ?? ''}'.toLowerCase();
      final email = (enseignant?['email'] ?? '').toString().toLowerCase();
      final offre = (p['abonnement']?['offre']?['nom'] ?? '').toString().toLowerCase();
      return ref.contains(query) || name.contains(query) || email.contains(query) || offre.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _metrics?['totalRevenue'] ?? 0.0;
    final totalTeachers = _metrics?['totalTeachers'] ?? 0;
    final totalPayments = _payments.length;
    final filtered = _filteredPayments;

    return EdutechDashboardLayout(
      activeRoute: 'admin_finance',
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
                        'Finances & Facturation Abonnements',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18181B),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Suivi en temps réel des encaissements des abonnements Enseignant Pro et historique Stripe.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF71717A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF71717A)),
                  onPressed: _loadData,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bento Stat Cards Pastel
            _buildFinanceStatsGrid(totalRevenue, totalPayments, totalTeachers),

            const SizedBox(height: 28),

            // Barre de Recherche & Synthèse
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE7E5E4), width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par enseignant, email, référence ou offre...',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${filtered.length} transactions affichées',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF27272A)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tableau des Transactions
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
                    Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFA1A1AA)),
                    SizedBox(height: 12),
                    Text(
                      'Aucune transaction trouvée',
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
                    // En-tête
                    Container(
                      color: const Color(0xFFFAF9F6),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('ENSEIGNANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('OFFRE SOUSCRITE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('MONTANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('DATE DE PAIEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          Expanded(flex: 2, child: Text('MÉTHODE / RÉFÉRENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                          SizedBox(width: 100, child: Text('STATUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFA1A1AA), letterSpacing: 0.6))),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE7E5E4)),

                    // Lignes
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF4F4F5)),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final refStr = (p['reference'] ?? p['id']?.toString().substring(0, 8) ?? 'N/A').toString();
                        final montant = (p['montant'] ?? 0.0);
                        final moyen = (p['moyenPaiement'] ?? 'STRIPE_CARD').toString();
                        final statut = (p['statut'] ?? 'VALIDE').toString();
                        final dateStr = p['datePaiement'] != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(p['datePaiement']))
                            : 'N/A';

                        final enseignant = p['abonnement']?['enseignant'];
                        final teacherName = enseignant != null
                            ? '${enseignant['prenom'] ?? ''} ${enseignant['nom'] ?? ''}'.trim()
                            : 'Enseignant';
                        final teacherEmail = enseignant != null ? (enseignant['email'] ?? '') : '';
                        final offreName = p['abonnement']?['offre']?['nom'] ?? 'Pass Enseignant Pro';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // Enseignant
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFFFFF1EB),
                                      child: const Icon(Icons.co_present_rounded, color: Color(0xFF2563EB), size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teacherName,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF18181B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            teacherEmail,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Offre
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      offreName,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                                    ),
                                  ),
                                ),
                              ),

                              // Montant
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '$montant DT',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                                ),
                              ),

                              // Date
                              Expanded(
                                flex: 2,
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF52525B), fontWeight: FontWeight.w600),
                                ),
                              ),

                              // Méthode / Ref
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      moyen.replaceAll('_', ' '),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF27272A)),
                                    ),
                                    Text(
                                      refStr,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                                    ),
                                  ],
                                ),
                              ),

                              // Statut
                              SizedBox(
                                width: 100,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Validé 🟢',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                    ),
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

  Widget _buildFinanceStatsGrid(dynamic totalRevenue, int totalPayments, dynamic totalTeachers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;
        final cardWidth = isNarrow ? (constraints.maxWidth - 14) / 2 : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              width: cardWidth.clamp(170.0, 360.0),
              bg: const Color(0xFFFFF1EB),
              border: const Color(0xFFFFDAC6),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Revenus Totaux',
              value: '$totalRevenue DT',
              subtitle: 'Encaissements cumulés Stripe',
            ),
            _buildStatCard(
              width: cardWidth.clamp(170.0, 360.0),
              bg: const Color(0xFFEBF7FF),
              border: const Color(0xFFC8E9FF),
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF0284C7),
              title: 'Transactions',
              value: '$totalPayments',
              subtitle: 'Paiements validés',
            ),
            _buildStatCard(
              width: cardWidth.clamp(170.0, 360.0),
              bg: const Color(0xFFF3FBE8),
              border: const Color(0xFFDEF7B8),
              icon: Icons.star_rounded,
              iconColor: const Color(0xFF65A30D),
              title: 'Abonnement Pro',
              value: '9.99 DT / m',
              subtitle: 'Tarif officiel enseignant',
            ),
            _buildStatCard(
              width: cardWidth.clamp(170.0, 360.0),
              bg: const Color(0xFFF5F3EF),
              border: const Color(0xFFE8E4DC),
              icon: Icons.co_present_rounded,
              iconColor: const Color(0xFFD97706),
              title: 'Enseignants Cibles',
              value: '$totalTeachers',
              subtitle: 'Professeurs actifs',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required Color bg,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF18181B),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF27272A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }
}
