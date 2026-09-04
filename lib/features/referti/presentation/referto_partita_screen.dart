import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/referti_providers.dart';
import '../domain/referto_letto.dart';
import '../domain/referto_partita.dart';

/// Mostra il referto gia' salvato per questa partita (risultato finale,
/// parziali, rose complete di reti/espulsioni), se esiste. Il salvataggio
/// vero e proprio avviene da "Leggi referto" (tab Partite): questa
/// schermata e' solo di consultazione.
class RefertoPartitaScreen extends ConsumerWidget {
  const RefertoPartitaScreen({required this.partita, super.key});

  final Partita partita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refertoAsync = ref.watch(refertoPerPartitaProvider(partita.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Referto')),
      body: SafeArea(
        child: refertoAsync.when(
          data: (referto) => referto == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nessun referto salvato per questa partita. Usa '
                      '"Leggi referto" dalla lista partite per digitalizzarne '
                      'uno da una foto.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _RefertoSalvatoView(referto: referto),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(messaggioErrore(error))),
        ),
      ),
    );
  }
}

class _RefertoSalvatoView extends StatelessWidget {
  const _RefertoSalvatoView({required this.referto});

  final RefertoPartita referto;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  '${referto.squadraCasa}   '
                  '${referto.risultatoCasa} - ${referto.risultatoTrasferta}'
                  '   ${referto.squadraTrasferta}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (referto.parziali.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      for (var i = 0; i < referto.parziali.length; i++)
                        'T${i + 1}: ${referto.parziali[i].casa}-'
                            '${referto.parziali[i].trasferta}',
                    ].join('   '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _TabellaGiocatoriSalvata(
            titolo: referto.squadraCasa,
            giocatori: referto.giocatoriCasa,
          ),
          const SizedBox(height: 24),
          _TabellaGiocatoriSalvata(
            titolo: referto.squadraTrasferta,
            giocatori: referto.giocatoriTrasferta,
          ),
        ],
      ),
    );
  }
}

class _TabellaGiocatoriSalvata extends StatelessWidget {
  const _TabellaGiocatoriSalvata({
    required this.titolo,
    required this.giocatori,
  });

  final String titolo;
  final List<GiocatoreReferto> giocatori;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final g in giocatori)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text(
                '${g.numeroCalottina}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(g.nome),
            trailing: Text('${g.reti} reti · ${g.espulsioni} esp.'),
          ),
      ],
    );
  }
}
