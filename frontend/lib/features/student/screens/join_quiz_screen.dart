import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';

class JoinQuizScreen extends StatefulWidget {
  const JoinQuizScreen({super.key});

  @override
  State<JoinQuizScreen> createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_pinController.text.length < 6) {
      setState(() {
        _pinController.text += digit;
        _errorMessage = null;
      });
      if (_pinController.text.length == 6) {
        _submitPin();
      }
    }
  }

  void _deleteDigit() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _errorMessage = 'Veuillez saisir les 6 caractères du code PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiClient.get('/quiz/pin/$pin');
      final quizId = response.data['id'];
      if (mounted) {
        context.push('/student/quiz/$quizId');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = getErrorMessage(e, 'Code PIN invalide. Aucun quiz trouvé.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const QuizPulseLogo(size: 32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded, size: 18, color: Color(0xFF2563EB)),
            label: const Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 480,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.pin, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Rejoindre l\'Arène QuizPulse',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Entrez le code PIN à 6 chiffres affiché au tableau par votre enseignant',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Affichage des 6 cases PIN lumineuses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final hasValue = index < _pinController.text.length;
                      final digit = hasValue ? _pinController.text[index] : '';

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: hasValue ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasValue ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                            width: hasValue ? 2.5 : 1.5,
                          ),
                          boxShadow: hasValue
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Puces démo rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Codes démo : ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      InkWell(
                        onTap: () {
                          setState(() => _pinController.text = '123456');
                          _submitPin();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('123456 (Public)', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() => _pinController.text = '742000');
                          _submitPin();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('742000 (Examen)', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Pavé numérique tactile 3D
                  Column(
                    children: [
                      for (var row = 0; row < 3; row++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var col = 1; col <= 3; col++)
                                _buildKeypadButton('${row * 3 + col}'),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.qr_code_scanner, () => context.push('/student/scan')),
                            _buildKeypadButton('0'),
                            _buildActionButton(Icons.backspace_outlined, _deleteDigit),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Grand Bouton 3D Rebondi
                  Pulse3DButton(
                    width: double.infinity,
                    backgroundColor: const Color(0xFF10B981),
                    shadowColor: const Color(0xFF047857),
                    icon: Icons.rocket_launch,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _isLoading ? null : _submitPin,
                    child: Text(
                      _isLoading ? 'Connexion à la session...' : 'Rejoindre la Session',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    ),
                    onPressed: () => context.push('/student/scan'),
                    icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB), size: 18),
                    label: const Text('Scanner le QR Code d\'examen', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Pulse3DButton(
      width: 76,
      depth: 3.0,
      borderRadius: 14,
      backgroundColor: Colors.white,
      shadowColor: const Color(0xFFCBD5E1),
      foregroundColor: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () => _appendDigit(digit),
      child: Text(
        digit,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Pulse3DButton(
      width: 76,
      depth: 3.0,
      borderRadius: 14,
      backgroundColor: const Color(0xFFEEF2FF),
      shadowColor: const Color(0xFFC7D2FE),
      foregroundColor: const Color(0xFF2563EB),
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: onTap,
      child: Icon(icon, size: 22, color: const Color(0xFF2563EB)),
    );
  }
}
