import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../club/application/current_club_provider.dart';
import '../../home/atleta/grafica_pallanuoto.dart';
import '../../home/atleta/home_atleta_widgets.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../application/gruppi_providers.dart';
import '../application/selezione_gruppo_provider.dart';
import 'gruppi_management_screen.dart';

/// Mostrata a ogni apertura dell'app (dopo il primo login, quando i gruppi
/// esistono gia'): una squadra per riquadro piu' "Tutti gli atleti", per
/// scegliere con chi si lavora in questa sessione prima di entrare nelle
/// tab normali. Ogni riquadro dice quanti atleti ha e qual e' il suo
/// prossimo impegno. Nessuna AppBar propria — vedi GruppiOnboardingScreen.
class GruppiChooserScreen extends ConsumerWidget {
  const GruppiChooserScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final dominio = context.dominio;
    final gruppi = ref.watch(gruppiListProvider(clubId)).value ?? [];
    final club = ref.watch(currentClubProvider).value;
    final pallanuoto = club?.sport != 'nuoto';
    final atleti =
        ref
            .watch(atletiListProvider((clubId: clubId, includeInactive: false)))
            .value ??
        const [];
    final oggi = DateTime.now();
    final inizio = DateTime(oggi.year, oggi.month, oggi.day);
    final allenamenti =
        (ref.watch(allenamentiListProvider(clubId)).value ?? const [])
            .where((a) => !a.data.isBefore(inizio))
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    final partite = pallanuoto
        ? ((ref.watch(partiteListProvider(clubId)).value ?? const [])
              .where((p) => !p.data.isBefore(inizio))
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data)))
        : const [];

    void scegli(String? gruppoId) => ref
        .read(selezioneGruppoProvider.notifier)
        .scegli(SelezioneGruppo(gruppoId));

    String prossimo(String? gruppoId) {
      final p = partite
          .where(
            (x) => visibileNelGruppo(
              gruppoDelRecord: x.gruppoId,
              gruppoSelezionato: gruppoId,
            ),
          )
          .firstOrNull;
      final a = allenamenti
          .where(
            (x) => visibileNelGruppo(
              gruppoDelRecord: x.gruppoId,
              gruppoSelezionato: gruppoId,
            ),
          )
          .firstOrNull;
      if (p != null && (a == null || !a.data.isBefore(p.data))) {
        return 'Partita ${traQuanto(p.data).toLowerCase()}';
      }
      if (a != null) return 'Allenamento ${traQuanto(a.data).toLowerCase()}';
      return 'Nessun impegno in programma';
    }

    final accenti = [
      dominio.evidenzaCiano,
      dominio.evidenzaViola,
      dominio.evidenzaAmbra,
      dominio.evidenzaVerde,
    ];
    final voci = [
      for (final (i, g) in gruppi.indexed)
        (
          id: g.id as String?,
          nome: g.nome,
          atleti: atleti.where((a) => a.gruppoId == g.id).length,
          prossimo: prossimo(g.id),
          accento: accenti[i % accenti.length],
        ),
      (
        id: null,
        nome: 'Tutti gli atleti',
        atleti: atleti.length,
        prossimo: prossimo(null),
        accento: colori.azione,
      ),
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Con chi lavori oggi?',
                          style: AppTypography.titoloXl.copyWith(
                            color: colori.testo,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scegli la squadra: puoi cambiarla quando vuoi dal '
                          'menu ☰.',
                          style: AppTypography.piccolo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Gestisci le squadre',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GruppiManagementScreen(clubId: clubId),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final colonne = w < 560 ? 1 : (w < 860 ? 2 : 3);
                  const spazio = 12.0;
                  final larghezza = (w - spazio * (colonne - 1)) / colonne;
                  return Wrap(
                    spacing: spazio,
                    runSpacing: spazio,
                    children: [
                      for (final (i, v) in voci.indexed)
                        SizedBox(
                          width: larghezza,
                          child: EntrataACascata(
                            indice: i,
                            child: _RiquadroSquadra(
                              nome: v.nome,
                              atleti: v.atleti,
                              prossimo: v.prossimo,
                              accento: v.accento,
                              tutti: v.id == null,
                              pallanuoto: pallanuoto,
                              onTap: () => scegli(v.id),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiquadroSquadra extends StatelessWidget {
  const _RiquadroSquadra({
    required this.nome,
    required this.atleti,
    required this.prossimo,
    required this.accento,
    required this.tutti,
    required this.pallanuoto,
    required this.onTap,
  });

  final String nome;
  final int atleti;
  final String prossimo;
  final Color accento;
  final bool tutti;
  final bool pallanuoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Premibile(
      onTap: onTap,
      etichetta: '$nome: $atleti atleti. $prossimo',
      child: Container(
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Striscia d'acqua con le calottine della squadra.
            SizedBox(
              height: 84,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: AcquaAnimata(conCorsia: false, conPorta: false),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accento.withValues(alpha: 0.45),
                            accento.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 10,
                    child: pallanuoto
                        ? SizedBox(
                            width: 120,
                            height: 48,
                            child: Stack(
                              children: [
                                for (final (k, c)
                                    in (tutti
                                            ? const [
                                                ColoreCalottina.bianca,
                                                ColoreCalottina.blu,
                                                ColoreCalottina.rossa,
                                              ]
                                            : const [
                                                ColoreCalottina.bianca,
                                                ColoreCalottina.bianca,
                                                ColoreCalottina.rossa,
                                              ])
                                        .indexed)
                                  Positioned(
                                    left: k * 26.0,
                                    child: Calottina(colore: c, dimensione: 50),
                                  ),
                              ],
                            ),
                          )
                        : const Icon(
                            Icons.pool,
                            size: 40,
                            color: AcquaPalette.bianco,
                          ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AcquaPalette.profonda.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        atleti == 1 ? '1 atleta' : '$atleti atleti',
                        style: AppTypography.etichetta.copyWith(
                          color: AcquaPalette.bianco,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sezione.copyWith(
                            color: colori.testo,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 14,
                              color: colori.testoSecondario,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                prossimo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.etichetta.copyWith(
                                  color: colori.testoSecondario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accento.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward, size: 18, color: accento),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
