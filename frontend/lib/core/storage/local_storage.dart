import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyQuizProgressPrefix = 'quiz_progress_';

  // Token JWT
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
    await prefs.remove(keyUser);
  }

  // Utilisateur
  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUser, jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyUser);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Sauvegarde automatique locale de l'état d'un quiz en cours
  // (si l'app est fermée accidentellement, elle se rouvre sur la même question)
  static Future<void> saveAttemptProgress({
    required String attemptId,
    String? identifiantSession,
    required int currentQuestionIndex,
    required Map<String, dynamic> selectedAnswers,
    required int remainingSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'attemptId': attemptId,
      'identifiantSession': identifiantSession,
      'currentQuestionIndex': currentQuestionIndex,
      'selectedAnswers': selectedAnswers,
      'remainingSeconds': remainingSeconds,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$keyQuizProgressPrefix$attemptId', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getAttemptProgress(String attemptId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$keyQuizProgressPrefix$attemptId');
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAttemptProgress(String attemptId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$keyQuizProgressPrefix$attemptId');
  }

  // Suivi de la tentative active par quizId (pour reprise fluide lors d'un rafraîchissement)
  static const String keyActiveQuizPrefix = 'active_quiz_';

  static Future<void> saveActiveQuizAttempt(String quizId, String attemptId, String? sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'attemptId': attemptId,
      'identifiantSession': sessionId,
    };
    await prefs.setString('$keyActiveQuizPrefix$quizId', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getActiveQuizAttempt(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$keyActiveQuizPrefix$quizId');
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearActiveQuizAttempt(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$keyActiveQuizPrefix$quizId');
  }
}

