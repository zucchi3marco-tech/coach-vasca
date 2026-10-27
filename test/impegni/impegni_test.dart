import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/impegni/application/impegni_providers.dart';
import 'package:coach_vasca/features/impegni/data/impegni_repository.dart';
import 'package:coach_vasca/features/impegni/domain/impegno.dart';
import 'package:coach_vasca/features/impegni/presentation/avviso_riposo.dart';
import 'package:coach_vasca/features/impegni/presentation/impegno_form_screen.dart';
import 'package:coach_vasca/features/stagioni/domain/evento_calendario.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Impegno _impegno(
  String id,
  TipoImpegno tipo,
  DateTime dal,
  DateTime al, {
  String? gruppoId,
  String? nome,
}) => Impegno(
  id: id,
  clubId: 'c1',
  tipo: tipo,
  dal: dal,
  al: al,
  gruppoId: gruppoId,
  nome: nome,
);

final _collegiale = _impegno(
  'col',
  TipoImpegno.collegiale,
  DateTime(2026, 12, 27),
  DateTime(2026, 12, 29),
  gruppoId: 'u16',
  nome: 'Collegiale a Lignano',
);
final _natale = _impegno(
  'nat',
  TipoImpegno.riposo,
  DateTime(2026, 12, 23),
  DateTime(2027, 1, 6),
  nome: 'Vacanze di Natale',
);
final _riposoU14 = _impegno(
  'r14',
  TipoImpegno.riposo,
  DateTime(2026, 11, 2),
  DateTime(2026, 11, 2),
  gruppoId: 'u14',
);

/// Il campo di testo sotto l'etichetta [etichetta].
Finder _campo(String etichetta) => find.descendant(
  of: find.widgetWithText(AppTextField, etichetta),
  matching: find.byType(TextFormField),
);

class _ImpegniFinti implements ImpegniRepository {
  final creati = <Map<String, Object?>>[];

