import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/api_error.dart';
import '../core/storage/local_storage.dart';
import '../models/attempt_model.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';

class QuizAttemptState {
  final bool isLoading;
  final String? errorMessage;
  final String? attemptId;
  final String? identifiantSession;
  final QuizModel? quiz;
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  // Map questionId -> optionId ou List<optionId>
  final Map<String, dynamic> selectedAnswers;
  final Set<String> bookmarkedQuestionIds;
  final int remainingSeconds;
  final int totalDurationSeconds;
  final int nbWarnings;
  final bool isSubmitting;
  final AttemptResultModel? result;

  QuizAttemptState({
    this.isLoading = false,
    this.errorMessage,
    this.attemptId,
    this.identifiantSession,
    this.quiz,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.bookmarkedQuestionIds = const {},
    this.remainingSeconds = 0,
    this.totalDurationSeconds = 0,
    this.nbWarnings = 0,
    this.isSubmitting = false,
    this.result,
  });

  bool get isCompleted => result != null;
  bool get isCriticalTime => remainingSeconds <= 60 && remainingSeconds > 0;
  double get progress =>
      questions.isEmpty ? 0 : (currentQuestionIndex + 1) / questions.length;

  QuizAttemptState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? attemptId,
    String? identifiantSession,
    QuizModel? quiz,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    Map<String, dynamic>? selectedAnswers,
    Set<String>? bookmarkedQuestionIds,
    int? remainingSeconds,
    int? totalDurationSeconds,
    int? nbWarnings,
    bool? isSubmitting,
    AttemptResultModel? result,
  }) {
    return QuizAttemptState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      attemptId: attemptId ?? this.attemptId,
      identifiantSession: identifiantSession ?? this.identifiantSession,
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      bookmarkedQuestionIds: bookmarkedQuestionIds ?? this.bookmarkedQuestionIds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      nbWarnings: nbWarnings ?? this.nbWarnings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result ?? this.result,
    );
  }
}

class QuizAttemptNotifier extends StateNotifier<QuizAttemptState> {
  Timer? _countdownTimer;

