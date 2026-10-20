import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/percentuale_presenze.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../ai_genera/application/corsie_service.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/application/personal_best_providers.dart';
import '../../atleti/domain/personal_best.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/application/benessere_providers.dart';
import '../../benessere/domain/segnale_benessere.dart';
import '../../benessere/presentation/benessere_squadra.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../home/area_atleta_home_screen.dart';
import '../application/presenze_providers.dart';
import '../data/presenze_repository.dart';
import '../domain/presenza.dart';
import '../../../widgets/nascondi_barra_club.dart';

/// Schermata da bordo vasca (DESIGN.md sezione 9): bersagli grandi, niente
/// form, e — a scelta dell'allenatore — sfondo scuro (vedi
/// [temaBordoVascaOverrideProvider]).
class PresenzeScreen extends ConsumerWidget {
  const PresenzeScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context, ref)));

  Widget _costruisci(BuildContext context, WidgetRef ref) {
    final filter = (clubId: allenamento.clubId, includeInactive: false);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final presenzeAsync = ref.watch(presenzeListProvider(allenamento.id));
    final overrideVasca = ref.watch(temaBordoVascaOverrideProvider);
    final temaVasca = temaBordoVascaDa(overrideVasca);
    // Per «questa settimana» e «a ottobre» accanto ai nomi, e il punto del
    // benessere di oggi per chi è peggio del solito.
    final allenamentiClub =
        ref.watch(allenamentiListProvider(allenamento.clubId)).value ??
        const <Allenamento>[];
    final presenzeClub =
        ref.watch(presenzeClubProvider(allenamento.clubId)).value ??
        const <Presenza>[];
    final schedeOggi = ref.watch(schedeOggiClubProvider(allenamento.clubId));
    final punteggiOggi = ref.watch(
      punteggiOggiClubProvider(allenamento.clubId),
    );
    final eOggi = soloData(allenamento.data) == soloData(DateTime.now());

    final scaffold = AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('Presenze · ${dataCompatta(allenamento.data)}'),
        actions: const [BottoneTemaBordoVasca()],
      ),
      body: atletiAsync.when(
        data: (tuttiGliAtleti) {
          return presenzeAsync.when(
            data: (presenze) {
              final conPresenza = {for (final p in presenze) p.atletaId};
              // Un allenamento con gruppo assegnato mostra solo chi è
              // atteso (bug: prima si vedevano — e si potevano segnare —
              // le presenze di tutto il club): gli atleti del gruppo, tranne
              // nei giorni in cui si allenano con un'altra squadra, e chi
              // quel giorno viene da un'altra squadra. Un atleta senza
              // gruppo resta visibile; chi è già segnato non sparisce (un
              // cambio di un giorno, "Aggiungi un atleta").
              final atleti = [
                for (final a in tuttiGliAtleti)
                  if (a.attesoA(allenamento.gruppoId, allenamento.data) ||
                      conPresenza.contains(a.id))
                    a,
              ];
              final altri = [
                for (final a in tuttiGliAtleti)
                  if (!atleti.contains(a)) a,
              ];
              final nomiGruppi = {
                for (final g
                    in ref
                            .watch(gruppiListProvider(allenamento.clubId))
                            .value ??
                        const <Gruppo>[])
                  g.id: g.nome,
              };
              // "da Under 14": chi quel giorno si allena con un'altra
              // squadra, non con la sua.
              String? daAltraSquadra(Atleta a) =>
                  allenamento.gruppoId == null ||
                      a.gruppoId == null ||
                      a.gruppoId == allenamento.gruppoId
                  ? null
                  : 'da ${nomiGruppi[a.gruppoId] ?? "un'altra squadra"}';
              Future<void> aggiungi() async {
                final scelto = await showDialog<Atleta>(
                  context: context,
                  builder: (_) => _DialogAggiungiAtleta(
                    atleti: altri,
                    nomiGruppi: nomiGruppi,
                  ),
                );
                if (scelto == null) return;
                await ref
                    .read(presenzeRepositoryProvider)
                    .segnaPresenza(
                      allenamentoId: allenamento.id,
                      atletaId: scelto.id,
                      stato: statoPresente,
                    );
              }

              if (atleti.isEmpty) {
                return EmptyState(
                  icona: Icons.groups_outlined,
                  titolo: 'Nessun atleta attivo in questo club',
                  descrizione:
                      'Aggiungi gli atleti dalla schermata Atleti per poter '
                      'segnare le presenze.',
                  azionePrincipale: 'Torna indietro',
                  onAzionePrincipale: () => Navigator.of(context).pop(),
                );
              }

              final statoPerAtleta = {
                for (final p in presenze) p.atletaId: p.stato,
              };

              // Se i tempi del gruppo sono troppo diversi per un'unica
              // ripartenza, la generazione li divide in due corsie: qui
              // si vede chi sta in quale (1 = veloci, 2 = lenti).
              final pbPerAtleta = <String, List<PersonalBest>>{};
              for (final pb
                  in ref
                          .watch(personalBestClubProvider(allenamento.clubId))
                          .value ??
                      const <PersonalBest>[]) {
                pbPerAtleta.putIfAbsent(pb.atletaId, () => []).add(pb);
              }
              final corsie = assegnaCorsie(atleti, pbPerAtleta);

              final daSegnare = [
                for (final a in atleti)
                  if (statoPerAtleta[a.id] == null) a,
              ];
              int quanti(bool Function(String? stato) vale) =>
                  atleti.where((a) => vale(statoPerAtleta[a.id])).length;

              // Le presenze del club con quelle di questo appello al posto
              // di quelle salvate: i numeri accanto ai nomi seguono ogni
              // tocco, senza aspettare il giro dal database.
              final presenzeCosi = [
                for (final p in presenzeClub)
                  if (p.allenamentoId != allenamento.id) p,
                ...presenze,
              ];
              final allenamentiCosi = [
                for (final a in allenamentiClub)
                  if (a.id != allenamento.id) a,
                allenamento,
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RiepilogoPresenze(
                    // Chi è in ritardo c'era: è fra i presenti, e si dice
                    // anche quanti sono.
                    presenti: quanti(contaComePresente),
                    inRitardo: quanti((s) => s == statoRitardo),
                    assenti: quanti((s) => s == statoAssente),
                    giustificati: quanti((s) => s == statoGiustificato),
                    daSegnare: daSegnare.length,
                    // Il caso di ogni giorno: quasi tutti presenti. Si
                    // segnano prima le eccezioni, poi gli altri in un tocco.
                    onTuttiPresenti: daSegnare.isEmpty
                        ? null
                        : () async {
                            final repository = ref.read(
                              presenzeRepositoryProvider,
                            );
                            for (final a in daSegnare) {
                              await repository.segnaPresenza(
                                allenamentoId: allenamento.id,
                                atletaId: a.id,
                                stato: statoPresente,
                              );
                            }
                          },
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (corsie.divisoInDue)
                    _AvvisoCorsie(
                      senzaTempo: corsie.senzaTempo
                          .where((id) => atleti.any((a) => a.id == id))
                          .length,
                    ),
                  AppListPanel(
                    righe: [
                      for (final atleta in atleti)
                        _RigaPresenza(
                          atleta: atleta,
                          corsia: corsie.numeroCorsia(atleta.id),
                          statoAttuale: statoPerAtleta[atleta.id],
                          daAltraSquadra: daAltraSquadra(atleta),
                          conteggi: presenzeSettimanaEMese(
                            allenamenti: allenamentiCosi,
                            presenze: presenzeCosi,
                            atletaId: atleta.id,
                            gruppoAtleta: atleta.gruppoId,
                            giorno: allenamento.data,
                            atteso: (a) => atleta.attesoA(a.gruppoId, a.data),
                            // Quello che si sta segnando conta comunque,
                            // anche se comincia fra un'ora.
                            sempre: {allenamento.id},
                          ),
                          meseDi: allenamento.data,
                          benessere: eOggi
                              ? segnaleBenessere(
                                  schedeOggi[atleta.id],
                                  punteggiOggi[atleta.id],
                                )
                              : null,
                          onApriBenessere: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AtletaDashboardScreen(atleta: atleta),
                            ),
                          ),
                          onSelect: (nuovoStato) => ref
                              .read(presenzeRepositoryProvider)
                              .segnaPresenza(
                                allenamentoId: allenamento.id,
                                atletaId: atleta.id,
                                stato: nuovoStato,
                              ),
                        ),
                    ],
                  ),
                  if (altri.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s12),
                    // Un cambio di un giorno: oggi si allena qui un atleta
                    // di un'altra squadra.
                    TextButton.icon(
                      onPressed: aggiungi,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Aggiungi un atleta'),
                    ),
                  ],
                ],
              );
            },
            loading: () => const LoadingSkeletonList(righe: 6),
            error: (error, _) => ErrorBanner(
              messaggio: 'Non è stato possibile caricare le presenze.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          );
        },
        loading: () => const LoadingSkeletonList(righe: 6),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );

    if (temaVasca == null) return scaffold;
    return Theme(data: temaVasca, child: scaffold);
  }
}

