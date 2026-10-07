import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/griglia_azioni.dart';
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/presentation/atleta_form_screen.dart';
import '../../benessere/presentation/benessere_squadra.dart';
import '../../club/domain/club.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/presentation/distinta_screen.dart';
import '../../pallanuoto/presentation/partita_form_screen.dart';
import '../../pallanuoto/presentation/partita_live_screen.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../atleta/grafica_pallanuoto.dart';
import '../atleta/home_atleta_widgets.dart';

bool _stessoGiorno(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Oggi": la prima scheda dell'allenatore. In un colpo d'occhio la
/// squadra, cosa c'e' in programma, chi sta male e cosa c'e' da
/// sistemare; le azioni di tutti i giorni sono a un tocco.
class CruscottoAllenatoreScreen extends ConsumerWidget {
  const CruscottoAllenatoreScreen({
    required this.club,
    required this.gruppoId,
    required this.onVaiATab,
    super.key,
  });

  final Club club;
  final String? gruppoId;

  /// Porta a una delle altre schede (per indice nella barra).
  final void Function(TabCruscotto) onVaiATab;

  void _apri(BuildContext context, Widget schermata) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => schermata));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final dominio = context.dominio;
    final pallanuoto = club.sport != 'nuoto';
    final oggi = DateTime.now();
    final inizio = DateTime(oggi.year, oggi.month, oggi.day);

    final gruppi = ref.watch(gruppiListProvider(club.id)).value ?? const [];
    final nomeSquadra =
        gruppi.where((g) => g.id == gruppoId).map((g) => g.nome).firstOrNull ??
        'Tutti gli atleti';
    final atleti =
        (ref
                    .watch(
                      atletiListProvider((
                        clubId: club.id,
                        includeInactive: false,
                      )),
                    )
                    .value ??
                const <Atleta>[])
            .where((a) => gruppoId == null || a.gruppoId == gruppoId)
            .toList();

    final allenamenti =
        (ref.watch(allenamentiListProvider(club.id)).value ??
                const <Allenamento>[])
            .where(
              (a) =>
                  !a.data.isBefore(inizio) &&
                  visibileNelGruppo(
                    gruppoDelRecord: a.gruppoId,
                    gruppoSelezionato: gruppoId,
                  ),
            )
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    final prossimoAllenamento = allenamenti.firstOrNull;
    final allenamentoOggi = allenamenti
        .where((a) => _stessoGiorno(a.data, oggi))
        .firstOrNull;

    final partite = pallanuoto
        ? ((ref.watch(partiteListProvider(club.id)).value ?? const <Partita>[])
              .where(
                (p) =>
                    !p.data.isBefore(inizio) &&
                    visibileNelGruppo(
                      gruppoDelRecord: p.gruppoId,
                      gruppoSelezionato: gruppoId,
                    ),
              )
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data)))
        : const <Partita>[];
    final prossimaPartita = partite.firstOrNull;
    final partitaOggi = partite
        .where((p) => _stessoGiorno(p.data, oggi))
        .firstOrNull;

    final visiteScadute = atleti.where((a) => a.visitaMedicaScaduta).toList();
    final visiteInScadenza = atleti
        .where((a) => !a.visitaMedicaScaduta && a.visitaMedicaInScadenza)
        .toList();
    final senzaConsenso = atleti
        .where((a) => !a.consensoPrivacyFirmato)
        .toList();

    final azioni = <AzioneRapida>[
      if (allenamentoOggi != null)
        AzioneRapida(
          icona: Icons.how_to_reg,
          titolo: 'Segna le presenze',
          sottotitolo: 'Allenamento di oggi',
          colore: dominio.evidenzaVerde,
          evidenziata: true,
          onTap: () =>
              _apri(context, PresenzeScreen(allenamento: allenamentoOggi)),
        ),
      if (partitaOggi != null)
        AzioneRapida(
          icona: Icons.play_circle_fill,
          titolo: 'Partita dal vivo',
          sottotitolo: 'Segna tiri e gol',
          colore: colori.rosso,
          evidenziata: true,
          onTap: () => _apri(context, PartitaLiveScreen(partita: partitaOggi)),
        ),
      AzioneRapida(
        icona: Icons.add_task,
        titolo: 'Nuovo allenamento',
        sottotitolo: 'Scrivilo, dettalo o generalo',
        colore: dominio.evidenzaCiano,
        onTap: () =>
            _apri(context, GeneraAllenamentoFormScreen(clubId: club.id)),
      ),
      if (pallanuoto)
        AzioneRapida(
          icona: Icons.sports_handball,
          titolo: 'Nuova partita',
          sottotitolo: 'Data, avversario, piscina',
          colore: dominio.evidenzaAmbra,
          onTap: () => _apri(context, PartitaFormScreen(clubId: club.id)),
        ),
      if (pallanuoto && prossimaPartita != null && partitaOggi == null)
        AzioneRapida(
          icona: Icons.format_list_numbered,
          titolo: 'Convocazioni',
          sottotitolo: 'Distinta della prossima partita',
          colore: dominio.evidenzaViola,
          onTap: () => _apri(context, DistintaScreen(partita: prossimaPartita)),
        ),
      AzioneRapida(
        icona: Icons.person_add_alt_1,
        titolo: 'Nuovo atleta',
        sottotitolo: 'Aggiungilo alla squadra',
        colore: colori.azione,
        onTap: () => _apri(context, AtletaFormScreen(clubId: club.id)),
      ),
    ];

    var i = 0;
    Widget blocco(Widget figlio) => EntrataACascata(indice: i++, child: figlio);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              blocco(
                _TestataSquadra(
                  club: club,
                  nomeSquadra: nomeSquadra,
                  atleti: atleti.length,
                  allenamentiSettimana: allenamenti
                      .where(
                        (a) => a.data.isBefore(
                          inizio.add(const Duration(days: 7)),
                        ),
                      )
                      .length,
                  partiteMese: partite
                      .where(
                        (p) => p.data.isBefore(
                          inizio.add(const Duration(days: 30)),
                        ),
                      )
                      .length,
                  pallanuoto: pallanuoto,
                  onAtleti: () => onVaiATab(TabCruscotto.atleti),
                  onAllenamenti: () => onVaiATab(TabCruscotto.allenamenti),
                  onPartite: () => onVaiATab(TabCruscotto.eventi),
                ),
              ),
              const SizedBox(height: 20),
              blocco(const TitoloSezione('Cosa vuoi fare?')),
              blocco(GrigliaAzioni(azioni: azioni)),
              const SizedBox(height: 20),
              blocco(const TitoloSezione('In programma')),
              if (prossimaPartita != null) ...[
                blocco(
                  CardProssimaPartita(
                    partita: prossimaPartita,
                    onTap: () => onVaiATab(TabCruscotto.eventi),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              blocco(
                _CardAllenamentoAllenatore(
                  allenamento: prossimoAllenamento,
                  onApri: prossimoAllenamento == null
                      ? () => _apri(
                          context,
                          GeneraAllenamentoFormScreen(clubId: club.id),
                        )
                      : () => _apri(
                          context,
                          AllenamentoDetailScreen(
                            allenamento: prossimoAllenamento,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              blocco(const TitoloSezione('La squadra oggi')),
              blocco(CardBenessereSquadra(clubId: club.id, gruppoId: gruppoId)),
              if (visiteScadute.isNotEmpty ||
                  visiteInScadenza.isNotEmpty ||
                  senzaConsenso.isNotEmpty) ...[
                const SizedBox(height: 12),
                blocco(
                  _CardDaSistemare(
                    clubId: club.id,
                    visiteScadute: visiteScadute,
                    visiteInScadenza: visiteInScadenza,
                    senzaConsenso: senzaConsenso,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Le schede raggiungibili dal cruscotto: `HomeScreen` le traduce
/// nell'indice della barra.
enum TabCruscotto { atleti, allenamenti, eventi }

class _TestataSquadra extends StatelessWidget {
  const _TestataSquadra({
    required this.club,
    required this.nomeSquadra,
    required this.atleti,
    required this.allenamentiSettimana,
    required this.partiteMese,
    required this.pallanuoto,
    required this.onAtleti,
    required this.onAllenamenti,
    required this.onPartite,
  });

  final Club club;
  final String nomeSquadra;
  final int atleti;
  final int allenamentiSettimana;
  final int partiteMese;
  final bool pallanuoto;
  final VoidCallback onAtleti;
  final VoidCallback onAllenamenti;
  final VoidCallback onPartite;

  String _saluto() {
    final ora = DateTime.now().hour;
    if (ora < 13) return 'Buongiorno, coach';
    if (ora < 18) return 'Buon pomeriggio, coach';
    return 'Buonasera, coach';
  }

  @override
  Widget build(BuildContext context) {
    final stretto = MediaQuery.sizeOf(context).width < 600;
    // Nome e periodo su due righe separate: "Allenamenti in 7 giorni" su
    // una riga sola, su telefono, si rimpiccioliva fino a non leggersi.
    Widget numero(
      String valore,
      String etichetta,
      VoidCallback onTap, {
      String? periodo,
    }) => Expanded(
      child: Premibile(
        onTap: onTap,
        etichetta: '$etichetta ${periodo ?? ''}: $valore',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(
                valore,
                style: AppTypography.numerica(
                  AppTypography.numeroMedio.copyWith(
                    color: AcquaPalette.bianco,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  etichetta,
                  maxLines: 1,
                  style: AppTypography.etichetta.copyWith(
                    color: AcquaPalette.schiuma.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  periodo ?? 'nel gruppo',
                  maxLines: 1,
                  style: AppTypography.etichetta.copyWith(
                    fontSize: 11,
                    color: AcquaPalette.schiuma.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(child: AcquaAnimata(conCorsia: false)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AcquaPalette.profonda.withValues(alpha: 0.9),
                    AcquaPalette.profonda.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(stretto ? 18 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (pallanuoto) ...[
                      SizedBox(
                        width: stretto ? 76 : 104,
                        height: stretto ? 48 : 64,
                        child: Stack(
                          children: [
                            for (final (k, c) in const [
                              ColoreCalottina.bianca,
                              ColoreCalottina.blu,
                              ColoreCalottina.rossa,
                            ].indexed)
                              Positioned(
                                left: k * (stretto ? 18.0 : 24.0),
                                child: Calottina(
                                  colore: c,
                                  dimensione: stretto ? 46 : 62,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _saluto(),
                        style: AppTypography.piccolo.copyWith(
                          color: AcquaPalette.schiuma.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  nomeSquadra,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (stretto ? AppTypography.titoloXl : AppTypography.display)
                          .copyWith(
                            color: AcquaPalette.bianco,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                ),
                const SizedBox(height: 4),
                Text(
                  club.nome,
                  style: AppTypography.corpo.copyWith(
                    color: AcquaPalette.schiuma.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: stretto ? 16 : 22),
                Container(
                  decoration: BoxDecoration(
                    color: AcquaPalette.bianco.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AcquaPalette.bianco.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      numero('$atleti', 'Atleti', onAtleti),
                      numero(
                        '$allenamentiSettimana',
                        'Allenamenti',
                        onAllenamenti,
                        periodo: 'prossimi 7 giorni',
                      ),
                      if (pallanuoto)
                        numero(
                          '$partiteMese',
                          'Partite',
                          onPartite,
                          periodo: 'prossimi 30 giorni',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAllenamentoAllenatore extends ConsumerWidget {
  const _CardAllenamentoAllenatore({
    required this.allenamento,
    required this.onApri,
  });

  final Allenamento? allenamento;
  final VoidCallback onApri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final a = allenamento;
    final accento = context.dominio.evidenzaCiano;
    return Premibile(
      onTap: onApri,
      etichetta: a == null
          ? 'Nessun allenamento in programma: creane uno'
          : 'Prossimo allenamento ${dataEstesa(a.data)}: apri',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accento.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: a == null
                  ? Icon(Icons.add, color: accento)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dataEstesa(a.data).split(' ').last.toUpperCase(),
                          style: AppTypography.etichetta.copyWith(
                            color: accento,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        Text(
                          '${a.data.day}',
                          style: AppTypography.numerica(
                            AppTypography.titolo.copyWith(
                              color: accento,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prossimo allenamento',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  Text(
                    a == null
                        ? 'Nessuno in programma'
                        : a.titolo ?? 'Allenamento',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  Text(
                    a == null
                        ? 'Tocca per programmarne uno'
                        : '${traQuanto(a.data)}, ${dataEstesa(a.data)}',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colori.testoSecondario),
          ],
        ),
      ),
    );
  }
}

class _CardDaSistemare extends StatelessWidget {
  const _CardDaSistemare({
    required this.clubId,
    required this.visiteScadute,
    required this.visiteInScadenza,
    required this.senzaConsenso,
  });

  final String clubId;
  final List<Atleta> visiteScadute;
  final List<Atleta> visiteInScadenza;
  final List<Atleta> senzaConsenso;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget voce(
      IconData icona,
      Color colore,
      String titolo,
      List<Atleta> atleti,
    ) {
      if (atleti.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icona, size: 18, color: colore),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$titolo (${atleti.length})',
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in atleti)
                  ActionChip(
                    label: Text(a.nomeCompleto),
                    avatar: Icon(Icons.edit_outlined, size: 16, color: colore),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AtletaFormScreen(clubId: clubId, atleta: a),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colori.attenzione.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checklist, color: colori.attenzione),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Da sistemare',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    Text(
                      'Tocca un nome per aggiornare la sua anagrafica',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          voce(
            Icons.medical_information_outlined,
            colori.rosso,
            'Visita medica scaduta',
            visiteScadute,
          ),
          voce(
            Icons.event_busy_outlined,
            colori.attenzione,
            'Visita medica in scadenza',
            visiteInScadenza,
          ),
          voce(
            Icons.privacy_tip_outlined,
            colori.azione,
            'Consenso privacy da firmare',
            senzaConsenso,
          ),
        ],
      ),
    );
  }
}
