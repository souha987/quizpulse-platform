import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';

class QrScannerScreen extends StatefulWidget {
  final String mode; // 'quiz' ou 'class'

  const QrScannerScreen({super.key, this.mode = 'quiz'});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCtrl = TextEditingController();
  bool _hasScanned = false;
  bool _showManual = false;

  void _processCode(String rawCode) async {
    if (_hasScanned) return;
    final code = rawCode.trim();
    if (code.isEmpty) return;

    setState(() => _hasScanned = true);

    if (widget.mode == 'class' || code.contains('/classes/join')) {
      // Mode Rejoindre une Classe
      String classCode = code;
      if (classCode.contains('/classes/join/')) {
        classCode = classCode.split('/classes/join/').last.split('?').first;
      } else if (classCode.contains('code=')) {
        classCode = Uri.tryParse(classCode)?.queryParameters['code'] ?? classCode;
      }

      if (mounted) {
        AppAlert.info(context, 'Code classe détecté : $classCode. Inscription...');
      }

      try {
        await apiClient.post('/classes/join', data: {
          'codeClasse': classCode.toUpperCase(),
        });
        if (mounted) {
          AppAlert.success(context, 'Classe rejointe avec succès ! 🎉');
          context.pushReplacement('/student/classes');
        }
      } catch (e) {
        if (mounted) {
          AppAlert.error(context, getErrorMessage(e, 'Impossible de rejoindre la classe'));
          setState(() => _hasScanned = false);
        }
      }
    } else {
      // Mode Quiz
      String targetQuizId = code;
      if (code.contains('/quiz/')) {
        targetQuizId = code.split('/quiz/').last.split('?').first;
      }

      if (mounted) {
        AppAlert.info(context, 'Code détecté ! Chargement du quiz...');
        context.pushReplacement('/student/quiz/$targetQuizId');
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _processCode(code);
        break;
      }
    }
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildManualInputFallback({String? errorMsg}) {
    final isClassMode = widget.mode == 'class';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorMsg != null ? Icons.videocam_off_rounded : Icons.keyboard_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMsg != null ? 'Caméra inaccessible' : 'Saisie manuelle du code',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMsg ??
                    (isClassMode
                        ? 'Entrez le code de votre classe pour la rejoindre.'
                        : 'Entrez le code PIN ou l\'identifiant du quiz.'),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _manualCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: isClassMode ? 'Code Classe (ex: ABC123)' : 'Code PIN ou Quiz ID',
                  hintText: isClassMode ? 'ABC123' : '123456',
                  prefixIcon: const Icon(Icons.pin_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (val) => _processCode(val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _processCode(_manualCtrl.text),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Valider et Continuer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (_showManual && errorMsg == null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => _showManual = false),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Revenir au scanner'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClassMode = widget.mode == 'class';
    return Scaffold(
      appBar: AppBar(
        title: Text(isClassMode ? 'Rejoindre une Classe' : 'Scanner le Quiz'),
        actions: [
          IconButton(
            tooltip: _showManual ? 'Scanner QR' : 'Saisie manuelle',
            icon: Icon(_showManual ? Icons.qr_code_scanner_rounded : Icons.keyboard_rounded),
            onPressed: () => setState(() => _showManual = !_showManual),
          ),
          if (!_showManual && !kIsWeb) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ],
      ),
      body: _showManual
          ? _buildManualInputFallback()
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return _buildManualInputFallback(
                      errorMsg:
                          'Impossible d\'accéder à la caméra (${error.errorCode.name}). Vous pouvez entrer le code manuellement ci-dessous.',
                    );
                  },
                ),
                // Overlay de ciblage
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Cadrez le QR Code affiché par votre enseignant ou basculez en saisie manuelle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

