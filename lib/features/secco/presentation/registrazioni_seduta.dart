import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/section_header.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../carico/application/carico_providers.dart';
import '../../carico/domain/carico_rpe.dart';
import '../application/secco_providers.dart';
import '../domain/esercizio_secco.dart';
import '../domain/serie_fatta.dart';

/// Nella seduta a secco dell'allenatore, sotto gli esercizi: chi l'ha
/// registrata dal telefono, con le serie fatte e quanto è stata dura; un
/// tocco apre cosa ha fatto in ogni esercizio, con il carico. Senza
/// registrazioni non mostra niente.
class RegistrazioniSeduta extends ConsumerWidget {
  const RegistrazioniSeduta({
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
    final fatte =
        ref.watch(serieFatteSedutaProvider(allenamento.id)).value ??
        const <SerieFatta>[];
    if (fatte.isEmpty) return const SizedBox.shrink();
    final atleti = {
      for (final a
          in ref
                  .watch(
                    atletiListProvider((
                      clubId: allenamento.clubId,
                      includeInactive: true,
                    )),
                  )
                  .value ??
              const <Atleta>[])
        a.id: a,
    };
    final rpe = {
      for (final r
          in ref.watch(rpeClubProvider(allenamento.clubId)).value ?? const [])
        if (r.eventoTipo == 'allenamento' && r.eventoId == allenamento.id)
          r.atletaId: r.rpe,
    };
    final perAtleta = <String, List<SerieFatta>>{};
    for (final f in fatte) {
      (perAtleta[f.atletaId] ??= []).add(f);
    }
    String nome(String id) => atleti[id]?.nomeCompleto ?? 'Atleta tolto';
    final ordine = perAtleta.keys.toList()
      ..sort((a, b) => nome(a).toLowerCase().compareTo(nome(b).toLowerCase()));

    String riassunto(String atletaId) {
      final conto = contaSerie(righe, perAtleta[atletaId]!);
      return [
        '${conto.fatte} serie su ${conto.totali}',
        if (rpe[atletaId] case final v?) 'RPE $v',
      ].join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s24),
        TitoloSezione(
          'Registrata dagli atleti',
          conteggio: ordine.length,
          spiegazione: 'Le serie segnate dal telefono, con il carico usato.',
        ),
        AppListPanel(
          righe: [
            for (final id in ordine)
              AppListRow(
                titolo: nome(id),
                sottotitolo: riassunto(id),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _dettaglio(
                  context,
                  nome: nome(id),
                  riassunto: [
                    riassunto(id).split(' · ').first,
                    if (rpe[id] case final v?) descriviRpe(v),
                  ].join(' · '),
                  fatte: perAtleta[id]!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Cosa ha fatto un atleta, esercizio per esercizio.
  void _dettaglio(
    BuildContext context, {
    required String nome,
    required String riassunto,
    required List<SerieFatta> fatte,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colori = sheetContext.colori;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              Text(
                riassunto,
                style: AppTypography.numerica(AppTypography.piccolo)
                    .copyWith(color: colori.testoSecondario),
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final (i, r) in righe.indexed) ...[
                if (i > 0) Divider(height: 1, color: colori.linea),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                  child: _RigaFatta(
                    nome:
                        esercizi[r.esercizioId]?.nome ??
                        'Esercizio tolto dall\'elenco',
                    riga: r,
                    fatte: fatteDellaRiga(r.id, fatte),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Un esercizio nel dettaglio di un atleta: il nome, cosa ha fatto
/// ("3 × 12, elastico rosso") e, se ne mancano, quante serie su quante.
class _RigaFatta extends StatelessWidget {
  const _RigaFatta({
    required this.nome,
    required this.riga,
    required this.fatte,
  });

  final String nome;
  final EsercizioSeduta riga;
  final List<SerieFatta> fatte;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final fatto = descriviFatte(fatte, aTempo: riga.durataS != null);
    final contate = fatte.where((f) => f.serie <= riga.serie).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: AppTypography.corpoForte.copyWith(color: colori.testo),
        ),
        const SizedBox(height: 2),
        Text(
          fatto == null
              ? 'Non fatto'
              : [
                  fatto,
                  if (contate < riga.serie) '$contate di ${riga.serie} serie',
                ].join(' · '),
          style: AppTypography.numerica(
            AppTypography.corpo,
          ).copyWith(color: fatto == null ? colori.testoTenue : colori.testo),
        ),
        Text(
          'Previsto: ${prescrizioneEsercizio(riga)}',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}
