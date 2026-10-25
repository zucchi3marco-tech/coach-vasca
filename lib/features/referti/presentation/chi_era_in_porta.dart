import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/data/distinta_repository.dart';
import '../../pallanuoto/domain/distinta_giocatore.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../statistiche/application/statistiche_providers.dart';

/// «Chi era in porta?»: per ogni tempo del referto, quale portiere della
/// distinta. Serve a contare i gol subiti dai parziali del referto.
///
/// Parte da quanto è già segnato nella distinta; con un solo portiere e
/// niente segnato, lo propone per tutti i tempi. Chi lo usa salva con
/// [ChiEraInPortaState.salva] (leggi referto) oppure col pulsante
/// ([conPulsanteSalva], referto già salvato).
class ChiEraInPorta extends ConsumerStatefulWidget {
  const ChiEraInPorta({
    required this.partita,
    required this.tempi,
    this.conPulsanteSalva = false,
    super.key,
  });

  final Partita partita;

  /// Quanti tempi ha il referto (di solito 4).
  final int tempi;

  final bool conPulsanteSalva;

  @override
  ConsumerState<ChiEraInPorta> createState() => ChiEraInPortaState();
}

class ChiEraInPortaState extends ConsumerState<ChiEraInPorta> {
  /// Tempo (1…) → id della riga di distinta del portiere scelto.
  Map<int, String>? _scelte;
  Map<int, String> _iniziali = const {};
  bool _salvando = false;

  List<DistintaGiocatore> _portieri(List<DistintaGiocatore> distinta) => [
    for (final g in distinta)
      if (g.portiere) g,
  ];

  Map<int, String> _calcolaIniziali(List<DistintaGiocatore> portieri) {
    final risultato = <int, String>{};
    for (var t = 1; t <= widget.tempi; t++) {
      for (final g in portieri) {
        if (g.tempiInPorta.contains(t)) {
          risultato[t] = g.id;
          break;
        }
      }
    }
    if (risultato.isEmpty && portieri.length == 1) {
      for (var t = 1; t <= widget.tempi; t++) {
        risultato[t] = portieri.first.id;
      }
    }
    return risultato;
  }

  bool get _modificato {
    final scelte = _scelte;
    if (scelte == null) return false;
    if (scelte.length != _iniziali.length) return true;
    return scelte.entries.any((e) => _iniziali[e.key] != e.value);
  }

  /// Scrive nella distinta i tempi di ogni portiere. Chi viene dal vivo
  /// può avere anche tempi oltre quelli del referto (supplementari): si
  /// lasciano com'erano.
  Future<void> salva() async {
    final scelte = _scelte;
    if (scelte == null) return;
    final distinta = ref.read(distintaListProvider(widget.partita.id)).value;
    if (distinta == null) return;
    final repository = ref.read(distintaRepositoryProvider);
    for (final g in _portieri(distinta)) {
      // Un tempo non toccato resta com'era: dal vivo, con un cambio a
      // metà tempo, quel tempo è di tutti e due i portieri.
      final suoi = {
        for (var t = 1; t <= widget.tempi; t++)
          if (scelte[t] != _iniziali[t]
              ? scelte[t] == g.id
              : scelte[t] == g.id || g.tempiInPorta.contains(t))
            t,
        for (final t in g.tempiInPorta)
          if (t > widget.tempi) t,
      }.toList()..sort();
      final prima = [...g.tempiInPorta]..sort();
      if (listEquals(suoi, prima)) continue;
      await repository.impostaTempiInPorta(g.id, suoi);
    }
    ref.invalidate(numeriPortiereProvider);
  }

  Future<void> _salvaDalPulsante() async {
    setState(() => _salvando = true);
    try {
      await salva();
      if (!mounted) return;
      _iniziali = Map.of(_scelte ?? const {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Portieri salvati.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tempi < 1) return const SizedBox.shrink();
    final distinta = ref.watch(distintaListProvider(widget.partita.id)).value;
    if (distinta == null) return const SizedBox.shrink();
    final colori = context.colori;
    final portieri = _portieri(distinta);

    Widget corpo;
    if (portieri.isEmpty) {
      corpo = Text(
        'Segna un portiere nella distinta per contare i gol subiti.',
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      );
    } else {
      if (_scelte == null) {
        _iniziali = _calcolaIniziali(portieri);
        _scelte = Map.of(_iniziali);
      }
      final atleti = ref
          .watch(
            atletiListProvider((
              clubId: widget.partita.clubId,
              includeInactive: true,
            )),
          )
          .value;
      String nome(DistintaGiocatore g) {
        final a = atleti?.where((a) => a.id == g.atletaId).firstOrNull;
        return '${g.numeroCalottina} · ${a?.cognome ?? 'Portiere'}';
      }

      final scelte = _scelte!;
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var t = 1; t <= widget.tempi; t++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      'Tempo $t',
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s4,
                      children: [
                        for (final g in portieri)
                          TonalChip(
                            etichetta: nome(g),
                            selezionato: scelte[t] == g.id,
                            onSelezionato: (_) => setState(() {
                              if (scelte[t] == g.id) {
                                scelte.remove(t);
                              } else {
                                scelte[t] = g.id;
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.conPulsanteSalva) ...[
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: _salvando ? 'Salvo...' : 'Salva chi era in porta',
              onPressed: _salvando || !_modificato ? null : _salvaDalPulsante,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione(
          'Chi era in porta?',
          spiegazione:
              'Per ogni tempo, il portiere che era in porta: servono per '
              'contare i gol subiti dai parziali del referto.',
        ),
        corpo,
      ],
    );
  }
}
