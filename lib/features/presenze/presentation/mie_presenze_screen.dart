import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
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
import '../../atleti/domain/atleta.dart';
import '../application/presenze_providers.dart';
import '../domain/presenza.dart';

String _etichettaStato(String stato) {
  switch (stato) {
    case 'presente':
      return 'Presente';
    case 'giustificato':
      return 'Giustificato';
    default:
      return 'Assente';
  }
}

IconData _iconaStato(String stato) {
  switch (stato) {
    case 'presente':
      return Icons.check_circle_outline;
    case 'giustificato':
      return Icons.event_note_outlined;
    default:
      return Icons.close;
  }
}

Color _coloreStato(String stato, ColoriApp colori) {
  switch (stato) {
    case 'presente':
      return colori.ok;
    case 'giustificato':
      return colori.attenzione;
    default:
      return colori.testoSecondario;
  }
}

/// Presenze e percentuali del solo atleta collegato (FASE 9). La
/// percentuale usa come denominatore gli allenamenti del club con lo
/// stesso `gruppo` dell'atleta (campo testo libero: se l'atleta non ha
/// un gruppo impostato, o nessun allenamento lo riporta, si conta su
/// tutti gli allenamenti del club).
class MiePresenzeScreen extends ConsumerWidget {
  const MiePresenzeScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;

  /// Aperta dall'allenatore dalla scheda di un atleta: titolo non in
  /// prima persona.
  final bool vistaAllenatore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenzeAsync = ref.watch(presenzePerAtletaProvider(atleta.id));
    final allenamentiAsync = ref.watch(
      allenamentiAtletaProvider(atleta.clubId),
    );

    return AppScaffold(
      appBar: AppBar(),
      body: presenzeAsync.when(
        data: (presenze) => allenamentiAsync.when(
          data: (allenamenti) => _Contenuto(
            atleta: atleta,
            vistaAllenatore: vistaAllenatore,
            presenze: presenze,
            allenamenti: allenamenti,
          ),
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
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare le presenze.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.atleta,
    required this.vistaAllenatore,
    required this.presenze,
    required this.allenamenti,
  });

  final Atleta atleta;
  final bool vistaAllenatore;
  final List<Presenza> presenze;
  final List<Allenamento> allenamenti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final haGruppo = atleta.gruppoId != null;
    final delGruppo = haGruppo
        ? allenamenti.where((a) => a.gruppoId == atleta.gruppoId).toList()
        : allenamenti;
    final rilevanti = delGruppo.isEmpty ? allenamenti : delGruppo;

    final oggi = DateTime.now();
    final inizioMese = DateTime(oggi.year, oggi.month, 1);
    final delMese = rilevanti
        .where((a) => !a.data.isBefore(inizioMese))
        .toList();

    final allenamentoPerId = {for (final a in allenamenti) a.id: a};

    int contaPresenti(List<Allenamento> periodo) {
      final idPeriodo = periodo.map((a) => a.id).toSet();
      return presenze
          .where(
            (p) => p.stato == 'presente' && idPeriodo.contains(p.allenamentoId),
          )
          .length;
    }

    final numeroPresenze = presenze.where((p) => p.stato == 'presente').length;
    final percentualeMese = delMese.isEmpty
        ? null
        : contaPresenti(delMese) / delMese.length * 100;
    final percentualeTotale = rilevanti.isEmpty
        ? null
        : contaPresenti(rilevanti) / rilevanti.length * 100;

    final storico = [...presenze]
      ..sort((a, b) {
        final dataA = allenamentoPerId[a.allenamentoId]?.data;
        final dataB = allenamentoPerId[b.allenamentoId]?.data;
        if (dataA == null || dataB == null) return 0;
        return dataB.compareTo(dataA);
      });

    // I numeri stanno in testata; sotto lo storico, una scheda per
    // allenamento con il riquadro data e lo stato colorato.
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s32),
      children: [
        TestataPagina(
          occhiello: atleta.nomeCompleto,
          titolo: vistaAllenatore ? 'Presenze' : 'Le mie presenze',
          numeri: [
            NumeroTestata(valore: '$numeroPresenze', etichetta: 'Presenze'),
            NumeroTestata(
              valore: percentualeMese == null
                  ? '—'
                  : '${percentualeMese.round()}%',
              etichetta: 'Questo mese',
            ),
            NumeroTestata(
              valore: percentualeTotale == null
                  ? '—'
                  : '${percentualeTotale.round()}%',
              etichetta: 'Da inizio stagione',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        if (storico.isEmpty)
          const EmptyState(
            icona: Icons.how_to_reg_outlined,
            titolo: 'Nessuna presenza registrata',
            descrizione:
                'Le presenze compaiono qui quando l\'allenatore le segna.',
            azionePrincipale: 'Ho capito',
          )
        else
          SezioneSchede(
            titolo: 'Storico',
            figli: [
              for (final p in storico)
                Builder(
                  builder: (context) {
                    final a = allenamentoPerId[p.allenamentoId];
                    final colore = _coloreStato(p.stato, colori);
                    return SchedaElenco(
                      leading: a == null
                          ? IconaRiquadro(_iconaStato(p.stato), colore: colore)
                          : RiquadroData(
                              a.data,
                              colore: colore,
                              dimensione: 48,
                            ),
                      titolo: a?.titolo != null && a!.titolo!.isNotEmpty
                          ? a.titolo!
                          : 'Allenamento',
                      sottotitolo: a == null ? null : giornoSettimana(a.data),
                      trailing: Pastiglia(
                        _etichettaStato(p.stato),
                        colore: colore,
                      ),
                      mostraFreccia: false,
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}
