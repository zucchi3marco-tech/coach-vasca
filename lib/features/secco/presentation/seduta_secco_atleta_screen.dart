import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../application/secco_providers.dart';
import '../domain/esercizio_secco.dart';
import 'secco_widgets.dart';

/// Una seduta a secco vista dall'atleta: gli esercizi in ordine con
/// quanto farne e, a un tocco, come si fanno. Le note dell'allenatore
/// non arrivano (come per le serie).
class SedutaSeccoAtletaScreen extends ConsumerWidget {
  const SedutaSeccoAtletaScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eserciziAsync = ref.watch(
      eserciziSedutaAtletaProvider(allenamento.id),
    );
    final numero = eserciziAsync.value?.length;
    return AppScaffold(
      appBar: AppBar(title: const Text('Seduta a secco')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: quandoEsteso(allenamento.data),
            titolo: allenamento.titoloMostrato,
            numeri: [
              if (numero != null)
                NumeroTestata(valore: '$numero', etichetta: 'Esercizi'),
              NumeroTestata(
                valore: "${minutiSeduta(allenamento)}'",
                etichetta: 'Durata',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          ...eserciziAsync.when(
            data: (esercizi) => esercizi.isEmpty
                ? const [
                    EmptyState(
                      icona: Icons.fitness_center,
                      titolo: 'Esercizi non ancora scritti',
                      descrizione:
                          'Quando l\'allenatore li aggiunge, li trovi qui con '
                          'serie, ripetizioni e come si fanno.',
                      // Senza azione: il pulsante non compare.
                      azionePrincipale: '',
                    ),
                  ]
                : [
                    TitoloSezione(
                      'Esercizi',
                      conteggio: esercizi.length,
                      spiegazione: 'Tocca un esercizio per vedere come si fa.',
                    ),
                    AppListPanel(
                      righe: [
                        for (final (i, e) in esercizi.indexed)
                          RigaEsercizio(
                            numero: i + 1,
                            esercizio: e.esercizio,
                            riga: e.riga,
                            onTap: () => _comeSiFa(context, e),
                          ),
                      ],
                    ),
                  ],
            loading: () => const [LoadingSkeletonList(righe: 4)],
            error: (errore, _) => [
              ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli esercizi.',
                suggerimento:
                    'Controlla la connessione e riprova: gli esercizi si '
                    'leggono dal server.',
                dettaglioTecnico: messaggioErrore(errore),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _comeSiFa(BuildContext context, EsercizioSedutaAtleta e) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) {
          final colori = sheetContext.colori;
          final descrizione = e.esercizio.descrizione;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.esercizio.nome,
                    style: AppTypography.sezione.copyWith(color: colori.testo),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    prescrizioneEsercizio(e.riga),
                    style: AppTypography.numerica(AppTypography.corpoForte)
                        .copyWith(color: colori.testo),
                  ),
                  if (e.esercizio.attrezzo case final a?
                      when a.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      a,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    descrizione == null || descrizione.trim().isEmpty
                        ? 'Per come si fa, chiedi all\'allenatore.'
                        : descrizione,
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
