import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/scheda_bordo_vasca_screen.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../secco/presentation/seduta_secco_atleta_screen.dart';

/// Quanti giorni avanti si vedono gli allenamenti delle due squadre.
const giorniAllenamentiSquadre = 14;

/// Gli allenamenti in programma delle due squadre di un atleta che si
/// allena anche con un'altra in giorni fissi (richiesta del coach
/// 2026-10-15: "devono avere la possibilità di vedere entrambe le
/// categorie"): da oggi per [giorniAllenamentiSquadre] giorni, quelli in
/// cui è atteso segnati "Il tuo", gli altri attenuati. Un tocco apre la
/// scheda, come il prossimo allenamento.
class AllenamentiSquadreScreen extends ConsumerWidget {
  const AllenamentiSquadreScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;

  /// Aperta dall'allenatore dalla pagina dell'atleta: "Il suo", non "Il
  /// tuo".
  final bool vistaAllenatore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(
      allenamentiAtletaProvider(atleta.clubId),
    );
    final nomi = {
      for (final g in ref.watch(gruppiListProvider(atleta.clubId)).value ?? [])
        g.id: g.nome,
    };
    String squadra(String? gruppo) => switch (gruppo) {
      null => 'Tutto il club',
      final g when g == atleta.gruppoId => nomi[g] ?? 'La tua squadra',
      final g => nomi[g] ?? "L'altra squadra",
    };
    final azzurro = context.colori.azione;
    final oggi = soloData(DateTime.now());
    final fine = aggiungiGiorni(oggi, giorniAllenamentiSquadre);

    void apri(Allenamento a) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => a.secco
            ? SedutaSeccoAtletaScreen(allenamento: a, atleta: atleta)
            : SchedaBordoVascaScreen(allenamento: a, perAtleta: true),
      ),
    );

    return AppScaffold(
      appBar: AppBar(),
      body: allenamentiAsync.when(
        data: (allenamenti) {
          final prossimi =
              allenamenti
                  .where(
                    (a) =>
                        !soloData(a.data).isBefore(oggi) &&
                        soloData(a.data).isBefore(fine) &&
                        atleta.vedeGruppo(a.gruppoId),
                  )
                  .toList()
                ..sort((a, b) => a.data.compareTo(b.data));
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                occhiello: atleta.nomeCompleto,
                titolo: 'Allenamenti',
                sottotitolo: [
                  squadra(atleta.gruppoId),
                  squadra(atleta.altroGruppoId),
                ].join(' e '),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (prossimi.isEmpty)
                EmptyState(
                  icona: Icons.pool_outlined,
                  titolo: 'Nessun allenamento in programma',
                  descrizione:
                      'Nelle prossime due settimane non ci sono allenamenti '
                      'delle tue squadre.',
                  azionePrincipale: 'Torna indietro',
                  onAzionePrincipale: () => Navigator.of(context).pop(),
                )
              else
                GrigliaSchede(
                  figli: [
                    for (final a in prossimi)
                      () {
                        final tuo = atleta.attesoA(a.gruppoId, a.data);
                        return SchedaElenco(
                          leading: RiquadroData(
                            a.data,
                            colore: azzurro,
                            spento: !tuo,
                          ),
                          titolo: a.titoloMostrato,
                          sottotitolo: [
                            squadra(a.gruppoId),
                            traQuanto(a.data),
                            if (a.secco) 'a secco',
                          ].join(' · '),
                          sotto: tuo
                              ? Pastiglia(
                                  vistaAllenatore ? 'Il suo' : 'Il tuo',
                                  colore: azzurro,
                                )
                              : null,
                          attenuata: !tuo,
                          onTap: () => apri(a),
                        );
                      }(),
                  ],
                ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli allenamenti.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}
