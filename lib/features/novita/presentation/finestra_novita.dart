import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../data/novita_viste.dart';
import '../domain/novita.dart';
import 'novita_screen.dart';

/// Dopo un aggiornamento mostra le novità importanti uscite dall'ultima
/// volta che questo telefono le ha viste. La prima volta su un telefono non
/// mostra niente (chi comincia adesso non riceve le novità vecchie), ma si
/// ricorda il punto di partenza. [context] deve stare sotto il Navigator;
/// [registro] serve ai test (di norma [registroNovita]).
Future<void> mostraNovitaSeServe(
  BuildContext context, {
  required bool atleta,
  List<Novita>? registro,
}) async {
  final elenco = registro ?? registroNovita;
  final ultimaVista = await leggiUltimaNovitaVista();
  final daMostrare = novitaDaMostrare(
    registro: elenco,
    ultimaVista: ultimaVista,
    atleta: atleta,
  );
  // Segnate come viste subito, prima della finestra: anche chiudendola
  // toccando fuori o con "indietro" non devono ripresentarsi.
  await segnaNovitaViste(elenco);
  if (daMostrare.isEmpty || !context.mounted) return;
  final tutte = await showDialog<bool>(
    context: context,
    builder: (_) => _FinestraNovita(novita: daMostrare),
  );
  if (tutte == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NovitaScreen(atleta: atleta, registro: elenco),
      ),
    );
  }
}

class _FinestraNovita extends StatelessWidget {
  const _FinestraNovita({required this.novita});

  final List<Novita> novita;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AlertDialog(
      backgroundColor: colori.superficie,
      title: Text(novita.length == 1 ? 'Una novità' : 'Novità'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, n) in novita.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s16),
                Text(
                  n.titolo,
                  style: AppTypography.corpoForte.copyWith(
                    color: colori.testo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  n.testo,
                  style: AppTypography.corpo.copyWith(
                    color: colori.testoSecondario,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Tutte le novità'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ho capito'),
        ),
      ],
    );
  }
}
