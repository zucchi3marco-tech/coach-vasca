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
import '../../atleti/domain/atleta.dart';
import '../../test/application/test_club_providers.dart';
import '../../test/domain/massimale.dart';
import '../application/secco_providers.dart';
import '../domain/esercizio_secco.dart';
import '../domain/serie_fatta.dart';
import 'come_si_fa.dart';
import 'registra_secco_screen.dart';
import 'secco_widgets.dart';

/// Una seduta a secco vista dall'atleta: gli esercizi in ordine con
/// quanto farne e, a un tocco, come si fanno. Le note dell'allenatore
/// non arrivano (come per le serie). Con l'atleta collegato, in testata
/// "Comincia la seduta": la registra serie per serie
/// ([RegistraSeccoScreen]).
class SedutaSeccoAtletaScreen extends ConsumerWidget {
  const SedutaSeccoAtletaScreen({
    required this.allenamento,
    this.atleta,
    super.key,
  });

  final Allenamento allenamento;

  /// Chi la registra; null = solo da leggere (la vista dell'allenatore).
  final Atleta? atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eserciziAsync = ref.watch(
      eserciziSedutaAtletaProvider((
        allenamentoId: allenamento.id,
        atletaId: this.atleta?.id,
      )),
    );
    final esercizi = eserciziAsync.value;
    final atleta = this.atleta;
    final fatte = atleta == null
        ? const <SerieFatta>[]
        : [
            for (final f
                in ref.watch(serieFatteAtletaProvider(atleta.id)).value ??
                    const <SerieFatta>[])
              if (f.allenamentoId == allenamento.id) f,
          ];
    final conto = esercizi == null
        ? null
        : contaSerie([for (final e in esercizi) e.riga], fatte);
    // I massimali dell'atleta, solo se qualche carico è in percentuale:
    // "70%" diventa i suoi chili.
    final massimali =
        atleta != null &&
            (esercizi ?? const []).any(
              (e) => percentualeDelCarico(e.riga.carico) != null,
            )
        ? ref.watch(massimaliProvider(atleta.clubId))
        : const <String, Map<String, Massimale>>{};
    double? massimaleDi(EsercizioSedutaAtleta e) =>
        atleta == null ? null : massimali[e.riga.esercizioId]?[atleta.id]?.kg;

    void registra() {
      if (atleta == null || esercizi == null || esercizi.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistraSeccoScreen(
            allenamento: allenamento,
            atleta: atleta,
            esercizi: esercizi,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(title: const Text('Seduta a secco')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: quandoEsteso(allenamento.data),
            titolo: allenamento.titoloMostrato,
            numeri: [
              if (esercizi != null)
                NumeroTestata(
                  valore: '${esercizi.length}',
                  etichetta: 'Esercizi',
                ),
              NumeroTestata(
                valore: "${minutiSeduta(allenamento)}'",
                etichetta: 'Durata',
              ),
              if (conto != null && conto.fatte > 0)
                NumeroTestata(
                  valore: '${conto.fatte}/${conto.totali}',
                  etichetta: 'Serie fatte',
                ),
            ],
            azioni: [
              if (atleta != null &&
                  esercizi != null &&
                  esercizi.isNotEmpty &&
                  conto != null)
                AzioneTestata(
                  icona: conto.fatte >= conto.totali
                      ? Icons.check_circle_outline
                      : Icons.play_arrow,
                  etichetta: conto.fatte == 0
                      ? 'Comincia la seduta'
                      : conto.fatte < conto.totali
                      ? 'Continua la seduta'
                      : 'Rivedi la seduta',
                  principale: true,
                  onTap: registra,
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
                      spiegazione: atleta == null
                          ? 'Tocca un esercizio per vedere come si fa.'
                          : 'Tocca un esercizio per vedere come si fa. Con '
                                '"Comincia la seduta" segni ogni serie e il '
                                'telefono conta il recupero.',
                    ),
                    AppListPanel(
                      righe: [
                        for (final (i, e) in esercizi.indexed)
                          RigaEsercizio(
                            numero: i + 1,
                            esercizio: e.esercizio,
                            riga: e.riga,
                            massimale: massimaleDi(e),
                            onTap: () => mostraComeSiFa(
                              context,
                              e,
                              massimale: massimaleDi(e),
                            ),
                            trailing: _Fatte(
                              fatte: fatteDellaRiga(e.riga.id, fatte).length,
                              di: e.riga.serie,
                            ),
                          ),
                      ],
                    ),
                  ],
            loading: () => const [LoadingSkeletonList(righe: 4)],
            error: (errore, _) => [
              ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli esercizi.',
                suggerimento:
                    'Controlla la connessione e riprova: la prima volta gli '
                    'esercizi si leggono dal server, poi restano anche sul '
                    'telefono.',
                dettaglioTecnico: messaggioErrore(errore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A destra della riga: le serie fatte ("2/3"), la spunta se ci sono
/// tutte; niente se non è ancora cominciato.
class _Fatte extends StatelessWidget {
  const _Fatte({required this.fatte, required this.di});

  final int fatte;
  final int di;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    if (fatte == 0) return const SizedBox.shrink();
    final tutte = fatte >= di;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s8,
        right: AppSpacing.s8,
        top: 2,
      ),
      child: tutte
          ? Icon(Icons.check_circle, color: colori.ok, semanticLabel: 'Fatto')
          : Text(
              '$fatte/$di',
              semanticsLabel: '$fatte serie su $di',
              style: AppTypography.numerica(AppTypography.corpoForte)
                  .copyWith(color: colori.testoSecondario),
            ),
    );
  }
}
