/// Parametri raccolti dal form "Genera con AI", da passare alla chiamata
/// API di generazione (Fase 5, punto successivo).
class ParametriGenerazione {
  const ParametriGenerazione({
    required this.gruppo,
    required this.livello,
    required this.volumeMetri,
    required this.focus,
    required this.regimiAmmessi,
    this.vincoli,
  });

  final String gruppo;
  final String livello;
  final int volumeMetri;
  final String focus;
  final List<String> regimiAmmessi;
  final String? vincoli;
}
