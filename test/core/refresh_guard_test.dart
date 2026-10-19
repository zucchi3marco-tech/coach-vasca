import 'dart:async';

import 'package:coach_vasca/core/db/refresh_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Una copia sul telefono finta: emette subito il valore attuale, poi ogni
/// cambio (come uno stream di Drift).
class _Copia<T> {
  _Copia(this.valore);

  T valore;
  final _cambi = StreamController<T>.broadcast();

  Stream<T> watch() async* {
    yield valore;
    yield* _cambi.stream;
  }

  void scrivi(T nuovo) {
    valore = nuovo;
    _cambi.add(nuovo);
  }
}

void main() {
  test('con la copia piena si vede subito, poi l\'aggiornamento', () async {
    final copia = _Copia<List<String>>(['Luca']);
    final server = Completer<void>();
    final visti = <List<String>>[];

    final sub = streamConRefreshIniziale(
      refresh: () async {
        await server.future;
        copia.scrivi(['Luca', 'Marco']);
      },
      watch: copia.watch,
    ).listen(visti.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    // Il server non ha ancora risposto: c'è già la copia.
    expect(visti, [
      ['Luca'],
    ]);

    server.complete();
    await pumpEventQueue();
    expect(visti.last, ['Luca', 'Marco']);
  });

  test('con la copia vuota aspetta il server, per non dire «vuoto» '
      'per sbaglio', () async {
    final copia = _Copia<List<String>>([]);
    final server = Completer<void>();
    final visti = <List<String>>[];

    final sub = streamConRefreshIniziale(
      refresh: () async {
        await server.future;
        copia.scrivi(['Luca']);
      },
      watch: copia.watch,
    ).listen(visti.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(visti, isEmpty);

    server.complete();
    await pumpEventQueue();
    expect(visti.first, ['Luca']);
  });

  test('un valore singolo assente (null) conta come copia vuota', () async {
    final copia = _Copia<String?>(null);
    final server = Completer<void>();
    final visti = <String?>[];

    final sub = streamConRefreshIniziale(
      refresh: () => server.future,
      watch: copia.watch,
    ).listen(visti.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(visti, isEmpty);
    server.complete();
    await pumpEventQueue();
    expect(visti, [null]);
  });

  test('senza rete si resta con la copia, senza errori', () async {
    final copia = _Copia<List<String>>(['Luca']);
    final errori = <Object>[];
    final visti = <List<String>>[];

    final sub = streamConRefreshIniziale(
      refresh: () async => throw http.ClientException('rete assente'),
      watch: copia.watch,
    ).listen(visti.add, onError: errori.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(visti, [
      ['Luca'],
    ]);
    expect(errori, isEmpty);
  });

  test('senza rete e con la copia vuota: la copia vuota', () async {
    final copia = _Copia<List<String>>([]);
    final visti = <List<String>>[];

    final sub = streamConRefreshIniziale(
      refresh: () async => throw http.ClientException('rete assente'),
      watch: copia.watch,
    ).listen(visti.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(visti, [<String>[]]);
  });

  test('un errore vero del server non si nasconde, anche con la copia '
      'piena', () async {
    final copia = _Copia<List<String>>(['Luca']);
    final errori = <Object>[];
    final visti = <List<String>>[];

    final sub = streamConRefreshIniziale(
      refresh: () async => throw StateError('permesso negato'),
      watch: copia.watch,
    ).listen(visti.add, onError: errori.add);
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(visti, [
      ['Luca'],
    ]);
    expect(errori.single, isA<StateError>());
  });

  test('un errore vero con la copia vuota risale come prima', () async {
    final copia = _Copia<List<String>>([]);
    await expectLater(
      streamConRefreshIniziale(
        refresh: () async => throw StateError('permesso negato'),
        watch: copia.watch,
      ),
      emitsError(isA<StateError>()),
    );
  });
}
