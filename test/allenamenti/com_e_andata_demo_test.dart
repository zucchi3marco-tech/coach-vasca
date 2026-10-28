import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/demo/dati_demo.dart';
import 'package:coach_vasca/features/allenamenti/domain/com_e_andata.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// I dati della demo hanno qualche seduta già fatta con serie in parte e
// saltate, così «Com'è andata» ha qualcosa da mostrare: e quello che c'è
// scritto deve essere una cosa che l'app permette di segnare.

Serie _daRiga(SerieTableData r) => Serie(
  id: r.id,
  allenamentoId: r.allenamentoId,
  clubId: r.clubId,
  ordine: r.ordine,
  blocco: r.blocco,
  ripetute: r.ripetute,
  distanzaM: r.distanzaM,
  durataS: r.durataS,
  stile: r.stile,
  esecuzione: r.esecuzione,
  zona: r.zona,
  esito: r.esito,
  metriFatti: r.metriFatti,
  secondiFatti: r.secondiFatti,
);

void main() {
  test('la demo ha serie fatte in parte e saltate, valide', () async {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(db.close);

    await inserisciDatiDemo(db);

    final allenamenti = {
      for (final a in await db.select(db.allenamentiTable).get()) a.id: a,
    };
    final serie = [
      for (final r in await db.select(db.serieTable).get()) _daRiga(r),
    ];
    final segnate = [
      for (final s in serie)
        if (s.esito != null) s,
    ];

    // Almeno una serie a distanza e una a tempo fatte in parte, e una
    // saltata.
    expect(
      segnate.any((s) => s.metriFatti != null && s.distanzaM != null),
      isTrue,
    );
    expect(
      segnate.any((s) => s.secondiFatti != null && s.durataS != null),
      isTrue,
    );
    expect(segnate.any((s) => s.saltata), isTrue);

    // Segnate solo in sedute già passate, e solo in due.
    final ora = DateTime.now();
    final sedute = {for (final s in segnate) s.allenamentoId};
    expect(sedute, hasLength(2));
    for (final id in sedute) {
      expect(allenamenti[id]!.data.isBefore(ora), isTrue);
    }

    for (final s in segnate.where((s) => s.inParte)) {
      // Chi è in parte è anche 'fatta', come vuole il database.
      expect(s.esito, 'fatta');
      // E il numero è una delle scelte del foglio «In parte».
      final scelte = opzioniInParte(s).scelte;
      expect(
        scelte.any((c) => c.eDi(s)),
        isTrue,
        reason: 'serie ${s.ordine}: ${s.metriFatti}/${s.secondiFatti}',
      );
      expect(descriviFatto(s), startsWith('In parte · '));
    }
  });
}
