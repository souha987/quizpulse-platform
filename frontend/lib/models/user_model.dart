enum UserRole {
  visiteur,
  etudiant,
  enseignant,
  admin;

  static UserRole fromString(String val) {
    switch (val.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'ENSEIGNANT':
        return UserRole.enseignant;
      case 'ETUDIANT':
      default:
        return UserRole.etudiant;
    }
  }

  String toServerString() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.enseignant:
        return 'ENSEIGNANT';
      case UserRole.etudiant:
        return 'ETUDIANT';
      case UserRole.visiteur:
        return 'VISITEUR';
    }
  }
}

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final bool actif;
  final bool emailVerifie;
  final DateTime? dateInscription;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.actif = true,
    this.emailVerifie = true,
    this.dateInscription,
  });

  String get nomComplet => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'ETUDIANT'),
      actif: json['actif'] ?? true,
      emailVerifie: json['emailVerifie'] ?? true,
      dateInscription: json['dateInscription'] != null
          ? DateTime.tryParse(json['dateInscription'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role.toServerString(),
      'actif': actif,
      'emailVerifie': emailVerifie,
      'dateInscription': dateInscription?.toIso8601String(),
    };
  }
}

