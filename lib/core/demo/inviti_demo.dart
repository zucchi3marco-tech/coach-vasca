import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:uuid/uuid.dart';

import '../../features/atleti/data/codici_gruppo_repository.dart';
import '../../features/atleti/data/inviti_atleta_repository.dart';
import '../../features/atleti/domain/atleta.dart';
import '../../features/atleti/domain/codice_gruppo.dart';
import '../db/app_database.dart';
import 'modalita_demo.dart';

/// Codici invito della demo, tutti in locale (in produzione sono RPC
/// Supabase). Per entrare sempre, in demo **ogni** codice e' valido:
/// - un codice generato dall'allenatore nell'app porta all'atleta o al
///   gruppo per cui e' stato creato;
/// - un codice che contiene "GRUPPO" fa il percorso del codice di gruppo
///   (primo gruppo del club);
/// - qualunque altro codice fa il percorso del codice personale, sul
///   primo atleta attivo senza account.

const _chiaveInviti = 'demo_inviti_atleta';
const _chiaveCodiciGruppo = 'demo_codici_gruppo';

String _nuovoCodice() {
  const alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(6, (_) => alfabeto[r.nextInt(alfabeto.length)]).join();
}

String _normalizza(String codice) => codice.trim().toUpperCase();

Future<Map<String, dynamic>> _leggi(String chiave) async {
  final prefs = await SharedPreferences.getInstance();
  final testo = prefs.getString(chiave);
  return testo == null ? {} : jsonDecode(testo) as Map<String, dynamic>;
}

Future<void> _scrivi(String chiave, Map<String, dynamic> valore) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(chiave, jsonEncode(valore));
}

Atleta _atletaDaRiga(AtletiTableData r) => Atleta.fromMap({
  'id': r.id,
  'club_id': r.clubId,
  'nome': r.nome,
  'cognome': r.cognome,
  'data_nascita': r.dataNascita.toIso8601String(),
  'sesso': r.sesso,
  'sport': r.sport,
  'gruppo_id': r.gruppoId,
  'email_genitore': r.emailGenitore,
  'telefono_genitore': r.telefonoGenitore,
  'consenso_privacy_firmato': r.consensoPrivacyFirmato,
  'consenso_privacy_data': r.consensoPrivacyData?.toIso8601String(),
  'note': r.note,
  'attivo': r.attivo,
  'numero_tessera_fin': r.numeroTesseraFin,
  'user_id': r.userId,
  'visita_medica_scadenza': r.visitaMedicaScadenza?.toIso8601String(),
});

/// Se nessun atleta e' collegato a [userId] (database demo ricreato),
/// collega il primo atleta attivo senza account: rientrare con l'email
/// di un atleta porta sempre nell'Area atleta.
Future<void> garantisciAtletaDemo(AppDatabase db, String userId) async {
  final gia = await (db.select(
    db.atletiTable,
  )..where((t) => t.userId.equals(userId))).get();
  if (gia.isNotEmpty) return;
  final liberi =
      await (db.select(db.atletiTable)
            ..where((t) => t.userId.isNull() & t.attivo.equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.cognome)])
            ..limit(1))
          .get();
  if (liberi.isEmpty) return;
  await (db.update(db.atletiTable)..where((t) => t.id.equals(liberi.first.id)))
      .write(AtletiTableCompanion(userId: Value(userId)));
}

class InvitiAtletaRepositoryDemo extends InvitiAtletaRepository {
  InvitiAtletaRepositoryDemo(this._db, this._auth)
    : super(Supabase.instance.client);

  final AppDatabase _db;
  final AuthRepositoryDemo _auth;

  @override
  Future<String> generaInvito(String atletaId) async {
    final inviti = await _leggi(_chiaveInviti);
    final codice = _nuovoCodice();
    inviti[codice] = atletaId;
    await _scrivi(_chiaveInviti, inviti);
    return codice;
  }

  Future<AtletiTableData?> _atletaDelCodice(String codice) async {
    final c = _normalizza(codice);
    // I codici "di gruppo" fanno l'altro percorso.
    if (c.contains('GRUPPO')) return null;
    final gruppo = (await _leggi(_chiaveCodiciGruppo))[c];
    if (gruppo != null) return null;
    final atletaId = (await _leggi(_chiaveInviti))[c] as String?;
    if (atletaId != null) {
      return (_db.select(
        _db.atletiTable,
      )..where((t) => t.id.equals(atletaId))).getSingleOrNull();
    }
    final liberi =
        await (_db.select(_db.atletiTable)
              ..where((t) => t.userId.isNull() & t.attivo.equals(true))
              ..orderBy([(t) => OrderingTerm(expression: t.cognome)])
              ..limit(1))
            .get();
    return liberi.isEmpty ? null : liberi.first;
  }

