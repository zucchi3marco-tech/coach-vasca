import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/allenamenti_providers.dart';
import '../application/modifiche_providers.dart';
import '../domain/modifica_allenamento.dart';
import 'allenamento_detail_screen.dart';

/// "U14 · mar 20 ott · 25 minuti fa": dove, per quando e da quanto è
/// cambiato. Le parti che non si sanno si saltano.
String sottotitoloModifica(
  ModificaAllenamento modifica, {
  String? squadra,
  DateTime? adesso,
}) => [
  ?squadra,
  if (modifica.data != null) dataCompatta(modifica.data!),
  quandoFa(modifica.ultimaAt, adesso: adesso),
].join(' · ');

/// Apre l'allenamento della modifica (con la fascia "Modificato da…").
/// L'allenamento si prende dall'elenco del club; se non c'è ancora (la
/// copia locale non si è aggiornata) un avviso.
void apriAllenamentoDellaModifica(
  BuildContext context,
  WidgetRef ref,
  ModificaAllenamento modifica,
) {
  final allenamento = ref
      .read(allenamentiListProvider(modifica.clubId))
      .value
      ?.where((a) => a.id == modifica.allenamentoId)
      .firstOrNull;
  if (allenamento == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Non trovo questo allenamento: riprova tra un momento.'),
      ),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AllenamentoDetailScreen(allenamento: allenamento),
    ),
  );
}

/// Una modifica da controllare: chi ha cambiato cosa, e dove e quando.
class RigaModifica extends StatelessWidget {
  const RigaModifica({
    required this.modifica,
    required this.onTap,
    this.squadra,
    super.key,
  });

  final ModificaAllenamento modifica;
  final String? squadra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final sottotitolo = sottotitoloModifica(modifica, squadra: squadra);
    return Semantics(
      button: true,
      label: '${modifica.frase}. $sottotitolo',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modifica.frase,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      sottotitolo,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
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
    );
  }
}

/// Tutte le modifiche da controllare, dalla più recente (da "Vedi tutte"
/// in "Oggi").
class ModificheDaControllareScreen extends ConsumerWidget {
  const ModificheDaControllareScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final modifiche = ref.watch(modificheDaControllareProvider(clubId));
    final nomiSquadre = {
      for (final g in ref.watch(gruppiListProvider(clubId)).value ?? const [])
        g.id: g.nome,
    };
    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          const TestataPagina(
            titolo: 'Da controllare',
            sottotitolo: 'Allenamenti cambiati da altri nelle tue squadre.',
          ),
          const SizedBox(height: AppSpacing.s20),
          modifiche.when(
            loading: () => const LoadingSkeletonList(righe: 3),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(
                  messaggio: 'Non è stato possibile leggere le modifiche.',
                  suggerimento: 'Controlla la connessione e riprova.',
                  dettaglioTecnico: messaggioErrore(e),
                ),
                const SizedBox(height: AppSpacing.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(modificheDaControllareProvider(clubId)),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Riprova'),
                  ),
                ),
              ],
            ),
            data: (elenco) => elenco.isEmpty
                ? const RiquadroVuoto('Non c\'è niente da controllare.')
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingPannello,
                      vertical: AppSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colori.superficie,
                      borderRadius: BorderRadius.circular(AppRadius.pannello),
                      border: Border.all(color: colori.linea),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < elenco.length; i++) ...[
                          RigaModifica(
                            modifica: elenco[i],
                            squadra: nomiSquadre[elenco[i].gruppoId],
                            onTap: () => apriAllenamentoDellaModifica(
                              context,
                              ref,
                              elenco[i],
                            ),
                          ),
                          if (i != elenco.length - 1)
                            Divider(height: 1, color: colori.linea),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
