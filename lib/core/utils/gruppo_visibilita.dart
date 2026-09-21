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
