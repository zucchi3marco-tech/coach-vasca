import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/configurazione/application/configurazione_providers.dart';
import 'package:coach_vasca/features/configurazione/data/configurazione_repository.dart';
import 'package:coach_vasca/features/configurazione/domain/stato_configurazione.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StatoConfigurazione _stato({
  int squadre = 0,
  int altriAllenatori = 0,
  bool invitiAllenatori = false,
  bool allenaDaSolo = false,
  int atleti = 0,
  int atletiConAccount = 0,
  bool codiciAtleti = false,
}) => StatoConfigurazione(
  squadre: squadre,
  altriAllenatori: altriAllenatori,
  invitiAllenatori: invitiAllenatori,
  allenaDaSolo: allenaDaSolo,
  atleti: atleti,
  atletiConAccount: atletiConAccount,
  codiciAtleti: codiciAtleti,
);

Atleta _atleta(String id, {String? userId}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Nome',
  cognome: id,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  userId: userId,
);

class _RepositoryFinto implements ConfigurazioneRepository {
  _RepositoryFinto({this.inviti = false, this.codici = false});

  final bool inviti;
  final bool codici;
  int letture = 0;

  @override
  Future<bool> ciSonoInvitiAllenatori(String clubId) async {
    letture++;
    return inviti;
  }

  @override
  Future<bool> ciSonoCodiciAtleti(String clubId) async {
    letture++;
    return codici;
  }
}

