import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../allenamenti/domain/volume_allenamento.dart' show lunediDi;
import '../domain/carico_rpe.dart';
import '../domain/monotonia.dart';

/// "2.150": il carico in unità arbitrarie, intero, con il punto delle
/// migliaia.
String formattaCarico(double carico) {
  final cifre = carico.round().toString();
  final gruppi = <String>[];
  for (var fine = cifre.length; fine > 0; fine -= 3) {
    gruppi.insert(0, cifre.substring(math.max(0, fine - 3), fine));
  }
  return gruppi.join('.');
}

/// I tre tipi di carico con il loro colore — DESIGN.md sezione 7,
/// "Grafici": acqua `evidenzaCiano` (come gli allenamenti), partita
/// `evidenzaAmbra` (come le partite), secco `evidenzaViola`.
List<({String etichetta, Color colore, double Function(CaricoPeriodo) valore})>
_tipi(BuildContext context) {
  final dominio = context.dominio;
  return [
    (etichetta: 'Acqua', colore: dominio.evidenzaCiano, valore: (c) => c.acqua),
    (etichetta: 'Secco', colore: dominio.evidenzaViola, valore: (c) => c.secco),
    (
      etichetta: 'Partita',
      colore: dominio.evidenzaAmbra,
      valore: (c) => c.partita,
    ),
  ];
}

/// Il carico delle ultime [settimane] settimane, una colonna per
/// settimana divisa in acqua, secco e partita, con il totale sopra. Un
/// tocco su una colonna mostra sotto i numeri di quella settimana. Il
/// colore non porta mai da solo il dato: legenda sopra e numeri scritti.
class CaricoSettimane extends StatefulWidget {
  const CaricoSettimane({
    required this.sedute,
    this.settimane = 8,
    this.obiettivoDi,
    this.oggi,
    super.key,
  });

  final List<CaricoSeduta> sedute;
  final int settimane;

  /// L'obiettivo di carico della settimana del lunedì dato (dalla fase
  /// della stagione), se c'è: una linea sulla colonna.
  final int? Function(DateTime lunedi)? obiettivoDi;

  /// Solo per i test; altrimenti adesso.
  final DateTime? oggi;

  @override
  State<CaricoSettimane> createState() => _CaricoSettimaneState();
}

class _CaricoSettimaneState extends State<CaricoSettimane> {
  /// Indice della colonna scelta: all'inizio l'ultima, questa settimana.
  late int _scelta = widget.settimane - 1;

