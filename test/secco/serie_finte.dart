import 'dart:async';

import 'package:coach_vasca/features/secco/data/serie_fatte_repository.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';

/// Le serie fatte, in memoria, al posto del repository vero: chi le guarda
/// riceve ogni cambiamento, e [salvate] ricorda ogni salvataggio in ordine
/// (una serie e poi il suo voto sono due salvataggi).
class SerieFinte implements SerieFatteRepository {
  SerieFinte([Iterable<SerieFatta> iniziali = const []]) {
    serie.addAll(iniziali);
  }

  final serie = <SerieFatta>[];
  final salvate = <SerieFatta>[];
  final _cambi = StreamController<void>.broadcast();

  Stream<List<SerieFatta>> _flusso(bool Function(SerieFatta) dove) async* {
    yield [
      for (final f in serie)
        if (dove(f)) f,
    ];
    await for (final _ in _cambi.stream) {
      yield [
        for (final f in serie)
          if (dove(f)) f,
      ];
    }
  }

  @override
  Stream<List<SerieFatta>> watchPerAtleta(String atletaId) =>
      _flusso((f) => f.atletaId == atletaId);

  @override
  Stream<List<SerieFatta>> watchPerSeduta(String allenamentoId) =>
      _flusso((f) => f.allenamentoId == allenamentoId);

  @override
  Future<SerieFatta> salva(SerieFatta f) async {
    salvate.add(f);
    serie
      ..removeWhere(
        (s) =>
            s.atletaId == f.atletaId &&
            s.rigaId == f.rigaId &&
            s.serie == f.serie,
      )
      ..add(f);
    _cambi.add(null);
    return f;
  }

  @override
  Future<void> togli(SerieFatta f) async {
    serie.removeWhere(
      (s) =>
          s.atletaId == f.atletaId &&
          s.rigaId == f.rigaId &&
          s.serie == f.serie,
    );
    _cambi.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
