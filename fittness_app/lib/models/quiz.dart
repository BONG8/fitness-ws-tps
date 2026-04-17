enum Obiettivo { dimagrimento, massa, resistenza, mobilita, forza }

enum Livello { principiante, intermedio, avanzato }

extension ObiettivoX on Obiettivo {
  String get value => name;
  String get label {
    switch (this) {
      case Obiettivo.dimagrimento:
        return 'Dimagrimento';
      case Obiettivo.massa:
        return 'Massa';
      case Obiettivo.resistenza:
        return 'Resistenza';
      case Obiettivo.mobilita:
        return 'Mobilità';
      case Obiettivo.forza:
        return 'Forza';
    }
  }

  static Obiettivo fromString(String? s) =>
      Obiettivo.values.firstWhere((e) => e.name == s,
          orElse: () => Obiettivo.massa);
}

extension LivelloX on Livello {
  String get value => name;
  String get label {
    switch (this) {
      case Livello.principiante:
        return 'Principiante';
      case Livello.intermedio:
        return 'Intermedio';
      case Livello.avanzato:
        return 'Avanzato';
    }
  }

  static Livello fromString(String? s) =>
      Livello.values.firstWhere((e) => e.name == s,
          orElse: () => Livello.principiante);
}

class QuizInput {
  final Obiettivo obiettivo;
  final Livello livello;
  final int giorniSettimana;
  final int durataSessione;
  final String attrezzatura;
  final String limitazioni;

  QuizInput({
    required this.obiettivo,
    required this.livello,
    required this.giorniSettimana,
    required this.durataSessione,
    this.attrezzatura = 'nessuna',
    this.limitazioni = '',
  });

  Map<String, dynamic> toJson() => {
        'obiettivo': obiettivo.value,
        'livello': livello.value,
        'giorni_settimana': giorniSettimana,
        'durata_sessione': durataSessione,
        'attrezzatura': attrezzatura,
        'limitazioni': limitazioni,
      };
}

class Quiz {
  final int id;
  final int utenteId;
  final Obiettivo obiettivo;
  final Livello livello;
  final int giorniSettimana;
  final int? durataSessione;
  final String? attrezzatura;
  final String? limitazioni;
  final DateTime? createdAt;

  Quiz({
    required this.id,
    required this.utenteId,
    required this.obiettivo,
    required this.livello,
    required this.giorniSettimana,
    this.durataSessione,
    this.attrezzatura,
    this.limitazioni,
    this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        id: (j['id'] as num).toInt(),
        utenteId: (j['utente_id'] as num?)?.toInt() ?? 0,
        obiettivo: ObiettivoX.fromString(j['obiettivo']?.toString()),
        livello: LivelloX.fromString(j['livello']?.toString()),
        giorniSettimana: (j['giorni_settimana'] as num?)?.toInt() ?? 0,
        durataSessione: (j['durata_sessione'] as num?)?.toInt(),
        attrezzatura: j['attrezzatura']?.toString(),
        limitazioni: j['limitazioni']?.toString(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );
}
