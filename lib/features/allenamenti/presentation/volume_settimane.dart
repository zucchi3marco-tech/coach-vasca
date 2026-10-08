import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/allenamento.dart';
import '../domain/volume_allenamento.dart';
import 'riepilogo_volumi.dart';

/// Il volume delle settimane, sempre sott'occhio in cima all'elenco degli
/// allenamenti (richiesta del coach 2026-10-08): una colonna per
/// settimana — le [settimanePassate] prima, questa e le
/// [settimaneFuture] in programma — con i km scritti sopra. Un tocco su
/// una colonna mostra sotto quella settimana: metri, lavoro a tempo,
/// allenamenti e differenza con la settimana prima, più "Apri la
/// settimana".
///
/// Colore (DESIGN.md sezione 6, l'occhio va su una cosa sola): la
/// settimana scelta in `azione`, quelle già cominciate in `testoTenue`,
/// quelle in programma in `lineaForte`, più chiare perché ancora da fare.
/// I numeri restano nei colori del testo: il colore non porta mai da solo
/// il dato.
class VolumeSettimane extends StatefulWidget {
  const VolumeSettimane({
    required this.allenamenti,
    required this.volumi,
    required this.onApriSettimana,
    this.oggi,
    super.key,
  });

  static const settimanePassate = 5;
  static const settimaneFuture = 2;

  final List<Allenamento> allenamenti;
  final Map<String, VolumeAllenamento> volumi;

  /// Con il lunedì della settimana scelta.
  final ValueChanged<DateTime> onApriSettimana;

  /// Solo per i test; altrimenti adesso.
  final DateTime? oggi;

  @override
  State<VolumeSettimane> createState() => _VolumeSettimaneState();
}

class _VolumeSettimaneState extends State<VolumeSettimane> {
  late final DateTime _questa = lunediDi(widget.oggi ?? DateTime.now());
  late DateTime _scelta = _questa;

  /// Di quante settimane è spostata la finestra rispetto a oggi.
  int _spostamento = 0;

  /// Le frecce spostano di quattro settimane: la scelta si sposta con la
  /// finestra e resta nella stessa colonna.
  void _sposta(int settimane) => setState(() {
    _spostamento += settimane;
    _scelta = aggiungiGiorni(_scelta, 7 * settimane);
  });

  String _giornoMese(DateTime d) => '${d.day} ${mesiBrevi[d.month - 1]}';

