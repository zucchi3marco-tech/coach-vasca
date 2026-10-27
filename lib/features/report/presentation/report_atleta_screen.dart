import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/categoria_fin.dart';
import '../../export/marchio_pdf.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../data/lettore_report_atleta.dart';
import '../domain/report_atleta.dart';
import '../pdf/report_atleta_pdf.dart';

/// Cosa fare del PDF pronto. Dietro un provider perché nei test non c'è
/// né un browser né il foglio di condivisione.
class AzioniReport {
  const AzioniReport();

  Future<Uint8List> creaPdf(ReportAtleta report, MarchioPdf? marchio) =>
      generaReportAtletaPdf(report, marchio: marchio);

  Future<void> consegna(Uint8List bytes, String nomeFile) async {
    if (scaricaFileDisponibile) {
      scaricaFile(bytes, nomeFile, mimeType: 'application/pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: nomeFile);
    }
  }
}

final azioniReportProvider = Provider<AzioniReport>(
  (ref) => const AzioniReport(),
);

/// "report-rossi-luca-2026-10-27.pdf".
String nomeFileReport(String nome, DateTime giorno) {
  const accenti = {
    'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i', //
    'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u',
  };
  final semplice =
      [for (final c in nome.toLowerCase().split('')) accenti[c] ?? c]
          .join()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
  final data =
      '${giorno.year}-${giorno.month.toString().padLeft(2, '0')}-'
      '${giorno.day.toString().padLeft(2, '0')}';
  return 'report-${semplice.isEmpty ? 'atleta' : semplice}-$data.pdf';
}

/// La stagione dell'atleta per proporre i periodi: quella della sua
/// squadra (o di tutto il club) che comprende oggi, se no l'ultima già
/// cominciata.
Stagione? stagioneDellAtleta(
  List<Stagione> stagioni,
  Atleta atleta,
  DateTime oggi,
) {
  final giorno = soloData(oggi);
  final sue =
      [
        for (final s in stagioni)
          if (s.gruppoId == null || s.gruppoId == atleta.gruppoId) s,
      ]..sort((a, b) {
        // Prima quelle della sua squadra, poi le più recenti.
        final squadra =
            (b.gruppoId != null ? 1 : 0) - (a.gruppoId != null ? 1 : 0);
        return squadra != 0 ? squadra : b.dataInizio.compareTo(a.dataInizio);
      });
  for (final s in sue) {
    if (!soloData(s.dataInizio).isAfter(giorno) &&
        !soloData(s.dataFine).isBefore(giorno)) {
      return s;
    }
  }
  for (final s in sue) {
    if (!soloData(s.dataInizio).isAfter(giorno)) return s;
  }
  return null;
}

/// «Report PDF» dalla scheda di un atleta (solo lo staff): si sceglie il
/// periodo, se mettere benessere e RPE, si scrive una nota e si crea il
/// PDF da mandare alla famiglia.
class ReportAtletaScreen extends ConsumerStatefulWidget {
  const ReportAtletaScreen({required this.atleta, this.oggi, super.key});

  final Atleta atleta;

  /// Per i test; di base adesso.
  final DateTime? oggi;

  @override
  ConsumerState<ReportAtletaScreen> createState() => _ReportAtletaScreenState();
}

class _ReportAtletaScreenState extends ConsumerState<ReportAtletaScreen> {
  final _nota = TextEditingController();
  int _scelto = 0;
  PeriodoReport? _date;
  bool _conBenessere = false;
  bool _creando = false;
  String? _errore;

  DateTime get _oggi => widget.oggi ?? DateTime.now();

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _scegliDate(List<PeriodoReport> proposti) async {
    final base = _date ?? proposti.first;
    final scelta = await showDateRangePicker(
      context: context,
      firstDate: DateTime(_oggi.year - 3),
      lastDate: soloData(_oggi),
      initialDateRange: DateTimeRange(
        start: base.dal,
        end: base.al.isAfter(soloData(_oggi)) ? soloData(_oggi) : base.al,
      ),
      helpText: 'Il periodo del report',
      saveText: 'Scegli',
    );
    if (scelta == null || !mounted) return;
    setState(() {
      _date = PeriodoReport(
        dal: scelta.start,
        al: scelta.end,
        nome: 'Periodo scelto',
      );
      _scelto = proposti.length;
    });
  }

