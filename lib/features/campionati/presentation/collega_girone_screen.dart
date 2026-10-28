import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/campionati_providers.dart';
import '../application/sito_fin_cambiato.dart';
import '../data/campionati_repository.dart';
import '../domain/campionato_fin.dart';

/// Collegare un girone FIN a una squadra: si sceglie la stagione, il
/// campionato con fase e girone, poi la propria squadra nella classifica
/// del girone. Restituisce il collegamento salvato.
class CollegaGironeScreen extends ConsumerStatefulWidget {
  const CollegaGironeScreen({required this.clubId, this.gruppoId, super.key});

  final String clubId;

  /// La squadra dell'app; null = si sceglie qui (o tutto il club).
  final String? gruppoId;

  @override
  ConsumerState<CollegaGironeScreen> createState() =>
      _CollegaGironeScreenState();
}

/// Il valore di "Tutto il club" nella scelta della squadra.
const _tuttoIlClub = '';

class _CollegaGironeScreenState extends ConsumerState<CollegaGironeScreen> {
  String? _stagione;
  late String? _gruppoId = widget.gruppoId;

  Future<void> _scegli(ElencoFin elenco, VoceElencoFin voce) async {
    final collegato = await Navigator.of(context).push<GironeCollegato>(
      MaterialPageRoute(
        builder: (_) => _ScegliSquadraScreen(
          clubId: widget.clubId,
          gruppoId: _gruppoId == _tuttoIlClub ? null : _gruppoId,
          voce: voce,
          stagione: elenco.stagione,
        ),
      ),
    );
    if (collegato != null && mounted) Navigator.of(context).pop(collegato);
  }

  @override
  Widget build(BuildContext context) {
    final elencoAsync = ref.watch(elencoFinProvider(_stagione));
    segnalaSeElencoNonLetto(ref, stagione: _stagione, clubId: widget.clubId);
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];

