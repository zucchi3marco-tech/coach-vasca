import '../../../../core/utils/giorni.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_messages.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/colori_app.dart';
import '../../../../widgets/app_list_panel.dart';
import '../../../../widgets/app_list_row.dart';
import '../../application/allenamenti_providers.dart';
import '../../data/duplicazione_settimana_service.dart';
import '../../domain/allenamento.dart';
import '../../domain/volume_allenamento.dart';
import '../riepilogo_volumi.dart';
import 'allenamenti_per_giorno.dart';

class CalendarioSettimanaleView extends ConsumerStatefulWidget {
  const CalendarioSettimanaleView({
    required this.clubId,
    required this.allenamenti,
    required this.onGiornoSelezionato,
    this.settimanaIniziale,
    super.key,
  });

  /// Un giorno della settimana da mostrare all'inizio (dal grafico dei
  /// volumi settimanali); null = questa settimana.
  final DateTime? settimanaIniziale;

  final String clubId;
  final List<Allenamento> allenamenti;
  final ValueChanged<DateTime> onGiornoSelezionato;

  @override
  ConsumerState<CalendarioSettimanaleView> createState() =>
      _CalendarioSettimanaleViewState();
}

class _CalendarioSettimanaleViewState
    extends ConsumerState<CalendarioSettimanaleView> {
  late DateTime _inizioSettimana;

  static const _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  @override
  void initState() {
    super.initState();
    _inizioSettimana = lunediDi(widget.settimanaIniziale ?? DateTime.now());
  }

  String _formattaData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _duplicaSettimana(int numeroAllenamenti) async {
    final colori = context.colori;
    final fineSettimana = aggiungiGiorni(_inizioSettimana, 6);
    var nuovaDataInizio = aggiungiGiorni(_inizioSettimana, 7);

    final confermata = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Duplicare questa settimana?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$numeroAllenamenti allenamenti dal '
                '${_formattaData(_inizioSettimana)} al '
                '${_formattaData(fineSettimana)} (con le stesse serie) '
                'verso la settimana che inizia:',
              ),
              const SizedBox(height: AppSpacing.s12),
              InkWell(
                onTap: () async {
                  final scelta = await showDatePicker(
                    context: dialogContext,
                    initialDate: nuovaDataInizio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (scelta != null) {
                    setDialogState(() => nuovaDataInizio = scelta);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: colori.azione,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      _formattaData(nuovaDataInizio),
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.azione,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Duplica'),
            ),
          ],
        ),
      ),
    );
    if (confermata != true || !mounted) return;

    try {
      final numeroDuplicati = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .duplica(
            clubId: widget.clubId,
            dataInizioSorgente: _inizioSettimana,
            dataFineSorgente: fineSettimana,
            nuovaDataInizio: nuovaDataInizio,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$numeroDuplicati allenamenti duplicati')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella duplicazione: ${messaggioErrore(e)}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final perGiorno = raggruppaPerGiorno(widget.allenamenti);
    final fineSettimana = aggiungiGiorni(_inizioSettimana, 6);
    final oggi = DateTime.now();

    // Metri e lavoro a tempo dalle serie di tutto il club, lette una volta
    // sola (non una chiamata per allenamento).
    final volumi =
        ref.watch(volumiAllenamentiProvider(widget.clubId)).value ??
        const <String, VolumeAllenamento>{};
    final volumePerGiorno = <DateTime, VolumeAllenamento>{};
    var numeroAllenamentiSettimana = 0;
    for (var index = 0; index < 7; index++) {
      final data = aggiungiGiorni(_inizioSettimana, index);
      final sessioni = perGiorno[data] ?? const [];
      numeroAllenamentiSettimana += sessioni.length;
      volumePerGiorno[data] = sessioni.fold(
        VolumeAllenamento.zero,
        (tot, a) => tot + (volumi[a.id] ?? VolumeAllenamento.zero),
      );
    }
    final volumeSettimana = volumePerGiorno.values.fold(
      VolumeAllenamento.zero,
      (tot, v) => tot + v,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s4,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: colori.testoSecondario,
                    ),
                    onPressed: () => setState(
                      () => _inizioSettimana = aggiungiGiorni(
                        _inizioSettimana,
                        -7,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_formattaData(_inizioSettimana)} — ${_formattaData(fineSettimana)}',
                        style: AppTypography.sezione.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: colori.testoSecondario,
                    ),
                    onPressed: () => setState(
                      () => _inizioSettimana = aggiungiGiorni(
                        _inizioSettimana,
                        7,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    tooltip: 'Duplica questa settimana',
                    onPressed: numeroAllenamentiSettimana == 0
                        ? null
                        : () => _duplicaSettimana(numeroAllenamentiSettimana),
                  ),
                ],
              ),
              if (etichettaVolume(volumeSettimana) case final totale?)
                Text(
                  'Totale settimana: $totale',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
            ],
          ),
        ),
        // Senza scroll proprio: scorre insieme alla pagina che la ospita.
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8),
          child: AppListPanel(
            righe: [
              for (var index = 0; index < 7; index++)
                Builder(
                  builder: (context) {
                    final data = aggiungiGiorni(_inizioSettimana, index);
                    final sessioni = perGiorno[data] ?? const [];
                    final oggiStesso = isStessoGiorno(data, oggi);
                    final volumeGiorno =
                        etichettaVolume(volumePerGiorno[data]!) ?? '0 m';
                    return AppListRow(
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: oggiStesso
                              ? colori.azione
                              : colori.superficieAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${data.day}',
                          style: AppTypography.corpoForte.copyWith(
                            color: oggiStesso ? colori.azioneInk : colori.testo,
                          ),
                        ),
                      ),
                      titolo: _nomiGiorni[index],
                      sottotitolo: sessioni.isEmpty
                          ? 'Nessun allenamento'
                          : '${sessioni.map((a) => a.titolo != null && a.titolo!.isNotEmpty ? a.titolo! : 'Allenamento').join(', ')} · $volumeGiorno',
                      onTap: () => widget.onGiornoSelezionato(data),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
