import '../../referti/domain/referto_partita.dart';
import 'evento_partita.dart';
import 'partita.dart';

/// I numeri di un portiere: parate e gol subiti al posto di gol e tiri.
class NumeriPortiere {
  const NumeriPortiere({
    required this.partite,
    required this.parate,
    required this.golSubiti,
    required this.golSubitiDalVivo,
  });

  static const vuoto = NumeriPortiere(
    partite: 0,
    parate: 0,
    golSubiti: 0,
    golSubitiDalVivo: 0,
  );

  /// Partite in cui è stato in porta almeno un tempo.
  final int partite;

  /// Solo dal vivo: il referto FIN non le riporta.
  final int parate;

  /// Dal vivo quando la partita è stata seguita con il portiere in acqua,
  /// altrimenti dai parziali del referto nei suoi tempi.
  final int golSubiti;

  /// La parte di [golSubiti] che viene dal vivo, per la % parate.
  final int golSubitiDalVivo;

  /// Parate su tiri in porta (parate + gol), solo dal vivo; null se non
  /// ha ancora affrontato tiri dal vivo.
  int? get percentualeParate {
    final tiri = parate + golSubitiDalVivo;
    return tiri == 0 ? null : (parate / tiri * 100).round();
  }
}

/// Parate e gol subiti di [atletaId] nelle [partite].
///
/// [tempiInPorta]: per partita, i tempi in cui era in porta (dalla
/// distinta). [eventi]: gli eventi di quelle partite (bastano i tiri
/// avversari). [referti]: per partita, il referto se c'è.
///
/// Per ogni partita: se i tiri avversari hanno il portiere (partita
/// seguita dal vivo con questa funzione) contano quelli, anche con un
/// cambio a metà tempo; altrimenti i gol subiti sono la somma dei
/// parziali avversari del referto nei suoi tempi.
NumeriPortiere numeriPortiere({
  required String atletaId,
  required List<Partita> partite,
  required Map<String, List<int>> tempiInPorta,
  required List<EventoPartita> eventi,
  required Map<String, RefertoPartita> referti,
}) {
  final tiriPerPartita = <String, List<EventoPartita>>{};
  for (final e in eventi) {
    if (e.tipo != 'tiro' || e.squadra != 'avversaria') continue;
    tiriPerPartita.putIfAbsent(e.partitaId, () => []).add(e);
  }

  var giocate = 0;
  var parate = 0;
  var golSubiti = 0;
  var golDalVivo = 0;
  for (final partita in partite) {
    final tiri = tiriPerPartita[partita.id] ?? const <EventoPartita>[];
    final tempi = tempiInPorta[partita.id] ?? const <int>[];
    final suoi = tiri.where((e) => e.portiereId == atletaId).toList();
    if (tempi.isEmpty && suoi.isEmpty) continue;
    giocate++;

    if (tiri.any((e) => e.portiereId != null)) {
      final gol = suoi.where((e) => e.esito == 'gol').length;
      parate += suoi.where((e) => e.esito == 'parato').length;
      golSubiti += gol;
      golDalVivo += gol;
      continue;
    }
    final referto = referti[partita.id];
    if (referto == null) continue;
    for (final t in tempi) {
      if (t < 1 || t > referto.parziali.length) continue;
      final p = referto.parziali[t - 1];
      golSubiti += partita.inCasa ? p.trasferta : p.casa;
    }
  }
  return NumeriPortiere(
    partite: giocate,
    parate: parate,
    golSubiti: golSubiti,
    golSubitiDalVivo: golDalVivo,
  );
}
