// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClubTableTable extends ClubTable
    with TableInfo<$ClubTableTable, ClubTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClubTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cittaMeta = const VerificationMeta('citta');
  @override
  late final GeneratedColumn<String> citta = GeneratedColumn<String>(
    'citta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categorieJsonMeta = const VerificationMeta(
    'categorieJson',
  );
  @override
  late final GeneratedColumn<String> categorieJson = GeneratedColumn<String>(
    'categorie_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome, citta, sport, categorieJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'club_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClubTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('citta')) {
      context.handle(
        _cittaMeta,
        citta.isAcceptableOrUnknown(data['citta']!, _cittaMeta),
      );
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    }
    if (data.containsKey('categorie_json')) {
      context.handle(
        _categorieJsonMeta,
        categorieJson.isAcceptableOrUnknown(
          data['categorie_json']!,
          _categorieJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClubTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClubTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      citta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citta'],
      ),
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      ),
      categorieJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categorie_json'],
      )!,
    );
  }

  @override
  $ClubTableTable createAlias(String alias) {
    return $ClubTableTable(attachedDatabase, alias);
  }
}

class ClubTableData extends DataClass implements Insertable<ClubTableData> {
  final String id;
  final String nome;
  final String? citta;
  final String? sport;

  /// Categorie allenate, codificate come lista JSON (es. `["U14","U16"]`):
  /// SQLite non ha un tipo array nativo, stesso schema gia' usato per i
  /// campi lista di `RefertiPartitaTable`.
  final String categorieJson;
  const ClubTableData({
    required this.id,
    required this.nome,
    this.citta,
    this.sport,
    required this.categorieJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || citta != null) {
      map['citta'] = Variable<String>(citta);
    }
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    map['categorie_json'] = Variable<String>(categorieJson);
    return map;
  }

  ClubTableCompanion toCompanion(bool nullToAbsent) {
    return ClubTableCompanion(
      id: Value(id),
      nome: Value(nome),
      citta: citta == null && nullToAbsent
          ? const Value.absent()
          : Value(citta),
      sport: sport == null && nullToAbsent
          ? const Value.absent()
          : Value(sport),
      categorieJson: Value(categorieJson),
    );
  }

  factory ClubTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClubTableData(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      citta: serializer.fromJson<String?>(json['citta']),
      sport: serializer.fromJson<String?>(json['sport']),
      categorieJson: serializer.fromJson<String>(json['categorieJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'citta': serializer.toJson<String?>(citta),
      'sport': serializer.toJson<String?>(sport),
      'categorieJson': serializer.toJson<String>(categorieJson),
    };
  }

  ClubTableData copyWith({
    String? id,
    String? nome,
    Value<String?> citta = const Value.absent(),
    Value<String?> sport = const Value.absent(),
    String? categorieJson,
  }) => ClubTableData(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    citta: citta.present ? citta.value : this.citta,
    sport: sport.present ? sport.value : this.sport,
    categorieJson: categorieJson ?? this.categorieJson,
  );
  ClubTableData copyWithCompanion(ClubTableCompanion data) {
    return ClubTableData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      citta: data.citta.present ? data.citta.value : this.citta,
      sport: data.sport.present ? data.sport.value : this.sport,
      categorieJson: data.categorieJson.present
          ? data.categorieJson.value
          : this.categorieJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClubTableData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('citta: $citta, ')
          ..write('sport: $sport, ')
          ..write('categorieJson: $categorieJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, citta, sport, categorieJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClubTableData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.citta == this.citta &&
          other.sport == this.sport &&
          other.categorieJson == this.categorieJson);
}

class ClubTableCompanion extends UpdateCompanion<ClubTableData> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String?> citta;
  final Value<String?> sport;
  final Value<String> categorieJson;
  final Value<int> rowid;
  const ClubTableCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.citta = const Value.absent(),
    this.sport = const Value.absent(),
    this.categorieJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClubTableCompanion.insert({
    required String id,
    required String nome,
    this.citta = const Value.absent(),
    this.sport = const Value.absent(),
    this.categorieJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome);
  static Insertable<ClubTableData> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? citta,
    Expression<String>? sport,
    Expression<String>? categorieJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (citta != null) 'citta': citta,
      if (sport != null) 'sport': sport,
      if (categorieJson != null) 'categorie_json': categorieJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClubTableCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String?>? citta,
    Value<String?>? sport,
    Value<String>? categorieJson,
    Value<int>? rowid,
  }) {
    return ClubTableCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      citta: citta ?? this.citta,
      sport: sport ?? this.sport,
      categorieJson: categorieJson ?? this.categorieJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (citta.present) {
      map['citta'] = Variable<String>(citta.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (categorieJson.present) {
      map['categorie_json'] = Variable<String>(categorieJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClubTableCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('citta: $citta, ')
          ..write('sport: $sport, ')
          ..write('categorieJson: $categorieJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AtletiTableTable extends AtletiTable
    with TableInfo<$AtletiTableTable, AtletiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtletiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cognomeMeta = const VerificationMeta(
    'cognome',
  );
  @override
  late final GeneratedColumn<String> cognome = GeneratedColumn<String>(
    'cognome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataNascitaMeta = const VerificationMeta(
    'dataNascita',
  );
  @override
  late final GeneratedColumn<DateTime> dataNascita = GeneratedColumn<DateTime>(
    'data_nascita',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessoMeta = const VerificationMeta('sesso');
  @override
  late final GeneratedColumn<String> sesso = GeneratedColumn<String>(
    'sesso',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gruppoIdMeta = const VerificationMeta(
    'gruppoId',
  );
  @override
  late final GeneratedColumn<String> gruppoId = GeneratedColumn<String>(
    'gruppo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailGenitoreMeta = const VerificationMeta(
    'emailGenitore',
  );
  @override
  late final GeneratedColumn<String> emailGenitore = GeneratedColumn<String>(
    'email_genitore',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoGenitoreMeta = const VerificationMeta(
    'telefonoGenitore',
  );
  @override
  late final GeneratedColumn<String> telefonoGenitore = GeneratedColumn<String>(
    'telefono_genitore',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consensoPrivacyFirmatoMeta =
      const VerificationMeta('consensoPrivacyFirmato');
  @override
  late final GeneratedColumn<bool> consensoPrivacyFirmato =
      GeneratedColumn<bool>(
        'consenso_privacy_firmato',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("consenso_privacy_firmato" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _consensoPrivacyDataMeta =
      const VerificationMeta('consensoPrivacyData');
  @override
  late final GeneratedColumn<DateTime> consensoPrivacyData =
      GeneratedColumn<DateTime>(
        'consenso_privacy_data',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attivoMeta = const VerificationMeta('attivo');
  @override
  late final GeneratedColumn<bool> attivo = GeneratedColumn<bool>(
    'attivo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("attivo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _numeroTesseraFinMeta = const VerificationMeta(
    'numeroTesseraFin',
  );
  @override
  late final GeneratedColumn<String> numeroTesseraFin = GeneratedColumn<String>(
    'numero_tessera_fin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitaMedicaScadenzaMeta =
      const VerificationMeta('visitaMedicaScadenza');
  @override
  late final GeneratedColumn<DateTime> visitaMedicaScadenza =
      GeneratedColumn<DateTime>(
        'visita_medica_scadenza',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    nome,
    cognome,
    dataNascita,
    sesso,
    sport,
    gruppoId,
    emailGenitore,
    telefonoGenitore,
    consensoPrivacyFirmato,
    consensoPrivacyData,
    note,
    attivo,
    numeroTesseraFin,
    userId,
    visitaMedicaScadenza,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atleti_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtletiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cognome')) {
      context.handle(
        _cognomeMeta,
        cognome.isAcceptableOrUnknown(data['cognome']!, _cognomeMeta),
      );
    } else if (isInserting) {
      context.missing(_cognomeMeta);
    }
    if (data.containsKey('data_nascita')) {
      context.handle(
        _dataNascitaMeta,
        dataNascita.isAcceptableOrUnknown(
          data['data_nascita']!,
          _dataNascitaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataNascitaMeta);
    }
    if (data.containsKey('sesso')) {
      context.handle(
        _sessoMeta,
        sesso.isAcceptableOrUnknown(data['sesso']!, _sessoMeta),
      );
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    } else if (isInserting) {
      context.missing(_sportMeta);
    }
    if (data.containsKey('gruppo_id')) {
      context.handle(
        _gruppoIdMeta,
        gruppoId.isAcceptableOrUnknown(data['gruppo_id']!, _gruppoIdMeta),
      );
    }
    if (data.containsKey('email_genitore')) {
      context.handle(
        _emailGenitoreMeta,
        emailGenitore.isAcceptableOrUnknown(
          data['email_genitore']!,
          _emailGenitoreMeta,
        ),
      );
    }
    if (data.containsKey('telefono_genitore')) {
      context.handle(
        _telefonoGenitoreMeta,
        telefonoGenitore.isAcceptableOrUnknown(
          data['telefono_genitore']!,
          _telefonoGenitoreMeta,
        ),
      );
    }
    if (data.containsKey('consenso_privacy_firmato')) {
      context.handle(
        _consensoPrivacyFirmatoMeta,
        consensoPrivacyFirmato.isAcceptableOrUnknown(
          data['consenso_privacy_firmato']!,
          _consensoPrivacyFirmatoMeta,
        ),
      );
    }
    if (data.containsKey('consenso_privacy_data')) {
      context.handle(
        _consensoPrivacyDataMeta,
        consensoPrivacyData.isAcceptableOrUnknown(
          data['consenso_privacy_data']!,
          _consensoPrivacyDataMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('attivo')) {
      context.handle(
        _attivoMeta,
        attivo.isAcceptableOrUnknown(data['attivo']!, _attivoMeta),
      );
    }
    if (data.containsKey('numero_tessera_fin')) {
      context.handle(
        _numeroTesseraFinMeta,
        numeroTesseraFin.isAcceptableOrUnknown(
          data['numero_tessera_fin']!,
          _numeroTesseraFinMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('visita_medica_scadenza')) {
      context.handle(
        _visitaMedicaScadenzaMeta,
        visitaMedicaScadenza.isAcceptableOrUnknown(
          data['visita_medica_scadenza']!,
          _visitaMedicaScadenzaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AtletiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtletiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      cognome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cognome'],
      )!,
      dataNascita: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_nascita'],
      )!,
      sesso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sesso'],
      ),
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      )!,
      gruppoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_id'],
      ),
      emailGenitore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_genitore'],
      ),
      telefonoGenitore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono_genitore'],
      ),
      consensoPrivacyFirmato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consenso_privacy_firmato'],
      )!,
      consensoPrivacyData: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consenso_privacy_data'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      attivo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}attivo'],
      )!,
      numeroTesseraFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_tessera_fin'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      visitaMedicaScadenza: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visita_medica_scadenza'],
      ),
    );
  }

  @override
  $AtletiTableTable createAlias(String alias) {
    return $AtletiTableTable(attachedDatabase, alias);
  }
}

class AtletiTableData extends DataClass implements Insertable<AtletiTableData> {
  final String id;
  final String clubId;
  final String nome;
  final String cognome;
  final DateTime dataNascita;
  final String? sesso;
  final String sport;
  final String? gruppoId;
  final String? emailGenitore;
  final String? telefonoGenitore;
  final bool consensoPrivacyFirmato;
  final DateTime? consensoPrivacyData;
  final String? note;
  final bool attivo;
  final String? numeroTesseraFin;
  final String? userId;
  final DateTime? visitaMedicaScadenza;
  const AtletiTableData({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.cognome,
    required this.dataNascita,
    this.sesso,
    required this.sport,
    this.gruppoId,
    this.emailGenitore,
    this.telefonoGenitore,
    required this.consensoPrivacyFirmato,
    this.consensoPrivacyData,
    this.note,
    required this.attivo,
    this.numeroTesseraFin,
    this.userId,
    this.visitaMedicaScadenza,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['nome'] = Variable<String>(nome);
    map['cognome'] = Variable<String>(cognome);
    map['data_nascita'] = Variable<DateTime>(dataNascita);
    if (!nullToAbsent || sesso != null) {
      map['sesso'] = Variable<String>(sesso);
    }
    map['sport'] = Variable<String>(sport);
    if (!nullToAbsent || gruppoId != null) {
      map['gruppo_id'] = Variable<String>(gruppoId);
    }
    if (!nullToAbsent || emailGenitore != null) {
      map['email_genitore'] = Variable<String>(emailGenitore);
    }
    if (!nullToAbsent || telefonoGenitore != null) {
      map['telefono_genitore'] = Variable<String>(telefonoGenitore);
    }
    map['consenso_privacy_firmato'] = Variable<bool>(consensoPrivacyFirmato);
    if (!nullToAbsent || consensoPrivacyData != null) {
      map['consenso_privacy_data'] = Variable<DateTime>(consensoPrivacyData);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['attivo'] = Variable<bool>(attivo);
    if (!nullToAbsent || numeroTesseraFin != null) {
      map['numero_tessera_fin'] = Variable<String>(numeroTesseraFin);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || visitaMedicaScadenza != null) {
      map['visita_medica_scadenza'] = Variable<DateTime>(visitaMedicaScadenza);
    }
    return map;
  }

  AtletiTableCompanion toCompanion(bool nullToAbsent) {
    return AtletiTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      nome: Value(nome),
      cognome: Value(cognome),
      dataNascita: Value(dataNascita),
      sesso: sesso == null && nullToAbsent
          ? const Value.absent()
          : Value(sesso),
      sport: Value(sport),
      gruppoId: gruppoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppoId),
      emailGenitore: emailGenitore == null && nullToAbsent
          ? const Value.absent()
          : Value(emailGenitore),
      telefonoGenitore: telefonoGenitore == null && nullToAbsent
          ? const Value.absent()
          : Value(telefonoGenitore),
      consensoPrivacyFirmato: Value(consensoPrivacyFirmato),
      consensoPrivacyData: consensoPrivacyData == null && nullToAbsent
          ? const Value.absent()
          : Value(consensoPrivacyData),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      attivo: Value(attivo),
      numeroTesseraFin: numeroTesseraFin == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroTesseraFin),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      visitaMedicaScadenza: visitaMedicaScadenza == null && nullToAbsent
          ? const Value.absent()
          : Value(visitaMedicaScadenza),
    );
  }

  factory AtletiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtletiTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      nome: serializer.fromJson<String>(json['nome']),
      cognome: serializer.fromJson<String>(json['cognome']),
      dataNascita: serializer.fromJson<DateTime>(json['dataNascita']),
      sesso: serializer.fromJson<String?>(json['sesso']),
      sport: serializer.fromJson<String>(json['sport']),
      gruppoId: serializer.fromJson<String?>(json['gruppoId']),
      emailGenitore: serializer.fromJson<String?>(json['emailGenitore']),
      telefonoGenitore: serializer.fromJson<String?>(json['telefonoGenitore']),
      consensoPrivacyFirmato: serializer.fromJson<bool>(
        json['consensoPrivacyFirmato'],
      ),
      consensoPrivacyData: serializer.fromJson<DateTime?>(
        json['consensoPrivacyData'],
      ),
      note: serializer.fromJson<String?>(json['note']),
      attivo: serializer.fromJson<bool>(json['attivo']),
      numeroTesseraFin: serializer.fromJson<String?>(json['numeroTesseraFin']),
      userId: serializer.fromJson<String?>(json['userId']),
      visitaMedicaScadenza: serializer.fromJson<DateTime?>(
        json['visitaMedicaScadenza'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'nome': serializer.toJson<String>(nome),
      'cognome': serializer.toJson<String>(cognome),
      'dataNascita': serializer.toJson<DateTime>(dataNascita),
      'sesso': serializer.toJson<String?>(sesso),
      'sport': serializer.toJson<String>(sport),
      'gruppoId': serializer.toJson<String?>(gruppoId),
      'emailGenitore': serializer.toJson<String?>(emailGenitore),
      'telefonoGenitore': serializer.toJson<String?>(telefonoGenitore),
      'consensoPrivacyFirmato': serializer.toJson<bool>(consensoPrivacyFirmato),
      'consensoPrivacyData': serializer.toJson<DateTime?>(consensoPrivacyData),
      'note': serializer.toJson<String?>(note),
      'attivo': serializer.toJson<bool>(attivo),
      'numeroTesseraFin': serializer.toJson<String?>(numeroTesseraFin),
      'userId': serializer.toJson<String?>(userId),
      'visitaMedicaScadenza': serializer.toJson<DateTime?>(
        visitaMedicaScadenza,
      ),
    };
  }

  AtletiTableData copyWith({
    String? id,
    String? clubId,
    String? nome,
    String? cognome,
    DateTime? dataNascita,
    Value<String?> sesso = const Value.absent(),
    String? sport,
    Value<String?> gruppoId = const Value.absent(),
    Value<String?> emailGenitore = const Value.absent(),
    Value<String?> telefonoGenitore = const Value.absent(),
    bool? consensoPrivacyFirmato,
    Value<DateTime?> consensoPrivacyData = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? attivo,
    Value<String?> numeroTesseraFin = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    Value<DateTime?> visitaMedicaScadenza = const Value.absent(),
  }) => AtletiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    nome: nome ?? this.nome,
    cognome: cognome ?? this.cognome,
    dataNascita: dataNascita ?? this.dataNascita,
    sesso: sesso.present ? sesso.value : this.sesso,
    sport: sport ?? this.sport,
    gruppoId: gruppoId.present ? gruppoId.value : this.gruppoId,
    emailGenitore: emailGenitore.present
        ? emailGenitore.value
        : this.emailGenitore,
    telefonoGenitore: telefonoGenitore.present
        ? telefonoGenitore.value
        : this.telefonoGenitore,
    consensoPrivacyFirmato:
        consensoPrivacyFirmato ?? this.consensoPrivacyFirmato,
    consensoPrivacyData: consensoPrivacyData.present
        ? consensoPrivacyData.value
        : this.consensoPrivacyData,
    note: note.present ? note.value : this.note,
    attivo: attivo ?? this.attivo,
    numeroTesseraFin: numeroTesseraFin.present
        ? numeroTesseraFin.value
        : this.numeroTesseraFin,
    userId: userId.present ? userId.value : this.userId,
    visitaMedicaScadenza: visitaMedicaScadenza.present
        ? visitaMedicaScadenza.value
        : this.visitaMedicaScadenza,
  );
  AtletiTableData copyWithCompanion(AtletiTableCompanion data) {
    return AtletiTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      nome: data.nome.present ? data.nome.value : this.nome,
      cognome: data.cognome.present ? data.cognome.value : this.cognome,
      dataNascita: data.dataNascita.present
          ? data.dataNascita.value
          : this.dataNascita,
      sesso: data.sesso.present ? data.sesso.value : this.sesso,
      sport: data.sport.present ? data.sport.value : this.sport,
      gruppoId: data.gruppoId.present ? data.gruppoId.value : this.gruppoId,
      emailGenitore: data.emailGenitore.present
          ? data.emailGenitore.value
          : this.emailGenitore,
      telefonoGenitore: data.telefonoGenitore.present
          ? data.telefonoGenitore.value
          : this.telefonoGenitore,
      consensoPrivacyFirmato: data.consensoPrivacyFirmato.present
          ? data.consensoPrivacyFirmato.value
          : this.consensoPrivacyFirmato,
      consensoPrivacyData: data.consensoPrivacyData.present
          ? data.consensoPrivacyData.value
          : this.consensoPrivacyData,
      note: data.note.present ? data.note.value : this.note,
      attivo: data.attivo.present ? data.attivo.value : this.attivo,
      numeroTesseraFin: data.numeroTesseraFin.present
          ? data.numeroTesseraFin.value
          : this.numeroTesseraFin,
      userId: data.userId.present ? data.userId.value : this.userId,
      visitaMedicaScadenza: data.visitaMedicaScadenza.present
          ? data.visitaMedicaScadenza.value
          : this.visitaMedicaScadenza,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtletiTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('cognome: $cognome, ')
          ..write('dataNascita: $dataNascita, ')
          ..write('sesso: $sesso, ')
          ..write('sport: $sport, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('emailGenitore: $emailGenitore, ')
          ..write('telefonoGenitore: $telefonoGenitore, ')
          ..write('consensoPrivacyFirmato: $consensoPrivacyFirmato, ')
          ..write('consensoPrivacyData: $consensoPrivacyData, ')
          ..write('note: $note, ')
          ..write('attivo: $attivo, ')
          ..write('numeroTesseraFin: $numeroTesseraFin, ')
          ..write('userId: $userId, ')
          ..write('visitaMedicaScadenza: $visitaMedicaScadenza')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    nome,
    cognome,
    dataNascita,
    sesso,
    sport,
    gruppoId,
    emailGenitore,
    telefonoGenitore,
    consensoPrivacyFirmato,
    consensoPrivacyData,
    note,
    attivo,
    numeroTesseraFin,
    userId,
    visitaMedicaScadenza,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtletiTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.nome == this.nome &&
          other.cognome == this.cognome &&
          other.dataNascita == this.dataNascita &&
          other.sesso == this.sesso &&
          other.sport == this.sport &&
          other.gruppoId == this.gruppoId &&
          other.emailGenitore == this.emailGenitore &&
          other.telefonoGenitore == this.telefonoGenitore &&
          other.consensoPrivacyFirmato == this.consensoPrivacyFirmato &&
          other.consensoPrivacyData == this.consensoPrivacyData &&
          other.note == this.note &&
          other.attivo == this.attivo &&
          other.numeroTesseraFin == this.numeroTesseraFin &&
          other.userId == this.userId &&
          other.visitaMedicaScadenza == this.visitaMedicaScadenza);
}

class AtletiTableCompanion extends UpdateCompanion<AtletiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> nome;
  final Value<String> cognome;
  final Value<DateTime> dataNascita;
  final Value<String?> sesso;
  final Value<String> sport;
  final Value<String?> gruppoId;
  final Value<String?> emailGenitore;
  final Value<String?> telefonoGenitore;
  final Value<bool> consensoPrivacyFirmato;
  final Value<DateTime?> consensoPrivacyData;
  final Value<String?> note;
  final Value<bool> attivo;
  final Value<String?> numeroTesseraFin;
  final Value<String?> userId;
  final Value<DateTime?> visitaMedicaScadenza;
  final Value<int> rowid;
  const AtletiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.nome = const Value.absent(),
    this.cognome = const Value.absent(),
    this.dataNascita = const Value.absent(),
    this.sesso = const Value.absent(),
    this.sport = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.emailGenitore = const Value.absent(),
    this.telefonoGenitore = const Value.absent(),
    this.consensoPrivacyFirmato = const Value.absent(),
    this.consensoPrivacyData = const Value.absent(),
    this.note = const Value.absent(),
    this.attivo = const Value.absent(),
    this.numeroTesseraFin = const Value.absent(),
    this.userId = const Value.absent(),
    this.visitaMedicaScadenza = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtletiTableCompanion.insert({
    required String id,
    required String clubId,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    this.sesso = const Value.absent(),
    required String sport,
    this.gruppoId = const Value.absent(),
    this.emailGenitore = const Value.absent(),
    this.telefonoGenitore = const Value.absent(),
    this.consensoPrivacyFirmato = const Value.absent(),
    this.consensoPrivacyData = const Value.absent(),
    this.note = const Value.absent(),
    this.attivo = const Value.absent(),
    this.numeroTesseraFin = const Value.absent(),
    this.userId = const Value.absent(),
    this.visitaMedicaScadenza = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       nome = Value(nome),
       cognome = Value(cognome),
       dataNascita = Value(dataNascita),
       sport = Value(sport);
  static Insertable<AtletiTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? nome,
    Expression<String>? cognome,
    Expression<DateTime>? dataNascita,
    Expression<String>? sesso,
    Expression<String>? sport,
    Expression<String>? gruppoId,
    Expression<String>? emailGenitore,
    Expression<String>? telefonoGenitore,
    Expression<bool>? consensoPrivacyFirmato,
    Expression<DateTime>? consensoPrivacyData,
    Expression<String>? note,
    Expression<bool>? attivo,
    Expression<String>? numeroTesseraFin,
    Expression<String>? userId,
    Expression<DateTime>? visitaMedicaScadenza,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (nome != null) 'nome': nome,
      if (cognome != null) 'cognome': cognome,
      if (dataNascita != null) 'data_nascita': dataNascita,
      if (sesso != null) 'sesso': sesso,
      if (sport != null) 'sport': sport,
      if (gruppoId != null) 'gruppo_id': gruppoId,
      if (emailGenitore != null) 'email_genitore': emailGenitore,
      if (telefonoGenitore != null) 'telefono_genitore': telefonoGenitore,
      if (consensoPrivacyFirmato != null)
        'consenso_privacy_firmato': consensoPrivacyFirmato,
      if (consensoPrivacyData != null)
        'consenso_privacy_data': consensoPrivacyData,
      if (note != null) 'note': note,
      if (attivo != null) 'attivo': attivo,
      if (numeroTesseraFin != null) 'numero_tessera_fin': numeroTesseraFin,
      if (userId != null) 'user_id': userId,
      if (visitaMedicaScadenza != null)
        'visita_medica_scadenza': visitaMedicaScadenza,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtletiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String>? nome,
    Value<String>? cognome,
    Value<DateTime>? dataNascita,
    Value<String?>? sesso,
    Value<String>? sport,
    Value<String?>? gruppoId,
    Value<String?>? emailGenitore,
    Value<String?>? telefonoGenitore,
    Value<bool>? consensoPrivacyFirmato,
    Value<DateTime?>? consensoPrivacyData,
    Value<String?>? note,
    Value<bool>? attivo,
    Value<String?>? numeroTesseraFin,
    Value<String?>? userId,
    Value<DateTime?>? visitaMedicaScadenza,
    Value<int>? rowid,
  }) {
    return AtletiTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      dataNascita: dataNascita ?? this.dataNascita,
      sesso: sesso ?? this.sesso,
      sport: sport ?? this.sport,
      gruppoId: gruppoId ?? this.gruppoId,
      emailGenitore: emailGenitore ?? this.emailGenitore,
      telefonoGenitore: telefonoGenitore ?? this.telefonoGenitore,
      consensoPrivacyFirmato:
          consensoPrivacyFirmato ?? this.consensoPrivacyFirmato,
      consensoPrivacyData: consensoPrivacyData ?? this.consensoPrivacyData,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
      numeroTesseraFin: numeroTesseraFin ?? this.numeroTesseraFin,
      userId: userId ?? this.userId,
      visitaMedicaScadenza: visitaMedicaScadenza ?? this.visitaMedicaScadenza,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cognome.present) {
      map['cognome'] = Variable<String>(cognome.value);
    }
    if (dataNascita.present) {
      map['data_nascita'] = Variable<DateTime>(dataNascita.value);
    }
    if (sesso.present) {
      map['sesso'] = Variable<String>(sesso.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (gruppoId.present) {
      map['gruppo_id'] = Variable<String>(gruppoId.value);
    }
    if (emailGenitore.present) {
      map['email_genitore'] = Variable<String>(emailGenitore.value);
    }
    if (telefonoGenitore.present) {
      map['telefono_genitore'] = Variable<String>(telefonoGenitore.value);
    }
    if (consensoPrivacyFirmato.present) {
      map['consenso_privacy_firmato'] = Variable<bool>(
        consensoPrivacyFirmato.value,
      );
    }
    if (consensoPrivacyData.present) {
      map['consenso_privacy_data'] = Variable<DateTime>(
        consensoPrivacyData.value,
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (attivo.present) {
      map['attivo'] = Variable<bool>(attivo.value);
    }
    if (numeroTesseraFin.present) {
      map['numero_tessera_fin'] = Variable<String>(numeroTesseraFin.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (visitaMedicaScadenza.present) {
      map['visita_medica_scadenza'] = Variable<DateTime>(
        visitaMedicaScadenza.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtletiTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('cognome: $cognome, ')
          ..write('dataNascita: $dataNascita, ')
          ..write('sesso: $sesso, ')
          ..write('sport: $sport, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('emailGenitore: $emailGenitore, ')
          ..write('telefonoGenitore: $telefonoGenitore, ')
          ..write('consensoPrivacyFirmato: $consensoPrivacyFirmato, ')
          ..write('consensoPrivacyData: $consensoPrivacyData, ')
          ..write('note: $note, ')
          ..write('attivo: $attivo, ')
          ..write('numeroTesseraFin: $numeroTesseraFin, ')
          ..write('userId: $userId, ')
          ..write('visitaMedicaScadenza: $visitaMedicaScadenza, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalBestTableTable extends PersonalBestTable
    with TableInfo<$PersonalBestTableTable, PersonalBestTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalBestTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stileMeta = const VerificationMeta('stile');
  @override
  late final GeneratedColumn<String> stile = GeneratedColumn<String>(
    'stile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanzaMMeta = const VerificationMeta(
    'distanzaM',
  );
  @override
  late final GeneratedColumn<int> distanzaM = GeneratedColumn<int>(
    'distanza_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempoSMeta = const VerificationMeta('tempoS');
  @override
  late final GeneratedColumn<double> tempoS = GeneratedColumn<double>(
    'tempo_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    atletaId,
    clubId,
    stile,
    distanzaM,
    tempoS,
    data,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_best_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalBestTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('stile')) {
      context.handle(
        _stileMeta,
        stile.isAcceptableOrUnknown(data['stile']!, _stileMeta),
      );
    } else if (isInserting) {
      context.missing(_stileMeta);
    }
    if (data.containsKey('distanza_m')) {
      context.handle(
        _distanzaMMeta,
        distanzaM.isAcceptableOrUnknown(data['distanza_m']!, _distanzaMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanzaMMeta);
    }
    if (data.containsKey('tempo_s')) {
      context.handle(
        _tempoSMeta,
        tempoS.isAcceptableOrUnknown(data['tempo_s']!, _tempoSMeta),
      );
    } else if (isInserting) {
      context.missing(_tempoSMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalBestTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalBestTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      stile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stile'],
      )!,
      distanzaM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distanza_m'],
      )!,
      tempoS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tempo_s'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PersonalBestTableTable createAlias(String alias) {
    return $PersonalBestTableTable(attachedDatabase, alias);
  }
}

class PersonalBestTableData extends DataClass
    implements Insertable<PersonalBestTableData> {
  final String id;
  final String atletaId;
  final String clubId;
  final String stile;
  final int distanzaM;
  final double tempoS;
  final DateTime? data;
  final String? note;
  const PersonalBestTableData({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.stile,
    required this.distanzaM,
    required this.tempoS,
    this.data,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['stile'] = Variable<String>(stile);
    map['distanza_m'] = Variable<int>(distanzaM);
    map['tempo_s'] = Variable<double>(tempoS);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<DateTime>(data);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PersonalBestTableCompanion toCompanion(bool nullToAbsent) {
    return PersonalBestTableCompanion(
      id: Value(id),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      stile: Value(stile),
      distanzaM: Value(distanzaM),
      tempoS: Value(tempoS),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PersonalBestTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalBestTableData(
      id: serializer.fromJson<String>(json['id']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      stile: serializer.fromJson<String>(json['stile']),
      distanzaM: serializer.fromJson<int>(json['distanzaM']),
      tempoS: serializer.fromJson<double>(json['tempoS']),
      data: serializer.fromJson<DateTime?>(json['data']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'stile': serializer.toJson<String>(stile),
      'distanzaM': serializer.toJson<int>(distanzaM),
      'tempoS': serializer.toJson<double>(tempoS),
      'data': serializer.toJson<DateTime?>(data),
      'note': serializer.toJson<String?>(note),
    };
  }

  PersonalBestTableData copyWith({
    String? id,
    String? atletaId,
    String? clubId,
    String? stile,
    int? distanzaM,
    double? tempoS,
    Value<DateTime?> data = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => PersonalBestTableData(
    id: id ?? this.id,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    stile: stile ?? this.stile,
    distanzaM: distanzaM ?? this.distanzaM,
    tempoS: tempoS ?? this.tempoS,
    data: data.present ? data.value : this.data,
    note: note.present ? note.value : this.note,
  );
  PersonalBestTableData copyWithCompanion(PersonalBestTableCompanion data) {
    return PersonalBestTableData(
      id: data.id.present ? data.id.value : this.id,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      stile: data.stile.present ? data.stile.value : this.stile,
      distanzaM: data.distanzaM.present ? data.distanzaM.value : this.distanzaM,
      tempoS: data.tempoS.present ? data.tempoS.value : this.tempoS,
      data: data.data.present ? data.data.value : this.data,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalBestTableData(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stile: $stile, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('tempoS: $tempoS, ')
          ..write('data: $data, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, atletaId, clubId, stile, distanzaM, tempoS, data, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalBestTableData &&
          other.id == this.id &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.stile == this.stile &&
          other.distanzaM == this.distanzaM &&
          other.tempoS == this.tempoS &&
          other.data == this.data &&
          other.note == this.note);
}

class PersonalBestTableCompanion
    extends UpdateCompanion<PersonalBestTableData> {
  final Value<String> id;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<String> stile;
  final Value<int> distanzaM;
  final Value<double> tempoS;
  final Value<DateTime?> data;
  final Value<String?> note;
  final Value<int> rowid;
  const PersonalBestTableCompanion({
    this.id = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.stile = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.tempoS = const Value.absent(),
    this.data = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalBestTableCompanion.insert({
    required String id,
    required String atletaId,
    required String clubId,
    required String stile,
    required int distanzaM,
    required double tempoS,
    this.data = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       stile = Value(stile),
       distanzaM = Value(distanzaM),
       tempoS = Value(tempoS);
  static Insertable<PersonalBestTableData> custom({
    Expression<String>? id,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<String>? stile,
    Expression<int>? distanzaM,
    Expression<double>? tempoS,
    Expression<DateTime>? data,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (stile != null) 'stile': stile,
      if (distanzaM != null) 'distanza_m': distanzaM,
      if (tempoS != null) 'tempo_s': tempoS,
      if (data != null) 'data': data,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalBestTableCompanion copyWith({
    Value<String>? id,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<String>? stile,
    Value<int>? distanzaM,
    Value<double>? tempoS,
    Value<DateTime?>? data,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PersonalBestTableCompanion(
      id: id ?? this.id,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      stile: stile ?? this.stile,
      distanzaM: distanzaM ?? this.distanzaM,
      tempoS: tempoS ?? this.tempoS,
      data: data ?? this.data,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (stile.present) {
      map['stile'] = Variable<String>(stile.value);
    }
    if (distanzaM.present) {
      map['distanza_m'] = Variable<int>(distanzaM.value);
    }
    if (tempoS.present) {
      map['tempo_s'] = Variable<double>(tempoS.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalBestTableCompanion(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stile: $stile, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('tempoS: $tempoS, ')
          ..write('data: $data, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TempiGaraTableTable extends TempiGaraTable
    with TableInfo<$TempiGaraTableTable, TempiGaraTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TempiGaraTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stileMeta = const VerificationMeta('stile');
  @override
  late final GeneratedColumn<String> stile = GeneratedColumn<String>(
    'stile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanzaMMeta = const VerificationMeta(
    'distanzaM',
  );
  @override
  late final GeneratedColumn<int> distanzaM = GeneratedColumn<int>(
    'distanza_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vascaMMeta = const VerificationMeta('vascaM');
  @override
  late final GeneratedColumn<int> vascaM = GeneratedColumn<int>(
    'vasca_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempoSMeta = const VerificationMeta('tempoS');
  @override
  late final GeneratedColumn<double> tempoS = GeneratedColumn<double>(
    'tempo_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _garaIdMeta = const VerificationMeta('garaId');
  @override
  late final GeneratedColumn<String> garaId = GeneratedColumn<String>(
    'gara_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    atletaId,
    clubId,
    stile,
    distanzaM,
    vascaM,
    tempoS,
    data,
    note,
    garaId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tempi_gara_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TempiGaraTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('stile')) {
      context.handle(
        _stileMeta,
        stile.isAcceptableOrUnknown(data['stile']!, _stileMeta),
      );
    } else if (isInserting) {
      context.missing(_stileMeta);
    }
    if (data.containsKey('distanza_m')) {
      context.handle(
        _distanzaMMeta,
        distanzaM.isAcceptableOrUnknown(data['distanza_m']!, _distanzaMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanzaMMeta);
    }
    if (data.containsKey('vasca_m')) {
      context.handle(
        _vascaMMeta,
        vascaM.isAcceptableOrUnknown(data['vasca_m']!, _vascaMMeta),
      );
    } else if (isInserting) {
      context.missing(_vascaMMeta);
    }
    if (data.containsKey('tempo_s')) {
      context.handle(
        _tempoSMeta,
        tempoS.isAcceptableOrUnknown(data['tempo_s']!, _tempoSMeta),
      );
    } else if (isInserting) {
      context.missing(_tempoSMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('gara_id')) {
      context.handle(
        _garaIdMeta,
        garaId.isAcceptableOrUnknown(data['gara_id']!, _garaIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TempiGaraTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TempiGaraTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      stile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stile'],
      )!,
      distanzaM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distanza_m'],
      )!,
      vascaM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vasca_m'],
      )!,
      tempoS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tempo_s'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      garaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gara_id'],
      ),
    );
  }

  @override
  $TempiGaraTableTable createAlias(String alias) {
    return $TempiGaraTableTable(attachedDatabase, alias);
  }
}

class TempiGaraTableData extends DataClass
    implements Insertable<TempiGaraTableData> {
  final String id;
  final String atletaId;
  final String clubId;
  final String stile;
  final int distanzaM;
  final int vascaM;
  final double tempoS;
  final DateTime data;
  final String? note;

  /// Gara in cui e' stato nuotato (null = tempo inserito a mano).
  final String? garaId;
  const TempiGaraTableData({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.stile,
    required this.distanzaM,
    required this.vascaM,
    required this.tempoS,
    required this.data,
    this.note,
    this.garaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['stile'] = Variable<String>(stile);
    map['distanza_m'] = Variable<int>(distanzaM);
    map['vasca_m'] = Variable<int>(vascaM);
    map['tempo_s'] = Variable<double>(tempoS);
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || garaId != null) {
      map['gara_id'] = Variable<String>(garaId);
    }
    return map;
  }

  TempiGaraTableCompanion toCompanion(bool nullToAbsent) {
    return TempiGaraTableCompanion(
      id: Value(id),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      stile: Value(stile),
      distanzaM: Value(distanzaM),
      vascaM: Value(vascaM),
      tempoS: Value(tempoS),
      data: Value(data),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      garaId: garaId == null && nullToAbsent
          ? const Value.absent()
          : Value(garaId),
    );
  }

  factory TempiGaraTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TempiGaraTableData(
      id: serializer.fromJson<String>(json['id']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      stile: serializer.fromJson<String>(json['stile']),
      distanzaM: serializer.fromJson<int>(json['distanzaM']),
      vascaM: serializer.fromJson<int>(json['vascaM']),
      tempoS: serializer.fromJson<double>(json['tempoS']),
      data: serializer.fromJson<DateTime>(json['data']),
      note: serializer.fromJson<String?>(json['note']),
      garaId: serializer.fromJson<String?>(json['garaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'stile': serializer.toJson<String>(stile),
      'distanzaM': serializer.toJson<int>(distanzaM),
      'vascaM': serializer.toJson<int>(vascaM),
      'tempoS': serializer.toJson<double>(tempoS),
      'data': serializer.toJson<DateTime>(data),
      'note': serializer.toJson<String?>(note),
      'garaId': serializer.toJson<String?>(garaId),
    };
  }

  TempiGaraTableData copyWith({
    String? id,
    String? atletaId,
    String? clubId,
    String? stile,
    int? distanzaM,
    int? vascaM,
    double? tempoS,
    DateTime? data,
    Value<String?> note = const Value.absent(),
    Value<String?> garaId = const Value.absent(),
  }) => TempiGaraTableData(
    id: id ?? this.id,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    stile: stile ?? this.stile,
    distanzaM: distanzaM ?? this.distanzaM,
    vascaM: vascaM ?? this.vascaM,
    tempoS: tempoS ?? this.tempoS,
    data: data ?? this.data,
    note: note.present ? note.value : this.note,
    garaId: garaId.present ? garaId.value : this.garaId,
  );
  TempiGaraTableData copyWithCompanion(TempiGaraTableCompanion data) {
    return TempiGaraTableData(
      id: data.id.present ? data.id.value : this.id,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      stile: data.stile.present ? data.stile.value : this.stile,
      distanzaM: data.distanzaM.present ? data.distanzaM.value : this.distanzaM,
      vascaM: data.vascaM.present ? data.vascaM.value : this.vascaM,
      tempoS: data.tempoS.present ? data.tempoS.value : this.tempoS,
      data: data.data.present ? data.data.value : this.data,
      note: data.note.present ? data.note.value : this.note,
      garaId: data.garaId.present ? data.garaId.value : this.garaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TempiGaraTableData(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stile: $stile, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('vascaM: $vascaM, ')
          ..write('tempoS: $tempoS, ')
          ..write('data: $data, ')
          ..write('note: $note, ')
          ..write('garaId: $garaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    atletaId,
    clubId,
    stile,
    distanzaM,
    vascaM,
    tempoS,
    data,
    note,
    garaId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TempiGaraTableData &&
          other.id == this.id &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.stile == this.stile &&
          other.distanzaM == this.distanzaM &&
          other.vascaM == this.vascaM &&
          other.tempoS == this.tempoS &&
          other.data == this.data &&
          other.note == this.note &&
          other.garaId == this.garaId);
}

class TempiGaraTableCompanion extends UpdateCompanion<TempiGaraTableData> {
  final Value<String> id;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<String> stile;
  final Value<int> distanzaM;
  final Value<int> vascaM;
  final Value<double> tempoS;
  final Value<DateTime> data;
  final Value<String?> note;
  final Value<String?> garaId;
  final Value<int> rowid;
  const TempiGaraTableCompanion({
    this.id = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.stile = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.vascaM = const Value.absent(),
    this.tempoS = const Value.absent(),
    this.data = const Value.absent(),
    this.note = const Value.absent(),
    this.garaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TempiGaraTableCompanion.insert({
    required String id,
    required String atletaId,
    required String clubId,
    required String stile,
    required int distanzaM,
    required int vascaM,
    required double tempoS,
    required DateTime data,
    this.note = const Value.absent(),
    this.garaId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       stile = Value(stile),
       distanzaM = Value(distanzaM),
       vascaM = Value(vascaM),
       tempoS = Value(tempoS),
       data = Value(data);
  static Insertable<TempiGaraTableData> custom({
    Expression<String>? id,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<String>? stile,
    Expression<int>? distanzaM,
    Expression<int>? vascaM,
    Expression<double>? tempoS,
    Expression<DateTime>? data,
    Expression<String>? note,
    Expression<String>? garaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (stile != null) 'stile': stile,
      if (distanzaM != null) 'distanza_m': distanzaM,
      if (vascaM != null) 'vasca_m': vascaM,
      if (tempoS != null) 'tempo_s': tempoS,
      if (data != null) 'data': data,
      if (note != null) 'note': note,
      if (garaId != null) 'gara_id': garaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TempiGaraTableCompanion copyWith({
    Value<String>? id,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<String>? stile,
    Value<int>? distanzaM,
    Value<int>? vascaM,
    Value<double>? tempoS,
    Value<DateTime>? data,
    Value<String?>? note,
    Value<String?>? garaId,
    Value<int>? rowid,
  }) {
    return TempiGaraTableCompanion(
      id: id ?? this.id,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      stile: stile ?? this.stile,
      distanzaM: distanzaM ?? this.distanzaM,
      vascaM: vascaM ?? this.vascaM,
      tempoS: tempoS ?? this.tempoS,
      data: data ?? this.data,
      note: note ?? this.note,
      garaId: garaId ?? this.garaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (stile.present) {
      map['stile'] = Variable<String>(stile.value);
    }
    if (distanzaM.present) {
      map['distanza_m'] = Variable<int>(distanzaM.value);
    }
    if (vascaM.present) {
      map['vasca_m'] = Variable<int>(vascaM.value);
    }
    if (tempoS.present) {
      map['tempo_s'] = Variable<double>(tempoS.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (garaId.present) {
      map['gara_id'] = Variable<String>(garaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TempiGaraTableCompanion(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stile: $stile, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('vascaM: $vascaM, ')
          ..write('tempoS: $tempoS, ')
          ..write('data: $data, ')
          ..write('note: $note, ')
          ..write('garaId: $garaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemiTatticiTableTable extends SchemiTatticiTable
    with TableInfo<$SchemiTatticiTableTable, SchemiTatticiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemiTatticiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titoloMeta = const VerificationMeta('titolo');
  @override
  late final GeneratedColumn<String> titolo = GeneratedColumn<String>(
    'titolo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gruppoIdsJsonMeta = const VerificationMeta(
    'gruppoIdsJson',
  );
  @override
  late final GeneratedColumn<String> gruppoIdsJson = GeneratedColumn<String>(
    'gruppo_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _campoMeta = const VerificationMeta('campo');
  @override
  late final GeneratedColumn<String> campo = GeneratedColumn<String>(
    'campo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('intero'),
  );
  static const VerificationMeta _datiMeta = const VerificationMeta('dati');
  @override
  late final GeneratedColumn<String> dati = GeneratedColumn<String>(
    'dati',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<DateTime> aggiornatoIl = GeneratedColumn<DateTime>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    titolo,
    gruppoIdsJson,
    categoria,
    campo,
    dati,
    aggiornatoIl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schemi_tattici_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemiTatticiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('titolo')) {
      context.handle(
        _titoloMeta,
        titolo.isAcceptableOrUnknown(data['titolo']!, _titoloMeta),
      );
    } else if (isInserting) {
      context.missing(_titoloMeta);
    }
    if (data.containsKey('gruppo_ids_json')) {
      context.handle(
        _gruppoIdsJsonMeta,
        gruppoIdsJson.isAcceptableOrUnknown(
          data['gruppo_ids_json']!,
          _gruppoIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('campo')) {
      context.handle(
        _campoMeta,
        campo.isAcceptableOrUnknown(data['campo']!, _campoMeta),
      );
    }
    if (data.containsKey('dati')) {
      context.handle(
        _datiMeta,
        dati.isAcceptableOrUnknown(data['dati']!, _datiMeta),
      );
    } else if (isInserting) {
      context.missing(_datiMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchemiTatticiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemiTatticiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      titolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titolo'],
      )!,
      gruppoIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_ids_json'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      campo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campo'],
      )!,
      dati: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dati'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}aggiornato_il'],
      )!,
    );
  }

  @override
  $SchemiTatticiTableTable createAlias(String alias) {
    return $SchemiTatticiTableTable(attachedDatabase, alias);
  }
}

class SchemiTatticiTableData extends DataClass
    implements Insertable<SchemiTatticiTableData> {
  final String id;
  final String clubId;
  final String titolo;

  /// Gruppi di allenamento (squadre) a cui appartiene lo schema — lista
  /// vuota se condiviso con tutto il club. Prima una singola colonna
  /// nullable `gruppo_id` (un solo gruppo): JSON con gli id, come il
  /// campo `gruppo_ids` jsonb lato Supabase — stesso schema di
  /// [ClubTable.categorieJson]. Da non confondere con [categoria] (il
  /// tipo di azione tattica, es. "Superiorità").
  final String gruppoIdsJson;

  /// Gruppo libero scelto dall'allenatore (es. "Transizioni",
  /// "Superiorità"...): non un elenco chiuso, se ne possono creare
  /// quanti se ne vogliono.
  final String categoria;

  /// 'intero' | 'meta' — vedi `CampoLavagna` in `WaterPoloTacticsBoard`.
  final String campo;

  /// JSON con giocatori/frecce (vedi `SchemiTatticiRepository`), come
  /// il campo `dati` jsonb lato Supabase: qui e' testo perche' Drift/
  /// sqlite non ha un tipo json nativo.
  final String dati;
  final DateTime aggiornatoIl;
  const SchemiTatticiTableData({
    required this.id,
    required this.clubId,
    required this.titolo,
    required this.gruppoIdsJson,
    required this.categoria,
    required this.campo,
    required this.dati,
    required this.aggiornatoIl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['titolo'] = Variable<String>(titolo);
    map['gruppo_ids_json'] = Variable<String>(gruppoIdsJson);
    map['categoria'] = Variable<String>(categoria);
    map['campo'] = Variable<String>(campo);
    map['dati'] = Variable<String>(dati);
    map['aggiornato_il'] = Variable<DateTime>(aggiornatoIl);
    return map;
  }

  SchemiTatticiTableCompanion toCompanion(bool nullToAbsent) {
    return SchemiTatticiTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      titolo: Value(titolo),
      gruppoIdsJson: Value(gruppoIdsJson),
      categoria: Value(categoria),
      campo: Value(campo),
      dati: Value(dati),
      aggiornatoIl: Value(aggiornatoIl),
    );
  }

  factory SchemiTatticiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemiTatticiTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      titolo: serializer.fromJson<String>(json['titolo']),
      gruppoIdsJson: serializer.fromJson<String>(json['gruppoIdsJson']),
      categoria: serializer.fromJson<String>(json['categoria']),
      campo: serializer.fromJson<String>(json['campo']),
      dati: serializer.fromJson<String>(json['dati']),
      aggiornatoIl: serializer.fromJson<DateTime>(json['aggiornatoIl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'titolo': serializer.toJson<String>(titolo),
      'gruppoIdsJson': serializer.toJson<String>(gruppoIdsJson),
      'categoria': serializer.toJson<String>(categoria),
      'campo': serializer.toJson<String>(campo),
      'dati': serializer.toJson<String>(dati),
      'aggiornatoIl': serializer.toJson<DateTime>(aggiornatoIl),
    };
  }

  SchemiTatticiTableData copyWith({
    String? id,
    String? clubId,
    String? titolo,
    String? gruppoIdsJson,
    String? categoria,
    String? campo,
    String? dati,
    DateTime? aggiornatoIl,
  }) => SchemiTatticiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    titolo: titolo ?? this.titolo,
    gruppoIdsJson: gruppoIdsJson ?? this.gruppoIdsJson,
    categoria: categoria ?? this.categoria,
    campo: campo ?? this.campo,
    dati: dati ?? this.dati,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
  );
  SchemiTatticiTableData copyWithCompanion(SchemiTatticiTableCompanion data) {
    return SchemiTatticiTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      titolo: data.titolo.present ? data.titolo.value : this.titolo,
      gruppoIdsJson: data.gruppoIdsJson.present
          ? data.gruppoIdsJson.value
          : this.gruppoIdsJson,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      campo: data.campo.present ? data.campo.value : this.campo,
      dati: data.dati.present ? data.dati.value : this.dati,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemiTatticiTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('titolo: $titolo, ')
          ..write('gruppoIdsJson: $gruppoIdsJson, ')
          ..write('categoria: $categoria, ')
          ..write('campo: $campo, ')
          ..write('dati: $dati, ')
          ..write('aggiornatoIl: $aggiornatoIl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    titolo,
    gruppoIdsJson,
    categoria,
    campo,
    dati,
    aggiornatoIl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemiTatticiTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.titolo == this.titolo &&
          other.gruppoIdsJson == this.gruppoIdsJson &&
          other.categoria == this.categoria &&
          other.campo == this.campo &&
          other.dati == this.dati &&
          other.aggiornatoIl == this.aggiornatoIl);
}

class SchemiTatticiTableCompanion
    extends UpdateCompanion<SchemiTatticiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> titolo;
  final Value<String> gruppoIdsJson;
  final Value<String> categoria;
  final Value<String> campo;
  final Value<String> dati;
  final Value<DateTime> aggiornatoIl;
  final Value<int> rowid;
  const SchemiTatticiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.titolo = const Value.absent(),
    this.gruppoIdsJson = const Value.absent(),
    this.categoria = const Value.absent(),
    this.campo = const Value.absent(),
    this.dati = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemiTatticiTableCompanion.insert({
    required String id,
    required String clubId,
    required String titolo,
    this.gruppoIdsJson = const Value.absent(),
    this.categoria = const Value.absent(),
    this.campo = const Value.absent(),
    required String dati,
    required DateTime aggiornatoIl,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       titolo = Value(titolo),
       dati = Value(dati),
       aggiornatoIl = Value(aggiornatoIl);
  static Insertable<SchemiTatticiTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? titolo,
    Expression<String>? gruppoIdsJson,
    Expression<String>? categoria,
    Expression<String>? campo,
    Expression<String>? dati,
    Expression<DateTime>? aggiornatoIl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (titolo != null) 'titolo': titolo,
      if (gruppoIdsJson != null) 'gruppo_ids_json': gruppoIdsJson,
      if (categoria != null) 'categoria': categoria,
      if (campo != null) 'campo': campo,
      if (dati != null) 'dati': dati,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemiTatticiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String>? titolo,
    Value<String>? gruppoIdsJson,
    Value<String>? categoria,
    Value<String>? campo,
    Value<String>? dati,
    Value<DateTime>? aggiornatoIl,
    Value<int>? rowid,
  }) {
    return SchemiTatticiTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      titolo: titolo ?? this.titolo,
      gruppoIdsJson: gruppoIdsJson ?? this.gruppoIdsJson,
      categoria: categoria ?? this.categoria,
      campo: campo ?? this.campo,
      dati: dati ?? this.dati,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (titolo.present) {
      map['titolo'] = Variable<String>(titolo.value);
    }
    if (gruppoIdsJson.present) {
      map['gruppo_ids_json'] = Variable<String>(gruppoIdsJson.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (campo.present) {
      map['campo'] = Variable<String>(campo.value);
    }
    if (dati.present) {
      map['dati'] = Variable<String>(dati.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<DateTime>(aggiornatoIl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemiTatticiTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('titolo: $titolo, ')
          ..write('gruppoIdsJson: $gruppoIdsJson, ')
          ..write('categoria: $categoria, ')
          ..write('campo: $campo, ')
          ..write('dati: $dati, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TestIngressoTableTable extends TestIngressoTable
    with TableInfo<$TestIngressoTableTable, TestIngressoTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestIngressoTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataTestMeta = const VerificationMeta(
    'dataTest',
  );
  @override
  late final GeneratedColumn<DateTime> dataTest = GeneratedColumn<DateTime>(
    'data_test',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanzaTotaleMMeta = const VerificationMeta(
    'distanzaTotaleM',
  );
  @override
  late final GeneratedColumn<int> distanzaTotaleM = GeneratedColumn<int>(
    'distanza_totale_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempoTotaleSMeta = const VerificationMeta(
    'tempoTotaleS',
  );
  @override
  late final GeneratedColumn<double> tempoTotaleS = GeneratedColumn<double>(
    'tempo_totale_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passoMedio100SMeta = const VerificationMeta(
    'passoMedio100S',
  );
  @override
  late final GeneratedColumn<double> passoMedio100S = GeneratedColumn<double>(
    'passo_medio100_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    atletaId,
    clubId,
    tipo,
    dataTest,
    distanzaTotaleM,
    tempoTotaleS,
    passoMedio100S,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_ingresso_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TestIngressoTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('data_test')) {
      context.handle(
        _dataTestMeta,
        dataTest.isAcceptableOrUnknown(data['data_test']!, _dataTestMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTestMeta);
    }
    if (data.containsKey('distanza_totale_m')) {
      context.handle(
        _distanzaTotaleMMeta,
        distanzaTotaleM.isAcceptableOrUnknown(
          data['distanza_totale_m']!,
          _distanzaTotaleMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanzaTotaleMMeta);
    }
    if (data.containsKey('tempo_totale_s')) {
      context.handle(
        _tempoTotaleSMeta,
        tempoTotaleS.isAcceptableOrUnknown(
          data['tempo_totale_s']!,
          _tempoTotaleSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tempoTotaleSMeta);
    }
    if (data.containsKey('passo_medio100_s')) {
      context.handle(
        _passoMedio100SMeta,
        passoMedio100S.isAcceptableOrUnknown(
          data['passo_medio100_s']!,
          _passoMedio100SMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passoMedio100SMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TestIngressoTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestIngressoTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      dataTest: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_test'],
      )!,
      distanzaTotaleM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distanza_totale_m'],
      )!,
      tempoTotaleS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tempo_totale_s'],
      )!,
      passoMedio100S: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}passo_medio100_s'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TestIngressoTableTable createAlias(String alias) {
    return $TestIngressoTableTable(attachedDatabase, alias);
  }
}

class TestIngressoTableData extends DataClass
    implements Insertable<TestIngressoTableData> {
  final String id;
  final String atletaId;
  final String clubId;
  final String tipo;
  final DateTime dataTest;
  final int distanzaTotaleM;
  final double tempoTotaleS;
  final double passoMedio100S;
  final String? note;
  const TestIngressoTableData({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.tipo,
    required this.dataTest,
    required this.distanzaTotaleM,
    required this.tempoTotaleS,
    required this.passoMedio100S,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['tipo'] = Variable<String>(tipo);
    map['data_test'] = Variable<DateTime>(dataTest);
    map['distanza_totale_m'] = Variable<int>(distanzaTotaleM);
    map['tempo_totale_s'] = Variable<double>(tempoTotaleS);
    map['passo_medio100_s'] = Variable<double>(passoMedio100S);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TestIngressoTableCompanion toCompanion(bool nullToAbsent) {
    return TestIngressoTableCompanion(
      id: Value(id),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      tipo: Value(tipo),
      dataTest: Value(dataTest),
      distanzaTotaleM: Value(distanzaTotaleM),
      tempoTotaleS: Value(tempoTotaleS),
      passoMedio100S: Value(passoMedio100S),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TestIngressoTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestIngressoTableData(
      id: serializer.fromJson<String>(json['id']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      dataTest: serializer.fromJson<DateTime>(json['dataTest']),
      distanzaTotaleM: serializer.fromJson<int>(json['distanzaTotaleM']),
      tempoTotaleS: serializer.fromJson<double>(json['tempoTotaleS']),
      passoMedio100S: serializer.fromJson<double>(json['passoMedio100S']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'tipo': serializer.toJson<String>(tipo),
      'dataTest': serializer.toJson<DateTime>(dataTest),
      'distanzaTotaleM': serializer.toJson<int>(distanzaTotaleM),
      'tempoTotaleS': serializer.toJson<double>(tempoTotaleS),
      'passoMedio100S': serializer.toJson<double>(passoMedio100S),
      'note': serializer.toJson<String?>(note),
    };
  }

  TestIngressoTableData copyWith({
    String? id,
    String? atletaId,
    String? clubId,
    String? tipo,
    DateTime? dataTest,
    int? distanzaTotaleM,
    double? tempoTotaleS,
    double? passoMedio100S,
    Value<String?> note = const Value.absent(),
  }) => TestIngressoTableData(
    id: id ?? this.id,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    tipo: tipo ?? this.tipo,
    dataTest: dataTest ?? this.dataTest,
    distanzaTotaleM: distanzaTotaleM ?? this.distanzaTotaleM,
    tempoTotaleS: tempoTotaleS ?? this.tempoTotaleS,
    passoMedio100S: passoMedio100S ?? this.passoMedio100S,
    note: note.present ? note.value : this.note,
  );
  TestIngressoTableData copyWithCompanion(TestIngressoTableCompanion data) {
    return TestIngressoTableData(
      id: data.id.present ? data.id.value : this.id,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      dataTest: data.dataTest.present ? data.dataTest.value : this.dataTest,
      distanzaTotaleM: data.distanzaTotaleM.present
          ? data.distanzaTotaleM.value
          : this.distanzaTotaleM,
      tempoTotaleS: data.tempoTotaleS.present
          ? data.tempoTotaleS.value
          : this.tempoTotaleS,
      passoMedio100S: data.passoMedio100S.present
          ? data.passoMedio100S.value
          : this.passoMedio100S,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestIngressoTableData(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('tipo: $tipo, ')
          ..write('dataTest: $dataTest, ')
          ..write('distanzaTotaleM: $distanzaTotaleM, ')
          ..write('tempoTotaleS: $tempoTotaleS, ')
          ..write('passoMedio100S: $passoMedio100S, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    atletaId,
    clubId,
    tipo,
    dataTest,
    distanzaTotaleM,
    tempoTotaleS,
    passoMedio100S,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestIngressoTableData &&
          other.id == this.id &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.tipo == this.tipo &&
          other.dataTest == this.dataTest &&
          other.distanzaTotaleM == this.distanzaTotaleM &&
          other.tempoTotaleS == this.tempoTotaleS &&
          other.passoMedio100S == this.passoMedio100S &&
          other.note == this.note);
}

class TestIngressoTableCompanion
    extends UpdateCompanion<TestIngressoTableData> {
  final Value<String> id;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<String> tipo;
  final Value<DateTime> dataTest;
  final Value<int> distanzaTotaleM;
  final Value<double> tempoTotaleS;
  final Value<double> passoMedio100S;
  final Value<String?> note;
  final Value<int> rowid;
  const TestIngressoTableCompanion({
    this.id = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.dataTest = const Value.absent(),
    this.distanzaTotaleM = const Value.absent(),
    this.tempoTotaleS = const Value.absent(),
    this.passoMedio100S = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TestIngressoTableCompanion.insert({
    required String id,
    required String atletaId,
    required String clubId,
    required String tipo,
    required DateTime dataTest,
    required int distanzaTotaleM,
    required double tempoTotaleS,
    required double passoMedio100S,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       tipo = Value(tipo),
       dataTest = Value(dataTest),
       distanzaTotaleM = Value(distanzaTotaleM),
       tempoTotaleS = Value(tempoTotaleS),
       passoMedio100S = Value(passoMedio100S);
  static Insertable<TestIngressoTableData> custom({
    Expression<String>? id,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<String>? tipo,
    Expression<DateTime>? dataTest,
    Expression<int>? distanzaTotaleM,
    Expression<double>? tempoTotaleS,
    Expression<double>? passoMedio100S,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (tipo != null) 'tipo': tipo,
      if (dataTest != null) 'data_test': dataTest,
      if (distanzaTotaleM != null) 'distanza_totale_m': distanzaTotaleM,
      if (tempoTotaleS != null) 'tempo_totale_s': tempoTotaleS,
      if (passoMedio100S != null) 'passo_medio100_s': passoMedio100S,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TestIngressoTableCompanion copyWith({
    Value<String>? id,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<String>? tipo,
    Value<DateTime>? dataTest,
    Value<int>? distanzaTotaleM,
    Value<double>? tempoTotaleS,
    Value<double>? passoMedio100S,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TestIngressoTableCompanion(
      id: id ?? this.id,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      tipo: tipo ?? this.tipo,
      dataTest: dataTest ?? this.dataTest,
      distanzaTotaleM: distanzaTotaleM ?? this.distanzaTotaleM,
      tempoTotaleS: tempoTotaleS ?? this.tempoTotaleS,
      passoMedio100S: passoMedio100S ?? this.passoMedio100S,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (dataTest.present) {
      map['data_test'] = Variable<DateTime>(dataTest.value);
    }
    if (distanzaTotaleM.present) {
      map['distanza_totale_m'] = Variable<int>(distanzaTotaleM.value);
    }
    if (tempoTotaleS.present) {
      map['tempo_totale_s'] = Variable<double>(tempoTotaleS.value);
    }
    if (passoMedio100S.present) {
      map['passo_medio100_s'] = Variable<double>(passoMedio100S.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestIngressoTableCompanion(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('tipo: $tipo, ')
          ..write('dataTest: $dataTest, ')
          ..write('distanzaTotaleM: $distanzaTotaleM, ')
          ..write('tempoTotaleS: $tempoTotaleS, ')
          ..write('passoMedio100S: $passoMedio100S, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TabellePassiTableTable extends TabellePassiTable
    with TableInfo<$TabellePassiTableTable, TabellePassiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TabellePassiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testIdMeta = const VerificationMeta('testId');
  @override
  late final GeneratedColumn<String> testId = GeneratedColumn<String>(
    'test_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
    'zona',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passo100SMeta = const VerificationMeta(
    'passo100S',
  );
  @override
  late final GeneratedColumn<double> passo100S = GeneratedColumn<double>(
    'passo100_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentualeRiferimentoMeta =
      const VerificationMeta('percentualeRiferimento');
  @override
  late final GeneratedColumn<double> percentualeRiferimento =
      GeneratedColumn<double>(
        'percentuale_riferimento',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    testId,
    atletaId,
    clubId,
    zona,
    passo100S,
    percentualeRiferimento,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tabelle_passi_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TabellePassiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('test_id')) {
      context.handle(
        _testIdMeta,
        testId.isAcceptableOrUnknown(data['test_id']!, _testIdMeta),
      );
    } else if (isInserting) {
      context.missing(_testIdMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('zona')) {
      context.handle(
        _zonaMeta,
        zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta),
      );
    } else if (isInserting) {
      context.missing(_zonaMeta);
    }
    if (data.containsKey('passo100_s')) {
      context.handle(
        _passo100SMeta,
        passo100S.isAcceptableOrUnknown(data['passo100_s']!, _passo100SMeta),
      );
    } else if (isInserting) {
      context.missing(_passo100SMeta);
    }
    if (data.containsKey('percentuale_riferimento')) {
      context.handle(
        _percentualeRiferimentoMeta,
        percentualeRiferimento.isAcceptableOrUnknown(
          data['percentuale_riferimento']!,
          _percentualeRiferimentoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TabellePassiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TabellePassiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      testId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      zona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zona'],
      )!,
      passo100S: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}passo100_s'],
      )!,
      percentualeRiferimento: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentuale_riferimento'],
      ),
    );
  }

  @override
  $TabellePassiTableTable createAlias(String alias) {
    return $TabellePassiTableTable(attachedDatabase, alias);
  }
}

class TabellePassiTableData extends DataClass
    implements Insertable<TabellePassiTableData> {
  final String id;
  final String testId;
  final String atletaId;
  final String clubId;
  final String zona;
  final double passo100S;
  final double? percentualeRiferimento;
  const TabellePassiTableData({
    required this.id,
    required this.testId,
    required this.atletaId,
    required this.clubId,
    required this.zona,
    required this.passo100S,
    this.percentualeRiferimento,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['test_id'] = Variable<String>(testId);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['zona'] = Variable<String>(zona);
    map['passo100_s'] = Variable<double>(passo100S);
    if (!nullToAbsent || percentualeRiferimento != null) {
      map['percentuale_riferimento'] = Variable<double>(percentualeRiferimento);
    }
    return map;
  }

  TabellePassiTableCompanion toCompanion(bool nullToAbsent) {
    return TabellePassiTableCompanion(
      id: Value(id),
      testId: Value(testId),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      zona: Value(zona),
      passo100S: Value(passo100S),
      percentualeRiferimento: percentualeRiferimento == null && nullToAbsent
          ? const Value.absent()
          : Value(percentualeRiferimento),
    );
  }

  factory TabellePassiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TabellePassiTableData(
      id: serializer.fromJson<String>(json['id']),
      testId: serializer.fromJson<String>(json['testId']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      zona: serializer.fromJson<String>(json['zona']),
      passo100S: serializer.fromJson<double>(json['passo100S']),
      percentualeRiferimento: serializer.fromJson<double?>(
        json['percentualeRiferimento'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'testId': serializer.toJson<String>(testId),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'zona': serializer.toJson<String>(zona),
      'passo100S': serializer.toJson<double>(passo100S),
      'percentualeRiferimento': serializer.toJson<double?>(
        percentualeRiferimento,
      ),
    };
  }

  TabellePassiTableData copyWith({
    String? id,
    String? testId,
    String? atletaId,
    String? clubId,
    String? zona,
    double? passo100S,
    Value<double?> percentualeRiferimento = const Value.absent(),
  }) => TabellePassiTableData(
    id: id ?? this.id,
    testId: testId ?? this.testId,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    zona: zona ?? this.zona,
    passo100S: passo100S ?? this.passo100S,
    percentualeRiferimento: percentualeRiferimento.present
        ? percentualeRiferimento.value
        : this.percentualeRiferimento,
  );
  TabellePassiTableData copyWithCompanion(TabellePassiTableCompanion data) {
    return TabellePassiTableData(
      id: data.id.present ? data.id.value : this.id,
      testId: data.testId.present ? data.testId.value : this.testId,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      zona: data.zona.present ? data.zona.value : this.zona,
      passo100S: data.passo100S.present ? data.passo100S.value : this.passo100S,
      percentualeRiferimento: data.percentualeRiferimento.present
          ? data.percentualeRiferimento.value
          : this.percentualeRiferimento,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TabellePassiTableData(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('zona: $zona, ')
          ..write('passo100S: $passo100S, ')
          ..write('percentualeRiferimento: $percentualeRiferimento')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    testId,
    atletaId,
    clubId,
    zona,
    passo100S,
    percentualeRiferimento,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TabellePassiTableData &&
          other.id == this.id &&
          other.testId == this.testId &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.zona == this.zona &&
          other.passo100S == this.passo100S &&
          other.percentualeRiferimento == this.percentualeRiferimento);
}

class TabellePassiTableCompanion
    extends UpdateCompanion<TabellePassiTableData> {
  final Value<String> id;
  final Value<String> testId;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<String> zona;
  final Value<double> passo100S;
  final Value<double?> percentualeRiferimento;
  final Value<int> rowid;
  const TabellePassiTableCompanion({
    this.id = const Value.absent(),
    this.testId = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.zona = const Value.absent(),
    this.passo100S = const Value.absent(),
    this.percentualeRiferimento = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TabellePassiTableCompanion.insert({
    required String id,
    required String testId,
    required String atletaId,
    required String clubId,
    required String zona,
    required double passo100S,
    this.percentualeRiferimento = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       testId = Value(testId),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       zona = Value(zona),
       passo100S = Value(passo100S);
  static Insertable<TabellePassiTableData> custom({
    Expression<String>? id,
    Expression<String>? testId,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<String>? zona,
    Expression<double>? passo100S,
    Expression<double>? percentualeRiferimento,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (testId != null) 'test_id': testId,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (zona != null) 'zona': zona,
      if (passo100S != null) 'passo100_s': passo100S,
      if (percentualeRiferimento != null)
        'percentuale_riferimento': percentualeRiferimento,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TabellePassiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? testId,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<String>? zona,
    Value<double>? passo100S,
    Value<double?>? percentualeRiferimento,
    Value<int>? rowid,
  }) {
    return TabellePassiTableCompanion(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      zona: zona ?? this.zona,
      passo100S: passo100S ?? this.passo100S,
      percentualeRiferimento:
          percentualeRiferimento ?? this.percentualeRiferimento,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (testId.present) {
      map['test_id'] = Variable<String>(testId.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (passo100S.present) {
      map['passo100_s'] = Variable<double>(passo100S.value);
    }
    if (percentualeRiferimento.present) {
      map['percentuale_riferimento'] = Variable<double>(
        percentualeRiferimento.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabellePassiTableCompanion(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('zona: $zona, ')
          ..write('passo100S: $passo100S, ')
          ..write('percentualeRiferimento: $percentualeRiferimento, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagioniTableTable extends StagioniTable
    with TableInfo<$StagioniTableTable, StagioniTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagioniTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataInizioMeta = const VerificationMeta(
    'dataInizio',
  );
  @override
  late final GeneratedColumn<DateTime> dataInizio = GeneratedColumn<DateTime>(
    'data_inizio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataFineMeta = const VerificationMeta(
    'dataFine',
  );
  @override
  late final GeneratedColumn<DateTime> dataFine = GeneratedColumn<DateTime>(
    'data_fine',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obiettivoMeta = const VerificationMeta(
    'obiettivo',
  );
  @override
  late final GeneratedColumn<String> obiettivo = GeneratedColumn<String>(
    'obiettivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gruppoIdMeta = const VerificationMeta(
    'gruppoId',
  );
  @override
  late final GeneratedColumn<String> gruppoId = GeneratedColumn<String>(
    'gruppo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _campionatoMeta = const VerificationMeta(
    'campionato',
  );
  @override
  late final GeneratedColumn<String> campionato = GeneratedColumn<String>(
    'campionato',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    nome,
    dataInizio,
    dataFine,
    obiettivo,
    gruppoId,
    campionato,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stagioni_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StagioniTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('data_inizio')) {
      context.handle(
        _dataInizioMeta,
        dataInizio.isAcceptableOrUnknown(data['data_inizio']!, _dataInizioMeta),
      );
    } else if (isInserting) {
      context.missing(_dataInizioMeta);
    }
    if (data.containsKey('data_fine')) {
      context.handle(
        _dataFineMeta,
        dataFine.isAcceptableOrUnknown(data['data_fine']!, _dataFineMeta),
      );
    } else if (isInserting) {
      context.missing(_dataFineMeta);
    }
    if (data.containsKey('obiettivo')) {
      context.handle(
        _obiettivoMeta,
        obiettivo.isAcceptableOrUnknown(data['obiettivo']!, _obiettivoMeta),
      );
    }
    if (data.containsKey('gruppo_id')) {
      context.handle(
        _gruppoIdMeta,
        gruppoId.isAcceptableOrUnknown(data['gruppo_id']!, _gruppoIdMeta),
      );
    }
    if (data.containsKey('campionato')) {
      context.handle(
        _campionatoMeta,
        campionato.isAcceptableOrUnknown(data['campionato']!, _campionatoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StagioniTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StagioniTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      dataInizio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_inizio'],
      )!,
      dataFine: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_fine'],
      )!,
      obiettivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obiettivo'],
      ),
      gruppoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_id'],
      ),
      campionato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campionato'],
      ),
    );
  }

  @override
  $StagioniTableTable createAlias(String alias) {
    return $StagioniTableTable(attachedDatabase, alias);
  }
}

class StagioniTableData extends DataClass
    implements Insertable<StagioniTableData> {
  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppoId;
  final String? campionato;
  const StagioniTableData({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppoId,
    this.campionato,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['nome'] = Variable<String>(nome);
    map['data_inizio'] = Variable<DateTime>(dataInizio);
    map['data_fine'] = Variable<DateTime>(dataFine);
    if (!nullToAbsent || obiettivo != null) {
      map['obiettivo'] = Variable<String>(obiettivo);
    }
    if (!nullToAbsent || gruppoId != null) {
      map['gruppo_id'] = Variable<String>(gruppoId);
    }
    if (!nullToAbsent || campionato != null) {
      map['campionato'] = Variable<String>(campionato);
    }
    return map;
  }

  StagioniTableCompanion toCompanion(bool nullToAbsent) {
    return StagioniTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      nome: Value(nome),
      dataInizio: Value(dataInizio),
      dataFine: Value(dataFine),
      obiettivo: obiettivo == null && nullToAbsent
          ? const Value.absent()
          : Value(obiettivo),
      gruppoId: gruppoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppoId),
      campionato: campionato == null && nullToAbsent
          ? const Value.absent()
          : Value(campionato),
    );
  }

  factory StagioniTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StagioniTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      nome: serializer.fromJson<String>(json['nome']),
      dataInizio: serializer.fromJson<DateTime>(json['dataInizio']),
      dataFine: serializer.fromJson<DateTime>(json['dataFine']),
      obiettivo: serializer.fromJson<String?>(json['obiettivo']),
      gruppoId: serializer.fromJson<String?>(json['gruppoId']),
      campionato: serializer.fromJson<String?>(json['campionato']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'nome': serializer.toJson<String>(nome),
      'dataInizio': serializer.toJson<DateTime>(dataInizio),
      'dataFine': serializer.toJson<DateTime>(dataFine),
      'obiettivo': serializer.toJson<String?>(obiettivo),
      'gruppoId': serializer.toJson<String?>(gruppoId),
      'campionato': serializer.toJson<String?>(campionato),
    };
  }

  StagioniTableData copyWith({
    String? id,
    String? clubId,
    String? nome,
    DateTime? dataInizio,
    DateTime? dataFine,
    Value<String?> obiettivo = const Value.absent(),
    Value<String?> gruppoId = const Value.absent(),
    Value<String?> campionato = const Value.absent(),
  }) => StagioniTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    nome: nome ?? this.nome,
    dataInizio: dataInizio ?? this.dataInizio,
    dataFine: dataFine ?? this.dataFine,
    obiettivo: obiettivo.present ? obiettivo.value : this.obiettivo,
    gruppoId: gruppoId.present ? gruppoId.value : this.gruppoId,
    campionato: campionato.present ? campionato.value : this.campionato,
  );
  StagioniTableData copyWithCompanion(StagioniTableCompanion data) {
    return StagioniTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      nome: data.nome.present ? data.nome.value : this.nome,
      dataInizio: data.dataInizio.present
          ? data.dataInizio.value
          : this.dataInizio,
      dataFine: data.dataFine.present ? data.dataFine.value : this.dataFine,
      obiettivo: data.obiettivo.present ? data.obiettivo.value : this.obiettivo,
      gruppoId: data.gruppoId.present ? data.gruppoId.value : this.gruppoId,
      campionato: data.campionato.present
          ? data.campionato.value
          : this.campionato,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StagioniTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('dataInizio: $dataInizio, ')
          ..write('dataFine: $dataFine, ')
          ..write('obiettivo: $obiettivo, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('campionato: $campionato')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    nome,
    dataInizio,
    dataFine,
    obiettivo,
    gruppoId,
    campionato,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagioniTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.nome == this.nome &&
          other.dataInizio == this.dataInizio &&
          other.dataFine == this.dataFine &&
          other.obiettivo == this.obiettivo &&
          other.gruppoId == this.gruppoId &&
          other.campionato == this.campionato);
}

class StagioniTableCompanion extends UpdateCompanion<StagioniTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> nome;
  final Value<DateTime> dataInizio;
  final Value<DateTime> dataFine;
  final Value<String?> obiettivo;
  final Value<String?> gruppoId;
  final Value<String?> campionato;
  final Value<int> rowid;
  const StagioniTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.nome = const Value.absent(),
    this.dataInizio = const Value.absent(),
    this.dataFine = const Value.absent(),
    this.obiettivo = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.campionato = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StagioniTableCompanion.insert({
    required String id,
    required String clubId,
    required String nome,
    required DateTime dataInizio,
    required DateTime dataFine,
    this.obiettivo = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.campionato = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       nome = Value(nome),
       dataInizio = Value(dataInizio),
       dataFine = Value(dataFine);
  static Insertable<StagioniTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? nome,
    Expression<DateTime>? dataInizio,
    Expression<DateTime>? dataFine,
    Expression<String>? obiettivo,
    Expression<String>? gruppoId,
    Expression<String>? campionato,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (nome != null) 'nome': nome,
      if (dataInizio != null) 'data_inizio': dataInizio,
      if (dataFine != null) 'data_fine': dataFine,
      if (obiettivo != null) 'obiettivo': obiettivo,
      if (gruppoId != null) 'gruppo_id': gruppoId,
      if (campionato != null) 'campionato': campionato,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StagioniTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String>? nome,
    Value<DateTime>? dataInizio,
    Value<DateTime>? dataFine,
    Value<String?>? obiettivo,
    Value<String?>? gruppoId,
    Value<String?>? campionato,
    Value<int>? rowid,
  }) {
    return StagioniTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      nome: nome ?? this.nome,
      dataInizio: dataInizio ?? this.dataInizio,
      dataFine: dataFine ?? this.dataFine,
      obiettivo: obiettivo ?? this.obiettivo,
      gruppoId: gruppoId ?? this.gruppoId,
      campionato: campionato ?? this.campionato,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (dataInizio.present) {
      map['data_inizio'] = Variable<DateTime>(dataInizio.value);
    }
    if (dataFine.present) {
      map['data_fine'] = Variable<DateTime>(dataFine.value);
    }
    if (obiettivo.present) {
      map['obiettivo'] = Variable<String>(obiettivo.value);
    }
    if (gruppoId.present) {
      map['gruppo_id'] = Variable<String>(gruppoId.value);
    }
    if (campionato.present) {
      map['campionato'] = Variable<String>(campionato.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagioniTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('dataInizio: $dataInizio, ')
          ..write('dataFine: $dataFine, ')
          ..write('obiettivo: $obiettivo, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('campionato: $campionato, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AllenamentiTableTable extends AllenamentiTable
    with TableInfo<$AllenamentiTableTable, AllenamentiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllenamentiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titoloMeta = const VerificationMeta('titolo');
  @override
  late final GeneratedColumn<String> titolo = GeneratedColumn<String>(
    'titolo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gruppoIdMeta = const VerificationMeta(
    'gruppoId',
  );
  @override
  late final GeneratedColumn<String> gruppoId = GeneratedColumn<String>(
    'gruppo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    data,
    titolo,
    gruppoId,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allenamenti_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AllenamentiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('titolo')) {
      context.handle(
        _titoloMeta,
        titolo.isAcceptableOrUnknown(data['titolo']!, _titoloMeta),
      );
    }
    if (data.containsKey('gruppo_id')) {
      context.handle(
        _gruppoIdMeta,
        gruppoId.isAcceptableOrUnknown(data['gruppo_id']!, _gruppoIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AllenamentiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AllenamentiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      titolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titolo'],
      ),
      gruppoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $AllenamentiTableTable createAlias(String alias) {
    return $AllenamentiTableTable(attachedDatabase, alias);
  }
}

class AllenamentiTableData extends DataClass
    implements Insertable<AllenamentiTableData> {
  final String id;
  final String clubId;
  final DateTime data;
  final String? titolo;
  final String? gruppoId;
  final String? note;
  const AllenamentiTableData({
    required this.id,
    required this.clubId,
    required this.data,
    this.titolo,
    this.gruppoId,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || titolo != null) {
      map['titolo'] = Variable<String>(titolo);
    }
    if (!nullToAbsent || gruppoId != null) {
      map['gruppo_id'] = Variable<String>(gruppoId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  AllenamentiTableCompanion toCompanion(bool nullToAbsent) {
    return AllenamentiTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      data: Value(data),
      titolo: titolo == null && nullToAbsent
          ? const Value.absent()
          : Value(titolo),
      gruppoId: gruppoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppoId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory AllenamentiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AllenamentiTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      data: serializer.fromJson<DateTime>(json['data']),
      titolo: serializer.fromJson<String?>(json['titolo']),
      gruppoId: serializer.fromJson<String?>(json['gruppoId']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'data': serializer.toJson<DateTime>(data),
      'titolo': serializer.toJson<String?>(titolo),
      'gruppoId': serializer.toJson<String?>(gruppoId),
      'note': serializer.toJson<String?>(note),
    };
  }

  AllenamentiTableData copyWith({
    String? id,
    String? clubId,
    DateTime? data,
    Value<String?> titolo = const Value.absent(),
    Value<String?> gruppoId = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => AllenamentiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    data: data ?? this.data,
    titolo: titolo.present ? titolo.value : this.titolo,
    gruppoId: gruppoId.present ? gruppoId.value : this.gruppoId,
    note: note.present ? note.value : this.note,
  );
  AllenamentiTableData copyWithCompanion(AllenamentiTableCompanion data) {
    return AllenamentiTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      data: data.data.present ? data.data.value : this.data,
      titolo: data.titolo.present ? data.titolo.value : this.titolo,
      gruppoId: data.gruppoId.present ? data.gruppoId.value : this.gruppoId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllenamentiTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('data: $data, ')
          ..write('titolo: $titolo, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clubId, data, titolo, gruppoId, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllenamentiTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.data == this.data &&
          other.titolo == this.titolo &&
          other.gruppoId == this.gruppoId &&
          other.note == this.note);
}

class AllenamentiTableCompanion extends UpdateCompanion<AllenamentiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<DateTime> data;
  final Value<String?> titolo;
  final Value<String?> gruppoId;
  final Value<String?> note;
  final Value<int> rowid;
  const AllenamentiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.data = const Value.absent(),
    this.titolo = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllenamentiTableCompanion.insert({
    required String id,
    required String clubId,
    required DateTime data,
    this.titolo = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       data = Value(data);
  static Insertable<AllenamentiTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<DateTime>? data,
    Expression<String>? titolo,
    Expression<String>? gruppoId,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (data != null) 'data': data,
      if (titolo != null) 'titolo': titolo,
      if (gruppoId != null) 'gruppo_id': gruppoId,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllenamentiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<DateTime>? data,
    Value<String?>? titolo,
    Value<String?>? gruppoId,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return AllenamentiTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      data: data ?? this.data,
      titolo: titolo ?? this.titolo,
      gruppoId: gruppoId ?? this.gruppoId,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (titolo.present) {
      map['titolo'] = Variable<String>(titolo.value);
    }
    if (gruppoId.present) {
      map['gruppo_id'] = Variable<String>(gruppoId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllenamentiTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('data: $data, ')
          ..write('titolo: $titolo, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SerieTableTable extends SerieTable
    with TableInfo<$SerieTableTable, SerieTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SerieTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allenamentoIdMeta = const VerificationMeta(
    'allenamentoId',
  );
  @override
  late final GeneratedColumn<String> allenamentoId = GeneratedColumn<String>(
    'allenamento_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bloccoMeta = const VerificationMeta('blocco');
  @override
  late final GeneratedColumn<String> blocco = GeneratedColumn<String>(
    'blocco',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ripetuteMeta = const VerificationMeta(
    'ripetute',
  );
  @override
  late final GeneratedColumn<int> ripetute = GeneratedColumn<int>(
    'ripetute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanzaMMeta = const VerificationMeta(
    'distanzaM',
  );
  @override
  late final GeneratedColumn<int> distanzaM = GeneratedColumn<int>(
    'distanza_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durataSMeta = const VerificationMeta(
    'durataS',
  );
  @override
  late final GeneratedColumn<int> durataS = GeneratedColumn<int>(
    'durata_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stileMeta = const VerificationMeta('stile');
  @override
  late final GeneratedColumn<String> stile = GeneratedColumn<String>(
    'stile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _esecuzioneMeta = const VerificationMeta(
    'esecuzione',
  );
  @override
  late final GeneratedColumn<String> esecuzione = GeneratedColumn<String>(
    'esecuzione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
    'zona',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passoObiettivoSMeta = const VerificationMeta(
    'passoObiettivoS',
  );
  @override
  late final GeneratedColumn<double> passoObiettivoS = GeneratedColumn<double>(
    'passo_obiettivo_s',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recuperoSMeta = const VerificationMeta(
    'recuperoS',
  );
  @override
  late final GeneratedColumn<int> recuperoS = GeneratedColumn<int>(
    'recupero_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ripartenzaSMeta = const VerificationMeta(
    'ripartenzaS',
  );
  @override
  late final GeneratedColumn<double> ripartenzaS = GeneratedColumn<double>(
    'ripartenza_s',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attrezzaturaMeta = const VerificationMeta(
    'attrezzatura',
  );
  @override
  late final GeneratedColumn<String> attrezzatura = GeneratedColumn<String>(
    'attrezzatura',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _piramideIdMeta = const VerificationMeta(
    'piramideId',
  );
  @override
  late final GeneratedColumn<String> piramideId = GeneratedColumn<String>(
    'piramide_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    allenamentoId,
    clubId,
    ordine,
    blocco,
    ripetute,
    distanzaM,
    durataS,
    stile,
    esecuzione,
    zona,
    passoObiettivoS,
    recuperoS,
    ripartenzaS,
    attrezzatura,
    note,
    piramideId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'serie_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SerieTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('allenamento_id')) {
      context.handle(
        _allenamentoIdMeta,
        allenamentoId.isAcceptableOrUnknown(
          data['allenamento_id']!,
          _allenamentoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allenamentoIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    } else if (isInserting) {
      context.missing(_ordineMeta);
    }
    if (data.containsKey('blocco')) {
      context.handle(
        _bloccoMeta,
        blocco.isAcceptableOrUnknown(data['blocco']!, _bloccoMeta),
      );
    } else if (isInserting) {
      context.missing(_bloccoMeta);
    }
    if (data.containsKey('ripetute')) {
      context.handle(
        _ripetuteMeta,
        ripetute.isAcceptableOrUnknown(data['ripetute']!, _ripetuteMeta),
      );
    } else if (isInserting) {
      context.missing(_ripetuteMeta);
    }
    if (data.containsKey('distanza_m')) {
      context.handle(
        _distanzaMMeta,
        distanzaM.isAcceptableOrUnknown(data['distanza_m']!, _distanzaMMeta),
      );
    }
    if (data.containsKey('durata_s')) {
      context.handle(
        _durataSMeta,
        durataS.isAcceptableOrUnknown(data['durata_s']!, _durataSMeta),
      );
    }
    if (data.containsKey('stile')) {
      context.handle(
        _stileMeta,
        stile.isAcceptableOrUnknown(data['stile']!, _stileMeta),
      );
    } else if (isInserting) {
      context.missing(_stileMeta);
    }
    if (data.containsKey('esecuzione')) {
      context.handle(
        _esecuzioneMeta,
        esecuzione.isAcceptableOrUnknown(data['esecuzione']!, _esecuzioneMeta),
      );
    } else if (isInserting) {
      context.missing(_esecuzioneMeta);
    }
    if (data.containsKey('zona')) {
      context.handle(
        _zonaMeta,
        zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta),
      );
    }
    if (data.containsKey('passo_obiettivo_s')) {
      context.handle(
        _passoObiettivoSMeta,
        passoObiettivoS.isAcceptableOrUnknown(
          data['passo_obiettivo_s']!,
          _passoObiettivoSMeta,
        ),
      );
    }
    if (data.containsKey('recupero_s')) {
      context.handle(
        _recuperoSMeta,
        recuperoS.isAcceptableOrUnknown(data['recupero_s']!, _recuperoSMeta),
      );
    }
    if (data.containsKey('ripartenza_s')) {
      context.handle(
        _ripartenzaSMeta,
        ripartenzaS.isAcceptableOrUnknown(
          data['ripartenza_s']!,
          _ripartenzaSMeta,
        ),
      );
    }
    if (data.containsKey('attrezzatura')) {
      context.handle(
        _attrezzaturaMeta,
        attrezzatura.isAcceptableOrUnknown(
          data['attrezzatura']!,
          _attrezzaturaMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('piramide_id')) {
      context.handle(
        _piramideIdMeta,
        piramideId.isAcceptableOrUnknown(data['piramide_id']!, _piramideIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SerieTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SerieTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      allenamentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allenamento_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
      blocco: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocco'],
      )!,
      ripetute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ripetute'],
      )!,
      distanzaM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distanza_m'],
      ),
      durataS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}durata_s'],
      ),
      stile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stile'],
      )!,
      esecuzione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esecuzione'],
      )!,
      zona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zona'],
      ),
      passoObiettivoS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}passo_obiettivo_s'],
      ),
      recuperoS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recupero_s'],
      ),
      ripartenzaS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ripartenza_s'],
      ),
      attrezzatura: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attrezzatura'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      piramideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}piramide_id'],
      ),
    );
  }

  @override
  $SerieTableTable createAlias(String alias) {
    return $SerieTableTable(attachedDatabase, alias);
  }
}

class SerieTableData extends DataClass implements Insertable<SerieTableData> {
  final String id;
  final String allenamentoId;
  final String clubId;
  final int ordine;
  final String blocco;
  final int ripetute;

  /// Una serie usa distanza o durata, mai entrambe — vedi [durataS].
  final int? distanzaM;

  /// Serie "a tempo" (es. lavoro a secco, tattica a tempo): alternativa
  /// a [distanzaM], non un campo aggiuntivo.
  final int? durataS;
  final String stile;
  final String esecuzione;
  final String? zona;
  final double? passoObiettivoS;
  final int? recuperoS;
  final double? ripartenzaS;
  final String? attrezzatura;
  final String? note;

  /// Righe della stessa piramide (es. 50-100-200-100-50, dalla barra
  /// rapida) condividono questo id, per raggrupparle in un'unica riga
  /// visiva — null per una serie normale.
  final String? piramideId;
  const SerieTableData({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.ordine,
    required this.blocco,
    required this.ripetute,
    this.distanzaM,
    this.durataS,
    required this.stile,
    required this.esecuzione,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
    this.ripartenzaS,
    this.attrezzatura,
    this.note,
    this.piramideId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['allenamento_id'] = Variable<String>(allenamentoId);
    map['club_id'] = Variable<String>(clubId);
    map['ordine'] = Variable<int>(ordine);
    map['blocco'] = Variable<String>(blocco);
    map['ripetute'] = Variable<int>(ripetute);
    if (!nullToAbsent || distanzaM != null) {
      map['distanza_m'] = Variable<int>(distanzaM);
    }
    if (!nullToAbsent || durataS != null) {
      map['durata_s'] = Variable<int>(durataS);
    }
    map['stile'] = Variable<String>(stile);
    map['esecuzione'] = Variable<String>(esecuzione);
    if (!nullToAbsent || zona != null) {
      map['zona'] = Variable<String>(zona);
    }
    if (!nullToAbsent || passoObiettivoS != null) {
      map['passo_obiettivo_s'] = Variable<double>(passoObiettivoS);
    }
    if (!nullToAbsent || recuperoS != null) {
      map['recupero_s'] = Variable<int>(recuperoS);
    }
    if (!nullToAbsent || ripartenzaS != null) {
      map['ripartenza_s'] = Variable<double>(ripartenzaS);
    }
    if (!nullToAbsent || attrezzatura != null) {
      map['attrezzatura'] = Variable<String>(attrezzatura);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || piramideId != null) {
      map['piramide_id'] = Variable<String>(piramideId);
    }
    return map;
  }

  SerieTableCompanion toCompanion(bool nullToAbsent) {
    return SerieTableCompanion(
      id: Value(id),
      allenamentoId: Value(allenamentoId),
      clubId: Value(clubId),
      ordine: Value(ordine),
      blocco: Value(blocco),
      ripetute: Value(ripetute),
      distanzaM: distanzaM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanzaM),
      durataS: durataS == null && nullToAbsent
          ? const Value.absent()
          : Value(durataS),
      stile: Value(stile),
      esecuzione: Value(esecuzione),
      zona: zona == null && nullToAbsent ? const Value.absent() : Value(zona),
      passoObiettivoS: passoObiettivoS == null && nullToAbsent
          ? const Value.absent()
          : Value(passoObiettivoS),
      recuperoS: recuperoS == null && nullToAbsent
          ? const Value.absent()
          : Value(recuperoS),
      ripartenzaS: ripartenzaS == null && nullToAbsent
          ? const Value.absent()
          : Value(ripartenzaS),
      attrezzatura: attrezzatura == null && nullToAbsent
          ? const Value.absent()
          : Value(attrezzatura),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      piramideId: piramideId == null && nullToAbsent
          ? const Value.absent()
          : Value(piramideId),
    );
  }

  factory SerieTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SerieTableData(
      id: serializer.fromJson<String>(json['id']),
      allenamentoId: serializer.fromJson<String>(json['allenamentoId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      ordine: serializer.fromJson<int>(json['ordine']),
      blocco: serializer.fromJson<String>(json['blocco']),
      ripetute: serializer.fromJson<int>(json['ripetute']),
      distanzaM: serializer.fromJson<int?>(json['distanzaM']),
      durataS: serializer.fromJson<int?>(json['durataS']),
      stile: serializer.fromJson<String>(json['stile']),
      esecuzione: serializer.fromJson<String>(json['esecuzione']),
      zona: serializer.fromJson<String?>(json['zona']),
      passoObiettivoS: serializer.fromJson<double?>(json['passoObiettivoS']),
      recuperoS: serializer.fromJson<int?>(json['recuperoS']),
      ripartenzaS: serializer.fromJson<double?>(json['ripartenzaS']),
      attrezzatura: serializer.fromJson<String?>(json['attrezzatura']),
      note: serializer.fromJson<String?>(json['note']),
      piramideId: serializer.fromJson<String?>(json['piramideId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'allenamentoId': serializer.toJson<String>(allenamentoId),
      'clubId': serializer.toJson<String>(clubId),
      'ordine': serializer.toJson<int>(ordine),
      'blocco': serializer.toJson<String>(blocco),
      'ripetute': serializer.toJson<int>(ripetute),
      'distanzaM': serializer.toJson<int?>(distanzaM),
      'durataS': serializer.toJson<int?>(durataS),
      'stile': serializer.toJson<String>(stile),
      'esecuzione': serializer.toJson<String>(esecuzione),
      'zona': serializer.toJson<String?>(zona),
      'passoObiettivoS': serializer.toJson<double?>(passoObiettivoS),
      'recuperoS': serializer.toJson<int?>(recuperoS),
      'ripartenzaS': serializer.toJson<double?>(ripartenzaS),
      'attrezzatura': serializer.toJson<String?>(attrezzatura),
      'note': serializer.toJson<String?>(note),
      'piramideId': serializer.toJson<String?>(piramideId),
    };
  }

  SerieTableData copyWith({
    String? id,
    String? allenamentoId,
    String? clubId,
    int? ordine,
    String? blocco,
    int? ripetute,
    Value<int?> distanzaM = const Value.absent(),
    Value<int?> durataS = const Value.absent(),
    String? stile,
    String? esecuzione,
    Value<String?> zona = const Value.absent(),
    Value<double?> passoObiettivoS = const Value.absent(),
    Value<int?> recuperoS = const Value.absent(),
    Value<double?> ripartenzaS = const Value.absent(),
    Value<String?> attrezzatura = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> piramideId = const Value.absent(),
  }) => SerieTableData(
    id: id ?? this.id,
    allenamentoId: allenamentoId ?? this.allenamentoId,
    clubId: clubId ?? this.clubId,
    ordine: ordine ?? this.ordine,
    blocco: blocco ?? this.blocco,
    ripetute: ripetute ?? this.ripetute,
    distanzaM: distanzaM.present ? distanzaM.value : this.distanzaM,
    durataS: durataS.present ? durataS.value : this.durataS,
    stile: stile ?? this.stile,
    esecuzione: esecuzione ?? this.esecuzione,
    zona: zona.present ? zona.value : this.zona,
    passoObiettivoS: passoObiettivoS.present
        ? passoObiettivoS.value
        : this.passoObiettivoS,
    recuperoS: recuperoS.present ? recuperoS.value : this.recuperoS,
    ripartenzaS: ripartenzaS.present ? ripartenzaS.value : this.ripartenzaS,
    attrezzatura: attrezzatura.present ? attrezzatura.value : this.attrezzatura,
    note: note.present ? note.value : this.note,
    piramideId: piramideId.present ? piramideId.value : this.piramideId,
  );
  SerieTableData copyWithCompanion(SerieTableCompanion data) {
    return SerieTableData(
      id: data.id.present ? data.id.value : this.id,
      allenamentoId: data.allenamentoId.present
          ? data.allenamentoId.value
          : this.allenamentoId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
      blocco: data.blocco.present ? data.blocco.value : this.blocco,
      ripetute: data.ripetute.present ? data.ripetute.value : this.ripetute,
      distanzaM: data.distanzaM.present ? data.distanzaM.value : this.distanzaM,
      durataS: data.durataS.present ? data.durataS.value : this.durataS,
      stile: data.stile.present ? data.stile.value : this.stile,
      esecuzione: data.esecuzione.present
          ? data.esecuzione.value
          : this.esecuzione,
      zona: data.zona.present ? data.zona.value : this.zona,
      passoObiettivoS: data.passoObiettivoS.present
          ? data.passoObiettivoS.value
          : this.passoObiettivoS,
      recuperoS: data.recuperoS.present ? data.recuperoS.value : this.recuperoS,
      ripartenzaS: data.ripartenzaS.present
          ? data.ripartenzaS.value
          : this.ripartenzaS,
      attrezzatura: data.attrezzatura.present
          ? data.attrezzatura.value
          : this.attrezzatura,
      note: data.note.present ? data.note.value : this.note,
      piramideId: data.piramideId.present
          ? data.piramideId.value
          : this.piramideId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SerieTableData(')
          ..write('id: $id, ')
          ..write('allenamentoId: $allenamentoId, ')
          ..write('clubId: $clubId, ')
          ..write('ordine: $ordine, ')
          ..write('blocco: $blocco, ')
          ..write('ripetute: $ripetute, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('durataS: $durataS, ')
          ..write('stile: $stile, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('zona: $zona, ')
          ..write('passoObiettivoS: $passoObiettivoS, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('ripartenzaS: $ripartenzaS, ')
          ..write('attrezzatura: $attrezzatura, ')
          ..write('note: $note, ')
          ..write('piramideId: $piramideId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    allenamentoId,
    clubId,
    ordine,
    blocco,
    ripetute,
    distanzaM,
    durataS,
    stile,
    esecuzione,
    zona,
    passoObiettivoS,
    recuperoS,
    ripartenzaS,
    attrezzatura,
    note,
    piramideId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SerieTableData &&
          other.id == this.id &&
          other.allenamentoId == this.allenamentoId &&
          other.clubId == this.clubId &&
          other.ordine == this.ordine &&
          other.blocco == this.blocco &&
          other.ripetute == this.ripetute &&
          other.distanzaM == this.distanzaM &&
          other.durataS == this.durataS &&
          other.stile == this.stile &&
          other.esecuzione == this.esecuzione &&
          other.zona == this.zona &&
          other.passoObiettivoS == this.passoObiettivoS &&
          other.recuperoS == this.recuperoS &&
          other.ripartenzaS == this.ripartenzaS &&
          other.attrezzatura == this.attrezzatura &&
          other.note == this.note &&
          other.piramideId == this.piramideId);
}

class SerieTableCompanion extends UpdateCompanion<SerieTableData> {
  final Value<String> id;
  final Value<String> allenamentoId;
  final Value<String> clubId;
  final Value<int> ordine;
  final Value<String> blocco;
  final Value<int> ripetute;
  final Value<int?> distanzaM;
  final Value<int?> durataS;
  final Value<String> stile;
  final Value<String> esecuzione;
  final Value<String?> zona;
  final Value<double?> passoObiettivoS;
  final Value<int?> recuperoS;
  final Value<double?> ripartenzaS;
  final Value<String?> attrezzatura;
  final Value<String?> note;
  final Value<String?> piramideId;
  final Value<int> rowid;
  const SerieTableCompanion({
    this.id = const Value.absent(),
    this.allenamentoId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.ordine = const Value.absent(),
    this.blocco = const Value.absent(),
    this.ripetute = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.durataS = const Value.absent(),
    this.stile = const Value.absent(),
    this.esecuzione = const Value.absent(),
    this.zona = const Value.absent(),
    this.passoObiettivoS = const Value.absent(),
    this.recuperoS = const Value.absent(),
    this.ripartenzaS = const Value.absent(),
    this.attrezzatura = const Value.absent(),
    this.note = const Value.absent(),
    this.piramideId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SerieTableCompanion.insert({
    required String id,
    required String allenamentoId,
    required String clubId,
    required int ordine,
    required String blocco,
    required int ripetute,
    this.distanzaM = const Value.absent(),
    this.durataS = const Value.absent(),
    required String stile,
    required String esecuzione,
    this.zona = const Value.absent(),
    this.passoObiettivoS = const Value.absent(),
    this.recuperoS = const Value.absent(),
    this.ripartenzaS = const Value.absent(),
    this.attrezzatura = const Value.absent(),
    this.note = const Value.absent(),
    this.piramideId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       allenamentoId = Value(allenamentoId),
       clubId = Value(clubId),
       ordine = Value(ordine),
       blocco = Value(blocco),
       ripetute = Value(ripetute),
       stile = Value(stile),
       esecuzione = Value(esecuzione);
  static Insertable<SerieTableData> custom({
    Expression<String>? id,
    Expression<String>? allenamentoId,
    Expression<String>? clubId,
    Expression<int>? ordine,
    Expression<String>? blocco,
    Expression<int>? ripetute,
    Expression<int>? distanzaM,
    Expression<int>? durataS,
    Expression<String>? stile,
    Expression<String>? esecuzione,
    Expression<String>? zona,
    Expression<double>? passoObiettivoS,
    Expression<int>? recuperoS,
    Expression<double>? ripartenzaS,
    Expression<String>? attrezzatura,
    Expression<String>? note,
    Expression<String>? piramideId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (allenamentoId != null) 'allenamento_id': allenamentoId,
      if (clubId != null) 'club_id': clubId,
      if (ordine != null) 'ordine': ordine,
      if (blocco != null) 'blocco': blocco,
      if (ripetute != null) 'ripetute': ripetute,
      if (distanzaM != null) 'distanza_m': distanzaM,
      if (durataS != null) 'durata_s': durataS,
      if (stile != null) 'stile': stile,
      if (esecuzione != null) 'esecuzione': esecuzione,
      if (zona != null) 'zona': zona,
      if (passoObiettivoS != null) 'passo_obiettivo_s': passoObiettivoS,
      if (recuperoS != null) 'recupero_s': recuperoS,
      if (ripartenzaS != null) 'ripartenza_s': ripartenzaS,
      if (attrezzatura != null) 'attrezzatura': attrezzatura,
      if (note != null) 'note': note,
      if (piramideId != null) 'piramide_id': piramideId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SerieTableCompanion copyWith({
    Value<String>? id,
    Value<String>? allenamentoId,
    Value<String>? clubId,
    Value<int>? ordine,
    Value<String>? blocco,
    Value<int>? ripetute,
    Value<int?>? distanzaM,
    Value<int?>? durataS,
    Value<String>? stile,
    Value<String>? esecuzione,
    Value<String?>? zona,
    Value<double?>? passoObiettivoS,
    Value<int?>? recuperoS,
    Value<double?>? ripartenzaS,
    Value<String?>? attrezzatura,
    Value<String?>? note,
    Value<String?>? piramideId,
    Value<int>? rowid,
  }) {
    return SerieTableCompanion(
      id: id ?? this.id,
      allenamentoId: allenamentoId ?? this.allenamentoId,
      clubId: clubId ?? this.clubId,
      ordine: ordine ?? this.ordine,
      blocco: blocco ?? this.blocco,
      ripetute: ripetute ?? this.ripetute,
      distanzaM: distanzaM ?? this.distanzaM,
      durataS: durataS ?? this.durataS,
      stile: stile ?? this.stile,
      esecuzione: esecuzione ?? this.esecuzione,
      zona: zona ?? this.zona,
      passoObiettivoS: passoObiettivoS ?? this.passoObiettivoS,
      recuperoS: recuperoS ?? this.recuperoS,
      ripartenzaS: ripartenzaS ?? this.ripartenzaS,
      attrezzatura: attrezzatura ?? this.attrezzatura,
      note: note ?? this.note,
      piramideId: piramideId ?? this.piramideId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (allenamentoId.present) {
      map['allenamento_id'] = Variable<String>(allenamentoId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (blocco.present) {
      map['blocco'] = Variable<String>(blocco.value);
    }
    if (ripetute.present) {
      map['ripetute'] = Variable<int>(ripetute.value);
    }
    if (distanzaM.present) {
      map['distanza_m'] = Variable<int>(distanzaM.value);
    }
    if (durataS.present) {
      map['durata_s'] = Variable<int>(durataS.value);
    }
    if (stile.present) {
      map['stile'] = Variable<String>(stile.value);
    }
    if (esecuzione.present) {
      map['esecuzione'] = Variable<String>(esecuzione.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (passoObiettivoS.present) {
      map['passo_obiettivo_s'] = Variable<double>(passoObiettivoS.value);
    }
    if (recuperoS.present) {
      map['recupero_s'] = Variable<int>(recuperoS.value);
    }
    if (ripartenzaS.present) {
      map['ripartenza_s'] = Variable<double>(ripartenzaS.value);
    }
    if (attrezzatura.present) {
      map['attrezzatura'] = Variable<String>(attrezzatura.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (piramideId.present) {
      map['piramide_id'] = Variable<String>(piramideId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SerieTableCompanion(')
          ..write('id: $id, ')
          ..write('allenamentoId: $allenamentoId, ')
          ..write('clubId: $clubId, ')
          ..write('ordine: $ordine, ')
          ..write('blocco: $blocco, ')
          ..write('ripetute: $ripetute, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('durataS: $durataS, ')
          ..write('stile: $stile, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('zona: $zona, ')
          ..write('passoObiettivoS: $passoObiettivoS, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('ripartenzaS: $ripartenzaS, ')
          ..write('attrezzatura: $attrezzatura, ')
          ..write('note: $note, ')
          ..write('piramideId: $piramideId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresenzeTableTable extends PresenzeTable
    with TableInfo<$PresenzeTableTable, PresenzeTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresenzeTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allenamentoIdMeta = const VerificationMeta(
    'allenamentoId',
  );
  @override
  late final GeneratedColumn<String> allenamentoId = GeneratedColumn<String>(
    'allenamento_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statoMeta = const VerificationMeta('stato');
  @override
  late final GeneratedColumn<String> stato = GeneratedColumn<String>(
    'stato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    allenamentoId,
    atletaId,
    clubId,
    stato,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presenze_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresenzeTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('allenamento_id')) {
      context.handle(
        _allenamentoIdMeta,
        allenamentoId.isAcceptableOrUnknown(
          data['allenamento_id']!,
          _allenamentoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allenamentoIdMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('stato')) {
      context.handle(
        _statoMeta,
        stato.isAcceptableOrUnknown(data['stato']!, _statoMeta),
      );
    } else if (isInserting) {
      context.missing(_statoMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresenzeTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresenzeTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      allenamentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allenamento_id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      stato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stato'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PresenzeTableTable createAlias(String alias) {
    return $PresenzeTableTable(attachedDatabase, alias);
  }
}

class PresenzeTableData extends DataClass
    implements Insertable<PresenzeTableData> {
  final String id;
  final String allenamentoId;
  final String atletaId;
  final String clubId;
  final String stato;
  final String? note;
  const PresenzeTableData({
    required this.id,
    required this.allenamentoId,
    required this.atletaId,
    required this.clubId,
    required this.stato,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['allenamento_id'] = Variable<String>(allenamentoId);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['stato'] = Variable<String>(stato);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PresenzeTableCompanion toCompanion(bool nullToAbsent) {
    return PresenzeTableCompanion(
      id: Value(id),
      allenamentoId: Value(allenamentoId),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      stato: Value(stato),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PresenzeTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresenzeTableData(
      id: serializer.fromJson<String>(json['id']),
      allenamentoId: serializer.fromJson<String>(json['allenamentoId']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      stato: serializer.fromJson<String>(json['stato']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'allenamentoId': serializer.toJson<String>(allenamentoId),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'stato': serializer.toJson<String>(stato),
      'note': serializer.toJson<String?>(note),
    };
  }

  PresenzeTableData copyWith({
    String? id,
    String? allenamentoId,
    String? atletaId,
    String? clubId,
    String? stato,
    Value<String?> note = const Value.absent(),
  }) => PresenzeTableData(
    id: id ?? this.id,
    allenamentoId: allenamentoId ?? this.allenamentoId,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    stato: stato ?? this.stato,
    note: note.present ? note.value : this.note,
  );
  PresenzeTableData copyWithCompanion(PresenzeTableCompanion data) {
    return PresenzeTableData(
      id: data.id.present ? data.id.value : this.id,
      allenamentoId: data.allenamentoId.present
          ? data.allenamentoId.value
          : this.allenamentoId,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      stato: data.stato.present ? data.stato.value : this.stato,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresenzeTableData(')
          ..write('id: $id, ')
          ..write('allenamentoId: $allenamentoId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stato: $stato, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, allenamentoId, atletaId, clubId, stato, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresenzeTableData &&
          other.id == this.id &&
          other.allenamentoId == this.allenamentoId &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.stato == this.stato &&
          other.note == this.note);
}

class PresenzeTableCompanion extends UpdateCompanion<PresenzeTableData> {
  final Value<String> id;
  final Value<String> allenamentoId;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<String> stato;
  final Value<String?> note;
  final Value<int> rowid;
  const PresenzeTableCompanion({
    this.id = const Value.absent(),
    this.allenamentoId = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.stato = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresenzeTableCompanion.insert({
    required String id,
    required String allenamentoId,
    required String atletaId,
    required String clubId,
    required String stato,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       allenamentoId = Value(allenamentoId),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       stato = Value(stato);
  static Insertable<PresenzeTableData> custom({
    Expression<String>? id,
    Expression<String>? allenamentoId,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<String>? stato,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (allenamentoId != null) 'allenamento_id': allenamentoId,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (stato != null) 'stato': stato,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresenzeTableCompanion copyWith({
    Value<String>? id,
    Value<String>? allenamentoId,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<String>? stato,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PresenzeTableCompanion(
      id: id ?? this.id,
      allenamentoId: allenamentoId ?? this.allenamentoId,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      stato: stato ?? this.stato,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (allenamentoId.present) {
      map['allenamento_id'] = Variable<String>(allenamentoId.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (stato.present) {
      map['stato'] = Variable<String>(stato.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresenzeTableCompanion(')
          ..write('id: $id, ')
          ..write('allenamentoId: $allenamentoId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('stato: $stato, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTableTable extends PendingOperationsTable
    with TableInfo<$PendingOperationsTableTable, PendingOperationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tabellaMeta = const VerificationMeta(
    'tabella',
  );
  @override
  late final GeneratedColumn<String> tabella = GeneratedColumn<String>(
    'tabella',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operazioneMeta = const VerificationMeta(
    'operazione',
  );
  @override
  late final GeneratedColumn<String> operazione = GeneratedColumn<String>(
    'operazione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rigaIdMeta = const VerificationMeta('rigaId');
  @override
  late final GeneratedColumn<String> rigaId = GeneratedColumn<String>(
    'riga_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatoIlMeta = const VerificationMeta(
    'creatoIl',
  );
  @override
  late final GeneratedColumn<DateTime> creatoIl = GeneratedColumn<DateTime>(
    'creato_il',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tabella,
    operazione,
    rigaId,
    payloadJson,
    creatoIl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tabella')) {
      context.handle(
        _tabellaMeta,
        tabella.isAcceptableOrUnknown(data['tabella']!, _tabellaMeta),
      );
    } else if (isInserting) {
      context.missing(_tabellaMeta);
    }
    if (data.containsKey('operazione')) {
      context.handle(
        _operazioneMeta,
        operazione.isAcceptableOrUnknown(data['operazione']!, _operazioneMeta),
      );
    } else if (isInserting) {
      context.missing(_operazioneMeta);
    }
    if (data.containsKey('riga_id')) {
      context.handle(
        _rigaIdMeta,
        rigaId.isAcceptableOrUnknown(data['riga_id']!, _rigaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rigaIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('creato_il')) {
      context.handle(
        _creatoIlMeta,
        creatoIl.isAcceptableOrUnknown(data['creato_il']!, _creatoIlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperationsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tabella: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tabella'],
      )!,
      operazione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operazione'],
      )!,
      rigaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}riga_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      creatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creato_il'],
      )!,
    );
  }

  @override
  $PendingOperationsTableTable createAlias(String alias) {
    return $PendingOperationsTableTable(attachedDatabase, alias);
  }
}

class PendingOperationsTableData extends DataClass
    implements Insertable<PendingOperationsTableData> {
  final int id;
  final String tabella;
  final String operazione;
  final String rigaId;
  final String? payloadJson;
  final DateTime creatoIl;
  const PendingOperationsTableData({
    required this.id,
    required this.tabella,
    required this.operazione,
    required this.rigaId,
    this.payloadJson,
    required this.creatoIl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tabella'] = Variable<String>(tabella);
    map['operazione'] = Variable<String>(operazione);
    map['riga_id'] = Variable<String>(rigaId);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['creato_il'] = Variable<DateTime>(creatoIl);
    return map;
  }

  PendingOperationsTableCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsTableCompanion(
      id: Value(id),
      tabella: Value(tabella),
      operazione: Value(operazione),
      rigaId: Value(rigaId),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      creatoIl: Value(creatoIl),
    );
  }

  factory PendingOperationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperationsTableData(
      id: serializer.fromJson<int>(json['id']),
      tabella: serializer.fromJson<String>(json['tabella']),
      operazione: serializer.fromJson<String>(json['operazione']),
      rigaId: serializer.fromJson<String>(json['rigaId']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      creatoIl: serializer.fromJson<DateTime>(json['creatoIl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tabella': serializer.toJson<String>(tabella),
      'operazione': serializer.toJson<String>(operazione),
      'rigaId': serializer.toJson<String>(rigaId),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'creatoIl': serializer.toJson<DateTime>(creatoIl),
    };
  }

  PendingOperationsTableData copyWith({
    int? id,
    String? tabella,
    String? operazione,
    String? rigaId,
    Value<String?> payloadJson = const Value.absent(),
    DateTime? creatoIl,
  }) => PendingOperationsTableData(
    id: id ?? this.id,
    tabella: tabella ?? this.tabella,
    operazione: operazione ?? this.operazione,
    rigaId: rigaId ?? this.rigaId,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    creatoIl: creatoIl ?? this.creatoIl,
  );
  PendingOperationsTableData copyWithCompanion(
    PendingOperationsTableCompanion data,
  ) {
    return PendingOperationsTableData(
      id: data.id.present ? data.id.value : this.id,
      tabella: data.tabella.present ? data.tabella.value : this.tabella,
      operazione: data.operazione.present
          ? data.operazione.value
          : this.operazione,
      rigaId: data.rigaId.present ? data.rigaId.value : this.rigaId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      creatoIl: data.creatoIl.present ? data.creatoIl.value : this.creatoIl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsTableData(')
          ..write('id: $id, ')
          ..write('tabella: $tabella, ')
          ..write('operazione: $operazione, ')
          ..write('rigaId: $rigaId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('creatoIl: $creatoIl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tabella, operazione, rigaId, payloadJson, creatoIl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperationsTableData &&
          other.id == this.id &&
          other.tabella == this.tabella &&
          other.operazione == this.operazione &&
          other.rigaId == this.rigaId &&
          other.payloadJson == this.payloadJson &&
          other.creatoIl == this.creatoIl);
}

class PendingOperationsTableCompanion
    extends UpdateCompanion<PendingOperationsTableData> {
  final Value<int> id;
  final Value<String> tabella;
  final Value<String> operazione;
  final Value<String> rigaId;
  final Value<String?> payloadJson;
  final Value<DateTime> creatoIl;
  const PendingOperationsTableCompanion({
    this.id = const Value.absent(),
    this.tabella = const Value.absent(),
    this.operazione = const Value.absent(),
    this.rigaId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.creatoIl = const Value.absent(),
  });
  PendingOperationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String tabella,
    required String operazione,
    required String rigaId,
    this.payloadJson = const Value.absent(),
    this.creatoIl = const Value.absent(),
  }) : tabella = Value(tabella),
       operazione = Value(operazione),
       rigaId = Value(rigaId);
  static Insertable<PendingOperationsTableData> custom({
    Expression<int>? id,
    Expression<String>? tabella,
    Expression<String>? operazione,
    Expression<String>? rigaId,
    Expression<String>? payloadJson,
    Expression<DateTime>? creatoIl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tabella != null) 'tabella': tabella,
      if (operazione != null) 'operazione': operazione,
      if (rigaId != null) 'riga_id': rigaId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (creatoIl != null) 'creato_il': creatoIl,
    });
  }

  PendingOperationsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? tabella,
    Value<String>? operazione,
    Value<String>? rigaId,
    Value<String?>? payloadJson,
    Value<DateTime>? creatoIl,
  }) {
    return PendingOperationsTableCompanion(
      id: id ?? this.id,
      tabella: tabella ?? this.tabella,
      operazione: operazione ?? this.operazione,
      rigaId: rigaId ?? this.rigaId,
      payloadJson: payloadJson ?? this.payloadJson,
      creatoIl: creatoIl ?? this.creatoIl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tabella.present) {
      map['tabella'] = Variable<String>(tabella.value);
    }
    if (operazione.present) {
      map['operazione'] = Variable<String>(operazione.value);
    }
    if (rigaId.present) {
      map['riga_id'] = Variable<String>(rigaId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (creatoIl.present) {
      map['creato_il'] = Variable<DateTime>(creatoIl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsTableCompanion(')
          ..write('id: $id, ')
          ..write('tabella: $tabella, ')
          ..write('operazione: $operazione, ')
          ..write('rigaId: $rigaId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('creatoIl: $creatoIl')
          ..write(')'))
        .toString();
  }
}

class $PartiteTableTable extends PartiteTable
    with TableInfo<$PartiteTableTable, PartiteTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartiteTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gruppoIdMeta = const VerificationMeta(
    'gruppoId',
  );
  @override
  late final GeneratedColumn<String> gruppoId = GeneratedColumn<String>(
    'gruppo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oraMeta = const VerificationMeta('ora');
  @override
  late final GeneratedColumn<String> ora = GeneratedColumn<String>(
    'ora',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _luogoMeta = const VerificationMeta('luogo');
  @override
  late final GeneratedColumn<String> luogo = GeneratedColumn<String>(
    'luogo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _campionatoMeta = const VerificationMeta(
    'campionato',
  );
  @override
  late final GeneratedColumn<String> campionato = GeneratedColumn<String>(
    'campionato',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coloreCalottinaMeta = const VerificationMeta(
    'coloreCalottina',
  );
  @override
  late final GeneratedColumn<String> coloreCalottina = GeneratedColumn<String>(
    'colore_calottina',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _squadraCasaMeta = const VerificationMeta(
    'squadraCasa',
  );
  @override
  late final GeneratedColumn<String> squadraCasa = GeneratedColumn<String>(
    'squadra_casa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _squadraTrasfertaMeta = const VerificationMeta(
    'squadraTrasferta',
  );
  @override
  late final GeneratedColumn<String> squadraTrasferta = GeneratedColumn<String>(
    'squadra_trasferta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroMaxConvocatiMeta =
      const VerificationMeta('numeroMaxConvocati');
  @override
  late final GeneratedColumn<int> numeroMaxConvocati = GeneratedColumn<int>(
    'numero_max_convocati',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dettaglioTiroMeta = const VerificationMeta(
    'dettaglioTiro',
  );
  @override
  late final GeneratedColumn<String> dettaglioTiro = GeneratedColumn<String>(
    'dettaglio_tiro',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('semplice'),
  );
  static const VerificationMeta _tracciaTempoMeta = const VerificationMeta(
    'tracciaTempo',
  );
  @override
  late final GeneratedColumn<bool> tracciaTempo = GeneratedColumn<bool>(
    'traccia_tempo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("traccia_tempo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _modalitaSuperioritaMeta =
      const VerificationMeta('modalitaSuperiorita');
  @override
  late final GeneratedColumn<String> modalitaSuperiorita =
      GeneratedColumn<String>(
        'modalita_superiorita',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('singolo'),
      );
  static const VerificationMeta _nostraSquadraMeta = const VerificationMeta(
    'nostraSquadra',
  );
  @override
  late final GeneratedColumn<String> nostraSquadra = GeneratedColumn<String>(
    'nostra_squadra',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('casa'),
  );
  static const VerificationMeta _importanzaMeta = const VerificationMeta(
    'importanza',
  );
  @override
  late final GeneratedColumn<String> importanza = GeneratedColumn<String>(
    'importanza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('media'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    gruppoId,
    data,
    ora,
    luogo,
    campionato,
    coloreCalottina,
    squadraCasa,
    squadraTrasferta,
    numeroMaxConvocati,
    note,
    dettaglioTiro,
    tracciaTempo,
    modalitaSuperiorita,
    nostraSquadra,
    importanza,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'partite_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PartiteTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('gruppo_id')) {
      context.handle(
        _gruppoIdMeta,
        gruppoId.isAcceptableOrUnknown(data['gruppo_id']!, _gruppoIdMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('ora')) {
      context.handle(
        _oraMeta,
        ora.isAcceptableOrUnknown(data['ora']!, _oraMeta),
      );
    }
    if (data.containsKey('luogo')) {
      context.handle(
        _luogoMeta,
        luogo.isAcceptableOrUnknown(data['luogo']!, _luogoMeta),
      );
    }
    if (data.containsKey('campionato')) {
      context.handle(
        _campionatoMeta,
        campionato.isAcceptableOrUnknown(data['campionato']!, _campionatoMeta),
      );
    }
    if (data.containsKey('colore_calottina')) {
      context.handle(
        _coloreCalottinaMeta,
        coloreCalottina.isAcceptableOrUnknown(
          data['colore_calottina']!,
          _coloreCalottinaMeta,
        ),
      );
    }
    if (data.containsKey('squadra_casa')) {
      context.handle(
        _squadraCasaMeta,
        squadraCasa.isAcceptableOrUnknown(
          data['squadra_casa']!,
          _squadraCasaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_squadraCasaMeta);
    }
    if (data.containsKey('squadra_trasferta')) {
      context.handle(
        _squadraTrasfertaMeta,
        squadraTrasferta.isAcceptableOrUnknown(
          data['squadra_trasferta']!,
          _squadraTrasfertaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_squadraTrasfertaMeta);
    }
    if (data.containsKey('numero_max_convocati')) {
      context.handle(
        _numeroMaxConvocatiMeta,
        numeroMaxConvocati.isAcceptableOrUnknown(
          data['numero_max_convocati']!,
          _numeroMaxConvocatiMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('dettaglio_tiro')) {
      context.handle(
        _dettaglioTiroMeta,
        dettaglioTiro.isAcceptableOrUnknown(
          data['dettaglio_tiro']!,
          _dettaglioTiroMeta,
        ),
      );
    }
    if (data.containsKey('traccia_tempo')) {
      context.handle(
        _tracciaTempoMeta,
        tracciaTempo.isAcceptableOrUnknown(
          data['traccia_tempo']!,
          _tracciaTempoMeta,
        ),
      );
    }
    if (data.containsKey('modalita_superiorita')) {
      context.handle(
        _modalitaSuperioritaMeta,
        modalitaSuperiorita.isAcceptableOrUnknown(
          data['modalita_superiorita']!,
          _modalitaSuperioritaMeta,
        ),
      );
    }
    if (data.containsKey('nostra_squadra')) {
      context.handle(
        _nostraSquadraMeta,
        nostraSquadra.isAcceptableOrUnknown(
          data['nostra_squadra']!,
          _nostraSquadraMeta,
        ),
      );
    }
    if (data.containsKey('importanza')) {
      context.handle(
        _importanzaMeta,
        importanza.isAcceptableOrUnknown(data['importanza']!, _importanzaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartiteTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartiteTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      gruppoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_id'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      ora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ora'],
      ),
      luogo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}luogo'],
      ),
      campionato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campionato'],
      ),
      coloreCalottina: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colore_calottina'],
      ),
      squadraCasa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}squadra_casa'],
      )!,
      squadraTrasferta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}squadra_trasferta'],
      )!,
      numeroMaxConvocati: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_max_convocati'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      dettaglioTiro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dettaglio_tiro'],
      )!,
      tracciaTempo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}traccia_tempo'],
      )!,
      modalitaSuperiorita: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modalita_superiorita'],
      )!,
      nostraSquadra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nostra_squadra'],
      )!,
      importanza: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}importanza'],
      )!,
    );
  }

  @override
  $PartiteTableTable createAlias(String alias) {
    return $PartiteTableTable(attachedDatabase, alias);
  }
}

class PartiteTableData extends DataClass
    implements Insertable<PartiteTableData> {
  final String id;
  final String clubId;

  /// Gruppo di allenamento (squadra) a cui appartiene la partita — null
  /// se condivisa con tutto il club.
  final String? gruppoId;
  final DateTime data;
  final String? ora;
  final String? luogo;
  final String? campionato;
  final String? coloreCalottina;
  final String squadraCasa;
  final String squadraTrasferta;
  final int numeroMaxConvocati;
  final String? note;
  final String dettaglioTiro;
  final bool tracciaTempo;
  final String modalitaSuperiorita;
  final String nostraSquadra;

  /// bassa | media | alta — lo scarico pre-partita del generatore
  /// settimanale (FASE 3) scatta solo per "alta".
  final String importanza;
  const PartiteTableData({
    required this.id,
    required this.clubId,
    this.gruppoId,
    required this.data,
    this.ora,
    this.luogo,
    this.campionato,
    this.coloreCalottina,
    required this.squadraCasa,
    required this.squadraTrasferta,
    required this.numeroMaxConvocati,
    this.note,
    required this.dettaglioTiro,
    required this.tracciaTempo,
    required this.modalitaSuperiorita,
    required this.nostraSquadra,
    required this.importanza,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    if (!nullToAbsent || gruppoId != null) {
      map['gruppo_id'] = Variable<String>(gruppoId);
    }
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || ora != null) {
      map['ora'] = Variable<String>(ora);
    }
    if (!nullToAbsent || luogo != null) {
      map['luogo'] = Variable<String>(luogo);
    }
    if (!nullToAbsent || campionato != null) {
      map['campionato'] = Variable<String>(campionato);
    }
    if (!nullToAbsent || coloreCalottina != null) {
      map['colore_calottina'] = Variable<String>(coloreCalottina);
    }
    map['squadra_casa'] = Variable<String>(squadraCasa);
    map['squadra_trasferta'] = Variable<String>(squadraTrasferta);
    map['numero_max_convocati'] = Variable<int>(numeroMaxConvocati);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['dettaglio_tiro'] = Variable<String>(dettaglioTiro);
    map['traccia_tempo'] = Variable<bool>(tracciaTempo);
    map['modalita_superiorita'] = Variable<String>(modalitaSuperiorita);
    map['nostra_squadra'] = Variable<String>(nostraSquadra);
    map['importanza'] = Variable<String>(importanza);
    return map;
  }

  PartiteTableCompanion toCompanion(bool nullToAbsent) {
    return PartiteTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      gruppoId: gruppoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppoId),
      data: Value(data),
      ora: ora == null && nullToAbsent ? const Value.absent() : Value(ora),
      luogo: luogo == null && nullToAbsent
          ? const Value.absent()
          : Value(luogo),
      campionato: campionato == null && nullToAbsent
          ? const Value.absent()
          : Value(campionato),
      coloreCalottina: coloreCalottina == null && nullToAbsent
          ? const Value.absent()
          : Value(coloreCalottina),
      squadraCasa: Value(squadraCasa),
      squadraTrasferta: Value(squadraTrasferta),
      numeroMaxConvocati: Value(numeroMaxConvocati),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      dettaglioTiro: Value(dettaglioTiro),
      tracciaTempo: Value(tracciaTempo),
      modalitaSuperiorita: Value(modalitaSuperiorita),
      nostraSquadra: Value(nostraSquadra),
      importanza: Value(importanza),
    );
  }

  factory PartiteTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartiteTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      gruppoId: serializer.fromJson<String?>(json['gruppoId']),
      data: serializer.fromJson<DateTime>(json['data']),
      ora: serializer.fromJson<String?>(json['ora']),
      luogo: serializer.fromJson<String?>(json['luogo']),
      campionato: serializer.fromJson<String?>(json['campionato']),
      coloreCalottina: serializer.fromJson<String?>(json['coloreCalottina']),
      squadraCasa: serializer.fromJson<String>(json['squadraCasa']),
      squadraTrasferta: serializer.fromJson<String>(json['squadraTrasferta']),
      numeroMaxConvocati: serializer.fromJson<int>(json['numeroMaxConvocati']),
      note: serializer.fromJson<String?>(json['note']),
      dettaglioTiro: serializer.fromJson<String>(json['dettaglioTiro']),
      tracciaTempo: serializer.fromJson<bool>(json['tracciaTempo']),
      modalitaSuperiorita: serializer.fromJson<String>(
        json['modalitaSuperiorita'],
      ),
      nostraSquadra: serializer.fromJson<String>(json['nostraSquadra']),
      importanza: serializer.fromJson<String>(json['importanza']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'gruppoId': serializer.toJson<String?>(gruppoId),
      'data': serializer.toJson<DateTime>(data),
      'ora': serializer.toJson<String?>(ora),
      'luogo': serializer.toJson<String?>(luogo),
      'campionato': serializer.toJson<String?>(campionato),
      'coloreCalottina': serializer.toJson<String?>(coloreCalottina),
      'squadraCasa': serializer.toJson<String>(squadraCasa),
      'squadraTrasferta': serializer.toJson<String>(squadraTrasferta),
      'numeroMaxConvocati': serializer.toJson<int>(numeroMaxConvocati),
      'note': serializer.toJson<String?>(note),
      'dettaglioTiro': serializer.toJson<String>(dettaglioTiro),
      'tracciaTempo': serializer.toJson<bool>(tracciaTempo),
      'modalitaSuperiorita': serializer.toJson<String>(modalitaSuperiorita),
      'nostraSquadra': serializer.toJson<String>(nostraSquadra),
      'importanza': serializer.toJson<String>(importanza),
    };
  }

  PartiteTableData copyWith({
    String? id,
    String? clubId,
    Value<String?> gruppoId = const Value.absent(),
    DateTime? data,
    Value<String?> ora = const Value.absent(),
    Value<String?> luogo = const Value.absent(),
    Value<String?> campionato = const Value.absent(),
    Value<String?> coloreCalottina = const Value.absent(),
    String? squadraCasa,
    String? squadraTrasferta,
    int? numeroMaxConvocati,
    Value<String?> note = const Value.absent(),
    String? dettaglioTiro,
    bool? tracciaTempo,
    String? modalitaSuperiorita,
    String? nostraSquadra,
    String? importanza,
  }) => PartiteTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    gruppoId: gruppoId.present ? gruppoId.value : this.gruppoId,
    data: data ?? this.data,
    ora: ora.present ? ora.value : this.ora,
    luogo: luogo.present ? luogo.value : this.luogo,
    campionato: campionato.present ? campionato.value : this.campionato,
    coloreCalottina: coloreCalottina.present
        ? coloreCalottina.value
        : this.coloreCalottina,
    squadraCasa: squadraCasa ?? this.squadraCasa,
    squadraTrasferta: squadraTrasferta ?? this.squadraTrasferta,
    numeroMaxConvocati: numeroMaxConvocati ?? this.numeroMaxConvocati,
    note: note.present ? note.value : this.note,
    dettaglioTiro: dettaglioTiro ?? this.dettaglioTiro,
    tracciaTempo: tracciaTempo ?? this.tracciaTempo,
    modalitaSuperiorita: modalitaSuperiorita ?? this.modalitaSuperiorita,
    nostraSquadra: nostraSquadra ?? this.nostraSquadra,
    importanza: importanza ?? this.importanza,
  );
  PartiteTableData copyWithCompanion(PartiteTableCompanion data) {
    return PartiteTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      gruppoId: data.gruppoId.present ? data.gruppoId.value : this.gruppoId,
      data: data.data.present ? data.data.value : this.data,
      ora: data.ora.present ? data.ora.value : this.ora,
      luogo: data.luogo.present ? data.luogo.value : this.luogo,
      campionato: data.campionato.present
          ? data.campionato.value
          : this.campionato,
      coloreCalottina: data.coloreCalottina.present
          ? data.coloreCalottina.value
          : this.coloreCalottina,
      squadraCasa: data.squadraCasa.present
          ? data.squadraCasa.value
          : this.squadraCasa,
      squadraTrasferta: data.squadraTrasferta.present
          ? data.squadraTrasferta.value
          : this.squadraTrasferta,
      numeroMaxConvocati: data.numeroMaxConvocati.present
          ? data.numeroMaxConvocati.value
          : this.numeroMaxConvocati,
      note: data.note.present ? data.note.value : this.note,
      dettaglioTiro: data.dettaglioTiro.present
          ? data.dettaglioTiro.value
          : this.dettaglioTiro,
      tracciaTempo: data.tracciaTempo.present
          ? data.tracciaTempo.value
          : this.tracciaTempo,
      modalitaSuperiorita: data.modalitaSuperiorita.present
          ? data.modalitaSuperiorita.value
          : this.modalitaSuperiorita,
      nostraSquadra: data.nostraSquadra.present
          ? data.nostraSquadra.value
          : this.nostraSquadra,
      importanza: data.importanza.present
          ? data.importanza.value
          : this.importanza,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartiteTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('data: $data, ')
          ..write('ora: $ora, ')
          ..write('luogo: $luogo, ')
          ..write('campionato: $campionato, ')
          ..write('coloreCalottina: $coloreCalottina, ')
          ..write('squadraCasa: $squadraCasa, ')
          ..write('squadraTrasferta: $squadraTrasferta, ')
          ..write('numeroMaxConvocati: $numeroMaxConvocati, ')
          ..write('note: $note, ')
          ..write('dettaglioTiro: $dettaglioTiro, ')
          ..write('tracciaTempo: $tracciaTempo, ')
          ..write('modalitaSuperiorita: $modalitaSuperiorita, ')
          ..write('nostraSquadra: $nostraSquadra, ')
          ..write('importanza: $importanza')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    gruppoId,
    data,
    ora,
    luogo,
    campionato,
    coloreCalottina,
    squadraCasa,
    squadraTrasferta,
    numeroMaxConvocati,
    note,
    dettaglioTiro,
    tracciaTempo,
    modalitaSuperiorita,
    nostraSquadra,
    importanza,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartiteTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.gruppoId == this.gruppoId &&
          other.data == this.data &&
          other.ora == this.ora &&
          other.luogo == this.luogo &&
          other.campionato == this.campionato &&
          other.coloreCalottina == this.coloreCalottina &&
          other.squadraCasa == this.squadraCasa &&
          other.squadraTrasferta == this.squadraTrasferta &&
          other.numeroMaxConvocati == this.numeroMaxConvocati &&
          other.note == this.note &&
          other.dettaglioTiro == this.dettaglioTiro &&
          other.tracciaTempo == this.tracciaTempo &&
          other.modalitaSuperiorita == this.modalitaSuperiorita &&
          other.nostraSquadra == this.nostraSquadra &&
          other.importanza == this.importanza);
}

class PartiteTableCompanion extends UpdateCompanion<PartiteTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String?> gruppoId;
  final Value<DateTime> data;
  final Value<String?> ora;
  final Value<String?> luogo;
  final Value<String?> campionato;
  final Value<String?> coloreCalottina;
  final Value<String> squadraCasa;
  final Value<String> squadraTrasferta;
  final Value<int> numeroMaxConvocati;
  final Value<String?> note;
  final Value<String> dettaglioTiro;
  final Value<bool> tracciaTempo;
  final Value<String> modalitaSuperiorita;
  final Value<String> nostraSquadra;
  final Value<String> importanza;
  final Value<int> rowid;
  const PartiteTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.data = const Value.absent(),
    this.ora = const Value.absent(),
    this.luogo = const Value.absent(),
    this.campionato = const Value.absent(),
    this.coloreCalottina = const Value.absent(),
    this.squadraCasa = const Value.absent(),
    this.squadraTrasferta = const Value.absent(),
    this.numeroMaxConvocati = const Value.absent(),
    this.note = const Value.absent(),
    this.dettaglioTiro = const Value.absent(),
    this.tracciaTempo = const Value.absent(),
    this.modalitaSuperiorita = const Value.absent(),
    this.nostraSquadra = const Value.absent(),
    this.importanza = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartiteTableCompanion.insert({
    required String id,
    required String clubId,
    this.gruppoId = const Value.absent(),
    required DateTime data,
    this.ora = const Value.absent(),
    this.luogo = const Value.absent(),
    this.campionato = const Value.absent(),
    this.coloreCalottina = const Value.absent(),
    required String squadraCasa,
    required String squadraTrasferta,
    this.numeroMaxConvocati = const Value.absent(),
    this.note = const Value.absent(),
    this.dettaglioTiro = const Value.absent(),
    this.tracciaTempo = const Value.absent(),
    this.modalitaSuperiorita = const Value.absent(),
    this.nostraSquadra = const Value.absent(),
    this.importanza = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       data = Value(data),
       squadraCasa = Value(squadraCasa),
       squadraTrasferta = Value(squadraTrasferta);
  static Insertable<PartiteTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? gruppoId,
    Expression<DateTime>? data,
    Expression<String>? ora,
    Expression<String>? luogo,
    Expression<String>? campionato,
    Expression<String>? coloreCalottina,
    Expression<String>? squadraCasa,
    Expression<String>? squadraTrasferta,
    Expression<int>? numeroMaxConvocati,
    Expression<String>? note,
    Expression<String>? dettaglioTiro,
    Expression<bool>? tracciaTempo,
    Expression<String>? modalitaSuperiorita,
    Expression<String>? nostraSquadra,
    Expression<String>? importanza,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (gruppoId != null) 'gruppo_id': gruppoId,
      if (data != null) 'data': data,
      if (ora != null) 'ora': ora,
      if (luogo != null) 'luogo': luogo,
      if (campionato != null) 'campionato': campionato,
      if (coloreCalottina != null) 'colore_calottina': coloreCalottina,
      if (squadraCasa != null) 'squadra_casa': squadraCasa,
      if (squadraTrasferta != null) 'squadra_trasferta': squadraTrasferta,
      if (numeroMaxConvocati != null)
        'numero_max_convocati': numeroMaxConvocati,
      if (note != null) 'note': note,
      if (dettaglioTiro != null) 'dettaglio_tiro': dettaglioTiro,
      if (tracciaTempo != null) 'traccia_tempo': tracciaTempo,
      if (modalitaSuperiorita != null)
        'modalita_superiorita': modalitaSuperiorita,
      if (nostraSquadra != null) 'nostra_squadra': nostraSquadra,
      if (importanza != null) 'importanza': importanza,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartiteTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String?>? gruppoId,
    Value<DateTime>? data,
    Value<String?>? ora,
    Value<String?>? luogo,
    Value<String?>? campionato,
    Value<String?>? coloreCalottina,
    Value<String>? squadraCasa,
    Value<String>? squadraTrasferta,
    Value<int>? numeroMaxConvocati,
    Value<String?>? note,
    Value<String>? dettaglioTiro,
    Value<bool>? tracciaTempo,
    Value<String>? modalitaSuperiorita,
    Value<String>? nostraSquadra,
    Value<String>? importanza,
    Value<int>? rowid,
  }) {
    return PartiteTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      gruppoId: gruppoId ?? this.gruppoId,
      data: data ?? this.data,
      ora: ora ?? this.ora,
      luogo: luogo ?? this.luogo,
      campionato: campionato ?? this.campionato,
      coloreCalottina: coloreCalottina ?? this.coloreCalottina,
      squadraCasa: squadraCasa ?? this.squadraCasa,
      squadraTrasferta: squadraTrasferta ?? this.squadraTrasferta,
      numeroMaxConvocati: numeroMaxConvocati ?? this.numeroMaxConvocati,
      note: note ?? this.note,
      dettaglioTiro: dettaglioTiro ?? this.dettaglioTiro,
      tracciaTempo: tracciaTempo ?? this.tracciaTempo,
      modalitaSuperiorita: modalitaSuperiorita ?? this.modalitaSuperiorita,
      nostraSquadra: nostraSquadra ?? this.nostraSquadra,
      importanza: importanza ?? this.importanza,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (gruppoId.present) {
      map['gruppo_id'] = Variable<String>(gruppoId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (ora.present) {
      map['ora'] = Variable<String>(ora.value);
    }
    if (luogo.present) {
      map['luogo'] = Variable<String>(luogo.value);
    }
    if (campionato.present) {
      map['campionato'] = Variable<String>(campionato.value);
    }
    if (coloreCalottina.present) {
      map['colore_calottina'] = Variable<String>(coloreCalottina.value);
    }
    if (squadraCasa.present) {
      map['squadra_casa'] = Variable<String>(squadraCasa.value);
    }
    if (squadraTrasferta.present) {
      map['squadra_trasferta'] = Variable<String>(squadraTrasferta.value);
    }
    if (numeroMaxConvocati.present) {
      map['numero_max_convocati'] = Variable<int>(numeroMaxConvocati.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dettaglioTiro.present) {
      map['dettaglio_tiro'] = Variable<String>(dettaglioTiro.value);
    }
    if (tracciaTempo.present) {
      map['traccia_tempo'] = Variable<bool>(tracciaTempo.value);
    }
    if (modalitaSuperiorita.present) {
      map['modalita_superiorita'] = Variable<String>(modalitaSuperiorita.value);
    }
    if (nostraSquadra.present) {
      map['nostra_squadra'] = Variable<String>(nostraSquadra.value);
    }
    if (importanza.present) {
      map['importanza'] = Variable<String>(importanza.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartiteTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('data: $data, ')
          ..write('ora: $ora, ')
          ..write('luogo: $luogo, ')
          ..write('campionato: $campionato, ')
          ..write('coloreCalottina: $coloreCalottina, ')
          ..write('squadraCasa: $squadraCasa, ')
          ..write('squadraTrasferta: $squadraTrasferta, ')
          ..write('numeroMaxConvocati: $numeroMaxConvocati, ')
          ..write('note: $note, ')
          ..write('dettaglioTiro: $dettaglioTiro, ')
          ..write('tracciaTempo: $tracciaTempo, ')
          ..write('modalitaSuperiorita: $modalitaSuperiorita, ')
          ..write('nostraSquadra: $nostraSquadra, ')
          ..write('importanza: $importanza, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DistintaGiocatoriTableTable extends DistintaGiocatoriTable
    with TableInfo<$DistintaGiocatoriTableTable, DistintaGiocatoriTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistintaGiocatoriTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partitaIdMeta = const VerificationMeta(
    'partitaId',
  );
  @override
  late final GeneratedColumn<String> partitaId = GeneratedColumn<String>(
    'partita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroCalottinaMeta = const VerificationMeta(
    'numeroCalottina',
  );
  @override
  late final GeneratedColumn<int> numeroCalottina = GeneratedColumn<int>(
    'numero_calottina',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capitanoMeta = const VerificationMeta(
    'capitano',
  );
  @override
  late final GeneratedColumn<bool> capitano = GeneratedColumn<bool>(
    'capitano',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("capitano" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _viceCapitanoMeta = const VerificationMeta(
    'viceCapitano',
  );
  @override
  late final GeneratedColumn<bool> viceCapitano = GeneratedColumn<bool>(
    'vice_capitano',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vice_capitano" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _portiereMeta = const VerificationMeta(
    'portiere',
  );
  @override
  late final GeneratedColumn<bool> portiere = GeneratedColumn<bool>(
    'portiere',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("portiere" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fuoriquotaMeta = const VerificationMeta(
    'fuoriquota',
  );
  @override
  late final GeneratedColumn<bool> fuoriquota = GeneratedColumn<bool>(
    'fuoriquota',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fuoriquota" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    partitaId,
    atletaId,
    clubId,
    numeroCalottina,
    capitano,
    viceCapitano,
    portiere,
    fuoriquota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distinta_giocatori_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DistintaGiocatoriTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('partita_id')) {
      context.handle(
        _partitaIdMeta,
        partitaId.isAcceptableOrUnknown(data['partita_id']!, _partitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partitaIdMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('numero_calottina')) {
      context.handle(
        _numeroCalottinaMeta,
        numeroCalottina.isAcceptableOrUnknown(
          data['numero_calottina']!,
          _numeroCalottinaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_numeroCalottinaMeta);
    }
    if (data.containsKey('capitano')) {
      context.handle(
        _capitanoMeta,
        capitano.isAcceptableOrUnknown(data['capitano']!, _capitanoMeta),
      );
    }
    if (data.containsKey('vice_capitano')) {
      context.handle(
        _viceCapitanoMeta,
        viceCapitano.isAcceptableOrUnknown(
          data['vice_capitano']!,
          _viceCapitanoMeta,
        ),
      );
    }
    if (data.containsKey('portiere')) {
      context.handle(
        _portiereMeta,
        portiere.isAcceptableOrUnknown(data['portiere']!, _portiereMeta),
      );
    }
    if (data.containsKey('fuoriquota')) {
      context.handle(
        _fuoriquotaMeta,
        fuoriquota.isAcceptableOrUnknown(data['fuoriquota']!, _fuoriquotaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DistintaGiocatoriTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistintaGiocatoriTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      partitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partita_id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      numeroCalottina: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_calottina'],
      )!,
      capitano: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}capitano'],
      )!,
      viceCapitano: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vice_capitano'],
      )!,
      portiere: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}portiere'],
      )!,
      fuoriquota: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fuoriquota'],
      )!,
    );
  }

  @override
  $DistintaGiocatoriTableTable createAlias(String alias) {
    return $DistintaGiocatoriTableTable(attachedDatabase, alias);
  }
}

class DistintaGiocatoriTableData extends DataClass
    implements Insertable<DistintaGiocatoriTableData> {
  final String id;
  final String partitaId;
  final String atletaId;
  final String clubId;
  final int numeroCalottina;
  final bool capitano;
  final bool viceCapitano;
  final bool portiere;
  final bool fuoriquota;
  const DistintaGiocatoriTableData({
    required this.id,
    required this.partitaId,
    required this.atletaId,
    required this.clubId,
    required this.numeroCalottina,
    required this.capitano,
    required this.viceCapitano,
    required this.portiere,
    required this.fuoriquota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['partita_id'] = Variable<String>(partitaId);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['numero_calottina'] = Variable<int>(numeroCalottina);
    map['capitano'] = Variable<bool>(capitano);
    map['vice_capitano'] = Variable<bool>(viceCapitano);
    map['portiere'] = Variable<bool>(portiere);
    map['fuoriquota'] = Variable<bool>(fuoriquota);
    return map;
  }

  DistintaGiocatoriTableCompanion toCompanion(bool nullToAbsent) {
    return DistintaGiocatoriTableCompanion(
      id: Value(id),
      partitaId: Value(partitaId),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      numeroCalottina: Value(numeroCalottina),
      capitano: Value(capitano),
      viceCapitano: Value(viceCapitano),
      portiere: Value(portiere),
      fuoriquota: Value(fuoriquota),
    );
  }

  factory DistintaGiocatoriTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistintaGiocatoriTableData(
      id: serializer.fromJson<String>(json['id']),
      partitaId: serializer.fromJson<String>(json['partitaId']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      numeroCalottina: serializer.fromJson<int>(json['numeroCalottina']),
      capitano: serializer.fromJson<bool>(json['capitano']),
      viceCapitano: serializer.fromJson<bool>(json['viceCapitano']),
      portiere: serializer.fromJson<bool>(json['portiere']),
      fuoriquota: serializer.fromJson<bool>(json['fuoriquota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partitaId': serializer.toJson<String>(partitaId),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'numeroCalottina': serializer.toJson<int>(numeroCalottina),
      'capitano': serializer.toJson<bool>(capitano),
      'viceCapitano': serializer.toJson<bool>(viceCapitano),
      'portiere': serializer.toJson<bool>(portiere),
      'fuoriquota': serializer.toJson<bool>(fuoriquota),
    };
  }

  DistintaGiocatoriTableData copyWith({
    String? id,
    String? partitaId,
    String? atletaId,
    String? clubId,
    int? numeroCalottina,
    bool? capitano,
    bool? viceCapitano,
    bool? portiere,
    bool? fuoriquota,
  }) => DistintaGiocatoriTableData(
    id: id ?? this.id,
    partitaId: partitaId ?? this.partitaId,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    numeroCalottina: numeroCalottina ?? this.numeroCalottina,
    capitano: capitano ?? this.capitano,
    viceCapitano: viceCapitano ?? this.viceCapitano,
    portiere: portiere ?? this.portiere,
    fuoriquota: fuoriquota ?? this.fuoriquota,
  );
  DistintaGiocatoriTableData copyWithCompanion(
    DistintaGiocatoriTableCompanion data,
  ) {
    return DistintaGiocatoriTableData(
      id: data.id.present ? data.id.value : this.id,
      partitaId: data.partitaId.present ? data.partitaId.value : this.partitaId,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      numeroCalottina: data.numeroCalottina.present
          ? data.numeroCalottina.value
          : this.numeroCalottina,
      capitano: data.capitano.present ? data.capitano.value : this.capitano,
      viceCapitano: data.viceCapitano.present
          ? data.viceCapitano.value
          : this.viceCapitano,
      portiere: data.portiere.present ? data.portiere.value : this.portiere,
      fuoriquota: data.fuoriquota.present
          ? data.fuoriquota.value
          : this.fuoriquota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DistintaGiocatoriTableData(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('numeroCalottina: $numeroCalottina, ')
          ..write('capitano: $capitano, ')
          ..write('viceCapitano: $viceCapitano, ')
          ..write('portiere: $portiere, ')
          ..write('fuoriquota: $fuoriquota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    partitaId,
    atletaId,
    clubId,
    numeroCalottina,
    capitano,
    viceCapitano,
    portiere,
    fuoriquota,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistintaGiocatoriTableData &&
          other.id == this.id &&
          other.partitaId == this.partitaId &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.numeroCalottina == this.numeroCalottina &&
          other.capitano == this.capitano &&
          other.viceCapitano == this.viceCapitano &&
          other.portiere == this.portiere &&
          other.fuoriquota == this.fuoriquota);
}

class DistintaGiocatoriTableCompanion
    extends UpdateCompanion<DistintaGiocatoriTableData> {
  final Value<String> id;
  final Value<String> partitaId;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<int> numeroCalottina;
  final Value<bool> capitano;
  final Value<bool> viceCapitano;
  final Value<bool> portiere;
  final Value<bool> fuoriquota;
  final Value<int> rowid;
  const DistintaGiocatoriTableCompanion({
    this.id = const Value.absent(),
    this.partitaId = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.numeroCalottina = const Value.absent(),
    this.capitano = const Value.absent(),
    this.viceCapitano = const Value.absent(),
    this.portiere = const Value.absent(),
    this.fuoriquota = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistintaGiocatoriTableCompanion.insert({
    required String id,
    required String partitaId,
    required String atletaId,
    required String clubId,
    required int numeroCalottina,
    this.capitano = const Value.absent(),
    this.viceCapitano = const Value.absent(),
    this.portiere = const Value.absent(),
    this.fuoriquota = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       partitaId = Value(partitaId),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       numeroCalottina = Value(numeroCalottina);
  static Insertable<DistintaGiocatoriTableData> custom({
    Expression<String>? id,
    Expression<String>? partitaId,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<int>? numeroCalottina,
    Expression<bool>? capitano,
    Expression<bool>? viceCapitano,
    Expression<bool>? portiere,
    Expression<bool>? fuoriquota,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partitaId != null) 'partita_id': partitaId,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (numeroCalottina != null) 'numero_calottina': numeroCalottina,
      if (capitano != null) 'capitano': capitano,
      if (viceCapitano != null) 'vice_capitano': viceCapitano,
      if (portiere != null) 'portiere': portiere,
      if (fuoriquota != null) 'fuoriquota': fuoriquota,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistintaGiocatoriTableCompanion copyWith({
    Value<String>? id,
    Value<String>? partitaId,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<int>? numeroCalottina,
    Value<bool>? capitano,
    Value<bool>? viceCapitano,
    Value<bool>? portiere,
    Value<bool>? fuoriquota,
    Value<int>? rowid,
  }) {
    return DistintaGiocatoriTableCompanion(
      id: id ?? this.id,
      partitaId: partitaId ?? this.partitaId,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      numeroCalottina: numeroCalottina ?? this.numeroCalottina,
      capitano: capitano ?? this.capitano,
      viceCapitano: viceCapitano ?? this.viceCapitano,
      portiere: portiere ?? this.portiere,
      fuoriquota: fuoriquota ?? this.fuoriquota,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partitaId.present) {
      map['partita_id'] = Variable<String>(partitaId.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (numeroCalottina.present) {
      map['numero_calottina'] = Variable<int>(numeroCalottina.value);
    }
    if (capitano.present) {
      map['capitano'] = Variable<bool>(capitano.value);
    }
    if (viceCapitano.present) {
      map['vice_capitano'] = Variable<bool>(viceCapitano.value);
    }
    if (portiere.present) {
      map['portiere'] = Variable<bool>(portiere.value);
    }
    if (fuoriquota.present) {
      map['fuoriquota'] = Variable<bool>(fuoriquota.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistintaGiocatoriTableCompanion(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('numeroCalottina: $numeroCalottina, ')
          ..write('capitano: $capitano, ')
          ..write('viceCapitano: $viceCapitano, ')
          ..write('portiere: $portiere, ')
          ..write('fuoriquota: $fuoriquota, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventiPartitaTableTable extends EventiPartitaTable
    with TableInfo<$EventiPartitaTableTable, EventiPartitaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventiPartitaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partitaIdMeta = const VerificationMeta(
    'partitaId',
  );
  @override
  late final GeneratedColumn<String> partitaId = GeneratedColumn<String>(
    'partita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _squadraMeta = const VerificationMeta(
    'squadra',
  );
  @override
  late final GeneratedColumn<String> squadra = GeneratedColumn<String>(
    'squadra',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('nostra'),
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodoMeta = const VerificationMeta(
    'periodo',
  );
  @override
  late final GeneratedColumn<int> periodo = GeneratedColumn<int>(
    'periodo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _esitoMeta = const VerificationMeta('esito');
  @override
  late final GeneratedColumn<String> esito = GeneratedColumn<String>(
    'esito',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contestoTiroMeta = const VerificationMeta(
    'contestoTiro',
  );
  @override
  late final GeneratedColumn<String> contestoTiro = GeneratedColumn<String>(
    'contesto_tiro',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('azione'),
  );
  static const VerificationMeta _posXMeta = const VerificationMeta('posX');
  @override
  late final GeneratedColumn<double> posX = GeneratedColumn<double>(
    'pos_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posYMeta = const VerificationMeta('posY');
  @override
  late final GeneratedColumn<double> posY = GeneratedColumn<double>(
    'pos_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numeroCalottinaAvversarioMeta =
      const VerificationMeta('numeroCalottinaAvversario');
  @override
  late final GeneratedColumn<int> numeroCalottinaAvversario =
      GeneratedColumn<int>(
        'numero_calottina_avversario',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _espulsioneDaRigoreMeta =
      const VerificationMeta('espulsioneDaRigore');
  @override
  late final GeneratedColumn<bool> espulsioneDaRigore = GeneratedColumn<bool>(
    'espulsione_da_rigore',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("espulsione_da_rigore" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creatoIlMeta = const VerificationMeta(
    'creatoIl',
  );
  @override
  late final GeneratedColumn<DateTime> creatoIl = GeneratedColumn<DateTime>(
    'creato_il',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    partitaId,
    clubId,
    tipo,
    squadra,
    atletaId,
    periodo,
    esito,
    contestoTiro,
    posX,
    posY,
    numeroCalottinaAvversario,
    espulsioneDaRigore,
    creatoIl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventi_partita_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventiPartitaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('partita_id')) {
      context.handle(
        _partitaIdMeta,
        partitaId.isAcceptableOrUnknown(data['partita_id']!, _partitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partitaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('squadra')) {
      context.handle(
        _squadraMeta,
        squadra.isAcceptableOrUnknown(data['squadra']!, _squadraMeta),
      );
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    }
    if (data.containsKey('periodo')) {
      context.handle(
        _periodoMeta,
        periodo.isAcceptableOrUnknown(data['periodo']!, _periodoMeta),
      );
    }
    if (data.containsKey('esito')) {
      context.handle(
        _esitoMeta,
        esito.isAcceptableOrUnknown(data['esito']!, _esitoMeta),
      );
    }
    if (data.containsKey('contesto_tiro')) {
      context.handle(
        _contestoTiroMeta,
        contestoTiro.isAcceptableOrUnknown(
          data['contesto_tiro']!,
          _contestoTiroMeta,
        ),
      );
    }
    if (data.containsKey('pos_x')) {
      context.handle(
        _posXMeta,
        posX.isAcceptableOrUnknown(data['pos_x']!, _posXMeta),
      );
    }
    if (data.containsKey('pos_y')) {
      context.handle(
        _posYMeta,
        posY.isAcceptableOrUnknown(data['pos_y']!, _posYMeta),
      );
    }
    if (data.containsKey('numero_calottina_avversario')) {
      context.handle(
        _numeroCalottinaAvversarioMeta,
        numeroCalottinaAvversario.isAcceptableOrUnknown(
          data['numero_calottina_avversario']!,
          _numeroCalottinaAvversarioMeta,
        ),
      );
    }
    if (data.containsKey('espulsione_da_rigore')) {
      context.handle(
        _espulsioneDaRigoreMeta,
        espulsioneDaRigore.isAcceptableOrUnknown(
          data['espulsione_da_rigore']!,
          _espulsioneDaRigoreMeta,
        ),
      );
    }
    if (data.containsKey('creato_il')) {
      context.handle(
        _creatoIlMeta,
        creatoIl.isAcceptableOrUnknown(data['creato_il']!, _creatoIlMeta),
      );
    } else if (isInserting) {
      context.missing(_creatoIlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventiPartitaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventiPartitaTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      partitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partita_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      squadra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}squadra'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      ),
      periodo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}periodo'],
      ),
      esito: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esito'],
      ),
      contestoTiro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contesto_tiro'],
      )!,
      posX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_x'],
      ),
      posY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_y'],
      ),
      numeroCalottinaAvversario: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_calottina_avversario'],
      ),
      espulsioneDaRigore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}espulsione_da_rigore'],
      )!,
      creatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creato_il'],
      )!,
    );
  }

  @override
  $EventiPartitaTableTable createAlias(String alias) {
    return $EventiPartitaTableTable(attachedDatabase, alias);
  }
}

class EventiPartitaTableData extends DataClass
    implements Insertable<EventiPartitaTableData> {
  final String id;
  final String partitaId;
  final String clubId;
  final String tipo;
  final String squadra;
  final String? atletaId;
  final int? periodo;
  final String? esito;
  final String contestoTiro;
  final double? posX;
  final double? posY;
  final int? numeroCalottinaAvversario;
  final bool espulsioneDaRigore;
  final DateTime creatoIl;
  const EventiPartitaTableData({
    required this.id,
    required this.partitaId,
    required this.clubId,
    required this.tipo,
    required this.squadra,
    this.atletaId,
    this.periodo,
    this.esito,
    required this.contestoTiro,
    this.posX,
    this.posY,
    this.numeroCalottinaAvversario,
    required this.espulsioneDaRigore,
    required this.creatoIl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['partita_id'] = Variable<String>(partitaId);
    map['club_id'] = Variable<String>(clubId);
    map['tipo'] = Variable<String>(tipo);
    map['squadra'] = Variable<String>(squadra);
    if (!nullToAbsent || atletaId != null) {
      map['atleta_id'] = Variable<String>(atletaId);
    }
    if (!nullToAbsent || periodo != null) {
      map['periodo'] = Variable<int>(periodo);
    }
    if (!nullToAbsent || esito != null) {
      map['esito'] = Variable<String>(esito);
    }
    map['contesto_tiro'] = Variable<String>(contestoTiro);
    if (!nullToAbsent || posX != null) {
      map['pos_x'] = Variable<double>(posX);
    }
    if (!nullToAbsent || posY != null) {
      map['pos_y'] = Variable<double>(posY);
    }
    if (!nullToAbsent || numeroCalottinaAvversario != null) {
      map['numero_calottina_avversario'] = Variable<int>(
        numeroCalottinaAvversario,
      );
    }
    map['espulsione_da_rigore'] = Variable<bool>(espulsioneDaRigore);
    map['creato_il'] = Variable<DateTime>(creatoIl);
    return map;
  }

  EventiPartitaTableCompanion toCompanion(bool nullToAbsent) {
    return EventiPartitaTableCompanion(
      id: Value(id),
      partitaId: Value(partitaId),
      clubId: Value(clubId),
      tipo: Value(tipo),
      squadra: Value(squadra),
      atletaId: atletaId == null && nullToAbsent
          ? const Value.absent()
          : Value(atletaId),
      periodo: periodo == null && nullToAbsent
          ? const Value.absent()
          : Value(periodo),
      esito: esito == null && nullToAbsent
          ? const Value.absent()
          : Value(esito),
      contestoTiro: Value(contestoTiro),
      posX: posX == null && nullToAbsent ? const Value.absent() : Value(posX),
      posY: posY == null && nullToAbsent ? const Value.absent() : Value(posY),
      numeroCalottinaAvversario:
          numeroCalottinaAvversario == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroCalottinaAvversario),
      espulsioneDaRigore: Value(espulsioneDaRigore),
      creatoIl: Value(creatoIl),
    );
  }

  factory EventiPartitaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventiPartitaTableData(
      id: serializer.fromJson<String>(json['id']),
      partitaId: serializer.fromJson<String>(json['partitaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      squadra: serializer.fromJson<String>(json['squadra']),
      atletaId: serializer.fromJson<String?>(json['atletaId']),
      periodo: serializer.fromJson<int?>(json['periodo']),
      esito: serializer.fromJson<String?>(json['esito']),
      contestoTiro: serializer.fromJson<String>(json['contestoTiro']),
      posX: serializer.fromJson<double?>(json['posX']),
      posY: serializer.fromJson<double?>(json['posY']),
      numeroCalottinaAvversario: serializer.fromJson<int?>(
        json['numeroCalottinaAvversario'],
      ),
      espulsioneDaRigore: serializer.fromJson<bool>(json['espulsioneDaRigore']),
      creatoIl: serializer.fromJson<DateTime>(json['creatoIl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partitaId': serializer.toJson<String>(partitaId),
      'clubId': serializer.toJson<String>(clubId),
      'tipo': serializer.toJson<String>(tipo),
      'squadra': serializer.toJson<String>(squadra),
      'atletaId': serializer.toJson<String?>(atletaId),
      'periodo': serializer.toJson<int?>(periodo),
      'esito': serializer.toJson<String?>(esito),
      'contestoTiro': serializer.toJson<String>(contestoTiro),
      'posX': serializer.toJson<double?>(posX),
      'posY': serializer.toJson<double?>(posY),
      'numeroCalottinaAvversario': serializer.toJson<int?>(
        numeroCalottinaAvversario,
      ),
      'espulsioneDaRigore': serializer.toJson<bool>(espulsioneDaRigore),
      'creatoIl': serializer.toJson<DateTime>(creatoIl),
    };
  }

  EventiPartitaTableData copyWith({
    String? id,
    String? partitaId,
    String? clubId,
    String? tipo,
    String? squadra,
    Value<String?> atletaId = const Value.absent(),
    Value<int?> periodo = const Value.absent(),
    Value<String?> esito = const Value.absent(),
    String? contestoTiro,
    Value<double?> posX = const Value.absent(),
    Value<double?> posY = const Value.absent(),
    Value<int?> numeroCalottinaAvversario = const Value.absent(),
    bool? espulsioneDaRigore,
    DateTime? creatoIl,
  }) => EventiPartitaTableData(
    id: id ?? this.id,
    partitaId: partitaId ?? this.partitaId,
    clubId: clubId ?? this.clubId,
    tipo: tipo ?? this.tipo,
    squadra: squadra ?? this.squadra,
    atletaId: atletaId.present ? atletaId.value : this.atletaId,
    periodo: periodo.present ? periodo.value : this.periodo,
    esito: esito.present ? esito.value : this.esito,
    contestoTiro: contestoTiro ?? this.contestoTiro,
    posX: posX.present ? posX.value : this.posX,
    posY: posY.present ? posY.value : this.posY,
    numeroCalottinaAvversario: numeroCalottinaAvversario.present
        ? numeroCalottinaAvversario.value
        : this.numeroCalottinaAvversario,
    espulsioneDaRigore: espulsioneDaRigore ?? this.espulsioneDaRigore,
    creatoIl: creatoIl ?? this.creatoIl,
  );
  EventiPartitaTableData copyWithCompanion(EventiPartitaTableCompanion data) {
    return EventiPartitaTableData(
      id: data.id.present ? data.id.value : this.id,
      partitaId: data.partitaId.present ? data.partitaId.value : this.partitaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      squadra: data.squadra.present ? data.squadra.value : this.squadra,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      periodo: data.periodo.present ? data.periodo.value : this.periodo,
      esito: data.esito.present ? data.esito.value : this.esito,
      contestoTiro: data.contestoTiro.present
          ? data.contestoTiro.value
          : this.contestoTiro,
      posX: data.posX.present ? data.posX.value : this.posX,
      posY: data.posY.present ? data.posY.value : this.posY,
      numeroCalottinaAvversario: data.numeroCalottinaAvversario.present
          ? data.numeroCalottinaAvversario.value
          : this.numeroCalottinaAvversario,
      espulsioneDaRigore: data.espulsioneDaRigore.present
          ? data.espulsioneDaRigore.value
          : this.espulsioneDaRigore,
      creatoIl: data.creatoIl.present ? data.creatoIl.value : this.creatoIl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventiPartitaTableData(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('clubId: $clubId, ')
          ..write('tipo: $tipo, ')
          ..write('squadra: $squadra, ')
          ..write('atletaId: $atletaId, ')
          ..write('periodo: $periodo, ')
          ..write('esito: $esito, ')
          ..write('contestoTiro: $contestoTiro, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('numeroCalottinaAvversario: $numeroCalottinaAvversario, ')
          ..write('espulsioneDaRigore: $espulsioneDaRigore, ')
          ..write('creatoIl: $creatoIl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    partitaId,
    clubId,
    tipo,
    squadra,
    atletaId,
    periodo,
    esito,
    contestoTiro,
    posX,
    posY,
    numeroCalottinaAvversario,
    espulsioneDaRigore,
    creatoIl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventiPartitaTableData &&
          other.id == this.id &&
          other.partitaId == this.partitaId &&
          other.clubId == this.clubId &&
          other.tipo == this.tipo &&
          other.squadra == this.squadra &&
          other.atletaId == this.atletaId &&
          other.periodo == this.periodo &&
          other.esito == this.esito &&
          other.contestoTiro == this.contestoTiro &&
          other.posX == this.posX &&
          other.posY == this.posY &&
          other.numeroCalottinaAvversario == this.numeroCalottinaAvversario &&
          other.espulsioneDaRigore == this.espulsioneDaRigore &&
          other.creatoIl == this.creatoIl);
}

class EventiPartitaTableCompanion
    extends UpdateCompanion<EventiPartitaTableData> {
  final Value<String> id;
  final Value<String> partitaId;
  final Value<String> clubId;
  final Value<String> tipo;
  final Value<String> squadra;
  final Value<String?> atletaId;
  final Value<int?> periodo;
  final Value<String?> esito;
  final Value<String> contestoTiro;
  final Value<double?> posX;
  final Value<double?> posY;
  final Value<int?> numeroCalottinaAvversario;
  final Value<bool> espulsioneDaRigore;
  final Value<DateTime> creatoIl;
  final Value<int> rowid;
  const EventiPartitaTableCompanion({
    this.id = const Value.absent(),
    this.partitaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.squadra = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.periodo = const Value.absent(),
    this.esito = const Value.absent(),
    this.contestoTiro = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.numeroCalottinaAvversario = const Value.absent(),
    this.espulsioneDaRigore = const Value.absent(),
    this.creatoIl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventiPartitaTableCompanion.insert({
    required String id,
    required String partitaId,
    required String clubId,
    required String tipo,
    this.squadra = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.periodo = const Value.absent(),
    this.esito = const Value.absent(),
    this.contestoTiro = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.numeroCalottinaAvversario = const Value.absent(),
    this.espulsioneDaRigore = const Value.absent(),
    required DateTime creatoIl,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       partitaId = Value(partitaId),
       clubId = Value(clubId),
       tipo = Value(tipo),
       creatoIl = Value(creatoIl);
  static Insertable<EventiPartitaTableData> custom({
    Expression<String>? id,
    Expression<String>? partitaId,
    Expression<String>? clubId,
    Expression<String>? tipo,
    Expression<String>? squadra,
    Expression<String>? atletaId,
    Expression<int>? periodo,
    Expression<String>? esito,
    Expression<String>? contestoTiro,
    Expression<double>? posX,
    Expression<double>? posY,
    Expression<int>? numeroCalottinaAvversario,
    Expression<bool>? espulsioneDaRigore,
    Expression<DateTime>? creatoIl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partitaId != null) 'partita_id': partitaId,
      if (clubId != null) 'club_id': clubId,
      if (tipo != null) 'tipo': tipo,
      if (squadra != null) 'squadra': squadra,
      if (atletaId != null) 'atleta_id': atletaId,
      if (periodo != null) 'periodo': periodo,
      if (esito != null) 'esito': esito,
      if (contestoTiro != null) 'contesto_tiro': contestoTiro,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
      if (numeroCalottinaAvversario != null)
        'numero_calottina_avversario': numeroCalottinaAvversario,
      if (espulsioneDaRigore != null)
        'espulsione_da_rigore': espulsioneDaRigore,
      if (creatoIl != null) 'creato_il': creatoIl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventiPartitaTableCompanion copyWith({
    Value<String>? id,
    Value<String>? partitaId,
    Value<String>? clubId,
    Value<String>? tipo,
    Value<String>? squadra,
    Value<String?>? atletaId,
    Value<int?>? periodo,
    Value<String?>? esito,
    Value<String>? contestoTiro,
    Value<double?>? posX,
    Value<double?>? posY,
    Value<int?>? numeroCalottinaAvversario,
    Value<bool>? espulsioneDaRigore,
    Value<DateTime>? creatoIl,
    Value<int>? rowid,
  }) {
    return EventiPartitaTableCompanion(
      id: id ?? this.id,
      partitaId: partitaId ?? this.partitaId,
      clubId: clubId ?? this.clubId,
      tipo: tipo ?? this.tipo,
      squadra: squadra ?? this.squadra,
      atletaId: atletaId ?? this.atletaId,
      periodo: periodo ?? this.periodo,
      esito: esito ?? this.esito,
      contestoTiro: contestoTiro ?? this.contestoTiro,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      numeroCalottinaAvversario:
          numeroCalottinaAvversario ?? this.numeroCalottinaAvversario,
      espulsioneDaRigore: espulsioneDaRigore ?? this.espulsioneDaRigore,
      creatoIl: creatoIl ?? this.creatoIl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partitaId.present) {
      map['partita_id'] = Variable<String>(partitaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (squadra.present) {
      map['squadra'] = Variable<String>(squadra.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (periodo.present) {
      map['periodo'] = Variable<int>(periodo.value);
    }
    if (esito.present) {
      map['esito'] = Variable<String>(esito.value);
    }
    if (contestoTiro.present) {
      map['contesto_tiro'] = Variable<String>(contestoTiro.value);
    }
    if (posX.present) {
      map['pos_x'] = Variable<double>(posX.value);
    }
    if (posY.present) {
      map['pos_y'] = Variable<double>(posY.value);
    }
    if (numeroCalottinaAvversario.present) {
      map['numero_calottina_avversario'] = Variable<int>(
        numeroCalottinaAvversario.value,
      );
    }
    if (espulsioneDaRigore.present) {
      map['espulsione_da_rigore'] = Variable<bool>(espulsioneDaRigore.value);
    }
    if (creatoIl.present) {
      map['creato_il'] = Variable<DateTime>(creatoIl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventiPartitaTableCompanion(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('clubId: $clubId, ')
          ..write('tipo: $tipo, ')
          ..write('squadra: $squadra, ')
          ..write('atletaId: $atletaId, ')
          ..write('periodo: $periodo, ')
          ..write('esito: $esito, ')
          ..write('contestoTiro: $contestoTiro, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('numeroCalottinaAvversario: $numeroCalottinaAvversario, ')
          ..write('espulsioneDaRigore: $espulsioneDaRigore, ')
          ..write('creatoIl: $creatoIl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefertiPartitaTableTable extends RefertiPartitaTable
    with TableInfo<$RefertiPartitaTableTable, RefertiPartitaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefertiPartitaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partitaIdMeta = const VerificationMeta(
    'partitaId',
  );
  @override
  late final GeneratedColumn<String> partitaId = GeneratedColumn<String>(
    'partita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _squadraCasaMeta = const VerificationMeta(
    'squadraCasa',
  );
  @override
  late final GeneratedColumn<String> squadraCasa = GeneratedColumn<String>(
    'squadra_casa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _squadraTrasfertaMeta = const VerificationMeta(
    'squadraTrasferta',
  );
  @override
  late final GeneratedColumn<String> squadraTrasferta = GeneratedColumn<String>(
    'squadra_trasferta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _risultatoCasaMeta = const VerificationMeta(
    'risultatoCasa',
  );
  @override
  late final GeneratedColumn<int> risultatoCasa = GeneratedColumn<int>(
    'risultato_casa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _risultatoTrasfertaMeta =
      const VerificationMeta('risultatoTrasferta');
  @override
  late final GeneratedColumn<int> risultatoTrasferta = GeneratedColumn<int>(
    'risultato_trasferta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parzialiJsonMeta = const VerificationMeta(
    'parzialiJson',
  );
  @override
  late final GeneratedColumn<String> parzialiJson = GeneratedColumn<String>(
    'parziali_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _giocatoriCasaJsonMeta = const VerificationMeta(
    'giocatoriCasaJson',
  );
  @override
  late final GeneratedColumn<String> giocatoriCasaJson =
      GeneratedColumn<String>(
        'giocatori_casa_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _giocatoriTrasfertaJsonMeta =
      const VerificationMeta('giocatoriTrasfertaJson');
  @override
  late final GeneratedColumn<String> giocatoriTrasfertaJson =
      GeneratedColumn<String>(
        'giocatori_trasferta_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    partitaId,
    clubId,
    squadraCasa,
    squadraTrasferta,
    risultatoCasa,
    risultatoTrasferta,
    parzialiJson,
    giocatoriCasaJson,
    giocatoriTrasfertaJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'referti_partita_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RefertiPartitaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('partita_id')) {
      context.handle(
        _partitaIdMeta,
        partitaId.isAcceptableOrUnknown(data['partita_id']!, _partitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partitaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('squadra_casa')) {
      context.handle(
        _squadraCasaMeta,
        squadraCasa.isAcceptableOrUnknown(
          data['squadra_casa']!,
          _squadraCasaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_squadraCasaMeta);
    }
    if (data.containsKey('squadra_trasferta')) {
      context.handle(
        _squadraTrasfertaMeta,
        squadraTrasferta.isAcceptableOrUnknown(
          data['squadra_trasferta']!,
          _squadraTrasfertaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_squadraTrasfertaMeta);
    }
    if (data.containsKey('risultato_casa')) {
      context.handle(
        _risultatoCasaMeta,
        risultatoCasa.isAcceptableOrUnknown(
          data['risultato_casa']!,
          _risultatoCasaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_risultatoCasaMeta);
    }
    if (data.containsKey('risultato_trasferta')) {
      context.handle(
        _risultatoTrasfertaMeta,
        risultatoTrasferta.isAcceptableOrUnknown(
          data['risultato_trasferta']!,
          _risultatoTrasfertaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_risultatoTrasfertaMeta);
    }
    if (data.containsKey('parziali_json')) {
      context.handle(
        _parzialiJsonMeta,
        parzialiJson.isAcceptableOrUnknown(
          data['parziali_json']!,
          _parzialiJsonMeta,
        ),
      );
    }
    if (data.containsKey('giocatori_casa_json')) {
      context.handle(
        _giocatoriCasaJsonMeta,
        giocatoriCasaJson.isAcceptableOrUnknown(
          data['giocatori_casa_json']!,
          _giocatoriCasaJsonMeta,
        ),
      );
    }
    if (data.containsKey('giocatori_trasferta_json')) {
      context.handle(
        _giocatoriTrasfertaJsonMeta,
        giocatoriTrasfertaJson.isAcceptableOrUnknown(
          data['giocatori_trasferta_json']!,
          _giocatoriTrasfertaJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefertiPartitaTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefertiPartitaTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      partitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partita_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      squadraCasa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}squadra_casa'],
      )!,
      squadraTrasferta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}squadra_trasferta'],
      )!,
      risultatoCasa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}risultato_casa'],
      )!,
      risultatoTrasferta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}risultato_trasferta'],
      )!,
      parzialiJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parziali_json'],
      )!,
      giocatoriCasaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}giocatori_casa_json'],
      )!,
      giocatoriTrasfertaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}giocatori_trasferta_json'],
      )!,
    );
  }

  @override
  $RefertiPartitaTableTable createAlias(String alias) {
    return $RefertiPartitaTableTable(attachedDatabase, alias);
  }
}

class RefertiPartitaTableData extends DataClass
    implements Insertable<RefertiPartitaTableData> {
  final String id;
  final String partitaId;
  final String clubId;
  final String squadraCasa;
  final String squadraTrasferta;
  final int risultatoCasa;
  final int risultatoTrasferta;
  final String parzialiJson;
  final String giocatoriCasaJson;
  final String giocatoriTrasfertaJson;
  const RefertiPartitaTableData({
    required this.id,
    required this.partitaId,
    required this.clubId,
    required this.squadraCasa,
    required this.squadraTrasferta,
    required this.risultatoCasa,
    required this.risultatoTrasferta,
    required this.parzialiJson,
    required this.giocatoriCasaJson,
    required this.giocatoriTrasfertaJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['partita_id'] = Variable<String>(partitaId);
    map['club_id'] = Variable<String>(clubId);
    map['squadra_casa'] = Variable<String>(squadraCasa);
    map['squadra_trasferta'] = Variable<String>(squadraTrasferta);
    map['risultato_casa'] = Variable<int>(risultatoCasa);
    map['risultato_trasferta'] = Variable<int>(risultatoTrasferta);
    map['parziali_json'] = Variable<String>(parzialiJson);
    map['giocatori_casa_json'] = Variable<String>(giocatoriCasaJson);
    map['giocatori_trasferta_json'] = Variable<String>(giocatoriTrasfertaJson);
    return map;
  }

  RefertiPartitaTableCompanion toCompanion(bool nullToAbsent) {
    return RefertiPartitaTableCompanion(
      id: Value(id),
      partitaId: Value(partitaId),
      clubId: Value(clubId),
      squadraCasa: Value(squadraCasa),
      squadraTrasferta: Value(squadraTrasferta),
      risultatoCasa: Value(risultatoCasa),
      risultatoTrasferta: Value(risultatoTrasferta),
      parzialiJson: Value(parzialiJson),
      giocatoriCasaJson: Value(giocatoriCasaJson),
      giocatoriTrasfertaJson: Value(giocatoriTrasfertaJson),
    );
  }

  factory RefertiPartitaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefertiPartitaTableData(
      id: serializer.fromJson<String>(json['id']),
      partitaId: serializer.fromJson<String>(json['partitaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      squadraCasa: serializer.fromJson<String>(json['squadraCasa']),
      squadraTrasferta: serializer.fromJson<String>(json['squadraTrasferta']),
      risultatoCasa: serializer.fromJson<int>(json['risultatoCasa']),
      risultatoTrasferta: serializer.fromJson<int>(json['risultatoTrasferta']),
      parzialiJson: serializer.fromJson<String>(json['parzialiJson']),
      giocatoriCasaJson: serializer.fromJson<String>(json['giocatoriCasaJson']),
      giocatoriTrasfertaJson: serializer.fromJson<String>(
        json['giocatoriTrasfertaJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partitaId': serializer.toJson<String>(partitaId),
      'clubId': serializer.toJson<String>(clubId),
      'squadraCasa': serializer.toJson<String>(squadraCasa),
      'squadraTrasferta': serializer.toJson<String>(squadraTrasferta),
      'risultatoCasa': serializer.toJson<int>(risultatoCasa),
      'risultatoTrasferta': serializer.toJson<int>(risultatoTrasferta),
      'parzialiJson': serializer.toJson<String>(parzialiJson),
      'giocatoriCasaJson': serializer.toJson<String>(giocatoriCasaJson),
      'giocatoriTrasfertaJson': serializer.toJson<String>(
        giocatoriTrasfertaJson,
      ),
    };
  }

  RefertiPartitaTableData copyWith({
    String? id,
    String? partitaId,
    String? clubId,
    String? squadraCasa,
    String? squadraTrasferta,
    int? risultatoCasa,
    int? risultatoTrasferta,
    String? parzialiJson,
    String? giocatoriCasaJson,
    String? giocatoriTrasfertaJson,
  }) => RefertiPartitaTableData(
    id: id ?? this.id,
    partitaId: partitaId ?? this.partitaId,
    clubId: clubId ?? this.clubId,
    squadraCasa: squadraCasa ?? this.squadraCasa,
    squadraTrasferta: squadraTrasferta ?? this.squadraTrasferta,
    risultatoCasa: risultatoCasa ?? this.risultatoCasa,
    risultatoTrasferta: risultatoTrasferta ?? this.risultatoTrasferta,
    parzialiJson: parzialiJson ?? this.parzialiJson,
    giocatoriCasaJson: giocatoriCasaJson ?? this.giocatoriCasaJson,
    giocatoriTrasfertaJson:
        giocatoriTrasfertaJson ?? this.giocatoriTrasfertaJson,
  );
  RefertiPartitaTableData copyWithCompanion(RefertiPartitaTableCompanion data) {
    return RefertiPartitaTableData(
      id: data.id.present ? data.id.value : this.id,
      partitaId: data.partitaId.present ? data.partitaId.value : this.partitaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      squadraCasa: data.squadraCasa.present
          ? data.squadraCasa.value
          : this.squadraCasa,
      squadraTrasferta: data.squadraTrasferta.present
          ? data.squadraTrasferta.value
          : this.squadraTrasferta,
      risultatoCasa: data.risultatoCasa.present
          ? data.risultatoCasa.value
          : this.risultatoCasa,
      risultatoTrasferta: data.risultatoTrasferta.present
          ? data.risultatoTrasferta.value
          : this.risultatoTrasferta,
      parzialiJson: data.parzialiJson.present
          ? data.parzialiJson.value
          : this.parzialiJson,
      giocatoriCasaJson: data.giocatoriCasaJson.present
          ? data.giocatoriCasaJson.value
          : this.giocatoriCasaJson,
      giocatoriTrasfertaJson: data.giocatoriTrasfertaJson.present
          ? data.giocatoriTrasfertaJson.value
          : this.giocatoriTrasfertaJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefertiPartitaTableData(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('clubId: $clubId, ')
          ..write('squadraCasa: $squadraCasa, ')
          ..write('squadraTrasferta: $squadraTrasferta, ')
          ..write('risultatoCasa: $risultatoCasa, ')
          ..write('risultatoTrasferta: $risultatoTrasferta, ')
          ..write('parzialiJson: $parzialiJson, ')
          ..write('giocatoriCasaJson: $giocatoriCasaJson, ')
          ..write('giocatoriTrasfertaJson: $giocatoriTrasfertaJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    partitaId,
    clubId,
    squadraCasa,
    squadraTrasferta,
    risultatoCasa,
    risultatoTrasferta,
    parzialiJson,
    giocatoriCasaJson,
    giocatoriTrasfertaJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefertiPartitaTableData &&
          other.id == this.id &&
          other.partitaId == this.partitaId &&
          other.clubId == this.clubId &&
          other.squadraCasa == this.squadraCasa &&
          other.squadraTrasferta == this.squadraTrasferta &&
          other.risultatoCasa == this.risultatoCasa &&
          other.risultatoTrasferta == this.risultatoTrasferta &&
          other.parzialiJson == this.parzialiJson &&
          other.giocatoriCasaJson == this.giocatoriCasaJson &&
          other.giocatoriTrasfertaJson == this.giocatoriTrasfertaJson);
}

class RefertiPartitaTableCompanion
    extends UpdateCompanion<RefertiPartitaTableData> {
  final Value<String> id;
  final Value<String> partitaId;
  final Value<String> clubId;
  final Value<String> squadraCasa;
  final Value<String> squadraTrasferta;
  final Value<int> risultatoCasa;
  final Value<int> risultatoTrasferta;
  final Value<String> parzialiJson;
  final Value<String> giocatoriCasaJson;
  final Value<String> giocatoriTrasfertaJson;
  final Value<int> rowid;
  const RefertiPartitaTableCompanion({
    this.id = const Value.absent(),
    this.partitaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.squadraCasa = const Value.absent(),
    this.squadraTrasferta = const Value.absent(),
    this.risultatoCasa = const Value.absent(),
    this.risultatoTrasferta = const Value.absent(),
    this.parzialiJson = const Value.absent(),
    this.giocatoriCasaJson = const Value.absent(),
    this.giocatoriTrasfertaJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefertiPartitaTableCompanion.insert({
    required String id,
    required String partitaId,
    required String clubId,
    required String squadraCasa,
    required String squadraTrasferta,
    required int risultatoCasa,
    required int risultatoTrasferta,
    this.parzialiJson = const Value.absent(),
    this.giocatoriCasaJson = const Value.absent(),
    this.giocatoriTrasfertaJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       partitaId = Value(partitaId),
       clubId = Value(clubId),
       squadraCasa = Value(squadraCasa),
       squadraTrasferta = Value(squadraTrasferta),
       risultatoCasa = Value(risultatoCasa),
       risultatoTrasferta = Value(risultatoTrasferta);
  static Insertable<RefertiPartitaTableData> custom({
    Expression<String>? id,
    Expression<String>? partitaId,
    Expression<String>? clubId,
    Expression<String>? squadraCasa,
    Expression<String>? squadraTrasferta,
    Expression<int>? risultatoCasa,
    Expression<int>? risultatoTrasferta,
    Expression<String>? parzialiJson,
    Expression<String>? giocatoriCasaJson,
    Expression<String>? giocatoriTrasfertaJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partitaId != null) 'partita_id': partitaId,
      if (clubId != null) 'club_id': clubId,
      if (squadraCasa != null) 'squadra_casa': squadraCasa,
      if (squadraTrasferta != null) 'squadra_trasferta': squadraTrasferta,
      if (risultatoCasa != null) 'risultato_casa': risultatoCasa,
      if (risultatoTrasferta != null) 'risultato_trasferta': risultatoTrasferta,
      if (parzialiJson != null) 'parziali_json': parzialiJson,
      if (giocatoriCasaJson != null) 'giocatori_casa_json': giocatoriCasaJson,
      if (giocatoriTrasfertaJson != null)
        'giocatori_trasferta_json': giocatoriTrasfertaJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefertiPartitaTableCompanion copyWith({
    Value<String>? id,
    Value<String>? partitaId,
    Value<String>? clubId,
    Value<String>? squadraCasa,
    Value<String>? squadraTrasferta,
    Value<int>? risultatoCasa,
    Value<int>? risultatoTrasferta,
    Value<String>? parzialiJson,
    Value<String>? giocatoriCasaJson,
    Value<String>? giocatoriTrasfertaJson,
    Value<int>? rowid,
  }) {
    return RefertiPartitaTableCompanion(
      id: id ?? this.id,
      partitaId: partitaId ?? this.partitaId,
      clubId: clubId ?? this.clubId,
      squadraCasa: squadraCasa ?? this.squadraCasa,
      squadraTrasferta: squadraTrasferta ?? this.squadraTrasferta,
      risultatoCasa: risultatoCasa ?? this.risultatoCasa,
      risultatoTrasferta: risultatoTrasferta ?? this.risultatoTrasferta,
      parzialiJson: parzialiJson ?? this.parzialiJson,
      giocatoriCasaJson: giocatoriCasaJson ?? this.giocatoriCasaJson,
      giocatoriTrasfertaJson:
          giocatoriTrasfertaJson ?? this.giocatoriTrasfertaJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partitaId.present) {
      map['partita_id'] = Variable<String>(partitaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (squadraCasa.present) {
      map['squadra_casa'] = Variable<String>(squadraCasa.value);
    }
    if (squadraTrasferta.present) {
      map['squadra_trasferta'] = Variable<String>(squadraTrasferta.value);
    }
    if (risultatoCasa.present) {
      map['risultato_casa'] = Variable<int>(risultatoCasa.value);
    }
    if (risultatoTrasferta.present) {
      map['risultato_trasferta'] = Variable<int>(risultatoTrasferta.value);
    }
    if (parzialiJson.present) {
      map['parziali_json'] = Variable<String>(parzialiJson.value);
    }
    if (giocatoriCasaJson.present) {
      map['giocatori_casa_json'] = Variable<String>(giocatoriCasaJson.value);
    }
    if (giocatoriTrasfertaJson.present) {
      map['giocatori_trasferta_json'] = Variable<String>(
        giocatoriTrasfertaJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefertiPartitaTableCompanion(')
          ..write('id: $id, ')
          ..write('partitaId: $partitaId, ')
          ..write('clubId: $clubId, ')
          ..write('squadraCasa: $squadraCasa, ')
          ..write('squadraTrasferta: $squadraTrasferta, ')
          ..write('risultatoCasa: $risultatoCasa, ')
          ..write('risultatoTrasferta: $risultatoTrasferta, ')
          ..write('parzialiJson: $parzialiJson, ')
          ..write('giocatoriCasaJson: $giocatoriCasaJson, ')
          ..write('giocatoriTrasfertaJson: $giocatoriTrasfertaJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GruppiTableTable extends GruppiTable
    with TableInfo<$GruppiTableTable, GruppiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GruppiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, clubId, nome, ordine, sport];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gruppi_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GruppiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GruppiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GruppiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      ),
    );
  }

  @override
  $GruppiTableTable createAlias(String alias) {
    return $GruppiTableTable(attachedDatabase, alias);
  }
}

class GruppiTableData extends DataClass implements Insertable<GruppiTableData> {
  final String id;
  final String clubId;
  final String nome;
  final int ordine;
  final String? sport;
  const GruppiTableData({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.ordine,
    this.sport,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['nome'] = Variable<String>(nome);
    map['ordine'] = Variable<int>(ordine);
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    return map;
  }

  GruppiTableCompanion toCompanion(bool nullToAbsent) {
    return GruppiTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      nome: Value(nome),
      ordine: Value(ordine),
      sport: sport == null && nullToAbsent
          ? const Value.absent()
          : Value(sport),
    );
  }

  factory GruppiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GruppiTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      nome: serializer.fromJson<String>(json['nome']),
      ordine: serializer.fromJson<int>(json['ordine']),
      sport: serializer.fromJson<String?>(json['sport']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'nome': serializer.toJson<String>(nome),
      'ordine': serializer.toJson<int>(ordine),
      'sport': serializer.toJson<String?>(sport),
    };
  }

  GruppiTableData copyWith({
    String? id,
    String? clubId,
    String? nome,
    int? ordine,
    Value<String?> sport = const Value.absent(),
  }) => GruppiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    nome: nome ?? this.nome,
    ordine: ordine ?? this.ordine,
    sport: sport.present ? sport.value : this.sport,
  );
  GruppiTableData copyWithCompanion(GruppiTableCompanion data) {
    return GruppiTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      nome: data.nome.present ? data.nome.value : this.nome,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
      sport: data.sport.present ? data.sport.value : this.sport,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GruppiTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('ordine: $ordine, ')
          ..write('sport: $sport')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clubId, nome, ordine, sport);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GruppiTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.nome == this.nome &&
          other.ordine == this.ordine &&
          other.sport == this.sport);
}

class GruppiTableCompanion extends UpdateCompanion<GruppiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> nome;
  final Value<int> ordine;
  final Value<String?> sport;
  final Value<int> rowid;
  const GruppiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.nome = const Value.absent(),
    this.ordine = const Value.absent(),
    this.sport = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GruppiTableCompanion.insert({
    required String id,
    required String clubId,
    required String nome,
    this.ordine = const Value.absent(),
    this.sport = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       nome = Value(nome);
  static Insertable<GruppiTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? nome,
    Expression<int>? ordine,
    Expression<String>? sport,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (nome != null) 'nome': nome,
      if (ordine != null) 'ordine': ordine,
      if (sport != null) 'sport': sport,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GruppiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String>? nome,
    Value<int>? ordine,
    Value<String?>? sport,
    Value<int>? rowid,
  }) {
    return GruppiTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      nome: nome ?? this.nome,
      ordine: ordine ?? this.ordine,
      sport: sport ?? this.sport,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GruppiTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('nome: $nome, ')
          ..write('ordine: $ordine, ')
          ..write('sport: $sport, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GareTableTable extends GareTable
    with TableInfo<$GareTableTable, GareTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GareTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gruppoIdMeta = const VerificationMeta(
    'gruppoId',
  );
  @override
  late final GeneratedColumn<String> gruppoId = GeneratedColumn<String>(
    'gruppo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oraMeta = const VerificationMeta('ora');
  @override
  late final GeneratedColumn<String> ora = GeneratedColumn<String>(
    'ora',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _luogoMeta = const VerificationMeta('luogo');
  @override
  late final GeneratedColumn<String> luogo = GeneratedColumn<String>(
    'luogo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importanzaMeta = const VerificationMeta(
    'importanza',
  );
  @override
  late final GeneratedColumn<String> importanza = GeneratedColumn<String>(
    'importanza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('media'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    gruppoId,
    data,
    ora,
    luogo,
    nome,
    note,
    importanza,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gare_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GareTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('gruppo_id')) {
      context.handle(
        _gruppoIdMeta,
        gruppoId.isAcceptableOrUnknown(data['gruppo_id']!, _gruppoIdMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('ora')) {
      context.handle(
        _oraMeta,
        ora.isAcceptableOrUnknown(data['ora']!, _oraMeta),
      );
    }
    if (data.containsKey('luogo')) {
      context.handle(
        _luogoMeta,
        luogo.isAcceptableOrUnknown(data['luogo']!, _luogoMeta),
      );
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('importanza')) {
      context.handle(
        _importanzaMeta,
        importanza.isAcceptableOrUnknown(data['importanza']!, _importanzaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GareTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GareTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      gruppoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo_id'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      ora: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ora'],
      ),
      luogo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}luogo'],
      ),
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      importanza: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}importanza'],
      )!,
    );
  }

  @override
  $GareTableTable createAlias(String alias) {
    return $GareTableTable(attachedDatabase, alias);
  }
}

class GareTableData extends DataClass implements Insertable<GareTableData> {
  final String id;
  final String clubId;

  /// Gruppo a cui appartiene la gara — null se di tutto il club.
  final String? gruppoId;
  final DateTime data;
  final String? ora;
  final String? luogo;
  final String nome;
  final String? note;

  /// bassa | media | alta — lo scarico pre-gara del generatore
  /// settimanale (FASE 3) scatta solo per "alta".
  final String importanza;
  const GareTableData({
    required this.id,
    required this.clubId,
    this.gruppoId,
    required this.data,
    this.ora,
    this.luogo,
    required this.nome,
    this.note,
    required this.importanza,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    if (!nullToAbsent || gruppoId != null) {
      map['gruppo_id'] = Variable<String>(gruppoId);
    }
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || ora != null) {
      map['ora'] = Variable<String>(ora);
    }
    if (!nullToAbsent || luogo != null) {
      map['luogo'] = Variable<String>(luogo);
    }
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['importanza'] = Variable<String>(importanza);
    return map;
  }

  GareTableCompanion toCompanion(bool nullToAbsent) {
    return GareTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      gruppoId: gruppoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppoId),
      data: Value(data),
      ora: ora == null && nullToAbsent ? const Value.absent() : Value(ora),
      luogo: luogo == null && nullToAbsent
          ? const Value.absent()
          : Value(luogo),
      nome: Value(nome),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      importanza: Value(importanza),
    );
  }

  factory GareTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GareTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      gruppoId: serializer.fromJson<String?>(json['gruppoId']),
      data: serializer.fromJson<DateTime>(json['data']),
      ora: serializer.fromJson<String?>(json['ora']),
      luogo: serializer.fromJson<String?>(json['luogo']),
      nome: serializer.fromJson<String>(json['nome']),
      note: serializer.fromJson<String?>(json['note']),
      importanza: serializer.fromJson<String>(json['importanza']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'gruppoId': serializer.toJson<String?>(gruppoId),
      'data': serializer.toJson<DateTime>(data),
      'ora': serializer.toJson<String?>(ora),
      'luogo': serializer.toJson<String?>(luogo),
      'nome': serializer.toJson<String>(nome),
      'note': serializer.toJson<String?>(note),
      'importanza': serializer.toJson<String>(importanza),
    };
  }

  GareTableData copyWith({
    String? id,
    String? clubId,
    Value<String?> gruppoId = const Value.absent(),
    DateTime? data,
    Value<String?> ora = const Value.absent(),
    Value<String?> luogo = const Value.absent(),
    String? nome,
    Value<String?> note = const Value.absent(),
    String? importanza,
  }) => GareTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    gruppoId: gruppoId.present ? gruppoId.value : this.gruppoId,
    data: data ?? this.data,
    ora: ora.present ? ora.value : this.ora,
    luogo: luogo.present ? luogo.value : this.luogo,
    nome: nome ?? this.nome,
    note: note.present ? note.value : this.note,
    importanza: importanza ?? this.importanza,
  );
  GareTableData copyWithCompanion(GareTableCompanion data) {
    return GareTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      gruppoId: data.gruppoId.present ? data.gruppoId.value : this.gruppoId,
      data: data.data.present ? data.data.value : this.data,
      ora: data.ora.present ? data.ora.value : this.ora,
      luogo: data.luogo.present ? data.luogo.value : this.luogo,
      nome: data.nome.present ? data.nome.value : this.nome,
      note: data.note.present ? data.note.value : this.note,
      importanza: data.importanza.present
          ? data.importanza.value
          : this.importanza,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GareTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('data: $data, ')
          ..write('ora: $ora, ')
          ..write('luogo: $luogo, ')
          ..write('nome: $nome, ')
          ..write('note: $note, ')
          ..write('importanza: $importanza')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    gruppoId,
    data,
    ora,
    luogo,
    nome,
    note,
    importanza,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GareTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.gruppoId == this.gruppoId &&
          other.data == this.data &&
          other.ora == this.ora &&
          other.luogo == this.luogo &&
          other.nome == this.nome &&
          other.note == this.note &&
          other.importanza == this.importanza);
}

class GareTableCompanion extends UpdateCompanion<GareTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String?> gruppoId;
  final Value<DateTime> data;
  final Value<String?> ora;
  final Value<String?> luogo;
  final Value<String> nome;
  final Value<String?> note;
  final Value<String> importanza;
  final Value<int> rowid;
  const GareTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.gruppoId = const Value.absent(),
    this.data = const Value.absent(),
    this.ora = const Value.absent(),
    this.luogo = const Value.absent(),
    this.nome = const Value.absent(),
    this.note = const Value.absent(),
    this.importanza = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GareTableCompanion.insert({
    required String id,
    required String clubId,
    this.gruppoId = const Value.absent(),
    required DateTime data,
    this.ora = const Value.absent(),
    this.luogo = const Value.absent(),
    required String nome,
    this.note = const Value.absent(),
    this.importanza = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       data = Value(data),
       nome = Value(nome);
  static Insertable<GareTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? gruppoId,
    Expression<DateTime>? data,
    Expression<String>? ora,
    Expression<String>? luogo,
    Expression<String>? nome,
    Expression<String>? note,
    Expression<String>? importanza,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (gruppoId != null) 'gruppo_id': gruppoId,
      if (data != null) 'data': data,
      if (ora != null) 'ora': ora,
      if (luogo != null) 'luogo': luogo,
      if (nome != null) 'nome': nome,
      if (note != null) 'note': note,
      if (importanza != null) 'importanza': importanza,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GareTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String?>? gruppoId,
    Value<DateTime>? data,
    Value<String?>? ora,
    Value<String?>? luogo,
    Value<String>? nome,
    Value<String?>? note,
    Value<String>? importanza,
    Value<int>? rowid,
  }) {
    return GareTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      gruppoId: gruppoId ?? this.gruppoId,
      data: data ?? this.data,
      ora: ora ?? this.ora,
      luogo: luogo ?? this.luogo,
      nome: nome ?? this.nome,
      note: note ?? this.note,
      importanza: importanza ?? this.importanza,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (gruppoId.present) {
      map['gruppo_id'] = Variable<String>(gruppoId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (ora.present) {
      map['ora'] = Variable<String>(ora.value);
    }
    if (luogo.present) {
      map['luogo'] = Variable<String>(luogo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (importanza.present) {
      map['importanza'] = Variable<String>(importanza.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GareTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('gruppoId: $gruppoId, ')
          ..write('data: $data, ')
          ..write('ora: $ora, ')
          ..write('luogo: $luogo, ')
          ..write('nome: $nome, ')
          ..write('note: $note, ')
          ..write('importanza: $importanza, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GaraIscrittiTableTable extends GaraIscrittiTable
    with TableInfo<$GaraIscrittiTableTable, GaraIscrittiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GaraIscrittiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _garaIdMeta = const VerificationMeta('garaId');
  @override
  late final GeneratedColumn<String> garaId = GeneratedColumn<String>(
    'gara_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, garaId, atletaId, clubId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gara_iscritti_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GaraIscrittiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gara_id')) {
      context.handle(
        _garaIdMeta,
        garaId.isAcceptableOrUnknown(data['gara_id']!, _garaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_garaIdMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GaraIscrittiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GaraIscrittiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      garaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gara_id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
    );
  }

  @override
  $GaraIscrittiTableTable createAlias(String alias) {
    return $GaraIscrittiTableTable(attachedDatabase, alias);
  }
}

class GaraIscrittiTableData extends DataClass
    implements Insertable<GaraIscrittiTableData> {
  final String id;
  final String garaId;
  final String atletaId;
  final String clubId;
  const GaraIscrittiTableData({
    required this.id,
    required this.garaId,
    required this.atletaId,
    required this.clubId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gara_id'] = Variable<String>(garaId);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    return map;
  }

  GaraIscrittiTableCompanion toCompanion(bool nullToAbsent) {
    return GaraIscrittiTableCompanion(
      id: Value(id),
      garaId: Value(garaId),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
    );
  }

  factory GaraIscrittiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GaraIscrittiTableData(
      id: serializer.fromJson<String>(json['id']),
      garaId: serializer.fromJson<String>(json['garaId']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'garaId': serializer.toJson<String>(garaId),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
    };
  }

  GaraIscrittiTableData copyWith({
    String? id,
    String? garaId,
    String? atletaId,
    String? clubId,
  }) => GaraIscrittiTableData(
    id: id ?? this.id,
    garaId: garaId ?? this.garaId,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
  );
  GaraIscrittiTableData copyWithCompanion(GaraIscrittiTableCompanion data) {
    return GaraIscrittiTableData(
      id: data.id.present ? data.id.value : this.id,
      garaId: data.garaId.present ? data.garaId.value : this.garaId,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GaraIscrittiTableData(')
          ..write('id: $id, ')
          ..write('garaId: $garaId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, garaId, atletaId, clubId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GaraIscrittiTableData &&
          other.id == this.id &&
          other.garaId == this.garaId &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId);
}

class GaraIscrittiTableCompanion
    extends UpdateCompanion<GaraIscrittiTableData> {
  final Value<String> id;
  final Value<String> garaId;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<int> rowid;
  const GaraIscrittiTableCompanion({
    this.id = const Value.absent(),
    this.garaId = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GaraIscrittiTableCompanion.insert({
    required String id,
    required String garaId,
    required String atletaId,
    required String clubId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       garaId = Value(garaId),
       atletaId = Value(atletaId),
       clubId = Value(clubId);
  static Insertable<GaraIscrittiTableData> custom({
    Expression<String>? id,
    Expression<String>? garaId,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (garaId != null) 'gara_id': garaId,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GaraIscrittiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? garaId,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<int>? rowid,
  }) {
    return GaraIscrittiTableCompanion(
      id: id ?? this.id,
      garaId: garaId ?? this.garaId,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (garaId.present) {
      map['gara_id'] = Variable<String>(garaId.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GaraIscrittiTableCompanion(')
          ..write('id: $id, ')
          ..write('garaId: $garaId, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingBlocksTableTable extends TrainingBlocksTable
    with TableInfo<$TrainingBlocksTableTable, TrainingBlocksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingBlocksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codiceMeta = const VerificationMeta('codice');
  @override
  late final GeneratedColumn<String> codice = GeneratedColumn<String>(
    'codice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
    'sport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faseMeta = const VerificationMeta('fase');
  @override
  late final GeneratedColumn<String> fase = GeneratedColumn<String>(
    'fase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obiettivoMeta = const VerificationMeta(
    'obiettivo',
  );
  @override
  late final GeneratedColumn<String> obiettivo = GeneratedColumn<String>(
    'obiettivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneCoinvolteMeta = const VerificationMeta(
    'zoneCoinvolte',
  );
  @override
  late final GeneratedColumn<String> zoneCoinvolte = GeneratedColumn<String>(
    'zone_coinvolte',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titoloMeta = const VerificationMeta('titolo');
  @override
  late final GeneratedColumn<String> titolo = GeneratedColumn<String>(
    'titolo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descrizioneMeta = const VerificationMeta(
    'descrizione',
  );
  @override
  late final GeneratedColumn<String> descrizione = GeneratedColumn<String>(
    'descrizione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stilePrincipaleMeta = const VerificationMeta(
    'stilePrincipale',
  );
  @override
  late final GeneratedColumn<String> stilePrincipale = GeneratedColumn<String>(
    'stile_principale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _livelliMeta = const VerificationMeta(
    'livelli',
  );
  @override
  late final GeneratedColumn<String> livelli = GeneratedColumn<String>(
    'livelli',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attrezziMeta = const VerificationMeta(
    'attrezzi',
  );
  @override
  late final GeneratedColumn<String> attrezzi = GeneratedColumn<String>(
    'attrezzi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metriTotaliMeta = const VerificationMeta(
    'metriTotali',
  );
  @override
  late final GeneratedColumn<int> metriTotali = GeneratedColumn<int>(
    'metri_totali',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durataStimataMinMeta = const VerificationMeta(
    'durataStimataMin',
  );
  @override
  late final GeneratedColumn<int> durataStimataMin = GeneratedColumn<int>(
    'durata_stimata_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statoMeta = const VerificationMeta('stato');
  @override
  late final GeneratedColumn<String> stato = GeneratedColumn<String>(
    'stato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bozza'),
  );
  static const VerificationMeta _fonteMeta = const VerificationMeta('fonte');
  @override
  late final GeneratedColumn<String> fonte = GeneratedColumn<String>(
    'fonte',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Allenatore'),
  );
  static const VerificationMeta _importatoIlMeta = const VerificationMeta(
    'importatoIl',
  );
  @override
  late final GeneratedColumn<DateTime> importatoIl = GeneratedColumn<DateTime>(
    'importato_il',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modificatoInAppMeta = const VerificationMeta(
    'modificatoInApp',
  );
  @override
  late final GeneratedColumn<bool> modificatoInApp = GeneratedColumn<bool>(
    'modificato_in_app',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("modificato_in_app" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    codice,
    sport,
    fase,
    obiettivo,
    zoneCoinvolte,
    titolo,
    descrizione,
    stilePrincipale,
    livelli,
    attrezzi,
    metriTotali,
    durataStimataMin,
    note,
    stato,
    fonte,
    importatoIl,
    modificatoInApp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_blocks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainingBlocksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('codice')) {
      context.handle(
        _codiceMeta,
        codice.isAcceptableOrUnknown(data['codice']!, _codiceMeta),
      );
    } else if (isInserting) {
      context.missing(_codiceMeta);
    }
    if (data.containsKey('sport')) {
      context.handle(
        _sportMeta,
        sport.isAcceptableOrUnknown(data['sport']!, _sportMeta),
      );
    } else if (isInserting) {
      context.missing(_sportMeta);
    }
    if (data.containsKey('fase')) {
      context.handle(
        _faseMeta,
        fase.isAcceptableOrUnknown(data['fase']!, _faseMeta),
      );
    } else if (isInserting) {
      context.missing(_faseMeta);
    }
    if (data.containsKey('obiettivo')) {
      context.handle(
        _obiettivoMeta,
        obiettivo.isAcceptableOrUnknown(data['obiettivo']!, _obiettivoMeta),
      );
    } else if (isInserting) {
      context.missing(_obiettivoMeta);
    }
    if (data.containsKey('zone_coinvolte')) {
      context.handle(
        _zoneCoinvolteMeta,
        zoneCoinvolte.isAcceptableOrUnknown(
          data['zone_coinvolte']!,
          _zoneCoinvolteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zoneCoinvolteMeta);
    }
    if (data.containsKey('titolo')) {
      context.handle(
        _titoloMeta,
        titolo.isAcceptableOrUnknown(data['titolo']!, _titoloMeta),
      );
    } else if (isInserting) {
      context.missing(_titoloMeta);
    }
    if (data.containsKey('descrizione')) {
      context.handle(
        _descrizioneMeta,
        descrizione.isAcceptableOrUnknown(
          data['descrizione']!,
          _descrizioneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descrizioneMeta);
    }
    if (data.containsKey('stile_principale')) {
      context.handle(
        _stilePrincipaleMeta,
        stilePrincipale.isAcceptableOrUnknown(
          data['stile_principale']!,
          _stilePrincipaleMeta,
        ),
      );
    }
    if (data.containsKey('livelli')) {
      context.handle(
        _livelliMeta,
        livelli.isAcceptableOrUnknown(data['livelli']!, _livelliMeta),
      );
    }
    if (data.containsKey('attrezzi')) {
      context.handle(
        _attrezziMeta,
        attrezzi.isAcceptableOrUnknown(data['attrezzi']!, _attrezziMeta),
      );
    }
    if (data.containsKey('metri_totali')) {
      context.handle(
        _metriTotaliMeta,
        metriTotali.isAcceptableOrUnknown(
          data['metri_totali']!,
          _metriTotaliMeta,
        ),
      );
    }
    if (data.containsKey('durata_stimata_min')) {
      context.handle(
        _durataStimataMinMeta,
        durataStimataMin.isAcceptableOrUnknown(
          data['durata_stimata_min']!,
          _durataStimataMinMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('stato')) {
      context.handle(
        _statoMeta,
        stato.isAcceptableOrUnknown(data['stato']!, _statoMeta),
      );
    }
    if (data.containsKey('fonte')) {
      context.handle(
        _fonteMeta,
        fonte.isAcceptableOrUnknown(data['fonte']!, _fonteMeta),
      );
    }
    if (data.containsKey('importato_il')) {
      context.handle(
        _importatoIlMeta,
        importatoIl.isAcceptableOrUnknown(
          data['importato_il']!,
          _importatoIlMeta,
        ),
      );
    }
    if (data.containsKey('modificato_in_app')) {
      context.handle(
        _modificatoInAppMeta,
        modificatoInApp.isAcceptableOrUnknown(
          data['modificato_in_app']!,
          _modificatoInAppMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingBlocksTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingBlocksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      codice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codice'],
      )!,
      sport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sport'],
      )!,
      fase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fase'],
      )!,
      obiettivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obiettivo'],
      )!,
      zoneCoinvolte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_coinvolte'],
      )!,
      titolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titolo'],
      )!,
      descrizione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descrizione'],
      )!,
      stilePrincipale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stile_principale'],
      ),
      livelli: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}livelli'],
      )!,
      attrezzi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attrezzi'],
      ),
      metriTotali: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metri_totali'],
      )!,
      durataStimataMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}durata_stimata_min'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      stato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stato'],
      )!,
      fonte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fonte'],
      )!,
      importatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}importato_il'],
      ),
      modificatoInApp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}modificato_in_app'],
      )!,
    );
  }

  @override
  $TrainingBlocksTableTable createAlias(String alias) {
    return $TrainingBlocksTableTable(attachedDatabase, alias);
  }
}

class TrainingBlocksTableData extends DataClass
    implements Insertable<TrainingBlocksTableData> {
  final String id;
  final String clubId;
  final String codice;
  final String sport;
  final String fase;
  final String obiettivo;
  final String zoneCoinvolte;
  final String titolo;
  final String descrizione;
  final String? stilePrincipale;
  final String livelli;
  final String? attrezzi;
  final int metriTotali;
  final int durataStimataMin;
  final String? note;
  final String stato;
  final String fonte;
  final DateTime? importatoIl;
  final bool modificatoInApp;
  const TrainingBlocksTableData({
    required this.id,
    required this.clubId,
    required this.codice,
    required this.sport,
    required this.fase,
    required this.obiettivo,
    required this.zoneCoinvolte,
    required this.titolo,
    required this.descrizione,
    this.stilePrincipale,
    required this.livelli,
    this.attrezzi,
    required this.metriTotali,
    required this.durataStimataMin,
    this.note,
    required this.stato,
    required this.fonte,
    this.importatoIl,
    required this.modificatoInApp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    map['codice'] = Variable<String>(codice);
    map['sport'] = Variable<String>(sport);
    map['fase'] = Variable<String>(fase);
    map['obiettivo'] = Variable<String>(obiettivo);
    map['zone_coinvolte'] = Variable<String>(zoneCoinvolte);
    map['titolo'] = Variable<String>(titolo);
    map['descrizione'] = Variable<String>(descrizione);
    if (!nullToAbsent || stilePrincipale != null) {
      map['stile_principale'] = Variable<String>(stilePrincipale);
    }
    map['livelli'] = Variable<String>(livelli);
    if (!nullToAbsent || attrezzi != null) {
      map['attrezzi'] = Variable<String>(attrezzi);
    }
    map['metri_totali'] = Variable<int>(metriTotali);
    map['durata_stimata_min'] = Variable<int>(durataStimataMin);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['stato'] = Variable<String>(stato);
    map['fonte'] = Variable<String>(fonte);
    if (!nullToAbsent || importatoIl != null) {
      map['importato_il'] = Variable<DateTime>(importatoIl);
    }
    map['modificato_in_app'] = Variable<bool>(modificatoInApp);
    return map;
  }

  TrainingBlocksTableCompanion toCompanion(bool nullToAbsent) {
    return TrainingBlocksTableCompanion(
      id: Value(id),
      clubId: Value(clubId),
      codice: Value(codice),
      sport: Value(sport),
      fase: Value(fase),
      obiettivo: Value(obiettivo),
      zoneCoinvolte: Value(zoneCoinvolte),
      titolo: Value(titolo),
      descrizione: Value(descrizione),
      stilePrincipale: stilePrincipale == null && nullToAbsent
          ? const Value.absent()
          : Value(stilePrincipale),
      livelli: Value(livelli),
      attrezzi: attrezzi == null && nullToAbsent
          ? const Value.absent()
          : Value(attrezzi),
      metriTotali: Value(metriTotali),
      durataStimataMin: Value(durataStimataMin),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      stato: Value(stato),
      fonte: Value(fonte),
      importatoIl: importatoIl == null && nullToAbsent
          ? const Value.absent()
          : Value(importatoIl),
      modificatoInApp: Value(modificatoInApp),
    );
  }

  factory TrainingBlocksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingBlocksTableData(
      id: serializer.fromJson<String>(json['id']),
      clubId: serializer.fromJson<String>(json['clubId']),
      codice: serializer.fromJson<String>(json['codice']),
      sport: serializer.fromJson<String>(json['sport']),
      fase: serializer.fromJson<String>(json['fase']),
      obiettivo: serializer.fromJson<String>(json['obiettivo']),
      zoneCoinvolte: serializer.fromJson<String>(json['zoneCoinvolte']),
      titolo: serializer.fromJson<String>(json['titolo']),
      descrizione: serializer.fromJson<String>(json['descrizione']),
      stilePrincipale: serializer.fromJson<String?>(json['stilePrincipale']),
      livelli: serializer.fromJson<String>(json['livelli']),
      attrezzi: serializer.fromJson<String?>(json['attrezzi']),
      metriTotali: serializer.fromJson<int>(json['metriTotali']),
      durataStimataMin: serializer.fromJson<int>(json['durataStimataMin']),
      note: serializer.fromJson<String?>(json['note']),
      stato: serializer.fromJson<String>(json['stato']),
      fonte: serializer.fromJson<String>(json['fonte']),
      importatoIl: serializer.fromJson<DateTime?>(json['importatoIl']),
      modificatoInApp: serializer.fromJson<bool>(json['modificatoInApp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'codice': serializer.toJson<String>(codice),
      'sport': serializer.toJson<String>(sport),
      'fase': serializer.toJson<String>(fase),
      'obiettivo': serializer.toJson<String>(obiettivo),
      'zoneCoinvolte': serializer.toJson<String>(zoneCoinvolte),
      'titolo': serializer.toJson<String>(titolo),
      'descrizione': serializer.toJson<String>(descrizione),
      'stilePrincipale': serializer.toJson<String?>(stilePrincipale),
      'livelli': serializer.toJson<String>(livelli),
      'attrezzi': serializer.toJson<String?>(attrezzi),
      'metriTotali': serializer.toJson<int>(metriTotali),
      'durataStimataMin': serializer.toJson<int>(durataStimataMin),
      'note': serializer.toJson<String?>(note),
      'stato': serializer.toJson<String>(stato),
      'fonte': serializer.toJson<String>(fonte),
      'importatoIl': serializer.toJson<DateTime?>(importatoIl),
      'modificatoInApp': serializer.toJson<bool>(modificatoInApp),
    };
  }

  TrainingBlocksTableData copyWith({
    String? id,
    String? clubId,
    String? codice,
    String? sport,
    String? fase,
    String? obiettivo,
    String? zoneCoinvolte,
    String? titolo,
    String? descrizione,
    Value<String?> stilePrincipale = const Value.absent(),
    String? livelli,
    Value<String?> attrezzi = const Value.absent(),
    int? metriTotali,
    int? durataStimataMin,
    Value<String?> note = const Value.absent(),
    String? stato,
    String? fonte,
    Value<DateTime?> importatoIl = const Value.absent(),
    bool? modificatoInApp,
  }) => TrainingBlocksTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    codice: codice ?? this.codice,
    sport: sport ?? this.sport,
    fase: fase ?? this.fase,
    obiettivo: obiettivo ?? this.obiettivo,
    zoneCoinvolte: zoneCoinvolte ?? this.zoneCoinvolte,
    titolo: titolo ?? this.titolo,
    descrizione: descrizione ?? this.descrizione,
    stilePrincipale: stilePrincipale.present
        ? stilePrincipale.value
        : this.stilePrincipale,
    livelli: livelli ?? this.livelli,
    attrezzi: attrezzi.present ? attrezzi.value : this.attrezzi,
    metriTotali: metriTotali ?? this.metriTotali,
    durataStimataMin: durataStimataMin ?? this.durataStimataMin,
    note: note.present ? note.value : this.note,
    stato: stato ?? this.stato,
    fonte: fonte ?? this.fonte,
    importatoIl: importatoIl.present ? importatoIl.value : this.importatoIl,
    modificatoInApp: modificatoInApp ?? this.modificatoInApp,
  );
  TrainingBlocksTableData copyWithCompanion(TrainingBlocksTableCompanion data) {
    return TrainingBlocksTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      codice: data.codice.present ? data.codice.value : this.codice,
      sport: data.sport.present ? data.sport.value : this.sport,
      fase: data.fase.present ? data.fase.value : this.fase,
      obiettivo: data.obiettivo.present ? data.obiettivo.value : this.obiettivo,
      zoneCoinvolte: data.zoneCoinvolte.present
          ? data.zoneCoinvolte.value
          : this.zoneCoinvolte,
      titolo: data.titolo.present ? data.titolo.value : this.titolo,
      descrizione: data.descrizione.present
          ? data.descrizione.value
          : this.descrizione,
      stilePrincipale: data.stilePrincipale.present
          ? data.stilePrincipale.value
          : this.stilePrincipale,
      livelli: data.livelli.present ? data.livelli.value : this.livelli,
      attrezzi: data.attrezzi.present ? data.attrezzi.value : this.attrezzi,
      metriTotali: data.metriTotali.present
          ? data.metriTotali.value
          : this.metriTotali,
      durataStimataMin: data.durataStimataMin.present
          ? data.durataStimataMin.value
          : this.durataStimataMin,
      note: data.note.present ? data.note.value : this.note,
      stato: data.stato.present ? data.stato.value : this.stato,
      fonte: data.fonte.present ? data.fonte.value : this.fonte,
      importatoIl: data.importatoIl.present
          ? data.importatoIl.value
          : this.importatoIl,
      modificatoInApp: data.modificatoInApp.present
          ? data.modificatoInApp.value
          : this.modificatoInApp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingBlocksTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('codice: $codice, ')
          ..write('sport: $sport, ')
          ..write('fase: $fase, ')
          ..write('obiettivo: $obiettivo, ')
          ..write('zoneCoinvolte: $zoneCoinvolte, ')
          ..write('titolo: $titolo, ')
          ..write('descrizione: $descrizione, ')
          ..write('stilePrincipale: $stilePrincipale, ')
          ..write('livelli: $livelli, ')
          ..write('attrezzi: $attrezzi, ')
          ..write('metriTotali: $metriTotali, ')
          ..write('durataStimataMin: $durataStimataMin, ')
          ..write('note: $note, ')
          ..write('stato: $stato, ')
          ..write('fonte: $fonte, ')
          ..write('importatoIl: $importatoIl, ')
          ..write('modificatoInApp: $modificatoInApp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clubId,
    codice,
    sport,
    fase,
    obiettivo,
    zoneCoinvolte,
    titolo,
    descrizione,
    stilePrincipale,
    livelli,
    attrezzi,
    metriTotali,
    durataStimataMin,
    note,
    stato,
    fonte,
    importatoIl,
    modificatoInApp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingBlocksTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.codice == this.codice &&
          other.sport == this.sport &&
          other.fase == this.fase &&
          other.obiettivo == this.obiettivo &&
          other.zoneCoinvolte == this.zoneCoinvolte &&
          other.titolo == this.titolo &&
          other.descrizione == this.descrizione &&
          other.stilePrincipale == this.stilePrincipale &&
          other.livelli == this.livelli &&
          other.attrezzi == this.attrezzi &&
          other.metriTotali == this.metriTotali &&
          other.durataStimataMin == this.durataStimataMin &&
          other.note == this.note &&
          other.stato == this.stato &&
          other.fonte == this.fonte &&
          other.importatoIl == this.importatoIl &&
          other.modificatoInApp == this.modificatoInApp);
}

class TrainingBlocksTableCompanion
    extends UpdateCompanion<TrainingBlocksTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> codice;
  final Value<String> sport;
  final Value<String> fase;
  final Value<String> obiettivo;
  final Value<String> zoneCoinvolte;
  final Value<String> titolo;
  final Value<String> descrizione;
  final Value<String?> stilePrincipale;
  final Value<String> livelli;
  final Value<String?> attrezzi;
  final Value<int> metriTotali;
  final Value<int> durataStimataMin;
  final Value<String?> note;
  final Value<String> stato;
  final Value<String> fonte;
  final Value<DateTime?> importatoIl;
  final Value<bool> modificatoInApp;
  final Value<int> rowid;
  const TrainingBlocksTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.codice = const Value.absent(),
    this.sport = const Value.absent(),
    this.fase = const Value.absent(),
    this.obiettivo = const Value.absent(),
    this.zoneCoinvolte = const Value.absent(),
    this.titolo = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.stilePrincipale = const Value.absent(),
    this.livelli = const Value.absent(),
    this.attrezzi = const Value.absent(),
    this.metriTotali = const Value.absent(),
    this.durataStimataMin = const Value.absent(),
    this.note = const Value.absent(),
    this.stato = const Value.absent(),
    this.fonte = const Value.absent(),
    this.importatoIl = const Value.absent(),
    this.modificatoInApp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingBlocksTableCompanion.insert({
    required String id,
    required String clubId,
    required String codice,
    required String sport,
    required String fase,
    required String obiettivo,
    required String zoneCoinvolte,
    required String titolo,
    required String descrizione,
    this.stilePrincipale = const Value.absent(),
    this.livelli = const Value.absent(),
    this.attrezzi = const Value.absent(),
    this.metriTotali = const Value.absent(),
    this.durataStimataMin = const Value.absent(),
    this.note = const Value.absent(),
    this.stato = const Value.absent(),
    this.fonte = const Value.absent(),
    this.importatoIl = const Value.absent(),
    this.modificatoInApp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       codice = Value(codice),
       sport = Value(sport),
       fase = Value(fase),
       obiettivo = Value(obiettivo),
       zoneCoinvolte = Value(zoneCoinvolte),
       titolo = Value(titolo),
       descrizione = Value(descrizione);
  static Insertable<TrainingBlocksTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? codice,
    Expression<String>? sport,
    Expression<String>? fase,
    Expression<String>? obiettivo,
    Expression<String>? zoneCoinvolte,
    Expression<String>? titolo,
    Expression<String>? descrizione,
    Expression<String>? stilePrincipale,
    Expression<String>? livelli,
    Expression<String>? attrezzi,
    Expression<int>? metriTotali,
    Expression<int>? durataStimataMin,
    Expression<String>? note,
    Expression<String>? stato,
    Expression<String>? fonte,
    Expression<DateTime>? importatoIl,
    Expression<bool>? modificatoInApp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (codice != null) 'codice': codice,
      if (sport != null) 'sport': sport,
      if (fase != null) 'fase': fase,
      if (obiettivo != null) 'obiettivo': obiettivo,
      if (zoneCoinvolte != null) 'zone_coinvolte': zoneCoinvolte,
      if (titolo != null) 'titolo': titolo,
      if (descrizione != null) 'descrizione': descrizione,
      if (stilePrincipale != null) 'stile_principale': stilePrincipale,
      if (livelli != null) 'livelli': livelli,
      if (attrezzi != null) 'attrezzi': attrezzi,
      if (metriTotali != null) 'metri_totali': metriTotali,
      if (durataStimataMin != null) 'durata_stimata_min': durataStimataMin,
      if (note != null) 'note': note,
      if (stato != null) 'stato': stato,
      if (fonte != null) 'fonte': fonte,
      if (importatoIl != null) 'importato_il': importatoIl,
      if (modificatoInApp != null) 'modificato_in_app': modificatoInApp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingBlocksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String>? codice,
    Value<String>? sport,
    Value<String>? fase,
    Value<String>? obiettivo,
    Value<String>? zoneCoinvolte,
    Value<String>? titolo,
    Value<String>? descrizione,
    Value<String?>? stilePrincipale,
    Value<String>? livelli,
    Value<String?>? attrezzi,
    Value<int>? metriTotali,
    Value<int>? durataStimataMin,
    Value<String?>? note,
    Value<String>? stato,
    Value<String>? fonte,
    Value<DateTime?>? importatoIl,
    Value<bool>? modificatoInApp,
    Value<int>? rowid,
  }) {
    return TrainingBlocksTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      codice: codice ?? this.codice,
      sport: sport ?? this.sport,
      fase: fase ?? this.fase,
      obiettivo: obiettivo ?? this.obiettivo,
      zoneCoinvolte: zoneCoinvolte ?? this.zoneCoinvolte,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      stilePrincipale: stilePrincipale ?? this.stilePrincipale,
      livelli: livelli ?? this.livelli,
      attrezzi: attrezzi ?? this.attrezzi,
      metriTotali: metriTotali ?? this.metriTotali,
      durataStimataMin: durataStimataMin ?? this.durataStimataMin,
      note: note ?? this.note,
      stato: stato ?? this.stato,
      fonte: fonte ?? this.fonte,
      importatoIl: importatoIl ?? this.importatoIl,
      modificatoInApp: modificatoInApp ?? this.modificatoInApp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (codice.present) {
      map['codice'] = Variable<String>(codice.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (fase.present) {
      map['fase'] = Variable<String>(fase.value);
    }
    if (obiettivo.present) {
      map['obiettivo'] = Variable<String>(obiettivo.value);
    }
    if (zoneCoinvolte.present) {
      map['zone_coinvolte'] = Variable<String>(zoneCoinvolte.value);
    }
    if (titolo.present) {
      map['titolo'] = Variable<String>(titolo.value);
    }
    if (descrizione.present) {
      map['descrizione'] = Variable<String>(descrizione.value);
    }
    if (stilePrincipale.present) {
      map['stile_principale'] = Variable<String>(stilePrincipale.value);
    }
    if (livelli.present) {
      map['livelli'] = Variable<String>(livelli.value);
    }
    if (attrezzi.present) {
      map['attrezzi'] = Variable<String>(attrezzi.value);
    }
    if (metriTotali.present) {
      map['metri_totali'] = Variable<int>(metriTotali.value);
    }
    if (durataStimataMin.present) {
      map['durata_stimata_min'] = Variable<int>(durataStimataMin.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (stato.present) {
      map['stato'] = Variable<String>(stato.value);
    }
    if (fonte.present) {
      map['fonte'] = Variable<String>(fonte.value);
    }
    if (importatoIl.present) {
      map['importato_il'] = Variable<DateTime>(importatoIl.value);
    }
    if (modificatoInApp.present) {
      map['modificato_in_app'] = Variable<bool>(modificatoInApp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingBlocksTableCompanion(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('codice: $codice, ')
          ..write('sport: $sport, ')
          ..write('fase: $fase, ')
          ..write('obiettivo: $obiettivo, ')
          ..write('zoneCoinvolte: $zoneCoinvolte, ')
          ..write('titolo: $titolo, ')
          ..write('descrizione: $descrizione, ')
          ..write('stilePrincipale: $stilePrincipale, ')
          ..write('livelli: $livelli, ')
          ..write('attrezzi: $attrezzi, ')
          ..write('metriTotali: $metriTotali, ')
          ..write('durataStimataMin: $durataStimataMin, ')
          ..write('note: $note, ')
          ..write('stato: $stato, ')
          ..write('fonte: $fonte, ')
          ..write('importatoIl: $importatoIl, ')
          ..write('modificatoInApp: $modificatoInApp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrainingBlockPartiTableTable extends TrainingBlockPartiTable
    with TableInfo<$TrainingBlockPartiTableTable, TrainingBlockPartiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingBlockPartiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bloccoIdMeta = const VerificationMeta(
    'bloccoId',
  );
  @override
  late final GeneratedColumn<String> bloccoId = GeneratedColumn<String>(
    'blocco_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _giriMeta = const VerificationMeta('giri');
  @override
  late final GeneratedColumn<int> giri = GeneratedColumn<int>(
    'giri',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _ripetizioniMeta = const VerificationMeta(
    'ripetizioni',
  );
  @override
  late final GeneratedColumn<int> ripetizioni = GeneratedColumn<int>(
    'ripetizioni',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _distanzaMMeta = const VerificationMeta(
    'distanzaM',
  );
  @override
  late final GeneratedColumn<int> distanzaM = GeneratedColumn<int>(
    'distanza_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durataSMeta = const VerificationMeta(
    'durataS',
  );
  @override
  late final GeneratedColumn<int> durataS = GeneratedColumn<int>(
    'durata_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stileMeta = const VerificationMeta('stile');
  @override
  late final GeneratedColumn<String> stile = GeneratedColumn<String>(
    'stile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _esercizioMeta = const VerificationMeta(
    'esercizio',
  );
  @override
  late final GeneratedColumn<String> esercizio = GeneratedColumn<String>(
    'esercizio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
    'zona',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _esecuzioneMeta = const VerificationMeta(
    'esecuzione',
  );
  @override
  late final GeneratedColumn<String> esecuzione = GeneratedColumn<String>(
    'esecuzione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recuperoSMeta = const VerificationMeta(
    'recuperoS',
  );
  @override
  late final GeneratedColumn<int> recuperoS = GeneratedColumn<int>(
    'recupero_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attrezziMeta = const VerificationMeta(
    'attrezzi',
  );
  @override
  late final GeneratedColumn<String> attrezzi = GeneratedColumn<String>(
    'attrezzi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bloccoId,
    clubId,
    ordine,
    giri,
    ripetizioni,
    distanzaM,
    durataS,
    stile,
    esercizio,
    zona,
    esecuzione,
    recuperoS,
    attrezzi,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_block_parti_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrainingBlockPartiTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('blocco_id')) {
      context.handle(
        _bloccoIdMeta,
        bloccoId.isAcceptableOrUnknown(data['blocco_id']!, _bloccoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bloccoIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    }
    if (data.containsKey('giri')) {
      context.handle(
        _giriMeta,
        giri.isAcceptableOrUnknown(data['giri']!, _giriMeta),
      );
    }
    if (data.containsKey('ripetizioni')) {
      context.handle(
        _ripetizioniMeta,
        ripetizioni.isAcceptableOrUnknown(
          data['ripetizioni']!,
          _ripetizioniMeta,
        ),
      );
    }
    if (data.containsKey('distanza_m')) {
      context.handle(
        _distanzaMMeta,
        distanzaM.isAcceptableOrUnknown(data['distanza_m']!, _distanzaMMeta),
      );
    }
    if (data.containsKey('durata_s')) {
      context.handle(
        _durataSMeta,
        durataS.isAcceptableOrUnknown(data['durata_s']!, _durataSMeta),
      );
    }
    if (data.containsKey('stile')) {
      context.handle(
        _stileMeta,
        stile.isAcceptableOrUnknown(data['stile']!, _stileMeta),
      );
    }
    if (data.containsKey('esercizio')) {
      context.handle(
        _esercizioMeta,
        esercizio.isAcceptableOrUnknown(data['esercizio']!, _esercizioMeta),
      );
    }
    if (data.containsKey('zona')) {
      context.handle(
        _zonaMeta,
        zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta),
      );
    } else if (isInserting) {
      context.missing(_zonaMeta);
    }
    if (data.containsKey('esecuzione')) {
      context.handle(
        _esecuzioneMeta,
        esecuzione.isAcceptableOrUnknown(data['esecuzione']!, _esecuzioneMeta),
      );
    } else if (isInserting) {
      context.missing(_esecuzioneMeta);
    }
    if (data.containsKey('recupero_s')) {
      context.handle(
        _recuperoSMeta,
        recuperoS.isAcceptableOrUnknown(data['recupero_s']!, _recuperoSMeta),
      );
    }
    if (data.containsKey('attrezzi')) {
      context.handle(
        _attrezziMeta,
        attrezzi.isAcceptableOrUnknown(data['attrezzi']!, _attrezziMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingBlockPartiTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingBlockPartiTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bloccoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocco_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
      giri: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}giri'],
      )!,
      ripetizioni: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ripetizioni'],
      )!,
      distanzaM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distanza_m'],
      ),
      durataS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}durata_s'],
      ),
      stile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stile'],
      ),
      esercizio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esercizio'],
      ),
      zona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zona'],
      )!,
      esecuzione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esecuzione'],
      )!,
      recuperoS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recupero_s'],
      ),
      attrezzi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attrezzi'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TrainingBlockPartiTableTable createAlias(String alias) {
    return $TrainingBlockPartiTableTable(attachedDatabase, alias);
  }
}

class TrainingBlockPartiTableData extends DataClass
    implements Insertable<TrainingBlockPartiTableData> {
  final String id;
  final String bloccoId;
  final String clubId;
  final int ordine;
  final int giri;
  final int ripetizioni;
  final int? distanzaM;
  final int? durataS;
  final String? stile;
  final String? esercizio;
  final String zona;
  final String esecuzione;
  final int? recuperoS;
  final String? attrezzi;
  final String? note;
  const TrainingBlockPartiTableData({
    required this.id,
    required this.bloccoId,
    required this.clubId,
    required this.ordine,
    required this.giri,
    required this.ripetizioni,
    this.distanzaM,
    this.durataS,
    this.stile,
    this.esercizio,
    required this.zona,
    required this.esecuzione,
    this.recuperoS,
    this.attrezzi,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['blocco_id'] = Variable<String>(bloccoId);
    map['club_id'] = Variable<String>(clubId);
    map['ordine'] = Variable<int>(ordine);
    map['giri'] = Variable<int>(giri);
    map['ripetizioni'] = Variable<int>(ripetizioni);
    if (!nullToAbsent || distanzaM != null) {
      map['distanza_m'] = Variable<int>(distanzaM);
    }
    if (!nullToAbsent || durataS != null) {
      map['durata_s'] = Variable<int>(durataS);
    }
    if (!nullToAbsent || stile != null) {
      map['stile'] = Variable<String>(stile);
    }
    if (!nullToAbsent || esercizio != null) {
      map['esercizio'] = Variable<String>(esercizio);
    }
    map['zona'] = Variable<String>(zona);
    map['esecuzione'] = Variable<String>(esecuzione);
    if (!nullToAbsent || recuperoS != null) {
      map['recupero_s'] = Variable<int>(recuperoS);
    }
    if (!nullToAbsent || attrezzi != null) {
      map['attrezzi'] = Variable<String>(attrezzi);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TrainingBlockPartiTableCompanion toCompanion(bool nullToAbsent) {
    return TrainingBlockPartiTableCompanion(
      id: Value(id),
      bloccoId: Value(bloccoId),
      clubId: Value(clubId),
      ordine: Value(ordine),
      giri: Value(giri),
      ripetizioni: Value(ripetizioni),
      distanzaM: distanzaM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanzaM),
      durataS: durataS == null && nullToAbsent
          ? const Value.absent()
          : Value(durataS),
      stile: stile == null && nullToAbsent
          ? const Value.absent()
          : Value(stile),
      esercizio: esercizio == null && nullToAbsent
          ? const Value.absent()
          : Value(esercizio),
      zona: Value(zona),
      esecuzione: Value(esecuzione),
      recuperoS: recuperoS == null && nullToAbsent
          ? const Value.absent()
          : Value(recuperoS),
      attrezzi: attrezzi == null && nullToAbsent
          ? const Value.absent()
          : Value(attrezzi),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TrainingBlockPartiTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingBlockPartiTableData(
      id: serializer.fromJson<String>(json['id']),
      bloccoId: serializer.fromJson<String>(json['bloccoId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      ordine: serializer.fromJson<int>(json['ordine']),
      giri: serializer.fromJson<int>(json['giri']),
      ripetizioni: serializer.fromJson<int>(json['ripetizioni']),
      distanzaM: serializer.fromJson<int?>(json['distanzaM']),
      durataS: serializer.fromJson<int?>(json['durataS']),
      stile: serializer.fromJson<String?>(json['stile']),
      esercizio: serializer.fromJson<String?>(json['esercizio']),
      zona: serializer.fromJson<String>(json['zona']),
      esecuzione: serializer.fromJson<String>(json['esecuzione']),
      recuperoS: serializer.fromJson<int?>(json['recuperoS']),
      attrezzi: serializer.fromJson<String?>(json['attrezzi']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bloccoId': serializer.toJson<String>(bloccoId),
      'clubId': serializer.toJson<String>(clubId),
      'ordine': serializer.toJson<int>(ordine),
      'giri': serializer.toJson<int>(giri),
      'ripetizioni': serializer.toJson<int>(ripetizioni),
      'distanzaM': serializer.toJson<int?>(distanzaM),
      'durataS': serializer.toJson<int?>(durataS),
      'stile': serializer.toJson<String?>(stile),
      'esercizio': serializer.toJson<String?>(esercizio),
      'zona': serializer.toJson<String>(zona),
      'esecuzione': serializer.toJson<String>(esecuzione),
      'recuperoS': serializer.toJson<int?>(recuperoS),
      'attrezzi': serializer.toJson<String?>(attrezzi),
      'note': serializer.toJson<String?>(note),
    };
  }

  TrainingBlockPartiTableData copyWith({
    String? id,
    String? bloccoId,
    String? clubId,
    int? ordine,
    int? giri,
    int? ripetizioni,
    Value<int?> distanzaM = const Value.absent(),
    Value<int?> durataS = const Value.absent(),
    Value<String?> stile = const Value.absent(),
    Value<String?> esercizio = const Value.absent(),
    String? zona,
    String? esecuzione,
    Value<int?> recuperoS = const Value.absent(),
    Value<String?> attrezzi = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => TrainingBlockPartiTableData(
    id: id ?? this.id,
    bloccoId: bloccoId ?? this.bloccoId,
    clubId: clubId ?? this.clubId,
    ordine: ordine ?? this.ordine,
    giri: giri ?? this.giri,
    ripetizioni: ripetizioni ?? this.ripetizioni,
    distanzaM: distanzaM.present ? distanzaM.value : this.distanzaM,
    durataS: durataS.present ? durataS.value : this.durataS,
    stile: stile.present ? stile.value : this.stile,
    esercizio: esercizio.present ? esercizio.value : this.esercizio,
    zona: zona ?? this.zona,
    esecuzione: esecuzione ?? this.esecuzione,
    recuperoS: recuperoS.present ? recuperoS.value : this.recuperoS,
    attrezzi: attrezzi.present ? attrezzi.value : this.attrezzi,
    note: note.present ? note.value : this.note,
  );
  TrainingBlockPartiTableData copyWithCompanion(
    TrainingBlockPartiTableCompanion data,
  ) {
    return TrainingBlockPartiTableData(
      id: data.id.present ? data.id.value : this.id,
      bloccoId: data.bloccoId.present ? data.bloccoId.value : this.bloccoId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
      giri: data.giri.present ? data.giri.value : this.giri,
      ripetizioni: data.ripetizioni.present
          ? data.ripetizioni.value
          : this.ripetizioni,
      distanzaM: data.distanzaM.present ? data.distanzaM.value : this.distanzaM,
      durataS: data.durataS.present ? data.durataS.value : this.durataS,
      stile: data.stile.present ? data.stile.value : this.stile,
      esercizio: data.esercizio.present ? data.esercizio.value : this.esercizio,
      zona: data.zona.present ? data.zona.value : this.zona,
      esecuzione: data.esecuzione.present
          ? data.esecuzione.value
          : this.esecuzione,
      recuperoS: data.recuperoS.present ? data.recuperoS.value : this.recuperoS,
      attrezzi: data.attrezzi.present ? data.attrezzi.value : this.attrezzi,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingBlockPartiTableData(')
          ..write('id: $id, ')
          ..write('bloccoId: $bloccoId, ')
          ..write('clubId: $clubId, ')
          ..write('ordine: $ordine, ')
          ..write('giri: $giri, ')
          ..write('ripetizioni: $ripetizioni, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('durataS: $durataS, ')
          ..write('stile: $stile, ')
          ..write('esercizio: $esercizio, ')
          ..write('zona: $zona, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('attrezzi: $attrezzi, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bloccoId,
    clubId,
    ordine,
    giri,
    ripetizioni,
    distanzaM,
    durataS,
    stile,
    esercizio,
    zona,
    esecuzione,
    recuperoS,
    attrezzi,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingBlockPartiTableData &&
          other.id == this.id &&
          other.bloccoId == this.bloccoId &&
          other.clubId == this.clubId &&
          other.ordine == this.ordine &&
          other.giri == this.giri &&
          other.ripetizioni == this.ripetizioni &&
          other.distanzaM == this.distanzaM &&
          other.durataS == this.durataS &&
          other.stile == this.stile &&
          other.esercizio == this.esercizio &&
          other.zona == this.zona &&
          other.esecuzione == this.esecuzione &&
          other.recuperoS == this.recuperoS &&
          other.attrezzi == this.attrezzi &&
          other.note == this.note);
}

class TrainingBlockPartiTableCompanion
    extends UpdateCompanion<TrainingBlockPartiTableData> {
  final Value<String> id;
  final Value<String> bloccoId;
  final Value<String> clubId;
  final Value<int> ordine;
  final Value<int> giri;
  final Value<int> ripetizioni;
  final Value<int?> distanzaM;
  final Value<int?> durataS;
  final Value<String?> stile;
  final Value<String?> esercizio;
  final Value<String> zona;
  final Value<String> esecuzione;
  final Value<int?> recuperoS;
  final Value<String?> attrezzi;
  final Value<String?> note;
  final Value<int> rowid;
  const TrainingBlockPartiTableCompanion({
    this.id = const Value.absent(),
    this.bloccoId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.ordine = const Value.absent(),
    this.giri = const Value.absent(),
    this.ripetizioni = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.durataS = const Value.absent(),
    this.stile = const Value.absent(),
    this.esercizio = const Value.absent(),
    this.zona = const Value.absent(),
    this.esecuzione = const Value.absent(),
    this.recuperoS = const Value.absent(),
    this.attrezzi = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrainingBlockPartiTableCompanion.insert({
    required String id,
    required String bloccoId,
    required String clubId,
    this.ordine = const Value.absent(),
    this.giri = const Value.absent(),
    this.ripetizioni = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.durataS = const Value.absent(),
    this.stile = const Value.absent(),
    this.esercizio = const Value.absent(),
    required String zona,
    required String esecuzione,
    this.recuperoS = const Value.absent(),
    this.attrezzi = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bloccoId = Value(bloccoId),
       clubId = Value(clubId),
       zona = Value(zona),
       esecuzione = Value(esecuzione);
  static Insertable<TrainingBlockPartiTableData> custom({
    Expression<String>? id,
    Expression<String>? bloccoId,
    Expression<String>? clubId,
    Expression<int>? ordine,
    Expression<int>? giri,
    Expression<int>? ripetizioni,
    Expression<int>? distanzaM,
    Expression<int>? durataS,
    Expression<String>? stile,
    Expression<String>? esercizio,
    Expression<String>? zona,
    Expression<String>? esecuzione,
    Expression<int>? recuperoS,
    Expression<String>? attrezzi,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bloccoId != null) 'blocco_id': bloccoId,
      if (clubId != null) 'club_id': clubId,
      if (ordine != null) 'ordine': ordine,
      if (giri != null) 'giri': giri,
      if (ripetizioni != null) 'ripetizioni': ripetizioni,
      if (distanzaM != null) 'distanza_m': distanzaM,
      if (durataS != null) 'durata_s': durataS,
      if (stile != null) 'stile': stile,
      if (esercizio != null) 'esercizio': esercizio,
      if (zona != null) 'zona': zona,
      if (esecuzione != null) 'esecuzione': esecuzione,
      if (recuperoS != null) 'recupero_s': recuperoS,
      if (attrezzi != null) 'attrezzi': attrezzi,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrainingBlockPartiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? bloccoId,
    Value<String>? clubId,
    Value<int>? ordine,
    Value<int>? giri,
    Value<int>? ripetizioni,
    Value<int?>? distanzaM,
    Value<int?>? durataS,
    Value<String?>? stile,
    Value<String?>? esercizio,
    Value<String>? zona,
    Value<String>? esecuzione,
    Value<int?>? recuperoS,
    Value<String?>? attrezzi,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TrainingBlockPartiTableCompanion(
      id: id ?? this.id,
      bloccoId: bloccoId ?? this.bloccoId,
      clubId: clubId ?? this.clubId,
      ordine: ordine ?? this.ordine,
      giri: giri ?? this.giri,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      distanzaM: distanzaM ?? this.distanzaM,
      durataS: durataS ?? this.durataS,
      stile: stile ?? this.stile,
      esercizio: esercizio ?? this.esercizio,
      zona: zona ?? this.zona,
      esecuzione: esecuzione ?? this.esecuzione,
      recuperoS: recuperoS ?? this.recuperoS,
      attrezzi: attrezzi ?? this.attrezzi,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bloccoId.present) {
      map['blocco_id'] = Variable<String>(bloccoId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (giri.present) {
      map['giri'] = Variable<int>(giri.value);
    }
    if (ripetizioni.present) {
      map['ripetizioni'] = Variable<int>(ripetizioni.value);
    }
    if (distanzaM.present) {
      map['distanza_m'] = Variable<int>(distanzaM.value);
    }
    if (durataS.present) {
      map['durata_s'] = Variable<int>(durataS.value);
    }
    if (stile.present) {
      map['stile'] = Variable<String>(stile.value);
    }
    if (esercizio.present) {
      map['esercizio'] = Variable<String>(esercizio.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (esecuzione.present) {
      map['esecuzione'] = Variable<String>(esecuzione.value);
    }
    if (recuperoS.present) {
      map['recupero_s'] = Variable<int>(recuperoS.value);
    }
    if (attrezzi.present) {
      map['attrezzi'] = Variable<String>(attrezzi.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingBlockPartiTableCompanion(')
          ..write('id: $id, ')
          ..write('bloccoId: $bloccoId, ')
          ..write('clubId: $clubId, ')
          ..write('ordine: $ordine, ')
          ..write('giri: $giri, ')
          ..write('ripetizioni: $ripetizioni, ')
          ..write('distanzaM: $distanzaM, ')
          ..write('durataS: $durataS, ')
          ..write('stile: $stile, ')
          ..write('esercizio: $esercizio, ')
          ..write('zona: $zona, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('attrezzi: $attrezzi, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedeBenessereTableTable extends SchedeBenessereTable
    with TableInfo<$SchedeBenessereTableTable, SchedeBenessereTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedeBenessereTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atletaIdMeta = const VerificationMeta(
    'atletaId',
  );
  @override
  late final GeneratedColumn<String> atletaId = GeneratedColumn<String>(
    'atleta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventoTipoMeta = const VerificationMeta(
    'eventoTipo',
  );
  @override
  late final GeneratedColumn<String> eventoTipo = GeneratedColumn<String>(
    'evento_tipo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventoIdMeta = const VerificationMeta(
    'eventoId',
  );
  @override
  late final GeneratedColumn<String> eventoId = GeneratedColumn<String>(
    'evento_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doloriMeta = const VerificationMeta('dolori');
  @override
  late final GeneratedColumn<bool> dolori = GeneratedColumn<bool>(
    'dolori',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dolori" IN (0, 1))',
    ),
  );
  static const VerificationMeta _zoneDoloreJsonMeta = const VerificationMeta(
    'zoneDoloreJson',
  );
  @override
  late final GeneratedColumn<String> zoneDoloreJson = GeneratedColumn<String>(
    'zone_dolore_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _intensitaDoloreMeta = const VerificationMeta(
    'intensitaDolore',
  );
  @override
  late final GeneratedColumn<int> intensitaDolore = GeneratedColumn<int>(
    'intensita_dolore',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oreSonnoMeta = const VerificationMeta(
    'oreSonno',
  );
  @override
  late final GeneratedColumn<double> oreSonno = GeneratedColumn<double>(
    'ore_sonno',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compilataIlMeta = const VerificationMeta(
    'compilataIl',
  );
  @override
  late final GeneratedColumn<DateTime> compilataIl = GeneratedColumn<DateTime>(
    'compilata_il',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualitaSonnoMeta = const VerificationMeta(
    'qualitaSonno',
  );
  @override
  late final GeneratedColumn<int> qualitaSonno = GeneratedColumn<int>(
    'qualita_sonno',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energiaMeta = const VerificationMeta(
    'energia',
  );
  @override
  late final GeneratedColumn<int> energia = GeneratedColumn<int>(
    'energia',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _muscoliMeta = const VerificationMeta(
    'muscoli',
  );
  @override
  late final GeneratedColumn<int> muscoli = GeneratedColumn<int>(
    'muscoli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stressMeta = const VerificationMeta('stress');
  @override
  late final GeneratedColumn<int> stress = GeneratedColumn<int>(
    'stress',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _umoreMeta = const VerificationMeta('umore');
  @override
  late final GeneratedColumn<int> umore = GeneratedColumn<int>(
    'umore',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sintomiJsonMeta = const VerificationMeta(
    'sintomiJson',
  );
  @override
  late final GeneratedColumn<String> sintomiJson = GeneratedColumn<String>(
    'sintomi_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    atletaId,
    clubId,
    data,
    eventoTipo,
    eventoId,
    dolori,
    zoneDoloreJson,
    intensitaDolore,
    oreSonno,
    compilataIl,
    qualitaSonno,
    energia,
    muscoli,
    stress,
    umore,
    sintomiJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schede_benessere_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchedeBenessereTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('atleta_id')) {
      context.handle(
        _atletaIdMeta,
        atletaId.isAcceptableOrUnknown(data['atleta_id']!, _atletaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_atletaIdMeta);
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('evento_tipo')) {
      context.handle(
        _eventoTipoMeta,
        eventoTipo.isAcceptableOrUnknown(data['evento_tipo']!, _eventoTipoMeta),
      );
    }
    if (data.containsKey('evento_id')) {
      context.handle(
        _eventoIdMeta,
        eventoId.isAcceptableOrUnknown(data['evento_id']!, _eventoIdMeta),
      );
    }
    if (data.containsKey('dolori')) {
      context.handle(
        _doloriMeta,
        dolori.isAcceptableOrUnknown(data['dolori']!, _doloriMeta),
      );
    } else if (isInserting) {
      context.missing(_doloriMeta);
    }
    if (data.containsKey('zone_dolore_json')) {
      context.handle(
        _zoneDoloreJsonMeta,
        zoneDoloreJson.isAcceptableOrUnknown(
          data['zone_dolore_json']!,
          _zoneDoloreJsonMeta,
        ),
      );
    }
    if (data.containsKey('intensita_dolore')) {
      context.handle(
        _intensitaDoloreMeta,
        intensitaDolore.isAcceptableOrUnknown(
          data['intensita_dolore']!,
          _intensitaDoloreMeta,
        ),
      );
    }
    if (data.containsKey('ore_sonno')) {
      context.handle(
        _oreSonnoMeta,
        oreSonno.isAcceptableOrUnknown(data['ore_sonno']!, _oreSonnoMeta),
      );
    } else if (isInserting) {
      context.missing(_oreSonnoMeta);
    }
    if (data.containsKey('compilata_il')) {
      context.handle(
        _compilataIlMeta,
        compilataIl.isAcceptableOrUnknown(
          data['compilata_il']!,
          _compilataIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compilataIlMeta);
    }
    if (data.containsKey('qualita_sonno')) {
      context.handle(
        _qualitaSonnoMeta,
        qualitaSonno.isAcceptableOrUnknown(
          data['qualita_sonno']!,
          _qualitaSonnoMeta,
        ),
      );
    }
    if (data.containsKey('energia')) {
      context.handle(
        _energiaMeta,
        energia.isAcceptableOrUnknown(data['energia']!, _energiaMeta),
      );
    }
    if (data.containsKey('muscoli')) {
      context.handle(
        _muscoliMeta,
        muscoli.isAcceptableOrUnknown(data['muscoli']!, _muscoliMeta),
      );
    }
    if (data.containsKey('stress')) {
      context.handle(
        _stressMeta,
        stress.isAcceptableOrUnknown(data['stress']!, _stressMeta),
      );
    }
    if (data.containsKey('umore')) {
      context.handle(
        _umoreMeta,
        umore.isAcceptableOrUnknown(data['umore']!, _umoreMeta),
      );
    }
    if (data.containsKey('sintomi_json')) {
      context.handle(
        _sintomiJsonMeta,
        sintomiJson.isAcceptableOrUnknown(
          data['sintomi_json']!,
          _sintomiJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchedeBenessereTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchedeBenessereTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      atletaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}atleta_id'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      eventoTipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evento_tipo'],
      ),
      eventoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evento_id'],
      ),
      dolori: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dolori'],
      )!,
      zoneDoloreJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_dolore_json'],
      )!,
      intensitaDolore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensita_dolore'],
      ),
      oreSonno: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ore_sonno'],
      )!,
      compilataIl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}compilata_il'],
      )!,
      qualitaSonno: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qualita_sonno'],
      ),
      energia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energia'],
      ),
      muscoli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muscoli'],
      ),
      stress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stress'],
      ),
      umore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}umore'],
      ),
      sintomiJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sintomi_json'],
      )!,
    );
  }

  @override
  $SchedeBenessereTableTable createAlias(String alias) {
    return $SchedeBenessereTableTable(attachedDatabase, alias);
  }
}

class SchedeBenessereTableData extends DataClass
    implements Insertable<SchedeBenessereTableData> {
  final String id;
  final String atletaId;
  final String clubId;
  final DateTime data;
  final String? eventoTipo;
  final String? eventoId;
  final bool dolori;

  /// Zone del corpo come lista JSON (es. `["spalla","ginocchio"]`).
  final String zoneDoloreJson;
  final int? intensitaDolore;
  final double oreSonno;
  final DateTime compilataIl;

  /// Voci del questionario di McLean (1-5, 5 = meglio): null per le
  /// schede compilate prima della seconda versione.
  final int? qualitaSonno;
  final int? energia;
  final int? muscoli;
  final int? stress;
  final int? umore;

  /// Sintomi di malattia come lista JSON (es. `["febbre"]`).
  final String sintomiJson;
  const SchedeBenessereTableData({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.data,
    this.eventoTipo,
    this.eventoId,
    required this.dolori,
    required this.zoneDoloreJson,
    this.intensitaDolore,
    required this.oreSonno,
    required this.compilataIl,
    this.qualitaSonno,
    this.energia,
    this.muscoli,
    this.stress,
    this.umore,
    required this.sintomiJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['atleta_id'] = Variable<String>(atletaId);
    map['club_id'] = Variable<String>(clubId);
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || eventoTipo != null) {
      map['evento_tipo'] = Variable<String>(eventoTipo);
    }
    if (!nullToAbsent || eventoId != null) {
      map['evento_id'] = Variable<String>(eventoId);
    }
    map['dolori'] = Variable<bool>(dolori);
    map['zone_dolore_json'] = Variable<String>(zoneDoloreJson);
    if (!nullToAbsent || intensitaDolore != null) {
      map['intensita_dolore'] = Variable<int>(intensitaDolore);
    }
    map['ore_sonno'] = Variable<double>(oreSonno);
    map['compilata_il'] = Variable<DateTime>(compilataIl);
    if (!nullToAbsent || qualitaSonno != null) {
      map['qualita_sonno'] = Variable<int>(qualitaSonno);
    }
    if (!nullToAbsent || energia != null) {
      map['energia'] = Variable<int>(energia);
    }
    if (!nullToAbsent || muscoli != null) {
      map['muscoli'] = Variable<int>(muscoli);
    }
    if (!nullToAbsent || stress != null) {
      map['stress'] = Variable<int>(stress);
    }
    if (!nullToAbsent || umore != null) {
      map['umore'] = Variable<int>(umore);
    }
    map['sintomi_json'] = Variable<String>(sintomiJson);
    return map;
  }

  SchedeBenessereTableCompanion toCompanion(bool nullToAbsent) {
    return SchedeBenessereTableCompanion(
      id: Value(id),
      atletaId: Value(atletaId),
      clubId: Value(clubId),
      data: Value(data),
      eventoTipo: eventoTipo == null && nullToAbsent
          ? const Value.absent()
          : Value(eventoTipo),
      eventoId: eventoId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventoId),
      dolori: Value(dolori),
      zoneDoloreJson: Value(zoneDoloreJson),
      intensitaDolore: intensitaDolore == null && nullToAbsent
          ? const Value.absent()
          : Value(intensitaDolore),
      oreSonno: Value(oreSonno),
      compilataIl: Value(compilataIl),
      qualitaSonno: qualitaSonno == null && nullToAbsent
          ? const Value.absent()
          : Value(qualitaSonno),
      energia: energia == null && nullToAbsent
          ? const Value.absent()
          : Value(energia),
      muscoli: muscoli == null && nullToAbsent
          ? const Value.absent()
          : Value(muscoli),
      stress: stress == null && nullToAbsent
          ? const Value.absent()
          : Value(stress),
      umore: umore == null && nullToAbsent
          ? const Value.absent()
          : Value(umore),
      sintomiJson: Value(sintomiJson),
    );
  }

  factory SchedeBenessereTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchedeBenessereTableData(
      id: serializer.fromJson<String>(json['id']),
      atletaId: serializer.fromJson<String>(json['atletaId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      data: serializer.fromJson<DateTime>(json['data']),
      eventoTipo: serializer.fromJson<String?>(json['eventoTipo']),
      eventoId: serializer.fromJson<String?>(json['eventoId']),
      dolori: serializer.fromJson<bool>(json['dolori']),
      zoneDoloreJson: serializer.fromJson<String>(json['zoneDoloreJson']),
      intensitaDolore: serializer.fromJson<int?>(json['intensitaDolore']),
      oreSonno: serializer.fromJson<double>(json['oreSonno']),
      compilataIl: serializer.fromJson<DateTime>(json['compilataIl']),
      qualitaSonno: serializer.fromJson<int?>(json['qualitaSonno']),
      energia: serializer.fromJson<int?>(json['energia']),
      muscoli: serializer.fromJson<int?>(json['muscoli']),
      stress: serializer.fromJson<int?>(json['stress']),
      umore: serializer.fromJson<int?>(json['umore']),
      sintomiJson: serializer.fromJson<String>(json['sintomiJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'atletaId': serializer.toJson<String>(atletaId),
      'clubId': serializer.toJson<String>(clubId),
      'data': serializer.toJson<DateTime>(data),
      'eventoTipo': serializer.toJson<String?>(eventoTipo),
      'eventoId': serializer.toJson<String?>(eventoId),
      'dolori': serializer.toJson<bool>(dolori),
      'zoneDoloreJson': serializer.toJson<String>(zoneDoloreJson),
      'intensitaDolore': serializer.toJson<int?>(intensitaDolore),
      'oreSonno': serializer.toJson<double>(oreSonno),
      'compilataIl': serializer.toJson<DateTime>(compilataIl),
      'qualitaSonno': serializer.toJson<int?>(qualitaSonno),
      'energia': serializer.toJson<int?>(energia),
      'muscoli': serializer.toJson<int?>(muscoli),
      'stress': serializer.toJson<int?>(stress),
      'umore': serializer.toJson<int?>(umore),
      'sintomiJson': serializer.toJson<String>(sintomiJson),
    };
  }

  SchedeBenessereTableData copyWith({
    String? id,
    String? atletaId,
    String? clubId,
    DateTime? data,
    Value<String?> eventoTipo = const Value.absent(),
    Value<String?> eventoId = const Value.absent(),
    bool? dolori,
    String? zoneDoloreJson,
    Value<int?> intensitaDolore = const Value.absent(),
    double? oreSonno,
    DateTime? compilataIl,
    Value<int?> qualitaSonno = const Value.absent(),
    Value<int?> energia = const Value.absent(),
    Value<int?> muscoli = const Value.absent(),
    Value<int?> stress = const Value.absent(),
    Value<int?> umore = const Value.absent(),
    String? sintomiJson,
  }) => SchedeBenessereTableData(
    id: id ?? this.id,
    atletaId: atletaId ?? this.atletaId,
    clubId: clubId ?? this.clubId,
    data: data ?? this.data,
    eventoTipo: eventoTipo.present ? eventoTipo.value : this.eventoTipo,
    eventoId: eventoId.present ? eventoId.value : this.eventoId,
    dolori: dolori ?? this.dolori,
    zoneDoloreJson: zoneDoloreJson ?? this.zoneDoloreJson,
    intensitaDolore: intensitaDolore.present
        ? intensitaDolore.value
        : this.intensitaDolore,
    oreSonno: oreSonno ?? this.oreSonno,
    compilataIl: compilataIl ?? this.compilataIl,
    qualitaSonno: qualitaSonno.present ? qualitaSonno.value : this.qualitaSonno,
    energia: energia.present ? energia.value : this.energia,
    muscoli: muscoli.present ? muscoli.value : this.muscoli,
    stress: stress.present ? stress.value : this.stress,
    umore: umore.present ? umore.value : this.umore,
    sintomiJson: sintomiJson ?? this.sintomiJson,
  );
  SchedeBenessereTableData copyWithCompanion(
    SchedeBenessereTableCompanion data,
  ) {
    return SchedeBenessereTableData(
      id: data.id.present ? data.id.value : this.id,
      atletaId: data.atletaId.present ? data.atletaId.value : this.atletaId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      data: data.data.present ? data.data.value : this.data,
      eventoTipo: data.eventoTipo.present
          ? data.eventoTipo.value
          : this.eventoTipo,
      eventoId: data.eventoId.present ? data.eventoId.value : this.eventoId,
      dolori: data.dolori.present ? data.dolori.value : this.dolori,
      zoneDoloreJson: data.zoneDoloreJson.present
          ? data.zoneDoloreJson.value
          : this.zoneDoloreJson,
      intensitaDolore: data.intensitaDolore.present
          ? data.intensitaDolore.value
          : this.intensitaDolore,
      oreSonno: data.oreSonno.present ? data.oreSonno.value : this.oreSonno,
      compilataIl: data.compilataIl.present
          ? data.compilataIl.value
          : this.compilataIl,
      qualitaSonno: data.qualitaSonno.present
          ? data.qualitaSonno.value
          : this.qualitaSonno,
      energia: data.energia.present ? data.energia.value : this.energia,
      muscoli: data.muscoli.present ? data.muscoli.value : this.muscoli,
      stress: data.stress.present ? data.stress.value : this.stress,
      umore: data.umore.present ? data.umore.value : this.umore,
      sintomiJson: data.sintomiJson.present
          ? data.sintomiJson.value
          : this.sintomiJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchedeBenessereTableData(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('data: $data, ')
          ..write('eventoTipo: $eventoTipo, ')
          ..write('eventoId: $eventoId, ')
          ..write('dolori: $dolori, ')
          ..write('zoneDoloreJson: $zoneDoloreJson, ')
          ..write('intensitaDolore: $intensitaDolore, ')
          ..write('oreSonno: $oreSonno, ')
          ..write('compilataIl: $compilataIl, ')
          ..write('qualitaSonno: $qualitaSonno, ')
          ..write('energia: $energia, ')
          ..write('muscoli: $muscoli, ')
          ..write('stress: $stress, ')
          ..write('umore: $umore, ')
          ..write('sintomiJson: $sintomiJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    atletaId,
    clubId,
    data,
    eventoTipo,
    eventoId,
    dolori,
    zoneDoloreJson,
    intensitaDolore,
    oreSonno,
    compilataIl,
    qualitaSonno,
    energia,
    muscoli,
    stress,
    umore,
    sintomiJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchedeBenessereTableData &&
          other.id == this.id &&
          other.atletaId == this.atletaId &&
          other.clubId == this.clubId &&
          other.data == this.data &&
          other.eventoTipo == this.eventoTipo &&
          other.eventoId == this.eventoId &&
          other.dolori == this.dolori &&
          other.zoneDoloreJson == this.zoneDoloreJson &&
          other.intensitaDolore == this.intensitaDolore &&
          other.oreSonno == this.oreSonno &&
          other.compilataIl == this.compilataIl &&
          other.qualitaSonno == this.qualitaSonno &&
          other.energia == this.energia &&
          other.muscoli == this.muscoli &&
          other.stress == this.stress &&
          other.umore == this.umore &&
          other.sintomiJson == this.sintomiJson);
}

class SchedeBenessereTableCompanion
    extends UpdateCompanion<SchedeBenessereTableData> {
  final Value<String> id;
  final Value<String> atletaId;
  final Value<String> clubId;
  final Value<DateTime> data;
  final Value<String?> eventoTipo;
  final Value<String?> eventoId;
  final Value<bool> dolori;
  final Value<String> zoneDoloreJson;
  final Value<int?> intensitaDolore;
  final Value<double> oreSonno;
  final Value<DateTime> compilataIl;
  final Value<int?> qualitaSonno;
  final Value<int?> energia;
  final Value<int?> muscoli;
  final Value<int?> stress;
  final Value<int?> umore;
  final Value<String> sintomiJson;
  final Value<int> rowid;
  const SchedeBenessereTableCompanion({
    this.id = const Value.absent(),
    this.atletaId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.data = const Value.absent(),
    this.eventoTipo = const Value.absent(),
    this.eventoId = const Value.absent(),
    this.dolori = const Value.absent(),
    this.zoneDoloreJson = const Value.absent(),
    this.intensitaDolore = const Value.absent(),
    this.oreSonno = const Value.absent(),
    this.compilataIl = const Value.absent(),
    this.qualitaSonno = const Value.absent(),
    this.energia = const Value.absent(),
    this.muscoli = const Value.absent(),
    this.stress = const Value.absent(),
    this.umore = const Value.absent(),
    this.sintomiJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedeBenessereTableCompanion.insert({
    required String id,
    required String atletaId,
    required String clubId,
    required DateTime data,
    this.eventoTipo = const Value.absent(),
    this.eventoId = const Value.absent(),
    required bool dolori,
    this.zoneDoloreJson = const Value.absent(),
    this.intensitaDolore = const Value.absent(),
    required double oreSonno,
    required DateTime compilataIl,
    this.qualitaSonno = const Value.absent(),
    this.energia = const Value.absent(),
    this.muscoli = const Value.absent(),
    this.stress = const Value.absent(),
    this.umore = const Value.absent(),
    this.sintomiJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       atletaId = Value(atletaId),
       clubId = Value(clubId),
       data = Value(data),
       dolori = Value(dolori),
       oreSonno = Value(oreSonno),
       compilataIl = Value(compilataIl);
  static Insertable<SchedeBenessereTableData> custom({
    Expression<String>? id,
    Expression<String>? atletaId,
    Expression<String>? clubId,
    Expression<DateTime>? data,
    Expression<String>? eventoTipo,
    Expression<String>? eventoId,
    Expression<bool>? dolori,
    Expression<String>? zoneDoloreJson,
    Expression<int>? intensitaDolore,
    Expression<double>? oreSonno,
    Expression<DateTime>? compilataIl,
    Expression<int>? qualitaSonno,
    Expression<int>? energia,
    Expression<int>? muscoli,
    Expression<int>? stress,
    Expression<int>? umore,
    Expression<String>? sintomiJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atletaId != null) 'atleta_id': atletaId,
      if (clubId != null) 'club_id': clubId,
      if (data != null) 'data': data,
      if (eventoTipo != null) 'evento_tipo': eventoTipo,
      if (eventoId != null) 'evento_id': eventoId,
      if (dolori != null) 'dolori': dolori,
      if (zoneDoloreJson != null) 'zone_dolore_json': zoneDoloreJson,
      if (intensitaDolore != null) 'intensita_dolore': intensitaDolore,
      if (oreSonno != null) 'ore_sonno': oreSonno,
      if (compilataIl != null) 'compilata_il': compilataIl,
      if (qualitaSonno != null) 'qualita_sonno': qualitaSonno,
      if (energia != null) 'energia': energia,
      if (muscoli != null) 'muscoli': muscoli,
      if (stress != null) 'stress': stress,
      if (umore != null) 'umore': umore,
      if (sintomiJson != null) 'sintomi_json': sintomiJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedeBenessereTableCompanion copyWith({
    Value<String>? id,
    Value<String>? atletaId,
    Value<String>? clubId,
    Value<DateTime>? data,
    Value<String?>? eventoTipo,
    Value<String?>? eventoId,
    Value<bool>? dolori,
    Value<String>? zoneDoloreJson,
    Value<int?>? intensitaDolore,
    Value<double>? oreSonno,
    Value<DateTime>? compilataIl,
    Value<int?>? qualitaSonno,
    Value<int?>? energia,
    Value<int?>? muscoli,
    Value<int?>? stress,
    Value<int?>? umore,
    Value<String>? sintomiJson,
    Value<int>? rowid,
  }) {
    return SchedeBenessereTableCompanion(
      id: id ?? this.id,
      atletaId: atletaId ?? this.atletaId,
      clubId: clubId ?? this.clubId,
      data: data ?? this.data,
      eventoTipo: eventoTipo ?? this.eventoTipo,
      eventoId: eventoId ?? this.eventoId,
      dolori: dolori ?? this.dolori,
      zoneDoloreJson: zoneDoloreJson ?? this.zoneDoloreJson,
      intensitaDolore: intensitaDolore ?? this.intensitaDolore,
      oreSonno: oreSonno ?? this.oreSonno,
      compilataIl: compilataIl ?? this.compilataIl,
      qualitaSonno: qualitaSonno ?? this.qualitaSonno,
      energia: energia ?? this.energia,
      muscoli: muscoli ?? this.muscoli,
      stress: stress ?? this.stress,
      umore: umore ?? this.umore,
      sintomiJson: sintomiJson ?? this.sintomiJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (atletaId.present) {
      map['atleta_id'] = Variable<String>(atletaId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<String>(clubId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (eventoTipo.present) {
      map['evento_tipo'] = Variable<String>(eventoTipo.value);
    }
    if (eventoId.present) {
      map['evento_id'] = Variable<String>(eventoId.value);
    }
    if (dolori.present) {
      map['dolori'] = Variable<bool>(dolori.value);
    }
    if (zoneDoloreJson.present) {
      map['zone_dolore_json'] = Variable<String>(zoneDoloreJson.value);
    }
    if (intensitaDolore.present) {
      map['intensita_dolore'] = Variable<int>(intensitaDolore.value);
    }
    if (oreSonno.present) {
      map['ore_sonno'] = Variable<double>(oreSonno.value);
    }
    if (compilataIl.present) {
      map['compilata_il'] = Variable<DateTime>(compilataIl.value);
    }
    if (qualitaSonno.present) {
      map['qualita_sonno'] = Variable<int>(qualitaSonno.value);
    }
    if (energia.present) {
      map['energia'] = Variable<int>(energia.value);
    }
    if (muscoli.present) {
      map['muscoli'] = Variable<int>(muscoli.value);
    }
    if (stress.present) {
      map['stress'] = Variable<int>(stress.value);
    }
    if (umore.present) {
      map['umore'] = Variable<int>(umore.value);
    }
    if (sintomiJson.present) {
      map['sintomi_json'] = Variable<String>(sintomiJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedeBenessereTableCompanion(')
          ..write('id: $id, ')
          ..write('atletaId: $atletaId, ')
          ..write('clubId: $clubId, ')
          ..write('data: $data, ')
          ..write('eventoTipo: $eventoTipo, ')
          ..write('eventoId: $eventoId, ')
          ..write('dolori: $dolori, ')
          ..write('zoneDoloreJson: $zoneDoloreJson, ')
          ..write('intensitaDolore: $intensitaDolore, ')
          ..write('oreSonno: $oreSonno, ')
          ..write('compilataIl: $compilataIl, ')
          ..write('qualitaSonno: $qualitaSonno, ')
          ..write('energia: $energia, ')
          ..write('muscoli: $muscoli, ')
          ..write('stress: $stress, ')
          ..write('umore: $umore, ')
          ..write('sintomiJson: $sintomiJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClubTableTable clubTable = $ClubTableTable(this);
  late final $AtletiTableTable atletiTable = $AtletiTableTable(this);
  late final $PersonalBestTableTable personalBestTable =
      $PersonalBestTableTable(this);
  late final $TempiGaraTableTable tempiGaraTable = $TempiGaraTableTable(this);
  late final $SchemiTatticiTableTable schemiTatticiTable =
      $SchemiTatticiTableTable(this);
  late final $TestIngressoTableTable testIngressoTable =
      $TestIngressoTableTable(this);
  late final $TabellePassiTableTable tabellePassiTable =
      $TabellePassiTableTable(this);
  late final $StagioniTableTable stagioniTable = $StagioniTableTable(this);
  late final $AllenamentiTableTable allenamentiTable = $AllenamentiTableTable(
    this,
  );
  late final $SerieTableTable serieTable = $SerieTableTable(this);
  late final $PresenzeTableTable presenzeTable = $PresenzeTableTable(this);
  late final $PendingOperationsTableTable pendingOperationsTable =
      $PendingOperationsTableTable(this);
  late final $PartiteTableTable partiteTable = $PartiteTableTable(this);
  late final $DistintaGiocatoriTableTable distintaGiocatoriTable =
      $DistintaGiocatoriTableTable(this);
  late final $EventiPartitaTableTable eventiPartitaTable =
      $EventiPartitaTableTable(this);
  late final $RefertiPartitaTableTable refertiPartitaTable =
      $RefertiPartitaTableTable(this);
  late final $GruppiTableTable gruppiTable = $GruppiTableTable(this);
  late final $GareTableTable gareTable = $GareTableTable(this);
  late final $GaraIscrittiTableTable garaIscrittiTable =
      $GaraIscrittiTableTable(this);
  late final $TrainingBlocksTableTable trainingBlocksTable =
      $TrainingBlocksTableTable(this);
  late final $TrainingBlockPartiTableTable trainingBlockPartiTable =
      $TrainingBlockPartiTableTable(this);
  late final $SchedeBenessereTableTable schedeBenessereTable =
      $SchedeBenessereTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clubTable,
    atletiTable,
    personalBestTable,
    tempiGaraTable,
    schemiTatticiTable,
    testIngressoTable,
    tabellePassiTable,
    stagioniTable,
    allenamentiTable,
    serieTable,
    presenzeTable,
    pendingOperationsTable,
    partiteTable,
    distintaGiocatoriTable,
    eventiPartitaTable,
    refertiPartitaTable,
    gruppiTable,
    gareTable,
    garaIscrittiTable,
    trainingBlocksTable,
    trainingBlockPartiTable,
    schedeBenessereTable,
  ];
}

typedef $$ClubTableTableCreateCompanionBuilder = ClubTableCompanion Function({
  required String id,
  required String nome,
  Value<String?> citta,
  Value<String?> sport,
  Value<String> categorieJson,
  Value<int> rowid,
});
typedef $$ClubTableTableUpdateCompanionBuilder = ClubTableCompanion Function({
  Value<String> id,
  Value<String> nome,
  Value<String?> citta,
  Value<String?> sport,
  Value<String> categorieJson,
  Value<int> rowid,
});

class $$ClubTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClubTableTable> {
  $$ClubTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citta => $composableBuilder(
    column: $table.citta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorieJson => $composableBuilder(
    column: $table.categorieJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClubTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClubTableTable> {
  $$ClubTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citta => $composableBuilder(
    column: $table.citta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorieJson => $composableBuilder(
    column: $table.categorieJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClubTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClubTableTable> {
  $$ClubTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get citta =>
      $composableBuilder(column: $table.citta, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get categorieJson => $composableBuilder(
    column: $table.categorieJson,
    builder: (column) => column,
  );
}

class $$ClubTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClubTableTable,
          ClubTableData,
          $$ClubTableTableFilterComposer,
          $$ClubTableTableOrderingComposer,
          $$ClubTableTableAnnotationComposer,
          $$ClubTableTableCreateCompanionBuilder,
          $$ClubTableTableUpdateCompanionBuilder,
          (
            ClubTableData,
            BaseReferences<_$AppDatabase, $ClubTableTable, ClubTableData>,
          ),
          ClubTableData,
          PrefetchHooks Function()
        > {
  $$ClubTableTableTableManager(_$AppDatabase db, $ClubTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClubTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClubTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClubTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> citta = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<String> categorieJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClubTableCompanion(
                id: id,
                nome: nome,
                citta: citta,
                sport: sport,
                categorieJson: categorieJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                Value<String?> citta = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<String> categorieJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClubTableCompanion.insert(
                id: id,
                nome: nome,
                citta: citta,
                sport: sport,
                categorieJson: categorieJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClubTableTable, ClubTableData>(table),
                  BaseReferences<_$AppDatabase, $ClubTableTable, ClubTableData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClubTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClubTableTable,
      ClubTableData,
      $$ClubTableTableFilterComposer,
      $$ClubTableTableOrderingComposer,
      $$ClubTableTableAnnotationComposer,
      $$ClubTableTableCreateCompanionBuilder,
      $$ClubTableTableUpdateCompanionBuilder,
      (
        ClubTableData,
        BaseReferences<_$AppDatabase, $ClubTableTable, ClubTableData>,
      ),
      ClubTableData,
      PrefetchHooks Function()
    >;
typedef $$AtletiTableTableCreateCompanionBuilder =
    AtletiTableCompanion Function({
      required String id,
      required String clubId,
      required String nome,
      required String cognome,
      required DateTime dataNascita,
      Value<String?> sesso,
      required String sport,
      Value<String?> gruppoId,
      Value<String?> emailGenitore,
      Value<String?> telefonoGenitore,
      Value<bool> consensoPrivacyFirmato,
      Value<DateTime?> consensoPrivacyData,
      Value<String?> note,
      Value<bool> attivo,
      Value<String?> numeroTesseraFin,
      Value<String?> userId,
      Value<DateTime?> visitaMedicaScadenza,
      Value<int> rowid,
    });
typedef $$AtletiTableTableUpdateCompanionBuilder =
    AtletiTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String> nome,
      Value<String> cognome,
      Value<DateTime> dataNascita,
      Value<String?> sesso,
      Value<String> sport,
      Value<String?> gruppoId,
      Value<String?> emailGenitore,
      Value<String?> telefonoGenitore,
      Value<bool> consensoPrivacyFirmato,
      Value<DateTime?> consensoPrivacyData,
      Value<String?> note,
      Value<bool> attivo,
      Value<String?> numeroTesseraFin,
      Value<String?> userId,
      Value<DateTime?> visitaMedicaScadenza,
      Value<int> rowid,
    });

class $$AtletiTableTableFilterComposer
    extends Composer<_$AppDatabase, $AtletiTableTable> {
  $$AtletiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cognome => $composableBuilder(
    column: $table.cognome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataNascita => $composableBuilder(
    column: $table.dataNascita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sesso => $composableBuilder(
    column: $table.sesso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailGenitore => $composableBuilder(
    column: $table.emailGenitore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefonoGenitore => $composableBuilder(
    column: $table.telefonoGenitore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consensoPrivacyFirmato => $composableBuilder(
    column: $table.consensoPrivacyFirmato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consensoPrivacyData => $composableBuilder(
    column: $table.consensoPrivacyData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get attivo => $composableBuilder(
    column: $table.attivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroTesseraFin => $composableBuilder(
    column: $table.numeroTesseraFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitaMedicaScadenza => $composableBuilder(
    column: $table.visitaMedicaScadenza,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AtletiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AtletiTableTable> {
  $$AtletiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cognome => $composableBuilder(
    column: $table.cognome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataNascita => $composableBuilder(
    column: $table.dataNascita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sesso => $composableBuilder(
    column: $table.sesso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailGenitore => $composableBuilder(
    column: $table.emailGenitore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefonoGenitore => $composableBuilder(
    column: $table.telefonoGenitore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consensoPrivacyFirmato => $composableBuilder(
    column: $table.consensoPrivacyFirmato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consensoPrivacyData => $composableBuilder(
    column: $table.consensoPrivacyData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get attivo => $composableBuilder(
    column: $table.attivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroTesseraFin => $composableBuilder(
    column: $table.numeroTesseraFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitaMedicaScadenza => $composableBuilder(
    column: $table.visitaMedicaScadenza,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AtletiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtletiTableTable> {
  $$AtletiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cognome =>
      $composableBuilder(column: $table.cognome, builder: (column) => column);

  GeneratedColumn<DateTime> get dataNascita => $composableBuilder(
    column: $table.dataNascita,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sesso =>
      $composableBuilder(column: $table.sesso, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get gruppoId =>
      $composableBuilder(column: $table.gruppoId, builder: (column) => column);

  GeneratedColumn<String> get emailGenitore => $composableBuilder(
    column: $table.emailGenitore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telefonoGenitore => $composableBuilder(
    column: $table.telefonoGenitore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consensoPrivacyFirmato => $composableBuilder(
    column: $table.consensoPrivacyFirmato,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get consensoPrivacyData => $composableBuilder(
    column: $table.consensoPrivacyData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get attivo =>
      $composableBuilder(column: $table.attivo, builder: (column) => column);

  GeneratedColumn<String> get numeroTesseraFin => $composableBuilder(
    column: $table.numeroTesseraFin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get visitaMedicaScadenza => $composableBuilder(
    column: $table.visitaMedicaScadenza,
    builder: (column) => column,
  );
}

class $$AtletiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtletiTableTable,
          AtletiTableData,
          $$AtletiTableTableFilterComposer,
          $$AtletiTableTableOrderingComposer,
          $$AtletiTableTableAnnotationComposer,
          $$AtletiTableTableCreateCompanionBuilder,
          $$AtletiTableTableUpdateCompanionBuilder,
          (
            AtletiTableData,
            BaseReferences<_$AppDatabase, $AtletiTableTable, AtletiTableData>,
          ),
          AtletiTableData,
          PrefetchHooks Function()
        > {
  $$AtletiTableTableTableManager(_$AppDatabase db, $AtletiTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtletiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtletiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtletiTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> cognome = const Value.absent(),
                Value<DateTime> dataNascita = const Value.absent(),
                Value<String?> sesso = const Value.absent(),
                Value<String> sport = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> emailGenitore = const Value.absent(),
                Value<String?> telefonoGenitore = const Value.absent(),
                Value<bool> consensoPrivacyFirmato = const Value.absent(),
                Value<DateTime?> consensoPrivacyData = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> attivo = const Value.absent(),
                Value<String?> numeroTesseraFin = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime?> visitaMedicaScadenza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtletiTableCompanion(
                id: id,
                clubId: clubId,
                nome: nome,
                cognome: cognome,
                dataNascita: dataNascita,
                sesso: sesso,
                sport: sport,
                gruppoId: gruppoId,
                emailGenitore: emailGenitore,
                telefonoGenitore: telefonoGenitore,
                consensoPrivacyFirmato: consensoPrivacyFirmato,
                consensoPrivacyData: consensoPrivacyData,
                note: note,
                attivo: attivo,
                numeroTesseraFin: numeroTesseraFin,
                userId: userId,
                visitaMedicaScadenza: visitaMedicaScadenza,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required String nome,
                required String cognome,
                required DateTime dataNascita,
                Value<String?> sesso = const Value.absent(),
                required String sport,
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> emailGenitore = const Value.absent(),
                Value<String?> telefonoGenitore = const Value.absent(),
                Value<bool> consensoPrivacyFirmato = const Value.absent(),
                Value<DateTime?> consensoPrivacyData = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> attivo = const Value.absent(),
                Value<String?> numeroTesseraFin = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime?> visitaMedicaScadenza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtletiTableCompanion.insert(
                id: id,
                clubId: clubId,
                nome: nome,
                cognome: cognome,
                dataNascita: dataNascita,
                sesso: sesso,
                sport: sport,
                gruppoId: gruppoId,
                emailGenitore: emailGenitore,
                telefonoGenitore: telefonoGenitore,
                consensoPrivacyFirmato: consensoPrivacyFirmato,
                consensoPrivacyData: consensoPrivacyData,
                note: note,
                attivo: attivo,
                numeroTesseraFin: numeroTesseraFin,
                userId: userId,
                visitaMedicaScadenza: visitaMedicaScadenza,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AtletiTableTable, AtletiTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AtletiTableTable,
                    AtletiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AtletiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtletiTableTable,
      AtletiTableData,
      $$AtletiTableTableFilterComposer,
      $$AtletiTableTableOrderingComposer,
      $$AtletiTableTableAnnotationComposer,
      $$AtletiTableTableCreateCompanionBuilder,
      $$AtletiTableTableUpdateCompanionBuilder,
      (
        AtletiTableData,
        BaseReferences<_$AppDatabase, $AtletiTableTable, AtletiTableData>,
      ),
      AtletiTableData,
      PrefetchHooks Function()
    >;
typedef $$PersonalBestTableTableCreateCompanionBuilder =
    PersonalBestTableCompanion Function({
      required String id,
      required String atletaId,
      required String clubId,
      required String stile,
      required int distanzaM,
      required double tempoS,
      Value<DateTime?> data,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$PersonalBestTableTableUpdateCompanionBuilder =
    PersonalBestTableCompanion Function({
      Value<String> id,
      Value<String> atletaId,
      Value<String> clubId,
      Value<String> stile,
      Value<int> distanzaM,
      Value<double> tempoS,
      Value<DateTime?> data,
      Value<String?> note,
      Value<int> rowid,
    });

class $$PersonalBestTableTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalBestTableTable> {
  $$PersonalBestTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempoS => $composableBuilder(
    column: $table.tempoS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonalBestTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalBestTableTable> {
  $$PersonalBestTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempoS => $composableBuilder(
    column: $table.tempoS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalBestTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalBestTableTable> {
  $$PersonalBestTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get stile =>
      $composableBuilder(column: $table.stile, builder: (column) => column);

  GeneratedColumn<int> get distanzaM =>
      $composableBuilder(column: $table.distanzaM, builder: (column) => column);

  GeneratedColumn<double> get tempoS =>
      $composableBuilder(column: $table.tempoS, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$PersonalBestTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalBestTableTable,
          PersonalBestTableData,
          $$PersonalBestTableTableFilterComposer,
          $$PersonalBestTableTableOrderingComposer,
          $$PersonalBestTableTableAnnotationComposer,
          $$PersonalBestTableTableCreateCompanionBuilder,
          $$PersonalBestTableTableUpdateCompanionBuilder,
          (
            PersonalBestTableData,
            BaseReferences<
              _$AppDatabase,
              $PersonalBestTableTable,
              PersonalBestTableData
            >,
          ),
          PersonalBestTableData,
          PrefetchHooks Function()
        > {
  $$PersonalBestTableTableTableManager(
    _$AppDatabase db,
    $PersonalBestTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalBestTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalBestTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalBestTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> stile = const Value.absent(),
                Value<int> distanzaM = const Value.absent(),
                Value<double> tempoS = const Value.absent(),
                Value<DateTime?> data = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalBestTableCompanion(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                stile: stile,
                distanzaM: distanzaM,
                tempoS: tempoS,
                data: data,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String atletaId,
                required String clubId,
                required String stile,
                required int distanzaM,
                required double tempoS,
                Value<DateTime?> data = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalBestTableCompanion.insert(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                stile: stile,
                distanzaM: distanzaM,
                tempoS: tempoS,
                data: data,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonalBestTableTable, PersonalBestTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PersonalBestTableTable,
                    PersonalBestTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonalBestTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalBestTableTable,
      PersonalBestTableData,
      $$PersonalBestTableTableFilterComposer,
      $$PersonalBestTableTableOrderingComposer,
      $$PersonalBestTableTableAnnotationComposer,
      $$PersonalBestTableTableCreateCompanionBuilder,
      $$PersonalBestTableTableUpdateCompanionBuilder,
      (
        PersonalBestTableData,
        BaseReferences<
          _$AppDatabase,
          $PersonalBestTableTable,
          PersonalBestTableData
        >,
      ),
      PersonalBestTableData,
      PrefetchHooks Function()
    >;
typedef $$TempiGaraTableTableCreateCompanionBuilder =
    TempiGaraTableCompanion Function({
      required String id,
      required String atletaId,
      required String clubId,
      required String stile,
      required int distanzaM,
      required int vascaM,
      required double tempoS,
      required DateTime data,
      Value<String?> note,
      Value<String?> garaId,
      Value<int> rowid,
    });
typedef $$TempiGaraTableTableUpdateCompanionBuilder =
    TempiGaraTableCompanion Function({
      Value<String> id,
      Value<String> atletaId,
      Value<String> clubId,
      Value<String> stile,
      Value<int> distanzaM,
      Value<int> vascaM,
      Value<double> tempoS,
      Value<DateTime> data,
      Value<String?> note,
      Value<String?> garaId,
      Value<int> rowid,
    });

class $$TempiGaraTableTableFilterComposer
    extends Composer<_$AppDatabase, $TempiGaraTableTable> {
  $$TempiGaraTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vascaM => $composableBuilder(
    column: $table.vascaM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempoS => $composableBuilder(
    column: $table.tempoS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get garaId => $composableBuilder(
    column: $table.garaId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TempiGaraTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TempiGaraTableTable> {
  $$TempiGaraTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vascaM => $composableBuilder(
    column: $table.vascaM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempoS => $composableBuilder(
    column: $table.tempoS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get garaId => $composableBuilder(
    column: $table.garaId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TempiGaraTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TempiGaraTableTable> {
  $$TempiGaraTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get stile =>
      $composableBuilder(column: $table.stile, builder: (column) => column);

  GeneratedColumn<int> get distanzaM =>
      $composableBuilder(column: $table.distanzaM, builder: (column) => column);

  GeneratedColumn<int> get vascaM =>
      $composableBuilder(column: $table.vascaM, builder: (column) => column);

  GeneratedColumn<double> get tempoS =>
      $composableBuilder(column: $table.tempoS, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get garaId =>
      $composableBuilder(column: $table.garaId, builder: (column) => column);
}

class $$TempiGaraTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TempiGaraTableTable,
          TempiGaraTableData,
          $$TempiGaraTableTableFilterComposer,
          $$TempiGaraTableTableOrderingComposer,
          $$TempiGaraTableTableAnnotationComposer,
          $$TempiGaraTableTableCreateCompanionBuilder,
          $$TempiGaraTableTableUpdateCompanionBuilder,
          (
            TempiGaraTableData,
            BaseReferences<
              _$AppDatabase,
              $TempiGaraTableTable,
              TempiGaraTableData
            >,
          ),
          TempiGaraTableData,
          PrefetchHooks Function()
        > {
  $$TempiGaraTableTableTableManager(
    _$AppDatabase db,
    $TempiGaraTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TempiGaraTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TempiGaraTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TempiGaraTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> stile = const Value.absent(),
                Value<int> distanzaM = const Value.absent(),
                Value<int> vascaM = const Value.absent(),
                Value<double> tempoS = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> garaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TempiGaraTableCompanion(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                stile: stile,
                distanzaM: distanzaM,
                vascaM: vascaM,
                tempoS: tempoS,
                data: data,
                note: note,
                garaId: garaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String atletaId,
                required String clubId,
                required String stile,
                required int distanzaM,
                required int vascaM,
                required double tempoS,
                required DateTime data,
                Value<String?> note = const Value.absent(),
                Value<String?> garaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TempiGaraTableCompanion.insert(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                stile: stile,
                distanzaM: distanzaM,
                vascaM: vascaM,
                tempoS: tempoS,
                data: data,
                note: note,
                garaId: garaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TempiGaraTableTable, TempiGaraTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TempiGaraTableTable,
                    TempiGaraTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TempiGaraTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TempiGaraTableTable,
      TempiGaraTableData,
      $$TempiGaraTableTableFilterComposer,
      $$TempiGaraTableTableOrderingComposer,
      $$TempiGaraTableTableAnnotationComposer,
      $$TempiGaraTableTableCreateCompanionBuilder,
      $$TempiGaraTableTableUpdateCompanionBuilder,
      (
        TempiGaraTableData,
        BaseReferences<_$AppDatabase, $TempiGaraTableTable, TempiGaraTableData>,
      ),
      TempiGaraTableData,
      PrefetchHooks Function()
    >;
typedef $$SchemiTatticiTableTableCreateCompanionBuilder =
    SchemiTatticiTableCompanion Function({
      required String id,
      required String clubId,
      required String titolo,
      Value<String> gruppoIdsJson,
      Value<String> categoria,
      Value<String> campo,
      required String dati,
      required DateTime aggiornatoIl,
      Value<int> rowid,
    });
typedef $$SchemiTatticiTableTableUpdateCompanionBuilder =
    SchemiTatticiTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String> titolo,
      Value<String> gruppoIdsJson,
      Value<String> categoria,
      Value<String> campo,
      Value<String> dati,
      Value<DateTime> aggiornatoIl,
      Value<int> rowid,
    });

class $$SchemiTatticiTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchemiTatticiTableTable> {
  $$SchemiTatticiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoIdsJson => $composableBuilder(
    column: $table.gruppoIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campo => $composableBuilder(
    column: $table.campo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dati => $composableBuilder(
    column: $table.dati,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemiTatticiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemiTatticiTableTable> {
  $$SchemiTatticiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoIdsJson => $composableBuilder(
    column: $table.gruppoIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campo => $composableBuilder(
    column: $table.campo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dati => $composableBuilder(
    column: $table.dati,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemiTatticiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemiTatticiTableTable> {
  $$SchemiTatticiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get titolo =>
      $composableBuilder(column: $table.titolo, builder: (column) => column);

  GeneratedColumn<String> get gruppoIdsJson => $composableBuilder(
    column: $table.gruppoIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get campo =>
      $composableBuilder(column: $table.campo, builder: (column) => column);

  GeneratedColumn<String> get dati =>
      $composableBuilder(column: $table.dati, builder: (column) => column);

  GeneratedColumn<DateTime> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );
}

class $$SchemiTatticiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemiTatticiTableTable,
          SchemiTatticiTableData,
          $$SchemiTatticiTableTableFilterComposer,
          $$SchemiTatticiTableTableOrderingComposer,
          $$SchemiTatticiTableTableAnnotationComposer,
          $$SchemiTatticiTableTableCreateCompanionBuilder,
          $$SchemiTatticiTableTableUpdateCompanionBuilder,
          (
            SchemiTatticiTableData,
            BaseReferences<
              _$AppDatabase,
              $SchemiTatticiTableTable,
              SchemiTatticiTableData
            >,
          ),
          SchemiTatticiTableData,
          PrefetchHooks Function()
        > {
  $$SchemiTatticiTableTableTableManager(
    _$AppDatabase db,
    $SchemiTatticiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemiTatticiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemiTatticiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemiTatticiTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> titolo = const Value.absent(),
                Value<String> gruppoIdsJson = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<String> campo = const Value.absent(),
                Value<String> dati = const Value.absent(),
                Value<DateTime> aggiornatoIl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchemiTatticiTableCompanion(
                id: id,
                clubId: clubId,
                titolo: titolo,
                gruppoIdsJson: gruppoIdsJson,
                categoria: categoria,
                campo: campo,
                dati: dati,
                aggiornatoIl: aggiornatoIl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required String titolo,
                Value<String> gruppoIdsJson = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<String> campo = const Value.absent(),
                required String dati,
                required DateTime aggiornatoIl,
                Value<int> rowid = const Value.absent(),
              }) => SchemiTatticiTableCompanion.insert(
                id: id,
                clubId: clubId,
                titolo: titolo,
                gruppoIdsJson: gruppoIdsJson,
                categoria: categoria,
                campo: campo,
                dati: dati,
                aggiornatoIl: aggiornatoIl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchemiTatticiTableTable, SchemiTatticiTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SchemiTatticiTableTable,
                    SchemiTatticiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemiTatticiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemiTatticiTableTable,
      SchemiTatticiTableData,
      $$SchemiTatticiTableTableFilterComposer,
      $$SchemiTatticiTableTableOrderingComposer,
      $$SchemiTatticiTableTableAnnotationComposer,
      $$SchemiTatticiTableTableCreateCompanionBuilder,
      $$SchemiTatticiTableTableUpdateCompanionBuilder,
      (
        SchemiTatticiTableData,
        BaseReferences<
          _$AppDatabase,
          $SchemiTatticiTableTable,
          SchemiTatticiTableData
        >,
      ),
      SchemiTatticiTableData,
      PrefetchHooks Function()
    >;
typedef $$TestIngressoTableTableCreateCompanionBuilder =
    TestIngressoTableCompanion Function({
      required String id,
      required String atletaId,
      required String clubId,
      required String tipo,
      required DateTime dataTest,
      required int distanzaTotaleM,
      required double tempoTotaleS,
      required double passoMedio100S,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$TestIngressoTableTableUpdateCompanionBuilder =
    TestIngressoTableCompanion Function({
      Value<String> id,
      Value<String> atletaId,
      Value<String> clubId,
      Value<String> tipo,
      Value<DateTime> dataTest,
      Value<int> distanzaTotaleM,
      Value<double> tempoTotaleS,
      Value<double> passoMedio100S,
      Value<String?> note,
      Value<int> rowid,
    });

class $$TestIngressoTableTableFilterComposer
    extends Composer<_$AppDatabase, $TestIngressoTableTable> {
  $$TestIngressoTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataTest => $composableBuilder(
    column: $table.dataTest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanzaTotaleM => $composableBuilder(
    column: $table.distanzaTotaleM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempoTotaleS => $composableBuilder(
    column: $table.tempoTotaleS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get passoMedio100S => $composableBuilder(
    column: $table.passoMedio100S,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TestIngressoTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TestIngressoTableTable> {
  $$TestIngressoTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataTest => $composableBuilder(
    column: $table.dataTest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanzaTotaleM => $composableBuilder(
    column: $table.distanzaTotaleM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempoTotaleS => $composableBuilder(
    column: $table.tempoTotaleS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get passoMedio100S => $composableBuilder(
    column: $table.passoMedio100S,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TestIngressoTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TestIngressoTableTable> {
  $$TestIngressoTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get dataTest =>
      $composableBuilder(column: $table.dataTest, builder: (column) => column);

  GeneratedColumn<int> get distanzaTotaleM => $composableBuilder(
    column: $table.distanzaTotaleM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tempoTotaleS => $composableBuilder(
    column: $table.tempoTotaleS,
    builder: (column) => column,
  );

  GeneratedColumn<double> get passoMedio100S => $composableBuilder(
    column: $table.passoMedio100S,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TestIngressoTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TestIngressoTableTable,
          TestIngressoTableData,
          $$TestIngressoTableTableFilterComposer,
          $$TestIngressoTableTableOrderingComposer,
          $$TestIngressoTableTableAnnotationComposer,
          $$TestIngressoTableTableCreateCompanionBuilder,
          $$TestIngressoTableTableUpdateCompanionBuilder,
          (
            TestIngressoTableData,
            BaseReferences<
              _$AppDatabase,
              $TestIngressoTableTable,
              TestIngressoTableData
            >,
          ),
          TestIngressoTableData,
          PrefetchHooks Function()
        > {
  $$TestIngressoTableTableTableManager(
    _$AppDatabase db,
    $TestIngressoTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestIngressoTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestIngressoTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestIngressoTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> dataTest = const Value.absent(),
                Value<int> distanzaTotaleM = const Value.absent(),
                Value<double> tempoTotaleS = const Value.absent(),
                Value<double> passoMedio100S = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TestIngressoTableCompanion(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                tipo: tipo,
                dataTest: dataTest,
                distanzaTotaleM: distanzaTotaleM,
                tempoTotaleS: tempoTotaleS,
                passoMedio100S: passoMedio100S,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String atletaId,
                required String clubId,
                required String tipo,
                required DateTime dataTest,
                required int distanzaTotaleM,
                required double tempoTotaleS,
                required double passoMedio100S,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TestIngressoTableCompanion.insert(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                tipo: tipo,
                dataTest: dataTest,
                distanzaTotaleM: distanzaTotaleM,
                tempoTotaleS: tempoTotaleS,
                passoMedio100S: passoMedio100S,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TestIngressoTableTable, TestIngressoTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TestIngressoTableTable,
                    TestIngressoTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TestIngressoTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TestIngressoTableTable,
      TestIngressoTableData,
      $$TestIngressoTableTableFilterComposer,
      $$TestIngressoTableTableOrderingComposer,
      $$TestIngressoTableTableAnnotationComposer,
      $$TestIngressoTableTableCreateCompanionBuilder,
      $$TestIngressoTableTableUpdateCompanionBuilder,
      (
        TestIngressoTableData,
        BaseReferences<
          _$AppDatabase,
          $TestIngressoTableTable,
          TestIngressoTableData
        >,
      ),
      TestIngressoTableData,
      PrefetchHooks Function()
    >;
typedef $$TabellePassiTableTableCreateCompanionBuilder =
    TabellePassiTableCompanion Function({
      required String id,
      required String testId,
      required String atletaId,
      required String clubId,
      required String zona,
      required double passo100S,
      Value<double?> percentualeRiferimento,
      Value<int> rowid,
    });
typedef $$TabellePassiTableTableUpdateCompanionBuilder =
    TabellePassiTableCompanion Function({
      Value<String> id,
      Value<String> testId,
      Value<String> atletaId,
      Value<String> clubId,
      Value<String> zona,
      Value<double> passo100S,
      Value<double?> percentualeRiferimento,
      Value<int> rowid,
    });

class $$TabellePassiTableTableFilterComposer
    extends Composer<_$AppDatabase, $TabellePassiTableTable> {
  $$TabellePassiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testId => $composableBuilder(
    column: $table.testId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get passo100S => $composableBuilder(
    column: $table.passo100S,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentualeRiferimento => $composableBuilder(
    column: $table.percentualeRiferimento,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TabellePassiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TabellePassiTableTable> {
  $$TabellePassiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testId => $composableBuilder(
    column: $table.testId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get passo100S => $composableBuilder(
    column: $table.passo100S,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentualeRiferimento => $composableBuilder(
    column: $table.percentualeRiferimento,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TabellePassiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TabellePassiTableTable> {
  $$TabellePassiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get testId =>
      $composableBuilder(column: $table.testId, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<double> get passo100S =>
      $composableBuilder(column: $table.passo100S, builder: (column) => column);

  GeneratedColumn<double> get percentualeRiferimento => $composableBuilder(
    column: $table.percentualeRiferimento,
    builder: (column) => column,
  );
}

class $$TabellePassiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TabellePassiTableTable,
          TabellePassiTableData,
          $$TabellePassiTableTableFilterComposer,
          $$TabellePassiTableTableOrderingComposer,
          $$TabellePassiTableTableAnnotationComposer,
          $$TabellePassiTableTableCreateCompanionBuilder,
          $$TabellePassiTableTableUpdateCompanionBuilder,
          (
            TabellePassiTableData,
            BaseReferences<
              _$AppDatabase,
              $TabellePassiTableTable,
              TabellePassiTableData
            >,
          ),
          TabellePassiTableData,
          PrefetchHooks Function()
        > {
  $$TabellePassiTableTableTableManager(
    _$AppDatabase db,
    $TabellePassiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TabellePassiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TabellePassiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TabellePassiTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> testId = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> zona = const Value.absent(),
                Value<double> passo100S = const Value.absent(),
                Value<double?> percentualeRiferimento = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TabellePassiTableCompanion(
                id: id,
                testId: testId,
                atletaId: atletaId,
                clubId: clubId,
                zona: zona,
                passo100S: passo100S,
                percentualeRiferimento: percentualeRiferimento,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String testId,
                required String atletaId,
                required String clubId,
                required String zona,
                required double passo100S,
                Value<double?> percentualeRiferimento = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TabellePassiTableCompanion.insert(
                id: id,
                testId: testId,
                atletaId: atletaId,
                clubId: clubId,
                zona: zona,
                passo100S: passo100S,
                percentualeRiferimento: percentualeRiferimento,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TabellePassiTableTable, TabellePassiTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TabellePassiTableTable,
                    TabellePassiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TabellePassiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TabellePassiTableTable,
      TabellePassiTableData,
      $$TabellePassiTableTableFilterComposer,
      $$TabellePassiTableTableOrderingComposer,
      $$TabellePassiTableTableAnnotationComposer,
      $$TabellePassiTableTableCreateCompanionBuilder,
      $$TabellePassiTableTableUpdateCompanionBuilder,
      (
        TabellePassiTableData,
        BaseReferences<
          _$AppDatabase,
          $TabellePassiTableTable,
          TabellePassiTableData
        >,
      ),
      TabellePassiTableData,
      PrefetchHooks Function()
    >;
typedef $$StagioniTableTableCreateCompanionBuilder =
    StagioniTableCompanion Function({
      required String id,
      required String clubId,
      required String nome,
      required DateTime dataInizio,
      required DateTime dataFine,
      Value<String?> obiettivo,
      Value<String?> gruppoId,
      Value<String?> campionato,
      Value<int> rowid,
    });
typedef $$StagioniTableTableUpdateCompanionBuilder =
    StagioniTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String> nome,
      Value<DateTime> dataInizio,
      Value<DateTime> dataFine,
      Value<String?> obiettivo,
      Value<String?> gruppoId,
      Value<String?> campionato,
      Value<int> rowid,
    });

class $$StagioniTableTableFilterComposer
    extends Composer<_$AppDatabase, $StagioniTableTable> {
  $$StagioniTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataInizio => $composableBuilder(
    column: $table.dataInizio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataFine => $composableBuilder(
    column: $table.dataFine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obiettivo => $composableBuilder(
    column: $table.obiettivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StagioniTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StagioniTableTable> {
  $$StagioniTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataInizio => $composableBuilder(
    column: $table.dataInizio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataFine => $composableBuilder(
    column: $table.dataFine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obiettivo => $composableBuilder(
    column: $table.obiettivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagioniTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StagioniTableTable> {
  $$StagioniTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<DateTime> get dataInizio => $composableBuilder(
    column: $table.dataInizio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataFine =>
      $composableBuilder(column: $table.dataFine, builder: (column) => column);

  GeneratedColumn<String> get obiettivo =>
      $composableBuilder(column: $table.obiettivo, builder: (column) => column);

  GeneratedColumn<String> get gruppoId =>
      $composableBuilder(column: $table.gruppoId, builder: (column) => column);

  GeneratedColumn<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => column,
  );
}

class $$StagioniTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StagioniTableTable,
          StagioniTableData,
          $$StagioniTableTableFilterComposer,
          $$StagioniTableTableOrderingComposer,
          $$StagioniTableTableAnnotationComposer,
          $$StagioniTableTableCreateCompanionBuilder,
          $$StagioniTableTableUpdateCompanionBuilder,
          (
            StagioniTableData,
            BaseReferences<
              _$AppDatabase,
              $StagioniTableTable,
              StagioniTableData
            >,
          ),
          StagioniTableData,
          PrefetchHooks Function()
        > {
  $$StagioniTableTableTableManager(_$AppDatabase db, $StagioniTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagioniTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagioniTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagioniTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<DateTime> dataInizio = const Value.absent(),
                Value<DateTime> dataFine = const Value.absent(),
                Value<String?> obiettivo = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> campionato = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagioniTableCompanion(
                id: id,
                clubId: clubId,
                nome: nome,
                dataInizio: dataInizio,
                dataFine: dataFine,
                obiettivo: obiettivo,
                gruppoId: gruppoId,
                campionato: campionato,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required String nome,
                required DateTime dataInizio,
                required DateTime dataFine,
                Value<String?> obiettivo = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> campionato = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagioniTableCompanion.insert(
                id: id,
                clubId: clubId,
                nome: nome,
                dataInizio: dataInizio,
                dataFine: dataFine,
                obiettivo: obiettivo,
                gruppoId: gruppoId,
                campionato: campionato,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StagioniTableTable, StagioniTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StagioniTableTable,
                    StagioniTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StagioniTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StagioniTableTable,
      StagioniTableData,
      $$StagioniTableTableFilterComposer,
      $$StagioniTableTableOrderingComposer,
      $$StagioniTableTableAnnotationComposer,
      $$StagioniTableTableCreateCompanionBuilder,
      $$StagioniTableTableUpdateCompanionBuilder,
      (
        StagioniTableData,
        BaseReferences<_$AppDatabase, $StagioniTableTable, StagioniTableData>,
      ),
      StagioniTableData,
      PrefetchHooks Function()
    >;
typedef $$AllenamentiTableTableCreateCompanionBuilder =
    AllenamentiTableCompanion Function({
      required String id,
      required String clubId,
      required DateTime data,
      Value<String?> titolo,
      Value<String?> gruppoId,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$AllenamentiTableTableUpdateCompanionBuilder =
    AllenamentiTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<DateTime> data,
      Value<String?> titolo,
      Value<String?> gruppoId,
      Value<String?> note,
      Value<int> rowid,
    });

class $$AllenamentiTableTableFilterComposer
    extends Composer<_$AppDatabase, $AllenamentiTableTable> {
  $$AllenamentiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AllenamentiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AllenamentiTableTable> {
  $$AllenamentiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AllenamentiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AllenamentiTableTable> {
  $$AllenamentiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get titolo =>
      $composableBuilder(column: $table.titolo, builder: (column) => column);

  GeneratedColumn<String> get gruppoId =>
      $composableBuilder(column: $table.gruppoId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$AllenamentiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AllenamentiTableTable,
          AllenamentiTableData,
          $$AllenamentiTableTableFilterComposer,
          $$AllenamentiTableTableOrderingComposer,
          $$AllenamentiTableTableAnnotationComposer,
          $$AllenamentiTableTableCreateCompanionBuilder,
          $$AllenamentiTableTableUpdateCompanionBuilder,
          (
            AllenamentiTableData,
            BaseReferences<
              _$AppDatabase,
              $AllenamentiTableTable,
              AllenamentiTableData
            >,
          ),
          AllenamentiTableData,
          PrefetchHooks Function()
        > {
  $$AllenamentiTableTableTableManager(
    _$AppDatabase db,
    $AllenamentiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AllenamentiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AllenamentiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AllenamentiTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> titolo = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllenamentiTableCompanion(
                id: id,
                clubId: clubId,
                data: data,
                titolo: titolo,
                gruppoId: gruppoId,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required DateTime data,
                Value<String?> titolo = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllenamentiTableCompanion.insert(
                id: id,
                clubId: clubId,
                data: data,
                titolo: titolo,
                gruppoId: gruppoId,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AllenamentiTableTable, AllenamentiTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $AllenamentiTableTable,
                    AllenamentiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AllenamentiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AllenamentiTableTable,
      AllenamentiTableData,
      $$AllenamentiTableTableFilterComposer,
      $$AllenamentiTableTableOrderingComposer,
      $$AllenamentiTableTableAnnotationComposer,
      $$AllenamentiTableTableCreateCompanionBuilder,
      $$AllenamentiTableTableUpdateCompanionBuilder,
      (
        AllenamentiTableData,
        BaseReferences<
          _$AppDatabase,
          $AllenamentiTableTable,
          AllenamentiTableData
        >,
      ),
      AllenamentiTableData,
      PrefetchHooks Function()
    >;
typedef $$SerieTableTableCreateCompanionBuilder = SerieTableCompanion Function({
  required String id,
  required String allenamentoId,
  required String clubId,
  required int ordine,
  required String blocco,
  required int ripetute,
  Value<int?> distanzaM,
  Value<int?> durataS,
  required String stile,
  required String esecuzione,
  Value<String?> zona,
  Value<double?> passoObiettivoS,
  Value<int?> recuperoS,
  Value<double?> ripartenzaS,
  Value<String?> attrezzatura,
  Value<String?> note,
  Value<String?> piramideId,
  Value<int> rowid,
});
typedef $$SerieTableTableUpdateCompanionBuilder = SerieTableCompanion Function({
  Value<String> id,
  Value<String> allenamentoId,
  Value<String> clubId,
  Value<int> ordine,
  Value<String> blocco,
  Value<int> ripetute,
  Value<int?> distanzaM,
  Value<int?> durataS,
  Value<String> stile,
  Value<String> esecuzione,
  Value<String?> zona,
  Value<double?> passoObiettivoS,
  Value<int?> recuperoS,
  Value<double?> ripartenzaS,
  Value<String?> attrezzatura,
  Value<String?> note,
  Value<String?> piramideId,
  Value<int> rowid,
});

class $$SerieTableTableFilterComposer
    extends Composer<_$AppDatabase, $SerieTableTable> {
  $$SerieTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocco => $composableBuilder(
    column: $table.blocco,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ripetute => $composableBuilder(
    column: $table.ripetute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durataS => $composableBuilder(
    column: $table.durataS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get passoObiettivoS => $composableBuilder(
    column: $table.passoObiettivoS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recuperoS => $composableBuilder(
    column: $table.recuperoS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ripartenzaS => $composableBuilder(
    column: $table.ripartenzaS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attrezzatura => $composableBuilder(
    column: $table.attrezzatura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get piramideId => $composableBuilder(
    column: $table.piramideId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SerieTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SerieTableTable> {
  $$SerieTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocco => $composableBuilder(
    column: $table.blocco,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ripetute => $composableBuilder(
    column: $table.ripetute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durataS => $composableBuilder(
    column: $table.durataS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get passoObiettivoS => $composableBuilder(
    column: $table.passoObiettivoS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recuperoS => $composableBuilder(
    column: $table.recuperoS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ripartenzaS => $composableBuilder(
    column: $table.ripartenzaS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attrezzatura => $composableBuilder(
    column: $table.attrezzatura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get piramideId => $composableBuilder(
    column: $table.piramideId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SerieTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SerieTableTable> {
  $$SerieTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  GeneratedColumn<String> get blocco =>
      $composableBuilder(column: $table.blocco, builder: (column) => column);

  GeneratedColumn<int> get ripetute =>
      $composableBuilder(column: $table.ripetute, builder: (column) => column);

  GeneratedColumn<int> get distanzaM =>
      $composableBuilder(column: $table.distanzaM, builder: (column) => column);

  GeneratedColumn<int> get durataS =>
      $composableBuilder(column: $table.durataS, builder: (column) => column);

  GeneratedColumn<String> get stile =>
      $composableBuilder(column: $table.stile, builder: (column) => column);

  GeneratedColumn<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<double> get passoObiettivoS => $composableBuilder(
    column: $table.passoObiettivoS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recuperoS =>
      $composableBuilder(column: $table.recuperoS, builder: (column) => column);

  GeneratedColumn<double> get ripartenzaS => $composableBuilder(
    column: $table.ripartenzaS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attrezzatura => $composableBuilder(
    column: $table.attrezzatura,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get piramideId => $composableBuilder(
    column: $table.piramideId,
    builder: (column) => column,
  );
}

class $$SerieTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SerieTableTable,
          SerieTableData,
          $$SerieTableTableFilterComposer,
          $$SerieTableTableOrderingComposer,
          $$SerieTableTableAnnotationComposer,
          $$SerieTableTableCreateCompanionBuilder,
          $$SerieTableTableUpdateCompanionBuilder,
          (
            SerieTableData,
            BaseReferences<_$AppDatabase, $SerieTableTable, SerieTableData>,
          ),
          SerieTableData,
          PrefetchHooks Function()
        > {
  $$SerieTableTableTableManager(_$AppDatabase db, $SerieTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SerieTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SerieTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SerieTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> allenamentoId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<String> blocco = const Value.absent(),
                Value<int> ripetute = const Value.absent(),
                Value<int?> distanzaM = const Value.absent(),
                Value<int?> durataS = const Value.absent(),
                Value<String> stile = const Value.absent(),
                Value<String> esecuzione = const Value.absent(),
                Value<String?> zona = const Value.absent(),
                Value<double?> passoObiettivoS = const Value.absent(),
                Value<int?> recuperoS = const Value.absent(),
                Value<double?> ripartenzaS = const Value.absent(),
                Value<String?> attrezzatura = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> piramideId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SerieTableCompanion(
                id: id,
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: ordine,
                blocco: blocco,
                ripetute: ripetute,
                distanzaM: distanzaM,
                durataS: durataS,
                stile: stile,
                esecuzione: esecuzione,
                zona: zona,
                passoObiettivoS: passoObiettivoS,
                recuperoS: recuperoS,
                ripartenzaS: ripartenzaS,
                attrezzatura: attrezzatura,
                note: note,
                piramideId: piramideId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String allenamentoId,
                required String clubId,
                required int ordine,
                required String blocco,
                required int ripetute,
                Value<int?> distanzaM = const Value.absent(),
                Value<int?> durataS = const Value.absent(),
                required String stile,
                required String esecuzione,
                Value<String?> zona = const Value.absent(),
                Value<double?> passoObiettivoS = const Value.absent(),
                Value<int?> recuperoS = const Value.absent(),
                Value<double?> ripartenzaS = const Value.absent(),
                Value<String?> attrezzatura = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> piramideId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SerieTableCompanion.insert(
                id: id,
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: ordine,
                blocco: blocco,
                ripetute: ripetute,
                distanzaM: distanzaM,
                durataS: durataS,
                stile: stile,
                esecuzione: esecuzione,
                zona: zona,
                passoObiettivoS: passoObiettivoS,
                recuperoS: recuperoS,
                ripartenzaS: ripartenzaS,
                attrezzatura: attrezzatura,
                note: note,
                piramideId: piramideId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SerieTableTable, SerieTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SerieTableTable,
                    SerieTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SerieTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SerieTableTable,
      SerieTableData,
      $$SerieTableTableFilterComposer,
      $$SerieTableTableOrderingComposer,
      $$SerieTableTableAnnotationComposer,
      $$SerieTableTableCreateCompanionBuilder,
      $$SerieTableTableUpdateCompanionBuilder,
      (
        SerieTableData,
        BaseReferences<_$AppDatabase, $SerieTableTable, SerieTableData>,
      ),
      SerieTableData,
      PrefetchHooks Function()
    >;
typedef $$PresenzeTableTableCreateCompanionBuilder =
    PresenzeTableCompanion Function({
      required String id,
      required String allenamentoId,
      required String atletaId,
      required String clubId,
      required String stato,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$PresenzeTableTableUpdateCompanionBuilder =
    PresenzeTableCompanion Function({
      Value<String> id,
      Value<String> allenamentoId,
      Value<String> atletaId,
      Value<String> clubId,
      Value<String> stato,
      Value<String?> note,
      Value<int> rowid,
    });

class $$PresenzeTableTableFilterComposer
    extends Composer<_$AppDatabase, $PresenzeTableTable> {
  $$PresenzeTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresenzeTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PresenzeTableTable> {
  $$PresenzeTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresenzeTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresenzeTableTable> {
  $$PresenzeTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get allenamentoId => $composableBuilder(
    column: $table.allenamentoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get stato =>
      $composableBuilder(column: $table.stato, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$PresenzeTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresenzeTableTable,
          PresenzeTableData,
          $$PresenzeTableTableFilterComposer,
          $$PresenzeTableTableOrderingComposer,
          $$PresenzeTableTableAnnotationComposer,
          $$PresenzeTableTableCreateCompanionBuilder,
          $$PresenzeTableTableUpdateCompanionBuilder,
          (
            PresenzeTableData,
            BaseReferences<
              _$AppDatabase,
              $PresenzeTableTable,
              PresenzeTableData
            >,
          ),
          PresenzeTableData,
          PrefetchHooks Function()
        > {
  $$PresenzeTableTableTableManager(_$AppDatabase db, $PresenzeTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresenzeTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresenzeTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresenzeTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> allenamentoId = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> stato = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresenzeTableCompanion(
                id: id,
                allenamentoId: allenamentoId,
                atletaId: atletaId,
                clubId: clubId,
                stato: stato,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String allenamentoId,
                required String atletaId,
                required String clubId,
                required String stato,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresenzeTableCompanion.insert(
                id: id,
                allenamentoId: allenamentoId,
                atletaId: atletaId,
                clubId: clubId,
                stato: stato,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PresenzeTableTable, PresenzeTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PresenzeTableTable,
                    PresenzeTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PresenzeTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresenzeTableTable,
      PresenzeTableData,
      $$PresenzeTableTableFilterComposer,
      $$PresenzeTableTableOrderingComposer,
      $$PresenzeTableTableAnnotationComposer,
      $$PresenzeTableTableCreateCompanionBuilder,
      $$PresenzeTableTableUpdateCompanionBuilder,
      (
        PresenzeTableData,
        BaseReferences<_$AppDatabase, $PresenzeTableTable, PresenzeTableData>,
      ),
      PresenzeTableData,
      PrefetchHooks Function()
    >;
typedef $$PendingOperationsTableTableCreateCompanionBuilder =
    PendingOperationsTableCompanion Function({
      Value<int> id,
      required String tabella,
      required String operazione,
      required String rigaId,
      Value<String?> payloadJson,
      Value<DateTime> creatoIl,
    });
typedef $$PendingOperationsTableTableUpdateCompanionBuilder =
    PendingOperationsTableCompanion Function({
      Value<int> id,
      Value<String> tabella,
      Value<String> operazione,
      Value<String> rigaId,
      Value<String?> payloadJson,
      Value<DateTime> creatoIl,
    });

class $$PendingOperationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTableTable> {
  $$PendingOperationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tabella => $composableBuilder(
    column: $table.tabella,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operazione => $composableBuilder(
    column: $table.operazione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rigaId => $composableBuilder(
    column: $table.rigaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTableTable> {
  $$PendingOperationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tabella => $composableBuilder(
    column: $table.tabella,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operazione => $composableBuilder(
    column: $table.operazione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rigaId => $composableBuilder(
    column: $table.rigaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTableTable> {
  $$PendingOperationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tabella =>
      $composableBuilder(column: $table.tabella, builder: (column) => column);

  GeneratedColumn<String> get operazione => $composableBuilder(
    column: $table.operazione,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rigaId =>
      $composableBuilder(column: $table.rigaId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creatoIl =>
      $composableBuilder(column: $table.creatoIl, builder: (column) => column);
}

class $$PendingOperationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTableTable,
          PendingOperationsTableData,
          $$PendingOperationsTableTableFilterComposer,
          $$PendingOperationsTableTableOrderingComposer,
          $$PendingOperationsTableTableAnnotationComposer,
          $$PendingOperationsTableTableCreateCompanionBuilder,
          $$PendingOperationsTableTableUpdateCompanionBuilder,
          (
            PendingOperationsTableData,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTableTable,
              PendingOperationsTableData
            >,
          ),
          PendingOperationsTableData,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingOperationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tabella = const Value.absent(),
                Value<String> operazione = const Value.absent(),
                Value<String> rigaId = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<DateTime> creatoIl = const Value.absent(),
              }) => PendingOperationsTableCompanion(
                id: id,
                tabella: tabella,
                operazione: operazione,
                rigaId: rigaId,
                payloadJson: payloadJson,
                creatoIl: creatoIl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tabella,
                required String operazione,
                required String rigaId,
                Value<String?> payloadJson = const Value.absent(),
                Value<DateTime> creatoIl = const Value.absent(),
              }) => PendingOperationsTableCompanion.insert(
                id: id,
                tabella: tabella,
                operazione: operazione,
                rigaId: rigaId,
                payloadJson: payloadJson,
                creatoIl: creatoIl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PendingOperationsTableTable,
                    PendingOperationsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingOperationsTableTable,
                    PendingOperationsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTableTable,
      PendingOperationsTableData,
      $$PendingOperationsTableTableFilterComposer,
      $$PendingOperationsTableTableOrderingComposer,
      $$PendingOperationsTableTableAnnotationComposer,
      $$PendingOperationsTableTableCreateCompanionBuilder,
      $$PendingOperationsTableTableUpdateCompanionBuilder,
      (
        PendingOperationsTableData,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTableTable,
          PendingOperationsTableData
        >,
      ),
      PendingOperationsTableData,
      PrefetchHooks Function()
    >;
typedef $$PartiteTableTableCreateCompanionBuilder =
    PartiteTableCompanion Function({
      required String id,
      required String clubId,
      Value<String?> gruppoId,
      required DateTime data,
      Value<String?> ora,
      Value<String?> luogo,
      Value<String?> campionato,
      Value<String?> coloreCalottina,
      required String squadraCasa,
      required String squadraTrasferta,
      Value<int> numeroMaxConvocati,
      Value<String?> note,
      Value<String> dettaglioTiro,
      Value<bool> tracciaTempo,
      Value<String> modalitaSuperiorita,
      Value<String> nostraSquadra,
      Value<String> importanza,
      Value<int> rowid,
    });
typedef $$PartiteTableTableUpdateCompanionBuilder =
    PartiteTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String?> gruppoId,
      Value<DateTime> data,
      Value<String?> ora,
      Value<String?> luogo,
      Value<String?> campionato,
      Value<String?> coloreCalottina,
      Value<String> squadraCasa,
      Value<String> squadraTrasferta,
      Value<int> numeroMaxConvocati,
      Value<String?> note,
      Value<String> dettaglioTiro,
      Value<bool> tracciaTempo,
      Value<String> modalitaSuperiorita,
      Value<String> nostraSquadra,
      Value<String> importanza,
      Value<int> rowid,
    });

class $$PartiteTableTableFilterComposer
    extends Composer<_$AppDatabase, $PartiteTableTable> {
  $$PartiteTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get luogo => $composableBuilder(
    column: $table.luogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coloreCalottina => $composableBuilder(
    column: $table.coloreCalottina,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroMaxConvocati => $composableBuilder(
    column: $table.numeroMaxConvocati,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dettaglioTiro => $composableBuilder(
    column: $table.dettaglioTiro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracciaTempo => $composableBuilder(
    column: $table.tracciaTempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modalitaSuperiorita => $composableBuilder(
    column: $table.modalitaSuperiorita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nostraSquadra => $composableBuilder(
    column: $table.nostraSquadra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PartiteTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PartiteTableTable> {
  $$PartiteTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get luogo => $composableBuilder(
    column: $table.luogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coloreCalottina => $composableBuilder(
    column: $table.coloreCalottina,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroMaxConvocati => $composableBuilder(
    column: $table.numeroMaxConvocati,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dettaglioTiro => $composableBuilder(
    column: $table.dettaglioTiro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracciaTempo => $composableBuilder(
    column: $table.tracciaTempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modalitaSuperiorita => $composableBuilder(
    column: $table.modalitaSuperiorita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nostraSquadra => $composableBuilder(
    column: $table.nostraSquadra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PartiteTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartiteTableTable> {
  $$PartiteTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get gruppoId =>
      $composableBuilder(column: $table.gruppoId, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get ora =>
      $composableBuilder(column: $table.ora, builder: (column) => column);

  GeneratedColumn<String> get luogo =>
      $composableBuilder(column: $table.luogo, builder: (column) => column);

  GeneratedColumn<String> get campionato => $composableBuilder(
    column: $table.campionato,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coloreCalottina => $composableBuilder(
    column: $table.coloreCalottina,
    builder: (column) => column,
  );

  GeneratedColumn<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numeroMaxConvocati => $composableBuilder(
    column: $table.numeroMaxConvocati,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get dettaglioTiro => $composableBuilder(
    column: $table.dettaglioTiro,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracciaTempo => $composableBuilder(
    column: $table.tracciaTempo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modalitaSuperiorita => $composableBuilder(
    column: $table.modalitaSuperiorita,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nostraSquadra => $composableBuilder(
    column: $table.nostraSquadra,
    builder: (column) => column,
  );

  GeneratedColumn<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => column,
  );
}

class $$PartiteTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartiteTableTable,
          PartiteTableData,
          $$PartiteTableTableFilterComposer,
          $$PartiteTableTableOrderingComposer,
          $$PartiteTableTableAnnotationComposer,
          $$PartiteTableTableCreateCompanionBuilder,
          $$PartiteTableTableUpdateCompanionBuilder,
          (
            PartiteTableData,
            BaseReferences<_$AppDatabase, $PartiteTableTable, PartiteTableData>,
          ),
          PartiteTableData,
          PrefetchHooks Function()
        > {
  $$PartiteTableTableTableManager(_$AppDatabase db, $PartiteTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartiteTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartiteTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartiteTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> ora = const Value.absent(),
                Value<String?> luogo = const Value.absent(),
                Value<String?> campionato = const Value.absent(),
                Value<String?> coloreCalottina = const Value.absent(),
                Value<String> squadraCasa = const Value.absent(),
                Value<String> squadraTrasferta = const Value.absent(),
                Value<int> numeroMaxConvocati = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> dettaglioTiro = const Value.absent(),
                Value<bool> tracciaTempo = const Value.absent(),
                Value<String> modalitaSuperiorita = const Value.absent(),
                Value<String> nostraSquadra = const Value.absent(),
                Value<String> importanza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiteTableCompanion(
                id: id,
                clubId: clubId,
                gruppoId: gruppoId,
                data: data,
                ora: ora,
                luogo: luogo,
                campionato: campionato,
                coloreCalottina: coloreCalottina,
                squadraCasa: squadraCasa,
                squadraTrasferta: squadraTrasferta,
                numeroMaxConvocati: numeroMaxConvocati,
                note: note,
                dettaglioTiro: dettaglioTiro,
                tracciaTempo: tracciaTempo,
                modalitaSuperiorita: modalitaSuperiorita,
                nostraSquadra: nostraSquadra,
                importanza: importanza,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                Value<String?> gruppoId = const Value.absent(),
                required DateTime data,
                Value<String?> ora = const Value.absent(),
                Value<String?> luogo = const Value.absent(),
                Value<String?> campionato = const Value.absent(),
                Value<String?> coloreCalottina = const Value.absent(),
                required String squadraCasa,
                required String squadraTrasferta,
                Value<int> numeroMaxConvocati = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> dettaglioTiro = const Value.absent(),
                Value<bool> tracciaTempo = const Value.absent(),
                Value<String> modalitaSuperiorita = const Value.absent(),
                Value<String> nostraSquadra = const Value.absent(),
                Value<String> importanza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiteTableCompanion.insert(
                id: id,
                clubId: clubId,
                gruppoId: gruppoId,
                data: data,
                ora: ora,
                luogo: luogo,
                campionato: campionato,
                coloreCalottina: coloreCalottina,
                squadraCasa: squadraCasa,
                squadraTrasferta: squadraTrasferta,
                numeroMaxConvocati: numeroMaxConvocati,
                note: note,
                dettaglioTiro: dettaglioTiro,
                tracciaTempo: tracciaTempo,
                modalitaSuperiorita: modalitaSuperiorita,
                nostraSquadra: nostraSquadra,
                importanza: importanza,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PartiteTableTable, PartiteTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PartiteTableTable,
                    PartiteTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PartiteTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartiteTableTable,
      PartiteTableData,
      $$PartiteTableTableFilterComposer,
      $$PartiteTableTableOrderingComposer,
      $$PartiteTableTableAnnotationComposer,
      $$PartiteTableTableCreateCompanionBuilder,
      $$PartiteTableTableUpdateCompanionBuilder,
      (
        PartiteTableData,
        BaseReferences<_$AppDatabase, $PartiteTableTable, PartiteTableData>,
      ),
      PartiteTableData,
      PrefetchHooks Function()
    >;
typedef $$DistintaGiocatoriTableTableCreateCompanionBuilder =
    DistintaGiocatoriTableCompanion Function({
      required String id,
      required String partitaId,
      required String atletaId,
      required String clubId,
      required int numeroCalottina,
      Value<bool> capitano,
      Value<bool> viceCapitano,
      Value<bool> portiere,
      Value<bool> fuoriquota,
      Value<int> rowid,
    });
typedef $$DistintaGiocatoriTableTableUpdateCompanionBuilder =
    DistintaGiocatoriTableCompanion Function({
      Value<String> id,
      Value<String> partitaId,
      Value<String> atletaId,
      Value<String> clubId,
      Value<int> numeroCalottina,
      Value<bool> capitano,
      Value<bool> viceCapitano,
      Value<bool> portiere,
      Value<bool> fuoriquota,
      Value<int> rowid,
    });

class $$DistintaGiocatoriTableTableFilterComposer
    extends Composer<_$AppDatabase, $DistintaGiocatoriTableTable> {
  $$DistintaGiocatoriTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroCalottina => $composableBuilder(
    column: $table.numeroCalottina,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capitano => $composableBuilder(
    column: $table.capitano,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get viceCapitano => $composableBuilder(
    column: $table.viceCapitano,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get portiere => $composableBuilder(
    column: $table.portiere,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fuoriquota => $composableBuilder(
    column: $table.fuoriquota,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DistintaGiocatoriTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DistintaGiocatoriTableTable> {
  $$DistintaGiocatoriTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroCalottina => $composableBuilder(
    column: $table.numeroCalottina,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capitano => $composableBuilder(
    column: $table.capitano,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get viceCapitano => $composableBuilder(
    column: $table.viceCapitano,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get portiere => $composableBuilder(
    column: $table.portiere,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fuoriquota => $composableBuilder(
    column: $table.fuoriquota,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DistintaGiocatoriTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DistintaGiocatoriTableTable> {
  $$DistintaGiocatoriTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partitaId =>
      $composableBuilder(column: $table.partitaId, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<int> get numeroCalottina => $composableBuilder(
    column: $table.numeroCalottina,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get capitano =>
      $composableBuilder(column: $table.capitano, builder: (column) => column);

  GeneratedColumn<bool> get viceCapitano => $composableBuilder(
    column: $table.viceCapitano,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get portiere =>
      $composableBuilder(column: $table.portiere, builder: (column) => column);

  GeneratedColumn<bool> get fuoriquota => $composableBuilder(
    column: $table.fuoriquota,
    builder: (column) => column,
  );
}

class $$DistintaGiocatoriTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DistintaGiocatoriTableTable,
          DistintaGiocatoriTableData,
          $$DistintaGiocatoriTableTableFilterComposer,
          $$DistintaGiocatoriTableTableOrderingComposer,
          $$DistintaGiocatoriTableTableAnnotationComposer,
          $$DistintaGiocatoriTableTableCreateCompanionBuilder,
          $$DistintaGiocatoriTableTableUpdateCompanionBuilder,
          (
            DistintaGiocatoriTableData,
            BaseReferences<
              _$AppDatabase,
              $DistintaGiocatoriTableTable,
              DistintaGiocatoriTableData
            >,
          ),
          DistintaGiocatoriTableData,
          PrefetchHooks Function()
        > {
  $$DistintaGiocatoriTableTableTableManager(
    _$AppDatabase db,
    $DistintaGiocatoriTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistintaGiocatoriTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DistintaGiocatoriTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DistintaGiocatoriTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> partitaId = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<int> numeroCalottina = const Value.absent(),
                Value<bool> capitano = const Value.absent(),
                Value<bool> viceCapitano = const Value.absent(),
                Value<bool> portiere = const Value.absent(),
                Value<bool> fuoriquota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DistintaGiocatoriTableCompanion(
                id: id,
                partitaId: partitaId,
                atletaId: atletaId,
                clubId: clubId,
                numeroCalottina: numeroCalottina,
                capitano: capitano,
                viceCapitano: viceCapitano,
                portiere: portiere,
                fuoriquota: fuoriquota,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String partitaId,
                required String atletaId,
                required String clubId,
                required int numeroCalottina,
                Value<bool> capitano = const Value.absent(),
                Value<bool> viceCapitano = const Value.absent(),
                Value<bool> portiere = const Value.absent(),
                Value<bool> fuoriquota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DistintaGiocatoriTableCompanion.insert(
                id: id,
                partitaId: partitaId,
                atletaId: atletaId,
                clubId: clubId,
                numeroCalottina: numeroCalottina,
                capitano: capitano,
                viceCapitano: viceCapitano,
                portiere: portiere,
                fuoriquota: fuoriquota,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $DistintaGiocatoriTableTable,
                    DistintaGiocatoriTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DistintaGiocatoriTableTable,
                    DistintaGiocatoriTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DistintaGiocatoriTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DistintaGiocatoriTableTable,
      DistintaGiocatoriTableData,
      $$DistintaGiocatoriTableTableFilterComposer,
      $$DistintaGiocatoriTableTableOrderingComposer,
      $$DistintaGiocatoriTableTableAnnotationComposer,
      $$DistintaGiocatoriTableTableCreateCompanionBuilder,
      $$DistintaGiocatoriTableTableUpdateCompanionBuilder,
      (
        DistintaGiocatoriTableData,
        BaseReferences<
          _$AppDatabase,
          $DistintaGiocatoriTableTable,
          DistintaGiocatoriTableData
        >,
      ),
      DistintaGiocatoriTableData,
      PrefetchHooks Function()
    >;
typedef $$EventiPartitaTableTableCreateCompanionBuilder =
    EventiPartitaTableCompanion Function({
      required String id,
      required String partitaId,
      required String clubId,
      required String tipo,
      Value<String> squadra,
      Value<String?> atletaId,
      Value<int?> periodo,
      Value<String?> esito,
      Value<String> contestoTiro,
      Value<double?> posX,
      Value<double?> posY,
      Value<int?> numeroCalottinaAvversario,
      Value<bool> espulsioneDaRigore,
      required DateTime creatoIl,
      Value<int> rowid,
    });
typedef $$EventiPartitaTableTableUpdateCompanionBuilder =
    EventiPartitaTableCompanion Function({
      Value<String> id,
      Value<String> partitaId,
      Value<String> clubId,
      Value<String> tipo,
      Value<String> squadra,
      Value<String?> atletaId,
      Value<int?> periodo,
      Value<String?> esito,
      Value<String> contestoTiro,
      Value<double?> posX,
      Value<double?> posY,
      Value<int?> numeroCalottinaAvversario,
      Value<bool> espulsioneDaRigore,
      Value<DateTime> creatoIl,
      Value<int> rowid,
    });

class $$EventiPartitaTableTableFilterComposer
    extends Composer<_$AppDatabase, $EventiPartitaTableTable> {
  $$EventiPartitaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get squadra => $composableBuilder(
    column: $table.squadra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodo => $composableBuilder(
    column: $table.periodo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esito => $composableBuilder(
    column: $table.esito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contestoTiro => $composableBuilder(
    column: $table.contestoTiro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroCalottinaAvversario => $composableBuilder(
    column: $table.numeroCalottinaAvversario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get espulsioneDaRigore => $composableBuilder(
    column: $table.espulsioneDaRigore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventiPartitaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EventiPartitaTableTable> {
  $$EventiPartitaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get squadra => $composableBuilder(
    column: $table.squadra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodo => $composableBuilder(
    column: $table.periodo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esito => $composableBuilder(
    column: $table.esito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contestoTiro => $composableBuilder(
    column: $table.contestoTiro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroCalottinaAvversario => $composableBuilder(
    column: $table.numeroCalottinaAvversario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get espulsioneDaRigore => $composableBuilder(
    column: $table.espulsioneDaRigore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventiPartitaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventiPartitaTableTable> {
  $$EventiPartitaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partitaId =>
      $composableBuilder(column: $table.partitaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get squadra =>
      $composableBuilder(column: $table.squadra, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<int> get periodo =>
      $composableBuilder(column: $table.periodo, builder: (column) => column);

  GeneratedColumn<String> get esito =>
      $composableBuilder(column: $table.esito, builder: (column) => column);

  GeneratedColumn<String> get contestoTiro => $composableBuilder(
    column: $table.contestoTiro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get posX =>
      $composableBuilder(column: $table.posX, builder: (column) => column);

  GeneratedColumn<double> get posY =>
      $composableBuilder(column: $table.posY, builder: (column) => column);

  GeneratedColumn<int> get numeroCalottinaAvversario => $composableBuilder(
    column: $table.numeroCalottinaAvversario,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get espulsioneDaRigore => $composableBuilder(
    column: $table.espulsioneDaRigore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creatoIl =>
      $composableBuilder(column: $table.creatoIl, builder: (column) => column);
}

class $$EventiPartitaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventiPartitaTableTable,
          EventiPartitaTableData,
          $$EventiPartitaTableTableFilterComposer,
          $$EventiPartitaTableTableOrderingComposer,
          $$EventiPartitaTableTableAnnotationComposer,
          $$EventiPartitaTableTableCreateCompanionBuilder,
          $$EventiPartitaTableTableUpdateCompanionBuilder,
          (
            EventiPartitaTableData,
            BaseReferences<
              _$AppDatabase,
              $EventiPartitaTableTable,
              EventiPartitaTableData
            >,
          ),
          EventiPartitaTableData,
          PrefetchHooks Function()
        > {
  $$EventiPartitaTableTableTableManager(
    _$AppDatabase db,
    $EventiPartitaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventiPartitaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventiPartitaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventiPartitaTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> partitaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> squadra = const Value.absent(),
                Value<String?> atletaId = const Value.absent(),
                Value<int?> periodo = const Value.absent(),
                Value<String?> esito = const Value.absent(),
                Value<String> contestoTiro = const Value.absent(),
                Value<double?> posX = const Value.absent(),
                Value<double?> posY = const Value.absent(),
                Value<int?> numeroCalottinaAvversario = const Value.absent(),
                Value<bool> espulsioneDaRigore = const Value.absent(),
                Value<DateTime> creatoIl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventiPartitaTableCompanion(
                id: id,
                partitaId: partitaId,
                clubId: clubId,
                tipo: tipo,
                squadra: squadra,
                atletaId: atletaId,
                periodo: periodo,
                esito: esito,
                contestoTiro: contestoTiro,
                posX: posX,
                posY: posY,
                numeroCalottinaAvversario: numeroCalottinaAvversario,
                espulsioneDaRigore: espulsioneDaRigore,
                creatoIl: creatoIl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String partitaId,
                required String clubId,
                required String tipo,
                Value<String> squadra = const Value.absent(),
                Value<String?> atletaId = const Value.absent(),
                Value<int?> periodo = const Value.absent(),
                Value<String?> esito = const Value.absent(),
                Value<String> contestoTiro = const Value.absent(),
                Value<double?> posX = const Value.absent(),
                Value<double?> posY = const Value.absent(),
                Value<int?> numeroCalottinaAvversario = const Value.absent(),
                Value<bool> espulsioneDaRigore = const Value.absent(),
                required DateTime creatoIl,
                Value<int> rowid = const Value.absent(),
              }) => EventiPartitaTableCompanion.insert(
                id: id,
                partitaId: partitaId,
                clubId: clubId,
                tipo: tipo,
                squadra: squadra,
                atletaId: atletaId,
                periodo: periodo,
                esito: esito,
                contestoTiro: contestoTiro,
                posX: posX,
                posY: posY,
                numeroCalottinaAvversario: numeroCalottinaAvversario,
                espulsioneDaRigore: espulsioneDaRigore,
                creatoIl: creatoIl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventiPartitaTableTable, EventiPartitaTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $EventiPartitaTableTable,
                    EventiPartitaTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventiPartitaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventiPartitaTableTable,
      EventiPartitaTableData,
      $$EventiPartitaTableTableFilterComposer,
      $$EventiPartitaTableTableOrderingComposer,
      $$EventiPartitaTableTableAnnotationComposer,
      $$EventiPartitaTableTableCreateCompanionBuilder,
      $$EventiPartitaTableTableUpdateCompanionBuilder,
      (
        EventiPartitaTableData,
        BaseReferences<
          _$AppDatabase,
          $EventiPartitaTableTable,
          EventiPartitaTableData
        >,
      ),
      EventiPartitaTableData,
      PrefetchHooks Function()
    >;
typedef $$RefertiPartitaTableTableCreateCompanionBuilder =
    RefertiPartitaTableCompanion Function({
      required String id,
      required String partitaId,
      required String clubId,
      required String squadraCasa,
      required String squadraTrasferta,
      required int risultatoCasa,
      required int risultatoTrasferta,
      Value<String> parzialiJson,
      Value<String> giocatoriCasaJson,
      Value<String> giocatoriTrasfertaJson,
      Value<int> rowid,
    });
typedef $$RefertiPartitaTableTableUpdateCompanionBuilder =
    RefertiPartitaTableCompanion Function({
      Value<String> id,
      Value<String> partitaId,
      Value<String> clubId,
      Value<String> squadraCasa,
      Value<String> squadraTrasferta,
      Value<int> risultatoCasa,
      Value<int> risultatoTrasferta,
      Value<String> parzialiJson,
      Value<String> giocatoriCasaJson,
      Value<String> giocatoriTrasfertaJson,
      Value<int> rowid,
    });

class $$RefertiPartitaTableTableFilterComposer
    extends Composer<_$AppDatabase, $RefertiPartitaTableTable> {
  $$RefertiPartitaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get risultatoCasa => $composableBuilder(
    column: $table.risultatoCasa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get risultatoTrasferta => $composableBuilder(
    column: $table.risultatoTrasferta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parzialiJson => $composableBuilder(
    column: $table.parzialiJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giocatoriCasaJson => $composableBuilder(
    column: $table.giocatoriCasaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get giocatoriTrasfertaJson => $composableBuilder(
    column: $table.giocatoriTrasfertaJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RefertiPartitaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RefertiPartitaTableTable> {
  $$RefertiPartitaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partitaId => $composableBuilder(
    column: $table.partitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get risultatoCasa => $composableBuilder(
    column: $table.risultatoCasa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get risultatoTrasferta => $composableBuilder(
    column: $table.risultatoTrasferta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parzialiJson => $composableBuilder(
    column: $table.parzialiJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giocatoriCasaJson => $composableBuilder(
    column: $table.giocatoriCasaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get giocatoriTrasfertaJson => $composableBuilder(
    column: $table.giocatoriTrasfertaJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RefertiPartitaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefertiPartitaTableTable> {
  $$RefertiPartitaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partitaId =>
      $composableBuilder(column: $table.partitaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get squadraCasa => $composableBuilder(
    column: $table.squadraCasa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get squadraTrasferta => $composableBuilder(
    column: $table.squadraTrasferta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get risultatoCasa => $composableBuilder(
    column: $table.risultatoCasa,
    builder: (column) => column,
  );

  GeneratedColumn<int> get risultatoTrasferta => $composableBuilder(
    column: $table.risultatoTrasferta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parzialiJson => $composableBuilder(
    column: $table.parzialiJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get giocatoriCasaJson => $composableBuilder(
    column: $table.giocatoriCasaJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get giocatoriTrasfertaJson => $composableBuilder(
    column: $table.giocatoriTrasfertaJson,
    builder: (column) => column,
  );
}

class $$RefertiPartitaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefertiPartitaTableTable,
          RefertiPartitaTableData,
          $$RefertiPartitaTableTableFilterComposer,
          $$RefertiPartitaTableTableOrderingComposer,
          $$RefertiPartitaTableTableAnnotationComposer,
          $$RefertiPartitaTableTableCreateCompanionBuilder,
          $$RefertiPartitaTableTableUpdateCompanionBuilder,
          (
            RefertiPartitaTableData,
            BaseReferences<
              _$AppDatabase,
              $RefertiPartitaTableTable,
              RefertiPartitaTableData
            >,
          ),
          RefertiPartitaTableData,
          PrefetchHooks Function()
        > {
  $$RefertiPartitaTableTableTableManager(
    _$AppDatabase db,
    $RefertiPartitaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefertiPartitaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefertiPartitaTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RefertiPartitaTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> partitaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> squadraCasa = const Value.absent(),
                Value<String> squadraTrasferta = const Value.absent(),
                Value<int> risultatoCasa = const Value.absent(),
                Value<int> risultatoTrasferta = const Value.absent(),
                Value<String> parzialiJson = const Value.absent(),
                Value<String> giocatoriCasaJson = const Value.absent(),
                Value<String> giocatoriTrasfertaJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefertiPartitaTableCompanion(
                id: id,
                partitaId: partitaId,
                clubId: clubId,
                squadraCasa: squadraCasa,
                squadraTrasferta: squadraTrasferta,
                risultatoCasa: risultatoCasa,
                risultatoTrasferta: risultatoTrasferta,
                parzialiJson: parzialiJson,
                giocatoriCasaJson: giocatoriCasaJson,
                giocatoriTrasfertaJson: giocatoriTrasfertaJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String partitaId,
                required String clubId,
                required String squadraCasa,
                required String squadraTrasferta,
                required int risultatoCasa,
                required int risultatoTrasferta,
                Value<String> parzialiJson = const Value.absent(),
                Value<String> giocatoriCasaJson = const Value.absent(),
                Value<String> giocatoriTrasfertaJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefertiPartitaTableCompanion.insert(
                id: id,
                partitaId: partitaId,
                clubId: clubId,
                squadraCasa: squadraCasa,
                squadraTrasferta: squadraTrasferta,
                risultatoCasa: risultatoCasa,
                risultatoTrasferta: risultatoTrasferta,
                parzialiJson: parzialiJson,
                giocatoriCasaJson: giocatoriCasaJson,
                giocatoriTrasfertaJson: giocatoriTrasfertaJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RefertiPartitaTableTable,
                    RefertiPartitaTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RefertiPartitaTableTable,
                    RefertiPartitaTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RefertiPartitaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefertiPartitaTableTable,
      RefertiPartitaTableData,
      $$RefertiPartitaTableTableFilterComposer,
      $$RefertiPartitaTableTableOrderingComposer,
      $$RefertiPartitaTableTableAnnotationComposer,
      $$RefertiPartitaTableTableCreateCompanionBuilder,
      $$RefertiPartitaTableTableUpdateCompanionBuilder,
      (
        RefertiPartitaTableData,
        BaseReferences<
          _$AppDatabase,
          $RefertiPartitaTableTable,
          RefertiPartitaTableData
        >,
      ),
      RefertiPartitaTableData,
      PrefetchHooks Function()
    >;
typedef $$GruppiTableTableCreateCompanionBuilder =
    GruppiTableCompanion Function({
      required String id,
      required String clubId,
      required String nome,
      Value<int> ordine,
      Value<String?> sport,
      Value<int> rowid,
    });
typedef $$GruppiTableTableUpdateCompanionBuilder =
    GruppiTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String> nome,
      Value<int> ordine,
      Value<String?> sport,
      Value<int> rowid,
    });

class $$GruppiTableTableFilterComposer
    extends Composer<_$AppDatabase, $GruppiTableTable> {
  $$GruppiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GruppiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GruppiTableTable> {
  $$GruppiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GruppiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GruppiTableTable> {
  $$GruppiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);
}

class $$GruppiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GruppiTableTable,
          GruppiTableData,
          $$GruppiTableTableFilterComposer,
          $$GruppiTableTableOrderingComposer,
          $$GruppiTableTableAnnotationComposer,
          $$GruppiTableTableCreateCompanionBuilder,
          $$GruppiTableTableUpdateCompanionBuilder,
          (
            GruppiTableData,
            BaseReferences<_$AppDatabase, $GruppiTableTable, GruppiTableData>,
          ),
          GruppiTableData,
          PrefetchHooks Function()
        > {
  $$GruppiTableTableTableManager(_$AppDatabase db, $GruppiTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GruppiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GruppiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GruppiTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GruppiTableCompanion(
                id: id,
                clubId: clubId,
                nome: nome,
                ordine: ordine,
                sport: sport,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required String nome,
                Value<int> ordine = const Value.absent(),
                Value<String?> sport = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GruppiTableCompanion.insert(
                id: id,
                clubId: clubId,
                nome: nome,
                ordine: ordine,
                sport: sport,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GruppiTableTable, GruppiTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GruppiTableTable,
                    GruppiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GruppiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GruppiTableTable,
      GruppiTableData,
      $$GruppiTableTableFilterComposer,
      $$GruppiTableTableOrderingComposer,
      $$GruppiTableTableAnnotationComposer,
      $$GruppiTableTableCreateCompanionBuilder,
      $$GruppiTableTableUpdateCompanionBuilder,
      (
        GruppiTableData,
        BaseReferences<_$AppDatabase, $GruppiTableTable, GruppiTableData>,
      ),
      GruppiTableData,
      PrefetchHooks Function()
    >;
typedef $$GareTableTableCreateCompanionBuilder = GareTableCompanion Function({
  required String id,
  required String clubId,
  Value<String?> gruppoId,
  required DateTime data,
  Value<String?> ora,
  Value<String?> luogo,
  required String nome,
  Value<String?> note,
  Value<String> importanza,
  Value<int> rowid,
});
typedef $$GareTableTableUpdateCompanionBuilder = GareTableCompanion Function({
  Value<String> id,
  Value<String> clubId,
  Value<String?> gruppoId,
  Value<DateTime> data,
  Value<String?> ora,
  Value<String?> luogo,
  Value<String> nome,
  Value<String?> note,
  Value<String> importanza,
  Value<int> rowid,
});

class $$GareTableTableFilterComposer
    extends Composer<_$AppDatabase, $GareTableTable> {
  $$GareTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get luogo => $composableBuilder(
    column: $table.luogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GareTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GareTableTable> {
  $$GareTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gruppoId => $composableBuilder(
    column: $table.gruppoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ora => $composableBuilder(
    column: $table.ora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get luogo => $composableBuilder(
    column: $table.luogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GareTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GareTableTable> {
  $$GareTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get gruppoId =>
      $composableBuilder(column: $table.gruppoId, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get ora =>
      $composableBuilder(column: $table.ora, builder: (column) => column);

  GeneratedColumn<String> get luogo =>
      $composableBuilder(column: $table.luogo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get importanza => $composableBuilder(
    column: $table.importanza,
    builder: (column) => column,
  );
}

class $$GareTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GareTableTable,
          GareTableData,
          $$GareTableTableFilterComposer,
          $$GareTableTableOrderingComposer,
          $$GareTableTableAnnotationComposer,
          $$GareTableTableCreateCompanionBuilder,
          $$GareTableTableUpdateCompanionBuilder,
          (
            GareTableData,
            BaseReferences<_$AppDatabase, $GareTableTable, GareTableData>,
          ),
          GareTableData,
          PrefetchHooks Function()
        > {
  $$GareTableTableTableManager(_$AppDatabase db, $GareTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GareTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GareTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GareTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String?> gruppoId = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> ora = const Value.absent(),
                Value<String?> luogo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> importanza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GareTableCompanion(
                id: id,
                clubId: clubId,
                gruppoId: gruppoId,
                data: data,
                ora: ora,
                luogo: luogo,
                nome: nome,
                note: note,
                importanza: importanza,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                Value<String?> gruppoId = const Value.absent(),
                required DateTime data,
                Value<String?> ora = const Value.absent(),
                Value<String?> luogo = const Value.absent(),
                required String nome,
                Value<String?> note = const Value.absent(),
                Value<String> importanza = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GareTableCompanion.insert(
                id: id,
                clubId: clubId,
                gruppoId: gruppoId,
                data: data,
                ora: ora,
                luogo: luogo,
                nome: nome,
                note: note,
                importanza: importanza,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GareTableTable, GareTableData>(table),
                  BaseReferences<_$AppDatabase, $GareTableTable, GareTableData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GareTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GareTableTable,
      GareTableData,
      $$GareTableTableFilterComposer,
      $$GareTableTableOrderingComposer,
      $$GareTableTableAnnotationComposer,
      $$GareTableTableCreateCompanionBuilder,
      $$GareTableTableUpdateCompanionBuilder,
      (
        GareTableData,
        BaseReferences<_$AppDatabase, $GareTableTable, GareTableData>,
      ),
      GareTableData,
      PrefetchHooks Function()
    >;
typedef $$GaraIscrittiTableTableCreateCompanionBuilder =
    GaraIscrittiTableCompanion Function({
      required String id,
      required String garaId,
      required String atletaId,
      required String clubId,
      Value<int> rowid,
    });
typedef $$GaraIscrittiTableTableUpdateCompanionBuilder =
    GaraIscrittiTableCompanion Function({
      Value<String> id,
      Value<String> garaId,
      Value<String> atletaId,
      Value<String> clubId,
      Value<int> rowid,
    });

class $$GaraIscrittiTableTableFilterComposer
    extends Composer<_$AppDatabase, $GaraIscrittiTableTable> {
  $$GaraIscrittiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get garaId => $composableBuilder(
    column: $table.garaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GaraIscrittiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GaraIscrittiTableTable> {
  $$GaraIscrittiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get garaId => $composableBuilder(
    column: $table.garaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GaraIscrittiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GaraIscrittiTableTable> {
  $$GaraIscrittiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get garaId =>
      $composableBuilder(column: $table.garaId, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);
}

class $$GaraIscrittiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GaraIscrittiTableTable,
          GaraIscrittiTableData,
          $$GaraIscrittiTableTableFilterComposer,
          $$GaraIscrittiTableTableOrderingComposer,
          $$GaraIscrittiTableTableAnnotationComposer,
          $$GaraIscrittiTableTableCreateCompanionBuilder,
          $$GaraIscrittiTableTableUpdateCompanionBuilder,
          (
            GaraIscrittiTableData,
            BaseReferences<
              _$AppDatabase,
              $GaraIscrittiTableTable,
              GaraIscrittiTableData
            >,
          ),
          GaraIscrittiTableData,
          PrefetchHooks Function()
        > {
  $$GaraIscrittiTableTableTableManager(
    _$AppDatabase db,
    $GaraIscrittiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GaraIscrittiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GaraIscrittiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GaraIscrittiTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> garaId = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GaraIscrittiTableCompanion(
                id: id,
                garaId: garaId,
                atletaId: atletaId,
                clubId: clubId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String garaId,
                required String atletaId,
                required String clubId,
                Value<int> rowid = const Value.absent(),
              }) => GaraIscrittiTableCompanion.insert(
                id: id,
                garaId: garaId,
                atletaId: atletaId,
                clubId: clubId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GaraIscrittiTableTable, GaraIscrittiTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $GaraIscrittiTableTable,
                    GaraIscrittiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GaraIscrittiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GaraIscrittiTableTable,
      GaraIscrittiTableData,
      $$GaraIscrittiTableTableFilterComposer,
      $$GaraIscrittiTableTableOrderingComposer,
      $$GaraIscrittiTableTableAnnotationComposer,
      $$GaraIscrittiTableTableCreateCompanionBuilder,
      $$GaraIscrittiTableTableUpdateCompanionBuilder,
      (
        GaraIscrittiTableData,
        BaseReferences<
          _$AppDatabase,
          $GaraIscrittiTableTable,
          GaraIscrittiTableData
        >,
      ),
      GaraIscrittiTableData,
      PrefetchHooks Function()
    >;
typedef $$TrainingBlocksTableTableCreateCompanionBuilder =
    TrainingBlocksTableCompanion Function({
      required String id,
      required String clubId,
      required String codice,
      required String sport,
      required String fase,
      required String obiettivo,
      required String zoneCoinvolte,
      required String titolo,
      required String descrizione,
      Value<String?> stilePrincipale,
      Value<String> livelli,
      Value<String?> attrezzi,
      Value<int> metriTotali,
      Value<int> durataStimataMin,
      Value<String?> note,
      Value<String> stato,
      Value<String> fonte,
      Value<DateTime?> importatoIl,
      Value<bool> modificatoInApp,
      Value<int> rowid,
    });
typedef $$TrainingBlocksTableTableUpdateCompanionBuilder =
    TrainingBlocksTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String> codice,
      Value<String> sport,
      Value<String> fase,
      Value<String> obiettivo,
      Value<String> zoneCoinvolte,
      Value<String> titolo,
      Value<String> descrizione,
      Value<String?> stilePrincipale,
      Value<String> livelli,
      Value<String?> attrezzi,
      Value<int> metriTotali,
      Value<int> durataStimataMin,
      Value<String?> note,
      Value<String> stato,
      Value<String> fonte,
      Value<DateTime?> importatoIl,
      Value<bool> modificatoInApp,
      Value<int> rowid,
    });

class $$TrainingBlocksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingBlocksTableTable> {
  $$TrainingBlocksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codice => $composableBuilder(
    column: $table.codice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fase => $composableBuilder(
    column: $table.fase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obiettivo => $composableBuilder(
    column: $table.obiettivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneCoinvolte => $composableBuilder(
    column: $table.zoneCoinvolte,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stilePrincipale => $composableBuilder(
    column: $table.stilePrincipale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get livelli => $composableBuilder(
    column: $table.livelli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attrezzi => $composableBuilder(
    column: $table.attrezzi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metriTotali => $composableBuilder(
    column: $table.metriTotali,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durataStimataMin => $composableBuilder(
    column: $table.durataStimataMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importatoIl => $composableBuilder(
    column: $table.importatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get modificatoInApp => $composableBuilder(
    column: $table.modificatoInApp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainingBlocksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingBlocksTableTable> {
  $$TrainingBlocksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codice => $composableBuilder(
    column: $table.codice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sport => $composableBuilder(
    column: $table.sport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fase => $composableBuilder(
    column: $table.fase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obiettivo => $composableBuilder(
    column: $table.obiettivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneCoinvolte => $composableBuilder(
    column: $table.zoneCoinvolte,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titolo => $composableBuilder(
    column: $table.titolo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stilePrincipale => $composableBuilder(
    column: $table.stilePrincipale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get livelli => $composableBuilder(
    column: $table.livelli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attrezzi => $composableBuilder(
    column: $table.attrezzi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metriTotali => $composableBuilder(
    column: $table.metriTotali,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durataStimataMin => $composableBuilder(
    column: $table.durataStimataMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importatoIl => $composableBuilder(
    column: $table.importatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get modificatoInApp => $composableBuilder(
    column: $table.modificatoInApp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainingBlocksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingBlocksTableTable> {
  $$TrainingBlocksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get codice =>
      $composableBuilder(column: $table.codice, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<String> get fase =>
      $composableBuilder(column: $table.fase, builder: (column) => column);

  GeneratedColumn<String> get obiettivo =>
      $composableBuilder(column: $table.obiettivo, builder: (column) => column);

  GeneratedColumn<String> get zoneCoinvolte => $composableBuilder(
    column: $table.zoneCoinvolte,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titolo =>
      $composableBuilder(column: $table.titolo, builder: (column) => column);

  GeneratedColumn<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stilePrincipale => $composableBuilder(
    column: $table.stilePrincipale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get livelli =>
      $composableBuilder(column: $table.livelli, builder: (column) => column);

  GeneratedColumn<String> get attrezzi =>
      $composableBuilder(column: $table.attrezzi, builder: (column) => column);

  GeneratedColumn<int> get metriTotali => $composableBuilder(
    column: $table.metriTotali,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durataStimataMin => $composableBuilder(
    column: $table.durataStimataMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get stato =>
      $composableBuilder(column: $table.stato, builder: (column) => column);

  GeneratedColumn<String> get fonte =>
      $composableBuilder(column: $table.fonte, builder: (column) => column);

  GeneratedColumn<DateTime> get importatoIl => $composableBuilder(
    column: $table.importatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get modificatoInApp => $composableBuilder(
    column: $table.modificatoInApp,
    builder: (column) => column,
  );
}

class $$TrainingBlocksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingBlocksTableTable,
          TrainingBlocksTableData,
          $$TrainingBlocksTableTableFilterComposer,
          $$TrainingBlocksTableTableOrderingComposer,
          $$TrainingBlocksTableTableAnnotationComposer,
          $$TrainingBlocksTableTableCreateCompanionBuilder,
          $$TrainingBlocksTableTableUpdateCompanionBuilder,
          (
            TrainingBlocksTableData,
            BaseReferences<
              _$AppDatabase,
              $TrainingBlocksTableTable,
              TrainingBlocksTableData
            >,
          ),
          TrainingBlocksTableData,
          PrefetchHooks Function()
        > {
  $$TrainingBlocksTableTableTableManager(
    _$AppDatabase db,
    $TrainingBlocksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingBlocksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingBlocksTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrainingBlocksTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<String> codice = const Value.absent(),
                Value<String> sport = const Value.absent(),
                Value<String> fase = const Value.absent(),
                Value<String> obiettivo = const Value.absent(),
                Value<String> zoneCoinvolte = const Value.absent(),
                Value<String> titolo = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<String?> stilePrincipale = const Value.absent(),
                Value<String> livelli = const Value.absent(),
                Value<String?> attrezzi = const Value.absent(),
                Value<int> metriTotali = const Value.absent(),
                Value<int> durataStimataMin = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> stato = const Value.absent(),
                Value<String> fonte = const Value.absent(),
                Value<DateTime?> importatoIl = const Value.absent(),
                Value<bool> modificatoInApp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingBlocksTableCompanion(
                id: id,
                clubId: clubId,
                codice: codice,
                sport: sport,
                fase: fase,
                obiettivo: obiettivo,
                zoneCoinvolte: zoneCoinvolte,
                titolo: titolo,
                descrizione: descrizione,
                stilePrincipale: stilePrincipale,
                livelli: livelli,
                attrezzi: attrezzi,
                metriTotali: metriTotali,
                durataStimataMin: durataStimataMin,
                note: note,
                stato: stato,
                fonte: fonte,
                importatoIl: importatoIl,
                modificatoInApp: modificatoInApp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                required String codice,
                required String sport,
                required String fase,
                required String obiettivo,
                required String zoneCoinvolte,
                required String titolo,
                required String descrizione,
                Value<String?> stilePrincipale = const Value.absent(),
                Value<String> livelli = const Value.absent(),
                Value<String?> attrezzi = const Value.absent(),
                Value<int> metriTotali = const Value.absent(),
                Value<int> durataStimataMin = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> stato = const Value.absent(),
                Value<String> fonte = const Value.absent(),
                Value<DateTime?> importatoIl = const Value.absent(),
                Value<bool> modificatoInApp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingBlocksTableCompanion.insert(
                id: id,
                clubId: clubId,
                codice: codice,
                sport: sport,
                fase: fase,
                obiettivo: obiettivo,
                zoneCoinvolte: zoneCoinvolte,
                titolo: titolo,
                descrizione: descrizione,
                stilePrincipale: stilePrincipale,
                livelli: livelli,
                attrezzi: attrezzi,
                metriTotali: metriTotali,
                durataStimataMin: durataStimataMin,
                note: note,
                stato: stato,
                fonte: fonte,
                importatoIl: importatoIl,
                modificatoInApp: modificatoInApp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TrainingBlocksTableTable,
                    TrainingBlocksTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TrainingBlocksTableTable,
                    TrainingBlocksTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainingBlocksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingBlocksTableTable,
      TrainingBlocksTableData,
      $$TrainingBlocksTableTableFilterComposer,
      $$TrainingBlocksTableTableOrderingComposer,
      $$TrainingBlocksTableTableAnnotationComposer,
      $$TrainingBlocksTableTableCreateCompanionBuilder,
      $$TrainingBlocksTableTableUpdateCompanionBuilder,
      (
        TrainingBlocksTableData,
        BaseReferences<
          _$AppDatabase,
          $TrainingBlocksTableTable,
          TrainingBlocksTableData
        >,
      ),
      TrainingBlocksTableData,
      PrefetchHooks Function()
    >;
typedef $$TrainingBlockPartiTableTableCreateCompanionBuilder =
    TrainingBlockPartiTableCompanion Function({
      required String id,
      required String bloccoId,
      required String clubId,
      Value<int> ordine,
      Value<int> giri,
      Value<int> ripetizioni,
      Value<int?> distanzaM,
      Value<int?> durataS,
      Value<String?> stile,
      Value<String?> esercizio,
      required String zona,
      required String esecuzione,
      Value<int?> recuperoS,
      Value<String?> attrezzi,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$TrainingBlockPartiTableTableUpdateCompanionBuilder =
    TrainingBlockPartiTableCompanion Function({
      Value<String> id,
      Value<String> bloccoId,
      Value<String> clubId,
      Value<int> ordine,
      Value<int> giri,
      Value<int> ripetizioni,
      Value<int?> distanzaM,
      Value<int?> durataS,
      Value<String?> stile,
      Value<String?> esercizio,
      Value<String> zona,
      Value<String> esecuzione,
      Value<int?> recuperoS,
      Value<String?> attrezzi,
      Value<String?> note,
      Value<int> rowid,
    });

class $$TrainingBlockPartiTableTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingBlockPartiTableTable> {
  $$TrainingBlockPartiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloccoId => $composableBuilder(
    column: $table.bloccoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get giri => $composableBuilder(
    column: $table.giri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ripetizioni => $composableBuilder(
    column: $table.ripetizioni,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durataS => $composableBuilder(
    column: $table.durataS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esercizio => $composableBuilder(
    column: $table.esercizio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recuperoS => $composableBuilder(
    column: $table.recuperoS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attrezzi => $composableBuilder(
    column: $table.attrezzi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrainingBlockPartiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingBlockPartiTableTable> {
  $$TrainingBlockPartiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloccoId => $composableBuilder(
    column: $table.bloccoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get giri => $composableBuilder(
    column: $table.giri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ripetizioni => $composableBuilder(
    column: $table.ripetizioni,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanzaM => $composableBuilder(
    column: $table.distanzaM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durataS => $composableBuilder(
    column: $table.durataS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stile => $composableBuilder(
    column: $table.stile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esercizio => $composableBuilder(
    column: $table.esercizio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recuperoS => $composableBuilder(
    column: $table.recuperoS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attrezzi => $composableBuilder(
    column: $table.attrezzi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrainingBlockPartiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingBlockPartiTableTable> {
  $$TrainingBlockPartiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bloccoId =>
      $composableBuilder(column: $table.bloccoId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  GeneratedColumn<int> get giri =>
      $composableBuilder(column: $table.giri, builder: (column) => column);

  GeneratedColumn<int> get ripetizioni => $composableBuilder(
    column: $table.ripetizioni,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanzaM =>
      $composableBuilder(column: $table.distanzaM, builder: (column) => column);

  GeneratedColumn<int> get durataS =>
      $composableBuilder(column: $table.durataS, builder: (column) => column);

  GeneratedColumn<String> get stile =>
      $composableBuilder(column: $table.stile, builder: (column) => column);

  GeneratedColumn<String> get esercizio =>
      $composableBuilder(column: $table.esercizio, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<String> get esecuzione => $composableBuilder(
    column: $table.esecuzione,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recuperoS =>
      $composableBuilder(column: $table.recuperoS, builder: (column) => column);

  GeneratedColumn<String> get attrezzi =>
      $composableBuilder(column: $table.attrezzi, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TrainingBlockPartiTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrainingBlockPartiTableTable,
          TrainingBlockPartiTableData,
          $$TrainingBlockPartiTableTableFilterComposer,
          $$TrainingBlockPartiTableTableOrderingComposer,
          $$TrainingBlockPartiTableTableAnnotationComposer,
          $$TrainingBlockPartiTableTableCreateCompanionBuilder,
          $$TrainingBlockPartiTableTableUpdateCompanionBuilder,
          (
            TrainingBlockPartiTableData,
            BaseReferences<
              _$AppDatabase,
              $TrainingBlockPartiTableTable,
              TrainingBlockPartiTableData
            >,
          ),
          TrainingBlockPartiTableData,
          PrefetchHooks Function()
        > {
  $$TrainingBlockPartiTableTableTableManager(
    _$AppDatabase db,
    $TrainingBlockPartiTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingBlockPartiTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TrainingBlockPartiTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrainingBlockPartiTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bloccoId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> giri = const Value.absent(),
                Value<int> ripetizioni = const Value.absent(),
                Value<int?> distanzaM = const Value.absent(),
                Value<int?> durataS = const Value.absent(),
                Value<String?> stile = const Value.absent(),
                Value<String?> esercizio = const Value.absent(),
                Value<String> zona = const Value.absent(),
                Value<String> esecuzione = const Value.absent(),
                Value<int?> recuperoS = const Value.absent(),
                Value<String?> attrezzi = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingBlockPartiTableCompanion(
                id: id,
                bloccoId: bloccoId,
                clubId: clubId,
                ordine: ordine,
                giri: giri,
                ripetizioni: ripetizioni,
                distanzaM: distanzaM,
                durataS: durataS,
                stile: stile,
                esercizio: esercizio,
                zona: zona,
                esecuzione: esecuzione,
                recuperoS: recuperoS,
                attrezzi: attrezzi,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bloccoId,
                required String clubId,
                Value<int> ordine = const Value.absent(),
                Value<int> giri = const Value.absent(),
                Value<int> ripetizioni = const Value.absent(),
                Value<int?> distanzaM = const Value.absent(),
                Value<int?> durataS = const Value.absent(),
                Value<String?> stile = const Value.absent(),
                Value<String?> esercizio = const Value.absent(),
                required String zona,
                required String esecuzione,
                Value<int?> recuperoS = const Value.absent(),
                Value<String?> attrezzi = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrainingBlockPartiTableCompanion.insert(
                id: id,
                bloccoId: bloccoId,
                clubId: clubId,
                ordine: ordine,
                giri: giri,
                ripetizioni: ripetizioni,
                distanzaM: distanzaM,
                durataS: durataS,
                stile: stile,
                esercizio: esercizio,
                zona: zona,
                esecuzione: esecuzione,
                recuperoS: recuperoS,
                attrezzi: attrezzi,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TrainingBlockPartiTableTable,
                    TrainingBlockPartiTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TrainingBlockPartiTableTable,
                    TrainingBlockPartiTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrainingBlockPartiTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrainingBlockPartiTableTable,
      TrainingBlockPartiTableData,
      $$TrainingBlockPartiTableTableFilterComposer,
      $$TrainingBlockPartiTableTableOrderingComposer,
      $$TrainingBlockPartiTableTableAnnotationComposer,
      $$TrainingBlockPartiTableTableCreateCompanionBuilder,
      $$TrainingBlockPartiTableTableUpdateCompanionBuilder,
      (
        TrainingBlockPartiTableData,
        BaseReferences<
          _$AppDatabase,
          $TrainingBlockPartiTableTable,
          TrainingBlockPartiTableData
        >,
      ),
      TrainingBlockPartiTableData,
      PrefetchHooks Function()
    >;
typedef $$SchedeBenessereTableTableCreateCompanionBuilder =
    SchedeBenessereTableCompanion Function({
      required String id,
      required String atletaId,
      required String clubId,
      required DateTime data,
      Value<String?> eventoTipo,
      Value<String?> eventoId,
      required bool dolori,
      Value<String> zoneDoloreJson,
      Value<int?> intensitaDolore,
      required double oreSonno,
      required DateTime compilataIl,
      Value<int?> qualitaSonno,
      Value<int?> energia,
      Value<int?> muscoli,
      Value<int?> stress,
      Value<int?> umore,
      Value<String> sintomiJson,
      Value<int> rowid,
    });
typedef $$SchedeBenessereTableTableUpdateCompanionBuilder =
    SchedeBenessereTableCompanion Function({
      Value<String> id,
      Value<String> atletaId,
      Value<String> clubId,
      Value<DateTime> data,
      Value<String?> eventoTipo,
      Value<String?> eventoId,
      Value<bool> dolori,
      Value<String> zoneDoloreJson,
      Value<int?> intensitaDolore,
      Value<double> oreSonno,
      Value<DateTime> compilataIl,
      Value<int?> qualitaSonno,
      Value<int?> energia,
      Value<int?> muscoli,
      Value<int?> stress,
      Value<int?> umore,
      Value<String> sintomiJson,
      Value<int> rowid,
    });

class $$SchedeBenessereTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchedeBenessereTableTable> {
  $$SchedeBenessereTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventoTipo => $composableBuilder(
    column: $table.eventoTipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventoId => $composableBuilder(
    column: $table.eventoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dolori => $composableBuilder(
    column: $table.dolori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneDoloreJson => $composableBuilder(
    column: $table.zoneDoloreJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intensitaDolore => $composableBuilder(
    column: $table.intensitaDolore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get oreSonno => $composableBuilder(
    column: $table.oreSonno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get compilataIl => $composableBuilder(
    column: $table.compilataIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qualitaSonno => $composableBuilder(
    column: $table.qualitaSonno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get muscoli => $composableBuilder(
    column: $table.muscoli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get umore => $composableBuilder(
    column: $table.umore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sintomiJson => $composableBuilder(
    column: $table.sintomiJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchedeBenessereTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedeBenessereTableTable> {
  $$SchedeBenessereTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atletaId => $composableBuilder(
    column: $table.atletaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventoTipo => $composableBuilder(
    column: $table.eventoTipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventoId => $composableBuilder(
    column: $table.eventoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dolori => $composableBuilder(
    column: $table.dolori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneDoloreJson => $composableBuilder(
    column: $table.zoneDoloreJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intensitaDolore => $composableBuilder(
    column: $table.intensitaDolore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get oreSonno => $composableBuilder(
    column: $table.oreSonno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get compilataIl => $composableBuilder(
    column: $table.compilataIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qualitaSonno => $composableBuilder(
    column: $table.qualitaSonno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get muscoli => $composableBuilder(
    column: $table.muscoli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get umore => $composableBuilder(
    column: $table.umore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sintomiJson => $composableBuilder(
    column: $table.sintomiJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchedeBenessereTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedeBenessereTableTable> {
  $$SchedeBenessereTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get atletaId =>
      $composableBuilder(column: $table.atletaId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get eventoTipo => $composableBuilder(
    column: $table.eventoTipo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventoId =>
      $composableBuilder(column: $table.eventoId, builder: (column) => column);

  GeneratedColumn<bool> get dolori =>
      $composableBuilder(column: $table.dolori, builder: (column) => column);

  GeneratedColumn<String> get zoneDoloreJson => $composableBuilder(
    column: $table.zoneDoloreJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intensitaDolore => $composableBuilder(
    column: $table.intensitaDolore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get oreSonno =>
      $composableBuilder(column: $table.oreSonno, builder: (column) => column);

  GeneratedColumn<DateTime> get compilataIl => $composableBuilder(
    column: $table.compilataIl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qualitaSonno => $composableBuilder(
    column: $table.qualitaSonno,
    builder: (column) => column,
  );

  GeneratedColumn<int> get energia =>
      $composableBuilder(column: $table.energia, builder: (column) => column);

  GeneratedColumn<int> get muscoli =>
      $composableBuilder(column: $table.muscoli, builder: (column) => column);

  GeneratedColumn<int> get stress =>
      $composableBuilder(column: $table.stress, builder: (column) => column);

  GeneratedColumn<int> get umore =>
      $composableBuilder(column: $table.umore, builder: (column) => column);

  GeneratedColumn<String> get sintomiJson => $composableBuilder(
    column: $table.sintomiJson,
    builder: (column) => column,
  );
}

class $$SchedeBenessereTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedeBenessereTableTable,
          SchedeBenessereTableData,
          $$SchedeBenessereTableTableFilterComposer,
          $$SchedeBenessereTableTableOrderingComposer,
          $$SchedeBenessereTableTableAnnotationComposer,
          $$SchedeBenessereTableTableCreateCompanionBuilder,
          $$SchedeBenessereTableTableUpdateCompanionBuilder,
          (
            SchedeBenessereTableData,
            BaseReferences<
              _$AppDatabase,
              $SchedeBenessereTableTable,
              SchedeBenessereTableData
            >,
          ),
          SchedeBenessereTableData,
          PrefetchHooks Function()
        > {
  $$SchedeBenessereTableTableTableManager(
    _$AppDatabase db,
    $SchedeBenessereTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedeBenessereTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedeBenessereTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SchedeBenessereTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> atletaId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> eventoTipo = const Value.absent(),
                Value<String?> eventoId = const Value.absent(),
                Value<bool> dolori = const Value.absent(),
                Value<String> zoneDoloreJson = const Value.absent(),
                Value<int?> intensitaDolore = const Value.absent(),
                Value<double> oreSonno = const Value.absent(),
                Value<DateTime> compilataIl = const Value.absent(),
                Value<int?> qualitaSonno = const Value.absent(),
                Value<int?> energia = const Value.absent(),
                Value<int?> muscoli = const Value.absent(),
                Value<int?> stress = const Value.absent(),
                Value<int?> umore = const Value.absent(),
                Value<String> sintomiJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedeBenessereTableCompanion(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                data: data,
                eventoTipo: eventoTipo,
                eventoId: eventoId,
                dolori: dolori,
                zoneDoloreJson: zoneDoloreJson,
                intensitaDolore: intensitaDolore,
                oreSonno: oreSonno,
                compilataIl: compilataIl,
                qualitaSonno: qualitaSonno,
                energia: energia,
                muscoli: muscoli,
                stress: stress,
                umore: umore,
                sintomiJson: sintomiJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String atletaId,
                required String clubId,
                required DateTime data,
                Value<String?> eventoTipo = const Value.absent(),
                Value<String?> eventoId = const Value.absent(),
                required bool dolori,
                Value<String> zoneDoloreJson = const Value.absent(),
                Value<int?> intensitaDolore = const Value.absent(),
                required double oreSonno,
                required DateTime compilataIl,
                Value<int?> qualitaSonno = const Value.absent(),
                Value<int?> energia = const Value.absent(),
                Value<int?> muscoli = const Value.absent(),
                Value<int?> stress = const Value.absent(),
                Value<int?> umore = const Value.absent(),
                Value<String> sintomiJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedeBenessereTableCompanion.insert(
                id: id,
                atletaId: atletaId,
                clubId: clubId,
                data: data,
                eventoTipo: eventoTipo,
                eventoId: eventoId,
                dolori: dolori,
                zoneDoloreJson: zoneDoloreJson,
                intensitaDolore: intensitaDolore,
                oreSonno: oreSonno,
                compilataIl: compilataIl,
                qualitaSonno: qualitaSonno,
                energia: energia,
                muscoli: muscoli,
                stress: stress,
                umore: umore,
                sintomiJson: sintomiJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SchedeBenessereTableTable,
                    SchedeBenessereTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SchedeBenessereTableTable,
                    SchedeBenessereTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchedeBenessereTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedeBenessereTableTable,
      SchedeBenessereTableData,
      $$SchedeBenessereTableTableFilterComposer,
      $$SchedeBenessereTableTableOrderingComposer,
      $$SchedeBenessereTableTableAnnotationComposer,
      $$SchedeBenessereTableTableCreateCompanionBuilder,
      $$SchedeBenessereTableTableUpdateCompanionBuilder,
      (
        SchedeBenessereTableData,
        BaseReferences<
          _$AppDatabase,
          $SchedeBenessereTableTable,
          SchedeBenessereTableData
        >,
      ),
      SchedeBenessereTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClubTableTableTableManager get clubTable =>
      $$ClubTableTableTableManager(_db, _db.clubTable);
  $$AtletiTableTableTableManager get atletiTable =>
      $$AtletiTableTableTableManager(_db, _db.atletiTable);
  $$PersonalBestTableTableTableManager get personalBestTable =>
      $$PersonalBestTableTableTableManager(_db, _db.personalBestTable);
  $$TempiGaraTableTableTableManager get tempiGaraTable =>
      $$TempiGaraTableTableTableManager(_db, _db.tempiGaraTable);
  $$SchemiTatticiTableTableTableManager get schemiTatticiTable =>
      $$SchemiTatticiTableTableTableManager(_db, _db.schemiTatticiTable);
  $$TestIngressoTableTableTableManager get testIngressoTable =>
      $$TestIngressoTableTableTableManager(_db, _db.testIngressoTable);
  $$TabellePassiTableTableTableManager get tabellePassiTable =>
      $$TabellePassiTableTableTableManager(_db, _db.tabellePassiTable);
  $$StagioniTableTableTableManager get stagioniTable =>
      $$StagioniTableTableTableManager(_db, _db.stagioniTable);
  $$AllenamentiTableTableTableManager get allenamentiTable =>
      $$AllenamentiTableTableTableManager(_db, _db.allenamentiTable);
  $$SerieTableTableTableManager get serieTable =>
      $$SerieTableTableTableManager(_db, _db.serieTable);
  $$PresenzeTableTableTableManager get presenzeTable =>
      $$PresenzeTableTableTableManager(_db, _db.presenzeTable);
  $$PendingOperationsTableTableTableManager get pendingOperationsTable =>
      $$PendingOperationsTableTableTableManager(
        _db,
        _db.pendingOperationsTable,
      );
  $$PartiteTableTableTableManager get partiteTable =>
      $$PartiteTableTableTableManager(_db, _db.partiteTable);
  $$DistintaGiocatoriTableTableTableManager get distintaGiocatoriTable =>
      $$DistintaGiocatoriTableTableTableManager(
        _db,
        _db.distintaGiocatoriTable,
      );
  $$EventiPartitaTableTableTableManager get eventiPartitaTable =>
      $$EventiPartitaTableTableTableManager(_db, _db.eventiPartitaTable);
  $$RefertiPartitaTableTableTableManager get refertiPartitaTable =>
      $$RefertiPartitaTableTableTableManager(_db, _db.refertiPartitaTable);
  $$GruppiTableTableTableManager get gruppiTable =>
      $$GruppiTableTableTableManager(_db, _db.gruppiTable);
  $$GareTableTableTableManager get gareTable =>
      $$GareTableTableTableManager(_db, _db.gareTable);
  $$GaraIscrittiTableTableTableManager get garaIscrittiTable =>
      $$GaraIscrittiTableTableTableManager(_db, _db.garaIscrittiTable);
  $$TrainingBlocksTableTableTableManager get trainingBlocksTable =>
      $$TrainingBlocksTableTableTableManager(_db, _db.trainingBlocksTable);
  $$TrainingBlockPartiTableTableTableManager get trainingBlockPartiTable =>
      $$TrainingBlockPartiTableTableTableManager(
        _db,
        _db.trainingBlockPartiTable,
      );
  $$SchedeBenessereTableTableTableManager get schedeBenessereTable =>
      $$SchedeBenessereTableTableTableManager(_db, _db.schedeBenessereTable);
}
