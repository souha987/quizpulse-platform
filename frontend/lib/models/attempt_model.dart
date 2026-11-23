class QuestionReviewModel {
  final String questionId;
  final String enonce;
  final String type;
  final double pointsPossible;
  final double pointsObtenus;
  final bool estCorrecte;
  final String? reponseUtilisateurOptionId;
  final String? explicationCorrection;
  final List<OptionReviewModel> options;

  QuestionReviewModel({
    required this.questionId,
    required this.enonce,
    required this.type,
    required this.pointsPossible,
    required this.pointsObtenus,
    required this.estCorrecte,
    this.reponseUtilisateurOptionId,
    this.explicationCorrection,
    required this.options,
  });

  factory QuestionReviewModel.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((o) => OptionReviewModel.fromJson(o as Map<String, dynamic>))
        .toList();

    return QuestionReviewModel(
      questionId: json['questionId'] ?? '',
      enonce: json['enonce'] ?? '',
      type: json['type'] ?? 'QCM_UNIQUE',
      pointsPossible: (json['pointsPossible'] as num?)?.toDouble() ?? 0.0,
      pointsObtenus: (json['pointsObtenus'] as num?)?.toDouble() ?? 0.0,
      estCorrecte: json['estCorrecte'] ?? false,
      reponseUtilisateurOptionId: json['reponseUtilisateurOptionId'],
      explicationCorrection: json['explicationCorrection'],
      options: opts,
    );
  }
}

class OptionReviewModel {
  final String id;
  final String texte;
  final bool estCorrecte;

  OptionReviewModel({
    required this.id,
    required this.texte,
    required this.estCorrecte,
  });

  factory OptionReviewModel.fromJson(Map<String, dynamic> json) {
    return OptionReviewModel(
      id: json['id'] ?? '',
      texte: json['texte'] ?? '',
      estCorrecte: json['estCorrecte'] ?? false,
    );
  }
}

class AttemptResultModel {
  final String tentativeId;
  final String statut;
  final bool estExpiree;
  final double score;
  final double totalPointsPossible;
  final int pourcentage;
  final double noteSur20;
  final int dureeSecondes;
  final int nbAvertissementsTriche;
  final List<QuestionReviewModel> corrige;

  AttemptResultModel({
    required this.tentativeId,
    required this.statut,
    required this.estExpiree,
    required this.score,
    required this.totalPointsPossible,
    required this.pourcentage,
    required this.noteSur20,
    required this.dureeSecondes,
    required this.nbAvertissementsTriche,
    required this.corrige,
  });

  factory AttemptResultModel.fromJson(Map<String, dynamic> json) {
    final corr = (json['corrige'] as List<dynamic>? ?? [])
        .map((c) => QuestionReviewModel.fromJson(c as Map<String, dynamic>))
        .toList();

    return AttemptResultModel(
      tentativeId: json['tentativeId'] ?? '',
      statut: json['statut'] ?? 'TERMINEE',
      estExpiree: json['estExpiree'] ?? (json['statut'] == 'EXPIREE'),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalPointsPossible: (json['totalPointsPossible'] as num?)?.toDouble() ?? 0.0,
      pourcentage: json['pourcentage'] ?? 0,
      noteSur20: (json['noteSur20'] as num?)?.toDouble() ?? 0.0,
      dureeSecondes: json['dureeSecondes'] ?? 0,
      nbAvertissementsTriche: json['nbAvertissementsTriche'] ?? 0,
      corrige: corr,
    );
  }
}

class AttemptHistoryItemModel {
  final String id;
  final String quizTitre;
  final DateTime dateDebut;
  final double score;
  final String statut;
  final int nbAvertissementsTriche;

  AttemptHistoryItemModel({
    required this.id,
    required this.quizTitre,
    required this.dateDebut,
    required this.score,
    required this.statut,
    required this.nbAvertissementsTriche,
  });

  factory AttemptHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return AttemptHistoryItemModel(
      id: json['id'] ?? '',
      quizTitre: json['quiz']?['titre'] ?? 'Quiz',
      dateDebut: json['dateDebut'] != null
          ? DateTime.parse(json['dateDebut'])
          : DateTime.now(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      statut: json['statut'] ?? 'TERMINEE',
      nbAvertissementsTriche: json['nbAvertissementsTriche'] ?? 0,
    );
  }
}

