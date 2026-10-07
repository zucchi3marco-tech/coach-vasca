import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/entrata_a_cascata.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/schemi_tattici_providers.dart';
import '../domain/schema_tattico.dart';
import 'schema_tattico_form_screen.dart';
import 'schema_tattico_viewer_screen.dart';

String _etichettaCampo(String campo) =>
    campo == 'meta' ? 'Metà campo' : 'Campo intero';

/// Elenco degli schemi tattici del club: l'allenatore li crea/modifica
/// (pulsante "Nuovo schema" in testata, tocco apre l'editor), l'atleta
/// li sfoglia in sola lettura ([soloLettura]: nessuna azione, il tocco
/// apre solo la vista, mai l'editor).
class SchemiTatticiListScreen extends ConsumerWidget {
  const SchemiTatticiListScreen({
    required this.clubId,
    this.soloLettura = false,
    this.filtroGruppoId,
    this.comeTab = false,
    super.key,
  });

  final String clubId;
  final bool soloLettura;

  /// Usata come corpo di una tab della home: senza barra propria (c'è già
  /// quella della home).
  final bool comeTab;

  /// null = nessun filtro (mostra gli schemi di tutti i gruppi).
  final String? filtroGruppoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuttiGliSchemi = ref.watch(schemiTatticiListProvider(clubId));
    // Uno schema con gruppo assegnato è visibile solo a chi lavora con
    // quel gruppo; uno senza gruppo resta visibile a tutti (stessa
    // regola di PresenzeScreen/AllenamentiListScreen).
    final schemiAsync = filtroGruppoId == null
        ? tuttiGliSchemi
        : tuttiGliSchemi.whenData(
            (schemi) => schemi
                .where(
                  (s) => visibileNelGruppoMultiplo(
                    gruppiDelRecord: s.gruppoIds,
                    gruppoSelezionato: filtroGruppoId,
                  ),
                )
                .toList(),
          );
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: filtroGruppoId)),
    );
    final viola = context.dominio.evidenzaViola;

    void apriNuovo() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchemaTatticoFormScreen(clubId: clubId),
      ),
    );

    Widget scheda(SchemaTattico s) => SchedaElenco(
      leading: IconaRiquadro(Icons.sports, colore: viola, dimensione: 48),
      titolo: s.titolo,
      sottotitolo: [
        s.passi.length > 1
            ? '${_etichettaCampo(s.campo)}, ${s.passi.length} passi'
            : _etichettaCampo(s.campo),
        'aggiornato ${dataCompatta(s.aggiornatoIl)}',
      ].join(' · '),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => soloLettura
              ? SchemaTatticoViewerScreen(schema: s)
              : SchemaTatticoFormScreen(clubId: clubId, schema: s),
        ),
      ),
    );

    return AppScaffold(
      appBar: comeTab ? null : AppBar(title: const Text('Schemi tattici')),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          if (comeTab) ...[
            EntrataACascata(
              indice: 0,
              child: TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Schemi tattici',
                sottotitolo: switch (schemiAsync.value?.length) {
                  null || 0 => null,
                  1 => '1 schema sulla lavagna',
                  final n => '$n schemi sulla lavagna',
                },
                azioni: [
                  if (!soloLettura)
                    AzioneTestata(
                      icona: Icons.draw_outlined,
                      etichetta: 'Nuovo schema',
                      principale: true,
                      onTap: apriNuovo,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
          schemiAsync.when(
            data: (schemi) => schemi.isEmpty
                ? EmptyState(
                    icona: Icons.sports_outlined,
                    titolo: 'Nessuno schema',
                    descrizione: soloLettura
                        ? 'L\'allenatore non ha ancora salvato nessuno '
                              'schema tattico.'
                        : 'Crea il primo schema sulla lavagna tattica.',
                    azionePrincipale: soloLettura
                        ? 'Torna indietro'
                        : 'Nuovo schema',
                    onAzionePrincipale: soloLettura
                        ? () => Navigator.of(context).maybePop()
                        : apriNuovo,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final categoria in _categorieOrdinate(schemi)) ...[
                        TitoloSezione(
                          categoria.isEmpty ? 'Senza categoria' : categoria,
                          conteggio: schemi
                              .where((s) => s.categoria == categoria)
                              .length,
                        ),
                        GrigliaSchede(
                          figli: [
                            for (final s in schemi.where(
                              (s) => s.categoria == categoria,
                            ))
                              scheda(s),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s24),
                      ],
                    ],
                  ),
            loading: () => const LoadingSkeletonList(righe: 4),
            error: (error, _) => ErrorBanner(
              messaggio: 'Non è stato possibile caricare gli schemi.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ],
      ),
      // Fuori dalle tab (aperto da una scheda) la testata non c'e': il
      // pulsante "+" resta l'unico modo di creare uno schema.
      floatingActionButton: soloLettura || comeTab
          ? null
          : FloatingActionButton(
              heroTag: 'fab-nuovo-schema-tattico',
              onPressed: apriNuovo,
              tooltip: 'Nuovo schema',
              child: const Icon(Icons.add),
            ),
    );
  }

  /// Categorie presenti, in ordine alfabetico — quella vuota ("senza
  /// categoria") sempre per ultima, non alfabeticamente prima di tutte.
  List<String> _categorieOrdinate(List<SchemaTattico> schemi) {
    final categorie = schemi.map((s) => s.categoria).toSet().toList()
      ..sort((a, b) {
        if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
        return a.compareTo(b);
      });
    return categorie;
  }
}
