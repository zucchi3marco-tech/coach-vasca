import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/apri_indirizzo.dart';
import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../pallanuoto/presentation/scheda_avversario_screen.dart';
import '../application/campionati_providers.dart';
import '../application/sito_fin_cambiato.dart';
import '../data/campionati_repository.dart';
import '../domain/campionato_fin.dart';
import 'collega_girone_screen.dart';

/// Classifica e calendario del campionato FIN di una squadra, letti dal
/// sito della FIN Lombardia. L'allenatore collega i gironi (uno per
/// fase); atleti e famiglie li vedono e basta.
class ClassificaScreen extends ConsumerStatefulWidget {
  const ClassificaScreen({
    required this.clubId,
    this.gruppoId,
    this.nomeSquadra,
    this.puoModificare = false,
    this.oggi,
    super.key,
  });

  final String clubId;

  /// null = tutte le squadre del club.
  final String? gruppoId;

  /// L'occhiello della testata (il nome della squadra nell'app).
  final String? nomeSquadra;

  /// Allenatore: collega e toglie i gironi.
  final bool puoModificare;

  /// Per i test.
  final DateTime? oggi;

  @override
  ConsumerState<ClassificaScreen> createState() => _ClassificaScreenState();
}

class _ClassificaScreenState extends ConsumerState<ClassificaScreen> {
  String? _sceltoId;
  bool _tuttoIlCalendario = false;

  Future<void> _collega() async {
    final collegato = await Navigator.of(context).push<GironeCollegato>(
      MaterialPageRoute(
        builder: (_) => CollegaGironeScreen(
          clubId: widget.clubId,
          gruppoId: widget.gruppoId,
        ),
      ),
    );
    if (collegato == null || !mounted) return;
    ref.invalidate(gironiCollegatiProvider(widget.clubId));
    setState(() => _sceltoId = collegato.id);
  }