ProviderContainer _container({
  List<Gruppo> gruppi = const [],
  List<Atleta> atleti = const [],
  List<MembroClub> membri = const [],
  ConfigurazioneRepository? repository,
}) {
  final container = ProviderContainer(
    overrides: [
      gruppiListProvider.overrideWith((ref, _) => Stream.value(gruppi)),
      atletiListProvider.overrideWith((ref, _) => Stream.value(atleti)),
      membriClubProvider.overrideWith((ref, _) async => membri),
      configurazioneRepositoryProvider.overrideWithValue(
        repository ?? _RepositoryFinto(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Legge il provider tenendolo in ascolto, come fa una schermata (in
/// Riverpod 3 un provider senza ascoltatori può restare in pausa).
Future<StatoConfigurazione> _leggi(ProviderContainer container) async {
  final sub = container.listen(statoConfigurazioneProvider('c1'), (_, _) {});
  addTearDown(sub.close);
  return container.read(statoConfigurazioneProvider('c1').future);
}

void main() {
  group('PassoConfigurazione', () {
    test('numeri e passi facoltativi', () {
      expect(PassoConfigurazione.totale, 5);
      expect(PassoConfigurazione.club.numero, 1);
      expect(PassoConfigurazione.codici.numero, 5);
      expect(PassoConfigurazione.values.where((p) => p.facoltativo), [
        PassoConfigurazione.allenatori,
        PassoConfigurazione.atleti,
        PassoConfigurazione.codici,
      ]);
    });
  });

  group('StatoConfigurazione', () {
    test('club appena creato: solo il club è fatto', () {
      final stato = _stato();
      expect(stato.fatti, 1);
      expect(stato.tuttoFatto, isFalse);
      expect(stato.prossimo, PassoConfigurazione.squadre);
    });

    test('gli allenatori contano fatti con un membro, un invito o da solo', () {
      expect(_stato().fatto(PassoConfigurazione.allenatori), isFalse);
      expect(
        _stato(altriAllenatori: 1).fatto(PassoConfigurazione.allenatori),
        isTrue,
      );
      expect(
        _stato(invitiAllenatori: true).fatto(PassoConfigurazione.allenatori),
        isTrue,
      );
      expect(
        _stato(allenaDaSolo: true).fatto(PassoConfigurazione.allenatori),
        isTrue,
      );
    });

    test('i codici contano fatti con un account o un codice creato', () {
      expect(_stato(atleti: 3).fatto(PassoConfigurazione.codici), isFalse);
      expect(
        _stato(
          atleti: 3,
          atletiConAccount: 1,
        ).fatto(PassoConfigurazione.codici),
        isTrue,
      );
      expect(
        _stato(atleti: 3, codiciAtleti: true).fatto(PassoConfigurazione.codici),
        isTrue,
      );
    });

    test(
      'il prossimo è il primo non fatto, anche se dopo ce ne sono di fatti',
      () {
        final stato = _stato(squadre: 2, atleti: 10, atletiConAccount: 4);
        expect(stato.fatti, 4);
        expect(stato.prossimo, PassoConfigurazione.allenatori);
      },
    );

    test('tutto fatto', () {
      final stato = _stato(
        squadre: 1,
        allenaDaSolo: true,
        atleti: 1,
        codiciAtleti: true,
      );
      expect(stato.fatti, 5);
      expect(stato.tuttoFatto, isTrue);
      expect(stato.prossimo, isNull);
    });
  });

  group('statoConfigurazioneProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
    });

    test('mette insieme squadre, atleti, membri e codici', () async {
      final container = _container(
        gruppi: const [Gruppo(id: 'g1', clubId: 'c1', nome: 'U14', ordine: 1)],
        atleti: [
          _atleta('a1', userId: 'u9'),
          _atleta('a2'),
        ],
        membri: const [
          MembroClub(userId: 'io', ruolo: RuoloClub.responsabile, sonoIo: true),
        ],
        repository: _RepositoryFinto(codici: true),
      );

      final stato = await _leggi(container);

      expect(stato.squadre, 1);
      expect(stato.atleti, 2);
      expect(stato.atletiConAccount, 1);
      expect(stato.altriAllenatori, 0);
      expect(stato.invitiAllenatori, isFalse);
      expect(stato.codiciAtleti, isTrue);
      expect(stato.prossimo, PassoConfigurazione.allenatori);
    });

    test('conta gli altri membri, non me', () async {
      final container = _container(
        membri: const [
          MembroClub(userId: 'io', ruolo: RuoloClub.responsabile, sonoIo: true),
          MembroClub(userId: 'u2', ruolo: RuoloClub.assistente, sonoIo: false),
        ],
      );

      final stato = await _leggi(container);

      expect(stato.altriAllenatori, 1);
      expect(stato.fatto(PassoConfigurazione.allenatori), isTrue);
    });

    test('"Alleno da solo" resta sul dispositivo, per club', () async {
      const preferenze = PreferenzeConfigurazione();
      await preferenze.segnaAllenaDaSolo('c1');

      final container = _container();
      final stato = await _leggi(container);
      expect(stato.allenaDaSolo, isTrue);
      expect(await preferenze.allenaDaSolo('c2'), isFalse);
    });

    test('nella demo non chiede niente al server', () async {
      dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
      final repository = _RepositoryFinto(inviti: true, codici: true);
      final container = ProviderContainer(
        overrides: [
          gruppiListProvider.overrideWith((ref, _) => Stream.value(const [])),
          atletiListProvider.overrideWith((ref, _) => Stream.value(const [])),
          membriClubProvider.overrideWith(
            (ref, _) async => throw StateError('niente rete nella demo'),
          ),
          configurazioneRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final stato = await _leggi(container);

      expect(repository.letture, 0);
      expect(stato.altriAllenatori, 0);
      expect(stato.invitiAllenatori, isFalse);
      expect(stato.codiciAtleti, isFalse);
    });
  });

  group('PreferenzeConfigurazione', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('nascondere la scheda vale per quel club', () async {
      const preferenze = PreferenzeConfigurazione();
      expect(await preferenze.nascosta('c1'), isFalse);
      await preferenze.nascondi('c1');
      expect(await preferenze.nascosta('c1'), isTrue);
      expect(await preferenze.nascosta('c2'), isFalse);
    });
  });
}
