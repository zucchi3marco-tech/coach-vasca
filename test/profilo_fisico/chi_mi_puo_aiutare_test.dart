import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/db/cache_utente_guard.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/profilo_fisico/data/contatti_specialisti_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/data/profilo_fisico_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/presentation/contatti_specialisti_screen.dart';
import 'package:coach_vasca/features/profilo_fisico/data/specialisti_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/chi_mi_puo_aiutare.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/specialista.dart';
import 'package:coach_vasca/features/profilo_fisico/presentation/chi_mi_puo_aiutare_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 30);

Atleta _atleta({required DateTime nascita}) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Sofia',
  cognome: 'Rossi',
  dataNascita: nascita,
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'u16',
);

const _fisio = Specialista(
  id: 's1',
  clubId: 'c1',
  tipo: TipoSpecialista.fisioterapista,
  nome: 'Studio Rossi',
  descrizione: 'A Monza, sconto per gli atleti',
  whatsapp: '+393331234567',
);

const _nutri = Specialista(
  id: 's2',
  clubId: 'c1',
  tipo: TipoSpecialista.nutrizionista,
  nome: 'Dott.ssa Bianchi',
  sito: 'https://www.nutrisport.it/',
);

void main() {
  group('le regole', () {
    test('ogni problema porta allo specialista giusto', () {
      expect(ProblemaFisico.dolore.tipo, TipoSpecialista.fisioterapista);
      expect(ProblemaFisico.rigidita.tipo, TipoSpecialista.osteopata);
      expect(ProblemaFisico.gambe.tipo, TipoSpecialista.massoterapista);
      expect(ProblemaFisico.energia.tipo, TipoSpecialista.nutrizionista);
      expect(ProblemaFisico.forte.soloMedico, isTrue);

      const elenco = [_nutri, _fisio];
      expect(ProblemaFisico.dolore.specialisti(elenco), [_fisio]);
      expect(ProblemaFisico.energia.specialisti(elenco), [_nutri]);
      expect(ProblemaFisico.rigidita.specialisti(elenco), isEmpty);
      expect(ProblemaFisico.forte.specialisti(elenco), isEmpty);
      // «Non lo so»: tutti, per tipo.
      expect(ProblemaFisico.nonLoSo.specialisti(elenco), [_nutri, _fisio]);
    });

    test('il messaggio dice chi è, di che club e per cosa', () {
      expect(
        messaggioSpecialista(
          nomeAtleta: 'Sofia Rossi',
          nomeClub: 'Rari Nantes Monza',
          problema: ProblemaFisico.dolore,
        ),
        'Buongiorno, sono Sofia Rossi, atleta del club Rari Nantes Monza. '
        'Ho trovato il vostro contatto su WaterTactics e vorrei un '
        'appuntamento per: dolore a spalla, schiena o ginocchio.',
      );
      expect(
        messaggioSpecialista(
          nomeAtleta: 'Sofia Rossi',
          nomeClub: null,
          problema: ProblemaFisico.nonLoSo,
        ),
        'Buongiorno, sono Sofia Rossi, atleta di pallanuoto. Ho trovato il '
        'vostro contatto su WaterTactics e vorrei qualche informazione.',
      );
    });

    test('il collegamento WhatsApp ha il numero e il testo', () {
      expect(
        collegamentoWhatsapp('+393331234567', 'Ciao, sono Sofia: dolore?'),
        'https://wa.me/393331234567?text=Ciao%2C%20sono%20Sofia%3A%20dolore%3F',
      );
    });
  });

  group('la pagina', () {
    late _Contatti contatti;
    setUp(() => contatti = _Contatti());

    Future<void> apri(
      WidgetTester tester,
      Atleta atleta, {
      DateTime? consenso,
      List<Specialista> specialisti = const [_fisio, _nutri],
    }) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consensoProfiloFisicoProvider.overrideWith(
              (ref, id) async => consenso,
            ),
            specialistiProvider.overrideWith((ref, id) async => specialisti),
            contattiSpecialistiRepositoryProvider.overrideWithValue(contatti),
            clubAtletaProvider.overrideWith(
              (ref, id) async => const Club(id: 'c1', nome: 'Rari Nantes'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ChiMiPuoAiutareScreen(atleta: atleta, oggi: _oggi),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('chi ha meno di 18 anni senza consenso trova la pagina '
        'chiusa', (tester) async {
      await apri(tester, _atleta(nascita: DateTime(2011, 3, 4)));
      expect(find.textContaining('serve il consenso'), findsOneWidget);
      expect(find.text('Cosa senti?'), findsNothing);
      expect(find.text(ProblemaFisico.dolore.etichetta), findsNothing);
    });

    testWidgets('con il consenso il minorenne sceglie cosa sente', (
      tester,
    ) async {
      await apri(
        tester,
        _atleta(nascita: DateTime(2011, 3, 4)),
        consenso: DateTime(2026, 10, 1),
      );
      expect(find.text('Cosa senti?'), findsOneWidget);
      for (final p in ProblemaFisico.values) {
        expect(find.text(p.etichetta), findsOneWidget);
      }
    });

    testWidgets('dal dolore il fisioterapista, con il messaggio già pronto', (
      tester,
    ) async {
      final copiati = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiati.add((call.arguments as Map)['text'] as String);
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
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.dolore.etichetta));
      await tester.pumpAndSettle();

      expect(find.text('Studio Rossi'), findsOneWidget);
      expect(find.text('Dott.ssa Bianchi'), findsNothing);
      expect(find.textContaining('non una diagnosi'), findsOneWidget);

      // Fuori dal browser il messaggio va negli appunti.
      await tester.tap(find.text('Scrivi su WhatsApp'));
      await tester.pumpAndSettle();
      expect(copiati.single, contains('atleta del club Rari Nantes'));
      expect(copiati.single, contains('dolore a spalla, schiena o ginocchio'));
      expect(copiati.single, endsWith('Il mio codice WaterTactics è WT-4K7Q.'));
      // Il contatto si segna per il responsabile.
      expect(contatti.registrati.single, (
        'Studio Rossi',
        ProblemaFisico.dolore,
        CanaleContatto.whatsapp,
        'WT-4K7Q',
      ));
      expect(find.text('Il tuo codice'), findsOneWidget);
      expect(find.text('WT-4K7Q'), findsOneWidget);
      expect(find.textContaining('+39 333 123 4567'), findsWidgets);
    });

    testWidgets('senza osteopata nel club: parlane con l\'allenatore', (
      tester,
    ) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.rigidita.etichetta));
      await tester.pumpAndSettle();
      expect(find.text('Il club non ha ancora un osteopata'), findsOneWidget);
      await tester.tap(find.text('Scegli un\'altra cosa'));
      await tester.pumpAndSettle();
      expect(find.text('Cosa senti?'), findsOneWidget);
    });

    testWidgets('con un dolore forte solo il medico', (tester) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.forte.etichetta));
      await tester.pumpAndSettle();
      expect(find.textContaining('la persona giusta è il medico'), findsOne);
      expect(find.text('Studio Rossi'), findsNothing);
      expect(find.text('Scrivi su WhatsApp'), findsNothing);
    });

    testWidgets('«Non lo so» mostra tutti gli specialisti, con il sito', (
      tester,
    ) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.nonLoSo.etichetta));
      await tester.pumpAndSettle();
      expect(find.text('Studio Rossi'), findsOneWidget);
      expect(find.text('Dott.ssa Bianchi'), findsOneWidget);
      expect(find.text('Apri il sito'), findsOneWidget);
      expect(find.text('nutrisport.it'), findsOneWidget);
      expect(find.textContaining('dillo alla'), findsOneWidget);

      await tester.tap(find.text('Apri il sito'));
      await tester.pumpAndSettle();
      expect(contatti.registrati.single, (
        'Dott.ssa Bianchi',
        ProblemaFisico.nonLoSo,
        CanaleContatto.sito,
        'WT-4K7Q',
      ));
    });

    testWidgets('con un dolore forte non si segna niente', (tester) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.forte.etichetta));
      await tester.pumpAndSettle();
      expect(find.text('Il tuo codice'), findsNothing);
      expect(contatti.registrati, isEmpty);
    });
  });

  group('la traccia dei contatti', () {
    ContattoSpecialista contatto(
      String id,
      DateTime giorno, {
      String atleta = 'Sofia Rossi',
      String specialista = 'Studio Rossi',
      DateTime? confermata,
    }) => ContattoSpecialista(
      id: id,
      clubId: 'c1',
      atletaId: 'a-$atleta',
      nomeAtleta: atleta,
      specialistaId: 's-$specialista',
      specialistaNome: specialista,
      tipo: TipoSpecialista.fisioterapista,
      problema: ProblemaFisico.dolore,
      canale: CanaleContatto.whatsapp,
      codice: 'WT-4K7Q',
      giorno: giorno,
      confermataIl: confermata,
    );

    test('cambiando utente il codice e i contatti si cancellano', () async {
      SharedPreferences.setMockInitialValues({
        'ultimo_utente_id_cache_locale': 'u1',
        'codice_specialisti_a1': 'WT-4K7Q',
        'contatti_specialisti_c1': '[]',
        'specialisti_c1': '[]',
      });
      final db = AppDatabase.perTest(NativeDatabase.memory());
      addTearDown(db.close);
      await allineaCacheLocaleAllUtente(db, 'u2');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('codice_specialisti_a1'), isFalse);
      expect(prefs.containsKey('contatti_specialisti_c1'), isFalse);
      // L'elenco degli specialisti non è dei singoli: resta.
      expect(prefs.containsKey('specialisti_c1'), isTrue);
    });

    test('il messaggio senza codice non lo nomina', () {
      expect(
        messaggioSpecialista(
          nomeAtleta: 'Sofia Rossi',
          nomeClub: 'RN',
          problema: ProblemaFisico.gambe,
        ),
        isNot(contains('codice')),
      );
    });

    test('il codice della demo è come quelli del database', () {
      var i = 0;
      final codice = codiceCasuale((max) => (i++ * 7) % max);
      expect(codice, matches(RegExp(r'^WT-[A-Z0-9]{4}$')));
      expect(codice, isNot(matches(RegExp('[0O1I2Z5S8B]'))));
    });

    test('i problemi si scrivono e si rileggono', () {
      for (final p in ProblemaFisico.values) {
        expect(ProblemaFisico.daCodice(p.codice), p);
      }
      expect(ProblemaFisico.nonLoSo.codice, 'non_lo_so');
    });

    test('dalla riga del database, con il nome dell\'atleta', () {
      final c = ContattoSpecialista.fromMap({
        'id': 'x1',
        'club_id': 'c1',
        'atleta_id': 'a1',
        'atleti': {'nome': 'Sofia', 'cognome': 'Rossi'},
        'specialista_id': null,
        'specialista_nome': 'Studio Rossi',
        'specialista_tipo': 'fisioterapista',
        'problema': 'non_lo_so',
        'canale': 'sito',
        'codice': 'WT-4K7Q',
        'giorno': '2026-10-30',
        'visita_confermata_il': '2026-11-02',
      })!;
      expect(c.nomeAtleta, 'Sofia Rossi');
      expect(c.problema, ProblemaFisico.nonLoSo);
      expect(c.canale, CanaleContatto.sito);
      expect(c.confermata, isTrue);
      // La copia sul telefono si rilegge uguale.
      final copia = ContattoSpecialista.fromMap(c.toMap())!;
      expect(copia.nomeAtleta, 'Sofia Rossi');
      expect(copia.giorno, DateTime(2026, 10, 30));
      expect(copia.confermataIl, DateTime(2026, 11, 2));
    });

    test('per mese, con il totale di ogni specialista', () {
      final mesi = contattiPerMese([
        contatto('1', DateTime(2026, 9, 20)),
        contatto('2', DateTime(2026, 10, 3), confermata: DateTime(2026, 10, 9)),
        contatto('3', DateTime(2026, 10, 28), atleta: 'Luca Bianchi'),
        contatto('4', DateTime(2026, 10, 12), specialista: 'Dott.ssa Bianchi'),
      ]);
      expect(
        [for (final m in mesi) m.mese],
        [DateTime(2026, 10), DateTime(2026, 9)],
      );
      expect([for (final c in mesi.first.contatti) c.id], ['3', '4', '2']);
      expect(mesi.first.totali, [
        (nome: 'Studio Rossi', contatti: 2, confermate: 1),
        (nome: 'Dott.ssa Bianchi', contatti: 1, confermate: 0),
      ]);
    });

    testWidgets('il responsabile vede i contatti e spunta la visita', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final oggi = DateTime.now();
      final repo = _Contatti([contatto('1', oggi)]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contattiSpecialistiRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const ContattiSpecialistiScreen(clubId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sofia Rossi'), findsOneWidget);
      expect(find.textContaining('codice WT-4K7Q'), findsOneWidget);
      expect(find.text('1 contatto, 0 visite confermate'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(repo.elenco_.single.confermata, isTrue);
      expect(find.text('1 contatto, 1 visita confermata'), findsOneWidget);
    });

    testWidgets('senza contatti lo dice', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contattiSpecialistiRepositoryProvider.overrideWithValue(
              _Contatti(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const ContattiSpecialistiScreen(clubId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nessun contatto ancora'), findsOneWidget);
    });
  });
}

class _Contatti implements ContattiSpecialistiRepository {
  _Contatti([List<ContattoSpecialista>? iniziali]) : elenco_ = [...?iniziali];

  final List<ContattoSpecialista> elenco_;
  final registrati = <(String, ProblemaFisico, CanaleContatto, String?)>[];

  @override
  Future<String?> mioCodice(String atletaId) async => 'WT-4K7Q';

  @override
  Future<bool> registra({
    required Atleta atleta,
    required Specialista specialista,
    required ProblemaFisico problema,
    required CanaleContatto canale,
    required String? codice,
  }) async {
    registrati.add((specialista.nome, problema, canale, codice));
    return true;
  }

  @override
  Future<List<ContattoSpecialista>> elenco(String clubId) async => [...elenco_];

  @override
  Future<ContattoSpecialista> confermaVisita(
    ContattoSpecialista contatto, {
    required bool confermata,
  }) async {
    final nuovo = contatto.conConferma(confermata ? DateTime.now() : null);
    elenco_[elenco_.indexWhere((c) => c.id == contatto.id)] = nuovo;
    return nuovo;
  }
}
