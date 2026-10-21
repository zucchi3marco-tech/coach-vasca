import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../application/secco_providers.dart';
import '../domain/esercizio_secco.dart';
import '../domain/varianti_secco.dart';
import 'scelte_variante.dart';

/// La variante di una seduta a secco per un solo atleta (la spalla che
/// fa male): tutti gli esercizi di tutti, ognuno con quello che fa lui —
/// come tutti, un altro al posto suo, lo stesso più leggero, o niente. Un
/// tocco su un esercizio apre le scelte. Il programma degli altri non
/// cambia. Con [rigaId] quell'esercizio è in evidenza.
class VarianteAtletaScreen extends ConsumerStatefulWidget {
  const VarianteAtletaScreen({
    required this.allenamento,
    required this.atleta,
    this.rigaId,
    super.key,
  });

  final Allenamento allenamento;
  final Atleta atleta;

  /// L'esercizio di tutti da cui si è partiti.
  final String? rigaId;

  @override
  ConsumerState<VarianteAtletaScreen> createState() =>
      _VarianteAtletaScreenState();
}

class _VarianteAtletaScreenState extends ConsumerState<VarianteAtletaScreen> {
  final _chiavi = <String, GlobalKey>{};
  bool _scorso = false;

  /// Porta in vista l'esercizio da cui si è partiti, una volta sola.
  void _mostraLaRiga() {
    final id = widget.rigaId;
    if (_scorso || id == null) return;
    _scorso = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contesto = _chiavi[id]?.currentContext;
      if (!mounted || contesto == null) return;
      Scrollable.ensureVisible(
        contesto,
        alignment: 0.3,
        duration: const Duration(milliseconds: 220),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final a = widget.allenamento;
    final atleta = widget.atleta;
    final atleti =
        ref
            .watch(
              atletiListProvider((clubId: a.clubId, includeInactive: false)),
            )
            .value ??
        const <Atleta>[];
    final nome = nomeBreve(atleta, atleti.isEmpty ? [atleta] : atleti);
    final righeAsync = ref.watch(eserciziSedutaProvider(a.id));
    final esercizi = {
      for (final e
          in ref.watch(eserciziSeccoProvider(a.clubId)).value ??
              const <EsercizioSecco>[])
        e.id: e,
    };

    return AppScaffold(
      appBar: AppBar(title: Text('Variante per $nome')),
      body: righeAsync.when(
        data: (tutte) {
          _mostraLaRiga();
          final principali = righePrincipali(tutte);
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${a.titoloMostrato} · ${dataEstesa(a.data)}',
                  style: AppTypography.corpo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                TitoloSezione('Esercizi', conteggio: principali.length),
                AppListPanel(
                  righe: [
                    for (final (i, r) in principali.indexed)
                      _RigaAtleta(
                        key: _chiavi.putIfAbsent(r.id, GlobalKey.new),
                        numero: i + 1,
                        nome:
                            esercizi[r.esercizioId]?.nome ??
                            'Esercizio tolto dall\'elenco',
                        cosaFa: _cosaFa(r, atleta.id, tutte, esercizi),
                        cambiato: cosaFa(r, atleta.id, tutte)?.id != r.id,
                        inEvidenza: r.id == widget.rigaId,
                        onTap: () => mostraScelteVariante(
                          context,
                          ref,
                          allenamento: a,
                          riga: r,
                          atletaId: atleta.id,
                          nome: nome,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Gli altri vedono l\'esercizio di sempre; $nome vede solo il '
                  'suo, anche sul tablet della squadra.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingSkeletonList(righe: 4),
        error: (errore, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli esercizi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(errore),
        ),
      ),
    );
  }

  /// «Come tutti · 3 × 10, 60 kg», «Al posto: Extrarotazione 2 × 10,
  /// elastico giallo», «Lo stesso, più leggero · 2 × 10, 30 kg», «Non lo
  /// fa».
  String _cosaFa(
    EsercizioSeduta riga,
    String atletaId,
    List<EsercizioSeduta> righe,
    Map<String, EsercizioSecco> esercizi,
  ) {
    final fa = cosaFa(riga, atletaId, righe);
    if (fa == null) return 'Non lo fa';
    final quanto = prescrizioneEsercizio(fa);
    if (!fa.variante) return 'Come tutti · $quanto';
    if (fa.esercizioId == riga.esercizioId) {
      return 'Lo stesso, più leggero · $quanto';
    }
    return 'Al posto: '
        '${esercizi[fa.esercizioId]?.nome ?? 'esercizio tolto dall\'elenco'} '
        '$quanto';
  }
}

/// Un esercizio di tutti e, sotto, cosa fa l'atleta.
class _RigaAtleta extends StatelessWidget {
  const _RigaAtleta({
    required this.numero,
    required this.nome,
    required this.cosaFa,
    required this.cambiato,
    required this.inEvidenza,
    required this.onTap,
    super.key,
  });

  final int numero;
  final String nome;
  final String cosaFa;

  /// Non lo fa come tutti: il testo risalta.
  final bool cambiato;
  final bool inEvidenza;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Material(
      color: inEvidenza ? colori.azioneTenue : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.altezzaMinimaRiga,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s8,
              AppSpacing.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$numero',
                    style: AppTypography.numerica(AppTypography.corpoForte)
                        .copyWith(color: colori.testoSecondario),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cosaFa,
                        style: AppTypography.numerica(AppTypography.corpo)
                            .copyWith(
                              color: cambiato
                                  ? colori.testo
                                  : colori.testoSecondario,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colori.testoSecondario),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
