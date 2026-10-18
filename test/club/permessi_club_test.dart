import 'package:coach_vasca/features/club/application/membri_club_providers.dart';
import 'package:coach_vasca/features/club/data/membri_club_repository.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ClubFinto implements MembriClubRepository {
  _ClubFinto(this.ruolo, {this.errore});

  final RuoloClub? ruolo;
  final Object? errore;

  @override
  Future<RuoloClub?> mioRuolo(String clubId) async {
    if (errore != null) throw errore!;
    return ruolo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Il valore di [puoGestireAtletiESquadreProvider] mentre il ruolo si
/// legge e dopo.
Future<(bool, bool)> _valori(_ClubFinto server) async {
  final container = ProviderContainer(
    overrides: [membriClubRepositoryProvider.overrideWithValue(server)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(
    puoGestireAtletiESquadreProvider('c1'),
    (_, _) {},
  );
  final mentreCarica = sub.read();
  await container
      .read(mioRuoloProvider('c1').future)
      .then((_) {}, onError: (_) {});
  return (mentreCarica, container.read(puoGestireAtletiESquadreProvider('c1')));
}

void main() {
  test(
    'un assistente non gestisce atleti e squadre (e nemmeno mentre carica)',
    () async {
      final (mentreCarica, dopo) = await _valori(
        _ClubFinto(RuoloClub.assistente),
      );
      expect(mentreCarica, isFalse);
      expect(dopo, isFalse);
    },
  );

  test(
    'il responsabile e l\'allenatore sì, dopo aver letto il ruolo',
    () async {
      for (final ruolo in [RuoloClub.responsabile, RuoloClub.allenatore]) {
        final (mentreCarica, dopo) = await _valori(_ClubFinto(ruolo));
        expect(mentreCarica, isFalse, reason: 'finché non si sa, è nascosto');
        expect(dopo, isTrue);
      }
    },
  );

  test('se il ruolo non si legge (offline) le azioni restano', () async {
    final (_, dopo) = await _valori(
      _ClubFinto(null, errore: Exception('rete')),
    );
    expect(dopo, isTrue);
  });
}
