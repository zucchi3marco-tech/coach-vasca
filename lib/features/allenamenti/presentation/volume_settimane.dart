import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../stagioni/domain/stagione.dart';
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
    this.faseDi,
    this.partiteDi,
    this.etichettaPartite = 'Settimana con partita',
    this.oggi,
    super.key,
  });

  static const settimanePassate = 5;
  static const settimaneFuture = 2;

  final List<Allenamento> allenamenti;
  final Map<String, VolumeAllenamento> volumi;

  /// Con il lunedì della settimana scelta.
  final ValueChanged<DateTime> onApriSettimana;

  /// La fase della stagione della settimana del lunedì dato, se c'è: il
  /// suo obiettivo di metri si disegna come linea sulla colonna.
  final FaseStagione? Function(DateTime lunedi)? faseDi;

  /// Le partite della settimana del lunedì dato, già descritte ("sab 11
  /// ott con Brescia"): le settimane con partita hanno un segno sotto la
  /// data.
  final List<String> Function(DateTime lunedi)? partiteDi;

  /// La voce della legenda per il segno delle partite ("Settimana con
  /// gara" nel nuoto).
  final String etichettaPartite;

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
    int? obiettivo(DateTime lunedi) =>
        widget.faseDi?.call(lunedi)?.obiettivoMetri;
    bool conPartita(DateTime lunedi) =>
        widget.partiteDi?.call(lunedi).isNotEmpty ?? false;
    final massimo = [
      ...settimane.map(metri),
      ...settimane.map((l) => obiettivo(l) ?? 0),
    ].fold(0, math.max);
    final legendaObiettivo = settimane.any((l) => obiettivo(l) != null);
    final legendaPartite = settimane.any(conPartita);

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
        if (legendaObiettivo || legendaPartite)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Wrap(
              spacing: AppSpacing.s16,
              runSpacing: AppSpacing.s4,
              children: [
                if (legendaObiettivo)
                  _VoceLegenda(
                    segno: Container(width: 16, height: 2, color: colori.testo),
                    testo: 'Obiettivo della fase',
                  ),
                if (legendaPartite)
                  _VoceLegenda(
                    segno: _SegnoPartita(colore: context.dominio.evidenzaAmbra),
                    testo: widget.etichettaPartite,
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: 158,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final lunedi in settimane)
                Expanded(
                  child: _Colonna(
                    metri: metri(lunedi),
                    obiettivo: obiettivo(lunedi),
                    conPartita: conPartita(lunedi),
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
        if (widget.faseDi?.call(_scelta) case final fase?)
          Text(
            [
              'Fase ${fase.nome}',
              if (fase.obiettivoMetri case final obiettivo?) ...[
                'obiettivo ${_km(obiettivo)} km',
                if (obiettivo > 0)
                  '${(metri / obiettivo * 100).round()}% fatto',
              ],
            ].join(' · '),
            style: secondario,
          ),
        for (final partita
            in widget.partiteDi?.call(_scelta) ?? const <String>[])
          Text(partita, style: secondario),
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

  /// 18000 -> "18", 18500 -> "18,5".
  String _km(int metri) => metri % 1000 == 0
      ? '${metri ~/ 1000}'
      : (metri / 1000).toStringAsFixed(1).replaceAll('.', ',');

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
    required this.obiettivo,
    required this.conPartita,
    required this.massimo,
    required this.scelta,
    required this.inProgramma,
    required this.etichettaData,
    required this.descrizione,
    required this.onTap,
  });

  final int metri;

  /// I metri dell'obiettivo della fase: una linea sulla colonna.
  final int? obiettivo;
  final bool conPartita;
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
              child: LayoutBuilder(
                builder: (context, vincoli) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
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
            SizedBox(
              height: 10,
              child: conPartita
                  ? Center(
                      child: _SegnoPartita(
                        colore: context.dominio.evidenzaAmbra,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Il segno delle settimane con partita: un punto nel colore delle
/// partite.
class _SegnoPartita extends StatelessWidget {
  const _SegnoPartita({required this.colore});

  final Color colore;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
  );
}

class _VoceLegenda extends StatelessWidget {
  const _VoceLegenda({required this.segno, required this.testo});

  final Widget segno;
  final String testo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      segno,
      const SizedBox(width: 6),
      Text(
        testo,
        style: AppTypography.etichetta.copyWith(
          color: context.colori.testoSecondario,
        ),
      ),
    ],
  );
}