/// Quanti presenti, assenti, giustificati e ancora da segnare, con il
/// pulsante che segna presenti tutti quelli non ancora segnati.
class _RiepilogoPresenze extends StatelessWidget {
  const _RiepilogoPresenze({
    required this.presenti,
    required this.inRitardo,
    required this.assenti,
    required this.giustificati,
    required this.daSegnare,
    required this.onTuttiPresenti,
  });

  /// Chi c'è: compresi quelli in ritardo.
  final int presenti;

  /// Di quei presenti, quelli arrivati in ritardo.
  final int inRitardo;
  final int assenti;
  final int giustificati;
  final int daSegnare;
  final VoidCallback? onTuttiPresenti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget numero(int valore, String etichetta, Color colore) => Expanded(
      child: Column(
        children: [
          Text(
            '$valore',
            style: AppTypography.numerica(
              AppTypography.numeroMedio.copyWith(
                color: colore,
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
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      ),
    );
    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              numero(presenti, 'Presenti', colori.ok),
              numero(assenti, 'Assenti', colori.testoSecondario),
              numero(giustificati, 'Giustificati', colori.attenzione),
              numero(daSegnare, 'Da segnare', colori.testo),
            ],
          ),
          if (inRitardo > 0) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 18, color: colori.azione),
                const SizedBox(width: AppSpacing.s4),
                Flexible(
                  child: Text(
                    'di cui $inRitardo in ritardo',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onTuttiPresenti != null) ...[
            const SizedBox(height: AppSpacing.s12),
            PrimaryButton(
              label: daSegnare == 1
                  ? 'Segna presente l\'ultimo'
                  : 'Segna presenti gli altri $daSegnare',
              onPressed: onTuttiPresenti,
            ),
          ],
        ],
      ),
    );
  }
}

