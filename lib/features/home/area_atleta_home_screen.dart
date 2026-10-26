import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/gruppo_visibilita.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import '../../theme/tokens_dominio.dart';
import '../../widgets/section_header.dart';
import '../atleti/application/personal_best_providers.dart';
import '../atleti/domain/atleta.dart';
import '../atleti/domain/squadre_atleta.dart';
import '../atleti/presentation/atleta_form_screen.dart';
import '../atleti/presentation/pb_list_screen.dart';
import '../carico/application/carico_providers.dart';
import '../carico/presentation/card_rpe.dart';
import '../carico/presentation/carico_atleta_screen.dart';
import '../carico/presentation/grafico_banister.dart';
import '../pallanuoto/application/pallanuoto_providers.dart';
import '../pallanuoto/application/schemi_tattici_providers.dart';
import '../pallanuoto/presentation/partite_atleta_list_screen.dart';
import '../pallanuoto/presentation/schemi_tattici_list_screen.dart';
import '../presenze/presentation/mie_presenze_screen.dart';
import '../referti/application/referti_providers.dart';
import '../statistiche/application/statistiche_providers.dart';
import '../secco/presentation/card_secco_da_fare.dart';
import '../stagioni/presentation/stagione_atleta_screen.dart';
import 'atleta/card_settimana.dart';
import '../statistiche/presentation/statistiche_atleta_screen.dart';
import '../allenamenti/domain/allenamento.dart';
import '../benessere/presentation/card_benessere.dart';
import '../benessere/presentation/scheda_benessere_screen.dart';
import '../pallanuoto/domain/convocazione.dart';
import '../pallanuoto/domain/partita.dart';
import 'atleta/allenamenti_squadre_screen.dart';
import 'atleta/dati_home_atleta.dart';
import 'atleta/grafica_pallanuoto.dart';
import 'atleta/home_atleta_widgets.dart';

/// Home/dashboard dell'atleta collegato (FASE 9, ridisegnata FASE 16 e
/// poi di nuovo per la pallanuoto): mostrata da HomeScreen al posto delle
/// tab da coach quando l'account autenticato e' collegato a un record
/// atleti. Nessun Scaffold proprio: e' incorporata nel body di
/// HomeScreen (in alto c'e' la barra fissa con logo, nome del club e menu
/// con "Esci"). Vedi anche [AtletaDashboardScreen].
///
/// Dall'alto:
/// 1. Testata con la foto della vasca, calottina col numero, nome e i
///    numeri chiave (toccabili).
/// 2. Scheda benessere del giorno, prossima partita (tabellone) e
///    prossimo allenamento.
/// 3. Andamento (grafico Banister).
/// 4. Riquadri illustrati verso tutte le altre sezioni.
class AreaAtletaHomeScreen extends ConsumerWidget {
  const AreaAtletaHomeScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;

  /// true quando e' l'allenatore ad aprire l'atleta dal proprio elenco:
  /// la scheda benessere si legge soltanto, con gli ultimi giorni.
  final bool vistaAllenatore;

  /// Il primo impegno in arrivo fra allenamento e partita, a cui si
  /// riferisce la scheda benessere.
  ImpegnoBenessere? _impegno(Allenamento? allenamento, Partita? partita) {
    ImpegnoBenessere? daAllenamento() => allenamento == null
        ? null
        : (
            tipo: 'allenamento',
            id: allenamento.id,
            descrizione:
                'dell\'allenamento di ${traQuanto(allenamento.data).toLowerCase() == 'oggi' ? 'oggi' : dataEstesa(allenamento.data)}',
          );
    ImpegnoBenessere? daPartita() => partita == null
        ? null
        : (
            tipo: 'partita',
            id: partita.id,
            descrizione:
                'della partita di ${traQuanto(partita.data).toLowerCase() == 'oggi' ? 'oggi' : dataEstesa(partita.data)}',
          );
    if (allenamento == null) return daPartita();
    if (partita == null) return daAllenamento();
    return partita.data.isBefore(allenamento.data)
        ? daPartita()
        : daAllenamento();
  }

