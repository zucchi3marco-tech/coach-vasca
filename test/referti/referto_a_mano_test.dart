import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/referti/application/referti_providers.dart';
import 'package:coach_vasca/features/referti/data/referti_repository.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/referti/presentation/leggi_referto_screen.dart';
import 'package:coach_vasca/features/referti/presentation/referto_partita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DistintaFinta implements DistintaRepository {
  @override
  Future<void> impostaTempiInPorta(String id, List<int> tempi) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Registra il referto salvato.
class _RefertiFinto implements RefertiRepository {
  Map<String, Object?>? salvato;

  @override
  Future<RefertoPartita> salvaReferto({
    required String partitaId,
    required String squadraCasa,
    required String squadraTrasferta,
    required int risultatoCasa,
    required int risultatoTrasferta,
    required List<ParzialeReferto> parziali,
    required List<GiocatoreReferto> giocatoriCasa,
    required List<GiocatoreReferto> giocatoriTrasferta,
  }) async {
    salvato = {
      'risultato': '$risultatoCasa-$risultatoTrasferta',
      'parziali': [for (final p in parziali) '${p.casa}-${p.trasferta}'],
      'casa': [
        for (final g in giocatoriCasa)
          '${g.numeroCalottina} ${g.nome} ${g.reti} ${g.atletaId}',
      ],
      'trasferta': [
        for (final g in giocatoriTrasferta) '${g.numeroCalottina} ${g.reti}',
      ],
    };
    return RefertoPartita(
      id: 'r1',
      partitaId: partitaId,
      clubId: 'c1',
      squadraCasa: squadraCasa,
      squadraTrasferta: squadraTrasferta,
      risultatoCasa: risultatoCasa,
      risultatoTrasferta: risultatoTrasferta,
      parziali: parziali,
      giocatoriCasa: giocatoriCasa,
      giocatoriTrasferta: giocatoriTrasferta,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 24),
  squadraCasa: 'Canottieri Milano',
  squadraTrasferta: 'NC Monza',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: 'casa',
);

DistintaGiocatore _riga(String atleta, int numero) => DistintaGiocatore(
  id: 'd$atleta',
  partitaId: 'p1',
  atletaId: atleta,
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: false,
  viceCapitano: false,
  portiere: false,
  fuoriquota: false,
);

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Luca',
  cognome: cognome,
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

void main() {
  test('il referto vuoto parte dai convocati, in casa o fuori', () {
    final atleti = {'a': _atleta('a', 'Rossi'), 'b': _atleta('b', 'Bianchi')};
    final distinta = [_riga('b', 7), _riga('a', 3)];

    final inCasa = refertoVuoto(_partita, distinta, atleti);
    expect(inCasa.squadraCasa, 'Canottieri Milano');
    expect(inCasa.parziali, hasLength(4));
    expect(
      [for (final g in inCasa.giocatoriCasa) '${g.numeroCalottina} ${g.nome}'],
      ['3 Rossi Luca', '7 Bianchi Luca'],
    );
    expect(inCasa.giocatoriCasa.first.atletaId, 'a');
    expect(inCasa.giocatoriTrasferta, hasLength(13));

    final fuori = refertoVuoto(
      Partita(
        id: 'p2',
        clubId: 'c1',
        data: DateTime(2026, 10, 24),
        squadraCasa: 'NC Monza',
        squadraTrasferta: 'Canottieri Milano',
        numeroMaxConvocati: 15,
        tracciaTempo: false,
        nostraSquadra: 'trasferta',
      ),
      distinta,
      atleti,
    );
    expect(fuori.giocatoriCasa, hasLength(13));
    expect(fuori.giocatoriTrasferta, hasLength(2));
  });

  testWidgets('senza referto: «Scrivi a mano», tempi che si sommano, '
      'righe vuote degli avversari scartate', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final referti = _RefertiFinto();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          distintaRepositoryProvider.overrideWithValue(_DistintaFinta()),
          refertiRepositoryProvider.overrideWithValue(referti),
          distintaListProvider.overrideWith(
            (ref, id) => Stream.value([_riga('a', 3), _riga('b', 7)]),
          ),
          atletiListProvider.overrideWith(
            (ref, filtro) =>
                Stream.value([_atleta('a', 'Rossi'), _atleta('b', 'Bianchi')]),
          ),
          refertoPerPartitaProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: RefertoPartitaScreen(partita: _partita),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scrivi a mano'));
    await tester.pumpAndSettle();
    expect(find.text('Scrivi referto'), findsOneWidget);
    expect(find.text('Rossi Luca'), findsOneWidget);

    // Su schermo largo i campi in ordine: squadra casa, gol casa, gol
    // trasferta, squadra trasferta, poi i 4 tempi (casa, trasferta).
    final campi = find.byType(TextFormField);
    Future<void> scrivi(int i, String testo) async {
      await tester.enterText(campi.at(i), testo);
      await tester.pump();
    }

    await scrivi(4, '1');
    await scrivi(5, '4');
    await scrivi(6, '6');
    await scrivi(7, '6');
    final golCasa = tester.widget<TextFormField>(campi.at(1));
    final golTrasferta = tester.widget<TextFormField>(campi.at(2));
    expect(golCasa.controller!.text, '7');
    expect(golTrasferta.controller!.text, '10');

    // Reti di Rossi (riga larga: n., nome, reti, esp.).
    final nomeRossi = find.widgetWithText(TextFormField, 'Rossi Luca');
    final indiceRossi = campi.evaluate().toList().indexOf(
      nomeRossi.evaluate().single,
    );
    await scrivi(indiceRossi + 1, '3');

    await tester.ensureVisible(find.text('Salva referto'));
    await tester.tap(find.text('Salva referto'));
    // Il pulsante gira finché non si chiude «Collega i giocatori».
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('Continua'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(referti.salvato, {
      'risultato': '7-10',
      'parziali': ['1-4', '6-6', '0-0', '0-0'],
      'casa': ['3 Rossi Luca 3 a', '7 Bianchi Luca 0 b'],
      'trasferta': <String>[],
    });
  });
}
