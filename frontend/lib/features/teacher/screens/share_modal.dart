import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/quiz_model.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';

class ShareModal extends StatelessWidget {
  final QuizModel quiz;

  const ShareModal({super.key, required this.quiz});

  static void show(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (ctx) => ShareModal(quiz: quiz),
    );
  }

  String _getBaseUrl() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('null')) {
        return origin;
      }
    }
    return const String.fromEnvironment('APP_BASE_URL', defaultValue: 'http://localhost:3000');
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = _getBaseUrl();
    final quizLink = '$baseUrl/student/quiz/${quiz.id}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec Logo et Bouton Fermer
              Row(
                children: [
                  const QuizPulseLogo(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Mode Projection Vidéoprojecteur • Session Live',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Grand QR Code Vectoriel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: quiz.codeAcces,
                  version: QrVersions.auto,
                  size: 240.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF2563EB),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // PIN Géant pour projection
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF2FF), Color(0xFFFAF5FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CODE PIN DE LA SESSION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          quiz.codeAcces.split('').join(' '),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            fontFamily: 'monospace',
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB), size: 24),
                          tooltip: 'Copier le code PIN',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: quiz.codeAcces));
                            AppAlert.success(context, 'Code PIN copié !');
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Les étudiants rejoignent instantanément sur $baseUrl/student/join',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mode Examen Badge si actif
              if (quiz.modeExamenSecurise)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Text(
                        'Mode Examen Sécurisé Actif (Surveillance focus & anti-triche)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Boutons d'Action 3D
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                  const SizedBox(width: 12),
                  Pulse3DButton(
                    backgroundColor: const Color(0xFF2563EB),
                    shadowColor: const Color(0xFF1D4ED8),
                    icon: Icons.link_rounded,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: quizLink));
                      AppAlert.success(context, 'Lien direct de passage copié !');
                    },
                    child: const Text('Copier le lien direct'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
