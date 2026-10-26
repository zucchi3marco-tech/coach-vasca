import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/home/atleta/card_settimana.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Preparazione da giovedì 1 ottobre a domenica 1 novembre: cinque
// settimane (la prima parte dal lunedì 28 settembre).
final _preparazione = FaseStagione(
  nome: 'Preparazione',
  dataInizio: DateTime(2026, 10, 1),
  dataFine: DateTime(2026, 11, 1),
  obiettivoMetri: 30000,
  scopo: 'Costruiamo il fondo: tanti metri, poca velocità',
  righeSettimane: {DateTime(2026, 10, 19): 'Settimana del derby: si scarica'},
);

Stagione _stagione(String? gruppoId, List<FaseStagione> fasi) => Stagione(
  id: 's-${gruppoId ?? 'club'}',
  clubId: 'c1',
  nome: 'Stagione',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  gruppoId: gruppoId,
  fasi: fasi,
);

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'g16',
);

void main() {
  test('le settimane di una fase vanno da lunedì a lunedì', () {
    expect(_preparazione.settimane, [
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
  });

  test('la riga di una settimana vale al posto di «A cosa serve»', () {
    expect(
      _preparazione.testoDellaSettimana(DateTime(2026, 10, 12)),
      'Costruiamo il fondo: tanti metri, poca velocità',
    );
    // Un giorno qualsiasi della settimana trova il suo lunedì.
    expect(
      _preparazione.testoDellaSettimana(DateTime(2026, 10, 21)),
      'Settimana del derby: si scarica',
    );
  });

  test('«A cosa serve» e le righe si salvano, si rileggono e si spostano', () {
    final mappa = _preparazione.toMap();
    expect(mappa['scopo'], 'Costruiamo il fondo: tanti metri, poca velocità');
    expect(mappa['righe_settimane'], {
      '2026-10-19': 'Settimana del derby: si scarica',
    });
    final riletta = FaseStagione.fromMap(mappa);
    expect(riletta.scopo, _preparazione.scopo);
    expect(riletta.righeSettimane, _preparazione.righeSettimane);

    // Le fasi di prima, senza testi, restano come sono.
    final vecchia = FaseStagione.fromMap({
      'nome': 'Andata',
      'data_inizio': '2026-11-02',
      'data_fine': '2027-01-31',
      'scopo': '   ',
    });
    expect(vecchia.scopo, isNull);
    expect(vecchia.righeSettimane, isEmpty);
    expect(vecchia.toMap().containsKey('righe_settimane'), isFalse);

    // Duplicando la stagione sull'anno dopo la riga resta sul lunedì.
    final anno = _preparazione.spostata(364);
    expect(anno.righeSettimane.keys.single, DateTime(2027, 10, 18));
    expect(anno.scopo, _preparazione.scopo);
  });

  test('la settimana dell\'atleta: fase, numero e testo', () {
    final stagioni = [
      _stagione('g16', [_preparazione]),
    ];
    final s = settimanaDellAtleta(stagioni, 'g16', DateTime(2026, 10, 14))!;
    expect(s.fase.nome, 'Preparazione');
    expect(s.numero, 3);
    expect(s.totale, 5);
    expect(s.testo, 'Costruiamo il fondo: tanti metri, poca velocità');
    // Un altro gruppo non vede le fasi di questo.
    expect(
      settimanaDellAtleta(stagioni, 'g14', DateTime(2026, 10, 14)),
      isNull,
    );
    expect(settimanaDellAtleta(stagioni, 'g16', DateTime(2027, 3, 1)), isNull);
  });

  group('nella home', () {
    Future<void> apri(WidgetTester tester, List<Stagione> stagioni) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stagioniListProvider.overrideWith(
              (ref, _) => Stream.value(stagioni),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            home: Scaffold(
              body: CardSettimana(
                atleta: _atleta,
                oggi: DateTime(2026, 10, 21),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('fase, settimana e testo, senza i numeri', (tester) async {
      await apri(tester, [
        _stagione('g16', [_preparazione]),
      ]);
      expect(find.text('Preparazione · settimana 4 di 5'), findsOneWidget);
      expect(find.text('Settimana del derby: si scarica'), findsOneWidget);
      expect(find.textContaining('km'), findsNothing);
      expect(find.textContaining('30'), findsNothing);
    });

    testWidgets('senza una fase in corso non c\'è', (tester) async {
      await apri(tester, [_stagione('g16', const [])]);
      expect(find.textContaining('settimana'), findsNothing);
    });
  });
}
