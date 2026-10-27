import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
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
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../impegni/application/impegni_providers.dart';
import '../../impegni/domain/impegno.dart';
import '../../impegni/presentation/impegno_screen.dart';
import '../application/allenamenti_providers.dart';
import '../../secco/presentation/secco_widgets.dart';
import 'allenamento_detail_screen.dart';
import 'calendario/allenamenti_per_giorno.dart';
import 'riepilogo_volumi.dart';

class GiornoAllenamentiScreen extends ConsumerWidget {
  const GiornoAllenamentiScreen({
    required this.clubId,
    required this.data,
    super.key,
  });

  final String clubId;
  final DateTime data;

  String get _titolo {
    final giorno = dataEstesa(data);
    return '${giorno[0].toUpperCase()}${giorno.substring(1)} ${data.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(clubId));
    final Map<String, String> nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(clubId)).value ?? [])
        g.id: g.nome,
    };

    void apriNuovo() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GeneraAllenamentoFormScreen(clubId: clubId, dataPredefinita: data),
      ),
    );

    return AppScaffold(
      appBar: AppBar(title: Text(_titolo)),
      body: allenamentiAsync.when(
        data: (tutti) {
          final delGiorno = tutti
              .where((a) => isStessoGiorno(a.data, data))
              .toList();
          // Collegiali, riposi… di quel giorno, per aprirli da qui.
          final impegni = [
            for (final i
                in ref.watch(impegniListProvider(clubId)).value ??
                    const <Impegno>[])
              if (i.contiene(data)) i,
          ];
          final sezioneImpegni = [
            if (impegni.isNotEmpty) ...[
              TitoloSezione('Impegni', conteggio: impegni.length),
              GrigliaSchede(
                colonneMassime: 1,
                figli: [
                  for (final i in impegni)
                    SchedaElenco(
                      leading: const IconaRiquadro(
                        Icons.event_note_outlined,
                        dimensione: 48,
                      ),
                      titolo: i.titolo,
                      sottotitolo: [
                        if (i.titolo != i.tipo.etichetta) i.tipo.etichetta,
                        i.gruppoId == null
                            ? 'Tutto il club'
                            : nomiGruppi[i.gruppoId] ?? 'Una squadra',
                        if (i.giorni > 1) periodoImpegno(i, dataCompatta),
                      ].join(' · '),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ImpegnoScreen(impegno: i),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ];
          if (delGiorno.isEmpty && impegni.isNotEmpty) {
            return ListView(
              children: [
                ...sezioneImpegni,
                const SizedBox(height: AppSpacing.s24),
                EmptyState(
                  icona: Icons.calendar_month_outlined,
                  titolo: 'Nessun allenamento in questo giorno',
                  descrizione:
                      'Scrivi, detta o genera il primo allenamento di questa '
                      'data: verrà salvato in questo giorno.',
                  azionePrincipale: 'Nuovo allenamento',
                  onAzionePrincipale: apriNuovo,
                ),
              ],
            );
          }
          if (delGiorno.isEmpty) {
            return EmptyState(
              icona: Icons.calendar_month_outlined,
              titolo: 'Nessun allenamento in questo giorno',
              descrizione:
                  'Scrivi, detta o genera il primo allenamento di questa '
                  'data: verrà salvato in questo giorno.',
              azionePrincipale: 'Nuovo allenamento',
              onAzionePrincipale: apriNuovo,
            );
          }
          final volumi =
              ref.watch(volumiAllenamentiProvider(clubId)).value ?? const {};
          return ListView(
            children: [
              ...sezioneImpegni,
              TitoloSezione(traQuanto(data), conteggio: delGiorno.length),
              GrigliaSchede(
                colonneMassime: 1,
                figli: [
                  for (final a in delGiorno)
                    SchedaElenco(
                      leading: IconaRiquadro(
                        a.secco ? Icons.fitness_center : Icons.pool,
                        colore: a.secco
                            ? context.dominio.evidenzaViola
                            : context.dominio.evidenzaCiano,
                        dimensione: 48,
                      ),
                      titolo: a.titoloMostrato,
                      sottotitolo: a.gruppoId == null
                          ? 'Tutto il club'
                          : nomiGruppi[a.gruppoId],
                      trailing: a.secco
                          ? DurataSecco(a)
                          : switch (volumi[a.id]) {
                              final v? => VolumeScheda(v),
                              null => null,
                            },
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AllenamentoDetailScreen(allenamento: a),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-giorno-allenamenti',
        onPressed: apriNuovo,
        tooltip: 'Nuovo allenamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
