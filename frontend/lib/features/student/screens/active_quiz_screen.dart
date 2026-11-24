import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/question_model.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../shared/widgets/pulse_3d_button.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/edu_mascot.dart';
import '../../../shared/widgets/loading_skeleton.dart';

class ActiveQuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const ActiveQuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends ConsumerState<ActiveQuizScreen>
    with WidgetsBindingObserver {
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _hideTimer = false;
  bool _isWarningDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(quizAttemptProvider.notifier).startQuiz(widget.quizId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Détection Anti-Triche : perte de focus / changement d'onglet / passage en arrière-plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final attemptState = ref.read(quizAttemptProvider);

    // Mode examen sécurisé actif pour tout le déroulement du quiz
    if (!attemptState.isCompleted && !attemptState.isSubmitting && attemptState.questions.isNotEmpty) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.hidden) {
        _handleCheatingDetected();
      }
    }
  }

  void _handleCheatingDetected() {
    if (_isWarningDialogOpen || !mounted) return;
    final attemptState = ref.read(quizAttemptProvider);
    if (attemptState.isCompleted || attemptState.isSubmitting) return;

    _isWarningDialogOpen = true;
    // Enregistrement et annulation immédiate de la tentative côté serveur
    ref.read(quizAttemptProvider.notifier).recordCheatWarning();

    // Annulation immédiate de l'épreuve sans avertissements (tolérance zéro triche)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Évaluation Annulée (Triche)',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w900,
                  fontSize: 16.5,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez quitté la page de l\'évaluation ou changé d\'onglet.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 12),
            Text(
              'Conformément aux consignes de surveillance académique, toute sortie de page entraîne l\'annulation immédiate de votre épreuve.\n\nVotre copie est invalidée avec la note de 0/20 et l\'incident « Triche Détectée » a été directement notifié à votre enseignant.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _isWarningDialogOpen = false;
              ref.read(quizAttemptProvider.notifier).submitQuiz(isAutoExpired: true);
            },
            child: const Text('Voir le Résultat (0/20)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final attemptState = ref.read(quizAttemptProvider);
    if (attemptState.questions.isEmpty || attemptState.isLoading || attemptState.isCompleted) {
      return;
    }

    final currentQ = attemptState.questions[attemptState.currentQuestionIndex];
    final key = event.logicalKey;

    // Raccourcis Options A/1, B/2, C/3, D/4
    int? targetOptionIndex;
    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      targetOptionIndex = 0;
    } else if (key == LogicalKeyboardKey.keyB || key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      targetOptionIndex = 1;
    } else if (key == LogicalKeyboardKey.keyC || key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      targetOptionIndex = 2;
    } else if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      targetOptionIndex = 3;
    }

    if (targetOptionIndex != null && targetOptionIndex < currentQ.options.length) {
      final option = currentQ.options[targetOptionIndex];
      final selectedAns = attemptState.selectedAnswers[currentQ.id];
      final isMultiple = currentQ.type == QuestionType.qcmMultiple;

      if (isMultiple) {
        final list = selectedAns is List ? List<String>.from(selectedAns) : <String>[];
        if (list.contains(option.id)) {
          list.remove(option.id);
        } else {
          list.add(option.id);
        }
        ref.read(quizAttemptProvider.notifier).selectAnswer(currentQ.id, list);
      } else {
        ref.read(quizAttemptProvider.notifier).selectAnswer(currentQ.id, option.id);
      }
      return;
    }

    // Raccourcis Flèches Gauche / Droite
    if (key == LogicalKeyboardKey.arrowLeft) {
      ref.read(quizAttemptProvider.notifier).previousQuestion();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      ref.read(quizAttemptProvider.notifier).nextQuestion();
    } else if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.keyF) {
      ref.read(quizAttemptProvider.notifier).toggleBookmark(currentQ.id);
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _confirmSubmit() {
    final state = ref.read(quizAttemptProvider);
    final unanswered = state.questions.length - state.selectedAnswers.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la soumission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir rendre votre copie maintenant ?'),
            if (unanswered > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention : il reste $unanswered question(s) sans réponse.',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer le quiz'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(quizAttemptProvider.notifier).submitQuiz();
              if (success && mounted) {
                context.pushReplacement('/student/result');
              }
            },
            child: const Text('Rendre ma copie'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPalette(QuizAttemptState attemptState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ResponsiveContainer(
        maxWidth: 820,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apps, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                const Text(
                  'Palette de navigation :',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                _buildLegendItem(const Color(0xFF10B981), 'Répondu'),
                const SizedBox(width: 10),
                _buildLegendItem(const Color(0xFFF59E0B), 'Épinglé'),
                const SizedBox(width: 10),
                _buildLegendItem(const Color(0xFF94A3B8), 'Non vu'),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: attemptState.questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  final isCurrent = idx == attemptState.currentQuestionIndex;
                  final isAnswered = attemptState.selectedAnswers.containsKey(q.id);
                  final isBookmarked = attemptState.bookmarkedQuestionIds.contains(q.id);

                  Color bgColor;
                  Color borderColor;
                  Color textColor;

                  if (isCurrent) {
                    bgColor = const Color(0xFFEEF2FF);
                    borderColor = const Color(0xFF2563EB);
                    textColor = const Color(0xFF2563EB);
                  } else if (isBookmarked) {
                    bgColor = const Color(0xFFFEF3C7);
                    borderColor = const Color(0xFFF59E0B);
                    textColor = const Color(0xFFB45309);
                  } else if (isAnswered) {
                    bgColor = const Color(0xFFECFDF5);
                    borderColor = const Color(0xFF10B981);
                    textColor = const Color(0xFF047857);
                  } else {
                    bgColor = const Color(0xFFF8FAFC);
                    borderColor = const Color(0xFFCBD5E1);
                    textColor = const Color(0xFF64748B);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => ref.read(quizAttemptProvider.notifier).goToQuestion(idx),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: isCurrent ? 2.5 : 1.2),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                                fontSize: 13,
                              ),
                              child: Text('${idx + 1}'),
                            ),
                            if (isBookmarked)
                              const Positioned(
                                top: 2,
                                right: 2,
                                child: Icon(Icons.bookmark, size: 10, color: Color(0xFFD97706)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuizAttemptState>(quizAttemptProvider, (prev, next) {
      if (next.isCompleted && mounted) {
        context.pushReplacement('/student/result');
      }
    });

    final attemptState = ref.watch(quizAttemptProvider);

    if (attemptState.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EduMascot(
                    mood: MascotMood.thinking,
                    size: 120,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Préparation de l\'évaluation sécurisée...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Vérification de l\'intégrité et chargement des questions...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 28),
                  QuizPreparationSkeleton(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (attemptState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                Text(
                  attemptState.errorMessage!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (attemptState.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Évaluation')),
        body: const Center(
          child: Text('Ce quiz ne contient aucune question pour le moment.'),
        ),
      );
    }

    final currentQ = attemptState.questions[attemptState.currentQuestionIndex];
    final selectedAns = attemptState.selectedAnswers[currentQ.id];
    final isBookmarked = attemptState.bookmarkedQuestionIds.contains(currentQ.id);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _confirmSubmit();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text(
              attemptState.quiz?.titre ?? 'Évaluation',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              // Indicateur Examen Sécurisé et Avertissements
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: attemptState.nbWarnings > 0
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: attemptState.nbWarnings > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      size: 16,
                      color: attemptState.nbWarnings > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attemptState.nbWarnings > 0
                          ? 'Triche Détectée (Annulé)'
                          : 'Anti-Triche Strict (Sortie = 0/20)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: attemptState.nbWarnings > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),

              // Compte à rebours interactif (Toggle Masquer / Afficher)
              InkWell(
                onTap: () => setState(() => _hideTimer = !_hideTimer),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: attemptState.isCriticalTime
                        ? const Color(0xFFEF4444)
                        : (_hideTimer ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: attemptState.isCriticalTime
                          ? const Color(0xFFDC2626)
                          : (_hideTimer ? const Color(0xFFCBD5E1) : const Color(0xFFC7D2FE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hideTimer && !attemptState.isCriticalTime
                            ? Icons.visibility_off_outlined
                            : Icons.timer_outlined,
                        size: 16,
                        color: attemptState.isCriticalTime
                            ? Colors.white
                            : (_hideTimer ? const Color(0xFF64748B) : const Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hideTimer && !attemptState.isCriticalTime
                            ? 'Chrono masqué'
                            : _formatDuration(attemptState.remainingSeconds),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: attemptState.isCriticalTime
                              ? Colors.white
                              : (_hideTimer ? const Color(0xFF64748B) : const Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Barre de progression fluide
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: attemptState.progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return LinearProgressIndicator(
                    value: animatedValue,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 4.5,
                  );
                },
              ),

              // Palette Interactive de Questions
              _buildQuestionPalette(attemptState),

              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveContainer(
                    maxWidth: 820,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Header Question avec Raccourcis et Bookmark
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Question ${attemptState.currentQuestionIndex + 1} / ${attemptState.questions.length}',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${currentQ.points} pt${currentQ.points > 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Bouton Épingler pour révision
                            ActionChip(
                              avatar: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 16,
                                color: isBookmarked ? const Color(0xFFD97706) : const Color(0xFF64748B),
                              ),
                              label: Text(
                                isBookmarked ? 'Épinglée 📌' : 'Épingler',
                                style: TextStyle(
                                  color: isBookmarked ? const Color(0xFFB45309) : const Color(0xFF475569),
                                  fontWeight: isBookmarked ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: isBookmarked ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                              side: BorderSide(
                                color: isBookmarked ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                              ),
                              onPressed: () => ref.read(quizAttemptProvider.notifier).toggleBookmark(currentQ.id),
                            ),
                            const SizedBox(width: 10),

                            // Indicateur de Sauvegarde
                            const Row(
                              children: [
                                Icon(Icons.cloud_done, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Sauvegardé',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Énoncé de la question
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentQ.enonce,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentQ.type.label,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '• Utilisez les touches A, B, C, D pour répondre',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Options de réponse avec badges de lettres A, B, C, D
                        ...currentQ.options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final option = entry.value;
                          final isMultiple = currentQ.type == QuestionType.qcmMultiple;
                          bool isSelected = false;

                          if (isMultiple) {
                            final list = selectedAns is List ? selectedAns : [];
                            isSelected = list.contains(option.id);
                          } else {
                            isSelected = selectedAns == option.id;
                          }

                          const optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];
                          final letter = i < optionLetters.length ? optionLetters[i] : '${i + 1}';

                          return InkWell(
                            onTap: () {
                              if (isMultiple) {
                                final list = selectedAns is List
                                    ? List<String>.from(selectedAns)
                                    : <String>[];
                                if (list.contains(option.id)) {
                                  list.remove(option.id);
                                } else {
                                  list.add(option.id);
                                }
                                ref
                                    .read(quizAttemptProvider.notifier)
                                    .selectAnswer(currentQ.id, list);
                              } else {
                                ref
                                    .read(quizAttemptProvider.notifier)
                                    .selectAnswer(currentQ.id, option.id);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedScale(
                              scale: isSelected ? 1.02 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? const Color(0xFF2563EB).withOpacity(0.08)
                                          : Colors.black.withOpacity(0.01),
                                      blurRadius: isSelected ? 10 : 6,
                                      offset: Offset(0, isSelected ? 3 : 2),
                                    ),
                                  ],
                                ),
                              child: Row(
                                children: [
                                  // Badge de la touche clavier A, B, C, D
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        letter,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Icon(
                                    isMultiple
                                        ? (isSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank)
                                        : (isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off),
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.texte,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        }),

                        const SizedBox(height: 12),

                        // Barre d'aide pour les raccourcis
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.keyboard, size: 16, color: Color(0xFF475569)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Touches : [A, B, C, D] pour répondre • [← / →] pour naviguer • [P] pour épingler',
                                  style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Barre de Navigation inférieure
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: ResponsiveContainer(
                  maxWidth: 820,
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Pulse3DButton(
                        height: 48,
                        backgroundColor: Colors.white,
                        shadowColor: const Color(0xFFCBD5E1),
                        foregroundColor: const Color(0xFF0F172A),
                        icon: Icons.arrow_back,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        borderRadius: 10,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        onPressed: attemptState.currentQuestionIndex > 0
                            ? () => ref.read(quizAttemptProvider.notifier).previousQuestion()
                            : null,
                        child: const Text('Précédent (←)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      ),
                      const Spacer(),
                      if (attemptState.currentQuestionIndex < attemptState.questions.length - 1)
                        Pulse3DButton(
                          height: 48,
                          backgroundColor: const Color(0xFF2563EB),
                          shadowColor: const Color(0xFF1D4ED8),
                          icon: Icons.arrow_forward,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          borderRadius: 10,
                          onPressed: () =>
                              ref.read(quizAttemptProvider.notifier).nextQuestion(),
                          child: const Text('Suivant (→)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        )
                      else
                        Pulse3DButton(
                          height: 48,
                          backgroundColor: const Color(0xFF10B981),
                          shadowColor: const Color(0xFF047857),
                          icon: Icons.check_circle_outline,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          borderRadius: 10,
                          onPressed: _confirmSubmit,
                          child: const Text('Terminer et Rendre', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
