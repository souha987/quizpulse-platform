enum QuestionType {
  qcmUnique,
  qcmMultiple,
  vraiFaux;

  static QuestionType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'QCM_MULTIPLE':
        return QuestionType.qcmMultiple;
      case 'VRAI_FAUX':
        return QuestionType.vraiFaux;
      case 'QCM_UNIQUE':
      default:
        return QuestionType.qcmUnique;
    }
  }

  String toServerString() {
    switch (this) {
      case QuestionType.qcmUnique:
        return 'QCM_UNIQUE';
      case QuestionType.qcmMultiple:
        return 'QCM_MULTIPLE';
      case QuestionType.vraiFaux:
        return 'VRAI_FAUX';
    }
  }

  String get label {
    switch (this) {
      case QuestionType.qcmUnique:
        return 'Choix unique';
      case QuestionType.qcmMultiple:
        return 'Choix multiples';
      case QuestionType.vraiFaux:
        return 'Vrai / Faux';
    }
  }
}

class OptionModel {
  final String id;
  final String texte;
  final bool? estCorrecte; // null pendant le passage sécurisé

  OptionModel({
    required this.id,
    required this.texte,
    this.estCorrecte,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] ?? '',
      texte: json['texte'] ?? '',
      estCorrecte: json['estCorrecte'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texte': texte,
      if (estCorrecte != null) 'estCorrecte': estCorrecte,
    };
  }
}

class QuestionModel {
  final String id;
  final String enonce;
  final QuestionType type;
  final double points;
  final int ordre;
  final String? explicationCorrection; // null pendant le passage sécurisé
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.enonce,
    required this.type,
    this.points = 1.0,
    this.ordre = 1,
    this.explicationCorrection,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
        .toList();

    return QuestionModel(
      id: json['id'] ?? '',
      enonce: json['enonce'] ?? '',
      type: QuestionType.fromString(json['type'] ?? 'QCM_UNIQUE'),
      points: (json['points'] as num?)?.toDouble() ?? 1.0,
      ordre: json['ordre'] ?? 1,
      explicationCorrection: json['explicationCorrection'],
      options: opts,
    );
  }
}

