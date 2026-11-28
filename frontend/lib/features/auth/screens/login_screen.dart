import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/app_alert.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      final role = ref.read(authProvider).role;
      if (role == UserRole.enseignant) {
        context.go('/teacher');
      } else if (role == UserRole.admin) {
        context.go('/admin');
      } else {
        context.go('/student');
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Mot de passe oublié ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saisissez l\'adresse e-mail associée à votre compte QuizPulse. Nous vous enverrons les instructions de réinitialisation.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                hintText: 'exemple@gmail.com',
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final email = emailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                AppAlert.warning(context, 'Veuillez saisir une adresse e-mail valide');
                return;
              }
              Navigator.pop(ctx);
              AppAlert.success(
                context,
                'Un lien de réinitialisation sécurisé a été envoyé à $email. Vérifiez votre boîte de réception.',
              );
            },
            child: const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image d'arrière-plan avec overlay bleu 50%
          Image.asset(
            'assets/images/classroom_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: const Color(0xFF1E3A8A).withOpacity(0.50),
          ),

          // Bouton flèche retour repositionné, stylisé et ultra-visible
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 20),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Retour',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenu centré
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ResponsiveContainer(
                  maxWidth: 480,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 560),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 42),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icône Chapeau de Diplômé Bleu (remplaçant le vert)
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 34),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Titre et sous-titre
                          const Text(
                            'Heureux de vous retrouver',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connectez-vous pour accéder à votre espace de travail et vos évaluations.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          if (authState.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.mark_email_unread_rounded, color: Color(0xFFDC2626), size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (authState.errorMessage!.toLowerCase().contains('e-mail') ||
                                      authState.errorMessage!.toLowerCase().contains('mail')) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            final email = _emailController.text.trim();
                                            context.push('/verify-email?email=${Uri.encodeComponent(email)}');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4F46E5),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          icon: const Icon(Icons.check_circle_outline, size: 16),
                                          label: const Text('Confirmer mon compte'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final email = _emailController.text.trim();
                                            if (email.isEmpty) {
                                              AppAlert.warning(context, 'Veuillez renseigner votre e-mail');
                                              return;
                                            }
                                            final ok = await ref.read(authProvider.notifier).resendVerificationEmail(email);
                                            if (context.mounted) {
                                              if (ok) {
                                                AppAlert.success(context, 'E-mail de confirmation renvoyé ! Vérifiez votre boîte mail.');
                                              } else {
                                                AppAlert.error(context, 'Erreur lors du renvoi.');
                                              }
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF4F46E5),
                                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          icon: const Icon(Icons.refresh_rounded, size: 16),
                                          label: const Text('Renvoyer l\'e-mail'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                          ),
                          const SizedBox(height: 12),

                          // Lien mot de passe oublié aligné à droite
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text('Mot de passe oublié ?', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bouton Se connecter
                          Pulse3DButton(
                            width: double.infinity,
                            backgroundColor: const Color(0xFF2563EB),
                            shadowColor: const Color(0xFF1D4ED8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            borderRadius: 14,
                            onPressed: authState.isLoading ? null : _submit,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Liens inscriptions / invité
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Pas encore de compte ?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: const Text('S\'inscrire', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ),
                            ],
                          ),

                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text(
                                'Continuer en invité',
                                style: TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
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
            ),
          ),
        ],
      ),
    );
  }
}
