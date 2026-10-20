import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/zone_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../application/allenamenti_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/com_e_andata.dart';
import '../domain/serie.dart';
import '../domain/volume_allenamento.dart';
import 'card_com_e_andata.dart';
import 'com_e_andata.dart';
import 'per_chi_serie.dart';
import 'serie_labels.dart';

/// «Segna com'è andata»: tutte le serie dell'allenamento, nell'ordine, con
/// «Fatta», «In parte» e «Saltata» per ognuna, per segnare dall'ufficio
/// com'è andata una seduta già fatta. Le stesse regole del bordo vasca:
/// «Fatta» vale solo per una serie fatta tutta (su una fatta in parte la
/// fa diventare fatta tutta), un secondo tocco su un esito lo toglie. In
/// cima, in diretta, quanto è stato fatto in tutto.
class ComEAndataScreen extends ConsumerStatefulWidget {
  const ComEAndataScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<ComEAndataScreen> createState() => _ComEAndataScreenState();
}

class _ComEAndataScreenState extends ConsumerState<ComEAndataScreen> {
  void _errore(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
  }

  Future<void> _tocca(Serie s, String esito) async {
    try {
      await ref
          .read(serieRepositoryProvider)
          .segnaEsito(s.id, esitoDopoTocco(s, esito));
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _inParte(BuildContext contesto, Serie s) async {
    final risposta = await mostraSceltaInParte(contesto, s);
    if (risposta == null || !mounted) return;
    try {
      await applicaInParte(ref.read(serieRepositoryProvider), s, risposta);
    } catch (e) {
      _errore(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allenamento = widget.allenamento;
    final colori = context.colori;
    final serieAsync = ref.watch(serieListProvider(allenamento.id));
    final serie = serieAsync.value ?? const <Serie>[];
    final atleti = atletiDellAllenamento(
      ref
              .watch(
                atletiListProvider((
                  clubId: allenamento.clubId,
                  includeInactive: true,
                )),
              )
              .value ??
          const [],
      gruppoId: allenamento.gruppoId,
      serie: serie,
    );
    // Per chi è ogni serie; in un momento in parallelo anche la colonna di
    // tutti lo dice, perché accanto c'è il lavoro dei portieri.
    String? perChi(Serie s) {
      final chi = labelPerChi(s.destinatari, atleti);
      if (chi != null || s.momentoId == null) return chi;
      return eMomento([
            for (final x in serie)
              if (x.momentoId == s.momentoId) x,
          ])
          ? 'Tutti'
          : null;
    }

    final telefono = MediaQuery.sizeOf(context).width < 480;
    return AppScaffold(
      appBar: AppBar(title: const Text("Com'è andata")),
      body: serieAsync.when(
        data: (serie) {
          if (serie.isEmpty) {
            return EmptyState(
              icona: Icons.pool_outlined,
              titolo: 'Nessuna serie in questo allenamento',
              descrizione:
                  'Aggiungi le serie dal dettaglio dell\'allenamento: poi '
                  'potrai segnare com\'è andata.',
              azionePrincipale: 'Torna indietro',
              onAzionePrincipale: () => Navigator.of(context).pop(),
            );
          }
          final gruppo = serieDelGruppo(serie);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  quandoEsteso(allenamento.data),
                  if (allenamento.titolo case final t? when t.isNotEmpty) t,
                ].join(' · '),
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              if (gruppo.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                SintesiComEAndata(riepilogoComEAndata(gruppo)),
              ],
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: ListView.separated(
                  itemCount: serie.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s8),
                  itemBuilder: (context, i) => _RigaDaSegnare(
                    serie: serie[i],
                    perChi: perChi(serie[i]),
                    impilati: telefono,
                    onEsito: (esito) => _tocca(serie[i], esito),
                    onInParte: (contesto) => _inParte(contesto, serie[i]),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare le serie.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }
}

/// Una serie con i suoi tre bottoni: il titolo, per chi è, com'è andata e
/// «Fatta» · «In parte» · «Saltata».
class _RigaDaSegnare extends StatelessWidget {
  const _RigaDaSegnare({
    required this.serie,
    required this.perChi,
    required this.impilati,
    required this.onEsito,
    required this.onInParte,
  });

  final Serie serie;
  final String? perChi;
  final bool impilati;
  final ValueChanged<String> onEsito;
  final void Function(BuildContext contesto) onInParte;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = serie;
    final stato = s.inParte
        ? descriviFatto(s)
        : s.saltata
        ? 'Saltata'
        : s.fatta
        ? 'Fatta'
        : null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: LaneRule(
        colore: context.dominio.colorePerZona(s.zona, rispetto: colori.linea),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (perChi case final chi?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: EtichettaPerChi(chi),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${s.ordine}  ',
                            style: AppTypography.piccolo.copyWith(
                              color: colori.testoTenue,
                            ),
                          ),
                          TextSpan(
                            text: titoloSerie(s),
                            style: AppTypography.corpoForte.copyWith(
                              color: s.saltata
                                  ? colori.testoSecondario
                                  : colori.testo,
                              decoration: s.saltata
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (s.zona != null) ...[
                    const SizedBox(width: AppSpacing.s8),
                    ZoneChip(sigla: s.zona!),
                  ],
                ],
              ),
              if (stato != null) ...[
                const SizedBox(height: 2),
                Text(
                  stato,
                  style: AppTypography.numerica(
                    AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s12),
              rigaDiBottoni(
                bottoniEsito(
                  s,
                  onEsito: onEsito,
                  onInParte: () => onInParte(context),
                  altezza: AppSpacing.altezzaMinimaBersaglio,
                  impilati: impilati,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
