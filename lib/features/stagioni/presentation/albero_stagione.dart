import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/ordine_badge.dart';
import '../application/mesocicli_providers.dart';
import '../application/microcicli_providers.dart';
import '../domain/macrociclo.dart';
import '../domain/mesociclo.dart';
import 'macrociclo_detail_screen.dart';
import 'mesociclo_detail_screen.dart';
import 'microciclo_detail_screen.dart';

typedef FormattaData = String Function(DateTime data);

/// Riga di un macrociclo nella panoramica ad albero della stagione: si apre
/// per mostrare i suoi mesocicli (che a loro volta si aprono sui
/// microcicli), per vedere la struttura a colpo d'occhio senza dover
/// entrare in ogni dettaglio. Riordino, duplicazione ed eliminazione
/// restano sulle rispettive schermate di dettaglio — qui si naviga soltanto.
class RigaAlberoMacrociclo extends StatefulWidget {
  const RigaAlberoMacrociclo({
    required this.macrociclo,
    required this.nomeStagione,
    required this.formattaData,
    super.key,
  });

  final Macrociclo macrociclo;
  final String nomeStagione;
  final FormattaData formattaData;

  @override
  State<RigaAlberoMacrociclo> createState() => _RigaAlberoMacrocicloState();
}

class _RigaAlberoMacrocicloState extends State<RigaAlberoMacrociclo> {
  bool _espanso = false;

  @override
  Widget build(BuildContext context) {
    final macrociclo = widget.macrociclo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_espanso ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => _espanso = !_espanso),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: AppSpacing.s4),
              OrdineBadge(numero: macrociclo.ordine),
            ],
          ),
          titolo: macrociclo.nome,
          sottotitolo:
              '${widget.formattaData(macrociclo.dataInizio)} — '
              '${widget.formattaData(macrociclo.dataFine)}',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MacrocicloDetailScreen(
                macrociclo: macrociclo,
                nomeStagione: widget.nomeStagione,
              ),
            ),
          ),
        ),
        if (_espanso)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s28),
            child: _MesocicliAnnidati(
              macrociclo: macrociclo,
              nomeStagione: widget.nomeStagione,
              formattaData: widget.formattaData,
            ),
          ),
      ],
    );
  }
}

class _MesocicliAnnidati extends ConsumerWidget {
  const _MesocicliAnnidati({
    required this.macrociclo,
    required this.nomeStagione,
    required this.formattaData,
  });

  final Macrociclo macrociclo;
  final String nomeStagione;
  final FormattaData formattaData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesocicliAsync = ref.watch(mesocicliListProvider(macrociclo.id));
    return mesocicliAsync.when(
      data: (mesocicli) => mesocicli.isEmpty
          ? _RigaVuota('Nessun mesociclo')
          : Column(
              children: [
                for (final me in mesocicli)
                  _RigaMesociclo(
                    mesociclo: me,
                    nomeStagione: nomeStagione,
                    nomeMacrociclo: macrociclo.nome,
                    formattaData: formattaData,
                  ),
              ],
            ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RigaMesociclo extends StatefulWidget {
  const _RigaMesociclo({
    required this.mesociclo,
    required this.nomeStagione,
    required this.nomeMacrociclo,
    required this.formattaData,
  });

  final Mesociclo mesociclo;
  final String nomeStagione;
  final String nomeMacrociclo;
  final FormattaData formattaData;

  @override
  State<_RigaMesociclo> createState() => _RigaMesocicloState();
}

class _RigaMesocicloState extends State<_RigaMesociclo> {
  bool _espanso = false;

  @override
  Widget build(BuildContext context) {
    final mesociclo = widget.mesociclo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          leading: IconButton(
            icon: Icon(_espanso ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _espanso = !_espanso),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          titolo: mesociclo.nome,
          sottotitolo:
              '${widget.formattaData(mesociclo.dataInizio)} — '
              '${widget.formattaData(mesociclo.dataFine)}',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MesocicloDetailScreen(
                mesociclo: mesociclo,
                nomeStagione: widget.nomeStagione,
                nomeMacrociclo: widget.nomeMacrociclo,
              ),
            ),
          ),
        ),
        if (_espanso)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s28),
            child: _MicrocicliAnnidati(
              mesociclo: mesociclo,
              nomeStagione: widget.nomeStagione,
              nomeMacrociclo: widget.nomeMacrociclo,
              formattaData: widget.formattaData,
            ),
          ),
      ],
    );
  }
}

class _MicrocicliAnnidati extends ConsumerWidget {
  const _MicrocicliAnnidati({
    required this.mesociclo,
    required this.nomeStagione,
    required this.nomeMacrociclo,
    required this.formattaData,
  });

  final Mesociclo mesociclo;
  final String nomeStagione;
  final String nomeMacrociclo;
  final FormattaData formattaData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(microcicliListProvider(mesociclo.id));
    return microcicliAsync.when(
      data: (microcicli) => microcicli.isEmpty
          ? _RigaVuota('Nessun microciclo')
          : Column(
              children: [
                for (final mc in microcicli)
                  AppListRow(
                    titolo: mc.nome != null && mc.nome!.isNotEmpty
                        ? mc.nome!
                        : (mc.numeroSettimana != null
                              ? 'Settimana ${mc.numeroSettimana}'
                              : 'Microciclo'),
                    sottotitolo:
                        '${formattaData(mc.dataInizio)} — '
                        '${formattaData(mc.dataFine)}'
                        '${mc.tipo != null && mc.tipo!.isNotEmpty ? ' · ${mc.tipo}' : ''}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MicrocicloDetailScreen(
                          microciclo: mc,
                          nomeStagione: nomeStagione,
                          nomeMacrociclo: nomeMacrociclo,
                          nomeMesociclo: mesociclo.nome,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RigaVuota extends StatelessWidget {
  const _RigaVuota(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s8,
        horizontal: AppSpacing.s16,
      ),
      child: Text(
        testo,
        style: AppTypography.piccolo.copyWith(color: AppColors.testoSecondario),
      ),
    );
  }
}
