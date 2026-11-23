import 'question_model.dart';

class QuizModel {
  final String id;
  final String titre;
  final String? description;
  final bool estPublic;
  final String statut;
  final int dureeMinutes;
  final String codeAcces;
  final bool modeExamenSecurise;
  final String? enseignantId;
  final String? enseignantNom;
  final String? classeId;
  final String? classeNom;
  final String? matiereNom;
  final String? categorieNom;
  final int? nbQuestions;
  final int? nbTentatives;
  final Map<String, dynamic>? derniereTentative;
  final List<QuestionModel>? questions;

  QuizModel({
    required this.id,
    required this.titre,
    this.description,
    this.estPublic = false,
    this.statut = 'PUBLIE',
    this.dureeMinutes = 15,
    required this.codeAcces,
    this.modeExamenSecurise = false,
    this.enseignantId,
    this.enseignantNom,
    this.classeId,
    this.classeNom,
    this.matiereNom,
    this.categorieNom,
    this.nbQuestions,
    this.nbTentatives,
    this.derniereTentative,
    this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    String? enseignantNom;
    if (json['enseignant'] != null) {
      enseignantNom =
          '${json['enseignant']['prenom'] ?? ''} ${json['enseignant']['nom'] ?? ''}'.trim();
    }

    String? catNom;
    String? matNom;
    if (json['categorie'] != null) {
      catNom = json['categorie']['nom'];
      if (json['categorie']['matiere'] != null) {
        matNom = json['categorie']['matiere']['nom'];
      }
    }

    List<QuestionModel>? qList;
    if (json['questions'] != null) {
      qList = (json['questions'] as List<dynamic>)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    return QuizModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],
      estPublic: json['estPublic'] ?? false,
      statut: json['statut'] ?? 'PUBLIE',
      dureeMinutes: json['dureeMinutes'] ?? 15,
      codeAcces: json['codeAcces'] ?? '',
      modeExamenSecurise: json['modeExamenSecurise'] ?? false,
      enseignantId: json['enseignantId'],
      enseignantNom: enseignantNom,
      classeId: json['classeId'],
      classeNom: json['classe']?['nom'],
      matiereNom: matNom,
      categorieNom: catNom,
      nbQuestions: json['_count']?['questions'] ?? qList?.length,
      nbTentatives: json['_count']?['tentatives'],
      derniereTentative: json['derniereTentative'] as Map<String, dynamic>?,
      questions: qList,
    );
  }
}

