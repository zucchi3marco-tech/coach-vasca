import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token di dominio (zone di intensita', calottine, colore "in corso"):
/// non stanno nel ColorScheme perche' non sono ruoli di Material, sono
/// vocabolario tecnico dell'allenatore. Si leggono con
/// `Theme.of(context).extension<DomainTokens>()`.
@immutable
class DomainTokens extends ThemeExtension<DomainTokens> {
  const DomainTokens({
    required this.coloriZona,
    required this.calottinaBianca,
    required this.calottinaBlu,
    required this.calottinaRossaPortiere,
    required this.inCorso,
  });

  final Map<String, Color> coloriZona;
  final Color calottinaBianca;
  final Color calottinaBlu;
  final Color calottinaRossaPortiere;
  final Color inCorso;

  static const standard = DomainTokens(
    coloriZona: {
      'A1': AppColors.zonaA1,
      'A2': AppColors.zonaA2,
      'B1': AppColors.zonaB1,
      'B2': AppColors.zonaB2,
      'C': AppColors.zonaC,
      'D': AppColors.zonaD,
    },
    calottinaBianca: AppColors.calottinaBianca,
    calottinaBlu: AppColors.calottinaBlu,
    calottinaRossaPortiere: AppColors.calottinaRossaPortiere,
    inCorso: AppColors.rosso,
  );

  /// Colore della zona, o [AppColors.testoTenue] se la sigla non e'
  /// riconosciuta (non deve mai capitare, ma non deve nemmeno far
  /// crashare una schermata).
  Color colorePerZona(String? sigla) => coloriZona[sigla] ?? AppColors.testoTenue;

  @override
  DomainTokens copyWith({
    Map<String, Color>? coloriZona,
    Color? calottinaBianca,
    Color? calottinaBlu,
    Color? calottinaRossaPortiere,
    Color? inCorso,
  }) {
    return DomainTokens(
      coloriZona: coloriZona ?? this.coloriZona,
      calottinaBianca: calottinaBianca ?? this.calottinaBianca,
      calottinaBlu: calottinaBlu ?? this.calottinaBlu,
      calottinaRossaPortiere:
          calottinaRossaPortiere ?? this.calottinaRossaPortiere,
      inCorso: inCorso ?? this.inCorso,
    );
  }

  @override
  DomainTokens lerp(ThemeExtension<DomainTokens>? other, double t) {
    // Token discreti (colori di dominio, non un gradiente): niente
    // interpolazione reale, si passa da un set all'altro a meta' strada.
    if (other is! DomainTokens) return this;
    return t < 0.5 ? this : other;
  }
}