  @override
  Future<Impegno> crea({
    required String clubId,
    String? gruppoId,
    required TipoImpegno tipo,
    required DateTime dal,
    required DateTime al,
    String? nome,
    String? luogo,
    String? note,
  }) async {
    creati.add({
      'gruppo': gruppoId,
      'tipo': tipo,
      'dal': dal,
      'al': al,
      'nome': nome,
      'luogo': luogo,
    });
    return _impegno('nuovo', tipo, dal, al, gruppoId: gruppoId, nome: nome);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget pagina, {_ImpegniFinti? repository}) => ProviderScope(
  overrides: [
    impegniRepositoryProvider.overrideWithValue(repository ?? _ImpegniFinti()),
    impegniListProvider.overrideWith(
      (ref, clubId) => Stream.value([_collegiale, _natale, _riposoU14]),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value(const [
        Gruppo(id: 'u14', clubId: 'c1', nome: 'U14', ordine: 1),
        Gruppo(id: 'u16', clubId: 'c1', nome: 'U16', ordine: 2),
      ]),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(body: pagina),
  ),
);

void main() {
  group('un impegno', () {
    test('giorni, titolo e periodo', () {
      expect(_collegiale.giorni, 3);
      expect(_natale.giorni, 15);
      expect(_riposoU14.giorni, 1);
      expect(_riposoU14.titolo, 'Riposo');
      expect(_collegiale.titolo, 'Collegiale a Lignano');
      expect(_collegiale.contiene(DateTime(2026, 12, 29, 18)), isTrue);
      expect(_collegiale.contiene(DateTime(2026, 12, 30)), isFalse);
      expect(
        periodoImpegno(_collegiale, (d) => '${d.day}/${d.month}'),
        '27/12 – 29/12',
      );
      expect(periodoImpegno(_riposoU14, (d) => '${d.day}/${d.month}'), '2/11');
    });

    test('il riposo vale per la sua squadra e per il club', () {
      final tutti = [_collegiale, _natale, _riposoU14];
      expect(
        riposoNelGiorno(tutti, DateTime(2026, 11, 2), gruppoId: 'u14')?.id,
        'r14',
      );
      // Il riposo degli U14 non ferma gli U16 né un allenamento di club.
      expect(
        riposoNelGiorno(tutti, DateTime(2026, 11, 2), gruppoId: 'u16'),
        isNull,
      );
      expect(
        riposoNelGiorno(tutti, DateTime(2026, 11, 2), gruppoId: null),
        isNull,
      );
      // Le vacanze di club valgono per tutti.
      expect(
        riposoNelGiorno(tutti, DateTime(2027, 1, 1), gruppoId: 'u16')?.id,
        'nat',
      );
      // Un collegiale non è un riposo.
      expect(
        riposoNelGiorno(tutti, DateTime(2026, 12, 28), gruppoId: 'u16')?.id,
        'nat',
      );
      expect(
        riposoNelGiorno([_collegiale], DateTime(2026, 12, 28), gruppoId: 'u16'),
        isNull,
      );
    });

    test('nel calendario della stagione un evento per ogni giorno', () {
      final stagioneU14 = Stagione(
        id: 's',
        clubId: 'c1',
        gruppoId: 'u14',
        nome: 'U14',
        dataInizio: DateTime(2026, 9, 1),
        dataFine: DateTime(2026, 12, 31),
      );
      final eventi = eventiVisibiliInStagione(
        stagioneU14,
        eventiDaImpegni([_collegiale, _natale, _riposoU14]),
      );
      // Il collegiale degli U16 no; le vacanze fino al 31 dicembre (9
      // giorni), il riposo degli U14 (1).
      expect(eventi.length, 10);
      expect(eventi.every((e) => e.impegno), isTrue);
      final natale = eventi.firstWhere((e) => e.titolo == 'Vacanze di Natale');
      expect(natale.sottotitolo, contains('Riposo'));
    });

    test('dal database', () {
      final i = Impegno.fromMap({
        'id': 'x',
        'club_id': 'c1',
        'gruppo_id': null,
        'tipo': 'torneo',
        'dal': '2027-04-02',
        'al': '2027-04-04',
        'nome': 'Torneo di Pasqua',
        'luogo': 'Recco',
        'note': null,
      });
      expect(i.tipo, TipoImpegno.torneo);
      expect(i.giorni, 3);
      expect(TipoImpegno.daValore('sconosciuto'), TipoImpegno.altro);
    });
  });

  testWidgets('il modulo: un collegiale di tre giorni per gli U16', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _ImpegniFinti();
    await tester.pumpWidget(
      _app(
        ImpegnoFormScreen(
          clubId: 'c1',
          giornoIniziale: DateTime(2026, 12, 27),
          gruppoIniziale: 'u16',
        ),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      _campo('Nome (facoltativo)'),
      'Collegiale a Lignano',
    );
    // «Altro» vuole un nome: senza, non si salva.
    await tester.tap(find.text('Altro'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Nome'), '');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('Scrivi che cos\'è'), findsOneWidget);
    expect(repository.creati, isEmpty);

    await tester.tap(find.text('Collegiale'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _campo('Nome (facoltativo)'),
      'Collegiale a Lignano',
    );
    await tester.enterText(_campo('Luogo (facoltativo)'), 'Lignano');
    // L'ultimo giorno dal calendario: il 29.
    await tester.tap(_campo('Al'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('3 giorni'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(repository.creati, [
      {
        'gruppo': 'u16',
        'tipo': TipoImpegno.collegiale,
        'dal': DateTime(2026, 12, 27),
        'al': DateTime(2026, 12, 29),
        'nome': 'Collegiale a Lignano',
        'luogo': 'Lignano',
      },
    ]);
  });

  testWidgets('l\'avviso sotto la data di un allenamento', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            AvvisoRiposo(
              clubId: 'c1',
              data: DateTime(2026, 11, 2),
              gruppoId: 'u14',
            ),
            AvvisoRiposo(
              clubId: 'c1',
              data: DateTime(2026, 11, 2),
              gruppoId: 'u16',
            ),
            AvvisoRiposo(
              clubId: 'c1',
              data: DateTime(2026, 12, 24),
              gruppoId: 'u16',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('2 novembre è un giorno di riposo. Puoi salvare lo stesso.'),
      findsOneWidget,
    );
    expect(
      find.text(
        '24 dicembre è un giorno di riposo («Vacanze di Natale»). Puoi '
        'salvare lo stesso.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('giorno di riposo'), findsNWidgets(2));
  });
}
