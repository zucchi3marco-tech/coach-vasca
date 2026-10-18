import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../application/dati_club_providers.dart';
import '../application/excel_dati_club.dart';
import '../data/dati_club_repository.dart';
import '../domain/periodo_dati.dart';

const _mimeXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Cosa farne del file pronto: scaricarlo nel browser. Dietro un provider
/// perché nei test non c'è un browser, e perché così si può leggere cosa
/// sarebbe stato scaricato.
class AzioniDatiClub {
  const AzioniDatiClub();

  /// Il download è possibile solo dall'app aperta nel browser.
  bool get disponibile => scaricaFileDisponibile;

  void scarica(Uint8List bytes, String nomeFile) =>
      scaricaFile(bytes, nomeFile, mimeType: _mimeXlsx);
}

final azioniDatiClubProvider = Provider<AzioniDatiClub>(
  (ref) => const AzioniDatiClub(),
);

/// Quanto aspettare, dopo aver scritto "Scrivo il file", prima di
/// cominciare a scriverlo davvero: il lavoro occupa il telefono per qualche
/// secondo con un club grande, e la frase deve fare in tempo a comparire.
const _pausaPerDisegnare = Duration(milliseconds: 60);

enum _Fase { scelta, inCorso, pronto }

/// "Scarica i dati del club": il responsabile sceglie il periodo (tutto o
/// una stagione) e se aggiungere anche benessere e dolori, e riceve un file
/// Excel con un foglio per tipo di dato. I dati si leggono dal server, il
/// file si scrive sul dispositivo e non passa da nessun altro servizio.
class ScaricaDatiClubScreen extends ConsumerStatefulWidget {
  const ScaricaDatiClubScreen({
    required this.clubId,
    required this.clubNome,
    required this.scaricatoDa,
    super.key,
  });

  final String clubId;
  final String clubNome;

  /// Chi scarica, com'è scritto nel foglio "Leggimi" ("Marco Rossi
  /// (marco@example.com)").
  final String scaricatoDa;

  @override
  ConsumerState<ScaricaDatiClubScreen> createState() =>
      _ScaricaDatiClubScreenState();
}

class _ScaricaDatiClubScreenState extends ConsumerState<ScaricaDatiClubScreen> {
  PeriodoDati _periodo = const PeriodoDati.tutto();
  bool _conBenessere = false;
  _Fase _fase = _Fase.scelta;

  /// Cosa sta facendo adesso ("Leggo le presenze"), senza i puntini.
  String _passo = '';
  Object? _errore;

  // Il file pronto: gli stessi byte per "Scaricalo di nuovo", così i dati
  // non si rileggono dal server.
  Uint8List? _bytes;
  String _nomeFile = '';

  /// L'esito (il file pronto o l'errore), che compare sotto il punto in cui
  /// si è toccato il pulsante: su un telefono può finire sotto il bordo.
  final _chiaveEsito = GlobalKey();

