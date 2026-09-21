import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/pace_format.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import '../../theme/tokens_dominio.dart';
import '../../widgets/app_list_panel.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/athlete_avatar_circle.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/pool_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_panel.dart';
import '../allenamenti/application/allenamenti_providers.dart';
import '../atleti/application/personal_best_providers.dart';
import '../atleti/domain/atleta.dart';
import '../atleti/domain/pb_slots.dart';
import '../atleti/presentation/pb_list_screen.dart';
import '../carico/application/carico_providers.dart';
import '../carico/presentation/carico_atleta_screen.dart';
import '../carico/presentation/grafico_banister.dart';
import '../club/application/current_club_provider.dart';
import '../gare/application/gare_providers.dart';
import '../gare/domain/gara.dart';
import '../pallanuoto/application/pallanuoto_providers.dart';
import '../pallanuoto/application/schemi_tattici_providers.dart';
import '../pallanuoto/domain/partita.dart';
import '../pallanuoto/presentation/partite_atleta_list_screen.dart';
import '../pallanuoto/presentation/schemi_tattici_list_screen.dart';
import '../presenze/application/presenze_providers.dart';
import '../presenze/presentation/mie_presenze_screen.dart';
import '../stagioni/domain/evento_calendario.dart';
import '../stagioni/presentation/stagione_atleta_screen.dart';
import '../statistiche/presentation/statistiche_atleta_screen.dart';

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

String _etichettaSport(String? sport) => switch (sport) {
  'pallanuoto' => 'Pallanuoto',
  _ => 'Nuoto',
};

/// Home/dashboard dell'atleta collegato (FASE 9, ridisegnata FASE 16):
/// mostrata da HomeScreen al posto delle tab da coach quando l'account
/// autenticato non e' membro di nessun club ma e' collegato a un record
/// atleti. Nessun Scaffold proprio: e' incorporata nel body di
/// HomeScreen, che ha gia' AppBar e pulsante "Esci". Vedi anche
/// [AtletaDashboardScreen], che la incornicia con una AppBar propria
/// per raggiungerla anche dall'account allenatore.
///
/// Tre fasce (DESIGN.md sezione 10, `Breakpoint.of(context)` — mai
/// `MediaQuery` a mano): affiancate da `medio` in su, impilate su
/// telefono verticale.
/// 1. Andamento (grafico Banister) + Lavagna tattica (solo pallanuoto).
/// 2. Profilo atleta + I miei tempi (personal best).
/// 3. Riepilogo club + KPI (% presenze, prossimi allenamenti, gol per
///    pallanuoto).
class AreaAtletaHomeScreen extends ConsumerWidget {
  const AreaAtletaHomeScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallanuoto = atleta.sport == 'pallanuoto';
    final affiancate = Breakpoint.of(context) != Breakpoint.compatto;

    Widget fascia(Widget primo, Widget? secondo) {
      if (secondo == null) return primo;
      if (!affiancate) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primo,
            const SizedBox(height: AppSpacing.s16),
            secondo,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: primo),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: secondo),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fascia(
              _CardAndamento(atleta: atleta),
              pallanuoto
                  ? _CardLavagnaTattica(
                      clubId: atleta.clubId,
                      gruppoId: atleta.gruppoId,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            fascia(
              _CardProfiloAtleta(atleta: atleta),
              _CardTempiRecenti(atleta: atleta),
            ),
            const SizedBox(height: AppSpacing.s16),
            _CardRiepilogoClub(atleta: atleta),
            _ProssimiEventi(atleta: atleta),
            const SizedBox(height: AppSpacing.s24),
            _AltriCollegamenti(atleta: atleta),
          ],
        ),
      ),
    );
  }
}

/// Incornicia [AreaAtletaHomeScreen] con una AppBar propria (titolo e
/// pulsante indietro), per raggiungerla come schermata a parte —
/// dall'account allenatore, toccando il nome di un atleta in
/// `AtletiListScreen`. [AreaAtletaHomeScreen] da sola non ha Scaffold
/// perché è pensata per stare già dentro quello di `HomeScreen`
/// (usato invece quando è l'atleta stesso ad autenticarsi).
class AtletaDashboardScreen extends StatelessWidget {
  const AtletaDashboardScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(atleta.nomeCompleto)),
      body: AreaAtletaHomeScreen(atleta: atleta),
    );
  }
}

