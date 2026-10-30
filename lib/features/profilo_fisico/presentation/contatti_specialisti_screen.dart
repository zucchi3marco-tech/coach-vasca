import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../data/contatti_specialisti_repository.dart';
import '../domain/chi_mi_puo_aiutare.dart';

/// «Chi li ha contattati», da «Specialisti convenzionati», solo per il
/// responsabile (profilo fisico, passo D): i contatti degli atleti con
/// gli specialisti, mese per mese, con il totale di ognuno. Quando lo
/// specialista conferma i codici visti, il responsabile spunta la
/// visita: su queste si calcola la royalty.
class ContattiSpecialistiScreen extends ConsumerWidget {
  const ContattiSpecialistiScreen({required this.clubId, super.key});

  final String clubId;

  Future<void> _conferma(
    BuildContext context,
    WidgetRef ref,
    ContattoSpecialista contatto,
    bool confermata,
  ) async {
    try {
      await ref
          .read(contattiSpecialistiRepositoryProvider)
          .confermaVisita(contatto, confermata: confermata);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
    ref.invalidate(contattiSpecialistiProvider(clubId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final elencoAsync = ref.watch(contattiSpecialistiProvider(clubId));
    final elenco = elencoAsync.value ?? const <ContattoSpecialista>[];
    final oggi = DateTime.now();
    final delMese = elenco.where(
      (c) => c.giorno.year == oggi.year && c.giorno.month == oggi.month,
    );

    return AppScaffold(
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: 'Specialisti convenzionati',
            titolo: 'Chi li ha contattati',
            numeri: [
              NumeroTestata(
                valore: elencoAsync.hasValue ? '${delMese.length}' : '—',
                etichetta: 'Contatti questo mese',
              ),
              NumeroTestata(
                valore: elencoAsync.hasValue
                    ? '${delMese.where((c) => c.confermata).length}'
                    : '—',
                etichetta: 'Visite confermate',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Text(
              'Si segna un contatto quando un atleta tocca «Scrivi su '
              'WhatsApp» o «Apri il sito» di uno specialista, con il suo '
              'codice. Quando lo specialista ti dice i codici delle visite '
              'fatte, spunta «Visita confermata». Lo vedi solo tu.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          ...elencoAsync.when(
            data: (elenco) => elenco.isEmpty
                ? const [
                    EmptyState(
                      icona: Icons.forum_outlined,
                      titolo: 'Nessun contatto ancora',
                      descrizione:
                          'Gli atleti trovano gli specialisti nella loro '
                          'home, in «Chi mi può aiutare?». Qui vedrai chi li '
                          'contatta.',
                      azionePrincipale: '',
                    ),
                  ]
                : [
                    for (final mese in contattiPerMese(elenco)) ...[
                      TitoloSezione(
                        meseAnno(mese.mese),
                        conteggio: mese.contatti.length,
                      ),
                      AppListPanel(
                        righe: [
                          for (final t in mese.totali)
                            AppListRow(
                              titolo: t.nome,
                              sottotitolo:
                                  '${t.contatti} '
                                  '${t.contatti == 1 ? 'contatto' : 'contatti'}, '
                                  '${t.confermate} '
                                  '${t.confermate == 1 ? 'visita confermata' : 'visite confermate'}',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      AppListPanel(
                        righe: [
                          for (final c in mese.contatti)
                            AppListRow(
                              titolo: c.nomeAtleta,
                              sottotitolo:
                                  '${c.specialistaNome}: '
                                  '${c.problema.etichetta.toLowerCase()}\n'
                                  '${giornoMese(c.giorno)}, da '
                                  '${c.canale.etichetta}, codice ${c.codice}',
                              trailing: Semantics(
                                label: 'Visita confermata',
                                child: Checkbox(
                                  value: c.confermata,
                                  onChanged: (v) =>
                                      _conferma(context, ref, c, v ?? false),
                                ),
                              ),
                              onTap: () =>
                                  _conferma(context, ref, c, !c.confermata),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s24),
                    ],
                  ],
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 4),
              ),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare i contatti.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
