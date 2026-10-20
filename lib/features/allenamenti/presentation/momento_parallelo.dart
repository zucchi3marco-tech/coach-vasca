import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/com_e_andata.dart';
import '../domain/durata_serie.dart';
import '../domain/riordino_serie.dart';
import '../domain/serie.dart';
import 'per_chi_serie.dart';
import 'riga_serie.dart' show AzioneSerie;
import 'serie_labels.dart';

/// Una colonna di un momento in parallelo con quanto dura.
typedef ColonnaConTempo<T extends DatiSerie> = ({
  ColonnaMomento<T> colonna,
  int minuti,

  /// Quanti minuti prima finisce rispetto alla colonna più lunga (0 per
  /// la più lunga, o se la differenza è meno di mezzo minuto).
  int primaDegliAltri,
});

/// Le colonne del momento fatto dalle [serie], con i minuti stimati di
/// ognuna (con il passo del gruppo, [riferimento]) e quanto finisce prima
/// della più lunga.
List<ColonnaConTempo<T>> colonneConTempo<T extends DatiSerie>(
  List<T> serie, {
  PassoRiferimento? riferimento,
}) {
  final colonne = colonneMomento(serie);
  final secondi = [
    for (final c in colonne) secondiStimati(c.serie, riferimento: riferimento),
  ];
  final massimo = secondi.fold(0.0, (a, b) => b > a ? b : a);
  return [
    for (final (i, c) in colonne.indexed)
      (
        colonna: c,
        minuti: (secondi[i] / 60).round(),
        primaDegliAltri: ((massimo - secondi[i]) / 60).round(),
      ),
  ];
}

/// "Portieri: 2' in meno degli altri", per ogni colonna che finisce
/// prima della più lunga; null se finiscono insieme.
String? avvisoMomento<T extends DatiSerie>(
  List<ColonnaConTempo<T>> colonne,
  String Function(Destinatari d) nome,
) {
  final prima = [
    for (final c in colonne)
      if (c.primaDegliAltri > 0)
        "${nome(c.colonna.destinatari)}: ${c.primaDegliAltri}' in meno",
  ];
  if (prima.isEmpty) return null;
  return '${prima.join(' · ')} degli altri';
}

/// Le colonne di un momento in parallelo, affiancate (richiesta del coach
/// 2026-10-15): in testa per chi è ("Tutti", "Portieri", "Centroboa") e
/// i minuti, sotto le serie; in fondo, in `attenzione`, quanto prima
/// finisce chi ha meno lavoro. Su schermo stretto le colonne restano
/// della loro larghezza e scorrono di lato.
class ColonneMomento<T extends DatiSerie> extends StatelessWidget {
  const ColonneMomento({
    required this.serie,
    required this.nome,
    this.riferimento,
    this.onApri,
    this.grande = false,
    super.key,
  });

  final List<T> serie;

  /// "Tutti", "Portieri", "Rossi, Bianchi".
  final String Function(Destinatari d) nome;
  final PassoRiferimento? riferimento;

  /// Il tocco su una serie (la prima di un gruppo): la modifica.
  final void Function(T serie)? onApri;

