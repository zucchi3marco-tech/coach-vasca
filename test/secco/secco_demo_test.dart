import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/demo/dati_demo.dart';
import 'package:coach_vasca/features/allenamenti/domain/destinatari.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/varianti_secco.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// La demo della pallanuoto ha le varianti del secco (proposta 12) e i voti
// delle serie, e quello che c'è scritto deve essere una cosa che il
// database accetta: una variante di un esercizio della stessa seduta,
// solo nomi; serie fatte solo sugli esercizi di chi le ha fatte.

EsercizioSeduta _daRiga(EserciziSedutaTableData r) => EsercizioSeduta(
  id: r.id,
  allenamentoId: r.allenamentoId,
  clubId: r.clubId,
  esercizioId: r.esercizioId,
  ordine: r.ordine,
  serie: r.serie,
  ripetizioni: r.ripetizioni,
  durataS: r.durataS,
  varianteDi: r.varianteDi,
  destinatari: Destinatari.daCampi(
    soloAtleti: r.soloAtletiJson,
    tranneAtleti: r.tranneAtletiJson,
  ),
);

void main() {
  test('la demo ha varianti e voti, validi per il database', () async {
    dotenv.loadFromString(envString: 'DEMO_SPORT=pallanuoto');
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(db.close);

    await inserisciDatiDemo(db);

    final righe = [
      for (final r in await db.select(db.eserciziSedutaTable).get()) _daRiga(r),
    ];
    final perId = {for (final r in righe) r.id: r};
    final varianti = righe.where((r) => r.variante).toList();
    expect(varianti, isNotEmpty);
    expect(righe.any((r) => r.destinatari.tranneAtleti.isNotEmpty), isTrue);
    for (final v in varianti) {
      // Come vuole `esercizi_seduta_variante_check` e il controllo della
      // seduta: solo nomi, di un esercizio di tutti della stessa seduta.
      expect(v.destinatari.soloAtleti, isNotEmpty);
      expect(v.destinatari.tranneAtleti, isEmpty);
      final originale = perId[v.varianteDi]!;
      expect(originale.variante, isFalse);
      expect(originale.allenamentoId, v.allenamentoId);
      expect(v.ordine, originale.ordine);
    }

    // Ogni serie fatta è su un esercizio che quell'atleta fa davvero.
    final perSeduta = <String, List<EsercizioSeduta>>{};
    for (final r in righe) {
      (perSeduta[r.allenamentoId] ??= []).add(r);
    }
    final fatte = await db.select(db.serieSeccoFatteTable).get();
    expect(fatte.any((f) => f.voto != null), isTrue);
    expect(fatte.any((f) => f.voto == null), isTrue);
    for (final f in fatte) {
      expect(f.voto, anyOf(isNull, isIn(['facile', 'giusta', 'dura'])));
      final suoi = eserciziDellAtleta(perSeduta[f.allenamentoId]!, f.atletaId);
      expect(
        suoi.map((r) => r.id),
        contains(f.rigaId),
        reason: 'una serie fatta su un esercizio che l\'atleta non fa',
      );
      expect(f.serie, lessThanOrEqualTo(perId[f.rigaId]!.serie));
    }
    // Chi ha la variante l'ha registrata.
    final conVariante = {for (final v in varianti) ...v.destinatari.soloAtleti};
    expect(
      fatte.any(
        (f) =>
            conVariante.contains(f.atletaId) &&
            varianti.any((v) => v.id == f.rigaId),
      ),
      isTrue,
    );
    // Il JSON degli elenchi si rilegge.
    for (final r in await db.select(db.eserciziSedutaTable).get()) {
      if (r.soloAtletiJson case final j?) {
        expect(jsonDecode(j), isA<List<dynamic>>());
      }
    }
  });
}
