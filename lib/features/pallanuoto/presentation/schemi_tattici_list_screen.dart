import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../application/schemi_tattici_providers.dart';
import '../domain/schema_tattico.dart';
import 'schema_tattico_form_screen.dart';
import 'schema_tattico_viewer_screen.dart';

String _etichettaCampo(String campo) =>
    campo == 'meta' ? 'Metà campo' : 'Campo intero';

/// Elenco degli schemi tattici del club: l'allenatore li crea/modifica
/// (FAB "Nuovo schema", tocco apre l'editor), l'atleta li sfoglia in
/// sola lettura ([soloLettura]: nessun FAB, il tocco apre solo la
/// vista, mai l'editor).
class SchemiTatticiListScreen extends ConsumerWidget {
  const SchemiTatticiListScreen({
    required this.clubId,
    this.soloLettura = false,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;
  final bool soloLettura;

  /// null = nessun filtro (mostra gli schemi di tutti i gruppi).
  final String? filtroGruppoId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

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
                  (s) => s.gruppoId == filtroGruppoId || s.gruppoId == null,
                )
                .toList(),
          );

    void apriNuovo() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchemaTatticoFormScreen(clubId: clubId),
      ),
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('Schemi tattici')),
      body: schemiAsync.when(
        data: (schemi) => schemi.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                    icona: Icons.sports_outlined,
                    titolo: 'Nessuno schema',
                    descrizione: soloLettura
                        ? 'L\'allenatore non ha ancora salvato nessuno '
                              'schema tattico.'
                        : 'Crea il primo schema sulla lavagna tattica.',
                    azionePrincipale: soloLettura
                        ? 'Torna indietro'
                        : 'Nuovo schema',
                    onAzionePrincipale: soloLettura ? null : apriNuovo,
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final categoria in _categorieOrdinate(schemi)) ...[
                      SectionHeader(
                        categoria.isEmpty ? 'Senza categoria' : categoria,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      AppListPanel(
                        righe: [
                          for (final s in schemi.where(
                            (s) => s.categoria == categoria,
                          ))
                            _rigaSchema(context, s),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                  ],
                ),
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli schemi.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
      floatingActionButton: soloLettura
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

  AppListRow _rigaSchema(BuildContext context, SchemaTattico s) {
    return AppListRow(
      titolo: s.titolo,
      sottotitolo:
          '${_etichettaCampo(s.campo)}'
          '${s.passi.length > 1 ? ' · ${s.passi.length} passi' : ''} · '
          'Aggiornato il ${_formattaData(s.aggiornatoIl)}',
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => soloLettura
              ? SchemaTatticoViewerScreen(schema: s)
              : SchemaTatticoFormScreen(clubId: clubId, schema: s),
        ),
      ),
    );
  }
}
