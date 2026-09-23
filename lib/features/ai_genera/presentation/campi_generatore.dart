import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/tipo_lavoro.dart';

/// Contenitore di un blocco di campi che dipendono da una scelta fatta
/// sopra (es. il dettaglio di "Gambe"): pannello `superficie` con bordo
/// `linea` e raggio 12 — DESIGN.md sezione 11.
class PannelloCampi extends StatelessWidget {
  const PannelloCampi({required this.titolo, required this.figli, super.key});

  final String titolo;
  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo,
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          for (final f in figli) ...[const SizedBox(height: AppSpacing.s12), f],
        ],
      ),
    );
  }
}

/// Etichetta sopra un campo, nello stile `etichetta` del design system.
class EtichettaCampo extends StatelessWidget {
  const EtichettaCampo(this.testo, {this.azione, super.key});

  final String testo;
  final Widget? azione;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            testo,
            style: AppTypography.etichetta.copyWith(
              color: context.colori.testoSecondario,
            ),
          ),
        ),
        ?azione,
      ],
    );
  }
}

/// Slider con, a destra, il valore in un riquadro: si legge il numero
/// esatto senza dover trascinare il cursore per vederlo.
class SliderConValore extends StatelessWidget {
  const SliderConValore({
    required this.etichetta,
    required this.valore,
    required this.min,
    required this.max,
    required this.divisioni,
    required this.onChanged,
    this.testoValore,
    this.azione,
    super.key,
  });

  final String etichetta;
  final double valore;
  final double min;
  final double max;
  final int divisioni;
  final ValueChanged<double> onChanged;

  /// Testo nel riquadro se diverso dal numero (es. "Auto").
  final String? testoValore;

  /// Widget a destra dell'etichetta (di solito un `PulsanteSpiegazione`).
  final Widget? azione;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtichettaCampo(etichetta, azione: azione),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: valore.clamp(min, max),
                min: min,
                max: max,
                divisions: divisioni,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Container(
              width: 76,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colori.superficie,
                borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
                border: Border.all(color: colori.lineaForte),
              ),
              child: Text(
                testoValore ?? '${valore.round()}',
                style: AppTypography.numerica(AppTypography.corpoForte)
                    .copyWith(color: colori.testo),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Riga di chip a scelta singola o multipla, con l'etichetta sopra.
class GruppoChip extends StatelessWidget {
  const GruppoChip({required this.etichetta, required this.chip, super.key});

  final String etichetta;
  final List<Widget> chip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtichettaCampo(etichetta),
        const SizedBox(height: AppSpacing.s8),
        Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: chip),
      ],
    );
  }
}

/// Un tipo di lavoro come riquadro selezionabile (due per riga) con il
/// punto del colore della zona e il pulsante info: intensità, cuore, a
/// cosa serve — vedi `tipo_lavoro.dart`.
class TileTipoLavoro extends StatelessWidget {
  const TileTipoLavoro({
    required this.zona,
    required this.selezionato,
    required this.onSelezionato,
    required this.mostraCodici,
    super.key,
  });

  final String zona;
  final bool selezionato;
  final ValueChanged<bool> onSelezionato;
  final bool mostraCodici;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tipo = tipiLavoro[zona];
    final coloreZona = context.dominio.colorePerZona(
      zona,
      rispetto: colori.testoTenue,
    );
    return Material(
      color: selezionato ? colori.azioneTenue : colori.superficieAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        side: BorderSide(color: selezionato ? colori.azione : colori.linea),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        onTap: () => onSelezionato(!selezionato),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: coloreZona,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    etichettaTipoLavoro(zona, mostraCodici: mostraCodici),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.piccolo.copyWith(
                      fontWeight: selezionato
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: colori.testo,
                    ),
                  ),
                ),
                if (tipo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                    ),
                    child: PulsanteSpiegazione(
                      titolo: tipo.nome,
                      spiegazione: tipo.spiegazione,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// I tipi di lavoro in griglia a due colonne.
class GrigliaTipiLavoro extends StatelessWidget {
  const GrigliaTipiLavoro({
    required this.selezionati,
    required this.mostraCodici,
    required this.onCambia,
    super.key,
  });

  final Set<String> selezionati;
  final bool mostraCodici;
  final void Function(String zona, bool selezionato) onCambia;

  @override
  Widget build(BuildContext context) {
    Widget tile(String zona) => TileTipoLavoro(
      zona: zona,
      selezionato: selezionati.contains(zona),
      mostraCodici: mostraCodici,
      onSelezionato: (s) => onCambia(zona, s),
    );
    return Column(
      children: [
        for (var i = 0; i < ordineTipiLavoro.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(child: tile(ordineTipiLavoro[i])),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: i + 1 < ordineTipiLavoro.length
                    ? tile(ordineTipiLavoro[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

const stiliNuoto = ['libero', 'dorso', 'rana', 'delfino', 'misti'];

String etichettaAttrezzo(String a) => switch (a) {
  'pull' => 'Pull',
  'palette' => 'Palette',
  'boccaglio' => 'Boccaglio',
  'pinne' => 'Pinne',
  'tavola' => 'Tavola',
  _ => a.isEmpty ? a : a[0].toUpperCase() + a.substring(1),
};

String siglaStile(String s) => switch (s) {
  'libero' => 'SL',
  'dorso' => 'DO',
  'rana' => 'RA',
  'delfino' => 'FA',
  'misti' => 'MX',
  _ => s,
};

/// Pannello di dettaglio di un focus (braccia o gambe): metri dedicati,
/// attrezzi e stile. Stateless: chi lo usa tiene lo stato e passa le
/// modifiche con i callback.
class PannelloFocusDettaglio extends StatelessWidget {
  const PannelloFocusDettaglio({
    required this.titolo,
    required this.etichettaMetri,
    required this.metri,
    required this.maxMetri,
    required this.onMetri,
    required this.attrezziDisponibili,
    required this.attrezziSelezionati,
    required this.onAttrezzo,
    required this.stile,
    required this.onStile,
    super.key,
  });

  final String titolo;
  final String etichettaMetri;
  final double? metri;
  final double maxMetri;
  final ValueChanged<double> onMetri;
  final List<String> attrezziDisponibili;
  final Set<String> attrezziSelezionati;
  final void Function(String attrezzo, bool selezionato) onAttrezzo;
  final String? stile;
  final ValueChanged<String?> onStile;

  @override
  Widget build(BuildContext context) {
    return PannelloCampi(
      titolo: titolo,
      figli: [
        SliderConValore(
          etichetta: etichettaMetri,
          valore: (metri ?? 0).clamp(0, maxMetri).toDouble(),
          min: 0,
          max: maxMetri,
          divisioni: (maxMetri / 100).round().clamp(1, 999),
          testoValore: metri == null ? 'Auto' : null,
          onChanged: onMetri,
        ),
        GruppoChip(
          etichetta: 'Attrezzi',
          chip: [
            for (final a in attrezziDisponibili)
              TonalChip(
                etichetta: etichettaAttrezzo(a),
                selezionato: attrezziSelezionati.contains(a),
                onSelezionato: (s) => onAttrezzo(a, s),
              ),
          ],
        ),
        GruppoChip(
          etichetta: 'Stile (facoltativo)',
          chip: [
            for (final s in stiliNuoto)
              TonalChip(
                etichetta: siglaStile(s),
                selezionato: stile == s,
                onSelezionato: (sel) => onStile(sel ? s : null),
              ),
          ],
        ),
      ],
    );
  }
}
