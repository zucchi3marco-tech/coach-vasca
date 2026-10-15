import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../domain/serie.dart';

/// Gli atleti di cui si parla nelle righe "per chi" di un allenamento:
/// quelli attivi del suo gruppo (di tutto il club senza gruppo), più
/// quelli già nominati dalle sue [serie] anche se intanto hanno cambiato
/// gruppo o sono stati archiviati — così riscritto il testo si rilegge
/// uguale. [tutti] sono gli atleti del club, archiviati compresi.
List<Atleta> atletiDellAllenamento(
  List<Atleta> tutti, {
  required String? gruppoId,
  Iterable<DatiSerie> serie = const [],
}) {
  final nominati = {
    for (final s in serie) ...[
      ...s.destinatari.soloAtleti,
      ...s.destinatari.tranneAtleti,
    ],
  };
  return [
    for (final a in tutti)
      if ((a.attivo &&
              (gruppoId == null ||
                  a.gruppoId == gruppoId ||
                  // Chi si allena con questo gruppo in giorni fissi.
                  a.altroGruppoId == gruppoId)) ||
          nominati.contains(a.id))
        a,
  ];
}

/// "Portieri", "Rossi, Bianchi", "Tutti tranne Rossi": per chi è una
/// serie, con i nomi brevi degli [atleti] del gruppo; null per tutto il
/// gruppo.
String? labelPerChi(Destinatari d, List<Atleta> atleti) =>
    etichettaDestinatari(d, (id) {
      final atleta = atleti.where((a) => a.id == id).firstOrNull;
      return atleta == null ? null : nomeBreve(atleta, atleti);
    });

/// Per chi è una serie, sopra il suo titolo: un'icona e i destinatari, in
/// neutro (è un dato della serie, non un'azione né uno stato).
class EtichettaPerChi extends StatelessWidget {
  const EtichettaPerChi(this.testo, {this.grande = false, super.key});

  final String testo;

  /// A bordo vasca: si legge da mezzo metro.
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stile = (grande ? AppTypography.corpoForte : AppTypography.etichetta)
        .copyWith(color: colori.testo, fontWeight: FontWeight.w600);
    return Semantics(
      label: 'Per: $testo',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_outlined,
            size: grande ? 20 : 16,
            color: colori.testoSecondario,
          ),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              testo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: stile,
            ),
          ),
        ],
      ),
    );
  }
}
