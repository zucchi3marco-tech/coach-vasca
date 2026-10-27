import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/leggi_a_pagine.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/serie.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/personal_best.dart';
import '../../atleti/domain/tempo_gara.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/rpe_seduta.dart';
import '../../club/data/membri_club_repository.dart';
import '../../gare/domain/gara.dart';
import '../../gare/domain/gara_iscritto.dart';
import '../../impegni/domain/impegno.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../pallanuoto/domain/distinta_giocatore.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../presenze/domain/presenza.dart';
import '../../referti/domain/referto_letto.dart';
import '../../referti/domain/referto_partita.dart';
import '../../secco/domain/esercizio_secco.dart';
import '../../secco/domain/serie_fatta.dart';
import '../../stagioni/domain/stagione.dart';
import '../../tabelle_passi/domain/tabella_passo.dart';
import '../../test/domain/test_club.dart';
import '../../test/domain/test_ingresso.dart';
import '../domain/dati_club.dart';

/// Legge dal server tutti i dati del club per "Scarica i dati del club".
/// Online-only e sola lettura: le tabelle si leggono a pagine (vedi
/// [leggiAPagine]), una dopo l'altra, e niente passa dalla copia locale né
/// va a qualcun altro.
class DatiClubRepository {
  DatiClubRepository(SupabaseClient client)
    : _client = client,
      _membri = MembriClubRepository(client);

  final SupabaseClient _client;
  final MembriClubRepository _membri;

  /// Tutti i dati del club [clubId]. Le schede benessere (la salute degli
  /// atleti) si leggono solo con [conBenessere]: altrimenti non vengono
  /// nemmeno chieste al server.
  ///
  /// [avanzamento] riceve, prima di ogni tabella, una frase breve da
  /// mostrare ("Leggo le presenze").
  Future<DatiClub> leggi(
    String clubId, {
    required bool conBenessere,
    void Function(String cosa)? avanzamento,
  }) async {
    Future<List<Map<String, dynamic>>> tabella(String nome, String cosa) {
      avanzamento?.call(cosa);
      return leggiAPagine(
        (da, a) => _client
            .from(nome)
            .select()
            .eq('club_id', clubId)
            .order('id')
            .range(da, a),
      );
    }

    avanzamento?.call('Leggo le squadre');
    final squadre = [for (final r in await _leggiSquadre(clubId)) _gruppo(r)];
    final squadreConCapo = await _membri.squadre(clubId);

    avanzamento?.call('Leggo gli allenatori');
    final membri = await _membri.membri(clubId);

    final atleti = [
      for (final r in await tabella('atleti', 'Leggo gli atleti'))
        Atleta.fromMap(r),
    ];
    final stagioni = [
      for (final r in await tabella('stagioni', 'Leggo le stagioni'))
        _stagione(r),
    ];
    final allenamenti = [
      for (final r in await tabella('allenamenti', 'Leggo gli allenamenti'))
        Allenamento.fromMap(r),
    ];
    final serie = [
      for (final r in await tabella('serie', 'Leggo le serie'))
        Serie.fromMap(r),
    ];
    final presenze = [
      for (final r in await tabella('presenze', 'Leggo le presenze'))
        Presenza.fromMap(r),
    ];
    final eserciziSecco = [
      for (final r in await tabella(
        'esercizi_secco',
        'Leggo gli esercizi a secco',
      ))
        _esercizio(r),
    ];
    final eserciziSeduta = [
      for (final r in await tabella(
        'esercizi_seduta',
        'Leggo le sedute a secco',
      ))
        EsercizioSeduta.fromMap(r),
    ];
    final serieSeccoFatte = [
      for (final r in await tabella(
        'serie_secco_fatte',
        'Leggo le serie a secco fatte',
      ))
        SerieFatta.fromMap(r),
    ];
    final partite = [
      for (final r in await tabella('partite', 'Leggo le partite'))
        Partita.fromMap(r),
    ];
    final distinte = [
      for (final r in await tabella('distinta_giocatori', 'Leggo i convocati'))
        DistintaGiocatore.fromMap(r),
    ];
    final eventiPartita = [
      for (final r in await tabella(
        'eventi_partita',
        'Leggo gli eventi delle partite',
      ))
        EventoPartita.fromMap(r),
    ];
    final referti = [
      for (final r in await tabella('referti_partita', 'Leggo i referti'))
        _referto(r),
    ];
    final gare = [
      for (final r in await tabella('gare', 'Leggo le gare')) Gara.fromMap(r),
    ];
    final impegni = [
      for (final r in await tabella('impegni', 'Leggo gli impegni'))
        Impegno.fromMap(r),
    ];
    final iscrittiGare = [
      for (final r in await tabella(
        'gara_iscritti',
        'Leggo le iscrizioni alle gare',
      ))
        _iscritto(r),
    ];
    final tempiGara = [
      for (final r in await tabella('tempi_gara', 'Leggo i tempi di gara'))
        _tempoGara(r),
    ];
    final personalBest = [
      for (final r in await tabella('personal_best', 'Leggo i personal best'))
        _personalBest(r),
    ];
    final testIngresso = [
      for (final r in await tabella('test_ingresso', 'Leggo i test del passo'))
        TestIngresso.fromMap(r),
    ];
    final tabellePassi = [
      for (final r in await tabella('tabelle_passi', 'Leggo i passi per zona'))
        TabellaPasso.fromMap(r),
    ];
    final testClub = [
      for (final r in await tabella('test_club', 'Leggo i test del club'))
        TestClub.fromMap(r),
    ];
    final risultatiTest = [
      for (final r in await tabella(
        'test_risultati',
        'Leggo i risultati dei test',
      ))
        RisultatoTest.fromMap(r),
    ];
    final rpeSedute = [
      for (final r in await tabella('rpe_sedute', 'Leggo lo sforzo (RPE)'))
        _rpe(r),
    ];
    // La salute degli atleti: solo se il responsabile l'ha chiesta.
    final schedeBenessere = conBenessere
        ? [
            for (final r in await tabella(
              'schede_benessere',
              'Leggo il benessere',
            ))
              _scheda(r),
          ]
        : null;

    return DatiClub(
      squadre: squadre,
      squadreConCapo: squadreConCapo,
      membri: membri,
      atleti: atleti,
      stagioni: stagioni,
      allenamenti: allenamenti,
      serie: serie,
      presenze: presenze,
      eserciziSecco: eserciziSecco,
      eserciziSeduta: eserciziSeduta,
      serieSeccoFatte: serieSeccoFatte,
      partite: partite,
      distinte: distinte,
      eventiPartita: eventiPartita,
      referti: referti,
      gare: gare,
      impegni: impegni,
      iscrittiGare: iscrittiGare,
      tempiGara: tempiGara,
      personalBest: personalBest,
      testIngresso: testIngresso,
      tabellePassi: tabellePassi,
      testClub: testClub,
      risultatiTest: risultatiTest,
      rpeSedute: rpeSedute,
      schedeBenessere: schedeBenessere,
    );
  }

