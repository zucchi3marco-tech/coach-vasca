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
  @override
  List<GeneratedColumn> get $columns => [id, nome, citta];
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
  const ClubTableData({required this.id, required this.nome, this.citta});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || citta != null) {
      map['citta'] = Variable<String>(citta);
    }
    return map;
  }

  ClubTableCompanion toCompanion(bool nullToAbsent) {
    return ClubTableCompanion(
      id: Value(id),
      nome: Value(nome),
      citta: citta == null && nullToAbsent
          ? const Value.absent()
          : Value(citta),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'citta': serializer.toJson<String?>(citta),
    };
  }

  ClubTableData copyWith({
    String? id,
    String? nome,
    Value<String?> citta = const Value.absent(),
  }) => ClubTableData(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    citta: citta.present ? citta.value : this.citta,
  );
  ClubTableData copyWithCompanion(ClubTableCompanion data) {
    return ClubTableData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      citta: data.citta.present ? data.citta.value : this.citta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClubTableData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('citta: $citta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, citta);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClubTableData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.citta == this.citta);
}

class ClubTableCompanion extends UpdateCompanion<ClubTableData> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String?> citta;
  final Value<int> rowid;
  const ClubTableCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.citta = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClubTableCompanion.insert({
    required String id,
    required String nome,
    this.citta = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome);
  static Insertable<ClubTableData> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? citta,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (citta != null) 'citta': citta,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClubTableCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String?>? citta,
    Value<int>? rowid,
  }) {
    return ClubTableCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      citta: citta ?? this.citta,
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
  static const VerificationMeta _gruppoMeta = const VerificationMeta('gruppo');
  @override
  late final GeneratedColumn<String> gruppo = GeneratedColumn<String>(
    'gruppo',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clubId,
    nome,
    cognome,
    dataNascita,
    sesso,
    sport,
    gruppo,
    emailGenitore,
    telefonoGenitore,
    consensoPrivacyFirmato,
    consensoPrivacyData,
    note,
    attivo,
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
    if (data.containsKey('gruppo')) {
      context.handle(
        _gruppoMeta,
        gruppo.isAcceptableOrUnknown(data['gruppo']!, _gruppoMeta),
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
      gruppo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo'],
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
  final String? gruppo;
  final String? emailGenitore;
  final String? telefonoGenitore;
  final bool consensoPrivacyFirmato;
  final DateTime? consensoPrivacyData;
  final String? note;
  final bool attivo;
  const AtletiTableData({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.cognome,
    required this.dataNascita,
    this.sesso,
    required this.sport,
    this.gruppo,
    this.emailGenitore,
    this.telefonoGenitore,
    required this.consensoPrivacyFirmato,
    this.consensoPrivacyData,
    this.note,
    required this.attivo,
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
    if (!nullToAbsent || gruppo != null) {
      map['gruppo'] = Variable<String>(gruppo);
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
      gruppo: gruppo == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppo),
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
      gruppo: serializer.fromJson<String?>(json['gruppo']),
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
      'gruppo': serializer.toJson<String?>(gruppo),
      'emailGenitore': serializer.toJson<String?>(emailGenitore),
      'telefonoGenitore': serializer.toJson<String?>(telefonoGenitore),
      'consensoPrivacyFirmato': serializer.toJson<bool>(consensoPrivacyFirmato),
      'consensoPrivacyData': serializer.toJson<DateTime?>(consensoPrivacyData),
      'note': serializer.toJson<String?>(note),
      'attivo': serializer.toJson<bool>(attivo),
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
    Value<String?> gruppo = const Value.absent(),
    Value<String?> emailGenitore = const Value.absent(),
    Value<String?> telefonoGenitore = const Value.absent(),
    bool? consensoPrivacyFirmato,
    Value<DateTime?> consensoPrivacyData = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? attivo,
  }) => AtletiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    nome: nome ?? this.nome,
    cognome: cognome ?? this.cognome,
    dataNascita: dataNascita ?? this.dataNascita,
    sesso: sesso.present ? sesso.value : this.sesso,
    sport: sport ?? this.sport,
    gruppo: gruppo.present ? gruppo.value : this.gruppo,
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
      gruppo: data.gruppo.present ? data.gruppo.value : this.gruppo,
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
          ..write('gruppo: $gruppo, ')
          ..write('emailGenitore: $emailGenitore, ')
          ..write('telefonoGenitore: $telefonoGenitore, ')
          ..write('consensoPrivacyFirmato: $consensoPrivacyFirmato, ')
          ..write('consensoPrivacyData: $consensoPrivacyData, ')
          ..write('note: $note, ')
          ..write('attivo: $attivo')
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
    gruppo,
    emailGenitore,
    telefonoGenitore,
    consensoPrivacyFirmato,
    consensoPrivacyData,
    note,
    attivo,
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
          other.gruppo == this.gruppo &&
          other.emailGenitore == this.emailGenitore &&
          other.telefonoGenitore == this.telefonoGenitore &&
          other.consensoPrivacyFirmato == this.consensoPrivacyFirmato &&
          other.consensoPrivacyData == this.consensoPrivacyData &&
          other.note == this.note &&
          other.attivo == this.attivo);
}

class AtletiTableCompanion extends UpdateCompanion<AtletiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String> nome;
  final Value<String> cognome;
  final Value<DateTime> dataNascita;
  final Value<String?> sesso;
  final Value<String> sport;
  final Value<String?> gruppo;
  final Value<String?> emailGenitore;
  final Value<String?> telefonoGenitore;
  final Value<bool> consensoPrivacyFirmato;
  final Value<DateTime?> consensoPrivacyData;
  final Value<String?> note;
  final Value<bool> attivo;
  final Value<int> rowid;
  const AtletiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.nome = const Value.absent(),
    this.cognome = const Value.absent(),
    this.dataNascita = const Value.absent(),
    this.sesso = const Value.absent(),
    this.sport = const Value.absent(),
    this.gruppo = const Value.absent(),
    this.emailGenitore = const Value.absent(),
    this.telefonoGenitore = const Value.absent(),
    this.consensoPrivacyFirmato = const Value.absent(),
    this.consensoPrivacyData = const Value.absent(),
    this.note = const Value.absent(),
    this.attivo = const Value.absent(),
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
    this.gruppo = const Value.absent(),
    this.emailGenitore = const Value.absent(),
    this.telefonoGenitore = const Value.absent(),
    this.consensoPrivacyFirmato = const Value.absent(),
    this.consensoPrivacyData = const Value.absent(),
    this.note = const Value.absent(),
    this.attivo = const Value.absent(),
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
    Expression<String>? gruppo,
    Expression<String>? emailGenitore,
    Expression<String>? telefonoGenitore,
    Expression<bool>? consensoPrivacyFirmato,
    Expression<DateTime>? consensoPrivacyData,
    Expression<String>? note,
    Expression<bool>? attivo,
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
      if (gruppo != null) 'gruppo': gruppo,
      if (emailGenitore != null) 'email_genitore': emailGenitore,
      if (telefonoGenitore != null) 'telefono_genitore': telefonoGenitore,
      if (consensoPrivacyFirmato != null)
        'consenso_privacy_firmato': consensoPrivacyFirmato,
      if (consensoPrivacyData != null)
        'consenso_privacy_data': consensoPrivacyData,
      if (note != null) 'note': note,
      if (attivo != null) 'attivo': attivo,
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
    Value<String?>? gruppo,
    Value<String?>? emailGenitore,
    Value<String?>? telefonoGenitore,
    Value<bool>? consensoPrivacyFirmato,
    Value<DateTime?>? consensoPrivacyData,
    Value<String?>? note,
    Value<bool>? attivo,
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
      gruppo: gruppo ?? this.gruppo,
      emailGenitore: emailGenitore ?? this.emailGenitore,
      telefonoGenitore: telefonoGenitore ?? this.telefonoGenitore,
      consensoPrivacyFirmato:
          consensoPrivacyFirmato ?? this.consensoPrivacyFirmato,
      consensoPrivacyData: consensoPrivacyData ?? this.consensoPrivacyData,
      note: note ?? this.note,
      attivo: attivo ?? this.attivo,
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
    if (gruppo.present) {
      map['gruppo'] = Variable<String>(gruppo.value);
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
          ..write('gruppo: $gruppo, ')
          ..write('emailGenitore: $emailGenitore, ')
          ..write('telefonoGenitore: $telefonoGenitore, ')
          ..write('consensoPrivacyFirmato: $consensoPrivacyFirmato, ')
          ..write('consensoPrivacyData: $consensoPrivacyData, ')
          ..write('note: $note, ')
          ..write('attivo: $attivo, ')
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
  static const VerificationMeta _microcicloIdMeta = const VerificationMeta(
    'microcicloId',
  );
  @override
  late final GeneratedColumn<String> microcicloId = GeneratedColumn<String>(
    'microciclo_id',
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
  static const VerificationMeta _titoloMeta = const VerificationMeta('titolo');
  @override
  late final GeneratedColumn<String> titolo = GeneratedColumn<String>(
    'titolo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gruppoMeta = const VerificationMeta('gruppo');
  @override
  late final GeneratedColumn<String> gruppo = GeneratedColumn<String>(
    'gruppo',
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
    microcicloId,
    data,
    titolo,
    gruppo,
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
    if (data.containsKey('microciclo_id')) {
      context.handle(
        _microcicloIdMeta,
        microcicloId.isAcceptableOrUnknown(
          data['microciclo_id']!,
          _microcicloIdMeta,
        ),
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
    if (data.containsKey('titolo')) {
      context.handle(
        _titoloMeta,
        titolo.isAcceptableOrUnknown(data['titolo']!, _titoloMeta),
      );
    }
    if (data.containsKey('gruppo')) {
      context.handle(
        _gruppoMeta,
        gruppo.isAcceptableOrUnknown(data['gruppo']!, _gruppoMeta),
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
      microcicloId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}microciclo_id'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      titolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titolo'],
      ),
      gruppo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gruppo'],
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
  final String? microcicloId;
  final DateTime data;
  final String? titolo;
  final String? gruppo;
  final String? note;
  const AllenamentiTableData({
    required this.id,
    required this.clubId,
    this.microcicloId,
    required this.data,
    this.titolo,
    this.gruppo,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['club_id'] = Variable<String>(clubId);
    if (!nullToAbsent || microcicloId != null) {
      map['microciclo_id'] = Variable<String>(microcicloId);
    }
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || titolo != null) {
      map['titolo'] = Variable<String>(titolo);
    }
    if (!nullToAbsent || gruppo != null) {
      map['gruppo'] = Variable<String>(gruppo);
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
      microcicloId: microcicloId == null && nullToAbsent
          ? const Value.absent()
          : Value(microcicloId),
      data: Value(data),
      titolo: titolo == null && nullToAbsent
          ? const Value.absent()
          : Value(titolo),
      gruppo: gruppo == null && nullToAbsent
          ? const Value.absent()
          : Value(gruppo),
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
      microcicloId: serializer.fromJson<String?>(json['microcicloId']),
      data: serializer.fromJson<DateTime>(json['data']),
      titolo: serializer.fromJson<String?>(json['titolo']),
      gruppo: serializer.fromJson<String?>(json['gruppo']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clubId': serializer.toJson<String>(clubId),
      'microcicloId': serializer.toJson<String?>(microcicloId),
      'data': serializer.toJson<DateTime>(data),
      'titolo': serializer.toJson<String?>(titolo),
      'gruppo': serializer.toJson<String?>(gruppo),
      'note': serializer.toJson<String?>(note),
    };
  }

  AllenamentiTableData copyWith({
    String? id,
    String? clubId,
    Value<String?> microcicloId = const Value.absent(),
    DateTime? data,
    Value<String?> titolo = const Value.absent(),
    Value<String?> gruppo = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => AllenamentiTableData(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    microcicloId: microcicloId.present ? microcicloId.value : this.microcicloId,
    data: data ?? this.data,
    titolo: titolo.present ? titolo.value : this.titolo,
    gruppo: gruppo.present ? gruppo.value : this.gruppo,
    note: note.present ? note.value : this.note,
  );
  AllenamentiTableData copyWithCompanion(AllenamentiTableCompanion data) {
    return AllenamentiTableData(
      id: data.id.present ? data.id.value : this.id,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      microcicloId: data.microcicloId.present
          ? data.microcicloId.value
          : this.microcicloId,
      data: data.data.present ? data.data.value : this.data,
      titolo: data.titolo.present ? data.titolo.value : this.titolo,
      gruppo: data.gruppo.present ? data.gruppo.value : this.gruppo,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllenamentiTableData(')
          ..write('id: $id, ')
          ..write('clubId: $clubId, ')
          ..write('microcicloId: $microcicloId, ')
          ..write('data: $data, ')
          ..write('titolo: $titolo, ')
          ..write('gruppo: $gruppo, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clubId, microcicloId, data, titolo, gruppo, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllenamentiTableData &&
          other.id == this.id &&
          other.clubId == this.clubId &&
          other.microcicloId == this.microcicloId &&
          other.data == this.data &&
          other.titolo == this.titolo &&
          other.gruppo == this.gruppo &&
          other.note == this.note);
}

class AllenamentiTableCompanion extends UpdateCompanion<AllenamentiTableData> {
  final Value<String> id;
  final Value<String> clubId;
  final Value<String?> microcicloId;
  final Value<DateTime> data;
  final Value<String?> titolo;
  final Value<String?> gruppo;
  final Value<String?> note;
  final Value<int> rowid;
  const AllenamentiTableCompanion({
    this.id = const Value.absent(),
    this.clubId = const Value.absent(),
    this.microcicloId = const Value.absent(),
    this.data = const Value.absent(),
    this.titolo = const Value.absent(),
    this.gruppo = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllenamentiTableCompanion.insert({
    required String id,
    required String clubId,
    this.microcicloId = const Value.absent(),
    required DateTime data,
    this.titolo = const Value.absent(),
    this.gruppo = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clubId = Value(clubId),
       data = Value(data);
  static Insertable<AllenamentiTableData> custom({
    Expression<String>? id,
    Expression<String>? clubId,
    Expression<String>? microcicloId,
    Expression<DateTime>? data,
    Expression<String>? titolo,
    Expression<String>? gruppo,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clubId != null) 'club_id': clubId,
      if (microcicloId != null) 'microciclo_id': microcicloId,
      if (data != null) 'data': data,
      if (titolo != null) 'titolo': titolo,
      if (gruppo != null) 'gruppo': gruppo,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllenamentiTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clubId,
    Value<String?>? microcicloId,
    Value<DateTime>? data,
    Value<String?>? titolo,
    Value<String?>? gruppo,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return AllenamentiTableCompanion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      microcicloId: microcicloId ?? this.microcicloId,
      data: data ?? this.data,
      titolo: titolo ?? this.titolo,
      gruppo: gruppo ?? this.gruppo,
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
    if (microcicloId.present) {
      map['microciclo_id'] = Variable<String>(microcicloId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (titolo.present) {
      map['titolo'] = Variable<String>(titolo.value);
    }
    if (gruppo.present) {
      map['gruppo'] = Variable<String>(gruppo.value);
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
          ..write('microcicloId: $microcicloId, ')
          ..write('data: $data, ')
          ..write('titolo: $titolo, ')
          ..write('gruppo: $gruppo, ')
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
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    allenamentoId,
    clubId,
    ordine,
    blocco,
    ripetute,
    distanzaM,
    stile,
    esecuzione,
    zona,
    passoObiettivoS,
    recuperoS,
    ripartenzaS,
    attrezzatura,
    note,
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
    } else if (isInserting) {
      context.missing(_distanzaMMeta);
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
      )!,
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
  final int distanzaM;
  final String stile;
  final String esecuzione;
  final String? zona;
  final double? passoObiettivoS;
  final int? recuperoS;
  final double? ripartenzaS;
  final String? attrezzatura;
  final String? note;
  const SerieTableData({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.ordine,
    required this.blocco,
    required this.ripetute,
    required this.distanzaM,
    required this.stile,
    required this.esecuzione,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
    this.ripartenzaS,
    this.attrezzatura,
    this.note,
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
    map['distanza_m'] = Variable<int>(distanzaM);
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
      distanzaM: Value(distanzaM),
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
      distanzaM: serializer.fromJson<int>(json['distanzaM']),
      stile: serializer.fromJson<String>(json['stile']),
      esecuzione: serializer.fromJson<String>(json['esecuzione']),
      zona: serializer.fromJson<String?>(json['zona']),
      passoObiettivoS: serializer.fromJson<double?>(json['passoObiettivoS']),
      recuperoS: serializer.fromJson<int?>(json['recuperoS']),
      ripartenzaS: serializer.fromJson<double?>(json['ripartenzaS']),
      attrezzatura: serializer.fromJson<String?>(json['attrezzatura']),
      note: serializer.fromJson<String?>(json['note']),
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
      'distanzaM': serializer.toJson<int>(distanzaM),
      'stile': serializer.toJson<String>(stile),
      'esecuzione': serializer.toJson<String>(esecuzione),
      'zona': serializer.toJson<String?>(zona),
      'passoObiettivoS': serializer.toJson<double?>(passoObiettivoS),
      'recuperoS': serializer.toJson<int?>(recuperoS),
      'ripartenzaS': serializer.toJson<double?>(ripartenzaS),
      'attrezzatura': serializer.toJson<String?>(attrezzatura),
      'note': serializer.toJson<String?>(note),
    };
  }

  SerieTableData copyWith({
    String? id,
    String? allenamentoId,
    String? clubId,
    int? ordine,
    String? blocco,
    int? ripetute,
    int? distanzaM,
    String? stile,
    String? esecuzione,
    Value<String?> zona = const Value.absent(),
    Value<double?> passoObiettivoS = const Value.absent(),
    Value<int?> recuperoS = const Value.absent(),
    Value<double?> ripartenzaS = const Value.absent(),
    Value<String?> attrezzatura = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => SerieTableData(
    id: id ?? this.id,
    allenamentoId: allenamentoId ?? this.allenamentoId,
    clubId: clubId ?? this.clubId,
    ordine: ordine ?? this.ordine,
    blocco: blocco ?? this.blocco,
    ripetute: ripetute ?? this.ripetute,
    distanzaM: distanzaM ?? this.distanzaM,
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
          ..write('stile: $stile, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('zona: $zona, ')
          ..write('passoObiettivoS: $passoObiettivoS, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('ripartenzaS: $ripartenzaS, ')
          ..write('attrezzatura: $attrezzatura, ')
          ..write('note: $note')
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
    stile,
    esecuzione,
    zona,
    passoObiettivoS,
    recuperoS,
    ripartenzaS,
    attrezzatura,
    note,
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
          other.stile == this.stile &&
          other.esecuzione == this.esecuzione &&
          other.zona == this.zona &&
          other.passoObiettivoS == this.passoObiettivoS &&
          other.recuperoS == this.recuperoS &&
          other.ripartenzaS == this.ripartenzaS &&
          other.attrezzatura == this.attrezzatura &&
          other.note == this.note);
}

class SerieTableCompanion extends UpdateCompanion<SerieTableData> {
  final Value<String> id;
  final Value<String> allenamentoId;
  final Value<String> clubId;
  final Value<int> ordine;
  final Value<String> blocco;
  final Value<int> ripetute;
  final Value<int> distanzaM;
  final Value<String> stile;
  final Value<String> esecuzione;
  final Value<String?> zona;
  final Value<double?> passoObiettivoS;
  final Value<int?> recuperoS;
  final Value<double?> ripartenzaS;
  final Value<String?> attrezzatura;
  final Value<String?> note;
  final Value<int> rowid;
  const SerieTableCompanion({
    this.id = const Value.absent(),
    this.allenamentoId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.ordine = const Value.absent(),
    this.blocco = const Value.absent(),
    this.ripetute = const Value.absent(),
    this.distanzaM = const Value.absent(),
    this.stile = const Value.absent(),
    this.esecuzione = const Value.absent(),
    this.zona = const Value.absent(),
    this.passoObiettivoS = const Value.absent(),
    this.recuperoS = const Value.absent(),
    this.ripartenzaS = const Value.absent(),
    this.attrezzatura = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SerieTableCompanion.insert({
    required String id,
    required String allenamentoId,
    required String clubId,
    required int ordine,
    required String blocco,
    required int ripetute,
    required int distanzaM,
    required String stile,
    required String esecuzione,
    this.zona = const Value.absent(),
    this.passoObiettivoS = const Value.absent(),
    this.recuperoS = const Value.absent(),
    this.ripartenzaS = const Value.absent(),
    this.attrezzatura = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       allenamentoId = Value(allenamentoId),
       clubId = Value(clubId),
       ordine = Value(ordine),
       blocco = Value(blocco),
       ripetute = Value(ripetute),
       distanzaM = Value(distanzaM),
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
    Expression<String>? stile,
    Expression<String>? esecuzione,
    Expression<String>? zona,
    Expression<double>? passoObiettivoS,
    Expression<int>? recuperoS,
    Expression<double>? ripartenzaS,
    Expression<String>? attrezzatura,
    Expression<String>? note,
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
      if (stile != null) 'stile': stile,
      if (esecuzione != null) 'esecuzione': esecuzione,
      if (zona != null) 'zona': zona,
      if (passoObiettivoS != null) 'passo_obiettivo_s': passoObiettivoS,
      if (recuperoS != null) 'recupero_s': recuperoS,
      if (ripartenzaS != null) 'ripartenza_s': ripartenzaS,
      if (attrezzatura != null) 'attrezzatura': attrezzatura,
      if (note != null) 'note': note,
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
    Value<int>? distanzaM,
    Value<String>? stile,
    Value<String>? esecuzione,
    Value<String?>? zona,
    Value<double?>? passoObiettivoS,
    Value<int?>? recuperoS,
    Value<double?>? ripartenzaS,
    Value<String?>? attrezzatura,
    Value<String?>? note,
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
      stile: stile ?? this.stile,
      esecuzione: esecuzione ?? this.esecuzione,
      zona: zona ?? this.zona,
      passoObiettivoS: passoObiettivoS ?? this.passoObiettivoS,
      recuperoS: recuperoS ?? this.recuperoS,
      ripartenzaS: ripartenzaS ?? this.ripartenzaS,
      attrezzatura: attrezzatura ?? this.attrezzatura,
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
          ..write('stile: $stile, ')
          ..write('esecuzione: $esecuzione, ')
          ..write('zona: $zona, ')
          ..write('passoObiettivoS: $passoObiettivoS, ')
          ..write('recuperoS: $recuperoS, ')
          ..write('ripartenzaS: $ripartenzaS, ')
          ..write('attrezzatura: $attrezzatura, ')
          ..write('note: $note, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClubTableTable clubTable = $ClubTableTable(this);
  late final $AtletiTableTable atletiTable = $AtletiTableTable(this);
  late final $TestIngressoTableTable testIngressoTable =
      $TestIngressoTableTable(this);
  late final $TabellePassiTableTable tabellePassiTable =
      $TabellePassiTableTable(this);
  late final $AllenamentiTableTable allenamentiTable = $AllenamentiTableTable(
    this,
  );
  late final $SerieTableTable serieTable = $SerieTableTable(this);
  late final $PresenzeTableTable presenzeTable = $PresenzeTableTable(this);
  late final $PendingOperationsTableTable pendingOperationsTable =
      $PendingOperationsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clubTable,
    atletiTable,
    testIngressoTable,
    tabellePassiTable,
    allenamentiTable,
    serieTable,
    presenzeTable,
    pendingOperationsTable,
  ];
}

typedef $$ClubTableTableCreateCompanionBuilder = ClubTableCompanion Function({
  required String id,
  required String nome,
  Value<String?> citta,
  Value<int> rowid,
});
typedef $$ClubTableTableUpdateCompanionBuilder = ClubTableCompanion Function({
  Value<String> id,
  Value<String> nome,
  Value<String?> citta,
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
                Value<int> rowid = const Value.absent(),
              }) => ClubTableCompanion(
                id: id,
                nome: nome,
                citta: citta,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                Value<String?> citta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClubTableCompanion.insert(
                id: id,
                nome: nome,
                citta: citta,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
      Value<String?> gruppo,
      Value<String?> emailGenitore,
      Value<String?> telefonoGenitore,
      Value<bool> consensoPrivacyFirmato,
      Value<DateTime?> consensoPrivacyData,
      Value<String?> note,
      Value<bool> attivo,
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
      Value<String?> gruppo,
      Value<String?> emailGenitore,
      Value<String?> telefonoGenitore,
      Value<bool> consensoPrivacyFirmato,
      Value<DateTime?> consensoPrivacyData,
      Value<String?> note,
      Value<bool> attivo,
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

  ColumnFilters<String> get gruppo => $composableBuilder(
    column: $table.gruppo,
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

  ColumnOrderings<String> get gruppo => $composableBuilder(
    column: $table.gruppo,
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

  GeneratedColumn<String> get gruppo =>
      $composableBuilder(column: $table.gruppo, builder: (column) => column);

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
                Value<String?> gruppo = const Value.absent(),
                Value<String?> emailGenitore = const Value.absent(),
                Value<String?> telefonoGenitore = const Value.absent(),
                Value<bool> consensoPrivacyFirmato = const Value.absent(),
                Value<DateTime?> consensoPrivacyData = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> attivo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtletiTableCompanion(
                id: id,
                clubId: clubId,
                nome: nome,
                cognome: cognome,
                dataNascita: dataNascita,
                sesso: sesso,
                sport: sport,
                gruppo: gruppo,
                emailGenitore: emailGenitore,
                telefonoGenitore: telefonoGenitore,
                consensoPrivacyFirmato: consensoPrivacyFirmato,
                consensoPrivacyData: consensoPrivacyData,
                note: note,
                attivo: attivo,
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
                Value<String?> gruppo = const Value.absent(),
                Value<String?> emailGenitore = const Value.absent(),
                Value<String?> telefonoGenitore = const Value.absent(),
                Value<bool> consensoPrivacyFirmato = const Value.absent(),
                Value<DateTime?> consensoPrivacyData = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> attivo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtletiTableCompanion.insert(
                id: id,
                clubId: clubId,
                nome: nome,
                cognome: cognome,
                dataNascita: dataNascita,
                sesso: sesso,
                sport: sport,
                gruppo: gruppo,
                emailGenitore: emailGenitore,
                telefonoGenitore: telefonoGenitore,
                consensoPrivacyFirmato: consensoPrivacyFirmato,
                consensoPrivacyData: consensoPrivacyData,
                note: note,
                attivo: attivo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
typedef $$AllenamentiTableTableCreateCompanionBuilder =
    AllenamentiTableCompanion Function({
      required String id,
      required String clubId,
      Value<String?> microcicloId,
      required DateTime data,
      Value<String?> titolo,
      Value<String?> gruppo,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$AllenamentiTableTableUpdateCompanionBuilder =
    AllenamentiTableCompanion Function({
      Value<String> id,
      Value<String> clubId,
      Value<String?> microcicloId,
      Value<DateTime> data,
      Value<String?> titolo,
      Value<String?> gruppo,
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

  ColumnFilters<String> get microcicloId => $composableBuilder(
    column: $table.microcicloId,
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

  ColumnFilters<String> get gruppo => $composableBuilder(
    column: $table.gruppo,
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

  ColumnOrderings<String> get microcicloId => $composableBuilder(
    column: $table.microcicloId,
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

  ColumnOrderings<String> get gruppo => $composableBuilder(
    column: $table.gruppo,
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

  GeneratedColumn<String> get microcicloId => $composableBuilder(
    column: $table.microcicloId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get titolo =>
      $composableBuilder(column: $table.titolo, builder: (column) => column);

  GeneratedColumn<String> get gruppo =>
      $composableBuilder(column: $table.gruppo, builder: (column) => column);

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
                Value<String?> microcicloId = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<String?> titolo = const Value.absent(),
                Value<String?> gruppo = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllenamentiTableCompanion(
                id: id,
                clubId: clubId,
                microcicloId: microcicloId,
                data: data,
                titolo: titolo,
                gruppo: gruppo,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clubId,
                Value<String?> microcicloId = const Value.absent(),
                required DateTime data,
                Value<String?> titolo = const Value.absent(),
                Value<String?> gruppo = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllenamentiTableCompanion.insert(
                id: id,
                clubId: clubId,
                microcicloId: microcicloId,
                data: data,
                titolo: titolo,
                gruppo: gruppo,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
  required int distanzaM,
  required String stile,
  required String esecuzione,
  Value<String?> zona,
  Value<double?> passoObiettivoS,
  Value<int?> recuperoS,
  Value<double?> ripartenzaS,
  Value<String?> attrezzatura,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$SerieTableTableUpdateCompanionBuilder = SerieTableCompanion Function({
  Value<String> id,
  Value<String> allenamentoId,
  Value<String> clubId,
  Value<int> ordine,
  Value<String> blocco,
  Value<int> ripetute,
  Value<int> distanzaM,
  Value<String> stile,
  Value<String> esecuzione,
  Value<String?> zona,
  Value<double?> passoObiettivoS,
  Value<int?> recuperoS,
  Value<double?> ripartenzaS,
  Value<String?> attrezzatura,
  Value<String?> note,
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
                Value<int> distanzaM = const Value.absent(),
                Value<String> stile = const Value.absent(),
                Value<String> esecuzione = const Value.absent(),
                Value<String?> zona = const Value.absent(),
                Value<double?> passoObiettivoS = const Value.absent(),
                Value<int?> recuperoS = const Value.absent(),
                Value<double?> ripartenzaS = const Value.absent(),
                Value<String?> attrezzatura = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SerieTableCompanion(
                id: id,
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: ordine,
                blocco: blocco,
                ripetute: ripetute,
                distanzaM: distanzaM,
                stile: stile,
                esecuzione: esecuzione,
                zona: zona,
                passoObiettivoS: passoObiettivoS,
                recuperoS: recuperoS,
                ripartenzaS: ripartenzaS,
                attrezzatura: attrezzatura,
                note: note,
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
                required int distanzaM,
                required String stile,
                required String esecuzione,
                Value<String?> zona = const Value.absent(),
                Value<double?> passoObiettivoS = const Value.absent(),
                Value<int?> recuperoS = const Value.absent(),
                Value<double?> ripartenzaS = const Value.absent(),
                Value<String?> attrezzatura = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SerieTableCompanion.insert(
                id: id,
                allenamentoId: allenamentoId,
                clubId: clubId,
                ordine: ordine,
                blocco: blocco,
                ripetute: ripetute,
                distanzaM: distanzaM,
                stile: stile,
                esecuzione: esecuzione,
                zona: zona,
                passoObiettivoS: passoObiettivoS,
                recuperoS: recuperoS,
                ripartenzaS: ripartenzaS,
                attrezzatura: attrezzatura,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClubTableTableTableManager get clubTable =>
      $$ClubTableTableTableManager(_db, _db.clubTable);
  $$AtletiTableTableTableManager get atletiTable =>
      $$AtletiTableTableTableManager(_db, _db.atletiTable);
  $$TestIngressoTableTableTableManager get testIngressoTable =>
      $$TestIngressoTableTableTableManager(_db, _db.testIngressoTable);
  $$TabellePassiTableTableTableManager get tabellePassiTable =>
      $$TabellePassiTableTableTableManager(_db, _db.tabellePassiTable);
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
}
