import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_vasca/features/segnalazioni/data/segnalazioni_repository.dart';
import 'package:coach_vasca/features/segnalazioni/domain/segnalazione.dart';

/// Un PNG vero di 1×1 pixel, per le anteprime.
final pngMinimo = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
  ),
);

Segnalazione segnalazioneDiProva({
  String id = 's1',
  String testo = 'Il cronometro si ferma da solo',
  bool risolta = false,
  String? risposta,
  String? schermata,
  DateTime? creataIl,
}) => Segnalazione(
  id: id,
  creataIl: creataIl ?? DateTime(2026, 10, 19, 9, 30),
  userId: 'u1',
  clubId: 'c1',
  autore: 'Marco Rossi',
  clubNome: 'Vasca Club',
  ruolo: 'coach',
  testo: testo,
  versione: '2026-10-19 a6ab096',
  pagina: 'Bordo vasca',
  dispositivo: 'Chrome su Android',
  schermo: '412×915',
  schermata: schermata,
  risolta: risolta,
  risposta: risposta,
);

class FintoSegnalazioniRepository implements SegnalazioniRepository {
  final inviate = <({String clubId, String testo, ContestoSegnalazione c})>[];
  final aggiornate = <({String id, bool risolta, String? risposta})>[];
  Object? erroreInvio;
  List<Segnalazione> mieSegnalazioni = const [];
  List<Segnalazione> tutteLeSegnalazioni = const [];
  bool amministratore = false;

  @override
  Future<void> invia({
    required String clubId,
    required String testo,
    required ContestoSegnalazione contesto,
  }) async {
    final errore = erroreInvio;
    if (errore != null) throw errore;
    inviate.add((clubId: clubId, testo: testo, c: contesto));
  }

  @override
  Future<List<Segnalazione>> mie() async => mieSegnalazioni;

  @override
  Future<List<Segnalazione>> tutte() async => tutteLeSegnalazioni;

  @override
  Future<bool> sonoAmministratore() async => amministratore;

  @override
  Future<Uint8List> schermata(String percorso) async => pngMinimo;

  @override
  Future<void> aggiorna(
    String id, {
    required bool risolta,
    required String? risposta,
  }) async {
    aggiornate.add((id: id, risolta: risolta, risposta: risposta));
  }
}
