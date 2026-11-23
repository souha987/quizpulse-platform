import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/edutech_dashboard_layout.dart';
import '../../../shared/widgets/pulse_3d_button.dart';

class TeacherSubscriptionScreen extends ConsumerStatefulWidget {
  const TeacherSubscriptionScreen({super.key});

  @override
  ConsumerState<TeacherSubscriptionScreen> createState() => _TeacherSubscriptionScreenState();
}

class _TeacherSubscriptionScreenState extends ConsumerState<TeacherSubscriptionScreen> {
  Map<String, dynamic>? _subData;
  List<dynamic> _plans = [];
  bool _isLoading = true;
  bool _isUpgrading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subRes = await apiClient.get('/subscriptions/my');
      final plansRes = await apiClient.get('/subscriptions/plans');

      setState(() {
        _subData = subRes.data as Map<String, dynamic>?;
        _plans = plansRes.data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e, 'Impossible de charger les données d\'abonnement');
      });
    }
  }

  Future<void> _upgradeToPro(String planId) async {
    setState(() => _isUpgrading = true);
    try {
      final res = await apiClient.post('/subscriptions/checkout', data: {
        'offreId': planId,
      });

      if (mounted) {
        setState(() => _isUpgrading = false);

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 28),
                SizedBox(width: 10),
                Text('Bienvenue dans Pro ! 🚀'),
              ],
            ),
            content: const Text(
              'Votre abonnement Enseignant Pro a été activé avec succès !\n\nVous bénéficiez désormais de :\n• Quiz et classes illimités\n• Mode Examen Sécurisé & Anti-triche\n• Export CSV complet des notes\n• Support prioritaire',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              Pulse3DButton(
                backgroundColor: const Color(0xFF10B981),
                shadowColor: const Color(0xFF047857),
                onPressed: () => Navigator.pop(ctx),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text('Génial, continuer', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );

        _loadSubscriptionData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpgrading = false);
        final msg = getErrorMessage(e, 'Erreur lors de la souscription');
        AppAlert.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlimited = _subData?['quotaQuiz'] == 'Illimité';
    final hasActiveSub = _subData?['hasActiveSubscription'] == true || isUnlimited;
    final usedCount = (_subData?['quizUtilisesCeMois'] as num?)?.toInt() ?? 0;
    final maxQuotaNum = isUnlimited ? 999 : ((_subData?['quotaQuiz'] as num?)?.toInt() ?? 5);
    final quotaAtteint = _subData?['quotaAtteint'] == true;
    final progress = isUnlimited ? 1.0 : (usedCount / maxQuotaNum).clamp(0.0, 1.0);

    // Trouver l'offre Pro
    final proPlan = _plans.firstWhere(
      (p) => (p['quotaQuiz'] == -1 || (p['prix'] as num?)?.toDouble() == 9.99),
      orElse: () => null,
    );
    final proPlanId = proPlan != null ? proPlan['id'].toString() : null;

    return EdutechDashboardLayout(
      activeRoute: 'pricing',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête conforme au dashboard
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon Abonnement & Quotas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Suivez la consommation de vos créations de quiz et passez à la formule Pro pour débloquer l\'illimité.',
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              )
            else ...[
              // 1. Carte État Actuel & Jauge de Consommation en temps réel (Bleu royal pour Pro, Bleu pâle pour Gratuit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: isUnlimited ? const Color(0xFF1E40AF) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isUnlimited ? const Color(0xFF1D4ED8) : const Color(0xFFDBEAFE),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isUnlimited ? Colors.white.withOpacity(0.18) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isUnlimited ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                                color: isUnlimited ? Colors.white : const Color(0xFF2563EB),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isUnlimited ? 'Formule Enseignant Pro' : 'Formule Gratuite (Découverte)',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: isUnlimited ? Colors.white : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isUnlimited ? const Color(0xFF10B981) : const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isUnlimited ? 'ACTIF ⚡' : 'FREEMIUM',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: isUnlimited ? Colors.white : const Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnlimited
                                      ? 'Abonnement mensuel renouvelé automatiquement. Accès illimité sans aucune restriction.'
                                      : 'Votre formule actuelle vous permet de créer jusqu\'à 5 quiz par mois civil.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isUnlimited ? const Color(0xFFDBEAFE) : const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (!isUnlimited && proPlanId != null)
                          Pulse3DButton(
                            backgroundColor: const Color(0xFF1E40AF),
                            shadowColor: const Color(0xFF1E3A8A),
                            isLoading: _isUpgrading,
                            icon: Icons.bolt_rounded,
                            onPressed: () => _upgradeToPro(proPlanId),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            child: const Text('Passer Pro (9.99 DT)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Divider(color: isUnlimited ? Colors.white.withOpacity(0.18) : const Color(0xFFDBEAFE)),
                    const SizedBox(height: 18),

                    // Indicateur de Quota de Création de Quiz
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Consommation du Quota de Quiz ce mois-ci',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isUnlimited ? Colors.white : const Color(0xFF18181B),
                          ),
                        ),
                        Text(
                          isUnlimited ? '$usedCount quiz créés (Illimité ⚡)' : '$usedCount / $maxQuotaNum quiz utilisés',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: isUnlimited
                                ? Colors.white
                                : (quotaAtteint ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: isUnlimited ? 1.0 : progress,
                        minHeight: 10,
                        backgroundColor: isUnlimited ? Colors.white.withOpacity(0.2) : const Color(0xFFDBEAFE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUnlimited
                              ? const Color(0xFF10B981)
                              : (quotaAtteint ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
                        ),
                      ),
                    ),

                    if (quotaAtteint && !isUnlimited) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Quota mensuel de 5 quiz atteint ! Passez à la formule Pro pour continuer à publier sans interruption.',
                                style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 2. Grille Comparative Freemium vs Pro (PLAN.md)
              const Text(
                'Comparatif des Formules Enseignant',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choisissez l\'offre la plus adaptée à vos besoins pédagogiques.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cardWidth = isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      // CARTE GRATUITE
                      _buildPlanCard(
                        title: 'Formule Gratuite',
                        price: '0 DT',
                        period: '/ toujours',
                        description: 'Idéal pour tester la plateforme avec vos premières classes.',
                        badge: 'DÉCOUVERTE',
                        badgeColor: const Color(0xFF64748B),
                        isCurrent: !isUnlimited,
                        isPro: false,
                        features: const [
                          '5 quiz créés par mois civil',
                          'Jusqu\'à 2 classes actives',
                          'Partage par code PIN et QR Code',
                          'Corrigé automatique pour les élèves',
                          'Mode Examen Sécurisé anti-triche : Non inclus',
                          'Export CSV des notes : Non inclus',
                        ],
                        buttonLabel: !isUnlimited ? 'Votre formule actuelle' : 'Revenir au gratuit',
                        onButtonPressed: null,
                        width: cardWidth,
                      ),

                      // CARTE PRO (RECOMMANDÉE)
                      _buildPlanCard(
                        title: 'Enseignant Pro',
                        price: '9.99 DT',
                        period: '/ mois',
                        description: 'Pour les enseignants exigeants souhaitant une liberté totale.',
                        badge: 'RECOMMANDÉ ⚡',
                        badgeColor: const Color(0xFF1E40AF),
                        isCurrent: isUnlimited,
                        isPro: true,
                        features: const [
                          'Quiz et évaluations ILLIMITÉS',
                          'Classes et étudiants illimités',
                          'Mode Examen Sécurisé & Anti-triche en direct',
                          'Analytiques avancées & Taux d\'échec par question',
                          'Export officiel CSV des notes pour bulletins',
                          'Support prioritaire pédagogique 7j/7',
                        ],
                        buttonLabel: isUnlimited ? 'Votre formule actuelle (Active ✅)' : 'Passer Pro maintenant',
                        onButtonPressed: isUnlimited || proPlanId == null
                            ? null
                            : () => _upgradeToPro(proPlanId),
                        width: cardWidth,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 36),

              // 3. Section Factures & Historique des Reçus (PLAN.md)
              Container(
                width: double.infinity,
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
                        Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Facturation & Reçus de Paiement',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Retrouvez les justificatifs de vos souscriptions pour vos notes de frais ou votre établissement.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    if (!hasActiveSub)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Color(0xFF94A3B8)),
                            SizedBox(width: 10),
                            Text('Aucune facture payante pour le compte Gratuit.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Abonnement Enseignant Pro (Mensuel)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                    SizedBox(height: 2),
                                    Text('Paiement par Carte Bancaire • Réf: SUB-PRO-2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('9.99 DT TTC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    AppAlert.success(context, 'Reçu téléchargé avec succès (PDF)');
                                  },
                                  icon: const Icon(Icons.download, size: 14),
                                  label: const Text('Télécharger le reçu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required String badge,
    required Color badgeColor,
    required bool isCurrent,
    required bool isPro,
    required List<String> features,
    required String buttonLabel,
    required VoidCallback? onButtonPressed,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isPro ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPro ? const Color(0xFF1E40AF) : const Color(0xFFE7E5E4),
          width: isPro ? 1.8 : 1,
        ),
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),

          // Titre & Prix
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
              ),
              const SizedBox(width: 4),
              Text(period, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),

          // Fonctionnalités
          ...features.map((feat) {
            final isExcluded = feat.contains('Non inclus');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    isExcluded ? Icons.close_rounded : Icons.check_circle_rounded,
                    size: 18,
                    color: isExcluded ? const Color(0xFF94A3B8) : (isPro ? const Color(0xFF10B981) : const Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isExcluded ? FontWeight.normal : FontWeight.w600,
                        color: isExcluded ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 13.5),
                      ),
                    ),
                  )
                : Pulse3DButton(
                    backgroundColor: isPro ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    shadowColor: isPro ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    isLoading: _isUpgrading,
                    onPressed: onButtonPressed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ),
          ),
        ],
      ),
    );
  }
}
