import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/section_header.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../test/application/test_club_providers.dart';
import '../../test/domain/massimale.dart';
import '../../test/domain/test_club.dart' show UnitaTest, formattaValore;
import '../domain/esercizio_secco.dart';
import '../domain/varianti_secco.dart';

/// Nella seduta a secco dell'allenatore, sotto gli esercizi: per ogni
/// esercizio con il carico in percentuale ("70%") i chili di ogni atleta
/// della squadra, dal suo ultimo massimale — da dire anche a chi non ha
/// il telefono. Niente se nessun carico è in percentuale.
class ChiliDiOgnuno extends ConsumerWidget {
  const ChiliDiOgnuno({
    required this.allenamento,
    required this.righe,
    required this.esercizi,
    super.key,
  });

  final Allenamento allenamento;
  final List<EsercizioSeduta> righe;
  final Map<String, EsercizioSecco> esercizi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inPercentuale = [
      for (final r in righe)
        if (percentualeDelCarico(r.carico) != null) r,
    ];
    if (inPercentuale.isEmpty) return const SizedBox.shrink();
    final massimali = ref.watch(massimaliProvider(allenamento.clubId));
    final atleti = [
      for (final a
          in ref
                  .watch(
                    atletiListProvider((
                      clubId: allenamento.clubId,
                      includeInactive: false,
                    )),
                  )
                  .value ??
              const <Atleta>[])
        if (allenamento.gruppoId == null || a.gruppoId == allenamento.gruppoId)
          a,
    ];

    String nomeDi(EsercizioSeduta r) => [
      esercizi[r.esercizioId]?.nome ?? 'Esercizio tolto dall\'elenco',
      if (r.variante) '(variante)',
    ].join(' ');

    // Chi fa l'esercizio: di una variante i suoi atleti, di uno di tutti
    // chi non ne ha una variante e non ne è escluso.
    List<Atleta> chiLoFa(EsercizioSeduta r) => [
      for (final a in atleti)
        if (r.variante
            ? r.destinatari.soloAtleti.contains(a.id)
            : identical(cosaFa(r, a.id, righe), r))
          a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s24),
        const TitoloSezione(
          'Chili di ognuno',
          spiegazione:
              'Dal massimale di ogni atleta in "Test e classifiche", '
              'arrotondati al chilo.',
        ),
        AppListPanel(
          righe: [
            for (final r in inPercentuale)
              Builder(
                builder: (context) {
                  final p = percentualeDelCarico(r.carico)!;
                  final suoi = massimali[r.esercizioId] ?? const {};
                  final atleti = chiLoFa(r);
                  final con = atleti.where((a) => suoi.containsKey(a.id));
                  return AppListRow(
                    titolo: nomeDi(r),
                    sottotitolo: [
                      '${volumeEsercizio(r)} al ${formattaPercentualeCarico(p)}',
                      if (con.isEmpty)
                        'nessuno ha il massimale'
                      else
                        '${con.length} di ${atleti.length} con il massimale',
                    ].join(' · '),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _mostra(
                      context,
                      nome: nomeDi(r),
                      riga: r,
                      percentuale: p,
                      atleti: atleti,
                      massimali: suoi,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  /// I chili di ogni atleta per un esercizio: prima chi ha il massimale.
  void _mostra(
    BuildContext context, {
    required String nome,
    required EsercizioSeduta riga,
    required double percentuale,
    required List<Atleta> atleti,
    required Map<String, Massimale> massimali,
  }) {
    final ordinati = [...atleti]
      ..sort((a, b) {
        final ma = massimali.containsKey(a.id);
        final mb = massimali.containsKey(b.id);
        if (ma != mb) return ma ? -1 : 1;
        return a.nomeCompleto.toLowerCase().compareTo(
          b.nomeCompleto.toLowerCase(),
        );
      });
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final colori = sheetContext.colori;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nome,
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              Text(
                '${volumeEsercizio(riga)} al '
                '${formattaPercentualeCarico(percentuale)} del massimale',
                style: AppTypography.numerica(AppTypography.piccolo)
                    .copyWith(color: colori.testoSecondario),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppListPanel(
                righe: [
                  for (final a in ordinati)
                    switch (massimali[a.id]) {
                      final m? => AppListRow(
                        titolo: a.nomeCompleto,
                        sottotitolo:
                            'massimale ${formattaValore(UnitaTest.chili, m.kg)}'
                            ' · ${traQuanto(m.data)}',
                        trailing: Text(
                          formattaValore(
                            UnitaTest.chili,
                            chiliDaPercentuale(percentuale, m.kg),
                          ),
                          style: AppTypography.numerica(
                            AppTypography.numeroMedio,
                          ).copyWith(color: colori.testo),
                        ),
                      ),
                      null => AppListRow(
                        titolo: a.nomeCompleto,
                        sottotitolo: 'Nessun massimale',
                      ),
                    },
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