  Future<void> _crea(PeriodoReport periodo, String? squadra) async {
    if (_creando) return;
    setState(() {
      _creando = true;
      _errore = null;
    });
    final leggiMarchio = lettoreMarchioPdf(context, widget.atleta.clubId);
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final dati = await ref
          .read(lettoreReportAtletaProvider)
          .leggi(widget.atleta, periodo, conBenessere: _conBenessere);
      final report = reportAtleta(
        atleta: widget.atleta,
        periodo: periodo,
        dati: dati,
        adesso: _oggi,
        conBenessere: _conBenessere,
        squadra: squadra,
        categoria: switch (categoriaAtleta(widget.atleta, periodo.al)) {
          final c? => 'classe ${widget.atleta.dataNascita.year} ($c)',
          null => null,
        },
        nota: _nota.text,
      );
      final marchio = await leggiMarchio();
      final azioni = ref.read(azioniReportProvider);
      final bytes = await azioni.creaPdf(report, marchio);
      final nomeFile = nomeFileReport(widget.atleta.nomeCompleto, _oggi);
      await azioni.consegna(bytes, nomeFile);
      messaggero.showSnackBar(
        SnackBar(content: Text('Report pronto: $nomeFile')),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _errore =
              'Non sono riuscito a fare il report: '
              '${messaggioErrore(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final atleta = widget.atleta;
    final stagioni = ref.watch(stagioniListProvider(atleta.clubId)).value;
    final gruppi = ref.watch(gruppiListProvider(atleta.clubId)).value;
    final squadra = gruppi
        ?.where((g) => g.id == atleta.gruppoId)
        .firstOrNull
        ?.nome;
    final proposti = periodiProposti(
      stagione: stagioni == null
          ? null
          : stagioneDellAtleta(stagioni, atleta, _oggi),
      oggi: _oggi,
    );
    final scelto = _scelto < proposti.length
        ? proposti[_scelto]
        : (_date ?? proposti.first);

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: atleta.nomeCompleto,
            titolo: 'Report PDF',
            sottotitolo: 'Il riassunto da mandare alla famiglia o al club.',
          ),
          const SizedBox(height: AppSpacing.s28),
          const TitoloSezione('Periodo'),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < proposti.length; i++)
                TonalChip(
                  etichetta: proposti[i].nome,
                  selezionato: _scelto == i,
                  onSelezionato: (_) => setState(() => _scelto = i),
                ),
              TonalChip(
                etichetta: 'Scegli le date',
                selezionato: _scelto >= proposti.length,
                onSelezionato: (_) => _scegliDate(proposti),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Dentro: ${scelto.descrizione}.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const TitoloSezione("Cosa c'è dentro"),
          Text(
            atleta.sport == 'pallanuoto'
                ? 'Presenze, partite con gol ed espulsioni, test e obiettivi.'
                : 'Presenze, test e obiettivi.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Material(
            color: colori.superficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pannello),
              side: BorderSide(color: colori.linea),
            ),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s4,
              ),
              title: Text(
                'Aggiungi benessere e RPE',
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s4),
                child: Text(
                  'Solo le medie del periodo. Dolori e sintomi non ci sono '
                  'mai: il PDF gira per email e chat.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
              value: _conBenessere,
              onChanged: _creando
                  ? null
                  : (v) => setState(() => _conBenessere = v),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const TitoloSezione('La tua nota'),
          AppTextField(
            etichetta: 'Nota per la famiglia (facoltativa)',
            controller: _nota,
            maxLines: 5,
            aiuto: 'Va in fondo al report, così come la scrivi. Non si salva.',
          ),
          if (_errore case final errore?) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              errore,
              style: AppTypography.piccolo.copyWith(color: colori.rosso),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Crea il PDF',
            icon: Icons.picture_as_pdf_outlined,
            isLoading: _creando,
            onPressed: _creando ? null : () => _crea(scelto, squadra),
          ),
        ],
      ),
    );
  }
}
