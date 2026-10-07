import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../atleti/domain/atleta.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';

/// Menu a tendina per scegliere la Stagione su cui filtrare le
/// statistiche. Preseleziona [idIniziale] se indicato, altrimenti la
/// stagione che contiene la data odierna, altrimenti la piu' recente;
/// richiama [onCambiata] appena la selezione e' pronta e ad ogni cambio
/// successivo.
class SelettoreStagione extends ConsumerStatefulWidget {
  const SelettoreStagione({
    required this.clubId,
    required this.onCambiata,
    this.atleta,
    this.idIniziale,
    super.key,
  });

  final String clubId;
  final ValueChanged<Stagione?> onCambiata;

  /// Statistiche di un atleta: solo le stagioni del suo gruppo e quelle di
  /// club. Senza filtro un U16 si vedeva proporre la stagione dell'U14.
  final Atleta? atleta;

  /// Stagione da cui si è arrivati (es. il dettaglio di una stagione).
  final String? idIniziale;

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
      data: (tutte) {
        final atleta = widget.atleta;
        final stagioni = atleta == null
            ? tutte
            : stagioniDiAtleta(tutte, atleta.gruppoId);
        if (stagioni.isEmpty) {
          return Text(
            atleta == null
                ? 'Nessuna stagione creata: creane una (tab "Stagioni") per '
                      'vedere le statistiche stagionali.'
                : 'Non c\'è ancora una stagione per questo gruppo: la crea '
                      'l\'allenatore.',
            style: AppTypography.piccolo.copyWith(
              color: context.colori.testoSecondario,
            ),
          );
        }
        final ordinate = [...stagioni]
          ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio));

        // Ogni emissione dello stream porta istanze Stagione nuove (anche
        // a parita' di dati): si ri-risolve sempre per id, sia per non
        // perdere la scelta manuale dell'utente sia perche' il valore del
        // dropdown deve essere la STESSA istanza presente in `items`.
        final selezionataId = _selezionata?.id ?? widget.idIniziale;
        Stagione? trovata;
        if (selezionataId != null) {
          for (final s in ordinate) {
            if (s.id == selezionataId) {
              trovata = s;
              break;
            }
          }
        }
        // Per un atleta, a parità di date, quella del suo gruppo prima di
        // quella di club.
        trovata ??= atleta == null
            ? _inCorso(ordinate)
            : stagioneCorrenteDiGruppo(ordinate, atleta.gruppoId);
        final scelta = trovata ?? ordinate.first;
        _selezionata = scelta;

        if (_idNotificato != scelta.id) {
          _idNotificato = scelta.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onCambiata(scelta);
          });
        }

        return AppSelect<Stagione>(
          key: ValueKey(scelta.id),
          etichetta: 'Stagione',
          value: scelta,
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
      loading: () =>
          const LoadingSkeleton(height: AppSpacing.altezzaMinimaBersaglio),
      error: (e, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare le stagioni.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(e),
      ),
    );
  }

  static Stagione? _inCorso(List<Stagione> stagioni) {
    final oggi = DateTime.now();
    for (final s in stagioni) {
      if (!oggi.isBefore(s.dataInizio) && !oggi.isAfter(s.dataFine)) return s;
    }
    return null;
  }
}
