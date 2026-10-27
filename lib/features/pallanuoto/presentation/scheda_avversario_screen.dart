import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../campionati/application/campionati_providers.dart';
import '../../campionati/domain/campionato_fin.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/scheda_avversario_providers.dart';
import '../domain/partita.dart';
import '../domain/scheda_avversario.dart';
import 'distinta_screen.dart';
import 'statistiche_partita_screen.dart';
import 'voci_partita.dart';

/// Tutto quello che sappiamo di un avversario: le nostre partite contro
/// di lui (solo della squadra), i suoi marcatori dai referti, i numeri
/// dal vivo e la sua classifica nel girone FIN collegato. La vedono
/// staff e atleti; lo staff da una partita apre la sua scheda.
class SchedaAvversarioScreen extends ConsumerWidget {
  const SchedaAvversarioScreen({
    required this.clubId,
    required this.gruppoId,
    required this.nome,
    this.partitaId,
    this.vistaStaff = false,
    super.key,
  });

  final String clubId;

  /// La squadra delle partite (null: quelle di tutto il club).
  final String? gruppoId;

  /// Come lo scriviamo noi o come lo scrive il sito FIN.
  final String nome;

  /// La partita da cui si è aperta: toccarla torna indietro.
  final String? partitaId;

  /// Allenatori e assistenti: un tocco su una partita apre la sua scheda.
  final bool vistaStaff;