  String _giornoMese(DateTime d) => '${d.day} ${mesiBrevi[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tipi = _tipi(context);
    final settimane = caricoPerSettimana(
      widget.sedute,
      settimane: widget.settimane,
      oggi: widget.oggi,
    );
    int? obiettivo(DateTime lunedi) => widget.obiettivoDi?.call(lunedi);
    final massimo = [
      ...settimane.map((s) => s.carico.totale),
      ...settimane.map((s) => (obiettivo(s.lunedi) ?? 0).toDouble()),
    ].fold(0.0, math.max);
    final conObiettivo = settimane.any((s) => obiettivo(s.lunedi) != null);
    // In legenda solo i tipi che ci sono nelle settimane mostrate: nel
    // nuoto, per esempio, la partita non c'è mai.
    final presenti = tipi
        .where((t) => settimane.any((s) => t.valore(s.carico) > 0))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s16,
          runSpacing: AppSpacing.s4,
          children: [
            for (final t in presenti.isEmpty ? tipi : presenti)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.colore,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.etichetta,
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            if (conObiettivo)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 2, color: colori.testo),
                  const SizedBox(width: 6),
                  Text(
                    'Obiettivo della fase',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, s) in settimane.indexed)
                Expanded(
                  child: _Colonna(
                    carico: s.carico,
                    obiettivo: obiettivo(s.lunedi),
                    massimo: massimo,
                    scelta: i == _scelta,
                    etichettaData: _giornoMese(s.lunedi),
                    descrizione:
                        'Settimana dal ${_giornoMese(s.lunedi)}: carico '
                        '${formattaCarico(s.carico.totale)}',
                    onTap: () => setState(() => _scelta = i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _dettaglio(context, settimane),
      ],
    );
  }

  Widget _dettaglio(
    BuildContext context,
    List<({DateTime lunedi, CaricoPeriodo carico})> settimane,
  ) {
    final colori = context.colori;
    final scelta = settimane[_scelta];
    final domenica = aggiungiGiorni(scelta.lunedi, 6);
    final sedute = widget.sedute
        .where(
          (s) =>
              !s.giorno.isBefore(scelta.lunedi) && !s.giorno.isAfter(domenica),
        )
        .toList();
    final stimate = sedute.where((s) => s.stimato).length;
    final secondario = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    // La monotonia di una settimana finita (quella in corso è nel
    // riquadro sotto, sugli ultimi 7 giorni).
    final monotonia =
        scelta.lunedi.isBefore(lunediDi(widget.oggi ?? DateTime.now()))
        ? monotoniaSettimana(widget.sedute, fine: domenica)
        : null;
    final nome = switch (widget.settimane - 1 - _scelta) {
      0 => 'Questa settimana',
      1 => 'Settimana scorsa',
      _ => 'Settimana dal ${_giornoMese(scelta.lunedi)}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nome, style: secondario),
        const SizedBox(height: 2),
        Text(
          sedute.isEmpty
              ? 'Nessuna seduta'
              : 'Carico ${formattaCarico(scelta.carico.totale)}',
          style: AppTypography.numerica(AppTypography.corpoForte)
              .copyWith(color: colori.testo),
        ),
        if (widget.obiettivoDi?.call(scelta.lunedi) case final obiettivo?)
          Text(
            'Obiettivo ${formattaCarico(obiettivo.toDouble())}'
            '${obiettivo > 0 ? ' · ${(scelta.carico.totale / obiettivo * 100).round()}% fatto' : ''}',
            style: secondario,
          ),
        if (sedute.isNotEmpty) ...[
          Text(
            [
              for (final t in _tipi(context))
                if (t.valore(scelta.carico) > 0)
                  '${t.etichetta.toLowerCase()} '
                      '${formattaCarico(t.valore(scelta.carico))}',
            ].join(' · '),
            style: secondario,
          ),
          Text(
            [
              '${sedute.length} ${sedute.length == 1 ? 'seduta' : 'sedute'}',
              if (stimate > 0)
                stimate == sedute.length
                    ? 'tutte senza RPE, stimate'
                    : '$stimate senza RPE, ${stimate == 1 ? 'stimata' : 'stimate'}',
            ].join(' · '),
            style: secondario,
          ),
          if (monotonia != null)
            Text(
              [
                'Monotonia ${formattaMonotonia(monotonia)}',
                if (monotonia.strain case final strain?)
                  'strain ${formattaCarico(strain)}',
                if (monotonia.alta) 'giorni troppo simili',
              ].join(' · '),
              style: secondario.copyWith(
                color: monotonia.alta ? colori.attenzione : null,
              ),
            ),
        ],
      ],
    );
  }
}

/// Una colonna: il totale sopra, i tre pezzi impilati (con 2 px di stacco
/// fra uno e l'altro), la data del lunedì sotto. Tutta la colonna si
/// tocca.
class _Colonna extends StatelessWidget {
  const _Colonna({
    required this.carico,
    required this.obiettivo,
    required this.massimo,
    required this.scelta,
    required this.etichettaData,
    required this.descrizione,
    required this.onTap,
  });

  final CaricoPeriodo carico;

