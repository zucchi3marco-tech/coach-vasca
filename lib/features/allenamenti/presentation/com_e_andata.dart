import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../data/serie_repository.dart';
import '../domain/com_e_andata.dart';
import '../domain/serie.dart';
import 'serie_labels.dart';

/// Cosa ha risposto il foglio «In parte»: una [scelta], o «Togli "In
/// parte"» per rimettere la serie come se non fosse segnata.
class RispostaInParte {
  const RispostaInParte.scelta(SceltaInParte this.scelta);
  const RispostaInParte.togli() : scelta = null;

  final SceltaInParte? scelta;

  bool get togli => scelta == null;
}

/// Segna sulla serie [s] quanto risposto dal foglio: la scelta fa la serie
/// «fatta in parte» (il programma scritto non cambia: si aggiungono solo i
/// metri o i secondi fatti), «Togli» la rimette non segnata.
Future<void> applicaInParte(
  SerieRepository repository,
  Serie s,
  RispostaInParte risposta,
) {
  final scelta = risposta.scelta;
  if (scelta == null) return repository.segnaEsito(s.id, null);
  return repository.segnaFatto(
    s.id,
    esito: 'fatta',
    metriFatti: scelta.metriFatti,
    secondiFatti: scelta.secondiFatti,
  );
}

/// Il foglio «In parte»: quanto si è fatto della serie [serie], a bottoni
/// grandi in una griglia che va a capo. Con [bordoVasca] i bottoni sono
/// alti almeno 64 (mani bagnate), altrimenti 48. Se la serie è già in
/// parte la scelta fatta è evidenziata e c'è «Togli "In parte"». Torna la
/// risposta, o null se il foglio si chiude senza scegliere.
Future<RispostaInParte?> mostraSceltaInParte(
  BuildContext context,
  Serie serie, {
  bool bordoVasca = false,
}) {
  final opzioni = opzioniInParte(serie);
  // Niente da scegliere e niente da togliere: «In parte» non c'è.
  if (opzioni.vuote && !serie.inParte) return Future.value();
  return showModalBottomSheet<RispostaInParte>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => SceltaInParteFoglio(
      serie: serie,
      opzioni: opzioni,
      bordoVasca: bordoVasca,
      onRisposta: (r) => Navigator.of(sheetContext).pop(r),
    ),
  );
}

/// Il contenuto del foglio «In parte» (vedi [mostraSceltaInParte]).
class SceltaInParteFoglio extends StatelessWidget {
  const SceltaInParteFoglio({
    required this.serie,
    required this.opzioni,
    required this.onRisposta,
    this.bordoVasca = false,
    super.key,
  });

