import '../../domain/allenamento.dart';

/// Raggruppa gli allenamenti per data (senza ora), per popolare le viste
/// a calendario.
Map<DateTime, List<Allenamento>> raggruppaPerGiorno(
  List<Allenamento> allenamenti,
) {
  final mappa = <DateTime, List<Allenamento>>{};
  for (final a in allenamenti) {
    final chiave = DateTime(a.data.year, a.data.month, a.data.day);
    mappa.putIfAbsent(chiave, () => []).add(a);
  }
  return mappa;
}

bool isStessoGiorno(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