  void _apri(BuildContext context, Partita p, {required bool giocata}) {
    if (p.id == partitaId) {
      Navigator.of(context).pop();
      return;
    }
    final Widget pagina;
    if (vistaStaff) {
      pagina = DistintaScreen(partita: p);
    } else if (giocata) {
      pagina = StatistichePartitaScreen(partita: p);
    } else {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (clubId: clubId, gruppoId: gruppoId, nome: nome);
    final schedaAsync = ref.watch(schedaAvversarioProvider(chiave));
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: gruppoId)),
    );
    final scheda = schedaAsync.value;

    final List<Widget> corpo;
    if (schedaAsync.hasError && scheda == null) {
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare la scheda.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(schedaAsync.error!),
        ),
      ];
    } else if (scheda == null) {
      corpo = const [LoadingSkeletonList(righe: 6)];
    } else {
      corpo = _corpo(context, scheda);
    }

    return AppScaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(schedaAvversarioProvider(chiave));
          ref.invalidate(gironiCollegatiProvider(clubId));
          try {
            await ref.read(schedaAvversarioProvider(chiave).future);
          } catch (_) {
            // L'errore lo mostra la pagina.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            TestataPagina(
              occhiello: nomeSquadra.isEmpty ? null : nomeSquadra,
              titolo: scheda?.nome ?? nome,
              sottotitolo: 'Scheda dell\'avversario',
              numeri: scheda == null || scheda.conRisultato.isEmpty
                  ? const []
                  : [
                      NumeroTestata(
                        valore: '${scheda.vinte}',
                        etichetta: 'Vinte',
                      ),
                      NumeroTestata(
                        valore: '${scheda.pari}',
                        etichetta: 'Pari',
                      ),
                      NumeroTestata(
                        valore: '${scheda.perse}',
                        etichetta: 'Perse',
                      ),
                      NumeroTestata(
                        valore: '${scheda.golFatti}–${scheda.golSubiti}',
                        etichetta: 'Gol',
                      ),
                    ],
            ),
            const SizedBox(height: AppSpacing.s24),
            ...corpo,
            const SizedBox(height: AppSpacing.s24),
            _CampionatiFin(
              clubId: clubId,
              gruppoId: gruppoId,
              nomi: {nome, ?scheda?.nome}.toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corpo(BuildContext context, SchedaAvversario scheda) {
    final colori = context.colori;
    final ambra = context.dominio.evidenzaAmbra;
    if (scheda.vuota) {
      return const [
        RiquadroVuoto(
          'Con questa squadra non ci sono ancora partite contro di loro.',
          icona: Icons.sports_handball_outlined,
        ),
      ];
    }

    Color coloreEsito(String? esito) => switch (esito) {
      'V' => colori.ok,
      'P' => colori.rosso,
      _ => colori.testoSecondario,
    };

    return [
      if (scheda.prossime.isNotEmpty) ...[
        SezioneSchede(
          titolo: 'Da giocare',
          figli: [
            for (final p in scheda.prossime)
              SchedaElenco(
                leading: RiquadroData(p.data, colore: ambra),
                occhiello: p.id == partitaId ? 'Questa partita' : null,
                titolo: 'vs ${p.avversario}',
                sottotitolo: [
                  quandoConOra(p.data, p.ora),
                  p.inCasa ? 'in casa' : 'in trasferta',
                ].join(' · '),
                mostraFreccia: vistaStaff,
                onTap: vistaStaff
                    ? () => _apri(context, p, giocata: false)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      if (scheda.giocate.isNotEmpty) ...[
        SezioneSchede(
          titolo: 'Precedenti',
          figli: [
            for (final g in scheda.giocate)
              SchedaElenco(
                leading: RiquadroData(
                  g.partita.data,
                  colore: ambra,
                  spento: true,
                ),
                occhiello: g.partita.id == partitaId ? 'Questa partita' : null,
                titolo: 'vs ${g.partita.avversario}',
                sottotitolo: [
                  dataCompatta(g.partita.data),
                  g.partita.inCasa ? 'in casa' : 'in trasferta',
                  if (!g.haRisultato)
                    'senza risultato'
                  else if (g.daReferto)
                    'dal referto'
                  else
                    'dal vivo',
                ].join(' · '),
                trailing: g.punteggio == null
                    ? null
                    : Pastiglia(g.punteggio!, colore: coloreEsito(g.esito)),
                onTap: () => _apri(context, g.partita, giocata: true),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        ..._giocatori(context, scheda),
        ..._dalVivo(context, scheda),
      ],
    ];
  }

  List<Widget> _giocatori(BuildContext context, SchedaAvversario scheda) {
    final colori = context.colori;
    // La loro calottina è l'altra rispetto alla nostra dell'ultima volta.
    final nostra = scheda.giocate.first.partita.coloreCalottina;
    final loro = nostra == 'blu' ? CapColore.bianca : CapColore.blu;
    return [
      const TitoloSezione(
        'I loro giocatori',
        spiegazione:
            'Dai referti delle partite contro di loro: gol ed espulsioni '
            'di ognuno, con il numero dell\'ultima partita.',
      ),
      if (scheda.giocatori.isEmpty)
        const RiquadroVuoto(
          'Leggi il referto di una partita contro di loro: qui compaiono '
          'chi segna e chi prende espulsioni.',
          icona: Icons.description_outlined,
        )
      else
        AppListPanel(
          righe: [
            for (final g in scheda.giocatori)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  children: [
                    CapBadge(numero: g.numero, colore: loro),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.nome.isEmpty ? 'Numero ${g.numero}' : g.nome,
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                          Text(
                            _rigaGiocatore(g),
                            style: AppTypography.piccolo.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      const SizedBox(height: AppSpacing.s24),
    ];
  }

  List<Widget> _dalVivo(BuildContext context, SchedaAvversario scheda) {
    if (scheda.partiteDalVivo == 0) return const [];
    final colori = context.colori;
    final n = scheda.dalVivo;
    final righe = <(String, String)>[
      ('I loro gol su tiri', conPercentuale(n.golSubiti, n.tiriSubiti)),
      ('I nostri gol su tiri', conPercentuale(n.gol, n.tiri)),
      (
        'La loro superiorità',
        conPercentuale(n.golSubitiInInferiorita, n.inferiorita),
      ),
      (
        'La nostra superiorità',
        conPercentuale(n.golInSuperiorita, n.superiorita),
      ),
      if (n.golSubitiControfuga > 0)
        ('Gol subiti in controfuga', '${n.golSubitiControfuga}'),
      if (scheda.espulsioniPerNumero.isNotEmpty)
        ('Le loro espulsioni', _espulsioni(scheda.espulsioniPerNumero)),
    ];
    return [
      TitoloSezione(
        'Dal vivo',
        spiegazione: scheda.partiteDalVivo == 1
            ? 'Dalla partita contro di loro seguita dal vivo.'
            : 'Dalle ${scheda.partiteDalVivo} partite contro di loro seguite '
                  'dal vivo.',
      ),
      AppListPanel(
        righe: [
          for (final (etichetta, valore) in righe)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      etichetta,
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(
                    child: Text(
                      valore,
                      textAlign: TextAlign.right,
                      style: AppTypography.numerica(
                        AppTypography.corpoForte.copyWith(color: colori.testo),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.s24),
    ];
  }
}

/// «3 gol in 2 partite · 1 espulsione».
String _rigaGiocatore(GiocatoreAvversario g) =>
    [
      g.reti == 1 ? '1 gol' : '${g.reti} gol',
      g.partite == 1 ? 'in 1 partita' : 'in ${g.partite} partite',
    ].join(' ') +
    (g.espulsioni == 0
        ? ''
        : g.espulsioni == 1
        ? ' · 1 espulsione'
        : ' · ${g.espulsioni} espulsioni');

/// «n. 7 (2), n. 3», dal numero con più espulsioni.
String _espulsioni(Map<int, int> perNumero) {
  final voci = perNumero.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return [
    for (final e in voci)
      e.value == 1 ? 'n. ${e.key}' : 'n. ${e.key} (${e.value})',
  ].join(', ');
}

/// L'avversario nei gironi FIN collegati alla squadra: uno per girone.
class _CampionatiFin extends ConsumerWidget {
  const _CampionatiFin({
    required this.clubId,
    required this.gruppoId,
    required this.nomi,
  });

  final String clubId;
  final String? gruppoId;

  /// I nomi con cui cercarlo, nell'ordine.
  final List<String> nomi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collegati = ref.watch(gironiCollegatiProvider(clubId)).value;
    if (collegati == null) return const SizedBox.shrink();
    final gironi = gironiDellaSquadra(collegati, gruppoId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in gironi) _GironeAvversario(collegato: g, nomi: nomi),
      ],
    );
  }
}

class _GironeAvversario extends ConsumerWidget {
  const _GironeAvversario({required this.collegato, required this.nomi});

  final GironeCollegato collegato;
  final List<String> nomi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final lettura = ref.watch(gironeFinProvider(collegato.cmpId));
    final titolo = [
      collegato.campionato,
      collegato.faseEGirone,
    ].where((s) => s.isNotEmpty).join(' · ');

    final List<Widget> contenuto;
    if (lettura.value case final l?) {
      AvversarioNelGirone? trovato;
      for (final n in nomi) {
        trovato = avversarioNelGirone(
          l.girone,
          nome: n,
          nostra: collegato.squadra,
        );
        if (trovato != null) break;
      }
      contenuto = trovato == null
          ? [
              RiquadroVuoto(
                'Non trovo «${nomi.first}» fra le squadre di questo girone.',
                icona: Icons.search_off_outlined,
              ),
            ]
          : _avversario(context, trovato, daCopia: l.daCopia);
    } else if (lettura.hasError) {
      contenuto = const [
        RiquadroVuoto(
          'Il sito della FIN non risponde: riprova tra qualche minuto.',
          icona: Icons.cloud_off_outlined,
        ),
      ];
    } else {
      contenuto = const [LoadingSkeletonList(righe: 3)];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitoloSezione(
            titolo,
            spiegazione:
                'Dal sito della FIN Lombardia: la loro classifica, gli '
                'ultimi risultati contro tutte le squadre del girone e la '
                'prossima partita.',
          ),
          ...contenuto,
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8, left: 4),
            child: Text(
              'Fonte: FIN Lombardia',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _avversario(
    BuildContext context,
    AvversarioNelGirone a, {
    required bool daCopia,
  }) {
    final colori = context.colori;
    final r = a.riga;
    Widget riga(String sinistra, Widget destra, {String? sotto}) => Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sinistra,
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
                if (sotto != null && sotto.isNotEmpty)
                  Text(
                    sotto,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          destra,
        ],
      ),
    );
    Text numero(String t) => Text(
      t,
      style: AppTypography.numerica(
        AppTypography.corpoForte.copyWith(color: colori.testo),
      ),
    );

    final prossimo = a.prossimo;
    return [
      AppListPanel(
        righe: [
          if (r != null)
            riga(
              a.nomeFin,
              numero(
                a.squadre > 0
                    ? '${r.posizione}° di ${a.squadre}'
                    : '${r.posizione}°',
              ),
              sotto:
                  '${r.punti} punti · ${r.giocate} giocate '
                  '(${r.vinte} V, ${r.pareggiate} N, ${r.perse} P) · '
                  'gol ${r.golFatti}-${r.golSubiti}',
            )
          else
            riga(
              a.nomeFin,
              const SizedBox.shrink(),
              sotto: 'La FIN non ha ancora pubblicato la classifica.',
            ),
          for (final i in a.ultimi)
            riga(
              'vs ${a.controChi(i)}',
              Pastiglia(
                a.punteggioDi(i),
                colore: switch (a.esitoDi(i)) {
                  'V' => colori.ok,
                  'N' => colori.attenzione,
                  _ => colori.rosso,
                },
              ),
              sotto: i.data == null ? i.dataTesto : dataCompatta(i.data!),
            ),
          if (prossimo != null)
            riga(
              'Prossima: vs ${a.controChi(prossimo)}',
              const SizedBox.shrink(),
              sotto: [
                if (prossimo.data != null)
                  prossimo.ora == null
                      ? dataCompatta(prossimo.data!)
                      : '${dataCompatta(prossimo.data!)}, ore ${prossimo.ora}'
                else
                  ?prossimo.dataTesto,
                ?prossimo.piscina,
              ].join(' · '),
            ),
        ],
      ),
      if (daCopia)
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.s8),
          child: RiquadroVuoto(
            'Il sito della FIN non risponde: è l\'ultima classifica letta.',
            icona: Icons.cloud_off_outlined,
          ),
        ),
    ];
  }
}
