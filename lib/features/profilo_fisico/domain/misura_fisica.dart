import '../../../core/utils/date_format.dart';
import '../../../core/utils/date_italiane.dart';

/// Altezza e peso di un atleta in un giorno (tabella `misure_fisiche`).
/// Dati sulla salute: li leggono solo l'atleta e lo staff, mai l'AI.
class MisuraFisica {
  const MisuraFisica({
    required this.atletaId,
    required this.clubId,
    required this.data,
    this.id,
    this.altezzaCm,
    this.pesoKg,
  });

  factory MisuraFisica.fromMap(Map<String, dynamic> m) => MisuraFisica(
    id: m['id'] as String?,
    atletaId: m['atleta_id'] as String,
    clubId: m['club_id'] as String,
    data: DateTime.parse(m['data'] as String),
    altezzaCm: (m['altezza_cm'] as num?)?.toDouble(),
    pesoKg: (m['peso_kg'] as num?)?.toDouble(),
  );

  final String? id;
  final String atletaId;
  final String clubId;
  final DateTime data;
  final double? altezzaCm;
  final double? pesoKg;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'atleta_id': atletaId,
    'club_id': clubId,
    'data': formatDateOnly(data),
    'altezza_cm': altezzaCm,
    'peso_kg': pesoKg,
  };
}

/// Limiti come nel database.
const altezzaMinCm = 80.0;
const altezzaMaxCm = 230.0;
const pesoMinKg = 20.0;
const pesoMaxKg = 200.0;

/// 18 anni compiuti il giorno [oggi].
bool maggiorenne(DateTime dataNascita, DateTime oggi) {
  final diciotto = DateTime(
    dataNascita.year + 18,
    dataNascita.month,
    dataNascita.day,
  );
  return !DateTime(oggi.year, oggi.month, oggi.day).isBefore(diciotto);
}

/// La sezione si apre a chi è maggiorenne o ha il consenso del genitore.
bool profiloFisicoAperto({
  required DateTime dataNascita,
  required bool conConsenso,
  required DateTime oggi,
}) => conConsenso || maggiorenne(dataNascita, oggi);

/// L'altezza come la scrive un ragazzo: «172», «172,5» oppure «1,72»
/// (in metri). null se vuota; [FormatException] se fuori dai limiti.
double? leggiAltezza(String testo) {
  final v = _numero(testo);
  if (v == null) return null;
  final cm = v < 3 ? v * 100 : v;
  if (cm < altezzaMinCm || cm > altezzaMaxCm) {
    throw const FormatException('L\'altezza va da 80 a 230 cm');
  }
  return _unDecimale(cm);
}

/// Il peso in chili, anche con la virgola. null se vuoto.
double? leggiPeso(String testo) {
  final v = _numero(testo);
  if (v == null) return null;
  if (v < pesoMinKg || v > pesoMaxKg) {
    throw const FormatException('Il peso va da 20 a 200 kg');
  }
  return _unDecimale(v);
}

double? _numero(String testo) {
  final t = testo
      .trim()
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null) throw const FormatException('Scrivi solo il numero');
  return v;
}

double _unDecimale(double v) => (v * 10).roundToDouble() / 10;

/// «172», «172,5».
String numeroMisura(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(1).replaceAll('.', ',');

/// Quanto è cambiata una misura dalla prima all'ultima volta:
/// «+3 cm dal 12 settembre». null con meno di due valori.
String? crescita(
  List<MisuraFisica> misure,
  double? Function(MisuraFisica) valore,
  String unita, {
  DateTime? oggi,
}) {
  final conValore = [
    for (final m in misure)
      if (valore(m) != null) m,
  ]..sort((a, b) => a.data.compareTo(b.data));
  if (conValore.length < 2) return null;
  final prima = conValore.first;
  final ultima = conValore.last;
  final quando = _giornoMese(prima.data, oggi ?? DateTime.now());
  // «l'8», «l'11», «l'1»: davanti a una vocale l'articolo si apostrofa.
  final vocale = const {1, 8, 11}.contains(prima.data.day);
  final diff = _unDecimale(valore(ultima)! - valore(prima)!);
  if (diff == 0) return vocale ? 'Come l\'$quando' : 'Come il $quando';
  final segno = diff > 0 ? '+' : '−';
  final dal = vocale ? 'dall\'' : 'dal ';
  return '$segno${numeroMisura(diff.abs())} $unita $dal$quando';
}

String _giornoMese(DateTime d, DateTime oggi) =>
    d.year == oggi.year ? giornoMese(d) : dataLunga(d);

/// L'ultima misura con un valore (le misure sono dalla più recente).
double? ultimoValore(
  List<MisuraFisica> misure,
  double? Function(MisuraFisica) valore,
) {
  for (final m in misure) {
    final v = valore(m);
    if (v != null) return v;
  }
  return null;
}