  String _nomeSettimana(DateTime lunedi) {
    final distanza = giorniTra(_questa, lunedi) ~/ 7;
    return switch (distanza) {
      0 => 'Questa settimana',
      -1 => 'Settimana scorsa',
      1 => 'Settimana prossima',
      _ => 'Settimana dal ${_giornoMese(lunedi)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final perSettimana = volumiPerSettimana(widget.allenamenti, widget.volumi);
    final inizio = aggiungiGiorni(
      _questa,
      7 * (_spostamento - VolumeSettimane.settimanePassate),
    );
    final settimane = [
      for (
        var i = 0;
        i <
            VolumeSettimane.settimanePassate +
                1 +
                VolumeSettimane.settimaneFuture;
        i++
      )
        aggiungiGiorni(inizio, 7 * i),
    ];
    int metri(DateTime lunedi) => perSettimana[lunedi]?.volume.metri ?? 0;
    final massimo = settimane.map(metri).fold(0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'km dal ${_giornoMese(settimane.first)} '
                'al ${_giornoMese(aggiungiGiorni(settimane.last, 6))}',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Settimane prima',
              icon: const Icon(Icons.chevron_left),
              color: colori.testoSecondario,
              onPressed: () => _sposta(-4),
            ),
            IconButton(
              tooltip: 'Settimane dopo',
              icon: const Icon(Icons.chevron_right),
              color: colori.testoSecondario,
              onPressed: () => _sposta(4),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final lunedi in settimane)
                Expanded(
                  child: _Colonna(
                    metri: metri(lunedi),
                    massimo: massimo,
                    scelta: lunedi == _scelta,
                    inProgramma: lunedi.isAfter(_questa),
                    etichettaData: _giornoMese(lunedi),
                    descrizione:
                        '${_nomeSettimana(lunedi)}: '
                        '${_riassunto(perSettimana[lunedi])}',
                    onTap: () => setState(() => _scelta = lunedi),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _dettaglio(context, perSettimana),
      ],
    );
  }

  String _riassunto(VolumeSettimana? settimana) {
    if (settimana == null) return 'nessun allenamento';
    final n = settimana.allenamenti;
    return [
      etichettaVolume(settimana.volume) ?? '0 m',
      '$n ${n == 1 ? 'allenamento' : 'allenamenti'}',
    ].join(' · ');
  }

  Widget _dettaglio(
    BuildContext context,
    Map<DateTime, VolumeSettimana> perSettimana,
  ) {
    final colori = context.colori;
    final settimana = perSettimana[_scelta];
    final metri = settimana?.volume.metri ?? 0;
    final metriPrima =
        perSettimana[aggiungiGiorni(_scelta, -7)]?.volume.metri ?? 0;
    final confronto = metri == 0 || metriPrima == 0
        ? null
        : switch (((metri - metriPrima) / metriPrima * 100).round()) {
            0 => 'metri come la settimana prima',
            final p => '${p > 0 ? '+' : ''}$p% di metri sulla settimana prima',
          };
    final secondario = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    final n = settimana?.allenamenti ?? 0;
    // Tre righe corte, il pulsante sotto: affiancato al testo, sul telefono
    // mandava a capo a metà ("5 ott / – 11 ott").
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_nomeSettimana(_scelta)} · ${_intervallo(_scelta)}',
          style: secondario,
        ),
        const SizedBox(height: 2),
        Text(
          settimana == null
              ? 'Nessun allenamento'
              : etichettaVolume(settimana.volume) ?? '0 m',
          style: AppTypography.numerica(AppTypography.corpoForte)
              .copyWith(color: colori.testo),
        ),
        if (settimana != null)
          Text(
            [
              '$n ${n == 1 ? 'allenamento' : 'allenamenti'}',
              ?confronto,
            ].join(' · '),
            style: secondario,
          ),
        if (settimana != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => widget.onApriSettimana(_scelta),
              child: const Text('Apri la settimana'),
            ),
          ),
      ],
    );
  }

  /// "5–11 ott", o "28 set – 4 ott" a cavallo di due mesi.
  String _intervallo(DateTime lunedi) {
    final domenica = aggiungiGiorni(lunedi, 6);
    return lunedi.month == domenica.month
        ? '${lunedi.day}–${_giornoMese(domenica)}'
        : '${_giornoMese(lunedi)} – ${_giornoMese(domenica)}';
  }
}

/// Una colonna del grafico: i km sopra, la barra (alta in proporzione
/// alla settimana con più metri della finestra), la data del lunedì
/// sotto. Tutta la colonna si tocca, non solo la barra.
class _Colonna extends StatelessWidget {
  const _Colonna({
    required this.metri,
    required this.massimo,
    required this.scelta,
    required this.inProgramma,
    required this.etichettaData,
    required this.descrizione,
    required this.onTap,
  });

  final int metri;
  final int massimo;
  final bool scelta;
  final bool inProgramma;
  final String etichettaData;
  final String descrizione;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final colore = scelta
        ? colori.azione
        : inProgramma
        ? colori.lineaForte
        : colori.testoTenue;
    final testo = AppTypography.numerica(AppTypography.etichetta).copyWith(
      color: scelta ? colori.testo : colori.testoSecondario,
      fontWeight: scelta ? FontWeight.w700 : null,
    );
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
                  metri == 0 ? '' : (metri / 1000).toStringAsFixed(1),
                  maxLines: 1,
                  style: testo,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: massimo == 0
                      ? 0
                      : math.max(metri / massimo, metri == 0 ? 0 : 0.03),
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      color: colore,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
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
