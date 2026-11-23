import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/quiz_pulse_logo.dart';
import '../../../shared/widgets/responsive_container.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.etudiant;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).register(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          motDePasse: _passwordController.text,
          role: _selectedRole,
        );

    if (result.success && mounted) {
      if (result.requiresVerification) {
        AppAlert.info(
          context,
          result.message ?? 'Inscription réussie ! Veuillez vérifier votre boîte mail.',
          title: 'Vérification requise',
        );
        context.go('/verify-email?email=${Uri.encodeComponent(result.email)}');
      } else {
        if (_selectedRole == UserRole.enseignant) {
          context.go('/teacher');
        } else {
          context.go('/student');
        }
      }
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
          onPressed: () => context.pop(),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: QuizPulseLogo(size: 44, showText: false),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Inscription QuizPulse',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choisissez votre profil pour débuter immédiatement',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Sélecteur de Rôle (Étudiant vs Enseignant)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = UserRole.etudiant),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.etudiant ? const Color(0xFFF7FEE7) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedRole == UserRole.etudiant ? const Color(0xFF65A30D) : const Color(0xFFE2E8F0),
                                  width: _selectedRole == UserRole.etudiant ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.school, color: _selectedRole == UserRole.etudiant ? const Color(0xFF4D7C0F) : const Color(0xFF64748B)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Étudiant',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedRole == UserRole.etudiant ? const Color(0xFF4D7C0F) : const Color(0xFF334155)),
                                  ),
                                  Text(
                                    '100% Gratuit',
                                    style: TextStyle(fontSize: 10, color: _selectedRole == UserRole.etudiant ? const Color(0xFF65A30D) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = UserRole.enseignant),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.enseignant ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedRole == UserRole.enseignant ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                  width: _selectedRole == UserRole.enseignant ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.co_present, color: _selectedRole == UserRole.enseignant ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enseignant',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedRole == UserRole.enseignant ? const Color(0xFF2563EB) : const Color(0xFF334155)),
                                  ),
                                  Text(
                                    'Quiz Studio Pro',
                                    style: TextStyle(fontSize: 10, color: _selectedRole == UserRole.enseignant ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (authState.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prenomController,
                            decoration: const InputDecoration(labelText: 'Prénom'),
                            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(labelText: 'Nom'),
                            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe (8+ caractères, 1 chiffre)',
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
                      validator: (v) => v == null || v.length < 8 ? '8 caractères minimum' : null,
                    ),
                    const SizedBox(height: 24),

                    Pulse3DButton(
                      width: double.infinity,
                      backgroundColor: const Color(0xFF2563EB),
                      shadowColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Créer mon compte QuizPulse', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Déjà inscrit ?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Se connecter', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
