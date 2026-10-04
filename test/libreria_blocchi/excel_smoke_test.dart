import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il package excel legge il file reale della libreria blocchi', () {
    final bytes = File('libreria_blocchi_nuoto_pallanuoto.xlsx')
        .readAsBytesSync();
    final wb = Excel.decodeBytes(bytes);
    expect(wb.tables.keys, containsAll(['Blocchi', 'Parti', 'Legenda']));

    final blocchi = wb.tables['Blocchi']!;
    expect(blocchi.maxRows, 351); // intestazione + 350 blocchi
    final intestazione = blocchi
        .row(0)
        .map((c) => c?.value?.toString())
        .toList();
    expect(intestazione.first, 'ID');

    final primaRiga = blocchi.row(1).map((c) => c?.value?.toString()).toList();
    expect(primaRiga[0], 'N-001');

    final parti = wb.tables['Parti']!;
    expect(parti.maxRows, 390); // intestazione + 389 parti
  });
}
