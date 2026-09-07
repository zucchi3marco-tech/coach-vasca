import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Neutri (sfondo/superficie/testo) letti dal tema — solo per le tre
/// schermate da bordo vasca, che possono passare a [scuro] a scelta
/// dell'allenatore (DESIGN.md sezione 9, "Chiaro o scuro?").
///
/// Non copre il resto dell'app: altrove `AppTypography`/`AppColors`
/// restano fissi come sempre, quindi questa estensione non cambia nulla
/// fuori dalle schermate che la leggono esplicitamente con [of].
@immutable
class SuperficiTema extends ThemeExtension<SuperficiTema> {
  const SuperficiTema({
    required this.sfondo,
    required this.superficie,
    required this.superficieTenue,
    required this.testo,
    required this.testoSecondario,
    required this.testoTenue,
    required this.linea,
    required this.campoTiro,
  });

  final Color sfondo;
  final Color superficie;
  final Color superficieTenue;
  final Color testo;
  final Color testoSecondario;
  final Color testoTenue;
  final Color linea;

  /// Sfondo del campo disegnato (eventi partita): in chiaro è lo stesso
  /// `bluTenue` usato altrove nell'app, in scuro un blu più profondo.
  final Color campoTiro;

  static const chiaro = SuperficiTema(
    sfondo: AppColors.sfondo,
    superficie: AppColors.superficie,
    superficieTenue: AppColors.superficieTenue,
    testo: AppColors.testo,
    testoSecondario: AppColors.testoSecondario,
    testoTenue: AppColors.testoTenue,
    linea: AppColors.linea,
    campoTiro: AppColors.bluTenue,
  );

  static const scuro = SuperficiTema(
    sfondo: Color(0xFF0B1A23),
    superficie: Color(0xFF162A36),
    superficieTenue: Color(0xFF1D3644),
    testo: Color(0xFFF2F5F7),
    testoSecondario: Color(0xFFAEC0CB),
    testoTenue: Color(0xFF7C909C),
    linea: Color(0xFF32505F),
    campoTiro: Color(0xFF1B3040),
  );

  /// Da usare nelle tre schermate bordo vasca al posto di `AppColors`
  /// diretto, per ogni colore neutro che deve seguire la scelta
  /// chiaro/scuro. Le altre schermate non chiamano mai questo metodo.
  static SuperficiTema of(BuildContext context) =>
      Theme.of(context).extension<SuperficiTema>() ?? chiaro;

  @override
  SuperficiTema copyWith({
    Color? sfondo,
    Color? superficie,
    Color? superficieTenue,
    Color? testo,
    Color? testoSecondario,
    Color? testoTenue,
    Color? linea,
    Color? campoTiro,
  }) {
    return SuperficiTema(
      sfondo: sfondo ?? this.sfondo,
      superficie: superficie ?? this.superficie,
      superficieTenue: superficieTenue ?? this.superficieTenue,
      testo: testo ?? this.testo,
      testoSecondario: testoSecondario ?? this.testoSecondario,
      testoTenue: testoTenue ?? this.testoTenue,
      linea: linea ?? this.linea,
      campoTiro: campoTiro ?? this.campoTiro,
    );
  }

  @override
  SuperficiTema lerp(ThemeExtension<SuperficiTema>? other, double t) {
    // Token discreti, si passa da un set all'altro a meta' strada, come
    // in DomainTokens.
    if (other is! SuperficiTema) return this;
    return t < 0.5 ? this : other;
  }
}