  /// L'obiettivo della fase: una linea sulla colonna.
  final int? obiettivo;
  final double massimo;
  final bool scelta;
  final String etichettaData;
  final String descrizione;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final testo = AppTypography.numerica(AppTypography.etichetta).copyWith(
      color: scelta ? colori.testo : colori.testoSecondario,
      fontWeight: scelta ? FontWeight.w700 : null,
    );
    final pezzi = [
      for (final t in _tipi(context).reversed)
        if (t.valore(carico) > 0) (colore: t.colore, valore: t.valore(carico)),
    ];
    return Semantics(
      button: true,
      selected: scelta,
      label: descrizione,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  carico.totale == 0 ? '' : formattaCarico(carico.totale),
                  maxLines: 1,
                  style: testo,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, vincoli) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: massimo == 0
                          ? 0
                          : math.max(carico.totale / massimo, 0.03),
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          // La colonna scelta ha un contorno, così si vede
                          // anche senza il colore.
                          border: scelta
                              ? Border.all(color: colori.testo, width: 1.5)
                              : null,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                        padding: scelta ? const EdgeInsets.all(1.5) : null,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          // I pezzi larghi quanto la colonna: un ColoredBox
                          // senza figlio altrimenti è largo zero.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, p) in pezzi.indexed) ...[
                                if (i > 0) const SizedBox(height: 2),
                                Expanded(
                                  flex: math.max(1, (p.valore * 100).round()),
                                  child: ColoredBox(color: p.colore),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (obiettivo case final o? when massimo > 0)
                      Positioned(
                        bottom: vincoli.maxHeight * o / massimo - 1,
                        child: Container(
                          width: 34,
                          height: 2,
                          color: colori.testo,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: colori.linea),
            const SizedBox(height: AppSpacing.s4),
            SizedBox(
              height: 16,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(etichettaData, maxLines: 1, style: testo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il rapporto fra il carico degli ultimi 7 giorni e la media delle
/// ultime 4 settimane, con la fascia e i due numeri da cui viene. Fuori
/// dalla norma in `attenzione`, mai in rosso (riservato a "in corso").
class PannelloAcwr extends StatelessWidget {
  const PannelloAcwr({required this.acwr, super.key});

  final Acwr? acwr;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final a = acwr;
    final secondario = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    if (a == null || !a.affidabile) {
      return Text(
        'Servono almeno tre settimane di sedute per confrontare la '
        'settimana con il solito.',
        style: secondario,
      );
    }
    final fascia = a.fascia!;
    final coloreFascia = switch (fascia) {
      FasciaAcwr.norma => colori.ok,
      FasciaAcwr.basso => colori.testoSecondario,
      FasciaAcwr.salita || FasciaAcwr.alto => colori.attenzione,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formattaAcwr(a.rapporto!),
              style: AppTypography.numerica(
                AppTypography.numeroGrande.copyWith(color: colori.testo),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (fascia) {
                      FasciaAcwr.norma => Icons.check_circle_outline,
                      FasciaAcwr.basso => Icons.south_east,
                      _ => Icons.north_east,
                    },
                    size: 18,
                    color: coloreFascia,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fascia.etichetta,
                    style: AppTypography.corpoForte.copyWith(
                      color: coloreFascia,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        _BarraFasce(rapporto: a.rapporto!),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Ultimi 7 giorni ${formattaCarico(a.acuto)} · media delle ultime '
          '4 settimane ${formattaCarico(a.cronico)}',
          style: secondario,
        ),
      ],
    );
  }
}

/// Quanto si somigliano i giorni degli ultimi 7 (la monotonia di Foster)
/// e lo strain, con quello solito delle quattro settimane prima. Sopra 2
/// in `attenzione`, mai in rosso, come l'ACWR.
class PannelloMonotonia extends StatelessWidget {
  const PannelloMonotonia({
    required this.monotonia,
    required this.strainSolito,
    super.key,
  });

  /// Degli ultimi 7 giorni; null se non ci sono sedute.
  final Monotonia? monotonia;

  /// La media dello strain delle quattro settimane prima; null se non c'è.
  final double? strainSolito;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final secondario = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    final m = monotonia;
    if (m == null) {
      return Text(
        'Negli ultimi 7 giorni non ci sono sedute.',
        style: secondario,
      );
    }
    final colore = m.alta ? colori.attenzione : colori.ok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.s12,
          children: [
            if (m.monotonia != null)
              Text(
                formattaMonotonia(m),
                style: AppTypography.numerica(
                  AppTypography.numeroGrande.copyWith(color: colori.testo),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    m.alta ? Icons.drag_handle : Icons.check_circle_outline,
                    size: 18,
                    color: colore,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      m.tuttiUguali
                          ? 'Tutti i giorni uguali'
                          : m.alta
                          ? 'Giorni troppo simili'
                          : 'Settimana varia',
                      style: AppTypography.corpoForte.copyWith(color: colore),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          [
            if (m.strain case final strain?) 'Strain ${formattaCarico(strain)}',
            if (strainSolito case final solito?)
              'il solito ${formattaCarico(solito)}',
          ].join(' · '),
          style: AppTypography.numerica(AppTypography.corpo)
              .copyWith(color: colori.testo),
        ),
        Text(
          'Ultimi 7 giorni: carico ${formattaCarico(m.carico)}',
          style: secondario,
        ),
      ],
    );
  }
}

/// La scala da 0 a 2 con la fascia di riferimento (0,8–1,3) in evidenza
/// e un segno dove cade il rapporto.
class _BarraFasce extends StatelessWidget {
  const _BarraFasce({required this.rapporto});

  final double rapporto;

  static const _massimo = 2.0;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final etichetta = AppTypography.numerica(AppTypography.etichetta)
        .copyWith(color: colori.testoTenue);
    return LayoutBuilder(
      builder: (context, vincoli) {
        final larghezza = vincoli.maxWidth;
        double x(double v) => (v / _massimo).clamp(0.0, 1.0) * larghezza;
        return SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colori.superficieAlt,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colori.linea),
                  ),
                ),
              ),
              Positioned(
                left: x(0.8),
                width: x(1.3) - x(0.8),
                top: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colori.okTenue,
                    border: Border.all(color: colori.ok.withValues(alpha: .5)),
                  ),
                ),
              ),
              Positioned(
                left: x(rapporto) - 2,
                top: 2,
                width: 4,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colori.testo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              for (final (v, testo) in const [(0.8, '0,8'), (1.3, '1,3')])
                Positioned(
                  left: x(v) - 20,
                  width: 40,
                  top: 24,
                  child: Text(
                    testo,
                    textAlign: TextAlign.center,
                    style: etichetta,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
