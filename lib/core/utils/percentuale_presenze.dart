import '../../features/allenamenti/domain/allenamento.dart';
import '../../features/presenze/domain/presenza.dart';
import 'gruppo_visibilita.dart';

/// Gli allenamenti che contano per un atleta: quelli già passati del suo
/// gruppo (più quelli di tutto il club, stessa regola di
/// [visibileNelGruppo] già usata altrove per isolare i record per
/// gruppo), e in ogni caso quelli in cui è stato segnato (un cambio di un
/// giorno).
///
/// Contano solo gli allenamenti gia' passati (o con una presenza gia'
/// segnata): quelli programmati nelle settimane successive non sono
/// assenze, e contarli faceva crollare la percentuale a chi pianifica in
/// anticipo.
///
/// Con [atteso] contano gli allenamenti in cui l'atleta era atteso
/// (`SquadreAtleta.attesoA`: chi si allena certi giorni con un'altra
/// squadra) invece di quelli del suo gruppo. [sempre] sono gli allenamenti
/// che contano comunque (l'appello che si sta facendo ora, anche se
/// comincia fra un'ora).
List<Allenamento> allenamentiRilevanti({
  required List<Allenamento> allenamenti,
  required List<Presenza> presenze,
  required String atletaId,
  required String? gruppoAtleta,
  bool Function(Allenamento a)? atteso,
  Set<String> sempre = const {},
  DateTime? adesso,
}) {
  final ora = adesso ?? DateTime.now();
  final conPresenza = {
    for (final p in presenze)
      if (p.atletaId == atletaId) p.allenamentoId,
  };
  return allenamenti
      .where(
        (a) =>
            conPresenza.contains(a.id) ||
            sempre.contains(a.id) ||
            (a.data.isBefore(ora) &&
                (atteso?.call(a) ??
                    visibileNelGruppo(
                      gruppoDelRecord: a.gruppoId,
                      gruppoSelezionato: gruppoAtleta,
                    ))),
      )
      .toList();
}

/// Quanti allenamenti, fra [rilevanti], l'atleta c'era (presente o in
/// ritardo: [contaComePresente]).
int contaPresenti({
  required List<Allenamento> rilevanti,
  required List<Presenza> presenze,
  required String atletaId,
}) {
  final idRilevanti = rilevanti.map((a) => a.id).toSet();
  return presenze
      .where(
        (p) =>
            p.atletaId == atletaId &&
            contaComePresente(p.stato) &&
            idRilevanti.contains(p.allenamentoId),
      )
      .length;
}

/// Percentuale di presenze di un atleta sugli allenamenti del suo gruppo
/// (vedi [allenamentiRilevanti]). `null` = nessun allenamento rilevante su
/// cui calcolarla (non 0%, che vorrebbe dire "sempre assente"). Chi è in
/// ritardo conta come presente.
double? percentualePresenze({
  required List<Allenamento> allenamenti,
  required List<Presenza> presenze,
  required String atletaId,
  required String? gruppoAtleta,
  bool Function(Allenamento a)? atteso,
  DateTime? adesso,
}) {
  final rilevanti = allenamentiRilevanti(
    allenamenti: allenamenti,
    presenze: presenze,
    atletaId: atletaId,
    gruppoAtleta: gruppoAtleta,
    atteso: atteso,
    adesso: adesso,
  );
  if (rilevanti.isEmpty) return null;
  return contaPresenti(
        rilevanti: rilevanti,
        presenze: presenze,
        atletaId: atletaId,
      ) /
      rilevanti.length *
      100;
}

/// «3 su 4»: quante volte c'era (presente o in ritardo) sugli allenamenti
/// che contavano.
typedef ConteggioPresenze = ({int presenti, int su});

/// Lunedì della settimana di [giorno] (la settimana va da lunedì a
/// domenica), a mezzanotte.
DateTime lunediDellaSettimana(DateTime giorno) =>
    DateTime(giorno.year, giorno.month, giorno.day - (giorno.weekday - 1));

/// Le presenze dell'atleta nella settimana (lunedì-domenica) e nel mese
/// (di calendario) di [giorno], con la regola di [allenamentiRilevanti].
/// `su == 0` = in quel periodo nessun allenamento lo riguardava.
({ConteggioPresenze settimana, ConteggioPresenze mese}) presenzeSettimanaEMese({
  required List<Allenamento> allenamenti,
  required List<Presenza> presenze,
  required String atletaId,
  required String? gruppoAtleta,
  required DateTime giorno,
  bool Function(Allenamento a)? atteso,
  Set<String> sempre = const {},
  DateTime? adesso,
}) {
  final rilevanti = allenamentiRilevanti(
    allenamenti: allenamenti,
    presenze: presenze,
    atletaId: atletaId,
    gruppoAtleta: gruppoAtleta,
    atteso: atteso,
    sempre: sempre,
    adesso: adesso,
  );
  final lunedi = lunediDellaSettimana(giorno);
  final lunediDopo = DateTime(lunedi.year, lunedi.month, lunedi.day + 7);
  final inizioMese = DateTime(giorno.year, giorno.month);
  final inizioMeseDopo = DateTime(giorno.year, giorno.month + 1);

  ConteggioPresenze conta(DateTime dal, DateTime al) {
    final periodo = [
      for (final a in rilevanti)
        if (!a.data.isBefore(dal) && a.data.isBefore(al)) a,
    ];
    return (
      presenti: contaPresenti(
        rilevanti: periodo,
        presenze: presenze,
        atletaId: atletaId,
      ),
      su: periodo.length,
    );
  }

  return (
    settimana: conta(lunedi, lunediDopo),
    mese: conta(inizioMese, inizioMeseDopo),
  );
}