  Future<void> _togli(GironeCollegato girone) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Togliere il girone?'),
        content: Text(
          '«${girone.campionato}, ${girone.faseEGirone}» non comparirà più '
          'nella classifica della squadra. Puoi collegarlo di nuovo quando '
          'vuoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Togli'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await ref.read(campionatiRepositoryProvider).scollega(girone);
      if (!mounted) return;
      ref.invalidate(gironiCollegatiProvider(widget.clubId));
      setState(() => _sceltoId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
  }

  Future<void> _aggiorna(GironeCollegato? girone) async {
    ref.invalidate(gironiCollegatiProvider(widget.clubId));
    if (girone != null) {
      ref.invalidate(gironeFinProvider(girone.cmpId));
      try {
        await ref.read(gironeFinProvider(girone.cmpId).future);
      } catch (_) {
        // L'errore lo mostra la pagina.
      }
    }
  }

  /// La scheda di una squadra del girone: le nostre partite contro di
  /// lei, i suoi marcatori, la sua classifica.
  void _apriAvversario(String nomeFin, GironeCollegato collegato) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SchedaAvversarioScreen(
          clubId: widget.clubId,
          gruppoId: collegato.gruppoId ?? widget.gruppoId,
          nome: nomeFin,
          vistaStaff: widget.puoModificare,
        ),
      ),
    );
  }

  void _apriSulSito(int cmpId) {
    final indirizzo = indirizzoGironeFin(cmpId);
    if (apriIndirizzo(indirizzo)) return;
    Clipboard.setData(ClipboardData(text: indirizzo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Indirizzo della pagina FIN copiato.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collegatiAsync = ref.watch(gironiCollegatiProvider(widget.clubId));
    final gironi = gironiDellaSquadra(
      collegatiAsync.value ?? const [],
      widget.gruppoId,
    );
    final scelto =
        gironi.where((g) => g.id == _sceltoId).firstOrNull ??
        gironi.firstOrNull;
    final letturaAsync = scelto == null
        ? null
        : ref.watch(gironeFinProvider(scelto.cmpId));
    if (scelto != null) {
      segnalaSeGironeNonLetto(
        ref,
        cmpId: scelto.cmpId,
        clubId: widget.clubId,
        nome: [
          scelto.campionato,
          scelto.faseEGirone,
        ].where((s) => s.isNotEmpty).join(' · '),
      );
    }
    final lettura = letturaAsync?.value;
    final nostra = scelto == null
        ? null
        : lettura?.girone.rigaDi(scelto.squadra);

    final List<Widget> corpo;
    if (collegatiAsync.hasError && !collegatiAsync.hasValue) {
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare i campionati.',
          suggerimento: 'Controlla la rete e riprova.',
          dettaglioTecnico: messaggioErrore(collegatiAsync.error!),
        ),
      ];
    } else if (!collegatiAsync.hasValue) {
      corpo = const [LoadingSkeletonList(righe: 6)];
    } else if (scelto == null) {
      corpo = [
        widget.puoModificare
            ? EmptyState(
                icona: Icons.leaderboard_outlined,
                titolo: 'Nessun campionato collegato',
                descrizione:
                    'Scegli dal sito della FIN Lombardia il girone della '
                    'squadra: poi classifica e calendario si aggiornano da '
                    'soli.',
                azionePrincipale: 'Collega un girone',
                onAzionePrincipale: _collega,
              )
            : EmptyState(
                icona: Icons.leaderboard_outlined,
                titolo: 'Nessun campionato',
                descrizione:
                    'Quando l\'allenatore collega il campionato della '
                    'squadra, qui trovi classifica e calendario.',
                azionePrincipale: 'Ho capito',
                onAzionePrincipale: () => Navigator.of(context).maybePop(),
              ),
      ];
    } else {
      corpo = [
        if (gironi.length > 1) ...[
          _SceltaGirone(
            gironi: gironi,
            scelto: scelto,
            onScelto: (g) => setState(() => _sceltoId = g.id),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        ...switch (letturaAsync!) {
          AsyncValue(:final value?) => _contenuto(context, scelto, value),
          AsyncValue(:final error?) => [
            ErrorBanner(
              messaggio: 'Non è stato possibile leggere il sito della FIN.',
              suggerimento: 'Riprova tra qualche minuto.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ],
          _ => [const LoadingSkeletonList(righe: 8)],
        },
        if (widget.puoModificare) ...[
          const SizedBox(height: AppSpacing.s24),
          Center(
            child: TextButton.icon(
              onPressed: () => _togli(scelto),
              icon: const Icon(Icons.link_off),
              label: const Text('Togli questo girone'),
            ),
          ),
        ],
      ];
    }

    return AppScaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => _aggiorna(scelto),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            TestataPagina(
              occhiello: widget.nomeSquadra,
              titolo: 'Classifica',
              sottotitolo: scelto == null
                  ? null
                  : [
                      scelto.campionato,
                      scelto.faseEGirone,
                    ].where((s) => s.isNotEmpty).join(' · '),
              numeri: nostra == null
                  ? const []
                  : [
                      NumeroTestata(
                        valore: '${nostra.posizione}°',
                        etichetta: 'Posizione',
                      ),
                      NumeroTestata(
                        valore: '${nostra.punti}',
                        etichetta: 'Punti',
                      ),
                      NumeroTestata(
                        valore: '${nostra.giocate}',
                        etichetta: 'Giocate',
                      ),
                    ],
              azioni: [
                if (widget.puoModificare && scelto != null)
                  AzioneTestata(
                    icona: Icons.add_link,
                    etichetta: 'Collega un girone',
                    onTap: _collega,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            ...corpo,
          ],
        ),
      ),
    );
  }

  List<Widget> _contenuto(
    BuildContext context,
    GironeCollegato collegato,
    LetturaGirone lettura,
  ) {
    final colori = context.colori;
    final girone = lettura.girone;
    final ora =
        '${lettura.lettoIl.hour.toString().padLeft(2, '0')}:'
        '${lettura.lettoIl.minute.toString().padLeft(2, '0')}';
    final quando =
        giorniTra(lettura.lettoIl, widget.oggi ?? DateTime.now()) == 0
        ? 'alle $ora'
        : 'il ${dataCompatta(lettura.lettoIl)} alle $ora';
    final incontri = girone.incontriDi(collegato.squadra);
    final prossimo = girone.prossimoDi(collegato.squadra);

    final nonLetto = girone.nonTuttoLetto;
    return [
      if (nonLetto)
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.s16),
          child: RiquadroVuoto(
            testoSitoFinCambiato,
            icona: Icons.report_problem_outlined,
          ),
        ),
      if (lettura.daCopia)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          child: RiquadroVuoto(
            'Il sito della FIN non risponde: è la classifica letta $quando.',
            icona: Icons.cloud_off_outlined,
          ),
        ),
      TitoloSezione(
        'Classifica',
        azione: 'Sito FIN',
        onAzione: () => _apriSulSito(girone.cmpId),
      ),
      if (girone.classifica.isEmpty)
        RiquadroVuoto(
          nonLetto
              ? 'La classifica non si riesce a leggere dal sito della FIN.'
              : 'La FIN non ha ancora pubblicato la classifica di questo '
                    'girone.',
        )
      else
        _TabellaClassifica(
          righe: girone.classifica,
          nostra: collegato.squadra,
          onSquadra: (nome) => _apriAvversario(nome, collegato),
        ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8, left: 4),
        child: Text(
          lettura.daCopia
              ? 'Fonte: FIN Lombardia'
              : 'Fonte: FIN Lombardia · aggiornata $quando',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ),
      const SizedBox(height: AppSpacing.s24),
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
        child: Wrap(
          spacing: AppSpacing.s8,
          children: [
            ChoiceChip(
              label: const Text('Le nostre partite'),
              selected: !_tuttoIlCalendario,
              onSelected: (_) => setState(() => _tuttoIlCalendario = false),
            ),
            ChoiceChip(
              label: const Text('Tutto il calendario'),
              selected: _tuttoIlCalendario,
              onSelected: (_) => setState(() => _tuttoIlCalendario = true),
            ),
          ],
        ),
      ),
      if (_tuttoIlCalendario)
        ..._calendarioCompleto(girone, collegato.squadra)
      else if (incontri.isEmpty)
        RiquadroVuoto(
          nonLetto
              ? 'Il calendario non si riesce a leggere dal sito della FIN.'
              : 'La FIN non ha ancora pubblicato il calendario della squadra.',
        )
      else
        SezioneSchede(
          titolo: 'Le nostre partite',
          vociIniziali: 30,
          figli: [
            for (final i in incontri)
              _SchedaIncontro(
                incontro: i,
                squadra: collegato.squadra,
                giornata: _giornataDi(girone, i),
                prossimo: identical(i, prossimo),
                onAvversario: (nome) => _apriAvversario(nome, collegato),
              ),
          ],
        ),
    ];
  }

  String _giornataDi(GironeFin girone, IncontroFin incontro) {
    for (final g in girone.giornate) {
      if (g.incontri.any((i) => identical(i, incontro))) return g.nome;
    }
    return '';
  }

  List<Widget> _calendarioCompleto(GironeFin girone, String squadra) {
    if (girone.giornate.isEmpty) {
      return [
        RiquadroVuoto(
          girone.nonTuttoLetto
              ? 'Il calendario non si riesce a leggere dal sito della FIN.'
              : 'La FIN non ha ancora pubblicato il calendario.',
        ),
      ];
    }
    return [
      for (final g in girone.giornate) ...[
        TitoloSezione(g.nome),
        AppListPanel(
          righe: [
            for (final i in g.incontri)
              _RigaIncontro(incontro: i, squadra: squadra),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
      ],
    ];
  }
}

/// Le fasi collegate (Fase 1, Finali…): una alla volta.
class _SceltaGirone extends StatelessWidget {
  const _SceltaGirone({
    required this.gironi,
    required this.scelto,
    required this.onScelto,
  });

  final List<GironeCollegato> gironi;
  final GironeCollegato scelto;
  final ValueChanged<GironeCollegato> onScelto;

  @override
  Widget build(BuildContext context) {
    // Con campionati diversi serve anche il nome del campionato.
    final campionati = {for (final g in gironi) g.campionato};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final g in gironi)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: ChoiceChip(
                label: Text(
                  campionati.length > 1
                      ? '${g.campionato} · ${g.faseEGirone}'
                      : g.faseEGirone.isEmpty
                      ? g.campionato
                      : g.faseEGirone,
                ),
                selected: g.id == scelto.id,
                onSelected: (_) => onScelto(g),
              ),
            ),
        ],
      ),
    );
  }
}