  /// Porta l'esito in vista, appena è sullo schermo.
  void _mostraEsito() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contesto = _chiaveEsito.currentContext;
      if (!mounted || contesto == null) return;
      Scrollable.ensureVisible(
        contesto,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: MediaQuery.disableAnimationsOf(contesto)
            ? Duration.zero
            : AppMotion.transizione,
        curve: AppMotion.curvaEntrata,
      );
    });
  }

  /// Cambiando una scelta il file pronto non vale più: si torna all'inizio.
  void _ricomincia() {
    _fase = _Fase.scelta;
    _bytes = null;
    _errore = null;
  }

  void _scegliPeriodo(PeriodoDati periodo) {
    if (_fase == _Fase.inCorso) return;
    setState(() {
      _periodo = periodo;
      _ricomincia();
    });
  }

  void _cambiaBenessere(bool valore) {
    if (_fase == _Fase.inCorso) return;
    setState(() {
      _conBenessere = valore;
      _ricomincia();
    });
  }

  Future<void> _prepara(PeriodoDati periodo) async {
    if (_fase == _Fase.inCorso) return;
    final conBenessere = _conBenessere;
    setState(() {
      _fase = _Fase.inCorso;
      _passo = 'Leggo i dati';
      _errore = null;
    });
    try {
      final dati = await ref
          .read(datiClubRepositoryProvider)
          .leggi(
            widget.clubId,
            conBenessere: conBenessere,
            avanzamento: (cosa) {
              if (mounted) setState(() => _passo = cosa);
            },
          );
      if (!mounted) return;
      setState(() => _passo = 'Scrivo il file');
      await Future<void>.delayed(_pausaPerDisegnare);
      if (!mounted) return;
      final adesso = DateTime.now();
      final bytes = fileExcelDatiClub(
        dati,
        nomeClub: widget.clubNome,
        scaricatoDa: widget.scaricatoDa,
        adesso: adesso,
        periodo: periodo,
        conBenessere: conBenessere,
      );
      final nomeFile = nomeFileDatiClub(widget.clubNome, adesso);
      ref.read(azioniDatiClubProvider).scarica(bytes, nomeFile);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _nomeFile = nomeFile;
          _fase = _Fase.pronto;
        });
        _mostraEsito();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fase = _Fase.scelta;
          _errore = e;
        });
        _mostraEsito();
      }
    }
  }

  void _scaricaDiNuovo() {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      ref.read(azioniDatiClubProvider).scarica(bytes, _nomeFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dotenv.isInitialized && modalitaDemo) {
      return AppScaffold(
        appBar: AppBar(),
        body: EmptyState(
          icona: Icons.download_outlined,
          titolo: 'Nella demo i dati non si scaricano',
          descrizione:
              'Con l\'app vera qui scarichi un file Excel con atleti, '
              'allenamenti, presenze, partite e il resto.',
          azionePrincipale: 'Torna indietro',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final disponibile = ref.watch(azioniDatiClubProvider).disponibile;
    final colori = context.colori;
    final occupato = _fase == _Fase.inCorso;

    // Finché non si sa quando è nato il club (o se non si riesce a
    // leggerlo) si offrono le stagioni di base.
    final creatoIl = ref.watch(creatoIlClubProvider(widget.clubId)).value;
    final periodi = periodiDisponibili(DateTime.now(), daQuando: creatoIl);
    // Il periodo scelto può uscire dall'elenco quando arriva la data di
    // nascita del club: si torna a "Tutto".
    final periodo = periodi.contains(_periodo)
        ? _periodo
        : const PeriodoDati.tutto();

    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: widget.clubNome,
            titolo: 'Scarica i dati del club',
            sottotitolo: 'Un file Excel con un foglio per tipo di dato.',
          ),
          const SizedBox(height: AppSpacing.s28),
          if (!disponibile)
            const RiquadroVuoto(
              'Il file Excel si scarica aprendo l\'app nel browser, per '
              'esempio da un computer.',
              icona: Icons.language,
            )
          else ...[
            const TitoloSezione('Periodo'),
            Opacity(
              opacity: occupato ? 0.38 : 1,
              child: AppListPanel(
                righe: [
                  for (final p in periodi)
                    _RigaPeriodo(
                      periodo: p,
                      selezionato: p == periodo,
                      onTap: occupato ? null : () => _scegliPeriodo(p),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Opacity(
              opacity: occupato ? 0.38 : 1,
              child: Material(
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
                    'Anche benessere e dolori',
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s4),
                    child: Text(
                      'Sonno, energia, dolori e sintomi delle schede degli '
                      'atleti: sono dati sulla salute, aggiungili solo se ti '
                      'servono.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ),
                  value: _conBenessere,
                  onChanged: occupato ? null : _cambiaBenessere,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            _Fascia(
              sfondo: colori.attenzioneTenue,
              segno: colori.attenzione,
              icona: Icons.info_outline,
              child: Text(
                'Il file contiene dati personali di atleti, anche '
                'minorenni: conservalo con cura e non mandarlo in giro. Si '
                'prepara su questo dispositivo e non passa da nessun altro '
                'servizio.',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            if (_errore != null)
              Column(
                key: _chiaveEsito,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(
                    messaggio: 'Non è stato possibile preparare il file.',
                    suggerimento: 'Controlla la connessione e riprova.',
                    dettaglioTecnico: messaggioErrore(_errore!),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _prepara(periodo),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Riprova'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ),
            if (_fase == _Fase.pronto)
              Column(
                key: _chiaveEsito,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Fascia(
                    sfondo: colori.okTenue,
                    segno: colori.ok,
                    icona: Icons.check_circle_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File scaricato: $_nomeFile',
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Lo trovi fra i download del browser.',
                          style: AppTypography.piccolo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  SecondaryButton(
                    label: 'Scaricalo di nuovo',
                    onPressed: _scaricaDiNuovo,
                  ),
                ],
              )
            else
              PrimaryButton(
                label: 'Scarica il file Excel',
                isLoading: occupato,
                onPressed: occupato ? null : () => _prepara(periodo),
              ),
            // Sotto il pulsante e non sopra: così il pulsante non si sposta
            // sotto il dito quando comincia il lavoro.
            if (occupato) ...[
              const SizedBox(height: AppSpacing.s12),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$_passo…',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Un periodo fra cui scegliere: "Tutto", "Stagione 2026-2027" e sotto cosa
/// comprende. La scelta selezionata ha il fondo tenue e il filetto, e il
/// cerchio pieno (il colore da solo non basta).
class _RigaPeriodo extends StatelessWidget {
  const _RigaPeriodo({
    required this.periodo,
    required this.selezionato,
    required this.onTap,
  });

  final PeriodoDati periodo;
  final bool selezionato;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selezionato,
        child: Container(
          color: selezionato ? colori.azioneTenue : null,
          child: LaneRule(
            // Sul fondo del pannello il filetto di una riga non scelta non
            // si vede.
            colore: selezionato ? colori.azione : colori.superficie,
            child: AppListRow(
              titolo: periodo.etichetta,
              sottotitolo: periodo.descrizione,
              leading: Icon(
                selezionato
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selezionato ? colori.azione : colori.testoSecondario,
              ),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

/// Una fascia con il suo segno a sinistra (avviso, conferma): fondo tenue,
/// filetto di 3px e icona dello stesso colore, come la fascia d'errore.
class _Fascia extends StatelessWidget {
  const _Fascia({
    required this.sfondo,
    required this.segno,
    required this.icona,
    required this.child,
  });

  final Color sfondo;
  final Color segno;
  final IconData icona;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border(left: BorderSide(color: segno, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icona, size: 20, color: segno),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