  final Serie serie;
  final OpzioniInParte opzioni;
  final bool bordoVasca;
  final ValueChanged<RispostaInParte> onRisposta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final altezza = bordoVasca
        ? AppSpacing.altezzaMinimaBersaglioVasca
        : AppSpacing.altezzaMinimaBersaglio;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titoloSerie(serie),
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              opzioni.vuote ? 'Fatta in parte' : opzioni.domanda,
              style:
                  (bordoVasca ? AppTypography.titoloXl : AppTypography.titolo)
                      .copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (!opzioni.vuote)
              Flexible(
                child: SingleChildScrollView(
                  child: _GrigliaScelte(
                    opzioni: opzioni,
                    serie: serie,
                    altezza: altezza,
                    bordoVasca: bordoVasca,
                    onScelta: (s) => onRisposta(RispostaInParte.scelta(s)),
                  ),
                ),
              ),
            if (serie.inParte) ...[
              const SizedBox(height: AppSpacing.s16),
              OutlinedButton(
                onPressed: () => onRisposta(const RispostaInParte.togli()),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(altezza),
                  foregroundColor: colori.testo,
                  side: BorderSide(color: colori.lineaForte),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.controllo),
                  ),
                  textStyle: AppTypography.corpoForte,
                ),
                child: const Text('Togli "In parte"'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// I bottoni delle scelte: quanti ne stanno in una riga dipende dalla
/// larghezza, e ognuno si allarga per riempirla.
class _GrigliaScelte extends StatelessWidget {
  const _GrigliaScelte({
    required this.opzioni,
    required this.serie,
    required this.altezza,
    required this.bordoVasca,
    required this.onScelta,
  });

  final OpzioniInParte opzioni;
  final Serie serie;
  final double altezza;
  final bool bordoVasca;
  final ValueChanged<SceltaInParte> onScelta;

  @override
  Widget build(BuildContext context) {
    const spazio = AppSpacing.spazioBersagli;
    // Il numero più lungo ("1.400") e la riga sotto ("1.400 m") decidono
    // quanto deve essere largo un bottone, al più prima del testo ingrandito.
    var lunghezza = 0;
    for (final s in opzioni.scelte) {
      lunghezza = math.max(
        lunghezza,
        math.max(s.etichetta.length, (s.unita.length * 0.6).ceil()),
      );
    }
    final larghezzaMinima =
        (bordoVasca ? 72.0 : 64.0) + (lunghezza > 3 ? 28 : 0);
    return LayoutBuilder(
      builder: (context, vincoli) {
        final disponibile = vincoli.maxWidth;
        final colonne = ((disponibile + spazio) / (larghezzaMinima + spazio))
            .floor()
            .clamp(1, 8);
        final larghezza = (disponibile - spazio * (colonne - 1)) / colonne;
        return Wrap(
          spacing: spazio,
          runSpacing: spazio,
          children: [
            for (final scelta in opzioni.scelte)
              SizedBox(
                width: larghezza,
                child: _BottoneScelta(
                  scelta: scelta,
                  scelto: scelta.eDi(serie),
                  altezza: altezza,
                  grande: bordoVasca,
                  onTap: () => onScelta(scelta),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BottoneScelta extends StatelessWidget {
  const _BottoneScelta({
    required this.scelta,
    required this.scelto,
    required this.altezza,
    required this.grande,
    required this.onTap,
  });

  final SceltaInParte scelta;
  final bool scelto;
  final double altezza;
  final bool grande;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      selected: scelto,
      label: '${scelta.etichetta} ${scelta.unita}',
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(altezza),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s8,
          ),
          backgroundColor: scelto ? colori.azioneTenue : null,
          foregroundColor: colori.testo,
          side: BorderSide(color: scelto ? colori.azione : colori.lineaForte),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.controllo),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                scelta.etichetta,
                maxLines: 1,
                style: AppTypography.numerica(
                  (grande
                          ? AppTypography.numeroGrande
                          : AppTypography.numeroMedio)
                      .copyWith(color: colori.testo),
                ),
              ),
              Text(
                scelta.unita,
                maxLines: 1,
                style: AppTypography.numerica(
                  AppTypography.etichetta.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Fatta», «In parte» o «Saltata»: un bersaglio con icona e parola,
/// evidenziato quando è l'esito segnato. [altezza] 64 a bordo vasca, 48 o
/// più nel dettaglio; [impilato] mette l'icona sopra la parola, per tre
/// bottoni in una riga su uno schermo stretto.
class BottoneEsito extends StatelessWidget {
  const BottoneEsito({
    required this.etichetta,
    required this.icona,
    required this.scelto,
    required this.onTap,
    this.altezza = AppSpacing.altezzaMinimaBersaglioVasca,
    this.impilato = false,
    super.key,
  });

  final String etichetta;
  final IconData icona;
  final bool scelto;
  final VoidCallback onTap;
  final double altezza;
  final bool impilato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final testo = Text(etichetta, maxLines: 1);
    return Semantics(
      selected: scelto,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(altezza),
          padding: EdgeInsets.symmetric(
            horizontal: impilato ? AppSpacing.s4 : AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          backgroundColor: scelto ? colori.azioneTenue : null,
          foregroundColor: colori.testo,
          side: BorderSide(color: scelto ? colori.azione : colori.lineaForte),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
          ),
          textStyle: AppTypography.corpoForte.copyWith(
            fontSize: impilato ? 16 : 18,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: impilato
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icona, size: 24),
                    const SizedBox(height: AppSpacing.s4),
                    testo,
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icona, size: 24),
                    const SizedBox(width: AppSpacing.s8),
                    testo,
                  ],
                ),
        ),
      ),
    );
  }
}

/// I bottoni di una serie, nell'ordine «Fatta», «In parte», «Saltata»:
/// chi li usa li dispone in riga o in colonna. «In parte» c'è solo se la
/// serie ha delle scelte (o è già in parte, per poterla togliere). Le
/// regole del tocco sono quelle di [esitoDopoTocco]: «Fatta» è evidenziata
/// solo per una serie fatta tutta.
List<Widget> bottoniEsito(
  Serie s, {
  required ValueChanged<String> onEsito,
  required VoidCallback onInParte,
  double altezza = AppSpacing.altezzaMinimaBersaglioVasca,
  bool impilati = false,
}) => [
  BottoneEsito(
    etichetta: 'Fatta',
    icona: s.fattaTutta ? Icons.check_circle : Icons.check_circle_outline,
    scelto: s.fattaTutta,
    altezza: altezza,
    impilato: impilati,
    onTap: () => onEsito('fatta'),
  ),
  if (ammetteInParte(s) || s.inParte)
    BottoneEsito(
      etichetta: 'In parte',
      icona: s.inParte ? Icons.timelapse : Icons.timelapse_outlined,
      scelto: s.inParte,
      altezza: altezza,
      impilato: impilati,
      onTap: onInParte,
    ),
  BottoneEsito(
    etichetta: 'Saltata',
    icona: Icons.redo,
    scelto: s.saltata,
    altezza: altezza,
    impilato: impilati,
    onTap: () => onEsito('saltata'),
  ),
];

/// I [bottoni] affiancati in una riga, della stessa larghezza e della
/// stessa altezza (la più alta: col testo grande uno può crescere più degli
/// altri). IntrinsicHeight perché una riga che si allunga in una lista
/// non ha un'altezza a cui allungarsi.
Widget rigaDiBottoni(List<Widget> bottoni) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, b) in bottoni.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.spazioBersagli),
        Expanded(child: b),
      ],
    ],
  ),
);
