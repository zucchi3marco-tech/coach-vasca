import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Avatar a cerchio con le iniziali dell'atleta — nessun campo foto
/// esiste su `Atleta`, quindi niente immagine: stesso principio di
/// `CapBadge` (un cerchio colorato coi token del tema, mai un colore
/// letterale). Usato dalla card profilo nella dashboard atleta.
class AthleteAvatarCircle extends StatelessWidget {
  const AthleteAvatarCircle({
    required this.nome,
    required this.cognome,
    this.size = 56,
    super.key,
  });

  final String nome;
  final String cognome;
  final double size;

  String get _iniziali {
    final i1 = nome.isNotEmpty ? nome[0] : '';
    final i2 = cognome.isNotEmpty ? cognome[0] : '';
    final iniziali = '$i1$i2'.toUpperCase();
    return iniziali.isEmpty ? '?' : iniziali;
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colori.azioneTenue,
        shape: BoxShape.circle,
        border: Border.all(color: colori.azione),
      ),
      child: Text(
        _iniziali,
        style: AppTypography.corpoForte.copyWith(
          color: colori.azione,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
