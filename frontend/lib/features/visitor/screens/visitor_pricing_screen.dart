import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/responsive_container.dart';

class VisitorPricingScreen extends StatelessWidget {
  const VisitorPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tarifs & Offres Enseignants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          maxWidth: 960,
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Pill tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text(
                  'TARIFS TRANSPARENTS • SANS SURCOÛT CACHÉ',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Des formules adaptées à chaque établissement',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Les étudiants ont toujours un accès 100% gratuit, sans publicité et sans limite de passage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),

              // Grille comparative avec cartes modernes Figma
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formule Découverte (Gratuit)
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Formule Gratuite',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Idéal pour tester la plateforme avec vos premières classes.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('0 DT', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                  SizedBox(width: 6),
                                  Text('/ pour toujours', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _buildFeatureItem('Jusqu\'à 5 quiz créés par mois', true),
                              _buildFeatureItem('Jusqu\'à 2 classes virtuelles', true),
                              _buildFeatureItem('QCM, Vrai/Faux & Choix multiples', true),
                              _buildFeatureItem('Génération de codes PIN & QR Codes', true),
                              _buildFeatureItem('Mode Examen Sécurisé anti-triche', false),
                              _buildFeatureItem('Export CSV des notes de classe', false),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => context.push('/register'),
                                  child: const Text('Commencer Gratuitement', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

                      // Formule Pro Enseignant (Carte mise en valeur)
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF2563EB), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Enseignant Pro',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF65A30D),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'POPULAIRE',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pour les professeurs et formateurs exigeants souhaitant la puissance maximale.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('9.99 DT', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                                  SizedBox(width: 6),
                                  Text('/ mois', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _buildFeatureItem('Quiz ILLIMITÉS', true, isBold: true),
                              _buildFeatureItem('Classes virtuelles ILLIMITÉES', true, isBold: true),
                              _buildFeatureItem('Mode Examen Sécurisé anti-triche', true),
                              _buildFeatureItem('Tableau de bord & taux d\'échec par question', true),
                              _buildFeatureItem('Export CSV complet des notes', true),
                              _buildFeatureItem('Support prioritaire 7j/7', true),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F6212),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => context.push('/register'),
                                  child: const Text('Passer à la formule Pro ➔', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool included, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: included ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: included ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                decoration: included ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