  /// Quando è nato il club (`club.created_at`), nel fuso del telefono; null
  /// se il server non lo mostra. Serve a offrire le stagioni da cui
  /// scegliere (vedi `periodiDisponibili`).
  Future<DateTime?> creatoIl(String clubId) async {
    final riga = await _client
        .from('club')
        .select('created_at')
        .eq('id', clubId)
        .maybeSingle();
    final quando = riga?['created_at'] as String?;
    return quando == null ? null : DateTime.parse(quando).toLocal();
  }

  Future<List<Map<String, dynamic>>> _leggiSquadre(String clubId) {
    return leggiAPagine(
      (da, a) => _client
          .from('gruppi')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
  }
}

final datiClubRepositoryProvider = Provider<DatiClubRepository>((ref) {
  return DatiClubRepository(ref.watch(supabaseClientProvider));
});

// ---------------------------------------------------------------------------
// Le righe dei modelli che non hanno un `fromMap`: i repository le leggono
// passando dal database locale, qui servono direttamente dal server.

Gruppo _gruppo(Map<String, dynamic> m) => Gruppo(
  id: m['id'] as String,
  clubId: m['club_id'] as String,
  nome: m['nome'] as String,
  ordine: (m['ordine'] as num?)?.toInt() ?? 1,
  sport: m['sport'] as String?,
);

Stagione _stagione(Map<String, dynamic> m) => Stagione(
  id: m['id'] as String,
  clubId: m['club_id'] as String,
  nome: m['nome'] as String,
  dataInizio: DateTime.parse(m['data_inizio'] as String),
  dataFine: DateTime.parse(m['data_fine'] as String),
  obiettivo: m['obiettivo'] as String?,
  gruppoId: m['gruppo_id'] as String?,
  campionato: m['campionato'] as String?,
  fasi: [
    for (final f in _elenco(m['fasi']))
      FaseStagione.fromMap(Map<String, dynamic>.from(f as Map)),
  ],
);

EsercizioSecco _esercizio(Map<String, dynamic> m) => EsercizioSecco(
  id: m['id'] as String,
  clubId: m['club_id'] as String,
  nome: m['nome'] as String,
  categoria: CategoriaEsercizio.daNome(m['categoria'] as String?),
  misura: MisuraEsercizio.daNome(m['misura'] as String?),
  attrezzo: m['attrezzo'] as String?,
  descrizione: m['descrizione'] as String?,
  modello: m['modello'] as String?,
  archiviato: m['archiviato'] as bool? ?? false,
  videoYoutube: m['video_youtube'] as String?,
  videoDaS: (m['video_da_s'] as num?)?.toInt(),
);

RefertoPartita _referto(Map<String, dynamic> m) => RefertoPartita(
  id: m['id'] as String,
  partitaId: m['partita_id'] as String,
  clubId: m['club_id'] as String,
  squadraCasa: m['squadra_casa'] as String,
  squadraTrasferta: m['squadra_trasferta'] as String,
  risultatoCasa: (m['risultato_casa'] as num).toInt(),
  risultatoTrasferta: (m['risultato_trasferta'] as num).toInt(),
  parziali: [
    for (final p in _elenco(m['parziali']))
      ParzialeReferto.fromMap(Map<String, dynamic>.from(p as Map)),
  ],
  giocatoriCasa: [
    for (final g in _elenco(m['giocatori_casa']))
      GiocatoreReferto.fromMap(Map<String, dynamic>.from(g as Map)),
  ],
  giocatoriTrasferta: [
    for (final g in _elenco(m['giocatori_trasferta']))
      GiocatoreReferto.fromMap(Map<String, dynamic>.from(g as Map)),
  ],
);

GaraIscritto _iscritto(Map<String, dynamic> m) => GaraIscritto(
  id: m['id'] as String,
  garaId: m['gara_id'] as String,
  atletaId: m['atleta_id'] as String,
  clubId: m['club_id'] as String,
);

TempoGara _tempoGara(Map<String, dynamic> m) => TempoGara(
  id: m['id'] as String,
  atletaId: m['atleta_id'] as String,
  clubId: m['club_id'] as String,
  stile: m['stile'] as String,
  distanzaM: (m['distanza_m'] as num).toInt(),
  vascaM: (m['vasca_m'] as num).toInt(),
  tempoS: (m['tempo_s'] as num).toDouble(),
  data: DateTime.parse(m['data'] as String),
  note: m['note'] as String?,
  garaId: m['gara_id'] as String?,
);

PersonalBest _personalBest(Map<String, dynamic> m) => PersonalBest(
  id: m['id'] as String,
  atletaId: m['atleta_id'] as String,
  clubId: m['club_id'] as String,
  stile: m['stile'] as String,
  distanzaM: (m['distanza_m'] as num).toInt(),
  tempoS: (m['tempo_s'] as num).toDouble(),
  data: m['data'] == null ? null : DateTime.parse(m['data'] as String),
  note: m['note'] as String?,
);

RpeSeduta _rpe(Map<String, dynamic> m) => RpeSeduta(
  id: m['id'] as String,
  atletaId: m['atleta_id'] as String,
  clubId: m['club_id'] as String,
  eventoTipo: m['evento_tipo'] as String,
  eventoId: m['evento_id'] as String,
  data: DateTime.parse(m['data'] as String),
  rpe: (m['rpe'] as num).toInt(),
);

SchedaBenessere _scheda(Map<String, dynamic> m) {
  final data = DateTime.parse(m['data'] as String);
  final compilata = (m['updated_at'] ?? m['created_at']) as String?;
  return SchedaBenessere(
    id: m['id'] as String,
    atletaId: m['atleta_id'] as String,
    clubId: m['club_id'] as String,
    data: data,
    eventoTipo: m['evento_tipo'] as String?,
    eventoId: m['evento_id'] as String?,
    dolori: m['dolori'] as bool,
    zoneDolore: [for (final z in _elenco(m['zone_dolore'])) z as String],
    intensitaDolore: (m['intensita_dolore'] as num?)?.toInt(),
    oreSonno: (m['ore_sonno'] as num).toDouble(),
    compilataIl: compilata == null ? data : DateTime.parse(compilata).toLocal(),
    qualitaSonno: (m['qualita_sonno'] as num?)?.toInt(),
    energia: (m['energia'] as num?)?.toInt(),
    muscoli: (m['muscoli'] as num?)?.toInt(),
    stress: (m['stress'] as num?)?.toInt(),
    umore: (m['umore'] as num?)?.toInt(),
    sintomi: [for (final s in _elenco(m['sintomi'])) s as String],
  );
}

/// Una colonna a elenco (json o array di testo): la lista, vuota se manca.
List<dynamic> _elenco(Object? valore) => switch (valore) {
  final List<dynamic> lista => lista,
  final String json when json.isNotEmpty => jsonDecode(json) as List<dynamic>,
  _ => const [],
};
