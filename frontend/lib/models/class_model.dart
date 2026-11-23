class ClassModel {
  final String id;
  final String nom;
  final String codeClasse;
  final String enseignantId;
  final String? enseignantNom;
  final int nbEtudiants;
  final int nbQuiz;

  ClassModel({
    required this.id,
    required this.nom,
    required this.codeClasse,
    required this.enseignantId,
    this.enseignantNom,
    this.nbEtudiants = 0,
    this.nbQuiz = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    String? enseignantNom;
    if (json['enseignant'] != null) {
      enseignantNom =
          '${json['enseignant']['prenom'] ?? ''} ${json['enseignant']['nom'] ?? ''}'.trim();
    }

    return ClassModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      codeClasse: json['codeClasse'] ?? '',
      enseignantId: json['enseignantId'] ?? '',
      enseignantNom: enseignantNom,
      nbEtudiants: json['_count']?['etudiants'] ?? 0,
      nbQuiz: json['_count']?['quizAssignes'] ?? 0,
    );
  }
}

