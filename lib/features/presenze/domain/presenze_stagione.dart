import '../../../core/utils/gruppo_visibilita.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/domain/atleta.dart';
import 'presenza.dart';

/// Come risulta un atleta a un allenamento, nella griglia delle presenze.
enum StatoPresenza {
  presente,
  giustificato,
  assente,

  /// Allenamento suo, ma la presenza non è stata segnata: conta come
  /// assenza nella percentuale, come in [percentualePresenze].
  nonSegnato,

  /// Allenamento di un altro gruppo: non lo riguarda e non conta.
  nonSuo,
}

class RigaPresenze {
  const RigaPresenze({
    required this.atleta,
    required this.stati,
    required this.presenti,
    required this.suoi,
    required this.diFila,
  });

  final Atleta atleta;

  /// Uno per allenamento di [PresenzeStagione.allenamenti], nello stesso
  /// ordine.
  final List<StatoPresenza> stati;
  final int presenti;

  /// Gli allenamenti del periodo che lo riguardano.
  final int suoi;

  /// Presenze di fila fino all'ultimo allenamento.
  final int diFila;

  /// `null` se nel periodo non c'è nessun allenamento suo (non 0%).
  double? get percentuale => suoi == 0 ? null : presenti / suoi * 100;
}

class PresenzeStagione {
  const PresenzeStagione({
    required this.allenamenti,
    required this.righe,
    required this.presentiMedi,
  });

  /// Gli allenamenti del periodo, già fatti, dal più vecchio.
  final List<Allenamento> allenamenti;

  /// Una per atleta, dalla percentuale più alta.
  final List<RigaPresenze> righe;

  /// Quanti presenti in media agli allenamenti in cui si sono segnate le
  /// presenze; `null` se non se ne sono mai segnate.
  final double? presentiMedi;

  /// La media delle percentuali degli atleti.
  double? get media {
    final valori = righe.map((r) => r.percentuale).whereType<double>();
    if (valori.isEmpty) return null;
    return valori.reduce((a, b) => a + b) / valori.length;
  }
}

/// Le presenze degli [atleti] dal giorno [dal] a oggi, allenamento per
/// allenamento — il cruscotto "Presenze" di un gruppo (idea presa da
/// Swimtraxx Hub). Stesse regole di [percentualePresenze]: contano gli
/// allenamenti già fatti (o con una presenza già segnata) del gruppo
/// dell'atleta o di tutto il club, e uno non segnato è un'assenza.
///
/// [gruppoId] è il gruppo scelto nella pagina: restano solo gli
/// allenamenti visibili a quel gruppo (null = tutto il club).
///
/// Le presenze di fila si contano dall'ultimo allenamento all'indietro:
/// un giustificato non le interrompe (e non le allunga), e un allenamento
/// in cui nessuno ha segnato le presenze si salta.
PresenzeStagione presenzeStagione({
  required List<Allenamento> allenamenti,
  required List<Presenza> presenze,
  required List<Atleta> atleti,
  required String? gruppoId,
  required DateTime dal,
  DateTime? adesso,
}) {
  final ora = adesso ?? DateTime.now();
  final inizio = DateTime(dal.year, dal.month, dal.day);
  final statoPer = <(String, String), String>{};
  final segnati = <String>{};
  for (final p in presenze) {
    statoPer[(p.atletaId, p.allenamentoId)] = p.stato;
    segnati.add(p.allenamentoId);
  }

  final delPeriodo =
      allenamenti
          .where(
            (a) =>
                !a.data.isBefore(inizio) &&
                (a.data.isBefore(ora) || segnati.contains(a.id)) &&
                visibileNelGruppo(
                  gruppoDelRecord: a.gruppoId,
                  gruppoSelezionato: gruppoId,
                ),
          )
          .toList()
        ..sort((a, b) => a.data.compareTo(b.data));

  final righe = <RigaPresenze>[];
  for (final atleta in atleti) {
    final stati = [
      for (final a in delPeriodo)
        if (!visibileNelGruppo(
          gruppoDelRecord: a.gruppoId,
          gruppoSelezionato: atleta.gruppoId,
        ))
          StatoPresenza.nonSuo
        else
          switch (statoPer[(atleta.id, a.id)]) {
            'presente' => StatoPresenza.presente,
            'giustificato' => StatoPresenza.giustificato,
            'assente' => StatoPresenza.assente,
            _ => StatoPresenza.nonSegnato,
          },
    ];

    var diFila = 0;
    for (var i = stati.length - 1; i >= 0; i--) {
      final stato = stati[i];
      if (stato == StatoPresenza.nonSuo ||
          stato == StatoPresenza.giustificato ||
          (stato == StatoPresenza.nonSegnato &&
              !segnati.contains(delPeriodo[i].id))) {
        continue;
      }
      if (stato != StatoPresenza.presente) break;
      diFila++;
    }

    righe.add(
      RigaPresenze(
        atleta: atleta,
        stati: stati,
        presenti: stati.where((s) => s == StatoPresenza.presente).length,
        suoi: stati.where((s) => s != StatoPresenza.nonSuo).length,
        diFila: diFila,
      ),
    );
  }
  righe.sort((a, b) {
    final perPercentuale = (b.percentuale ?? -1).compareTo(a.percentuale ?? -1);
    if (perPercentuale != 0) return perPercentuale;
    return a.atleta.cognome.toLowerCase().compareTo(
      b.atleta.cognome.toLowerCase(),
    );
  });

  final conPresenze = {
    for (final a in delPeriodo)
      if (segnati.contains(a.id)) a.id,
  };
  final atletiIds = {for (final a in atleti) a.id};
  final presentiTotali = presenze
      .where(
        (p) =>
            p.stato == 'presente' &&
            atletiIds.contains(p.atletaId) &&
            conPresenze.contains(p.allenamentoId),
      )
      .length;

  return PresenzeStagione(
    allenamenti: delPeriodo,
    righe: righe,
    presentiMedi: conPresenze.isEmpty
        ? null
        : presentiTotali / conPresenze.length,
  );
}
