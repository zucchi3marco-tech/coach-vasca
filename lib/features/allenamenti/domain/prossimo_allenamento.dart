import '../../../core/utils/gruppo_visibilita.dart';
import 'allenamento.dart';
import 'serie.dart';

/// Il primo allenamento in programma (data da oggi in poi, oggi compreso)
/// fra quelli che l'atleta può vedere: senza gruppo o del suo gruppo. Un
/// atleta senza gruppo li vede tutti. A parità di data vince l'id più
/// basso, così la scelta è stabile. Null se non ce n'è nessuno.
Allenamento? prossimoAllenamento(
  List<Allenamento> allenamenti,
  String? gruppoAtleta, {
  DateTime? oggi,
}) {
  final adesso = oggi ?? DateTime.now();
  final inizio = DateTime(adesso.year, adesso.month, adesso.day);
  final candidati =
      allenamenti
          .where(
            (a) =>
                !a.data.isBefore(inizio) &&
                visibileNelGruppo(
                  gruppoDelRecord: a.gruppoId,
                  gruppoSelezionato: gruppoAtleta,
                ),
          )
          .toList()
        ..sort((a, b) {
          final perData = a.data.compareTo(b.data);
          return perData != 0 ? perData : a.id.compareTo(b.id);
        });
  return candidati.isEmpty ? null : candidati.first;
}

/// Metri totali di una scheda: ripetute × distanza di ogni serie, con
/// riscaldamento e defaticamento inclusi.
int metriTotaliSerie(List<Serie> serie) =>
    serie.fold(0, (somma, s) => somma + s.distanzaTotaleM);

/// "2.400 m": punto come separatore delle migliaia, all'italiana.
String formattaMetri(int metri) {
  final cifre = metri.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < cifre.length; i++) {
    if (i > 0 && (cifre.length - i) % 3 == 0) buffer.write('.');
    buffer.write(cifre[i]);
  }
  return '${metri < 0 ? '-' : ''}$buffer m';
}