  @override
  Future<AtletaInvitato?> validaCodice(String codice) async {
    final atleta = await _atletaDelCodice(codice);
    return atleta == null ? null : (nome: atleta.nome, cognome: atleta.cognome);
  }

  @override
  Future<Atleta> collegaConCodice(String codice) async {
    final atleta = await _atletaDelCodice(codice);
    if (atleta == null) throw StateError('Codice non valido');
    await (_db.update(_db.atletiTable)..where((t) => t.id.equals(atleta.id)))
        .write(AtletiTableCompanion(userId: Value(_auth.currentUser?.id)));
    final inviti = await _leggi(_chiaveInviti)
      ..remove(_normalizza(codice)); // monouso, come in produzione
    await _scrivi(_chiaveInviti, inviti);
    final aggiornato = await (_db.select(
      _db.atletiTable,
    )..where((t) => t.id.equals(atleta.id))).getSingle();
    return _atletaDaRiga(aggiornato);
  }
}

class CodiciGruppoRepositoryDemo extends CodiciGruppoRepository {
  CodiciGruppoRepositoryDemo(this._db, this._auth)
    : super(Supabase.instance.client);

  final AppDatabase _db;
  final AuthRepositoryDemo _auth;

  @override
  Future<String> generaCodice({
    required String clubId,
    required String gruppoId,
  }) async {
    final codici = await _leggi(_chiaveCodiciGruppo);
    final codice = _nuovoCodice();
    final adesso = DateTime.now();
    codici[codice] = {
      'id': const Uuid().v4(),
      'club_id': clubId,
      'gruppo_id': gruppoId,
      'creato_il': adesso.toIso8601String(),
      'scade_il': adesso.add(const Duration(days: 30)).toIso8601String(),
    };
    await _scrivi(_chiaveCodiciGruppo, codici);
    return codice;
  }

  @override
  Future<List<CodiceGruppo>> elencoPerGruppo(String gruppoId) async {
    final gruppo = await (_db.select(
      _db.gruppiTable,
    )..where((t) => t.id.equals(gruppoId))).getSingleOrNull();
    final codici = await _leggi(_chiaveCodiciGruppo);
    final elenco = [
      for (final MapEntry(key: codice, value: dati) in codici.entries)
        if ((dati as Map<String, dynamic>)['gruppo_id'] == gruppoId)
          CodiceGruppo.fromMap({
            ...dati,
            'codice': codice,
            'gruppi': {'nome': gruppo?.nome ?? ''},
          }),
    ]..sort((a, b) => b.creatoIl.compareTo(a.creatoIl));
    return elenco;
  }

  Future<GruppiTableData?> _gruppoDelCodice(String codice) async {
    final c = _normalizza(codice);
    final dati = (await _leggi(_chiaveCodiciGruppo))[c] as Map?;
    if (dati != null) {
      return (_db.select(_db.gruppiTable)
            ..where((t) => t.id.equals(dati['gruppo_id'] as String)))
          .getSingleOrNull();
    }
    // Arriva qui solo se il percorso "codice personale" non l'ha preso:
    // un codice di gruppo libero, o nessun atleta libero in elenco.
    final gruppi =
        await (_db.select(_db.gruppiTable)
              ..orderBy([(t) => OrderingTerm(expression: t.ordine)])
              ..limit(1))
            .get();
    return gruppi.isEmpty ? null : gruppi.first;
  }

  @override
  Future<GruppoInvitato?> validaCodice(String codice) async {
    final gruppo = await _gruppoDelCodice(codice);
    if (gruppo == null) return null;
    final club = await (_db.select(
      _db.clubTable,
    )..where((t) => t.id.equals(gruppo.clubId))).getSingleOrNull();
    return (
      gruppoNome: gruppo.nome,
      clubNome: club?.nome ?? '',
      gruppoSport: gruppo.sport ?? club?.sport,
    );
  }

  @override
  Future<Atleta> registraConCodice({
    required String codice,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
  }) async {
    final gruppo = await _gruppoDelCodice(codice);
    if (gruppo == null) throw StateError('Codice non valido');
    final id = const Uuid().v4();
    await _db
        .into(_db.atletiTable)
        .insert(
          AtletiTableCompanion.insert(
            id: id,
            clubId: gruppo.clubId,
            nome: nome,
            cognome: cognome,
            dataNascita: dataNascita,
            sesso: Value(sesso),
            sport: sport,
            gruppoId: Value(gruppo.id),
            userId: Value(_auth.currentUser?.id),
          ),
        );
    final riga = await (_db.select(
      _db.atletiTable,
    )..where((t) => t.id.equals(id))).getSingle();
    return _atletaDaRiga(riga);
  }
}
