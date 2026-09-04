import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';

/// Menu a tendina per scegliere la Stagione su cui filtrare le
/// statistiche. Preseleziona la stagione che contiene la data odierna,
/// altrimenti la piu' recente; richiama [onCambiata] appena la selezione
/// e' pronta e ad ogni cambio successivo.
class SelettoreStagione extends ConsumerStatefulWidget {
  const SelettoreStagione({
    required this.clubId,
    required this.onCambiata,
    super.key,
  });

  final String clubId;
  final ValueChanged<Stagione?> onCambiata;

  @override
  ConsumerState<SelettoreStagione> createState() => _SelettoreStagioneState();
}

class _SelettoreStagioneState extends ConsumerState<SelettoreStagione> {
  Stagione? _selezionata;
  String? _idNotificato;

  @override
  Widget build(BuildContext context) {
    final stagioniAsync = ref.watch(stagioniListProvider(widget.clubId));

    return stagioniAsync.when(
      data: (stagioni) {
        if (stagioni.isEmpty) {
          return const Text(
            'Nessuna stagione creata: creane una (tab "Stagioni") per '
            'vedere le statistiche stagionali.',
          );
        }
        final ordinate = [...stagioni]
          ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio));

        // Ogni emissione dello stream porta istanze Stagione nuove (anche
        // a parita' di dati): si ri-risolve sempre per id, sia per non
        // perdere la scelta manuale dell'utente sia perche' il valore del
        // dropdown deve essere la STESSA istanza presente in `items`.
        final selezionataId = _selezionata?.id;
        Stagione trovata = ordinate.first;
        var trovataCorrispondenza = false;
        if (selezionataId != null) {
          for (final s in ordinate) {
            if (s.id == selezionataId) {
              trovata = s;
              trovataCorrispondenza = true;
              break;
            }
          }
        }
        if (!trovataCorrispondenza) {
          final oggi = DateTime.now();
          final correnti = ordinate.where(
            (s) => !oggi.isBefore(s.dataInizio) && !oggi.isAfter(s.dataFine),
          );
          trovata = correnti.isNotEmpty ? correnti.first : ordinate.first;
        }
        _selezionata = trovata;

        if (_idNotificato != trovata.id) {
          _idNotificato = trovata.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onCambiata(trovata);
          });
        }

        return DropdownButtonFormField<Stagione>(
          key: ValueKey(trovata.id),
          initialValue: trovata,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Stagione'),
          items: [
            for (final s in ordinate)
              DropdownMenuItem(value: s, child: Text(s.nome)),
          ],
          onChanged: (s) {
            if (s == null) return;
            setState(() {
              _selezionata = s;
              _idNotificato = s.id;
            });
            widget.onCambiata(s);
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Errore nel caricamento stagioni: ${messaggioErrore(e)}',
      ),
    );
  }
}
