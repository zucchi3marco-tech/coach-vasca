import '../../features/allenamenti/domain/allenamento.dart';
import '../../features/presenze/domain/presenza.dart';
import 'gruppo_visibilita.dart';

/// Percentuale di presenze di un atleta sugli allenamenti del suo gruppo
/// (più quelli di tutto il club, stessa regola di [visibileNelGruppo] già
/// usata altrove per isolare i record per gruppo). `null` = nessun
/// allenamento rilevante su cui calcolarla (non 0%, che vorrebbe dire
/// "sempre assente").
double? percentualePresenze({
  required List<Allenamento> allenamenti,
  required List<Presenza> presenze,
  required String atletaId,
  required String? gruppoAtleta,
}) {
  final rilevanti = allenamenti
      .where(
        (a) => visibileNelGruppo(
          gruppoDelRecord: a.gruppoId,
          gruppoSelezionato: gruppoAtleta,
        ),
      )
      .toList();
  if (rilevanti.isEmpty) return null;
  final idRilevanti = rilevanti.map((a) => a.id).toSet();
  final presenti = presenze
      .where(
        (p) =>
            p.atletaId == atletaId &&
            p.stato == 'presente' &&
            idRilevanti.contains(p.allenamentoId),
      )
      .length;
  return presenti / rilevanti.length * 100;
}