  void _apri(BuildContext context, Widget schermata) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => schermata));

  /// La convocazione della prossima partita, solo quando l'allenatore
  /// l'ha inviata e l'atleta e' fra i convocati.
  ConvocazioneInScheda? _convocazione(WidgetRef ref, Partita? partita) {
    if (partita == null || !partita.convocazioneInviata) return null;
    final mia = ref
        .watch(distintaListProvider(partita.id))
        .value
        ?.where((g) => g.atletaId == atleta.id)
        .firstOrNull;
    if (mia == null) return null;
    final convocato = atleta.sesso == 'F' ? 'convocata' : 'convocato';
    return (
      titolo: vistaAllenatore
          ? '${convocato[0].toUpperCase()}${convocato.substring(1)} con il '
                'numero ${mia.numeroCalottina}'
          : 'Sei $convocato con il numero ${mia.numeroCalottina}',
      voci: vociConvocazioneAtleta(partita),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallanuoto = atleta.sport == 'pallanuoto';
    final dominio = context.dominio;
    // Il portiere non segna: al posto di gol e tiri, parate e gol subiti
    // (i gol che segna, se capita, stanno solo nelle statistiche).
    final portiere = pallanuoto && atleta.portiere;
    final golTiri = portiere
        ? null
        : ref.watch(
            golTiriAtletaProvider((atletaId: atleta.id, clubId: atleta.clubId)),
          );
    final numeriPortiere = portiere
        ? ref.watch(numeriPortiereAtletaProvider(atleta.id))
        : null;
    final allenamenti = ref.watch(riepilogoAllenamentiAtletaProvider(atleta));
    final partita = pallanuoto
        ? ref.watch(prossimaPartitaAtletaProvider(atleta))
        : null;
    final convocazione = _convocazione(ref, partita);
    final pb = ref.watch(personalBestListProvider(atleta.id)).value;
    final schemi = pallanuoto
        ? ref
              .watch(schemiTatticiListProvider(atleta.clubId))
              .value
              ?.where(
                (s) => visibileNelGruppoMultiplo(
                  gruppiDelRecord: s.gruppoIds,
                  gruppoSelezionato: atleta.gruppoId,
                ),
              )
              .length
        : null;

    final presenze = allenamenti?.percentualePresenze;
    final gol = golTiri?.gol;
    final tiri = golTiri?.tiri;
    // Gol anche dai referti, precisione solo dal vivo.
    final precisione = precisioneDalVivo(golTiri);

    void apriStatistiche() =>
        _apri(context, StatisticheAtletaScreen(atleta: atleta));

    final statistiche = portiere
        ? [
            (
              etichetta: 'Parate',
              valore: numeriPortiere == null ? '—' : '${numeriPortiere.parate}',
              onTap: apriStatistiche,
            ),
            (
              etichetta: 'Gol subiti',
              valore: numeriPortiere == null
                  ? '—'
                  : '${numeriPortiere.golSubiti}',
              onTap: apriStatistiche,
            ),
            (
              etichetta: '% parate',
              valore: numeriPortiere?.percentualeParate == null
                  ? '—'
                  : '${numeriPortiere!.percentualeParate}%',
              onTap: apriStatistiche,
            ),
            (
              etichetta: 'Presenze',
              valore: presenze == null ? '—' : '$presenze%',
              onTap: () => _apri(
                context,
                MiePresenzeScreen(
                  atleta: atleta,
                  vistaAllenatore: vistaAllenatore,
                ),
              ),
            ),
          ]
        : pallanuoto
        ? [
            (
              etichetta: 'Gol',
              valore: gol == null ? '—' : '$gol',
              onTap: () =>
                  _apri(context, StatisticheAtletaScreen(atleta: atleta)),
            ),
            (
              etichetta: 'Tiri',
              valore: tiri == null ? '—' : '$tiri',
              onTap: () =>
                  _apri(context, StatisticheAtletaScreen(atleta: atleta)),
            ),
            (
              etichetta: 'Precisione',
              valore: precisione == null ? '—' : '$precisione%',
              onTap: () =>
                  _apri(context, StatisticheAtletaScreen(atleta: atleta)),
            ),
            (
              etichetta: 'Presenze',
              valore: presenze == null ? '—' : '$presenze%',
              onTap: () => _apri(
                context,
                MiePresenzeScreen(
                  atleta: atleta,
                  vistaAllenatore: vistaAllenatore,
                ),
              ),
            ),
          ]
        : [
            (
              etichetta: 'Personal best',
              valore: pb == null ? '—' : '${pb.length}',
              onTap: () => _apri(context, PbListScreen(atleta: atleta)),
            ),
            (
              etichetta: 'Presenze',
              valore: presenze == null ? '—' : '$presenze%',
              onTap: () => _apri(
                context,
                MiePresenzeScreen(
                  atleta: atleta,
                  vistaAllenatore: vistaAllenatore,
                ),
              ),
            ),
          ];

    // Aperta dall'allenatore ("Tutto su Sofia") i titoli non sono in prima
    // persona: "Statistiche", non "Le mie statistiche".
    String titolo(String mio, String suo) => vistaAllenatore ? suo : mio;

    final riquadri = <VoceRiquadro>[
      if (pallanuoto) ...[
        VoceRiquadro(
          soggetto: SoggettoRiquadro.schemi,
          titolo: 'Schemi tattici',
          descrizione: 'Le azioni preparate dall\'allenatore',
          valore: schemi == null || schemi == 0 ? null : '$schemi',
          accento: dominio.evidenzaVerde,
          onTap: () => _apri(
            context,
            SchemiTatticiListScreen(
              clubId: atleta.clubId,
              soloLettura: true,
              filtroGruppoId: atleta.gruppoId,
            ),
          ),
        ),
        VoceRiquadro(
          soggetto: SoggettoRiquadro.partite,
          titolo: titolo('Le mie partite', 'Partite'),
          descrizione: 'Calendario, risultati e referti',
          accento: dominio.evidenzaViola,
          onTap: () => _apri(
            context,
            PartiteAtletaListScreen(
              clubId: atleta.clubId,
              filtroGruppoId: atleta.gruppoId,
              altroGruppoId: atleta.altroGruppoId,
              vistaAllenatore: vistaAllenatore,
            ),
          ),
        ),
      ],
      VoceRiquadro(
        // Il disegno del campo con i tiri e' della pallanuoto.
        soggetto: pallanuoto
            ? SoggettoRiquadro.statistiche
            : SoggettoRiquadro.andamento,
        titolo: titolo('Le mie statistiche', 'Statistiche'),
        descrizione: portiere
            ? 'Parate e gol subiti'
            : pallanuoto
            ? 'Tiri, gol e dove segni di più'
            : 'Tempi di gara e progressi',
        accento: dominio.evidenzaCiano,
        onTap: () => _apri(context, StatisticheAtletaScreen(atleta: atleta)),
      ),
      VoceRiquadro(
        soggetto: SoggettoRiquadro.tempi,
        titolo: titolo('I miei tempi', 'Tempi'),
        descrizione: 'Personal best a nuoto',
        // Nel nuoto il numero dei personal best e' gia' in testata.
        valore: !pallanuoto || pb == null || pb.isEmpty ? null : '${pb.length}',
        accento: dominio.evidenzaAmbra,
        onTap: () => _apri(context, PbListScreen(atleta: atleta)),
      ),
      // Chi si allena anche con un'altra squadra vede gli allenamenti di
      // tutte e due, con i suoi segnati.
      if (atleta.conAltraSquadra)
        VoceRiquadro(
          soggetto: SoggettoRiquadro.stagione,
          titolo: 'Allenamenti',
          descrizione: vistaAllenatore
              ? 'Delle sue due squadre, i suoi segnati'
              : 'Delle tue due squadre, i tuoi segnati',
          accento: dominio.evidenzaCiano,
          onTap: () => _apri(
            context,
            AllenamentiSquadreScreen(
              atleta: atleta,
              vistaAllenatore: vistaAllenatore,
            ),
          ),
        ),
      VoceRiquadro(
        soggetto: SoggettoRiquadro.presenze,
        titolo: titolo('Le mie presenze', 'Presenze'),
        descrizione: allenamenti == null || allenamenti.fatti == 0
            ? 'Gli allenamenti a cui hai partecipato'
            : '${allenamenti.presente} su ${allenamenti.fatti} allenamenti',
        accento: dominio.evidenzaVerde,
        onTap: () => _apri(
          context,
          MiePresenzeScreen(atleta: atleta, vistaAllenatore: vistaAllenatore),
        ),
      ),
      VoceRiquadro(
        soggetto: SoggettoRiquadro.stagione,
        titolo: titolo('La mia stagione', 'Stagione'),
        descrizione: 'Calendario e obiettivi della squadra',
        accento: dominio.evidenzaAmbra,
        onTap: () => _apri(
          context,
          StagioneAtletaScreen(
            atleta: atleta,
            vistaAllenatore: vistaAllenatore,
          ),
        ),
      ),
    ];

    var i = 0;
    Widget blocco(Widget figlio) => EntrataACascata(indice: i++, child: figlio);

    final pagina = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largo = constraints.maxWidth >= 840;
                final prossimi = [
                  if (partita != null)
                    CardProssimaPartita(
                      partita: partita,
                      convocazione: convocazione,
                      onTap: () => _apri(
                        context,
                        PartiteAtletaListScreen(
                          clubId: atleta.clubId,
                          filtroGruppoId: atleta.gruppoId,
                          altroGruppoId: atleta.altroGruppoId,
                        ),
                      ),
                    ),
                  CardProssimoAllenamento(atleta: atleta),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    blocco(
                      TestataAtleta(
                        atleta: atleta,
                        statistiche: statistiche,
                        vistaAllenatore: vistaAllenatore,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // La fase e a cosa serve la settimana (si nasconde
                    // da sola se nessuna fase è in corso).
                    blocco(
                      CardSettimana(
                        atleta: atleta,
                        vistaAllenatore: vistaAllenatore,
                      ),
                    ),
                    blocco(const TitoloSezione('In programma')),
                    blocco(
                      CardBenessere(
                        atleta: atleta,
                        vistaAllenatore: vistaAllenatore,
                        impegno: _impegno(allenamenti?.prossimo, partita),
                      ),
                    ),
                    // La domanda di fine seduta: la risponde solo
                    // l'atleta.
                    if (!vistaAllenatore) blocco(CardRpe(atleta: atleta)),
                    // Le sedute a secco da registrare, serie per serie.
                    if (!vistaAllenatore)
                      blocco(CardSeccoDaFare(atleta: atleta)),
                    const SizedBox(height: 12),
                    if (largo && prossimi.length == 2)
                      blocco(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: prossimi[0]),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: prossimi[1]),
                          ],
                        ),
                      )
                    else
                      for (final (k, card) in prossimi.indexed) ...[
                        if (k > 0) const SizedBox(height: 12),
                        blocco(card),
                      ],
                    const SizedBox(height: 20),
                    blocco(
                      _CardAndamento(
                        atleta: atleta,
                        vistaAllenatore: vistaAllenatore,
                      ),
                    ),
                    const SizedBox(height: 20),
                    blocco(
                      TitoloSezione(
                        vistaAllenatore
                            ? 'Tutto su ${atleta.nome}'
                            : 'Tutto il tuo mondo',
                      ),
                    ),
                    GrigliaRiquadri(voci: riquadri),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    return pallanuoto
        ? _AggiornaAlRitorno(atleta: atleta, child: pagina)
        : pagina;
  }
}