/// Riga di un atleta con i quattro stati possibili come bersagli grandi —
/// vedi DESIGN.md sezione 9: a bordo vasca i dati si inseriscono con
/// "bottoni grandi", altezza minima 64, mai un form o un menu a tendina.
/// Sotto il nome, quante volte c'era questa settimana e questo mese; a
/// destra del nome, il punto del benessere solo per chi è peggio del
/// solito oggi.
class _RigaPresenza extends StatelessWidget {
  const _RigaPresenza({
    required this.atleta,
    required this.corsia,
    required this.statoAttuale,
    required this.onSelect,
    required this.conteggi,
    required this.meseDi,
    required this.onApriBenessere,
    this.benessere,
    this.daAltraSquadra,
  });

  final Atleta atleta;

  /// 1 o 2 se il gruppo è diviso in corsie di ripartenza, altrimenti null.
  final int? corsia;
  final String? statoAttuale;
  final ValueChanged<String> onSelect;

  /// "da Under 14": oggi si allena con questa squadra, non con la sua.
  final String? daAltraSquadra;

  /// Presenze della settimana e del mese dell'allenamento ([meseDi]).
  final ({ConteggioPresenze settimana, ConteggioPresenze mese}) conteggi;
  final DateTime meseDi;

  /// `null` = niente da dire sul benessere di oggi: nessun punto.
  final SegnaleBenessere? benessere;
  final VoidCallback onApriBenessere;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (corsia != null) ...[
                _BadgeCorsia(numero: corsia!),
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: Text(
                  atleta.nomeCompleto,
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
              if (daAltraSquadra case final da?) ...[
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    da,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              ],
              if (benessere case final b?) ...[
                const SizedBox(width: AppSpacing.s8),
                _PuntoBenessere(
                  atletaId: atleta.id,
                  segnale: b,
                  onTap: onApriBenessere,
                ),
              ],
            ],
          ),
          _RigaConteggi(conteggi: conteggi, meseDi: meseDi),
          const SizedBox(height: AppSpacing.s12),
          // Quattro stati: in una riga se c'è posto, altrimenti due per
          // due (a 360 px con il testo ingrandito, "Giustificato" e "In
          // ritardo" non stanno uno accanto all'altro in quattro).
          LayoutBuilder(
            builder: (context, vincoli) {
              final presente = _BottoneStato(
                etichetta: 'Presente',
                icona: Icons.check,
                colore: colori.ok,
                selezionato: statoAttuale == statoPresente,
                onTap: () => onSelect(statoPresente),
              );
              final ritardo = _BottoneStato(
                etichetta: 'In ritardo',
                icona: Icons.schedule,
                colore: colori.azione,
                selezionato: statoAttuale == statoRitardo,
                onTap: () => onSelect(statoRitardo),
              );
              final assente = _BottoneStato(
                etichetta: 'Assente',
                icona: Icons.close,
                colore: colori.testoSecondario,
                selezionato: statoAttuale == statoAssente,
                onTap: () => onSelect(statoAssente),
              );
              final giustificato = _BottoneStato(
                etichetta: 'Giustificato',
                icona: Icons.event_note_outlined,
                colore: colori.attenzione,
                selezionato: statoAttuale == statoGiustificato,
                onTap: () => onSelect(statoGiustificato),
              );
              const spazio = SizedBox(width: AppSpacing.s12);
              if (vincoli.maxWidth >= 520) {
                return Row(
                  children: [
                    Expanded(child: presente),
                    spazio,
                    Expanded(child: ritardo),
                    spazio,
                    Expanded(child: assente),
                    spazio,
                    Expanded(child: giustificato),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: presente),
                      spazio,
                      Expanded(child: ritardo),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(child: assente),
                      spazio,
                      Expanded(child: giustificato),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// «3 su 4 questa settimana» e «11 su 14 a ottobre»: quante volte l'atleta
/// c'era (presente o in ritardo) sugli allenamenti che lo riguardavano.
/// Su due righe se non stanno insieme; niente per un periodo senza
/// allenamenti suoi.
class _RigaConteggi extends StatelessWidget {
  const _RigaConteggi({required this.conteggi, required this.meseDi});

  final ({ConteggioPresenze settimana, ConteggioPresenze mese}) conteggi;
  final DateTime meseDi;

  @override
  Widget build(BuildContext context) {
    final stile = AppTypography.etichetta.copyWith(
      color: context.colori.testoSecondario,
    );
    final voci = [
      if (conteggi.settimana.su > 0)
        '${conteggi.settimana.presenti} su ${conteggi.settimana.su} '
            'questa settimana',
      if (conteggi.mese.su > 0)
        '${conteggi.mese.presenti} su ${conteggi.mese.su} '
            '${inMese(meseDi)}',
    ];
    if (voci.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      child: Wrap(
        spacing: AppSpacing.s16,
        children: [for (final v in voci) Text(v, style: stile)],
      ),
    );
  }
}

/// Il punto accanto al nome per chi oggi sta peggio del solito o ha un
/// dolore: giallo da seguire, rosso da sentire. Un tocco apre il suo
/// benessere. Bersaglio da 48 anche se il segno è piccolo; il colore non
/// è l'unico segnale (cuore pieno, testo nella descrizione).
class _PuntoBenessere extends StatelessWidget {
  const _PuntoBenessere({
    required this.atletaId,
    required this.segnale,
    required this.onTap,
  });

  final String atletaId;
  final SegnaleBenessere segnale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final colore = segnale.livello >= 2 ? colori.rosso : colori.attenzione;
    return Tooltip(
      message: segnale.testo,
      child: Semantics(
        button: true,
        label: segnale.testo,
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('benessere-$atletaId'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: AppSpacing.altezzaMinimaBersaglio,
            height: AppSpacing.altezzaMinimaBersaglio,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colore.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, size: 18, color: colore),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Aggiungi un atleta": un atleta del club che oggi si allena con
/// questa squadra (un cambio di un giorno). Segnato presente, resta
/// nell'elenco di questo allenamento.
class _DialogAggiungiAtleta extends StatelessWidget {
  const _DialogAggiungiAtleta({required this.atleti, required this.nomiGruppi});

  final List<Atleta> atleti;
  final Map<String, String> nomiGruppi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final ordinati = [...atleti]
      ..sort((a, b) => a.nomeCompleto.compareTo(b.nomeCompleto));
    return AlertDialog(
      title: const Text('Aggiungi un atleta'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oggi si allena con questa squadra: lo segni presente qui.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(
              child: ListView.builder(
                itemCount: ordinati.length,
                itemBuilder: (context, i) {
                  final a = ordinati[i];
                  return ListTile(
                    title: Text(a.nomeCompleto),
                    subtitle: a.gruppoId == null
                        ? null
                        : Text(nomiGruppi[a.gruppoId] ?? ''),
                    onTap: () => Navigator.of(context).pop(a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

class _BottoneStato extends StatelessWidget {
  const _BottoneStato({
    required this.etichetta,
    required this.icona,
    required this.colore,
    required this.selezionato,
    required this.onTap,
  });

  final String etichetta;
  final IconData icona;
  final Color colore;
  final bool selezionato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.controllo),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaBersaglioVasca,
        ),
        decoration: BoxDecoration(
          color: selezionato ? colore : colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          border: Border.all(color: selezionato ? colore : colori.linea),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icona,
              size: 24,
              color: selezionato ? colori.azioneInk : colori.testoSecondario,
            ),
            const SizedBox(height: 4),
            // Una riga sola, rimpicciolita se serve: a 320 px
            // "Giustificato" andava a capo a meta' parola.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  etichetta,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTypography.piccolo.copyWith(
                    color: selezionato
                        ? colori.azioneInk
                        : colori.testoSecondario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numero della corsia di ripartenza (1 = veloci, 2 = lenti) accanto al
/// nome: il gruppo si divide guardando i numeri, senza leggere i tempi.
class _BadgeCorsia extends StatelessWidget {
  const _BadgeCorsia({required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colori.azioneTenue,
        shape: BoxShape.circle,
        border: Border.all(color: colori.azione),
      ),
      child: Text(
        '$numero',
        style: AppTypography.corpoForte.copyWith(color: colori.azione),
      ),
    );
  }
}

class _AvvisoCorsie extends StatelessWidget {
  const _AvvisoCorsie({required this.senzaTempo});

  final int senzaTempo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Text(
        'Tempi molto diversi nel gruppo: due corsie di ripartenza. '
        '1 = più veloci, 2 = più lenti.'
        '${senzaTempo > 0 ? ' Senza numero: $senzaTempo atleti senza tempo sui 100 stile libero, da assegnare tu.' : ''}',
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
    );
  }
}
