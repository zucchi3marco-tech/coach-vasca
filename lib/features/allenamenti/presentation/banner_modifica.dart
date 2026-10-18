import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../application/modifiche_providers.dart';
import '../data/modifiche_repository.dart';
import '../domain/allenamento.dart';
import '../domain/modifica_allenamento.dart';
import 'confronto_modifica_screen.dart';

/// Segna la modifica come vista dal capo, rilegge i due elenchi che la
/// mostrano e dà l'avviso. Torna true se è andata. Un errore diventa un
/// avviso, non un'eccezione.
Future<bool> segnaModificaVista(
  BuildContext context,
  WidgetRef ref,
  ModificaAllenamento modifica,
) async {
  final messaggero = ScaffoldMessenger.of(context);
  final repository = ref.read(modificheRepositoryProvider);
  try {
    await repository.segnaVista(modifica.id);
    // Se intanto la pagina è stata chiusa, `ref` non si può più usare: gli
    // elenchi si rileggono comunque alla prossima apertura.
    if (context.mounted) {
      ref.invalidate(modificaApertaProvider(modifica.allenamentoId));
      ref.invalidate(modificheDaControllareProvider(modifica.clubId));
    }
    messaggero.showSnackBar(
      const SnackBar(content: Text('Segnato come visto')),
    );
    return true;
  } catch (e) {
    messaggero.showSnackBar(
      SnackBar(content: Text('Non è stato segnato. ${messaggioErrore(e)}')),
    );
    return false;
  }
}

/// La fascia sotto la testata di un allenamento che un altro ha cambiato
/// (o aggiunto) e che il capo non ha ancora visto: chi, quando, e due
/// azioni, "Cosa è cambiato" e "Visto". Senza modifica da vedere (o nella
/// demo, o senza rete) non c'è.
class BannerModifica extends ConsumerStatefulWidget {
  const BannerModifica({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<BannerModifica> createState() => _BannerModificaState();
}

class _BannerModificaState extends ConsumerState<BannerModifica> {
  bool _occupato = false;

  Future<void> _visto(ModificaAllenamento modifica) async {
    if (_occupato) return;
    setState(() => _occupato = true);
    try {
      await segnaModificaVista(context, ref, modifica);
    } finally {
      if (mounted) setState(() => _occupato = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modifica = ref
        .watch(modificaApertaProvider(widget.allenamento.id))
        .value;
    if (modifica == null) return const SizedBox.shrink();
    final colori = context.colori;
    final chi = modifica.nuovo
        ? 'Aggiunto da ${modifica.autoriTesto}'
        : 'Modificato da ${modifica.autoriTesto}';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.paddingPannello),
        decoration: BoxDecoration(
          color: colori.attenzioneTenue,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.attenzione),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note, color: colori.attenzione),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: chi,
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${quandoFa(modifica.ultimaAt)}',
                          style: AppTypography.corpo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s4,
              children: [
                if (!modifica.nuovo)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ConfrontoModificaScreen(
                          modifica: modifica,
                          allenamento: widget.allenamento,
                        ),
                      ),
                    ),
                    child: const Text('Cosa è cambiato'),
                  ),
                TextButton(
                  onPressed: _occupato ? null : () => _visto(modifica),
                  child: const Text('Visto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
