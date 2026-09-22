/// Riassunto di una riga dello storico "Genera con AI" (Storico
/// generazioni): due forme diverse a seconda di come è stata avviata la
/// generazione.
/// - Dal form a parametri: `{gruppo?, livello?, volumeMetri?, focus?}`.
/// - Dalla dettatura: `{modalita: 'dettatura', testo, gruppo?}`.
String riassuntoParametriGenerazione(Map<String, dynamic> p) {
  if (p['modalita'] == 'dettatura') {
    final testo = p['testo'] as String? ?? '';
    final anteprima = testo.length > 60 ? '${testo.substring(0, 60)}…' : testo;
    return '🎙️ $anteprima';
  }
  final parti = <String>[];
  if (p['gruppo'] != null) parti.add(p['gruppo'] as String);
  if (p['livello'] != null) parti.add(p['livello'] as String);
  if (p['volumeMetri'] != null) parti.add('${p['volumeMetri']} m');
  if (p['focus'] != null) parti.add(p['focus'] as String);
  return parti.join(' · ');
}
