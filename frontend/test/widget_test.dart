import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edutech_quiz_app/models/user_model.dart';
import 'package:edutech_quiz_app/models/question_model.dart';
import 'package:edutech_quiz_app/models/quiz_model.dart';
import 'package:edutech_quiz_app/shared/widgets/loading_skeleton.dart';
import 'package:edutech_quiz_app/shared/widgets/responsive_container.dart';

void main() {
  group('QA Tests - Modèles de Données & Widgets UI', () {
    test('UserModel doit parser correctement les données JSON et rôles', () {
      final json = {
        'id': 'usr-1',
        'nom': 'Curie',
        'prenom': 'Marie',
        'email': 'marie@test.com',
        'role': 'ENSEIGNANT',
        'actif': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'usr-1');
      expect(user.nomComplet, 'Marie Curie');
      expect(user.role, UserRole.enseignant);
      expect(user.role.toServerString(), 'ENSEIGNANT');
    });

    test('QuizModel et QuestionModel doivent parser correctement', () {
      final quizJson = {
        'id': 'q-100',
        'titre': 'Quiz de Sécurité',
        'dureeMinutes': 20,
        'codeAcces': '999888',
        'modeExamenSecurise': true,
        'questions': [
          {
            'id': 'qst-1',
            'enonce': 'Quelle est la commande pour lister les fichiers ?',
            'type': 'QCM_UNIQUE',
            'points': 2.0,
            'options': [
              {'id': 'o-1', 'texte': 'ls', 'estCorrecte': true},
              {'id': 'o-2', 'texte': 'cd', 'estCorrecte': false},
            ],
          }
        ],
      };

      final quiz = QuizModel.fromJson(quizJson);
      expect(quiz.titre, 'Quiz de Sécurité');
      expect(quiz.modeExamenSecurise, true);
      expect(quiz.questions?.length, 1);
      expect(quiz.questions?[0].type, QuestionType.qcmUnique);
      expect(quiz.questions?[0].options.length, 2);
    });

    testWidgets('ResponsiveContainer et LoadingSkeleton doivent se rendre sans erreur', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              child: LoadingSkeleton(width: 200, height: 40),
            ),
          ),
        ),
      );

      expect(find.byType(ResponsiveContainer), findsOneWidget);
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });
  });
}
