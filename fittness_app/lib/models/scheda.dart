class Esercizio {
  final String nome;
  final int serie;
  final String ripetizioni;
  final int recuperoSec;
  final String note;

  Esercizio({
    required this.nome,
    required this.serie,
    required this.ripetizioni,
    required this.recuperoSec,
    required this.note,
  });

  factory Esercizio.fromJson(Map<String, dynamic> j) => Esercizio(
        nome: j['nome']?.toString() ?? '',
        serie: (j['serie'] as num?)?.toInt() ?? 0,
        ripetizioni: j['ripetizioni']?.toString() ?? '',
        recuperoSec: (j['recupero_sec'] as num?)?.toInt() ?? 0,
        note: j['note']?.toString() ?? '',
      );
}

class Giorno {
  final String giorno;
  final String focus;
  final List<Esercizio> esercizi;

  Giorno({required this.giorno, required this.focus, required this.esercizi});

  factory Giorno.fromJson(Map<String, dynamic> j) => Giorno(
        giorno: j['giorno']?.toString() ?? '',
        focus: j['focus']?.toString() ?? '',
        esercizi: (j['esercizi'] as List? ?? [])
            .map((e) => Esercizio.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class SchedaContenuto {
  final String titolo;
  final String descrizione;
  final int? settimaneConsigliate;
  final List<Giorno> giorni;

  SchedaContenuto({
    required this.titolo,
    required this.descrizione,
    this.settimaneConsigliate,
    required this.giorni,
  });

  factory SchedaContenuto.fromJson(Map<String, dynamic> j) => SchedaContenuto(
        titolo: j['titolo']?.toString() ?? '',
        descrizione: j['descrizione']?.toString() ?? '',
        settimaneConsigliate: (j['settimane_consigliate'] as num?)?.toInt(),
        giorni: (j['giorni'] as List? ?? [])
            .map((e) => Giorno.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class SchedaListItem {
  final int id;
  final int utenteId;
  final int? quizId;
  final String titolo;
  final String? modelloAi;
  final DateTime? createdAt;

  SchedaListItem({
    required this.id,
    required this.utenteId,
    this.quizId,
    required this.titolo,
    this.modelloAi,
    this.createdAt,
  });

  factory SchedaListItem.fromJson(Map<String, dynamic> j) => SchedaListItem(
        id: (j['id'] as num).toInt(),
        utenteId: (j['utente_id'] as num?)?.toInt() ?? 0,
        quizId: (j['quiz_id'] as num?)?.toInt(),
        titolo: j['titolo']?.toString() ?? 'Scheda',
        modelloAi: j['modello_ai']?.toString(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );
}

class Scheda {
  final int id;
  final int utenteId;
  final int? quizId;
  final String titolo;
  final SchedaContenuto contenuto;
  final String? modelloAi;
  final DateTime? createdAt;

  Scheda({
    required this.id,
    required this.utenteId,
    this.quizId,
    required this.titolo,
    required this.contenuto,
    this.modelloAi,
    this.createdAt,
  });

  factory Scheda.fromJson(Map<String, dynamic> j) {
    final rawContent = j['contenuto'];
    final contentMap = rawContent is Map
        ? Map<String, dynamic>.from(rawContent)
        : <String, dynamic>{};
    return Scheda(
      id: (j['id'] as num).toInt(),
      utenteId: (j['utente_id'] as num?)?.toInt() ?? 0,
      quizId: (j['quiz_id'] as num?)?.toInt(),
      titolo: j['titolo']?.toString() ?? contentMap['titolo']?.toString() ?? 'Scheda',
      contenuto: SchedaContenuto.fromJson(contentMap),
      modelloAi: j['modello_ai']?.toString(),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }
}