/// La dashboard resta aperta a lungo (anche con l'app in sottofondo):
/// quando si torna nell'app rilegge gol, tiri e numeri del portiere, così
/// compaiono i referti salvati nel frattempo, anche da un altro telefono.
class _AggiornaAlRitorno extends ConsumerStatefulWidget {
  const _AggiornaAlRitorno({required this.atleta, required this.child});

  final Atleta atleta;
  final Widget child;

  @override
  ConsumerState<_AggiornaAlRitorno> createState() => _AggiornaAlRitornoState();
}

class _AggiornaAlRitornoState extends ConsumerState<_AggiornaAlRitorno> {
  late final AppLifecycleListener _ascolto;

  @override
  void initState() {
    super.initState();
    _ascolto = AppLifecycleListener(onResume: _rileggi);
  }

  void _rileggi() {
    if (!mounted) return;
    ref.invalidate(tiriAtletaProvider(widget.atleta.id));
    ref.invalidate(refertiDelClubProvider(widget.atleta.clubId));
    ref.invalidate(numeriPortiereProvider);
  }

  @override
  void dispose() {
    _ascolto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Incornicia [AreaAtletaHomeScreen] con una AppBar propria (titolo e
/// pulsante indietro), per raggiungerla come schermata a parte —
/// dall'account allenatore, toccando il nome di un atleta in
/// `AtletiListScreen`.
class AtletaDashboardScreen extends StatelessWidget {
  const AtletaDashboardScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Il nome e' gia' in grande nella testata: qui solo cosa si guarda
      // e la modifica dell'anagrafica, prima raggiungibile solo dal menu
      // dell'elenco atleti.
      appBar: AppBar(
        title: const Text('Scheda atleta'),
        actions: [
          IconButton(
            tooltip: 'Modifica anagrafica',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AtletaFormScreen(clubId: atleta.clubId, atleta: atleta),
              ),
            ),
          ),
        ],
      ),
      body: AreaAtletaHomeScreen(atleta: atleta, vistaAllenatore: true),
    );
  }
}