/// La classifica: posizione, squadra, punti, giocate e differenza reti;
/// su uno schermo largo anche vinte, pari, perse e gol. La squadra del
/// club in evidenza.
class _TabellaClassifica extends StatelessWidget {
  const _TabellaClassifica({
    required this.righe,
    required this.nostra,
    required this.onSquadra,
  });

  final List<RigaClassificaFin> righe;
  final String nostra;

  /// Un tocco su un'altra squadra apre la sua scheda.
  final ValueChanged<String> onSquadra;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return LayoutBuilder(
      builder: (context, vincoli) {
        final largo = vincoli.maxWidth >= 560;
        final intestazione = AppTypography.etichetta.copyWith(
          color: colori.testoSecondario,
        );
        Widget numero(String testo, TextStyle stile, {double larghezza = 36}) =>
            SizedBox(
              width: larghezza,
              child: Text(
                testo,
                textAlign: TextAlign.right,
                style: AppTypography.numerica(stile),
              ),
            );
        Widget riga({
          required String posizione,
          required String squadra,
          required List<String> valori,
          required TextStyle stile,
          Color? fondo,
        }) {
          return Container(
            constraints: const BoxConstraints(minHeight: 48),
            color: fondo,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(posizione, style: AppTypography.numerica(stile)),
                ),
                Expanded(
                  child: Text(
                    squadra,
                    style: stile,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final (i, v) in valori.indexed)
                  numero(v, stile, larghezza: i == valori.length - 1 ? 44 : 36),
              ],
            ),
          );
        }

