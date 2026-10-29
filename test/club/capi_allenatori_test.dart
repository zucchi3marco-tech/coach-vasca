import 'package:coach_vasca/features/club/data/membri_club_repository.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/club/presentation/mio_club_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/scheda_elenco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: membri e squadre con il loro capo; annota i capi scelti.
class _ClubFinto implements MembriClubRepository {
  _ClubFinto(this.membri_, this.squadre_);

  final List<MembroClub> membri_;
  List<SquadraConCapo> squadre_;
  Object? erroreAzione;
  Object? erroreSquadre;
  final scelte = <(String, String?)>[];
  var lettureSquadre = 0;

  @override
  Future<List<MembroClub>> membri(String clubId) async => membri_;

  @override
  Future<List<SquadraConCapo>> squadre(String clubId) async {
    lettureSquadre++;
    if (erroreSquadre != null) throw erroreSquadre!;
    return squadre_;
  }

  @override
  Future<void> scegliCapo(String gruppoId, String? userId) async {
    if (erroreAzione != null) throw erroreAzione!;
    scelte.add((gruppoId, userId));
    squadre_ = [
      for (final s in squadre_)
        if (s.id == gruppoId)
          SquadraConCapo(id: s.id, nome: s.nome, capoUserId: userId)
        else
          s,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _io = MembroClub(
  userId: 'u-io',
  nome: 'Marco Zucchi',
  ruolo: RuoloClub.responsabile,
  email: 'marco@example.com',
  sonoIo: true,
);
const _luca = MembroClub(
  userId: 'u-luca',
  nome: 'Luca Bianchi',
  ruolo: RuoloClub.allenatore,
  sonoIo: false,
);
const _anna = MembroClub(
  userId: 'u-anna',
  nome: 'Anna Verdi',
  ruolo: RuoloClub.assistente,
  sonoIo: false,
);
// Il responsabile visto da un altro: senza nome e senza email.
const _responsabileAnonimo = MembroClub(
  userId: 'u-resp',
  ruolo: RuoloClub.responsabile,
  sonoIo: false,
);

const _u14 = SquadraConCapo(id: 'g14', nome: 'U14', capoUserId: 'u-luca');
const _u16 = SquadraConCapo(id: 'g16', nome: 'U16');

Widget _app(_ClubFinto server) => ProviderScope(
  overrides: [membriClubRepositoryProvider.overrideWithValue(server)],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const MioClubScreen(clubId: 'c1', clubNome: 'Mako Pallanuoto'),
  ),
);

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _apri(WidgetTester tester, _ClubFinto server) async {
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(server));
  await _passa(tester);
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('la sezione «Capi allenatori» ha una riga per squadra', (
    tester,
  ) async {
    await _apri(tester, _ClubFinto([_io, _luca, _anna], [_u14, _u16]));

    expect(find.text('Capi allenatori'), findsOneWidget);
    expect(
      find.text(
        'Il capo riceve un avviso quando un altro cambia un allenamento '
        'della sua squadra, e vede cosa è cambiato.',
      ),
      findsOneWidget,
    );
    expect(find.text('U14'), findsOneWidget);
    expect(find.text('U16'), findsOneWidget);
    // Il capo di U14 è Luca: il suo nome compare nella riga della squadra e
    // nella riga del membro.
    expect(find.text('Luca Bianchi'), findsNWidgets(2));
    expect(find.text('Nessun capo'), findsOneWidget);
    // Il membro che è capo lo dice.
    expect(find.text('Capo di U14'), findsOneWidget);
  });

  testWidgets('un membro capo di più squadre le elenca', (tester) async {
    await _apri(
      tester,
      _ClubFinto(
        [_io, _luca],
        [
          _u14,
          const SquadraConCapo(id: 'g16', nome: 'U16', capoUserId: 'u-luca'),
        ],
      ),
    );
    expect(find.text('Capo di U14, U16'), findsOneWidget);
  });

  testWidgets('senza squadre la sezione non c\'è', (tester) async {
    await _apri(tester, _ClubFinto([_io, _luca], []));
    expect(find.text('Capi allenatori'), findsNothing);
    expect(find.text('Allenatori e assistenti'), findsOneWidget);
  });

  testWidgets('se le squadre non si leggono il resto della pagina c\'è', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca], [_u14])
      ..erroreSquadre = Exception('rete');
    await _apri(tester, server);
    expect(find.text('Capi allenatori'), findsNothing);
    expect(find.text('Luca Bianchi'), findsOneWidget);
  });

  testWidgets('chi non è il responsabile vede le righe e basta', (
    tester,
  ) async {
    final luca = _luca.copy(sonoIo: true);
    await _apri(tester, _ClubFinto([_responsabileAnonimo, luca], [_u14, _u16]));

    expect(find.text('U14'), findsOneWidget);
    // Nessun segno di riga che si apre: l'unica freccia è quella degli
    // specialisti convenzionati, che lo staff apre per leggerli.
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.widgetWithText(
          SchedaElenco,
          'Specialisti convenzionati',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('U16'));
    await _passa(tester);
    expect(find.text('Capo di U16'), findsNothing);
  });

  testWidgets('senza nome il capo è l\'email (responsabile) o «Senza nome»', (
    tester,
  ) async {
    const respSenzaNome = MembroClub(
      userId: 'u-io',
      ruolo: RuoloClub.responsabile,
      email: 'marco@example.com',
      sonoIo: true,
    );
    const anonimo = MembroClub(
      userId: 'u-x',
      ruolo: RuoloClub.allenatore,
      sonoIo: false,
    );
    await _apri(
      tester,
      _ClubFinto(
        [respSenzaNome, anonimo],
        [
          const SquadraConCapo(id: 'g1', nome: 'U12', capoUserId: 'u-io'),
          const SquadraConCapo(id: 'g2', nome: 'U10', capoUserId: 'u-x'),
        ],
      ),
    );
    // L'email compare nella riga del membro e in quella della squadra.
    expect(find.text('marco@example.com'), findsNWidgets(2));
    expect(find.text('Senza nome'), findsNWidgets(2));
  });

  testWidgets('il responsabile sceglie il capo: niente assistenti', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca, _anna], [_u14, _u16]);
    await _apri(tester, server);

    await tester.tap(find.text('U16'));
    await _passa(tester);

    expect(find.text('Capo di U16'), findsOneWidget);
    // Nel foglio: responsabile, allenatore, «Nessun capo»; non l'assistente.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Marco Zucchi'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Luca Bianchi'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Anna Verdi'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nessun capo'),
      ),
      findsOneWidget,
    );

    final letture = server.lettureSquadre;
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Luca Bianchi'),
      ),
    );
    await _passa(tester);

    expect(server.scelte, [('g16', 'u-luca')]);
    // L'elenco è riletto: ora Luca è capo di entrambe.
    expect(server.lettureSquadre, greaterThan(letture));
    expect(find.text('Capo di U14, U16'), findsOneWidget);
  });

  testWidgets('«Nessun capo» manda null', (tester) async {
    final server = _ClubFinto([_io, _luca], [_u14]);
    await _apri(tester, server);

    await tester.tap(find.text('U14'));
    await _passa(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Nessun capo'),
      ),
    );
    await _passa(tester);

    expect(server.scelte, [('g14', null)]);
    expect(find.text('Capo di U14'), findsNothing);
  });

  testWidgets('chiudere il foglio senza scegliere non cambia niente', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca], [_u14]);
    await _apri(tester, server);

    await tester.tap(find.text('U14'));
    await _passa(tester);
    await tester.tapAt(const Offset(180, 20));
    await _passa(tester);

    expect(server.scelte, isEmpty);
  });

  testWidgets('se la scelta fallisce, un avviso con il motivo', (tester) async {
    final server = _ClubFinto([_io, _luca], [_u14, _u16])
      ..erroreAzione = const MessaggioClub('Solo il responsabile sceglie');
    await _apri(tester, server);

    await tester.tap(find.text('U16'));
    await _passa(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Luca Bianchi'),
      ),
    );
    await _passa(tester);

    expect(find.textContaining('Solo il responsabile sceglie'), findsOneWidget);
    expect(server.scelte, isEmpty);
  });
}

extension on MembroClub {
  MembroClub copy({bool? sonoIo}) => MembroClub(
    userId: userId,
    nome: nome,
    ruolo: ruolo,
    email: email,
    sonoIo: sonoIo ?? this.sonoIo,
  );
}