    final List<Widget> corpo = switch (elencoAsync) {
      AsyncValue(:final value?) when !elencoAsync.isLoading => [
        AppSelect<String>(
          etichetta: 'Stagione',
          value: value.stagione.isEmpty ? null : value.stagione,
          items: [
            for (final s in value.stagioni.reversed)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
          onChanged: (s) => setState(() => _stagione = s),
        ),
        const SizedBox(height: AppSpacing.s24),
        if (value.nonTuttoLetto) ...[
          const RiquadroVuoto(
            testoSitoFinCambiato,
            icona: Icons.report_problem_outlined,
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
        if (value.voci.isEmpty && !value.nonTuttoLetto)
          RiquadroVuoto(
            'La FIN non ha ancora pubblicato i campionati '
            '${value.stagione}: compariranno qui appena escono.',
            icona: Icons.hourglass_empty,
          )
        else
          for (final MapEntry(key: campionato, value: voci)
              in value.perCampionato.entries) ...[
            SezioneSchede(
              titolo: campionato,
              vociIniziali: 12,
              figli: [
                for (final v in voci)
                  SchedaElenco(
                    leading: const IconaRiquadro(Icons.leaderboard_outlined),
                    titolo: v.faseEGirone.isEmpty ? campionato : v.faseEGirone,
                    onTap: () => _scegli(value, v),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
      ],
      AsyncValue(:final error?) when !elencoAsync.isLoading => [
        ErrorBanner(
          messaggio: 'Non è stato possibile leggere il sito della FIN.',
          suggerimento: 'Riprova tra qualche minuto.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ],
      _ => [const LoadingSkeletonList(righe: 8)],
    };

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          const TestataPagina(
            occhiello: 'FIN Lombardia',
            titolo: 'Collega un girone',
            sottotitolo:
                'Scegli campionato, fase e girone: poi la tua squadra.',
          ),
          const SizedBox(height: AppSpacing.s24),
          if (widget.gruppoId == null) ...[
            AppSelect<String>(
              etichetta: 'Squadra dell\'app',
              value: _gruppoId ?? _tuttoIlClub,
              items: [
                for (final g in gruppi)
                  DropdownMenuItem(value: g.id, child: Text(g.nome)),
                const DropdownMenuItem(
                  value: _tuttoIlClub,
                  child: Text('Tutto il club'),
                ),
              ],
              onChanged: (id) => setState(() => _gruppoId = id),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          ...corpo,
        ],
      ),
    );
  }
}

/// La squadra del club nella classifica del girone scelto: un tocco e il
/// collegamento è salvato.
class _ScegliSquadraScreen extends ConsumerStatefulWidget {
  const _ScegliSquadraScreen({
    required this.clubId,
    required this.gruppoId,
    required this.voce,
    required this.stagione,
  });

  final String clubId;
  final String? gruppoId;
  final VoceElencoFin voce;
  final String stagione;

  @override
  ConsumerState<_ScegliSquadraScreen> createState() =>
      _ScegliSquadraScreenState();
}

class _ScegliSquadraScreenState extends ConsumerState<_ScegliSquadraScreen> {
  String? _inSalvataggio;

  Future<void> _salva(String squadra) async {
    setState(() => _inSalvataggio = squadra);
    try {
      final collegato = await ref
          .read(campionatiRepositoryProvider)
          .collega(
            clubId: widget.clubId,
            gruppoId: widget.gruppoId,
            voce: widget.voce,
            stagione: widget.stagione,
            squadra: squadra,
          );
      if (mounted) Navigator.of(context).pop(collegato);
    } catch (e) {
      if (!mounted) return;
      setState(() => _inSalvataggio = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final letturaAsync = ref.watch(gironeFinProvider(widget.voce.cmpId));
    segnalaSeGironeNonLetto(
      ref,
      cmpId: widget.voce.cmpId,
      clubId: widget.clubId,
      nome: [
        widget.voce.campionato,
        widget.voce.faseEGirone,
      ].where((s) => s.isNotEmpty).join(' · '),
    );
    final List<Widget> corpo = switch (letturaAsync) {
      AsyncValue(:final value?) =>
        value.girone.squadre.isEmpty
            ? [
                EmptyState(
                  icona: value.girone.nonTuttoLetto
                      ? Icons.report_problem_outlined
                      : Icons.groups_outlined,
                  titolo: value.girone.nonTuttoLetto
                      ? 'Il sito della FIN è cambiato'
                      : 'Ancora nessuna squadra',
                  descrizione: value.girone.nonTuttoLetto
                      ? "L'app non riesce più a leggere le squadre di questo "
                            'girone. Riprova più avanti.'
                      : 'La FIN non ha ancora pubblicato le squadre di questo '
                            'girone. Riprova più avanti.',
                  azionePrincipale: 'Torna all\'elenco',
                  onAzionePrincipale: () => Navigator.of(context).pop(),
                ),
              ]
            : [
                SezioneSchede(
                  titolo: 'Qual è la tua squadra?',
                  vociIniziali: 30,
                  figli: [
                    for (final s in value.girone.squadre)
                      SchedaElenco(
                        leading: const IconaRiquadro(Icons.shield_outlined),
                        titolo: s,
                        trailing: _inSalvataggio == s
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _inSalvataggio == null ? () => _salva(s) : null,
                      ),
                  ],
                ),
              ],
      AsyncValue(:final error?) => [
        ErrorBanner(
          messaggio: 'Non è stato possibile leggere il girone.',
          suggerimento: 'Riprova tra qualche minuto.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ],
      _ => [const LoadingSkeletonList(righe: 8)],
    };

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: widget.voce.campionato,
            titolo: widget.voce.faseEGirone.isEmpty
                ? 'La tua squadra'
                : widget.voce.faseEGirone,
            sottotitolo: 'Tocca la tua squadra come la scrive la FIN.',
          ),
          const SizedBox(height: AppSpacing.s24),
          ...corpo,
        ],
      ),
    );
  }
}
