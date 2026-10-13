import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
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
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import 'esercizio_secco_form_screen.dart';
import 'secco_widgets.dart';

/// L'elenco degli esercizi a secco del club, per categoria: un tocco per
/// cambiarne uno, "Nuovo esercizio", l'elenco pronto da aggiungere tutto
/// insieme, gli archiviati in fondo.
class EserciziSeccoScreen extends ConsumerWidget {
  const EserciziSeccoScreen({required this.clubId, super.key});

  final String clubId;

  void _apri(BuildContext context, Widget schermata) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => schermata));

  Future<void> _aggiungiPronti(
    BuildContext context,
    WidgetRef ref,
    List<ModelloEsercizio> pronti,
  ) async {
    final messaggero = ScaffoldMessenger.of(context);
    try {
      await ref.read(seccoRepositoryProvider).aggiungiModelli(clubId, pronti);
      messaggero.showSnackBar(
        SnackBar(
          content: Text(
            pronti.length == 1
                ? 'Esercizio aggiunto all\'elenco'
                : '${pronti.length} esercizi aggiunti all\'elenco',
          ),
        ),
      );
    } catch (e) {
      messaggero.showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viola = context.dominio.evidenzaViola;
    final eserciziAsync = ref.watch(eserciziSeccoProvider(clubId));

    return AppScaffold(
      appBar: AppBar(),
      body: eserciziAsync.when(
        data: (esercizi) {
          final attivi = [
            for (final e in esercizi)
              if (!e.archiviato) e,
          ];
          final archiviati = [
            for (final e in esercizi)
              if (e.archiviato) e,
          ];
          final giaNelClub = {for (final e in esercizi) ?e.modello};
          final pronti = [
            for (final m in modelliEsercizi)
              if (!giaNelClub.contains(m.chiave)) m,
          ];

          SchedaElenco scheda(EsercizioSecco e) => SchedaElenco(
            leading: IconaRiquadro(
              iconaCategoria(e.categoria),
              colore: viola,
              dimensione: 48,
            ),
            titolo: e.nome,
            sottotitolo: [
              e.attrezzo ?? 'Corpo libero',
              if (e.aTempo) 'a tempo',
            ].join(' · '),
            attenuata: e.archiviato,
            onTap: () => _apri(
              context,
              EsercizioSeccoFormScreen(clubId: clubId, esercizio: e),
            ),
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                titolo: 'Esercizi a secco',
                sottotitolo: 'Quelli che scegli per le sedute a secco del club',
                numeri: [
                  NumeroTestata(
                    valore: '${attivi.length}',
                    etichetta: 'Esercizi',
                  ),
                ],
                azioni: [
                  AzioneTestata(
                    icona: Icons.add,
                    etichetta: 'Nuovo esercizio',
                    principale: true,
                    onTap: () => _apri(
                      context,
                      EsercizioSeccoFormScreen(clubId: clubId),
                    ),
                  ),
                  if (pronti.isNotEmpty)
                    AzioneTestata(
                      icona: Icons.playlist_add,
                      etichetta: pronti.length == modelliEsercizi.length
                          ? 'Aggiungi l\'elenco pronto'
                          : 'Aggiungi gli altri pronti',
                      onTap: () => _aggiungiPronti(context, ref, pronti),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              if (attivi.isEmpty)
                EmptyState(
                  icona: Icons.fitness_center,
                  titolo: 'Nessun esercizio nell\'elenco',
                  descrizione:
                      'Aggiungi l\'elenco pronto (spalla, scapole, core, '
                      'gambe, mobilità, forza) o crea i tuoi esercizi.',
                  azionePrincipale: 'Aggiungi l\'elenco pronto',
                  onAzionePrincipale: () => _aggiungiPronti(
                    context,
                    ref,
                    pronti.isEmpty ? modelliEsercizi : pronti,
                  ),
                  azioneSecondaria: 'Nuovo esercizio',
                  onAzioneSecondaria: () =>
                      _apri(context, EsercizioSeccoFormScreen(clubId: clubId)),
                ),
              for (final c in CategoriaEsercizio.values)
                if (attivi.where((e) => e.categoria == c).toList()
                    case final elenco when elenco.isNotEmpty) ...[
                  TitoloSezione(c.etichetta, conteggio: elenco.length),
                  GrigliaSchede(figli: [for (final e in elenco) scheda(e)]),
                  const SizedBox(height: AppSpacing.s24),
                ],
              if (archiviati.isNotEmpty) ...[
                TitoloSezione('Archiviati', conteggio: archiviati.length),
                GrigliaSchede(figli: [for (final e in archiviati) scheda(e)]),
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
            messaggio: 'Non è stato possibile caricare gli esercizi.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(errore),
          ),
        ),
      ),
    );
  }
}
