class PlanModel {
  final String id;
  final String nom;
  final double prix;
  final int dureeJours;
  final int quotaQuiz; // -1 = illimité
  final int quotaClasses;
  final bool modeSecuriseAutorise;
  final bool active;

  PlanModel({
    required this.id,
    required this.nom,
    required this.prix,
    this.dureeJours = 30,
    this.quotaQuiz = 5,
    this.quotaClasses = 2,
    this.modeSecuriseAutorise = false,
    this.active = true,
  });

  bool get isUnlimitedQuiz => quotaQuiz == -1;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      dureeJours: json['dureeJours'] ?? 30,
      quotaQuiz: json['quotaQuiz'] ?? 5,
      quotaClasses: json['quotaClasses'] ?? 2,
      modeSecuriseAutorise: json['modeSecuriseAutorise'] ?? false,
      active: json['active'] ?? true,
    );
  }
}