/// Card "Andamento": grafico Banister compatto, tocco apre il dettaglio
/// completo (`CaricoAtletaScreen`).
class _CardAndamento extends ConsumerWidget {
  const _CardAndamento({required this.atleta, this.vistaAllenatore = false});

  final Atleta atleta;
  final bool vistaAllenatore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntiAsync = ref.watch(
      andamentoCaricoProvider((atletaId: atleta.id, clubId: atleta.clubId)),
    );
    final colori = context.colori;
    final accento = context.dominio.evidenzaCiano;

    return Premibile(
      etichetta: 'Andamento della forma: apri il dettaglio',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CaricoAtletaScreen(atleta: atleta)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accento.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.show_chart, color: accento),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: SectionHeader(
                    vistaAllenatore ? 'Forma' : 'La tua forma',
                    spiegazione:
                        'Il grafico Banister: tre curve calcolate dagli '
                        'allenamenti e dalle partite '
                        '${vistaAllenatore ? 'svolti' : 'a cui hai partecipato'}, '
                        'con quanto sono stati duri. Fitness cresce '
                        'con il carico accumulato nel tempo, Fatica cresce '
                        'più in fretta ma si scarica anche più in fretta, '
                        'Forma è la differenza fra le due — più alta è, '
                        'più ${vistaAllenatore ? 'è pronto' : 'sei pronto'} per una partita.',
                  ),
                ),
                Icon(Icons.chevron_right, color: colori.testoSecondario),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            puntiAsync.when(
              data: (punti) => punti.isEmpty
                  ? _FormaVuota(accento: accento)
                  : SizedBox(height: 180, child: GraficoBanister(punti: punti)),
              loading: () => const SizedBox(height: 120),
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

/// Grafico ancora vuoto: un'anteprima disegnata e cosa serve per
/// riempirlo, invece di una riga grigia da sola.
class _FormaVuota extends StatelessWidget {
  const _FormaVuota({required this.accento});

  final Color accento;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: IllustrazioneRiquadroPainter(
                soggetto: SoggettoRiquadro.andamento,
                accento: accento,
                fondo: colori.superficie,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'La curva compare dopo i primi allenamenti con la presenza '
            'segnata dall\'allenatore.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      ],
    );
  }
}