/// Card "Andamento": grafico Banister compatto, tocco apre il dettaglio
/// completo (`CaricoAtletaScreen`, con anche la scomposizione per
/// volume).
class _CardAndamento extends ConsumerWidget {
  const _CardAndamento({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntiAsync = ref.watch(
      andamentoCaricoProvider((atletaId: atleta.id, clubId: atleta.clubId)),
    );
    final colori = context.colori;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pannello),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CaricoAtletaScreen(atleta: atleta)),
      ),
      child: PoolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  Icons.show_chart,
                  colore: context.dominio.evidenzaCiano,
                ),
                const SizedBox(width: AppSpacing.s12),
                const Expanded(
                  child: SectionHeader(
                    'Andamento',
                    spiegazione:
                        'Il grafico Banister: tre curve calcolate dagli '
                        'allenamenti a cui hai partecipato. Fitness cresce '
                        'con il carico accumulato nel tempo, Fatica cresce '
                        'più in fretta ma si scarica anche più in fretta, '
                        'Forma è la differenza fra le due — più alta è, '
                        'più sei pronto per una prestazione.',
                  ),
                ),
                Icon(Icons.chevron_right, color: colori.testoSecondario),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            puntiAsync.when(
              data: (punti) => punti.isEmpty
                  ? Text(
                      'Nessun dato ancora: si calcola dagli allenamenti con '
                      'presenza segnata.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    )
                  : SizedBox(height: 160, child: GraficoBanister(punti: punti)),
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Text(
                'Non disponibile al momento.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anteprima degli schemi tattici salvati dall'allenatore: a differenza
/// della vecchia lavagna libera (locale, effimera), qui l'atleta
/// sfoglia in sola lettura ciò che l'allenatore ha disegnato e salvato
/// — il tocco sulla card apre l'elenco completo
/// (`SchemiTatticiListScreen` con `soloLettura: true`).
class _CardLavagnaTattica extends ConsumerWidget {
  const _CardLavagnaTattica({required this.clubId, this.gruppoId});

  final String clubId;
  final String? gruppoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuttiGliSchemi = ref.watch(schemiTatticiListProvider(clubId));
    // Stessa regola di isolamento per gruppo delle liste del coach: uno
    // schema senza gruppo resta visibile a tutti.
    final schemiAsync = gruppoId == null
        ? tuttiGliSchemi
        : tuttiGliSchemi.whenData(
            (schemi) => schemi
                .where((s) => s.gruppoId == gruppoId || s.gruppoId == null)
                .toList(),
          );
    final colori = context.colori;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pannello),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SchemiTatticiListScreen(
            clubId: clubId,
            soloLettura: true,
            filtroGruppoId: gruppoId,
          ),
        ),
      ),
      child: PoolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  Icons.route_outlined,
                  colore: context.dominio.evidenzaVerde,
                ),
                const SizedBox(width: AppSpacing.s12),
                const Expanded(
                  child: SectionHeader(
                    'Schemi tattici',
                    spiegazione:
                        'Gli schemi che il tuo allenatore ha disegnato e '
                        'salvato sulla lavagna tattica: posizioni dei '
                        'giocatori e frecce di movimento, anche in più '
                        'passi in sequenza. Tocca per sfogliarli.',
                  ),
                ),
                Icon(Icons.chevron_right, color: colori.testoSecondario),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            schemiAsync.when(
              data: (schemi) => Text(
                schemi.isEmpty
                    ? 'L\'allenatore non ha ancora salvato nessuno schema.'
                    : schemi.length == 1
                    ? '1 schema salvato dall\'allenatore.'
                    : '${schemi.length} schemi salvati dall\'allenatore.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              loading: () => Text(
                'Caricamento...',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              error: (_, _) => Text(
                'Non è stato possibile caricare gli schemi.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card profilo: avatar a iniziali, nome, sport, e le metriche chiave —
/// personal best per il nuoto, gol/tiri per la pallanuoto (le uniche
/// tracciate davvero: l'app non registra assist/steal né uno storico
/// dello stroke rate, vedi ROADMAP.md FASE 16).
class _CardProfiloAtleta extends StatelessWidget {
  const _CardProfiloAtleta({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final pallanuoto = atleta.sport == 'pallanuoto';

    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AthleteAvatarCircle(nome: atleta.nome, cognome: atleta.cognome),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atleta.nomeCompleto,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colori.azioneTenue,
                        borderRadius: BorderRadius.circular(AppRadius.pillola),
                      ),
                      child: Text(
                        _etichettaSport(atleta.sport),
                        style: AppTypography.etichetta.copyWith(
                          color: colori.azione,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          if (pallanuoto)
            _MetricheWaterPolo(atleta: atleta)
          else
            _MetricheNuoto(atleta: atleta),
        ],
      ),
    );
  }
}

class _MetricheNuoto extends ConsumerWidget {
  const _MetricheNuoto({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync = ref.watch(personalBestListProvider(atleta.id));
    final colori = context.colori;

    return pbAsync.when(
      data: (pb) {
        if (pb.isEmpty) {
          return Text(
            'Nessun personal best registrato ancora.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          );
        }
        final ordinati = [...pb]..sort((a, b) => a.stile.compareTo(b.stile));
        return Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s12,
          children: [
            for (final p in ordinati.take(2))
              StatPanel(
                etichetta: '${p.distanzaM}m ${capitalizzaParola(p.stile)}',
                valore: formatPaceSeconds(p.tempoS),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Non disponibile al momento.',
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
    );
  }
}

class _MetricheWaterPolo extends ConsumerWidget {
  const _MetricheWaterPolo({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiriAsync = ref.watch(tiriAtletaProvider(atleta.id));

    return tiriAsync.when(
      data: (tiri) {
        final gol = tiri
            .where((e) => e.tipo == 'tiro' && e.esito == 'gol')
            .length;
        return Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s12,
          children: [
            StatPanel(etichetta: 'Gol', valore: '$gol'),
            StatPanel(etichetta: 'Tiri', valore: '${tiri.length}'),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Non disponibile al momento.',
        style: AppTypography.piccolo.copyWith(
          color: context.colori.testoSecondario,
        ),
      ),
    );
  }
}

/// Card "I miei tempi": i cinque personal best più recenti in
/// ordine di stile/distanza, formato compatto per tablet. Tocco apre
/// l'elenco completo (`PbListScreen`, con tutte le combinazioni
/// possibili per lo sport, registrate o no).
class _CardTempiRecenti extends ConsumerWidget {
  const _CardTempiRecenti({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync = ref.watch(personalBestListProvider(atleta.id));
    final colori = context.colori;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pannello),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PbListScreen(atleta: atleta))),
      child: PoolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  Icons.timer_outlined,
                  colore: context.dominio.evidenzaAmbra,
                ),
                const SizedBox(width: AppSpacing.s12),
                const Expanded(
                  child: SectionHeader(
                    'I miei tempi',
                    spiegazione:
                        'I tuoi ultimi personal best registrati, per stile '
                        'e distanza. Tocca per vedere l\'elenco completo e '
                        'aggiungerne di nuovi.',
                  ),
                ),
                Icon(Icons.chevron_right, color: colori.testoSecondario),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            pbAsync.when(
              data: (pb) {
                if (pb.isEmpty) {
                  return Text(
                    'Nessun tempo registrato ancora.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  );
                }
                final ordinati = [...pb]
                  ..sort((a, b) {
                    final perStile = a.stile.compareTo(b.stile);
                    return perStile != 0
                        ? perStile
                        : a.distanzaM.compareTo(b.distanzaM);
                  });
                return Column(
                  children: [
                    for (final p in ordinati.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.distanzaM}m ${capitalizzaParola(p.stile)}',
                                style: AppTypography.corpo.copyWith(
                                  color: colori.testo,
                                ),
                              ),
                            ),
                            Text(
                              formatPaceSeconds(p.tempoS),
                              style: AppTypography.corpoForte.copyWith(
                                color: colori.testo,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Text(
                'Non disponibile al momento.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Riepilogo del club (nome, sport) e KPI — % presenze e prossimi
/// allenamenti già calcolati come nella versione precedente di questa
/// schermata, più i gol totali per la pallanuoto.
class _CardRiepilogoClub extends ConsumerWidget {
  const _CardRiepilogoClub({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubAtletaProvider(atleta.clubId));
    final presenzeAsync = ref.watch(presenzePerAtletaProvider(atleta.id));
    final allenamentiAsync = ref.watch(
      allenamentiAtletaProvider(atleta.clubId),
    );
    final colori = context.colori;

    String? percentuale;
    var prossimi7Giorni = 0;
    if (allenamentiAsync.hasValue) {
      final allenamenti = allenamentiAsync.value!;
      final haGruppo = atleta.gruppoId != null;
      final delGruppo = haGruppo
          ? allenamenti.where((a) => a.gruppoId == atleta.gruppoId).toList()
          : allenamenti;
      final rilevanti = delGruppo.isEmpty ? allenamenti : delGruppo;
      final oggi = DateTime.now();
      final inizio = DateTime(oggi.year, oggi.month, oggi.day);
      final fine = inizio.add(const Duration(days: 7));
      prossimi7Giorni = rilevanti
          .where((a) => !a.data.isBefore(inizio) && a.data.isBefore(fine))
          .length;
      if (presenzeAsync.hasValue && rilevanti.isNotEmpty) {
        final idRilevanti = rilevanti.map((a) => a.id).toSet();
        final presenti = presenzeAsync.value!
            .where(
              (p) =>
                  p.stato == 'presente' &&
                  idRilevanti.contains(p.allenamentoId),
            )
            .length;
        percentuale = '${(presenti / rilevanti.length * 100).round()}%';
      }
    }

    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.pool_outlined),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: clubAsync.when(
                  data: (club) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club?.nome ?? 'Il tuo club',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _etichettaSport(club?.sport),
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s24,
            runSpacing: AppSpacing.s12,
            children: [
              StatPanel(etichetta: '% presenze', valore: percentuale ?? '—'),
              StatPanel(
                etichetta: 'Prossimi 7 giorni',
                valore: '$prossimi7Giorni',
              ),
              if (atleta.sport == 'pallanuoto') _GolTotaliStat(atleta: atleta),
            ],
          ),
        ],
      ),
    );
  }
}

class _GolTotaliStat extends ConsumerWidget {
  const _GolTotaliStat({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiriAsync = ref.watch(tiriAtletaProvider(atleta.id));
    final gol =
        tiriAsync.value
            ?.where((e) => e.tipo == 'tiro' && e.esito == 'gol')
            .length ??
        0;
    return StatPanel(etichetta: 'Gol totali', valore: '$gol');
  }
}

/// Prossima partita in agenda per il club (solo atleti di pallanuoto).
class _ProssimiEventi extends ConsumerWidget {
  const _ProssimiEventi({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallanuoto = atleta.sport == 'pallanuoto';
    final eventi = pallanuoto
        ? [
            for (final p
                in ref.watch(partiteListProvider(atleta.clubId)).value ??
                    const <Partita>[])
              EventoCalendario.daPartita(p),
          ]
        : [
            for (final g
                in ref.watch(gareListProvider(atleta.clubId)).value ??
                    const <Gara>[])
              EventoCalendario.daGara(g),
          ];
    final prossimi = prossimiEventi(eventi, atleta.gruppoId, DateTime.now());
    if (prossimi.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prossimi eventi',
            style: AppTypography.etichetta.copyWith(
              color: context.colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          AppListPanel(
            righe: [
              for (final e in prossimi)
                AppListRow(
                  leading: Icon(
                    pallanuoto
                        ? Icons.sports_outlined
                        : Icons.emoji_events_outlined,
                  ),
                  titolo: e.titolo,
                  sottotitolo:
                      '${_formattaData(e.data)}'
                      '${e.sottotitolo != null ? ' · ${e.sottotitolo}' : ''}'
                      '${e.diClub ? ' · Tutto il club' : ''}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Collegamenti non già raggiungibili dalle card sopra.
class _AltriCollegamenti extends StatelessWidget {
  const _AltriCollegamenti({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    final pallanuoto = atleta.sport == 'pallanuoto';
    return AppListPanel(
      righe: [
        AppListRow(
          leading: const Icon(Icons.how_to_reg_outlined),
          titolo: 'Le mie presenze',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MiePresenzeScreen(atleta: atleta),
            ),
          ),
        ),
        AppListRow(
          leading: const Icon(Icons.event_note_outlined),
          titolo: 'La mia stagione',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StagioneAtletaScreen(atleta: atleta),
            ),
          ),
        ),
        AppListRow(
          leading: const Icon(Icons.bar_chart_outlined),
          titolo: 'Le mie statistiche',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StatisticheAtletaScreen(atleta: atleta),
            ),
          ),
        ),
        if (pallanuoto)
          AppListRow(
            leading: const Icon(Icons.sports_outlined),
            titolo: 'Le mie partite',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartiteAtletaListScreen(
                  clubId: atleta.clubId,
                  filtroGruppoId: atleta.gruppoId,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
