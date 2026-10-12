import 'dart:convert';

import 'package:flutter/foundation.dart';

/// I ruoli di pallanuoto nella scheda dell'atleta, nell'ordine dei menu.
const ruoliAtleta = [('movimento', 'Movimento'), ('portiere', 'Portiere')];

/// Per chi è una serie (fase 2 del "Mako della pallanuoto", proposta 2):
/// in quasi ogni seduta i portieri fanno un lavoro diverso, e capita che
/// un infortunato faccia altro.
///
/// - Tutto vuoto: tutto il gruppo.
/// - [ruolo]: solo i portieri o solo i giocatori di movimento.
/// - [soloAtleti]: solo questi atleti (e allora niente ruolo né esclusi).
/// - [tranneAtleti]: tutti (o tutti quelli del [ruolo]) tranne questi.
///
/// La stessa regola vive nel database (`serie_per_atleta`).
@immutable
class Destinatari {
  const Destinatari({
    this.ruolo,
    this.soloAtleti = const [],
    this.tranneAtleti = const [],
  });

  /// Solo questi atleti.
  const Destinatari.solo(List<String> atleti) : this(soloAtleti: atleti);

  static const tutti = Destinatari();
  static const portieri = Destinatari(ruolo: 'portiere');
  static const movimento = Destinatari(ruolo: 'movimento');

  /// Dai campi `per_ruolo`, `solo_atleti`, `tranne_atleti` (liste di id
  /// dal database, o testo JSON dalla copia locale).
  factory Destinatari.daCampi({
    String? perRuolo,
    Object? soloAtleti,
    Object? tranneAtleti,
  }) {
    List<String> elenco(Object? valore) => switch (valore) {
      null => const [],
      final String json when json.isEmpty => const [],
      final String json => [
        for (final id in jsonDecode(json) as List) id as String,
      ],
      final List<dynamic> lista => [for (final id in lista) id as String],
      _ => const [],
    };
    final solo = elenco(soloAtleti);
    if (solo.isNotEmpty) return Destinatari(soloAtleti: solo);
    return Destinatari(ruolo: perRuolo, tranneAtleti: elenco(tranneAtleti));
  }

  factory Destinatari.fromMap(Map<String, dynamic> map) => Destinatari.daCampi(
    perRuolo: map['per_ruolo'] as String?,
    soloAtleti: map['solo_atleti'],
    tranneAtleti: map['tranne_atleti'],
  );

  /// 'portiere' | 'movimento' | null (tutti i ruoli).
  final String? ruolo;
  final List<String> soloAtleti;
  final List<String> tranneAtleti;

  bool get perTutti =>
      ruolo == null && soloAtleti.isEmpty && tranneAtleti.isEmpty;

  /// La serie è anche per l'atleta [atletaId], che ha il [ruoloAtleta]
  /// (null: non indicato, conta come movimento)?
  bool perAtleta(String atletaId, String? ruoloAtleta) {
    if (soloAtleti.isNotEmpty) return soloAtleti.contains(atletaId);
    if (ruolo != null && ruolo != (ruoloAtleta ?? 'movimento')) return false;
    return !tranneAtleti.contains(atletaId);
  }

  /// Conta nel volume del gruppo, cioè in quello di un giocatore di
  /// movimento qualunque: non le serie dei soli portieri, né quelle di
  /// alcuni atleti (una variante per un infortunato, il lavoro di un
  /// centroboa). Gli esclusi da una serie non la tolgono dal gruppo.
  bool get delGruppo => soloAtleti.isEmpty && ruolo != 'portiere';

  /// Come [delGruppo], per un portiere.
  bool get deiPortieri => soloAtleti.isEmpty && ruolo != 'movimento';

  /// I campi per il database: tutti e tre sempre, così una modifica
  /// cancella anche quelli che non servono più.
  Map<String, Object?> get campi => {
    'per_ruolo': soloAtleti.isEmpty ? ruolo : null,
    'solo_atleti': soloAtleti.isEmpty ? null : soloAtleti,
    'tranne_atleti': soloAtleti.isNotEmpty || tranneAtleti.isEmpty
        ? null
        : tranneAtleti,
  };

  /// Gli elenchi di id come testo JSON, per la copia locale.
  String? get soloAtletiJson =>
      soloAtleti.isEmpty ? null : jsonEncode(soloAtleti);
  String? get tranneAtletiJson => soloAtleti.isNotEmpty || tranneAtleti.isEmpty
      ? null
      : jsonEncode(tranneAtleti);

  /// Gli stessi destinatari con anche [atletaId] fra gli esclusi (o tolto
  /// da [soloAtleti]); null se così la serie non resta a nessuno.
  Destinatari? senza(String atletaId) {
    if (soloAtleti.isNotEmpty) {
      final restanti = [
        for (final id in soloAtleti)
          if (id != atletaId) id,
      ];
      return restanti.isEmpty ? null : Destinatari(soloAtleti: restanti);
    }
    if (tranneAtleti.contains(atletaId)) return this;
    return Destinatari(ruolo: ruolo, tranneAtleti: [...tranneAtleti, atletaId]);
  }

  @override
  bool operator ==(Object other) =>
      other is Destinatari &&
      other.ruolo == ruolo &&
      setEquals(other.soloAtleti.toSet(), soloAtleti.toSet()) &&
      setEquals(other.tranneAtleti.toSet(), tranneAtleti.toSet());

  @override
  int get hashCode => Object.hash(
    ruolo,
    Object.hashAllUnordered(soloAtleti),
    Object.hashAllUnordered(tranneAtleti),
  );

  @override
  String toString() =>
      'Destinatari(ruolo: $ruolo, solo: $soloAtleti, tranne: $tranneAtleti)';
}

/// "Portieri", "Movimento", "Rossi, Bianchi", "Tutti tranne Rossi",
/// "Movimento tranne Rossi"; null per tutto il gruppo. [nome] dà il nome
/// breve di un atleta (null per un id che non si conosce più: si salta).
String? etichettaDestinatari(
  Destinatari d,
  String? Function(String atletaId) nome,
) {
  String elenco(List<String> ids) {
    final nomi = [for (final id in ids) ?nome(id)];
    return nomi.isEmpty ? 'atleti non più nel gruppo' : nomi.join(', ');
  }

  if (d.soloAtleti.isNotEmpty) return elenco(d.soloAtleti);
  final gruppo = switch (d.ruolo) {
    'portiere' => 'Portieri',
    'movimento' => 'Movimento',
    _ => null,
  };
  if (d.tranneAtleti.isEmpty) return gruppo;
  return '${gruppo ?? 'Tutti'} tranne ${elenco(d.tranneAtleti)}';
}
