import 'dart:typed_data';

import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/data/gruppi_repository.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/staff_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/excel/distinta_excel.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/staff_distinta_dialog.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/error_banner.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

// Lo staff del modulo della distinta: il dialog da solo (squadre) e il
// dialog del modulo che precede il download del file Excel.

// --- Finti ------------------------------------------------------------------

/// Gli staff delle squadre, e cosa gli si è salvato.
class _GruppiFinti implements GruppiRepository {
  _GruppiFinti([this.staff = StaffDistinta.vuoto]);

  StaffDistinta staff;
  Object? errore;
  final salvataggi = <(String, StaffDistinta)>[];

  @override
  Future<StaffDistinta> staffDellaSquadra(String gruppoId) async => staff;

  @override
  Future<void> aggiornaStaffDellaSquadra(
    String gruppoId,
    StaffDistinta nuovo,
  ) async {
    if (errore != null) throw errore!;
    salvataggi.add((gruppoId, nuovo));
    staff = nuovo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Gli staff cambiati per una partita, e cosa gli si è salvato.
class _PartiteFinte implements PartiteRepository {
  _PartiteFinte([this.staff]);

  StaffDistinta? staff;
  final salvataggi = <(String, StaffDistinta?)>[];

  @override
  Future<StaffDistinta?> staffDellaPartita(String partitaId) async => staff;

  @override
  Future<void> aggiornaStaffDellaPartita(
    String partitaId,
    StaffDistinta? nuovo,
  ) async {
    salvataggi.add((partitaId, nuovo));
    staff = nuovo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il browser finto: tiene i file che si sarebbero scaricati.
class _AzioniFinte implements AzioniDistinta {
  _AzioniFinte({this.disponibile = true});

  @override
  final bool disponibile;
  final scaricati = <(String, Uint8List)>[];

  @override
  void scarica(Uint8List bytes, String nomeFile) =>
      scaricati.add((nomeFile, bytes));
}

// --- Dati -------------------------------------------------------------------

Partita _partita({String? gruppoId = 'g1'}) => Partita(
  id: 'p1',
  clubId: 'c1',
  gruppoId: gruppoId,
  data: DateTime(2026, 10, 25),
  ora: '18:30',
  luogo: 'Piscina Comunale',
  campionato: 'Under 16',
  coloreCalottina: 'bianca',
  squadraCasa: 'Canottieri',
  squadraTrasferta: 'Rari Nantes',
  numeroMaxConvocati: 15,
);

List<ConvocatoModulo> _convocati() => [
  (
    giocatore: const DistintaGiocatore(
      id: 'd1',
      partitaId: 'p1',
      atletaId: 'a1',
      clubId: 'c1',
      numeroCalottina: 4,
      capitano: true,
      viceCapitano: false,
      portiere: false,
      fuoriquota: false,
    ),
    atleta: Atleta(
      id: 'a1',
      clubId: 'c1',
      nome: 'Mario',
      cognome: 'Rossi',
      dataNascita: DateTime(2010, 5, 1),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: true,
      numeroTesseraFin: '700001',
    ),
  ),
];

const _tecnico = StaffDistinta({
  RuoloStaff.tecnico: PersonaStaff(nome: 'Gialli Carlo', tessera: '800001'),
});

const _altroStaff = StaffDistinta({
  RuoloStaff.medico: PersonaStaff(nome: 'Blu Elisa', tessera: '800009'),
});

// --- Aiuti ------------------------------------------------------------------

Widget _intorno(
  Widget figlio, {
  List<Override> overrides = const [],
  double testo = 1.3,
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(testo), disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(body: Center(child: figlio)),
  ),
);

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Il campo di testo con questa chiave dello staff (nome o tessera).
Finder _campo(RuoloStaff ruolo, String quale) => find.descendant(
  of: find.byKey(ValueKey('staff-${ruolo.chiave}-$quale')),
  matching: find.byType(TextFormField),
);

Future<void> _scrivi(
  WidgetTester tester,
  RuoloStaff ruolo,
  String quale,
  String testo,
) async {
  await tester.ensureVisible(_campo(ruolo, quale));
  await tester.enterText(_campo(ruolo, quale), testo);
}

String _testoDel(WidgetTester tester, RuoloStaff ruolo, String quale) =>
    tester.widget<TextFormField>(_campo(ruolo, quale)).controller!.text;

/// Un pulsante che apre il dialog dello staff e tiene cosa ha dato.
class _ApriStaff extends StatefulWidget {
  const _ApriStaff(this.iniziale, {this.spiegazione});

  final StaffDistinta iniziale;
  final String? spiegazione;

  @override
  State<_ApriStaff> createState() => _ApriStaffState();
}

class _ApriStaffState extends State<_ApriStaff> {
  StaffDistinta? dato;
  bool chiuso = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: () async {
            final risposta = await chiediStaffDistinta(
              context,
              iniziale: widget.iniziale,
              titolo: 'Staff di U16 Allievi',
              spiegazione: widget.spiegazione,
            );
            setState(() {
              dato = risposta;
              chiuso = true;
            });
          },
          child: const Text('Apri staff'),
        ),
        Text(chiuso ? (dato == null ? 'annullato' : 'salvato') : 'aperto'),
      ],
    );
  }
}

