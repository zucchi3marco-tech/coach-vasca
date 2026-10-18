import 'package:coach_vasca/features/club/data/membri_club_repository.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/club/presentation/mio_club_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: tiene l'elenco dei membri e annota cosa gli si chiede.
class _ClubFinto implements MembriClubRepository {
  _ClubFinto(this.membri_);

  List<MembroClub> membri_;
  Object? erroreElenco;
  Object? erroreAzione;
  final inviti = <(String, RuoloClub)>[];
  final tolti = <String>[];
  final cambi = <(String, RuoloClub)>[];
  final nomi = <String>[];
  var letture = 0;

  @override
  Future<List<MembroClub>> membri(String clubId) async {
    letture++;
    if (erroreElenco != null) throw erroreElenco!;
    return membri_;
  }

  @override
  Future<String> generaInvito(String clubId, RuoloClub ruolo) async {
    if (erroreAzione != null) throw erroreAzione!;
    inviti.add((clubId, ruolo));
    return 'ABCDE12345';
  }

  @override
  Future<void> togliMembro(String clubId, String userId) async {
    if (erroreAzione != null) throw erroreAzione!;
    tolti.add(userId);
    membri_ = [
      for (final m in membri_)
        if (m.userId != userId) m,
    ];
  }

  @override
  Future<void> cambiaRuolo(
    String clubId,
    String userId,
    RuoloClub ruolo,
  ) async {
    if (erroreAzione != null) throw erroreAzione!;
    cambi.add((userId, ruolo));
  }

