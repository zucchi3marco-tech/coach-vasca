/// Regola di isolamento per gruppo: un record con un gruppo assegnato è
/// visibile solo a chi lavora con quel gruppo; un record senza gruppo (di
/// club) è visibile a tutti i gruppi.
///
/// [gruppoSelezionato] null = nessun filtro (tutti i gruppi).
bool visibileNelGruppo({
  required String? gruppoDelRecord,
  required String? gruppoSelezionato,
}) {
  if (gruppoSelezionato == null) return true;
  return gruppoDelRecord == null || gruppoDelRecord == gruppoSelezionato;
}

/// Stessa regola di [visibileNelGruppo], per un record che può
/// appartenere a più gruppi insieme (es. uno schema tattico): lista
/// vuota = di club, visibile a tutti i gruppi.
bool visibileNelGruppoMultiplo({
  required List<String> gruppiDelRecord,
  required String? gruppoSelezionato,
}) {
  if (gruppoSelezionato == null) return true;
  return gruppiDelRecord.isEmpty || gruppiDelRecord.contains(gruppoSelezionato);
}