/// Un pulsante che avvia l'esportazione, come farà la distinta.
class _Esporta extends ConsumerWidget {
  const _Esporta(this.partita);

  final Partita partita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () => esportaDistintaExcel(
        context,
        ref,
        partita: partita,
        convocati: _convocati(),
      ),
      child: const Text('Esporta'),
    );
  }
}

class _Scenario {
  _Scenario({
    StaffDistinta staffSquadra = StaffDistinta.vuoto,
    StaffDistinta? staffPartita,
    bool disponibile = true,
  }) : gruppi = _GruppiFinti(staffSquadra),
       partite = _PartiteFinte(staffPartita),
       azioni = _AzioniFinte(disponibile: disponibile);

  final _GruppiFinti gruppi;
  final _PartiteFinte partite;
  final _AzioniFinte azioni;

  List<Override> get overrides => [
    gruppiRepositoryProvider.overrideWithValue(gruppi),
    partiteRepositoryProvider.overrideWithValue(partite),
    azioniDistintaProvider.overrideWithValue(azioni),
    currentClubProvider.overrideWith(
      (ref) async => const Club(id: 'c1', nome: 'Club Nuoto Test'),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value([
        const Gruppo(id: 'g1', clubId: 'c1', nome: 'U16 Allievi', ordine: 1),
      ]),
    ),
  ];
}

Future<void> _apriModulo(
  WidgetTester tester,
  _Scenario scenario, {
  Partita? partita,
}) async {
  await tester.pumpWidget(
    _intorno(_Esporta(partita ?? _partita()), overrides: scenario.overrides),
  );
  await tester.tap(find.text('Esporta'));
  await tester.pumpAndSettle();
}

Future<void> _scarica(WidgetTester tester) async {
  await tester.tap(find.text('Scarica il file Excel'));
  await tester.pumpAndSettle();
}

Finder get _interruttore => find.byType(Switch);

bool _acceso(WidgetTester tester) => tester.widget<Switch>(_interruttore).value;

Future<void> _giraInterruttore(WidgetTester tester) async {
  await tester.ensureVisible(_interruttore);
  await tester.tap(_interruttore);
  await tester.pumpAndSettle();
}

