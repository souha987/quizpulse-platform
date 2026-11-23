import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/widgets/confetti_celebration.dart';

class HeroInteractiveQuizCard extends StatefulWidget {
  final VoidCallback? onExploreCatalog;

  const HeroInteractiveQuizCard({super.key, this.onExploreCatalog});

  @override
  State<HeroInteractiveQuizCard> createState() => _HeroInteractiveQuizCardState();
}

class _HeroInteractiveQuizCardState extends State<HeroInteractiveQuizCard>
    with SingleTickerProviderStateMixin {
  int? _selectedOption;
  bool _showConfetti = false;
  late AnimationController _shakeController;

  final List<String> _options = [
    'Notation instantanée & anti-triche sécurisé ⚡',
    'Attendre 3 semaines pour avoir sa note 😴',
    'Remplir des grilles papier austères 📝',
    'Des QCM sans explications ni stats ❌',
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onSelect(int index) {
    setState(() {
      _selectedOption = index;
      if (index == 0) {
        _showConfetti = true;
      } else {
        _showConfetti = false;
        _shakeController.forward(from: 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = _selectedOption == 0;

    return ConfettiCelebration(
      isPlaying: _showConfetti,
      onFinished: () => setState(() => _showConfetti = false),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = sin(_shakeController.value * 3.1415 * 4) * 6;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isCorrect
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE0E7FF),
              width: isCorrect ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isCorrect
                    ? const Color(0xFF10B981).withOpacity(0.25)
                    : const Color(0xFF2563EB).withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'DÉFI LIVE EN DIRECT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFD97706), size: 14),
                        SizedBox(width: 4),
                        Text(
                          '+100 XP',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Énoncé
              const Text(
                'Pourquoi les meilleures écoles et universités adoptent QuizPulse ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cliquez sur la bonne réponse pour tester en direct :',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // Options
              ..._options.asMap().entries.map((entry) {
                final idx = entry.key;
                final text = entry.value;
                final isSelected = _selectedOption == idx;
                final isThisCorrect = isSelected && idx == 0;
                final isThisWrong = isSelected && idx != 0;

                Color bg = const Color(0xFFF8FAFC);
                Color border = const Color(0xFFE2E8F0);
                Color textColor = const Color(0xFF1E293B);
                IconData icon = Icons.circle_outlined;
                Color iconColor = const Color(0xFF94A3B8);

                if (isThisCorrect) {
                  bg = const Color(0xFFECFDF5);
                  border = const Color(0xFF10B981);
                  textColor = const Color(0xFF065F46);
                  icon = Icons.check_circle_rounded;
                  iconColor = const Color(0xFF10B981);
                } else if (isThisWrong) {
                  bg = const Color(0xFFFFF1F2);
                  border = const Color(0xFFF43F5E);
                  textColor = const Color(0xFF9F1239);
                  icon = Icons.cancel_rounded;
                  iconColor = const Color(0xFFF43F5E);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _onSelect(idx),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border, width: isSelected ? 2 : 1.2),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: border.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Toast de succès ou encouragements
              if (isCorrect) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Color(0xFF16A34A), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🎉 Excellent ! Vous avez compris l\'esprit QuizPulse.',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

