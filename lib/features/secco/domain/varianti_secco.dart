import '../../allenamenti/domain/destinatari.dart';
import 'esercizio_secco.dart';

// Le varianti degli esercizi di una seduta a secco (proposta 12 del
// «Piano di WaterTactics»): un atleta con la spalla dolorante fa un altro
// esercizio, o lo stesso più leggero, o non lo fa. Il programma di tutti
// non cambia.

/// Gli esercizi di tutti, in ordine (senza le varianti).
List<EsercizioSeduta> righePrincipali(Iterable<EsercizioSeduta> righe) => [
  for (final r in righe)
    if (!r.variante) r,
]..sort((a, b) => a.ordine.compareTo(b.ordine));

/// Le varianti di [riga], nell'ordine in cui sono state messe (per id
/// della riga a parità di ordine: stabile).
List<EsercizioSeduta> variantiDi(
  EsercizioSeduta riga,
  Iterable<EsercizioSeduta> righe,
) => [
  for (final r in righe)
    if (r.varianteDi == riga.id) r,
];

/// Cosa fa [atletaId] al posto di [riga] (un esercizio di tutti): la sua
/// variante, se ne ha una; se no, se ne è escluso, niente; se no l'esercizio.
/// Null: non lo fa.
EsercizioSeduta? cosaFa(
  EsercizioSeduta riga,
  String atletaId,
  Iterable<EsercizioSeduta> righe,
) {
  for (final v in variantiDi(riga, righe)) {
    if (v.destinatari.soloAtleti.contains(atletaId)) return v;
  }
  if (riga.destinatari.tranneAtleti.contains(atletaId)) return null;
  return riga;
}

/// Gli esercizi che fa [atletaId], in ordine: al posto di ogni esercizio
/// di tutti la sua variante, se ne ha una; niente se ne è escluso. Una
/// variante di un esercizio non più nella seduta non conta. La stessa
/// regola nel database (`esercizi_seduta_atleta`).
List<EsercizioSeduta> eserciziDellAtleta(
  Iterable<EsercizioSeduta> righe,
  String atletaId,
) => [for (final r in righePrincipali(righe)) ?cosaFa(r, atletaId, righe)];

/// Gli atleti che non fanno [riga] come tutti: chi ha una variante e chi
/// ne è escluso.
Set<String> atletiFuoriDa(
  EsercizioSeduta riga,
  Iterable<EsercizioSeduta> righe,
) => {
  ...riga.destinatari.tranneAtleti,
  for (final v in variantiDi(riga, righe)) ...v.destinatari.soloAtleti,
};

/// Gli atleti che in questa seduta hanno almeno una variante o un
/// esercizio che non fanno.
Set<String> atletiConVarianti(Iterable<EsercizioSeduta> righe) => {
  for (final r in righePrincipali(righe)) ...atletiFuoriDa(r, righe),
};

/// La variante di [riga] per [atletaId]: un altro esercizio, o lo stesso
/// con un'altra prescrizione. Sta al posto di [riga] (stesso ordine).
EsercizioSeduta nuovaVariante({
  required EsercizioSeduta riga,
  required String atletaId,
  required String esercizioId,
  required int serie,
  required int? ripetizioni,
  required int? durataS,
  required String? carico,
  required int? recuperoS,
  String? note,
}) => EsercizioSeduta(
  id: '',
  allenamentoId: riga.allenamentoId,
  clubId: riga.clubId,
  esercizioId: esercizioId,
  ordine: riga.ordine,
  serie: serie,
  ripetizioni: durataS == null ? ripetizioni : null,
  durataS: durataS,
  carico: carico,
  recuperoS: recuperoS,
  note: note,
  varianteDi: riga.id,
  destinatari: Destinatari.solo([atletaId]),
);

/// [riga] (un esercizio di tutti) con [atletaId] fra chi non lo fa.
EsercizioSeduta conEscluso(EsercizioSeduta riga, String atletaId) =>
    riga.destinatari.tranneAtleti.contains(atletaId)
    ? riga
    : riga.copyWith(
        destinatari: Destinatari(
          tranneAtleti: [...riga.destinatari.tranneAtleti, atletaId],
        ),
      );

/// [riga] (un esercizio di tutti) con [atletaId] di nuovo fra chi lo fa.
EsercizioSeduta senzaEscluso(EsercizioSeduta riga, String atletaId) =>
    riga.copyWith(
      destinatari: Destinatari(
        tranneAtleti: [
          for (final id in riga.destinatari.tranneAtleti)
            if (id != atletaId) id,
        ],
      ),
    );
