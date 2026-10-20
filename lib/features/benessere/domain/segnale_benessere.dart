import 'scheda_benessere.dart';

/// Il segnale di benessere accanto al nome nell'appello: [livello] 1 =
/// da seguire (giallo), 2 = da sentire (rosso); [testo] dice perché.
typedef SegnaleBenessere = ({int livello, String testo});

/// Il segnale di oggi per un atleta, o `null` se non c'è niente da dire:
/// scheda non compilata, o scheda a posto e senza dolori. Ricompare solo
/// per chi è peggio del solito oggi (la Prontezza scende a «da seguire» o
/// «da sentire», che include «molto sotto il suo solito») o ha segnalato
/// un dolore, anche con una Prontezza ancora buona.
SegnaleBenessere? segnaleBenessere(
  SchedaBenessere? scheda,
  PunteggioBenessere? punteggio,
) {
  if (scheda == null || punteggio == null) return null;
  if (punteggio.livello == 0 && !scheda.dolori) return null;
  final livello = punteggio.livello >= 2 ? 2 : 1;
  final String perche;
  if (scheda.dolori) {
    final zone = scheda.zoneDolore.map(etichettaZona).join(', ').toLowerCase();
    final intensita = scheda.intensitaDolore;
    perche = [
      'dolore',
      if (zone.isNotEmpty) zone,
      if (intensita != null) '$intensita/10',
    ].join(' ');
  } else if (punteggio.motivi.isNotEmpty) {
    final motivo = punteggio.motivi.first.testo;
    perche = motivo.substring(0, 1).toLowerCase() + motivo.substring(1);
  } else {
    perche = 'prontezza ${punteggio.valore}';
  }
  final stato = livello == 2 ? 'da sentire' : 'da seguire';
  return (livello: livello, testo: 'Benessere $stato: $perche');
}
