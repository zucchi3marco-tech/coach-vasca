/// Lo staff del modulo della distinta FIN, come nel foglio del coach
/// (2026-10-21): chi va in panchina, con la tessera FIN.
enum RuoloStaff {
  tecnico('tecnico', 'Tecnico'),
  viceTecnico('vice_tecnico', 'Vice tecnico'),
  accompagnatore('accompagnatore', 'Accompagnatore'),
  dirigente('dirigente', 'Dirigente di servizio'),
  medico('medico', 'Medico di servizio');

  const RuoloStaff(this.chiave, this.etichetta);

  /// La chiave nel JSON del database (`staff_distinta`).
  final String chiave;

  /// Come si legge nel modulo.
  final String etichetta;
}

class PersonaStaff {
  const PersonaStaff({this.nome = '', this.tessera = ''});

  final String nome;

  /// Il numero di tessera FIN.
  final String tessera;

  bool get vuota => nome.trim().isEmpty && tessera.trim().isEmpty;

  @override
  bool operator ==(Object other) =>
      other is PersonaStaff &&
      other.nome.trim() == nome.trim() &&
      other.tessera.trim() == tessera.trim();

  @override
  int get hashCode => Object.hash(nome.trim(), tessera.trim());
}

/// Le cinque righe dello staff. Si scrive una volta nella squadra; una
/// partita può avere il suo (vedi `partite.staff_distinta`).
class StaffDistinta {
  const StaffDistinta([this.persone = const {}]);

  final Map<RuoloStaff, PersonaStaff> persone;

  static const vuoto = StaffDistinta();

  PersonaStaff di(RuoloStaff ruolo) => persone[ruolo] ?? const PersonaStaff();

  /// Nessuna riga compilata.
  bool get senzaNessuno => persone.values.every((p) => p.vuota);

  StaffDistinta con(RuoloStaff ruolo, PersonaStaff persona) =>
      StaffDistinta({...persone, ruolo: persona});

  /// Dal JSON del database: una mappa `{"tecnico": {"nome", "tessera"}}`.
  /// Quello che non si legge resta vuoto.
  factory StaffDistinta.fromJson(Object? json) {
    if (json is! Map) return vuoto;
    final persone = <RuoloStaff, PersonaStaff>{};
    for (final ruolo in RuoloStaff.values) {
      final voce = json[ruolo.chiave];
      if (voce is! Map) continue;
      final persona = PersonaStaff(
        nome: '${voce['nome'] ?? ''}'.trim(),
        tessera: '${voce['tessera'] ?? ''}'.trim(),
      );
      if (!persona.vuota) persone[ruolo] = persona;
    }
    return StaffDistinta(persone);
  }

  /// Per il database: solo le righe compilate.
  Map<String, dynamic> toJson() => {
    for (final ruolo in RuoloStaff.values)
      if (!di(ruolo).vuota)
        ruolo.chiave: {
          'nome': di(ruolo).nome.trim(),
          'tessera': di(ruolo).tessera.trim(),
        },
  };

  @override
  bool operator ==(Object other) =>
      other is StaffDistinta &&
      RuoloStaff.values.every((r) => other.di(r) == di(r));

  @override
  int get hashCode => Object.hashAll(RuoloStaff.values.map(di));
}