        List<String> valori(RigaClassificaFin r) => [
          '${r.punti}',
          '${r.giocate}',
          if (largo) ...[
            '${r.vinte}',
            '${r.pareggiate}',
            '${r.perse}',
            '${r.golFatti}',
            '${r.golSubiti}',
          ],
          r.differenza > 0 ? '+${r.differenza}' : '${r.differenza}',
        ];

        return AppListPanel(
          righe: [
            riga(
              posizione: '#',
              squadra: 'Squadra',
              valori: [
                'Pt',
                'G',
                if (largo) ...['V', 'N', 'P', 'GF', 'GS'],
                'DR',
              ],
              stile: intestazione,
              fondo: colori.superficieAlt,
            ),
            for (final r in righe)
              if (stessaSquadra(r.squadra, nostra))
                Semantics(
                  label:
                      '${r.posizione}°, ${r.squadra}, ${r.punti} punti, '
                      '${r.giocate} giocate, differenza reti ${r.differenza}',
                  excludeSemantics: true,
                  child: riga(
                    posizione: '${r.posizione}',
                    squadra: r.squadra,
                    valori: valori(r),
                    stile: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                    fondo: colori.azioneTenue,
                  ),
                )
              else
                Semantics(
                  label:
                      '${r.posizione}°, ${r.squadra}, ${r.punti} punti, '
                      '${r.giocate} giocate, differenza reti ${r.differenza}. '
                      'Apri la scheda dell\'avversario',
                  button: true,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onSquadra(r.squadra),
                    child: riga(
                      posizione: '${r.posizione}',
                      squadra: r.squadra,
                      valori: valori(r),
                      stile: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Esito di un incontro per la squadra: vinta, pari, persa (null se non
/// giocato).
String? _esito(IncontroFin i, String squadra) {
  if (!i.giocato) return null;
  final inCasa = stessaSquadra(i.casa, squadra);
  final nostri = inCasa ? i.golCasa! : i.golOspite!;
  final loro = inCasa ? i.golOspite! : i.golCasa!;
  return nostri > loro
      ? 'V'
      : nostri == loro
      ? 'N'
      : 'P';
}

/// Una partita della squadra, come nell'elenco delle partite.
class _SchedaIncontro extends StatelessWidget {
  const _SchedaIncontro({
    required this.incontro,
    required this.squadra,
    required this.giornata,
    required this.prossimo,
    required this.onAvversario,
  });

  final IncontroFin incontro;
  final String squadra;
  final String giornata;
  final bool prossimo;
  final ValueChanged<String> onAvversario;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final ambra = context.dominio.evidenzaAmbra;
    final i = incontro;
    if (i.riposo) {
      return SchedaElenco(
        leading: const IconaRiquadro(Icons.weekend_outlined),
        occhiello: giornata,
        titolo: 'Riposo',
        attenuata: true,
        mostraFreccia: false,
      );
    }
    final inCasa = stessaSquadra(i.casa, squadra);
    final avversario = inCasa ? i.ospite : i.casa;
    final esito = _esito(i, squadra);
    final quando = i.data == null
        ? (i.dataTesto ?? 'Data da definire')
        : i.ora == null
        ? dataCompatta(i.data!)
        : '${dataCompatta(i.data!)}, ore ${i.ora}';
    return SchedaElenco(
      leading: i.data == null
          ? const IconaRiquadro(Icons.event_outlined)
          : RiquadroData(i.data!, colore: ambra, spento: esito != null),
      occhiello: prossimo ? 'Prossima · $giornata' : giornata,
      evidenza: prossimo ? ambra : null,
      titolo: 'vs $avversario',
      sottotitolo: [quando, ?i.piscina].join(' · '),
      attenuata: esito != null,
      onTap: () => onAvversario(avversario),
      trailing: esito != null
          ? Pastiglia(
              inCasa
                  ? '${i.golCasa}-${i.golOspite}'
                  : '${i.golOspite}-${i.golCasa}',
              colore: switch (esito) {
                'V' => colori.ok,
                'N' => colori.attenzione,
                _ => colori.rosso,
              },
            )
          : i.risultatoTesto != null
          ? Pastiglia(i.risultatoTesto!, colore: colori.testoSecondario)
          : null,
    );
  }
}

/// Un incontro del calendario completo: "Casa 14-7 Ospite", la squadra
/// del club in grassetto.
class _RigaIncontro extends StatelessWidget {
  const _RigaIncontro({required this.incontro, required this.squadra});

  final IncontroFin incontro;
  final String squadra;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final i = incontro;
    TextStyle stile(String nome) => stessaSquadra(nome, squadra)
        ? AppTypography.corpoForte.copyWith(color: colori.testo)
        : AppTypography.corpo.copyWith(color: colori.testo);
    final centro = i.giocato
        ? '${i.golCasa}-${i.golOspite}'
        : i.risultatoTesto ?? (i.riposo ? '' : (i.ora ?? '–'));
    final sotto = i.riposo
        ? null
        : [
            if (i.data != null) dataCompatta(i.data!) else ?i.dataTesto,
            ?i.piscina,
          ].join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i.casa,
                  style: stile(i.casa),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  centro,
                  textAlign: TextAlign.center,
                  style: AppTypography.numerica(
                    AppTypography.corpoForte.copyWith(
                      color: i.giocato ? colori.testo : colori.testoSecondario,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  i.riposo && stessaSquadra(i.ospite, 'riposo')
                      ? 'riposa'
                      : i.ospite,
                  style: stile(i.ospite),
                ),
              ),
            ],
          ),
          if (sotto != null && sotto.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sotto,
                textAlign: TextAlign.center,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
