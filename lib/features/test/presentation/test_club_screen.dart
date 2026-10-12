import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/test_club_providers.dart';
import '../data/test_club_repository.dart';
import '../domain/test_club.dart';
import 'classifica_test_screen.dart';
import 'inserisci_risultati_screen.dart';
import 'test_club_form_screen.dart';
import 'test_club_widgets.dart';

/// I test del club (fase 2 del "Mako della pallanuoto", proposta 3):
/// quelli che l'allenatore usa, ognuno con la sua classifica, e — per la
/// pallanuoto — quelli pronti da aggiungere con un tocco. In testata
/// "Inserisci risultati" (a raffica, a bordo vasca) e "Nuovo test".
class TestClubScreen extends ConsumerWidget {
  const TestClubScreen({
    required this.clubId,
    required this.pallanuoto,
    super.key,
  });

  final String clubId;
  final bool pallanuoto;

  void _apri(BuildContext context, Widget pagina) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => pagina));

  Future<void> _inserisci(BuildContext context, List<TestClub> test) async {
    final scelto = test.length == 1
        ? test.single
        : await scegliTest(context, test);
    if (scelto == null || !context.mounted) return;
    _apri(context, InserisciRisultatiScreen(test: scelto));
  }

  Future<void> _aggiungiModello(
    BuildContext context,
    WidgetRef ref,
    ModelloTest m,
  ) async {
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final test = await ref
          .read(testClubRepositoryProvider)
          .creaTest(
            TestClub(
              id: '',
              clubId: clubId,
              nome: m.nome,
              descrizione: m.descrizione,
              unita: m.unita,
              piuBassoMeglio: m.piuBassoMeglio,
              prove: m.prove,
              punteggio: m.punteggio,
              modello: m.chiave,
            ),
          );
      messaggero.showSnackBar(
        SnackBar(content: Text('${test.nome}: aggiunto ai test del club')),
      );
    } catch (e) {
      messaggero.showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominio = context.dominio;
    final testAsync = ref.watch(testClubProvider(clubId));
    final risultati =
        ref.watch(risultatiTestClubProvider(clubId)).value ?? const [];
    final atleti =
        ref
            .watch(atletiListProvider((clubId: clubId, includeInactive: false)))
            .value ??
        const <Atleta>[];
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gruppi = ref.watch(gruppiListProvider(clubId)).value ?? const [];
    final nomeSquadra = gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome;
    // I risultati della squadra scelta in alto (di tutto il club senza).
    final squadra = {
      for (final a in atleti)
        if (gruppoId == null || a.gruppoId == gruppoId) a.id,
    };
    final dellaSquadra = [
      for (final r in risultati)
        if (squadra.contains(r.atletaId)) r,
    ];

    return AppScaffold(
      // Il titolo sta in grande nella testata.
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: testAsync.when(
        data: (tutti) {
          final attivi = [
            for (final t in tutti)
              if (!t.archiviato) t,
          ];
          final archiviati = [
            for (final t in tutti)
              if (t.archiviato) t,
          ];
          final giaAggiunti = {for (final t in tutti) ?t.modello};
          final pronti = pallanuoto
              ? [
                  for (final m in modelliTest)
                    if (!giaAggiunti.contains(m.chiave)) m,
                ]
              : const <ModelloTest>[];

          Widget schedaTest(TestClub t) {
            final suoi = [
              for (final r in dellaSquadra)
                if (r.testId == t.id) r,
            ];
            final ultima = suoi.isEmpty
                ? null
                : suoi
                      .map((r) => r.data)
                      .reduce((a, b) => a.isAfter(b) ? a : b);
            final atletiConRisultato = {for (final r in suoi) r.atletaId}
                .length;
            return SchedaElenco(
              leading: IconaRiquadro(
                iconaTest(t.unita),
                colore: dominio.evidenzaViola,
                dimensione: 56,
              ),
              titolo: t.nome,
              sottotitolo: ultima == null
                  ? 'Nessun risultato · ${t.comeSiLegge.toLowerCase()}'
                  : '${traQuanto(ultima)} · '
                        '${atletiConRisultato == 1 ? '1 atleta' : '$atletiConRisultato atleti'}',
              attenuata: t.archiviato,
              onTap: () => _apri(context, ClassificaTestScreen(test: t)),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                occhiello: nomeSquadra ?? 'Tutto il club',
                titolo: 'Test',
                sottotitolo: pallanuoto
                    ? 'Sprint, verticale, tiro: le classifiche della squadra'
                    : 'I test del club con le loro classifiche',
                numeri: [
                  NumeroTestata(valore: '${attivi.length}', etichetta: 'Test'),
                  NumeroTestata(
                    valore: '${dellaSquadra.length}',
                    etichetta: 'Risultati',
                  ),
                ],
                azioni: [
                  if (attivi.isNotEmpty)
                    AzioneTestata(
                      icona: Icons.dialpad,
                      etichetta: 'Inserisci risultati',
                      principale: true,
                      onTap: () => _inserisci(context, attivi),
                    ),
                  AzioneTestata(
                    icona: Icons.add,
                    etichetta: 'Nuovo test',
                    principale: attivi.isEmpty,
                    onTap: () =>
                        _apri(context, TestClubFormScreen(clubId: clubId)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              if (attivi.isEmpty && pronti.isEmpty)
                EmptyState(
                  icona: Icons.leaderboard_outlined,
                  titolo: 'Nessun test',
                  descrizione:
                      'Crea un test: cosa misura, quante prove, quale valore '
                      'è migliore. Poi segni i risultati a bordo vasca.',
                  azionePrincipale: 'Nuovo test',
                  onAzionePrincipale: () =>
                      _apri(context, TestClubFormScreen(clubId: clubId)),
                ),
              if (attivi.isNotEmpty) ...[
                TitoloSezione('I test del club', conteggio: attivi.length),
                GrigliaSchede(figli: [for (final t in attivi) schedaTest(t)]),
              ],
              if (pronti.isNotEmpty) ...[
                if (attivi.isNotEmpty) const SizedBox(height: AppSpacing.s28),
                TitoloSezione(
                  attivi.isEmpty
                      ? 'Test di pallanuoto pronti'
                      : 'Altri test pronti',
                  spiegazione:
                      'Tocca un test per aggiungerlo al club: '
                      'nome, misura e prove si possono cambiare.',
                ),
                GrigliaSchede(
                  figli: [
                    for (final m in pronti)
                      SchedaElenco(
                        leading: IconaRiquadro(
                          Icons.add,
                          colore: dominio.evidenzaViola,
                          dimensione: 56,
                        ),
                        titolo: m.nome,
                        sottotitolo: [
                          m.unita.etichetta,
                          if (m.prove == 1) '1 prova' else '${m.prove} prove',
                        ].join(' · '),
                        mostraFreccia: false,
                        onTap: () => _aggiungiModello(context, ref, m),
                      ),
                  ],
                ),
              ],
              if (archiviati.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s28),
                TitoloSezione('Archiviati', conteggio: archiviati.length),
                GrigliaSchede(
                  figli: [for (final t in archiviati) schedaTest(t)],
                ),
              ],
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (errore, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i test.',
            suggerimento:
                "Riprova. Se l'errore continua, chiudi e riapri l'app.",
            dettaglioTecnico: messaggioErrore(errore),
          ),
        ),
      ),
    );
  }
}