void main() {
  group('chiediStaffDistinta', () {
    testWidgets('dà quello che si è scritto', (tester) async {
      _telefono(tester);
      await tester.pumpWidget(_intorno(const _ApriStaff(_tecnico)));
      await tester.tap(find.text('Apri staff'));
      await tester.pumpAndSettle();

      // Parte da quello che c'è.
      expect(_testoDel(tester, RuoloStaff.tecnico, 'nome'), 'Gialli Carlo');
      expect(_testoDel(tester, RuoloStaff.tecnico, 'tessera'), '800001');
      expect(_testoDel(tester, RuoloStaff.viceTecnico, 'nome'), '');

      await _scrivi(tester, RuoloStaff.tecnico, 'tessera', '');
      await _scrivi(tester, RuoloStaff.viceTecnico, 'nome', '  Blu Elisa ');
      await _scrivi(tester, RuoloStaff.viceTecnico, 'tessera', '800002');
      await _scrivi(tester, RuoloStaff.medico, 'nome', 'Neri Paolo');

      await tester.tap(find.text('Salva staff'));
      await tester.pumpAndSettle();

      final stato = tester.state<_ApriStaffState>(find.byType(_ApriStaff));
      expect(stato.dato, isNotNull);
      final staff = stato.dato!;
      expect(staff.di(RuoloStaff.tecnico).nome, 'Gialli Carlo');
      expect(staff.di(RuoloStaff.tecnico).tessera, '');
      expect(staff.di(RuoloStaff.viceTecnico).nome, 'Blu Elisa');
      expect(staff.di(RuoloStaff.viceTecnico).tessera, '800002');
      expect(staff.di(RuoloStaff.medico).nome, 'Neri Paolo');
      expect(staff.di(RuoloStaff.accompagnatore).vuota, isTrue);
      expect(staff.di(RuoloStaff.dirigente).vuota, isTrue);
      // Le righe vuote non ci sono nemmeno.
      expect(staff.persone.keys, {
        RuoloStaff.tecnico,
        RuoloStaff.viceTecnico,
        RuoloStaff.medico,
      });
    });

    testWidgets('annullando non dà nulla', (tester) async {
      _telefono(tester);
      await tester.pumpWidget(_intorno(const _ApriStaff(_tecnico)));
      await tester.tap(find.text('Apri staff'));
      await tester.pumpAndSettle();

      await _scrivi(tester, RuoloStaff.tecnico, 'nome', 'Cambiato');
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      final stato = tester.state<_ApriStaffState>(find.byType(_ApriStaff));
      expect(stato.chiuso, isTrue);
      expect(stato.dato, isNull);
      expect(find.text('annullato'), findsOneWidget);
    });

    testWidgets('mostra titolo, spiegazione e i cinque ruoli', (tester) async {
      _telefono(tester);
      await tester.pumpWidget(
        _intorno(
          const _ApriStaff(
            StaffDistinta.vuoto,
            spiegazione: 'Vale per tutte le partite.',
          ),
        ),
      );
      await tester.tap(find.text('Apri staff'));
      await tester.pumpAndSettle();

      expect(find.text('Staff di U16 Allievi'), findsOneWidget);
      expect(find.text('Vale per tutte le partite.'), findsOneWidget);
      for (final ruolo in RuoloStaff.values) {
        expect(find.text(ruolo.etichetta), findsOneWidget);
        expect(_campo(ruolo, 'nome'), findsOneWidget);
        expect(_campo(ruolo, 'tessera'), findsOneWidget);
      }
      // La tessera si scrive con la tastiera dei numeri.
      final tessera = tester.widget<TextField>(
        find.descendant(
          of: _campo(RuoloStaff.tecnico, 'tessera'),
          matching: find.byType(TextField),
        ),
      );
      expect(tessera.keyboardType, TextInputType.number);
    });

    testWidgets('a 360x740 con il testo ingrandito niente overflow', (
      tester,
    ) async {
      _telefono(tester);
      await tester.pumpWidget(
        _intorno(
          const _ApriStaff(
            _tecnico,
            spiegazione:
                'Lo staff e le tessere che finiscono nel modulo della '
                'distinta, per tutte le partite della squadra.',
          ),
        ),
      );
      await tester.tap(find.text('Apri staff'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // I pulsanti si vedono sempre, e si arriva anche all'ultimo campo.
      expect(find.text('Salva staff'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
      await tester.ensureVisible(_campo(RuoloStaff.medico, 'tessera'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final campo = tester.getRect(_campo(RuoloStaff.medico, 'tessera'));
      expect(campo.right, lessThanOrEqualTo(360));
      expect(campo.left, greaterThanOrEqualTo(0));
    });
  });

  group('esportaDistintaExcel', () {
    testWidgets('squadra senza staff: lo salva per la squadra e scarica', (
      tester,
    ) async {
      _telefono(tester);
      final s = _Scenario();
      await _apriModulo(tester, s);

      expect(find.text('Il modulo della distinta'), findsOneWidget);
      expect(
        find.text('Usa per tutte le partite di U16 Allievi'),
        findsOneWidget,
      );
      expect(_acceso(tester), isTrue);

      await _scrivi(tester, RuoloStaff.tecnico, 'nome', 'Gialli Carlo');
      await _scrivi(tester, RuoloStaff.tecnico, 'tessera', '800001');
      await _scarica(tester);

      expect(s.gruppi.salvataggi, hasLength(1));
      expect(s.gruppi.salvataggi.single.$1, 'g1');
      expect(
        s.gruppi.salvataggi.single.$2.di(RuoloStaff.tecnico),
        const PersonaStaff(nome: 'Gialli Carlo', tessera: '800001'),
      );
      // La partita non aveva il suo: resta com'è.
      expect(s.partite.salvataggi, isEmpty);

      // Il dialog si è chiuso e il file è stato scaricato.
      expect(find.text('Il modulo della distinta'), findsNothing);
      expect(s.azioni.scaricati, hasLength(1));
      final (nomeFile, bytes) = s.azioni.scaricati.single;
      expect(nomeFile, 'Formazione Canottieri-Rari Nantes 2026-10-25.xlsx');
      expect(find.textContaining('File Excel scaricato'), findsOneWidget);

      // Dentro il file: club, squadra, giocatore e staff scritto adesso.
      final foglio = Excel.decodeBytes(bytes);
      expect(foglio.tables.keys.single, 'Formazione U16 Allievi');
      final f = foglio.tables.values.single;
      String t(String indirizzo) =>
          switch (f.cell(CellIndex.indexByString(indirizzo)).value) {
            TextCellValue(:final value) => value.text ?? '',
            null => '',
            final altro => '$altro',
          };
      expect(t('B2'), 'CLUB NUOTO TEST');
      expect(t('B7'), 'Rossi Mario');
      expect(t('D7'), 'CAP');
      expect(t('A23'), 'Tecnico');
      expect(t('B23'), 'Gialli Carlo');
      expect(
        f.cell(CellIndex.indexByString('D23')).value,
        const IntCellValue(800001),
      );
    });

    testWidgets('lo staff della squadra c\'è già: senza modifiche non si '
        'scrive nulla', (tester) async {
      _telefono(tester);
      final s = _Scenario(staffSquadra: _tecnico);
      await _apriModulo(tester, s);

      expect(_testoDel(tester, RuoloStaff.tecnico, 'nome'), 'Gialli Carlo');
      // La partita non ha il suo: si tiene per la squadra.
      expect(_acceso(tester), isTrue);
      await _scarica(tester);

      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, isEmpty);
      expect(s.azioni.scaricati, hasLength(1));
    });

    testWidgets('interruttore spento: lo staff vale solo per la partita', (
      tester,
    ) async {
      _telefono(tester);
      final s = _Scenario(staffSquadra: _tecnico);
      await _apriModulo(tester, s);

      await _scrivi(tester, RuoloStaff.medico, 'nome', 'Neri Paolo');
      await _giraInterruttore(tester);
      expect(_acceso(tester), isFalse);
      await _scarica(tester);

      // La squadra resta com'era.
      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, hasLength(1));
      expect(s.partite.salvataggi.single.$1, 'p1');
      final staff = s.partite.salvataggi.single.$2!;
      expect(staff.di(RuoloStaff.tecnico).nome, 'Gialli Carlo');
      expect(staff.di(RuoloStaff.medico).nome, 'Neri Paolo');
      expect(s.azioni.scaricati, hasLength(1));
    });

    testWidgets('la partita ha il suo staff: si parte da quello, a '
        'interruttore spento', (tester) async {
      _telefono(tester);
      final s = _Scenario(staffSquadra: _tecnico, staffPartita: _altroStaff);
      await _apriModulo(tester, s);

      expect(_testoDel(tester, RuoloStaff.medico, 'nome'), 'Blu Elisa');
      expect(_testoDel(tester, RuoloStaff.tecnico, 'nome'), '');
      expect(_acceso(tester), isFalse);

      // Senza toccare niente il suo staff resta suo.
      await _scarica(tester);
      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, isEmpty);
    });

    testWidgets('acceso su una partita con il suo staff: passa alla squadra '
        'e la partita torna come lei', (tester) async {
      _telefono(tester);
      final s = _Scenario(staffSquadra: _tecnico, staffPartita: _altroStaff);
      await _apriModulo(tester, s);

      await _giraInterruttore(tester);
      expect(_acceso(tester), isTrue);
      await _scarica(tester);

      expect(s.gruppi.salvataggi, hasLength(1));
      expect(
        s.gruppi.salvataggi.single.$2.di(RuoloStaff.medico).nome,
        'Blu Elisa',
      );
      expect(s.partite.salvataggi, [('p1', null)]);
    });

    testWidgets('spento e uguale alla squadra: la partita torna come la '
        'squadra', (tester) async {
      _telefono(tester);
      // La squadra non ha staff, la partita sì: l'interruttore parte acceso.
      final s = _Scenario(staffPartita: _altroStaff);
      await _apriModulo(tester, s);

      await _giraInterruttore(tester);
      await _scrivi(tester, RuoloStaff.medico, 'nome', '');
      await _scrivi(tester, RuoloStaff.medico, 'tessera', '');
      await _scarica(tester);

      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, [('p1', null)]);
    });

    testWidgets('senza squadra non c\'è l\'interruttore e si salva sulla '
        'partita', (tester) async {
      _telefono(tester);
      final s = _Scenario();
      await _apriModulo(tester, s, partita: _partita(gruppoId: null));

      expect(_interruttore, findsNothing);
      await _scrivi(tester, RuoloStaff.tecnico, 'nome', 'Gialli Carlo');
      await _scarica(tester);

      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, hasLength(1));
      expect(
        s.partite.salvataggi.single.$2!.di(RuoloStaff.tecnico).nome,
        'Gialli Carlo',
      );
      // Il foglio non porta il nome di una squadra.
      expect(
        Excel.decodeBytes(s.azioni.scaricati.single.$2).tables.keys.single,
        'Formazione',
      );
    });

    testWidgets('annullando non si scrive né si scarica nulla', (tester) async {
      _telefono(tester);
      final s = _Scenario();
      await _apriModulo(tester, s);

      await _scrivi(tester, RuoloStaff.tecnico, 'nome', 'Gialli Carlo');
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(find.text('Il modulo della distinta'), findsNothing);
      expect(s.gruppi.salvataggi, isEmpty);
      expect(s.partite.salvataggi, isEmpty);
      expect(s.azioni.scaricati, isEmpty);
    });

    testWidgets('fuori dal browser dice dove si scarica e non apre nulla', (
      tester,
    ) async {
      _telefono(tester);
      final s = _Scenario(disponibile: false);
      await _apriModulo(tester, s);

      expect(
        find.text('Il file si scarica dall\'app aperta nel browser.'),
        findsOneWidget,
      );
      expect(find.text('Il modulo della distinta'), findsNothing);
      expect(s.azioni.scaricati, isEmpty);
    });

    testWidgets('se il salvataggio dà errore il dialog resta aperto con il '
        'messaggio', (tester) async {
      _telefono(tester);
      final s = _Scenario();
      s.gruppi.errore = Exception('Connessione persa');
      await _apriModulo(tester, s);

      await _scrivi(tester, RuoloStaff.tecnico, 'nome', 'Gialli Carlo');
      await _scarica(tester);

      expect(find.text('Il modulo della distinta'), findsOneWidget);
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(s.azioni.scaricati, isEmpty);
      // Quello che si era scritto c'è ancora, e si può riprovare.
      expect(_testoDel(tester, RuoloStaff.tecnico, 'nome'), 'Gialli Carlo');

      s.gruppi.errore = null;
      await _scarica(tester);
      expect(find.text('Il modulo della distinta'), findsNothing);
      expect(s.azioni.scaricati, hasLength(1));
    });

    testWidgets('a 360x740 con il testo ingrandito niente overflow', (
      tester,
    ) async {
      _telefono(tester);
      final s = _Scenario(staffSquadra: _tecnico);
      await _apriModulo(tester, s);

      expect(tester.takeException(), isNull);
      expect(find.text('Scarica il file Excel'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
      await tester.ensureVisible(_interruttore);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final riga = tester.getRect(find.byType(SwitchListTile));
      expect(riga.right, lessThanOrEqualTo(360));
    });
  });
}
