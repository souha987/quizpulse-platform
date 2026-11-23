import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialCode;

  const EmailVerificationScreen({
    super.key,
    this.initialEmail,
    this.initialCode,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isResending = false;
  String? _infoBanner;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      // Tenter une vérification automatique si email et code sont présents
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_emailController.text.isNotEmpty) {
          _verifyCode();
        }
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorBanner = 'Veuillez renseigner votre adresse e-mail';
        _infoBanner = null;
      });
      return;
    }

    if (code.isEmpty || code.length < 4) {
      setState(() {
        _errorBanner = 'Veuillez saisir le code de confirmation reçu';
        _infoBanner = null;
      });
      return;
    }

    setState(() {
      _errorBanner = null;
      _infoBanner = null;
    });

    final success = await ref.read(authProvider.notifier).verifyEmail(email, code);

    if (success && mounted) {
      AppAlert.success(context, 'Compte activé avec succès ! Bienvenue sur QuizPulse.');

      final role = ref.read(authProvider).role;
      if (role == UserRole.enseignant) {
        context.go('/teacher');
      } else if (role == UserRole.admin) {
        context.go('/admin');
      } else {
        context.go('/student');
      }
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      setState(() {
        _errorBanner = error ?? 'Code invalide ou expiré';
      });
    }
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorBanner = 'Veuillez renseigner votre adresse e-mail';
        _infoBanner = null;
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorBanner = null;
      _infoBanner = null;
    });

    final success =
        await ref.read(authProvider.notifier).resendVerificationEmail(email);

    if (mounted) {
      setState(() {
        _isResending = false;
        if (success) {
          _infoBanner =
              'Un nouveau code de confirmation a été envoyé à $email. Vérifiez votre boîte mail !';
        } else {
          _errorBanner = ref.read(authProvider).errorMessage ??
              'Impossible de renvoyer l\'e-mail.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const QuizPulseLogo(size: 32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 520,
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
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône enveloppe moderne avec badge de validation
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 40,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vérifiez votre boîte mail',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailController.text.isNotEmpty
                        ? 'Nous avons envoyé un e-mail avec un code de confirmation à :'
                        : 'Veuillez saisir votre e-mail et le code reçu pour activer votre compte :',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_emailController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Message d'information de succès de renvoi
                  if (_infoBanner != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _infoBanner!,
                              style: const TextStyle(
                                  color: Color(0xFF065F46), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Message d'erreur
                  if (_errorBanner != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorBanner!,
                              style: const TextStyle(
                                  color: Color(0xFF991B1B), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Si email vide, permettre de le saisir
                  if (_emailController.text.isEmpty) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'votre.email@exemple.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champ pour le code de confirmation
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Code de confirmation (6 chiffres)',
                      counterText: '',
                      hintText: '123456',
                      prefixIcon: const Icon(Icons.key_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton Valider
                  Pulse3DButton(
                    onPressed: authState.isLoading ? null : _verifyCode,
                    icon: Icons.verified_user_rounded,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Text(
                      authState.isLoading
                          ? 'Validation...'
                          : 'Confirmer mon adresse e-mail',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option pour renvoyer le code
                  Center(
                    child: TextButton.icon(
                      onPressed: _isResending ? null : _resendCode,
                      icon: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _isResending
                            ? 'Envoi en cours...'
                            : 'Renvoyer l\'e-mail de confirmation',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Retour connexion
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Retour à la page de connexion',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