  QuizAttemptNotifier() : super(QuizAttemptState());

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<bool> startQuiz(String quizId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Reprendre la session précédente si disponible pour éviter une nouvelle tentative au rafraîchissement
      final activeAttempt = await LocalStorage.getActiveQuizAttempt(quizId);
      final prevSessionId = activeAttempt?['identifiantSession'] as String?;

      final response = await apiClient.get(
        '/quiz/$quizId/start',
        queryParameters: prevSessionId != null ? {'sessionId': prevSessionId} : null,
        options: prevSessionId != null ? Options(headers: {'x-session-id': prevSessionId}) : null,
      );
      final data = response.data;

      final attemptId = data['tentativeId'];
      final identifiantSession = data['identifiantSession'] as String?;
      final serverRemainingSeconds = data['tempsRestantSecondes'] as int?;
      final quizData = data['quiz'];
      final quiz = QuizModel.fromJson(quizData);
      final questions = (quizData['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();

      final totalSeconds = (quiz.dureeMinutes) * 60;

      // Sauvegarder la tentative active pour ce quizId
      await LocalStorage.saveActiveQuizAttempt(quizId, attemptId, identifiantSession);

      // Vérifier s'il y a une sauvegarde locale antérieure
      final savedProgress = await LocalStorage.getAttemptProgress(attemptId);
      int startIndex = 0;
      Map<String, dynamic> initialAnswers = {};
      int secondsRemaining = serverRemainingSeconds ?? totalSeconds;

      if (savedProgress != null) {
        startIndex = savedProgress['currentQuestionIndex'] ?? 0;
        initialAnswers = Map<String, dynamic>.from(savedProgress['selectedAnswers'] ?? {});
        final localRemaining = savedProgress['remainingSeconds'] as int?;
        if (localRemaining != null && serverRemainingSeconds != null) {
          // Utiliser la valeur la plus restrictive pour empêcher la triche
          secondsRemaining = localRemaining < serverRemainingSeconds ? localRemaining : serverRemainingSeconds;
        } else if (localRemaining != null) {
          secondsRemaining = localRemaining;
        }
      }

      state = QuizAttemptState(
        attemptId: attemptId,
        identifiantSession: identifiantSession ?? (savedProgress?['identifiantSession'] as String?),
        quiz: quiz,
        questions: questions,
        currentQuestionIndex: startIndex < questions.length ? startIndex : 0,
        selectedAnswers: initialAnswers,
        totalDurationSeconds: totalSeconds,
        remainingSeconds: secondsRemaining,
        isLoading: false,
      );

      _startTimer();
      return true;
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors du démarrage du quiz');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        timer.cancel();
        submitQuiz(isAutoExpired: true);
      } else {
        final newSec = state.remainingSeconds - 1;
        state = state.copyWith(remainingSeconds: newSec);

        // Sauvegarde toutes les 15 secondes
        if (newSec % 15 == 0 && state.attemptId != null) {
          _saveStateLocally();
        }
      }
    });
  }

  void selectAnswer(String questionId, dynamic answer) {
    final updated = Map<String, dynamic>.from(state.selectedAnswers);
    updated[questionId] = answer;

    state = state.copyWith(selectedAnswers: updated);
    _saveStateLocally();
  }

  void toggleBookmark(String questionId) {
    final updated = Set<String>.from(state.bookmarkedQuestionIds);
    if (updated.contains(questionId)) {
      updated.remove(questionId);
    } else {
      updated.add(questionId);
    }
    state = state.copyWith(bookmarkedQuestionIds: updated);
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
      _saveStateLocally();
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
      _saveStateLocally();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
      _saveStateLocally();
    }
  }

  void _saveStateLocally() {
    if (state.attemptId == null) return;
    LocalStorage.saveAttemptProgress(
      attemptId: state.attemptId!,
      identifiantSession: state.identifiantSession,
      currentQuestionIndex: state.currentQuestionIndex,
      selectedAnswers: state.selectedAnswers,
      remainingSeconds: state.remainingSeconds,
    );
  }

  Future<void> recordCheatWarning() async {
    if (state.attemptId == null || state.isCompleted) return;

    final newCount = state.nbWarnings + 1;
    state = state.copyWith(nbWarnings: newCount);

    try {
      await apiClient.post('/attempts/${state.attemptId}/warning');
    } catch (_) {}
  }

  Future<bool> submitQuiz({bool isAutoExpired = false}) async {
    if (state.attemptId == null || state.isSubmitting) return false;
    _countdownTimer?.cancel();

    state = state.copyWith(isSubmitting: true);

    try {
      // Transformation des réponses au format attendu par le backend
      final answersList = <Map<String, dynamic>>[];

      for (final q in state.questions) {
        final ans = state.selectedAnswers[q.id];
        if (ans != null) {
          if (q.type == QuestionType.qcmMultiple) {
            final List<String> optIds = ans is List ? List<String>.from(ans) : [ans.toString()];
            answersList.add({
              'questionId': q.id,
              'optionIds': optIds,
            });
          } else {
            answersList.add({
              'questionId': q.id,
              'optionId': ans.toString(),
            });
          }
        }
      }

      final payload = <String, dynamic>{
        'reponses': answersList,
        'estExpiree': isAutoExpired || state.remainingSeconds <= 0,
      };

      if (state.identifiantSession != null && state.identifiantSession!.isNotEmpty) {
        payload['identifiantSession'] = state.identifiantSession;
      }

      final response = await apiClient.post(
        '/attempts/${state.attemptId}/submit',
        data: payload,
      );

      final result = AttemptResultModel.fromJson(response.data);

      // Nettoyer la sauvegarde locale
      await LocalStorage.clearAttemptProgress(state.attemptId!);
      if (state.quiz?.id != null) {
        await LocalStorage.clearActiveQuizAttempt(state.quiz!.id);
      }

      state = state.copyWith(
        isSubmitting: false,
        result: result,
      );
      return true;
    } catch (e) {
      final msg = getErrorMessage(e, 'Erreur lors de la soumission');
      state = state.copyWith(isSubmitting: false, errorMessage: msg);
      return false;
    }
  }
}

final quizAttemptProvider =
    StateNotifierProvider<QuizAttemptNotifier, QuizAttemptState>((ref) {
  return QuizAttemptNotifier();
});
