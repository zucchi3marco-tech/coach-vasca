import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/testata_pagina.dart';
import '../../export/marchio_pdf.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../data/lettore_report_squadra.dart';
import '../domain/report_atleta.dart';
import '../domain/report_squadra.dart';
import 'azioni_report.dart';
import 'scegli_periodo_report.dart';

/// «Report PDF» di una squadra, dalle statistiche della stagione: si
/// sceglie il periodo, se mettere le medie di benessere e RPE, si scrive
/// una nota e si crea il PDF da mandare al club o alle famiglie.
class ReportSquadraScreen extends ConsumerStatefulWidget {
  const ReportSquadraScreen({required this.stagione, this.oggi, super.key});

  final Stagione stagione;

  /// Per i test; di base adesso.
  final DateTime? oggi;

  @override
  ConsumerState<ReportSquadraScreen> createState() =>
      _ReportSquadraScreenState();
}

class _ReportSquadraScreenState extends ConsumerState<ReportSquadraScreen> {
  final _nota = TextEditingController();
  PeriodoReport? _periodo;
  bool _conBenessere = false;
  bool _creando = false;
  String? _errore;

  DateTime get _oggi => widget.oggi ?? DateTime.now();

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _crea(PeriodoReport periodo, String nome) async {
    if (_creando) return;
    setState(() {
      _creando = true;
      _errore = null;
    });
    final stagione = widget.stagione;
    final leggiMarchio = lettoreMarchioPdf(context, stagione.clubId);
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final dati = await ref
          .read(lettoreReportSquadraProvider)
          .leggi(
            clubId: stagione.clubId,
            gruppoId: stagione.gruppoId,
            periodo: periodo,
            conBenessere: _conBenessere,
          );
      final report = reportSquadra(
        nome: nome,
        gruppoId: stagione.gruppoId,
        periodo: periodo,
        dati: dati,
        adesso: _oggi,
        conBenessere: _conBenessere,
        campionato: (stagione.campionato ?? '').trim().isEmpty
            ? null
            : stagione.campionato!.trim(),
        nota: _nota.text,
      );
      final marchio = await leggiMarchio();
      final azioni = ref.read(azioniReportProvider);
      final bytes = await azioni.creaPdfSquadra(report, marchio);
      final nomeFile = nomeFileReport(nome, _oggi);
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
    final stagione = widget.stagione;
    final gruppi = ref.watch(gruppiListProvider(stagione.clubId)).value;
    final squadra = stagione.gruppoId == null
        ? 'Tutto il club'
        : gruppi?.where((g) => g.id == stagione.gruppoId).firstOrNull?.nome ??
              stagione.nome;
    final cominciata = !soloData(stagione.dataInizio).isAfter(soloData(_oggi));
    final proposti = periodiProposti(stagione: stagione, oggi: _oggi);
    final scelto = ScegliPeriodoReport.valore(proposti, _periodo);

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: '$squadra · ${stagione.nome}',
            titolo: 'Report PDF',
            sottotitolo:
                'Il riassunto della squadra da mandare al club o alle '
                'famiglie.',
          ),
          const SizedBox(height: AppSpacing.s28),
          if (!cominciata)
            const RiquadroVuoto(
              'La stagione non è ancora cominciata: il report si fa dal '
              'primo giorno.',
            )
          else ...[
            ScegliPeriodoReport(
              proposti: proposti,
              scelto: _periodo,
              oggi: _oggi,
              onScelto: (p) => setState(() => _periodo = p),
            ),
            const SizedBox(height: AppSpacing.s24),
            const TitoloSezione("Cosa c'è dentro"),
            Text(
              'Le partite con il risultato e il bilancio, la classifica FIN, '
              'i marcatori, le presenze di ognuno e i numeri delle partite '
              'seguite dal vivo.',
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
                    'Solo le medie di tutta la squadra, mai dei singoli. '
                    'Dolori e sintomi non ci sono mai.',
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
              etichetta: 'Nota sulla squadra (facoltativa)',
              controller: _nota,
              maxLines: 5,
              aiuto:
                  'Va in fondo al report, così come la scrivi. Non si salva.',
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
        ],
      ),
    );
  }
}
