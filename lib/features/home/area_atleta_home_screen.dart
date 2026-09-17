import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/pace_format.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import '../../widgets/app_list_panel.dart';
import '../../widgets/app_list_row.dart';
import '../../widgets/athlete_avatar_circle.dart';
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
import '../pallanuoto/application/pallanuoto_providers.dart';
import '../pallanuoto/domain/partita.dart';
import '../pallanuoto/presentation/partite_atleta_list_screen.dart';
import '../pallanuoto/presentation/water_polo_tactics_board.dart';
import '../presenze/application/presenze_providers.dart';
import '../presenze/presentation/mie_presenze_screen.dart';
import '../stagioni/presentation/stagione_atleta_screen.dart';
import '../statistiche/presentation/statistiche_atleta_screen.dart';

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

String _etichettaSport(String? sport) => switch (sport) {
  'pallanuoto' => 'Pallanuoto',
  'nuoto_pallanuoto' => 'Nuoto e pallanuoto',
  _ => 'Nuoto',
};

/// Home/dashboard dell'atleta collegato (FASE 9, ridisegnata FASE 16):
/// mostrata da HomeScreen al posto delle tab da coach quando l'account
/// autenticato non e' membro di nessun club ma e' collegato a un record
/// atleti. Nessun Scaffold proprio: e' incorporata nel body di
/// HomeScreen, che ha gia' AppBar e pulsante "Esci".
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
              pallanuoto ? const _CardLavagnaTattica() : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            fascia(
              _CardProfiloAtleta(atleta: atleta),
              _CardTempiRecenti(atleta: atleta),
            ),
            const SizedBox(height: AppSpacing.s16),
            _CardRiepilogoClub(atleta: atleta),
            if (pallanuoto) ...[
              const SizedBox(height: AppSpacing.s16),
              _ProssimoEvento(clubId: atleta.clubId),
            ],
            const SizedBox(height: AppSpacing.s24),
            _AltriCollegamenti(atleta: atleta),
          ],
        ),
      ),
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
                const Expanded(child: SectionHeader('Andamento')),
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

class _CardLavagnaTattica extends StatelessWidget {
  const _CardLavagnaTattica();

  @override
  Widget build(BuildContext context) {
    return const PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader('Lavagna tattica'),
          SizedBox(height: AppSpacing.s12),
          WaterPoloTacticsBoard(),
        ],
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
                const Expanded(child: SectionHeader('I miei tempi')),
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
    final clubAsync = ref.watch(currentClubProvider);
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
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colori.azioneTenue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pool_outlined, color: colori.azione),
              ),
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
class _ProssimoEvento extends ConsumerWidget {
  const _ProssimoEvento({required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partitaAsync = ref.watch(prossimaPartitaProvider(clubId));

    return partitaAsync.when(
      data: (Partita? partita) {
        if (partita == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prossimo evento',
              style: AppTypography.etichetta.copyWith(
                color: context.colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppListPanel(
              righe: [
                AppListRow(
                  leading: const Icon(Icons.sports_outlined),
                  titolo:
                      '${partita.squadraCasa} - ${partita.squadraTrasferta}',
                  sottotitolo:
                      '${_formattaData(partita.data)}'
                      '${partita.ora != null ? ' · ${partita.ora}' : ''}'
                      '${partita.luogo != null ? ' · ${partita.luogo}' : ''}',
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
        if (pallanuoto)
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
                builder: (_) => PartiteAtletaListScreen(clubId: atleta.clubId),
              ),
            ),
          ),
      ],
    );
  }
}
