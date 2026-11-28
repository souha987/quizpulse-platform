import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_alert.dart';
import '../../../models/question_model.dart';
import '../../../models/quiz_model.dart';
import '../../../shared/widgets/responsive_container.dart';

class QuizEditorScreen extends StatefulWidget {
  final String? quizId;
  final String? initialClassId;

  const QuizEditorScreen({super.key, this.quizId, this.initialClassId});

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _dureeMinutes = 15;
  bool _estPublic = false;
  bool _modeExamenSecurise = false;
  String _statut = 'BROUILLON';
  String? _classeId;
  List<dynamic> _availableClasses = [];
  bool _isLoadingClasses = false;
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditing => widget.quizId != null && widget.quizId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _classeId = widget.initialClassId;
    _loadClasses();
    if (_isEditing) {
      _loadQuizDetails();
    }
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final res = await apiClient.get('/classes/teacher');
      setState(() {
        _availableClasses = res.data as List<dynamic>? ?? [];
        _isLoadingClasses = false;
      });
    } catch (_) {
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadQuizDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/quiz/${widget.quizId}');
      final quiz = QuizModel.fromJson(res.data);

      setState(() {
        _titreCtrl.text = quiz.titre;
        _descCtrl.text = quiz.description ?? '';
        _dureeMinutes = quiz.dureeMinutes;
        _estPublic = quiz.estPublic;
        _modeExamenSecurise = quiz.modeExamenSecurise;
        _statut = quiz.statut;
        _classeId = quiz.classeId;
        _questions = quiz.questions ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final finalStatut = _estPublic ? 'PUBLIE' : _statut;
    if (_isEditing && finalStatut == 'PUBLIE' && _questions.isEmpty) {
      AppAlert.warning(context, 'Vous devez ajouter au moins une question avant de pouvoir publier ce quiz.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await apiClient.put('/quiz/${widget.quizId}', data: {
          'titre': _titreCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'dureeMinutes': _dureeMinutes,
          'estPublic': _estPublic,
          'modeExamenSecurise': _modeExamenSecurise,
          'statut': finalStatut,
          'classeId': _classeId,
        });
        if (mounted) {
          AppAlert.success(context, 'Quiz mis à jour avec succès');
        }
      } else {
        final res = await apiClient.post('/quiz', data: {
          'titre': _titreCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'dureeMinutes': _dureeMinutes,
          'estPublic': _estPublic,
          'statut': 'BROUILLON',
          'modeExamenSecurise': _modeExamenSecurise,
          if (_classeId != null) 'classeId': _classeId,
        });
        final newId = res.data['id'];
        if (mounted) {
          context.pushReplacement('/teacher/quiz/$newId/edit');
        }
      }
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors de l\'enregistrement');
      if (mounted) {
        AppAlert.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddQuestionDialog() {
    if (!_isEditing) {
      AppAlert.warning(context, 'Veuillez d\'abord enregistrer le quiz pour ajouter des questions');
      return;
    }

    final enonceCtrl = TextEditingController();
    QuestionType type = QuestionType.qcmUnique;
    double points = 1.0;

    List<Map<String, dynamic>> options = [
      {'texte': TextEditingController(), 'estCorrecte': true},
      {'texte': TextEditingController(), 'estCorrecte': false},
      {'texte': TextEditingController(), 'estCorrecte': false},
      {'texte': TextEditingController(), 'estCorrecte': false},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Ajouter une Question'),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: enonceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Énoncé de la question',
                        hintText: 'Ex: Quelle est la capitale de la France ?',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<QuestionType>(
                            value: type,
                            decoration: const InputDecoration(labelText: 'Type de question'),
                            items: QuestionType.values
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  type = val;
                                  if (type == QuestionType.vraiFaux) {
                                    options = [
                                      {'texte': TextEditingController(text: 'Vrai'), 'estCorrecte': true},
                                      {'texte': TextEditingController(text: 'Faux'), 'estCorrecte': false},
                                    ];
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue: '$points',
                            decoration: const InputDecoration(labelText: 'Points'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => points = double.tryParse(v) ?? 1.0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text('Options de réponse (cochez la/les bonnes réponses) :',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),

                    ...options.asMap().entries.map((entry) {
                      final i = entry.key;
                      final opt = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: opt['estCorrecte'],
                              onChanged: (val) {
                                setDialogState(() {
                                  if (type != QuestionType.qcmMultiple) {
                                    for (var o in options) {
                                      o['estCorrecte'] = false;
                                    }
                                  }
                                  opt['estCorrecte'] = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: opt['texte'],
                                decoration: InputDecoration(
                                  hintText: 'Option ${i + 1}',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (enonceCtrl.text.trim().isEmpty) return;

                  final validOptions = options
                      .where((o) => (o['texte'] as TextEditingController).text.trim().isNotEmpty)
                      .map((o) => {
                            'texte': (o['texte'] as TextEditingController).text.trim(),
                            'estCorrecte': o['estCorrecte'] as bool,
                          })
                      .toList();

                  if (validOptions.length < 2) {
                    AppAlert.warning(context, 'Veuillez définir au moins 2 options');
                    return;
                  }

                  final correctCount = validOptions.where((o) => o['estCorrecte'] == true).length;
                  if (correctCount == 0) {
                    AppAlert.warning(context, 'Veuillez cocher au moins une réponse correcte');
                    return;
                  }
                  if ((type == QuestionType.qcmUnique || type == QuestionType.vraiFaux) && correctCount > 1) {
                    AppAlert.warning(context, 'Une question à choix unique ou vrai/faux ne peut avoir qu\'une seule réponse correcte');
                    return;
                  }

                  try {
                    await apiClient.post('/quiz/${widget.quizId}/questions', data: {
                      'enonce': enonceCtrl.text.trim(),
                      'type': type.toServerString(),
                      'points': points,
                      'options': validOptions,
                    });
                    Navigator.pop(ctx);
                    _loadQuizDetails();
                  } catch (e) {
                    final msg = getErrorMessage(e, 'Erreur lors de l\'ajout');
                    if (mounted) {
                      AppAlert.error(context, msg);
                    }
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditQuestionDialog(QuestionModel q) {
    final enonceCtrl = TextEditingController(text: q.enonce);
    QuestionType type = q.type;
    double points = q.points;

    List<Map<String, dynamic>> options = q.options.map((opt) {
      return {
        'id': opt.id,
        'texte': TextEditingController(text: opt.texte),
        'estCorrecte': opt.estCorrecte ?? false,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Modifier la Question'),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: enonceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Énoncé de la question',
                        hintText: 'Ex: Quelle est la capitale de la France ?',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<QuestionType>(
                            value: type,
                            decoration: const InputDecoration(labelText: 'Type de question'),
                            items: QuestionType.values
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  type = val;
                                  if (type == QuestionType.vraiFaux) {
                                    options = [
                                      {'texte': TextEditingController(text: 'Vrai'), 'estCorrecte': true},
                                      {'texte': TextEditingController(text: 'Faux'), 'estCorrecte': false},
                                    ];
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue: '$points',
                            decoration: const InputDecoration(labelText: 'Points'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => points = double.tryParse(v) ?? 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Options de réponse (cochez les bonnes réponses) :',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (type != QuestionType.vraiFaux)
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                options.add({
                                  'texte': TextEditingController(),
                                  'estCorrecte': false,
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Option', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...options.asMap().entries.map((entry) {
                      final i = entry.key;
                      final opt = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: opt['estCorrecte'] as bool,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (type != QuestionType.qcmMultiple) {
                                    for (var o in options) {
                                      o['estCorrecte'] = false;
                                    }
                                  }
                                  opt['estCorrecte'] = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: opt['texte'] as TextEditingController,
                                decoration: InputDecoration(
                                  hintText: 'Option ${i + 1}',
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (type != QuestionType.vraiFaux && options.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.danger),
                                onPressed: () {
                                  setDialogState(() {
                                    options.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                onPressed: () async {
                  if (enonceCtrl.text.trim().isEmpty) return;

                  final validOptions = options
                      .where((o) => (o['texte'] as TextEditingController).text.trim().isNotEmpty)
                      .map((o) => {
                            'texte': (o['texte'] as TextEditingController).text.trim(),
                            'estCorrecte': o['estCorrecte'] as bool,
                          })
                      .toList();

                  if (validOptions.length < 2) {
                    AppAlert.warning(context, 'Veuillez définir au moins 2 options');
                    return;
                  }

                  final correctCount = validOptions.where((o) => o['estCorrecte'] == true).length;
                  if (correctCount == 0) {
                    AppAlert.warning(context, 'Veuillez cocher au moins une réponse correcte');
                    return;
                  }
                  if ((type == QuestionType.qcmUnique || type == QuestionType.vraiFaux) && correctCount > 1) {
                    AppAlert.warning(context, 'Une question à choix unique ou vrai/faux ne peut avoir qu\'une seule réponse correcte');
                    return;
                  }

                  try {
                    await apiClient.put('/quiz/${widget.quizId}/questions/${q.id}', data: {
                      'enonce': enonceCtrl.text.trim(),
                      'type': type.toServerString(),
                      'points': points,
                      'options': validOptions,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadQuizDetails();
                  } catch (e) {
                    final msg = getErrorMessage(e, 'Erreur lors de la modification');
                    if (mounted) {
                      AppAlert.error(context, msg);
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await apiClient.delete('/quiz/${widget.quizId}/questions/$questionId');
      _loadQuizDetails();
    } catch (_) {}
  }

  Future<void> _onReorderQuestions(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });

    final updates = _questions
        .asMap()
        .entries
        .map((e) => {'questionId': e.value.id, 'ordre': e.key + 1})
        .toList();

    try {
      await apiClient.post('/quiz/${widget.quizId}/reorder', data: {'questions': updates});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              _isEditing ? 'Éditeur de Quiz' : 'Créer un Quiz',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF18181B)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/teacher/quizzes'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF1E40AF)),
            label: const Text('Mes Quiz', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          ),
          const SizedBox(width: 8),
          if (_isEditing) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
                side: const BorderSide(color: Color(0xFF1E40AF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => context.push('/student/quiz/${widget.quizId}'),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              label: const Text('Prévisualiser', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: _isSaving ? null : _saveQuiz,
            icon: const Icon(Icons.save, size: 18),
            label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer le quiz', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ResponsiveContainer(
                maxWidth: 900,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Paramètres généraux
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Paramètres Généraux',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                              TextFormField(
                                controller: _titreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Titre de l\'évaluation',
                                  hintText: 'Ex: Évaluation sommative d\'histoire',
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Description / Instructions',
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _dureeMinutes,
                                      decoration: const InputDecoration(labelText: 'Durée'),
                                      items: [5, 10, 15, 20, 30, 45, 60, 90]
                                          .map((d) => DropdownMenuItem(
                                              value: d, child: Text('$d minutes')))
                                          .toList(),
                                      onChanged: (v) => setState(() => _dureeMinutes = v ?? 15),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: DropdownButtonFormField<bool>(
                                      value: _estPublic,
                                      decoration: const InputDecoration(
                                        labelText: 'Visibilité',
                                        prefixIcon: Icon(Icons.visibility_outlined, color: Color(0xFF2563EB)),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: false,
                                          child: Row(
                                            children: [
                                              Icon(Icons.lock_outline, size: 16, color: Color(0xFF2563EB)),
                                              SizedBox(width: 8),
                                              Text('Privé (Classe ou Code PIN)'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: true,
                                          child: Row(
                                            children: [
                                              Icon(Icons.public, size: 16, color: Color(0xFF10B981)),
                                              SizedBox(width: 8),
                                              Text('Public (Catalogue ouvert)'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        setState(() {
                                          _estPublic = v ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String?>(
                                value: _classeId,
                                decoration: InputDecoration(
                                  labelText: 'Classe assignée',
                                  helperText: _estPublic
                                      ? 'Pour un quiz public, l\'assignation à une classe est facultative.'
                                      : 'Sélectionnez la classe autorisée à passer ce quiz privé.',
                                  prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
                                  suffixIcon: _isLoadingClasses
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Aucune classe (Accès libre par code PIN)'),
                                  ),
                                  ..._availableClasses.map((c) {
                                    final cId = c['id'] as String;
                                    final cNom = (c['nom'] ?? 'Classe').toString();
                                    final cCode = (c['codeClasse'] ?? '').toString();
                                    return DropdownMenuItem<String?>(
                                      value: cId,
                                      child: Text('$cNom ($cCode)'),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setState(() => _classeId = val),
                              ),
                              const SizedBox(height: 14),
                              if (_isEditing) ...[
                                DropdownButtonFormField<String>(
                                  value: _statut,
                                  decoration: const InputDecoration(
                                    labelText: 'Statut de publication',
                                    prefixIcon: Icon(Icons.flag_outlined, color: Color(0xFF2563EB)),
                                    helperText: 'En mode Publié, les étudiants peuvent voir et passer l\'évaluation.',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'BROUILLON',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note, size: 18, color: Color(0xFFEAB308)),
                                          SizedBox(width: 8),
                                          Text('Brouillon (En cours d\'écriture - Masqué des élèves)'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'PUBLIE',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF10B981)),
                                          SizedBox(width: 8),
                                          Text('Publié (Ouvert aux élèves)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == 'PUBLIE' && _questions.isEmpty) {
                                      AppAlert.warning(context, 'Ajoutez au moins une question avant de publier ce quiz.');
                                      return;
                                    }
                                    setState(() => _statut = v ?? 'BROUILLON');
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Row(
                                  children: [
                                    Icon(Icons.shield_outlined, size: 18, color: Color(0xFFEA580C)),
                                    SizedBox(width: 8),
                                    Text('Mode Examen Sécurisé (Anti-Triche Strict)', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                subtitle: const Text(
                                    'Activer pour un examen officiel : toute sortie d\'écran ou changement d\'onglet annule immédiatement la copie avec 0/20.\nDésactiver pour un quiz d\'entraînement libre où l\'élève peut consulter ses cours.'),
                                value: _modeExamenSecurise,
                                onChanged: (v) => setState(() => _modeExamenSecurise = v),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Section Questions & Glisser-Déposer
                      Builder(
                        builder: (context) {
                          final totalBareme = _questions.fold<double>(0.0, (acc, q) => acc + q.points);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Questions de l\'évaluation',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      'Barème total : ${totalBareme.toStringAsFixed(1)} point(s) • Ramené sur 20 pour l\'élève',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (_isEditing) ...[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E40AF),
                                    side: const BorderSide(color: Color(0xFF1E40AF)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () => context.push('/student/quiz/${widget.quizId}'),
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                                  label: const Text('Prévisualiser', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: _showAddQuestionDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Ajouter une question', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      if (_questions.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.help_outline, size: 48, color: AppTheme.textMuted),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Aucune question pour l\'instant. Cliquez sur "Ajouter une question".',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          onReorder: _onReorderQuestions,
                          itemBuilder: (context, index) {
                            final q = _questions[index];

                            return Card(
                              key: ValueKey(q.id),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _showEditQuestionDialog(q),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  q.enonce,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${q.type.label} • ${q.points} point(s) • ${q.options.length} options',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                                      tooltip: 'Modifier cette question',
                                      onPressed: () => _showEditQuestionDialog(q),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                      tooltip: 'Supprimer cette question',
                                      onPressed: () => _deleteQuestion(q.id),
                                    ),
                                    const Icon(Icons.drag_handle, color: AppTheme.textMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
