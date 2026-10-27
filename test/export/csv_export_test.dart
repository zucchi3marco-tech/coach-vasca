import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/export/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_export_test.dart' show serieDaTesto, testoCompleto;

final _allenamento = Allenamento(
  id: 'a',
  clubId: 'c',
  gruppoId: 'g',
  data: DateTime(2026, 10, 27),
  titolo: 'Martedì',
);

/// Le righe del CSV (senza l'intestazione), ogni riga come mappa
/// colonna → valore.
List<Map<String, String>> _righe(String testo) {
  final csv = generaCsv([(_allenamento, serieDaTesto(testo))]);
  final righe = csv.split('\r\n');
  final colonne = righe.first.split(',');
  return [
    for (final r in righe.skip(1))
      {for (final (i, v) in _celle(r).indexed) colonne[i]: v},
  ];
}

/// Le celle di una riga CSV, con le virgolette di RFC 4180.
List<String> _celle(String riga) {
  final celle = <String>[];
  final b = StringBuffer();
  var tra = false;
  for (var i = 0; i < riga.length; i++) {
    final c = riga[i];
    if (tra) {
      if (c == '"' && i + 1 < riga.length && riga[i + 1] == '"') {
        b.write('"');
        i++;
      } else if (c == '"') {
        tra = false;
      } else {
        b.write(c);
      }
    } else if (c == '"') {
      tra = true;
    } else if (c == ',') {
      celle.add(b.toString());
      b.clear();
    } else {
      b.write(c);
    }
  }
  celle.add(b.toString());
  return celle;
}

void main() {
  test('una piramide è una riga sola, con i metri di tutto il gruppo', () {
    final righe = _righe('Principale\n50-100-200-100-50 sl B1 r20');
    expect(righe, hasLength(1));
    final r = righe.single;
    expect(r['Ripetute'], '1');
    expect(r['Distanza (m)'], '50-100-200-100-50');
    expect(r['Metri'], '500');
    expect(r['Recupero (s)'], '20');
    expect(r['Zona'], 'B1');
    expect(r['Stile'], 'Libero');
  });

  test('una piramide ripetuta: i giri nelle ripetute', () {
    final righe = _righe('Principale\n2x(50-100) sl A2');
    expect(righe, hasLength(1));
    expect(righe.single['Ripetute'], '2');
    expect(righe.single['Distanza (m)'], '50-100');
    expect(righe.single['Metri'], '300');
  });

  test('le serie normali restano una riga l\'una, con i metri', () {
    final righe = _righe('Principale\n10x100 sl A2 @1:40\n200 sl A1');
    expect(righe, hasLength(2));
    expect(righe[0]['Ripetute'], '10');
    expect(righe[0]['Distanza (m)'], '100');
    expect(righe[0]['Metri'], '1000');
    expect(righe[1]['Metri'], '200');
  });

  test('a tempo: niente metri', () {
    final r = _righe("Principale\n10' palleggio").single;
    expect(r['Metri'], '');
    expect(r['Durata (s)'], '600');
  });

  test('la somma dei metri è quella dell\'allenamento intero', () {
    final righe = _righe(
      '$testoCompleto\nPrincipale\n50-100-200-100-50 sl B1 r20\n'
      '2x(50-100) sl A2',
    );
    final metri = righe.fold(
      0,
      (m, r) => m + (int.tryParse(r['Metri'] ?? '') ?? 0),
    );
    // 3.150 m dell'allenamento completo più 500 e 300 delle piramidi.
    expect(metri, 3150 + 500 + 300);
  });
}
