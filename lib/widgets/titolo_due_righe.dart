import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Titolo di AppBar su due righe: la sezione sopra (stile del titolo della
/// barra) e, sotto e piu' piccolo, di chi o di cosa si parla (atleta,
/// gruppo, le due squadre). Su telefono "Sezione — Nome Cognome" su una
/// riga sola veniva tagliato proprio sul nome.
///
/// Con [righeSottotitolo] = 2 la barra deve essere alta almeno
/// [altezzaBarraDueRighe]: passarla come `toolbarHeight` dell'AppBar.
class TitoloDueRighe extends StatelessWidget {
  const TitoloDueRighe({
    required this.titolo,
    required this.sottotitolo,
    this.righeSottotitolo = 1,
    super.key,
  });

  final String titolo;
  final String sottotitolo;
  final int righeSottotitolo;

  /// Altezza della barra che fa stare il titolo e due righe di
  /// sottotitolo (28 + 2 × 20 di interlinea, piu' un po' di respiro).
  static const altezzaBarraDueRighe = 76.0;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          sottotitolo,
          maxLines: righeSottotitolo,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}