  /// A bordo vasca: si legge da mezzo metro.
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colonne = colonneConTempo(serie, riferimento: riferimento);
    final larghezzaMinima = grande ? 220.0 : 150.0;
    return LayoutBuilder(
      builder: (context, vincoli) {
        final n = colonne.length;
        final spazio = AppSpacing.s8 * (n - 1);
        final affiancate = vincoli.maxWidth >= n * larghezzaMinima + spazio;
        Widget colonna(ColonnaConTempo<T> c) => _Colonna<T>(
          colonna: c,
          nome: nome(c.colonna.destinatari),
          onApri: onApri,
          grande: grande,
        );
        if (affiancate) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in colonne.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                Expanded(child: colonna(c)),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in colonne.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                SizedBox(width: larghezzaMinima, child: colonna(c)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Colonna<T extends DatiSerie> extends StatelessWidget {
  const _Colonna({
    required this.colonna,
    required this.nome,
    required this.onApri,
    required this.grande,
  });

  final ColonnaConTempo<T> colonna;
  final String nome;
  final void Function(T serie)? onApri;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final titoloStile = (grande ? AppTypography.sezione : AppTypography.corpo)
        .copyWith(color: colori.testo);
    final dettaglioStile =
        (grande ? AppTypography.corpo : AppTypography.piccolo).copyWith(
          color: colori.testoSecondario,
        );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s8),
      decoration: BoxDecoration(
        color: colori.superficieAlt,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: EtichettaPerChi(nome, grande: grande)),
              const SizedBox(width: AppSpacing.s4),
              Text(
                "${colonna.minuti}'",
                style: AppTypography.numerica(
                  grande ? AppTypography.corpoForte : AppTypography.etichetta,
                ).copyWith(color: colori.testo, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          for (final gruppo in raggruppaPerPiramide(colonna.colonna.serie))
            InkWell(
              onTap: onApri == null ? null : () => onApri!(gruppo.first),
              borderRadius: BorderRadius.circular(AppRadius.controllo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gruppo.length == 1
                          ? titoloSerie(gruppo.single)
                          : titoloGruppo(gruppo),
                      style: titoloStile.copyWith(
                        decoration: gruppo.every((s) => _saltata(s))
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (dettagliSerie(gruppo.first) case final d
                        when d.isNotEmpty)
                      Text(d.join(' · '), style: dettaglioStile),
                    if (_fattaInParte(gruppo) case final fatto?)
                      Text(
                        fatto,
                        style: dettaglioStile.copyWith(
                          color: colori.testo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (gruppo.first.note?.trim() case final nota?
                        when nota.isNotEmpty)
                      Text(
                        nota,
                        style: dettaglioStile.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (colonna.primaDegliAltri > 0)
            Text(
              "${colonna.primaDegliAltri}' in meno",
              style: dettaglioStile.copyWith(
                color: colori.attenzione,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  static bool _saltata(DatiSerie s) => s is Serie && s.saltata;

  /// «in parte · 6 di 10» per una serie fatta in parte e, per un gruppo
  /// con qualche serie in parte, com'è andato ([riassuntoEsiti]); null se
  /// niente è fatto in parte.
  static String? _fattaInParte(List<DatiSerie> gruppo) {
    final salvate = [
      for (final s in gruppo)
        if (s is Serie) s,
    ];
    if (salvate.length != gruppo.length || !salvate.any((s) => s.inParte)) {
      return null;
    }
    return salvate.length == 1
        ? descriviFatto(salvate.single).toLowerCase()
        : riassuntoEsiti(salvate);
  }
}

/// L'intestazione di un momento: "In parallelo · 20'" (la colonna più
/// lunga).
class TestaMomento extends StatelessWidget {
  const TestaMomento({required this.minuti, this.grande = false, super.key});

  final int minuti;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(
          Icons.view_column_outlined,
          size: grande ? 22 : 18,
          color: colori.testoSecondario,
        ),
        const SizedBox(width: AppSpacing.s4),
        // Su un telefono stretto o con il testo grande si accorcia, invece
        // di uscire dalla riga.
        Flexible(
          child: Text(
            "In parallelo · $minuti'",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (grande ? AppTypography.corpoForte : AppTypography.etichetta)
                .copyWith(color: colori.testo, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Un momento in parallelo nell'elenco del dettaglio allenamento: un
/// elemento solo, che si sposta, si duplica e si elimina tutto insieme,
/// con le colonne affiancate. Il tocco su una serie la apre.
class RigaMomento extends StatelessWidget {
  const RigaMomento({
    required this.gruppo,
    required this.maniglia,
    required this.primo,
    required this.ultimo,
    required this.nome,
    required this.onApri,
    required this.onAzione,
    this.riferimento,
    super.key,
  });

  final List<Serie> gruppo;
  final Widget maniglia;
  final bool primo;
  final bool ultimo;
  final String Function(Destinatari d) nome;
  final void Function(Serie serie) onApri;
  final ValueChanged<AzioneSerie> onAzione;
  final PassoRiferimento? riferimento;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final colonne = colonneConTempo(gruppo, riferimento: riferimento);
    final minuti = colonne.fold(0, (a, c) => c.minuti > a ? c.minuti : a);
    return Container(
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, height: 56, child: Center(child: maniglia)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: TestaMomento(minuti: minuti)),
                      Text(
                        '  ·  ${labelBloccoBreve(gruppo.first.blocco)}',
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  ColonneMomento<Serie>(
                    serie: gruppo,
                    nome: nome,
                    riferimento: riferimento,
                    onApri: onApri,
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<AzioneSerie>(
            tooltip: 'Azioni sul lavoro in parallelo',
            icon: const Icon(Icons.more_vert),
            onSelected: onAzione,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AzioneSerie.su,
                enabled: !primo,
                child: const _Voce(Icons.arrow_upward, 'Sposta su'),
              ),
              PopupMenuItem(
                value: AzioneSerie.giu,
                enabled: !ultimo,
                child: const _Voce(Icons.arrow_downward, 'Sposta giù'),
              ),
              const PopupMenuItem(
                value: AzioneSerie.cambiaBlocco,
                child: _Voce(Icons.swap_vert, 'Cambia blocco'),
              ),
              const PopupMenuItem(
                value: AzioneSerie.duplica,
                child: _Voce(Icons.copy_outlined, 'Duplica'),
              ),
              PopupMenuItem(
                value: AzioneSerie.elimina,
                child: _Voce(
                  Icons.delete_outline,
                  'Elimina',
                  colore: colori.rosso,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Voce extends StatelessWidget {
  const _Voce(this.icona, this.etichetta, {this.colore});

  final IconData icona;
  final String etichetta;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(icona, size: 20, color: colore ?? colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(
          etichetta,
          style: AppTypography.corpo.copyWith(color: colore ?? colori.testo),
        ),
      ],
    );
  }
}