  @override
  Future<void> scriviMioNome(String clubId, String nome) async {
    if (erroreAzione != null) throw erroreAzione!;
    nomi.add(nome);
    membri_ = [
      for (final m in membri_)
        if (m.sonoIo)
          MembroClub(
            userId: m.userId,
            nome: nome,
            ruolo: m.ruolo,
            sonoIo: true,
            email: m.email,
          )
        else
          m,
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
  email: 'luca@example.com',
  sonoIo: false,
);
const _anna = MembroClub(
  userId: 'u-anna',
  nome: 'Anna Verdi',
  ruolo: RuoloClub.assistente,
  email: 'anna@example.com',
  sonoIo: false,
);

Widget _app(_ClubFinto server) => ProviderScope(
  overrides: [membriClubRepositoryProvider.overrideWithValue(server)],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // Come "Riduci movimento": l'acqua della testata è animata senza fine.
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
  // Telefono, alto abbastanza per tutta la lista.
  tester.view.physicalSize = const Size(360, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(server));
  await _passa(tester);
}

/// Apre il menu «⋮» della riga con questo nome.
Future<void> _apriMenuDi(WidgetTester tester, String nome) async {
  await tester.tap(find.byTooltip('Azioni per $nome'));
  await _passa(tester);
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('il responsabile vede i membri, i ruoli e il pulsante invito', (
    tester,
  ) async {
    await _apri(tester, _ClubFinto([_io, _luca, _anna]));

    expect(find.text('Mako Pallanuoto'), findsOneWidget);
    expect(find.text('Il mio club'), findsOneWidget);
    expect(find.text('Chi allena con te e cosa può fare.'), findsOneWidget);
    expect(find.text('Allenatori e assistenti'), findsOneWidget);
    expect(find.text('Marco Zucchi'), findsOneWidget);
    expect(find.text('Luca Bianchi'), findsOneWidget);
    expect(find.text('Anna Verdi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
    expect(find.text('Cosa può fare chi'), findsOneWidget);
    for (final ruolo in RuoloClub.values) {
      expect(find.text(ruolo.descrizione), findsOneWidget);
    }
    expect(find.text('Invita un allenatore'), findsOneWidget);
    // Niente scheda «Scrivi il tuo nome»: il nome c'è.
    expect(find.text('Scrivi il tuo nome'), findsNothing);
  });

  testWidgets('il menu del responsabile sugli altri membri', (tester) async {
    await _apri(tester, _ClubFinto([_io, _luca, _anna]));

    // Su un allenatore: può farlo assistente, non allenatore.
    await _apriMenuDi(tester, 'Luca Bianchi');
    expect(find.text('Fai assistente'), findsOneWidget);
    expect(find.text('Fai allenatore'), findsNothing);
    expect(find.text('Togli dal club'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await _passa(tester);

    // Su un assistente: può farlo allenatore.
    await _apriMenuDi(tester, 'Anna Verdi');
    expect(find.text('Fai allenatore'), findsOneWidget);
    expect(find.text('Fai assistente'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await _passa(tester);

    // Su di sé: solo il nome, niente ruolo né «Togli».
    await _apriMenuDi(tester, 'Marco Zucchi');
    expect(find.text('Cambia il tuo nome'), findsOneWidget);
    expect(find.text('Togli dal club'), findsNothing);
  });

  testWidgets('«Fai assistente» cambia il ruolo e rilegge l\'elenco', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca]);
    await _apri(tester, server);
    final letture = server.letture;

    await _apriMenuDi(tester, 'Luca Bianchi');
    await tester.tap(find.text('Fai assistente'));
    await _passa(tester);

    expect(server.cambi, [('u-luca', RuoloClub.assistente)]);
    expect(server.letture, greaterThan(letture));
  });

  testWidgets('un assistente non vede invito né menu sugli altri', (
    tester,
  ) async {
    const assistente = MembroClub(
      userId: 'u-io',
      nome: 'Anna Verdi',
      ruolo: RuoloClub.assistente,
      sonoIo: true,
    );
    await _apri(tester, _ClubFinto([_io.copy(sonoIo: false), assistente]));

    expect(find.text('Invita un allenatore'), findsNothing);
    expect(find.byTooltip('Azioni per Marco Zucchi'), findsNothing);
    // Il proprio nome si può cambiare.
    expect(find.byTooltip('Azioni per Anna Verdi'), findsOneWidget);
  });

  testWidgets('senza nome compare la scheda «Scrivi il tuo nome»', (
    tester,
  ) async {
    const senzaNome = MembroClub(
      userId: 'u-io',
      ruolo: RuoloClub.responsabile,
      email: 'marco@example.com',
      sonoIo: true,
    );
    final server = _ClubFinto([senzaNome, _luca]);
    await _apri(tester, server);

    expect(find.text('Scrivi il tuo nome'), findsOneWidget);
    expect(
      find.text(
        'Lo vedono gli altri allenatori, per esempio quando modifichi un '
        'allenamento.',
      ),
      findsOneWidget,
    );
    // Il responsabile vede l'email di chi non ha ancora un nome.
    expect(find.text('marco@example.com'), findsOneWidget);

    await tester.tap(find.text('Scrivi il nome'));
    await _passa(tester);
    await tester.enterText(find.byType(TextFormField), 'Marco Zucchi');
    await tester.tap(find.text('Salva'));
    await _passa(tester);

    expect(server.nomi, ['Marco Zucchi']);
    // Ora il nome c'è: la scheda sparisce.
    expect(find.text('Scrivi il tuo nome'), findsNothing);
    expect(find.text('Marco Zucchi'), findsOneWidget);
  });

  testWidgets('chi non ha nome né email (non responsabile) è «Senza nome»', (
    tester,
  ) async {
    const anonimo = MembroClub(
      userId: 'u-x',
      ruolo: RuoloClub.allenatore,
      sonoIo: false,
    );
    await _apri(tester, _ClubFinto([_io.copy(sonoIo: false), anonimo]));
    expect(find.text('Senza nome'), findsOneWidget);
  });

  testWidgets('invitare: sceglie il ruolo, crea il codice e lo mostra', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca]);
    await _apri(tester, server);

    await tester.tap(find.text('Invita un allenatore'));
    await _passa(tester);
    expect(find.text('Chi inviti?'), findsOneWidget);
    expect(find.text(RuoloClub.allenatore.descrizione), findsWidgets);

    await tester.tap(find.widgetWithText(ListTile, 'Assistente'));
    await _passa(tester);

    expect(server.inviti, [('c1', RuoloClub.assistente)]);
    expect(find.text('ABCDE12345'), findsOneWidget);
    expect(find.text('Vale 7 giorni, una volta sola.'), findsOneWidget);
    expect(find.text('Copia'), findsOneWidget);
    expect(find.text('Condividi'), findsOneWidget);
  });

  testWidgets('«Copia» mette il codice negli appunti', (tester) async {
    String? copiato;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiato = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _apri(tester, _ClubFinto([_io]));
    await tester.tap(find.text('Invita un allenatore'));
    await _passa(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Allenatore'));
    await _passa(tester);

    await tester.tap(find.text('Copia'));
    await tester.pump();

    expect(copiato, 'ABCDE12345');
    expect(find.text('Codice copiato'), findsOneWidget);
  });

  testWidgets('«Condividi» senza foglio di condivisione copia il messaggio', (
    tester,
  ) async {
    String? copiato;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiato = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _apri(tester, _ClubFinto([_io]));
    await tester.tap(find.text('Invita un allenatore'));
    await _passa(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Assistente'));
    await _passa(tester);

    await tester.tap(find.text('Condividi'));
    await tester.pump();

    expect(
      copiato,
      'Ti invito in Mako Pallanuoto su WaterTactics come assistente. '
      'Registrati come allenatore e scegli «Ho un codice da allenatore»: '
      'ABCDE12345',
    );
  });

  testWidgets('se il codice non si crea, un avviso e niente dialogo', (
    tester,
  ) async {
    final server = _ClubFinto([_io])
      ..erroreAzione = const MessaggioClub('Solo il responsabile invita');
    await _apri(tester, server);

    await tester.tap(find.text('Invita un allenatore'));
    await _passa(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Allenatore'));
    await _passa(tester);

    expect(find.textContaining('Solo il responsabile invita'), findsOneWidget);
    expect(find.text('Vale 7 giorni, una volta sola.'), findsNothing);
  });

  testWidgets('togliere: chiede conferma e poi chiama il server', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca, _anna]);
    await _apri(tester, server);

    await _apriMenuDi(tester, 'Luca Bianchi');
    await tester.tap(find.text('Togli dal club'));
    await _passa(tester);

    expect(find.text('Togliere Luca Bianchi dal club?'), findsOneWidget);
    expect(
      find.text(
        'Non vedrà più gli allenamenti e i dati del club. Potrai invitarlo di '
        'nuovo con un codice.',
      ),
      findsOneWidget,
    );

    // Annulla: niente cambia.
    await tester.tap(find.text('Annulla'));
    await _passa(tester);
    expect(server.tolti, isEmpty);
    expect(find.text('Luca Bianchi'), findsOneWidget);

    await _apriMenuDi(tester, 'Luca Bianchi');
    await tester.tap(find.text('Togli dal club'));
    await _passa(tester);
    await tester.tap(find.text('Togli'));
    await _passa(tester);

    expect(server.tolti, ['u-luca']);
    // L'elenco è riletto: Luca non c'è più.
    expect(find.text('Luca Bianchi'), findsNothing);
    expect(find.text('Anna Verdi'), findsOneWidget);
  });

  testWidgets('se togliere fallisce, un avviso con il motivo', (tester) async {
    final server = _ClubFinto([_io, _luca])
      ..erroreAzione = const MessaggioClub('Membro non trovato');
    await _apri(tester, server);

    await _apriMenuDi(tester, 'Luca Bianchi');
    await tester.tap(find.text('Togli dal club'));
    await _passa(tester);
    await tester.tap(find.text('Togli'));
    await _passa(tester);

    expect(find.textContaining('Membro non trovato'), findsOneWidget);
    expect(find.text('Luca Bianchi'), findsOneWidget);
  });

  testWidgets('se l\'elenco non si legge: fascia d\'errore e «Riprova»', (
    tester,
  ) async {
    final server = _ClubFinto([_io, _luca])..erroreElenco = Exception('rete');
    await _apri(tester, server);

    expect(
      find.text('Non è stato possibile leggere chi c\'è nel club.'),
      findsOneWidget,
    );
    expect(find.text('Riprova'), findsOneWidget);
    expect(find.text('Invita un allenatore'), findsNothing);

    server.erroreElenco = null;
    await tester.tap(find.text('Riprova'));
    await _passa(tester);
    expect(find.text('Luca Bianchi'), findsOneWidget);
  });

  testWidgets('nella demo non chiama il server', (tester) async {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
    final server = _ClubFinto([_io]);
    await _apri(tester, server);

    expect(find.text('Nella demo il club è solo tuo'), findsOneWidget);
    expect(
      find.text(
        'Con l\'app vera qui inviti allenatori e assistenti e decidi cosa '
        'possono fare.',
      ),
      findsOneWidget,
    );
    expect(find.text('Torna indietro'), findsOneWidget);
    expect(server.letture, 0);
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
